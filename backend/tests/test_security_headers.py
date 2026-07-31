"""Regression cover for M-4: no app-level security headers existed at all —
only CORSMiddleware. This is what made C-1 (the reset-password XSS) fully
exploitable rather than merely theoretical: no CSP meant nothing blocked an
injected <script> tag from executing even before that bug was fixed.
"""

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from starlette.responses import JSONResponse

from app.main import create_application
from app.middleware.security_headers import SecurityHeadersMiddleware

# ---- Unit test: the middleware in isolation --------------------------------


def test_middleware_sets_baseline_headers_on_a_bare_response():
    app = FastAPI()
    app.add_middleware(SecurityHeadersMiddleware)

    @app.get("/whatever")
    def whatever():
        return {"ok": True}

    client = TestClient(app)
    resp = client.get("/whatever")

    assert resp.headers["x-content-type-options"] == "nosniff"
    assert resp.headers["x-frame-options"] == "DENY"
    assert resp.headers["referrer-policy"] == "strict-origin-when-cross-origin"
    assert resp.headers["content-security-policy"] == "default-src 'none'; frame-ancestors 'none'"


def test_middleware_does_not_override_a_route_set_csp():
    app = FastAPI()
    app.add_middleware(SecurityHeadersMiddleware)

    @app.get("/custom-csp")
    def custom_csp():
        return JSONResponse({"ok": True}, headers={"Content-Security-Policy": "script-src 'self' 'nonce-abc'"})

    client = TestClient(app)
    resp = client.get("/custom-csp")
    assert resp.headers["content-security-policy"] == "script-src 'self' 'nonce-abc'"


# ---- Feature tests: through the real app -----------------------------------


@pytest.fixture
def client():
    return TestClient(create_application())


def test_reset_password_page_carries_baseline_headers_plus_its_own_csp(client):
    resp = client.get("/r/reset-password", params={"token": "sometoken"})
    assert resp.headers["x-content-type-options"] == "nosniff"
    assert resp.headers["referrer-policy"] == "strict-origin-when-cross-origin"
    # Its own nonce-scoped CSP from C-1's fix must win over the middleware's
    # generic default — this route needs script-src 'self', not default-src 'none'.
    csp = resp.headers["content-security-policy"]
    assert "nonce-" in csp
    assert csp != SecurityHeadersMiddleware._DEFAULT_CSP


def test_verify_email_page_carries_baseline_headers(client):
    resp = client.get("/r/verify-email", params={"token": "not-real"})
    assert resp.headers["x-content-type-options"] == "nosniff"
    assert resp.headers["x-frame-options"] == "DENY"
    # No route-specific CSP here, so the middleware's restrictive default applies.
    assert resp.headers["content-security-policy"] == SecurityHeadersMiddleware._DEFAULT_CSP


def test_json_api_endpoint_also_carries_baseline_headers(client):
    resp = client.get("/api/v1/health")
    assert resp.status_code == 200
    assert resp.headers["x-content-type-options"] == "nosniff"
    assert resp.headers["x-frame-options"] == "DENY"
    assert resp.headers["content-security-policy"] == SecurityHeadersMiddleware._DEFAULT_CSP


def test_xss_regression_still_neutralized_with_headers_in_place(client):
    """Combined regression: C-1's escaping fix + M-4's CSP together — re-run
    the exact exploit payload from test_reset_password_page.py to confirm
    adding this middleware didn't change that route's behavior."""
    payload = "</script><img src=x onerror=alert(document.domain)>"
    resp = client.get("/r/reset-password", params={"token": payload})
    assert resp.status_code == 200
    import re
    assert len(re.findall(r"</script\s*>", resp.text)) == 1
    assert "'unsafe-inline'" not in resp.headers["content-security-policy"].split("script-src", 1)[1].split(";", 1)[0]
