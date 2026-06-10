"""Celery tasks for all transactional email delivery.

Every email type is a separate task so:
  • SMTP never blocks an HTTP request path (signup/login/reset take < 1 ms).
  • Failed sends are automatically retried with exponential back-off.
  • Individual email failures are isolated — a broken SMTP connection
    cannot cause a 500 on /signup or /login.

Usage from synchronous code (auth_service.py etc.):

    from app.tasks.email import send_verification_email_task
    send_verification_email_task.delay(
        email=user.email, token=token, user_name=user.first_name
    )

All tasks use `ignore_result=True` — callers never await the return value.
"""

import logging

from app.core.celery_app import celery_app
from app.services.email_service import EmailService

logger = logging.getLogger(__name__)

_RETRY_KWARGS = dict(
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_backoff_max=120,
    max_retries=3,
    ignore_result=True,
)


@celery_app.task(name="app.tasks.email.send_verification_email", **_RETRY_KWARGS)
def send_verification_email_task(*, email: str, token: str, user_name: str = "there") -> None:
    EmailService().send_verification_email(email=email, token=token, user_name=user_name)


@celery_app.task(name="app.tasks.email.send_password_reset_email", **_RETRY_KWARGS)
def send_password_reset_email_task(*, email: str, token: str, user_name: str = "there") -> None:
    EmailService().send_password_reset_email(email=email, token=token, user_name=user_name)


@celery_app.task(name="app.tasks.email.send_welcome_email", **_RETRY_KWARGS)
def send_welcome_email_task(*, email: str, user_name: str, action_url: str) -> None:
    EmailService().send_welcome_email(email=email, user_name=user_name, action_url=action_url)


@celery_app.task(name="app.tasks.email.send_login_alert_email", **_RETRY_KWARGS)
def send_login_alert_email_task(
    *,
    email: str,
    user_name: str,
    action_url: str,
    device: str,
    location: str,
    login_time: str,
) -> None:
    EmailService().send_login_alert_email(
        email=email,
        user_name=user_name,
        action_url=action_url,
        device=device,
        location=location,
        login_time=login_time,
    )


@celery_app.task(name="app.tasks.email.send_duplicate_signup_alert_email", **_RETRY_KWARGS)
def send_duplicate_signup_alert_email_task(
    *,
    email: str,
    user_name: str,
    attempt_time: str,
) -> None:
    """Sent to the existing account holder when a signup attempt is made with
    their email. Fires asynchronously so it never adds latency to the
    (deliberately generic) signup response."""
    EmailService().send_duplicate_signup_alert_email(
        email=email,
        user_name=user_name,
        attempt_time=attempt_time,
    )


@celery_app.task(name="app.tasks.email.send_notification_email", **_RETRY_KWARGS)
def send_notification_email_task(
    *,
    email: str,
    user_name: str,
    action_url: str,
    notification_title: str,
    notification_message: str,
) -> None:
    EmailService().send_notification_email(
        email=email,
        user_name=user_name,
        action_url=action_url,
        notification_title=notification_title,
        notification_message=notification_message,
    )
