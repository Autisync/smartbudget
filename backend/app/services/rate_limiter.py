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

    def check_action(
        self,
        action: str,
        key: str,
        *,
        max_attempts: int,
        window_seconds: int,
    ) -> bool:
        """Generic fixed-window limiter for sensitive actions such as resending
        verification or reset emails. Returns False once the caller exceeds
        ``max_attempts`` within ``window_seconds``."""
        bucket_key = f"rate-limit:{action}:{key}"
        value = self.redis.incr(bucket_key)
        if value == 1:
            self.redis.expire(bucket_key, window_seconds)
        return value <= max_attempts
