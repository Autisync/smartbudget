from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Baseline security headers on every response (M-4).

    Applies to both the JSON API and the two HTML pages this service serves
    directly (/r/reset-password, /r/verify-email). A default, restrictive CSP
    is set here as a floor — but never overrides a header a route already set
    itself, so /r/reset-password's own nonce-scoped CSP (see C-1) still wins
    for that specific response rather than being replaced by this generic one.
    """

    _DEFAULT_CSP = "default-src 'none'; frame-ancestors 'none'"

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
        response.headers.setdefault("Content-Security-Policy", self._DEFAULT_CSP)
        return response
