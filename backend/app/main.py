import logging
import json
from html import escape
from urllib.parse import quote

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from app.api.v1.router import api_router
from app.core.config import settings

logger = logging.getLogger(__name__)


def _deep_link_bridge_html(*, title: str, message: str, app_link: str) -> str:
        safe_title = escape(title)
        safe_message = escape(message)
        safe_app_link = escape(app_link, quote=True)
        app_link_js = json.dumps(app_link)
        return f"""<!doctype html>
<html lang=\"en\">
    <head>
        <meta charset=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
        <title>{safe_title}</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f8fafc; color: #111827; }}
            .wrap {{ max-width: 520px; margin: 0 auto; padding: 40px 20px; }}
            .card {{ background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 24px; }}
            h1 {{ margin-top: 0; font-size: 24px; }}
            p {{ line-height: 1.5; color: #374151; }}
            .btn {{ display: inline-block; margin-top: 12px; background: #2563eb; color: #fff; text-decoration: none; padding: 12px 16px; border-radius: 8px; font-weight: 600; }}
            .muted {{ margin-top: 16px; font-size: 12px; color: #6b7280; word-break: break-all; }}
        </style>
    </head>
    <body>
        <div class=\"wrap\">
            <div class=\"card\">
                <h1>{safe_title}</h1>
                <p>{safe_message}</p>
                <a id=\"open-app\" class=\"btn\" href=\"{safe_app_link}\">Open SmartSpend App</a>
                <p class=\"muted\">If nothing happens, tap the button above again.<br/>Deep link: {safe_app_link}</p>
            </div>
        </div>
        <script>
            window.location.href = {app_link_js};
        </script>
    </body>
</html>
"""


def create_application() -> FastAPI:
    app = FastAPI(title=settings.app_name)

    smtp_issues = settings.smtp_validation_issues()
    for issue in smtp_issues:
        logger.warning("SMTP configuration: %s", issue)

    allowed_origins = [origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()]
    if not allowed_origins:
        allowed_origins = ["*"]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(api_router)

    @app.get("/r/reset-password", response_class=HTMLResponse)
    def reset_password_redirect(token: str) -> str:
        app_link = f"smartbudget://reset-password?token={quote(token, safe='')}"
        return _deep_link_bridge_html(
            title="Reset Your Password",
            message="We are opening SmartSpend so you can reset your password securely.",
            app_link=app_link,
        )

    @app.get("/r/verify-email", response_class=HTMLResponse)
    def verify_email_redirect(token: str) -> str:
        app_link = f"smartbudget://verify-email?token={quote(token, safe='')}"
        return _deep_link_bridge_html(
            title="Verify Your Email",
            message="We are opening SmartSpend so you can finish email verification.",
            app_link=app_link,
        )

    return app


app = create_application()
