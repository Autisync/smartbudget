from urllib.parse import urlencode

from app.core.config import settings


def build_link(base_url: str, token: str) -> str:
    separator = '&' if '?' in base_url else '?'
    return f"{base_url}{separator}{urlencode({'token': token})}"


def main() -> None:
    sample_token = "sample-token"
    reset_link = build_link(settings.reset_password_deep_link_base, sample_token)
    verify_link = build_link(settings.verify_email_deep_link_base, sample_token)

    print("Auth link preview using current environment settings")
    print(f"RESET_PASSWORD_DEEP_LINK_BASE: {settings.reset_password_deep_link_base}")
    print(f"VERIFY_EMAIL_DEEP_LINK_BASE:  {settings.verify_email_deep_link_base}")
    print()
    print(f"Reset password link: {reset_link}")
    print(f"Verify email link:   {verify_link}")


if __name__ == "__main__":
    main()
