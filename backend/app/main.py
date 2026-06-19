import asyncio
import json
import logging
from html import escape
from urllib.parse import quote

import jwt
from fastapi import Depends, FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.api.deps import db_session
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.redis import get_async_redis
from app.core.security import decode_token
from app.services.auth_service import AuthService

logger = logging.getLogger(__name__)


def _verify_email_result_html(*, success: bool, app_link: str) -> str:
    """Final-state page shown after the verification link is opened. Verification
    has already happened server-side, so this page never depends on the app."""
    safe_app_link = escape(app_link, quote=True)
    if success:
        accent = "#16a34a"
        glyph = "&#10003;"  # check
        heading = "Email verified"
        body = (
            "Your SmartSpend email address is confirmed. "
            "Return to the SmartSpend app and sign in to get started."
        )
    else:
        accent = "#dc2626"
        glyph = "&#33;"  # exclamation
        heading = "Link expired or invalid"
        body = (
            "This verification link is no longer valid. Open the SmartSpend app "
            "and tap &ldquo;Resend verification email&rdquo; to get a fresh link."
        )
    return f"""<!doctype html>
<html lang=\"en\">
    <head>
        <meta charset=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
        <title>{heading} | SmartSpend</title>
        <style>
            body {{ font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 0; background: #f6f8fb; color: #14161d; }}
            .wrap {{ max-width: 460px; margin: 0 auto; padding: 56px 20px; text-align: center; }}
            .card {{ background: #fff; border: 1px solid #e6e9ef; border-radius: 18px; padding: 40px 28px; box-shadow: 0 8px 28px rgba(20,22,29,0.06); }}
            .badge {{ width: 64px; height: 64px; border-radius: 50%; background: {accent}1a; color: {accent}; font-size: 34px; line-height: 64px; margin: 0 auto 20px; font-weight: 700; }}
            h1 {{ margin: 0 0 10px; font-size: 23px; letter-spacing: -0.3px; }}
            p {{ line-height: 1.55; color: #4b5563; font-size: 15px; margin: 0 0 22px; }}
            .btn {{ display: inline-block; background: #2563eb; color: #fff; text-decoration: none; padding: 13px 22px; border-radius: 12px; font-weight: 600; font-size: 15px; }}
        </style>
    </head>
    <body>
        <div class=\"wrap\">
            <div class=\"card\">
                <div class=\"badge\">{glyph}</div>
                <h1>{heading}</h1>
                <p>{body}</p>
                <a class=\"btn\" href=\"{safe_app_link}\">Open SmartSpend</a>
            </div>
        </div>
    </body>
</html>
"""


