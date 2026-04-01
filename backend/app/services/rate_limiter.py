from redis import Redis

from app.core.config import settings


class RateLimiterService:
    def __init__(self, redis_client: Redis):
        self.redis = redis_client

    def check_login_attempts(self, key: str) -> bool:
        bucket_key = f"rate-limit:login:{key}"
        value = self.redis.incr(bucket_key)
        if value == 1:
            self.redis.expire(bucket_key, settings.login_rate_limit_window_seconds)
        return value <= settings.login_rate_limit_max_attempts
