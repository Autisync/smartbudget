"""Regression cover for P2.9: the backend had zero error-monitoring
integration and no global exception handler — an unhandled exception
produced a bare stdout line via FastAPI's default 500 response, and nobody
was ever alerted. Also covers the structured JSON logging setup.
"""

import json
import logging

import pytest
from fastapi.testclient import TestClient

from app.core.logging import JsonFormatter, configure_logging
from app.core.sentry import configure_sentry
from app.main import create_application

# ---- Unit tests: JSON logging -----------------------------------------------


def test_json_formatter_produces_valid_json_with_expected_fields():
    record = logging.LogRecord(
        name="app.test", level=logging.INFO, pathname=__file__, lineno=1,
        msg="hello %s", args=("world",), exc_info=None,
    )
    formatted = JsonFormatter().format(record)
    parsed = json.loads(formatted)
    assert parsed["message"] == "hello world"
    assert parsed["level"] == "INFO"
    assert parsed["logger"] == "app.test"
    assert "timestamp" in parsed


def test_json_formatter_includes_exception_info():
    try:
        raise ValueError("boom")
    except ValueError:
        import sys
        record = logging.LogRecord(
            name="app.test", level=logging.ERROR, pathname=__file__, lineno=1,
            msg="failed", args=(), exc_info=sys.exc_info(),
        )
    formatted = JsonFormatter().format(record)
    parsed = json.loads(formatted)
    assert "ValueError" in parsed["exception"]
    assert "boom" in parsed["exception"]


def test_configure_logging_is_idempotent_no_duplicate_handlers():
    configure_logging()
    configure_logging()
    configure_logging()
    assert len(logging.getLogger().handlers) == 1


# ---- Unit tests: Sentry configuration --------------------------------------


def test_configure_sentry_is_a_safe_noop_without_a_dsn(monkeypatch):
    monkeypatch.setattr("app.core.sentry.settings.sentry_dsn", "")
    # Must not raise, and must not actually configure a real DSN.
    configure_sentry()
    import sentry_sdk
    client = sentry_sdk.get_client()
    assert not client.dsn


# ---- Feature tests: the global exception handler ---------------------------


@pytest.fixture
def client():
    app = create_application()

    @app.get("/__test_unhandled_error")
    def boom():
        raise ValueError("something with internal details: /etc/passwd, SELECT * FROM users")

    return TestClient(app, raise_server_exceptions=False)


def test_unhandled_exception_returns_sanitized_500(client):
    resp = client.get("/__test_unhandled_error")
    assert resp.status_code == 500
    body = resp.json()
    assert body == {"detail": "Internal server error"}
    # The raw exception message (with the "leaked" fake internals) must never
    # reach the response body.
    assert "/etc/passwd" not in resp.text
    assert "SELECT" not in resp.text
    assert "ValueError" not in resp.text


def test_unhandled_exception_reports_to_sentry(client, monkeypatch):
    captured = []
    monkeypatch.setattr("app.main.sentry_sdk.capture_exception", lambda exc: captured.append(exc))
    client.get("/__test_unhandled_error")
    assert len(captured) == 1
    assert isinstance(captured[0], ValueError)


def test_app_keeps_working_normally_after_an_unhandled_exception(client):
    """No shared-state corruption from the handler itself — a normal
    request right after a crash must succeed exactly as if nothing happened."""
    client.get("/__test_unhandled_error")
    resp = client.get("/api/v1/health")
    assert resp.status_code == 200


def test_existing_http_exceptions_are_unaffected_by_the_global_handler():
    """HTTPException (401/400/404/etc, used throughout app/core/errors.py)
    must keep its normal status code and detail — the global handler only
    catches exceptions FastAPI doesn't already have a specific handler for."""
    client = TestClient(create_application())
    resp = client.post("/api/v1/auth/login", json={"email": "nobody@example.com", "password": "wrongpassword"})
    assert resp.status_code in (401, 400)  # never 500
    assert resp.json()["detail"] != "Internal server error"
