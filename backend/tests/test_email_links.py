"""Guards the verification/reset email links.

Regression cover for the bug where the verification link reached the server
without its `token`, producing a raw 422. These assert the token is always
present (and correctly URL-encoded) in both the HTML and the plain-text body.
"""

from urllib.parse import parse_qs, urlparse

import pytest

from app.services.email_service import EmailService

# A token with characters that must survive URL-encoding.
SAMPLE_TOKEN = "eyJhbGciOi.J9.sig-with_special=chars&stuff"


class _CapturingEmailService(EmailService):
    """Captures what would be sent instead of hitting SMTP."""

    def __init__(self):
        self.sent = []

    def _send_email(self, *, to_email, subject, text_body, html_body):
        self.sent.append(
            {
                "to": to_email,
                "subject": subject,
                "text": text_body,
                "html": html_body,
            }
        )


def _token_in(url_string: str) -> str | None:
    """Extract the `token` query param from the first URL-looking token."""
    for chunk in url_string.replace('"', " ").replace("'", " ").split():
        if "token=" in chunk and "://" in chunk:
            qs = parse_qs(urlparse(chunk).query)
            if "token" in qs:
                return qs["token"][0]
    return None


def test_build_link_appends_token():
    svc = EmailService()
    link = svc._build_link("https://api.example.com/r/verify-email", SAMPLE_TOKEN)
    assert "token=" in link
    assert parse_qs(urlparse(link).query)["token"][0] == SAMPLE_TOKEN


def test_build_link_handles_base_with_existing_query():
    svc = EmailService()
    link = svc._build_link("https://api.example.com/r/verify-email?ref=x", SAMPLE_TOKEN)
    qs = parse_qs(urlparse(link).query)
    assert qs["token"][0] == SAMPLE_TOKEN
    assert qs["ref"][0] == "x"


def test_verification_email_contains_token_in_html_and_text():
    svc = _CapturingEmailService()
    svc.send_verification_email(email="a@b.com", token=SAMPLE_TOKEN, user_name="A")
    assert len(svc.sent) == 1
    msg = svc.sent[0]
    # plain-text body carries the full link with token
    assert _token_in(msg["text"]) == SAMPLE_TOKEN
    # HTML body's action button href carries the token too
    assert _token_in(msg["html"]) == SAMPLE_TOKEN


def test_password_reset_email_contains_token():
    svc = _CapturingEmailService()
    svc.send_password_reset_email(email="a@b.com", token=SAMPLE_TOKEN, user_name="A")
    msg = svc.sent[0]
    assert _token_in(msg["text"]) == SAMPLE_TOKEN
    assert _token_in(msg["html"]) == SAMPLE_TOKEN


@pytest.mark.parametrize("token", ["", "   "])
def test_blank_token_is_obvious_in_link(token):
    # Defensive: a blank token must NOT silently produce a tokenless URL that
    # looks valid — token= will be present but empty, which the route treats as
    # an invalid link (friendly page) rather than verifying.
    svc = EmailService()
    link = svc._build_link("https://api.example.com/r/verify-email", token)
    assert "token=" in link
