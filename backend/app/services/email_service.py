import logging
import smtplib
from email.message import EmailMessage
from pathlib import Path
from urllib.parse import urlencode

from app.core.config import settings

logger = logging.getLogger(__name__)
TEMPLATE_DIR = Path(__file__).resolve().parents[1] / 'templates' / 'emails'


class EmailService:
    def _render_html_template(self, template_name: str, context: dict[str, str]) -> str:
        template_path = TEMPLATE_DIR / template_name
        html = template_path.read_text(encoding='utf-8')
        rendered = html
        for key, value in context.items():
            rendered = rendered.replace(f'{{{{{key}}}}}', str(value))
        return rendered

    def _base_context(self, *, user_name: str, action_url: str) -> dict[str, str]:
        return {
            'user_name': user_name,
            'app_name': settings.app_name,
            'action_url': action_url,
            'support_email': settings.smtp_from_email,
            'company_name': settings.smtp_from_name,
            'year': '2026',
        }

    def _build_link(self, base_url: str, token: str) -> str:
        separator = '&' if '?' in base_url else '?'
        return f"{base_url}{separator}{urlencode({'token': token})}"

    def _send_email(self, *, to_email: str, subject: str, text_body: str, html_body: str) -> None:
        message = EmailMessage()
        message['Subject'] = subject
        message['From'] = f"{settings.smtp_from_name} <{settings.smtp_from_email}>"
        message['To'] = to_email
        message.set_content(text_body)
        message.add_alternative(html_body, subtype='html')

        if not settings.smtp_enabled:
            logger.info(
                "SMTP disabled. Email not sent. to=%s subject=%s body_preview=%s",
                to_email,
                subject,
                text_body,
            )
            return

        try:
            if settings.smtp_use_ssl:
                with smtplib.SMTP_SSL(settings.smtp_host, settings.smtp_port, timeout=20) as server:
                    if settings.smtp_username:
                        server.login(settings.smtp_username, settings.smtp_password)
                    server.send_message(message)
            else:
                with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=20) as server:
                    if settings.smtp_use_tls:
                        server.starttls()
                    if settings.smtp_username:
                        server.login(settings.smtp_username, settings.smtp_password)
                    server.send_message(message)
        except Exception:
            logger.exception("SMTP send failed for to=%s subject=%s", to_email, subject)
            raise

    def send_verification_email(self, *, email: str, token: str) -> None:
        verification_link = self._build_link(settings.verify_email_deep_link_base, token)
        context = self._base_context(user_name='there', action_url=verification_link)
        html_body = self._render_html_template('email_verification.html', context)
        subject = 'Verify your SmartBudget email'
        text_body = f'Use this link to verify your email: {verification_link}'
        self._send_email(
            to_email=email,
            subject=subject,
            text_body=text_body,
            html_body=html_body,
        )

    def send_password_reset_email(self, *, email: str, token: str) -> None:
        reset_link = self._build_link(settings.reset_password_deep_link_base, token)
        context = self._base_context(user_name='there', action_url=reset_link)
        context['expiration_minutes'] = '30'
        html_body = self._render_html_template('password_reset.html', context)
        subject = 'Reset your SmartBudget password'
        text_body = f'Use this link to reset your password: {reset_link}'
        self._send_email(
            to_email=email,
            subject=subject,
            text_body=text_body,
            html_body=html_body,
        )

    def send_welcome_email(self, *, email: str, user_name: str, action_url: str) -> None:
        context = self._base_context(user_name=user_name, action_url=action_url)
        html_body = self._render_html_template('welcome_email.html', context)
        self._send_email(
            to_email=email,
            subject=f'Welcome to {settings.app_name}',
            text_body=f'Welcome to {settings.app_name}. Get started: {action_url}',
            html_body=html_body,
        )

    def send_login_alert_email(
        self,
        *,
        email: str,
        user_name: str,
        action_url: str,
        device: str,
        location: str,
        login_time: str,
    ) -> None:
        context = self._base_context(user_name=user_name, action_url=action_url)
        context.update({'device': device, 'location': location, 'login_time': login_time})
        html_body = self._render_html_template('login_alert.html', context)
        self._send_email(
            to_email=email,
            subject='New login detected',
            text_body=f'New login detected. Review activity: {action_url}',
            html_body=html_body,
        )

    def send_notification_email(
        self,
        *,
        email: str,
        user_name: str,
        action_url: str,
        notification_title: str,
        notification_message: str,
    ) -> None:
        context = self._base_context(user_name=user_name, action_url=action_url)
        context.update(
            {
                'notification_title': notification_title,
                'notification_message': notification_message,
            }
        )
        html_body = self._render_html_template('notification_email.html', context)
        self._send_email(
            to_email=email,
            subject=notification_title,
            text_body=f'{notification_message} Open: {action_url}',
            html_body=html_body,
        )

    def send_billing_subscription_email(
        self,
        *,
        email: str,
        user_name: str,
        action_url: str,
        amount: str,
        billing_date: str,
        plan_name: str,
    ) -> None:
        context = self._base_context(user_name=user_name, action_url=action_url)
        context.update({'amount': amount, 'billing_date': billing_date, 'plan_name': plan_name})
        html_body = self._render_html_template('billing_subscription.html', context)
        self._send_email(
            to_email=email,
            subject='Payment सफल / Invoice',
            text_body=f'Payment processed. Amount: {amount}. View invoice: {action_url}',
            html_body=html_body,
        )