def _reset_password_page_html(*, token: str) -> str:
    safe_token = escape(token, quote=True)
    token_js = json.dumps(token)
    app_link = f"smartbudget://reset-password?token={quote(token, safe='')}"
    app_link_html = escape(app_link, quote=True)
    app_link_js = json.dumps(app_link)

    return f"""<!doctype html>
<html lang=\"en\">
    <head>
        <meta charset=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
        <title>Reset Password | SmartSpend</title>
        <style>
            :root {{
                --bg: #f6f8fb;
                --card: #ffffff;
                --text: #111827;
                --muted: #6b7280;
                --line: #e5e7eb;
                --primary: #2563eb;
                --success: #0f9d58;
                --danger: #dc2626;
            }}

            * {{ box-sizing: border-box; }}
            body {{
                margin: 0;
                font-family: Arial, sans-serif;
                color: var(--text);
                background:
                    radial-gradient(900px 420px at 10% -10%, rgba(37,99,235,0.14), transparent 60%),
                    radial-gradient(700px 350px at 100% 0%, rgba(14,165,233,0.12), transparent 60%),
                    var(--bg);
            }}

            .container {{
                max-width: 560px;
                margin: 0 auto;
                min-height: 100vh;
                display: flex;
                align-items: center;
                padding: 28px 16px;
            }}

            .card {{
                width: 100%;
                background: var(--card);
                border: 1px solid var(--line);
                border-radius: 16px;
                box-shadow: 0 10px 30px rgba(17,24,39,0.08);
                padding: 24px;
            }}

            h1 {{ margin: 0 0 8px 0; font-size: 28px; line-height: 1.1; }}
            p {{ margin: 0; color: #374151; line-height: 1.5; }}

            .hint {{ margin-top: 12px; color: var(--muted); font-size: 13px; }}
            .field {{ margin-top: 16px; }}
            label {{ display: block; margin-bottom: 6px; font-weight: 700; font-size: 14px; }}

            input[type=\"password\"] {{
                width: 100%;
                padding: 12px 13px;
                border: 1px solid #d1d5db;
                border-radius: 10px;
                font-size: 15px;
            }}

            .rules {{ margin-top: 10px; color: var(--muted); font-size: 13px; }}
            .actions {{ margin-top: 18px; display: flex; gap: 10px; flex-wrap: wrap; }}

            .btn {{
                border: 0;
                border-radius: 10px;
                padding: 12px 14px;
                font-weight: 700;
                cursor: pointer;
                text-decoration: none;
                display: inline-block;
            }}

            .btn-primary {{ background: var(--primary); color: #fff; }}
            .btn-secondary {{ background: #eef2ff; color: #1e3a8a; }}
            .btn:disabled {{ opacity: 0.55; cursor: not-allowed; }}

            .message {{ margin-top: 14px; padding: 10px 12px; border-radius: 10px; font-size: 14px; display: none; }}
            .message.error {{ background: #fef2f2; color: var(--danger); border: 1px solid #fecaca; }}
            .message.success {{ background: #ecfdf3; color: #065f46; border: 1px solid #a7f3d0; }}

            .token {{ margin-top: 14px; font-size: 12px; color: var(--muted); word-break: break-all; }}
        </style>
    </head>
    <body>
        <div class=\"container\">
            <div class=\"card\">
                <h1>Set a new password</h1>
                <p>Choose a strong password for your SmartSpend account. You can reset directly here or open the app.</p>

                <div class=\"hint\">This page was opened from your secure reset link.</div>

                <form id=\"reset-form\">
                    <div class=\"field\">
                        <label for=\"password\">New password</label>
                        <input id=\"password\" type=\"password\" autocomplete=\"new-password\" required />
                    </div>

                    <div class=\"field\">
                        <label for=\"confirm\">Confirm password</label>
                        <input id=\"confirm\" type=\"password\" autocomplete=\"new-password\" required />
                    </div>

                    <div class=\"rules\">Use at least 8 characters and include uppercase, lowercase, and a number.</div>

                    <div class=\"actions\">
                        <button id=\"submit-btn\" type=\"submit\" class=\"btn btn-primary\">Reset password</button>
                        <a id=\"open-app\" class=\"btn btn-secondary\" href=\"{app_link_html}\">Open SmartSpend App</a>
                    </div>

                    <div id=\"msg-error\" class=\"message error\"></div>
                    <div id=\"msg-success\" class=\"message success\"></div>
                </form>

                <div class=\"token\">Token: {safe_token}</div>
            </div>
        </div>

        <script>
            const token = {token_js};
            const appLink = {app_link_js};
            const form = document.getElementById('reset-form');
            const submitBtn = document.getElementById('submit-btn');
            const openAppBtn = document.getElementById('open-app');
            const errorEl = document.getElementById('msg-error');
            const successEl = document.getElementById('msg-success');
            const passwordEl = document.getElementById('password');
            const confirmEl = document.getElementById('confirm');

            openAppBtn.addEventListener('click', () => {{
                window.location.href = appLink;
            }});

            function setError(message) {{
                successEl.style.display = 'none';
                errorEl.textContent = message;
                errorEl.style.display = 'block';
            }}

            function setSuccess(message) {{
                errorEl.style.display = 'none';
                successEl.textContent = message;
                successEl.style.display = 'block';
            }}

            function isStrongPassword(value) {{
                return value.length >= 8 && /[A-Z]/.test(value) && /[a-z]/.test(value) && /[0-9]/.test(value);
            }}

            form.addEventListener('submit', async (event) => {{
                event.preventDefault();

                const password = passwordEl.value || '';
                const confirm = confirmEl.value || '';

                if (!token) {{
                    setError('This reset link is missing a token. Please request a new reset email.');
                    return;
                }}
                if (!isStrongPassword(password)) {{
                    setError('Use a stronger password: at least 8 chars with uppercase, lowercase, and number.');
                    return;
                }}
                if (password !== confirm) {{
                    setError('Passwords do not match.');
                    return;
                }}

                submitBtn.disabled = true;
                submitBtn.textContent = 'Updating...';
                errorEl.style.display = 'none';
                successEl.style.display = 'none';

                try {{
                    const response = await fetch('/api/v1/auth/reset-password', {{
                        method: 'POST',
                        headers: {{ 'Content-Type': 'application/json' }},
                        body: JSON.stringify({{ token: token, new_password: password }}),
                    }});

                    const data = await response.json().catch(() => ({{}}));

                    if (!response.ok) {{
                        setError(data.detail || 'Could not reset password. Request a new email and try again.');
                        return;
                    }}

                    setSuccess('Password updated successfully. You can now sign in with your new password.');
                    passwordEl.value = '';
                    confirmEl.value = '';
                }} catch (_) {{
                    setError('Network error while resetting password. Please try again.');
                }} finally {{
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Reset password';
                }}
            }});
        </script>
    </body>
</html>
"""


