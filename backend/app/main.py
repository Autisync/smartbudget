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
        return _reset_password_page_html(token=token)

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
