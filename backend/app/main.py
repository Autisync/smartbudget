import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings

logger = logging.getLogger(__name__)


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
    return app


app = create_application()
