from functools import lru_cache

from redis import Redis
from redis.asyncio import Redis as AsyncRedis

from app.core.config import settings


@lru_cache(maxsize=1)
def get_redis() -> Redis:
    return Redis.from_url(settings.redis_url, decode_responses=True)


@lru_cache(maxsize=1)
def get_async_redis() -> AsyncRedis:
    return AsyncRedis.from_url(settings.redis_url, decode_responses=True)
