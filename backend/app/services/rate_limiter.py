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

    def check_resend(
        self,
        key: str,
        *,
        max_per_window: int = 3,
        window_seconds: int = 3600,
        min_gap_seconds: int = 60,
    ) -> tuple[str, int]:
        """Two-tier limiter for verification-email resends: up to
        ``max_per_window`` per hour, with at least ``min_gap_seconds`` between
        each. Returns ('ok', 0) when allowed, ('minute', secs_left) when the
        per-send gap hasn't elapsed, or ('hour', secs_left) when the hourly cap
        is hit. Only increments the hourly counter when the send is allowed."""
        hour_key = f"rate-limit:resend_verification:{key}"
        gap_key = f"rate-limit:resend_verification_gap:{key}"

        count = int(self.redis.get(hour_key) or 0)
        if count >= max_per_window:
            ttl = self.redis.ttl(hour_key)
            return ("hour", ttl if ttl and ttl > 0 else window_seconds)

        # SET NX EX succeeds only if no gap key exists (>= min_gap since last send).
        if not self.redis.set(gap_key, "1", nx=True, ex=min_gap_seconds):
            ttl = self.redis.ttl(gap_key)
            return ("minute", ttl if ttl and ttl > 0 else min_gap_seconds)

        value = self.redis.incr(hour_key)
        if value == 1:
            self.redis.expire(hour_key, window_seconds)
        return ("ok", 0)
