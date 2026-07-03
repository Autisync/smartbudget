from redis import Redis

from app.core.config import settings


class RateLimiterService:
    def __init__(self, redis_client: Redis):
        self.redis = redis_client

    def check_once(self, action: str, key: str, *, max_attempts: int, window_seconds: int) -> bool:
        return self.check_action(
            action,
            key,
            max_attempts=max_attempts,
            window_seconds=window_seconds,
        )

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

    # Atomic two-tier limiter executed server-side so the cap check and the
    # increment can't race across concurrent requests. Returns {status, ttl}.
    _RESEND_LUA = """
    local count = tonumber(redis.call('GET', KEYS[1]) or '0')
    if count >= tonumber(ARGV[1]) then
        local ttl = redis.call('TTL', KEYS[1])
        if ttl < 0 then ttl = tonumber(ARGV[2]) end
        return {'hour', ttl}
    end
    if not redis.call('SET', KEYS[2], '1', 'NX', 'EX', ARGV[3]) then
        local ttl = redis.call('TTL', KEYS[2])
        if ttl < 0 then ttl = tonumber(ARGV[3]) end
        return {'minute', ttl}
    end
    local value = redis.call('INCR', KEYS[1])
    if value == 1 then redis.call('EXPIRE', KEYS[1], ARGV[2]) end
    return {'ok', 0}
    """

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
        is hit. Only increments the hourly counter when the send is allowed.

        Runs as a single Lua script so the read-check-increment sequence is
        atomic — concurrent resend requests can't both slip past the cap."""
        hour_key = f"rate-limit:resend_verification:{key}"
        gap_key = f"rate-limit:resend_verification_gap:{key}"
        status, ttl = self.redis.eval(
            self._RESEND_LUA,
            2,
            hour_key,
            gap_key,
            max_per_window,
            window_seconds,
            min_gap_seconds,
        )
        # decode_responses may leave status as bytes depending on client config.
        if isinstance(status, bytes):
            status = status.decode()
        return (status, int(ttl))
