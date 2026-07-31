"""Regression cover for L-3: /health/ready never checked Postgres or the
main Redis at all — only the Celery broker (a separate Redis DB). If
Postgres or Redis went down, real requests would start failing while this
endpoint still reported `status: ok` as long as email prerequisites
happened to be met. Also covers the new HEALTH_CHECK_TOKEN gate — the
endpoint was unauthenticated and exposed Celery/SMTP internals to anyone.
"""

import pytest
from fastapi.testclient import TestClient

from app.core.config import settings
from app.main import create_application


@pytest.fixture(autouse=True)
def _restore_token_setting():
    original = settings.health_check_token
    yield
    settings.health_check_token = original


@pytest.fixture
def client():
    return TestClient(create_application())


# ---- Unit tests: the individual check functions ----------------------------


def test_check_database_reports_reachable_against_the_real_test_db():
    from app.api.v1.endpoints.health import _check_database
    result = _check_database()
    assert result["reachable"] is True
    assert result["error"] is None


def test_check_database_reports_unreachable_on_failure(monkeypatch):
    from app.api.v1.endpoints import health as health_module

    class _BrokenSessionLocal:
        def __enter__(self):
            raise RuntimeError("connection refused")

        def __exit__(self, *args):
            return False

    monkeypatch.setattr(health_module, "SessionLocal", lambda: _BrokenSessionLocal())
    result = health_module._check_database()
    assert result["reachable"] is False
    assert result["error"] == "RuntimeError"


def test_check_redis_reports_reachable_against_the_real_test_redis():
    from app.api.v1.endpoints.health import _check_redis
    result = _check_redis()
    assert result["reachable"] is True


def test_check_redis_reports_unreachable_on_failure(monkeypatch):
    from app.api.v1.endpoints import health as health_module

    class _BrokenRedis:
        def ping(self):
            raise ConnectionError("refused")

    monkeypatch.setattr(health_module, "get_redis", lambda: _BrokenRedis())
    result = health_module._check_redis()
    assert result["reachable"] is False
    assert result["error"] == "ConnectionError"


# ---- Feature tests: the real endpoint via TestClient -----------------------


def test_liveness_endpoint_always_returns_ok(client):
    resp = client.get("/api/v1/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_readiness_reports_database_and_redis_when_healthy(client):
    resp = client.get("/api/v1/health/ready")
    assert resp.status_code == 200
    body = resp.json()
    assert body["database"]["reachable"] is True
    assert body["redis"]["reachable"] is True


def test_readiness_is_degraded_but_still_200_when_database_is_down(client, monkeypatch):
    from app.api.v1.endpoints import health as health_module

    def _broken_check_database():
        return {"reachable": False, "error": "OperationalError"}

    monkeypatch.setattr(health_module, "_check_database", _broken_check_database)

    resp = client.get("/api/v1/health/ready")
    assert resp.status_code == 200  # never trips the container healthcheck
    body = resp.json()
    assert body["status"] == "degraded"
    assert body["database"]["reachable"] is False


def test_readiness_is_degraded_but_still_200_when_redis_is_down(client, monkeypatch):
    from app.api.v1.endpoints import health as health_module

    monkeypatch.setattr(
        health_module, "_check_redis", lambda: {"reachable": False, "error": "ConnectionError"}
    )

    resp = client.get("/api/v1/health/ready")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "degraded"
    assert body["redis"]["reachable"] is False


# ---- Feature tests: HEALTH_CHECK_TOKEN gate (L-3) --------------------------


def test_readiness_is_unrestricted_by_default(client):
    settings.health_check_token = ""
    resp = client.get("/api/v1/health/ready")
    assert resp.status_code == 200


def test_readiness_requires_token_header_when_configured(client):
    settings.health_check_token = "super-secret-monitor-token"
    resp = client.get("/api/v1/health/ready")
    assert resp.status_code == 404  # hides existence, not just contents


def test_readiness_rejects_wrong_token(client):
    settings.health_check_token = "super-secret-monitor-token"
    resp = client.get("/api/v1/health/ready", headers={"X-Health-Check-Token": "wrong"})
    assert resp.status_code == 404


def test_readiness_accepts_correct_token(client):
    settings.health_check_token = "super-secret-monitor-token"
    resp = client.get(
        "/api/v1/health/ready", headers={"X-Health-Check-Token": "super-secret-monitor-token"}
    )
    assert resp.status_code == 200
    assert "database" in resp.json()