def create_application() -> FastAPI:
    app = FastAPI(title=settings.app_name)

    # Fail fast if critical secrets are still at insecure defaults in production.
    secret_issues = settings.production_secret_issues()
    if secret_issues:
        for issue in secret_issues:
            logger.critical("SECURITY MISCONFIGURATION: %s", issue)
        raise SystemExit(
            "Refusing to start: critical security misconfigurations detected. "
            "See logs above. Fix them and restart."
        )

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

    @app.websocket("/ws/v1/balance/{user_id}")
    async def balance_updates(websocket: WebSocket, user_id: str):
        await websocket.accept()
        redis_client = get_async_redis()
        pubsub = redis_client.pubsub()
        channel = f"balance:{user_id}"
        await pubsub.subscribe(channel)
        try:
            await websocket.send_json({"type": "connected", "channel": channel})
            while True:
                message = await pubsub.get_message(ignore_subscribe_messages=True, timeout=0.5)
                if message and message.get("data"):
                    await websocket.send_text(message["data"])
                await asyncio.sleep(0.05)
        except WebSocketDisconnect:
            logger.info("balance websocket disconnected", extra={"user_id": user_id})
        finally:
            await pubsub.unsubscribe(channel)
            await pubsub.close()
            await redis_client.aclose()

    @app.get("/r/reset-password", response_class=HTMLResponse)
    def reset_password_redirect(token: str = "") -> str:
        # token optional so a malformed link still renders the page (which shows
        # an error in-page) rather than a raw 422 JSON body.
        return _reset_password_page_html(token=token)

    @app.get("/r/verify-email", response_class=HTMLResponse)
    def verify_email_redirect(
        token: str | None = None, db: Session = Depends(db_session)
    ) -> HTMLResponse:
        # Verify server-side the moment the link is opened, so it works on ANY
        # device (desktop, a different phone) and never depends on the app being
        # installed or a custom-scheme deep link firing. The token is single-use
        # and short-lived; a verified user clicking again still lands on success.
        # `token` is OPTIONAL so a malformed/missing link renders the friendly
        # HTML page below instead of a raw 422 JSON body (what users were seeing).
        # Trade-off: email security scanners/prefetchers may "click" the link and
        # consume the token before the user does. Accepted here because the token
        # is short-lived and the user can always request a fresh one.
        ok = False
        if token:
            try:
                token_payload = decode_token(token)
                if token_payload.get("type") == "verify_email":
                    AuthService(db).verify_email(token_payload=token_payload)
                    ok = True
            except jwt.PyJWTError:
                ok = False
            except Exception:  # noqa: BLE001 - never leak a stack trace to the user
                logger.exception("verify-email link handling failed")
                ok = False
        # Verification is already complete, so the button just opens the app at
        # sign-in via the Android App Link (https://<host>/app/*). On platforms
        # without the app installed it harmlessly opens the website instead — far
        # more reliable than the custom smartbudget:// scheme (unregistered on iOS).
        base = settings.verify_email_deep_link_base
        app_link = (base.rsplit("/", 1)[0] + "/login") if "/app/" in base else base
        return HTMLResponse(_verify_email_result_html(success=ok, app_link=app_link))

    return app


app = create_application()
