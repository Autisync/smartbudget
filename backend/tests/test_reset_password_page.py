"""Regression cover for C-1: reflected XSS on the password-reset landing page.

`_reset_password_page_html` used to embed the `token` query param into an
inline `<script>` block via bare `json.dumps`, which does not escape `/` — a
token containing the literal text `</script>` closed the script element
early (HTML parsing happens before JS parsing) and let arbitrary markup
execute. The fix escapes `/` in every value interpolated into inline script
blocks and adds a nonce-based CSP so even a future regression can't execute
an injected <script> tag.
"""

import re

import pytest
from fastapi.testclient import TestClient

from app.main import _json_for_inline_script, _reset_password_page_html, create_application

XSS_PAYLOAD = "</script><img src=x onerror=alert(document.domain)>"
NORMAL_TOKEN = "eyJhbGciOi.J9.sig-with_special=chars&stuff"


# ---- Unit tests -----------------------------------------------------------


def test_json_for_inline_script_escapes_forward_slash():
    encoded = _json_for_inline_script(XSS_PAYLOAD)
    assert "</script>" not in encoded
    assert "<\\/script>" in encoded


def test_json_for_inline_script_round_trips_normal_values():
    import json as _json

    encoded = _json_for_inline_script(NORMAL_TOKEN)
    # Escaping '/' is a no-op for JSON parsing — decoding must still recover
    # the exact original string.
    assert _json.loads(encoded.replace("\\/", "/")) == NORMAL_TOKEN


def test_reset_password_html_neutralizes_malicious_token():
    html = _reset_password_page_html(token=XSS_PAYLOAD, script_nonce="test-nonce")
    # The only real </script> in the document must be the one closing the
    # legitimate nonce'd script block — never one produced by the token.
    close_tags = re.findall(r"</script\s*>", html)
    assert len(close_tags) == 1
    # The payload's own "</script>" must appear only in its escaped form.
    assert "<\\/script>" in html
    # The <img onerror=...> payload text is present as inert JS-string data
    # (never as real markup, since it never left the script string literal).
    assert 'onerror=alert(document.domain)' in html


def test_reset_password_html_renders_normal_token_correctly():
    html = _reset_password_page_html(token=NORMAL_TOKEN, script_nonce="test-nonce")
    assert f'const token = "{NORMAL_TOKEN}"' in html
    assert 'nonce="test-nonce"' in html


# ---- Feature test: full request through the real route --------------------


@pytest.fixture
def client():
    return TestClient(create_application())


def test_reset_password_route_neutralizes_xss_payload(client):
    resp = client.get("/r/reset-password", params={"token": XSS_PAYLOAD})
    assert resp.status_code == 200
    body = resp.text
    close_tags = re.findall(r"</script\s*>", body)
    assert len(close_tags) == 1, "payload must not introduce an extra </script> boundary"
    # CSP must be present and must NOT allow unnonced inline scripts.
    csp = resp.headers.get("content-security-policy", "")
    assert "script-src" in csp
    assert "'unsafe-inline'" not in csp.split("script-src", 1)[1].split(";", 1)[0]
    assert "nonce-" in csp


def test_reset_password_route_normal_token_still_works(client):
    resp = client.get("/r/reset-password", params={"token": NORMAL_TOKEN})
    assert resp.status_code == 200
    assert NORMAL_TOKEN in resp.text
    assert "Set a new password" in resp.text
    assert "reset-form" in resp.text
    # The app-open deep link must still carry the token, URL-encoded.
    assert "token=" in resp.text


def test_reset_password_route_missing_token_renders_page_not_422(client):
    resp = client.get("/r/reset-password")
    assert resp.status_code == 200
    assert "Set a new password" in resp.text


def test_reset_password_route_csp_nonce_matches_script_tag(client):
    resp = client.get("/r/reset-password", params={"token": NORMAL_TOKEN})
    csp = resp.headers["content-security-policy"]
    nonce = csp.split("nonce-", 1)[1].split("'", 1)[0]
    assert f'nonce="{nonce}"' in resp.text


def test_verify_email_route_unaffected(client):
    # Sibling HTML route — confirm this change didn't collaterally break it.
    resp = client.get("/r/verify-email", params={"token": "not-a-real-token"})
    assert resp.status_code == 200
    assert "SmartSpend" in resp.text
