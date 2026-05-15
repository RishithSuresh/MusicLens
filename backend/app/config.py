from __future__ import annotations

import os
from dataclasses import dataclass

DEFAULT_DEV_ORIGINS = (
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:5000",
    "http://127.0.0.1:5000",
)


def _parse_list(value: str | None) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(",") if item.strip()]


def _parse_bool(value: str | None, *, default: bool) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _parse_int(value: str | None, *, default: int) -> int:
    if value is None:
        return default
    try:
        return int(value)
    except ValueError:
        return default


@dataclass(frozen=True)
class Settings:
    runtime_env: str
    log_level: str
    cors_origins: list[str]
    max_upload_bytes: int
    max_prompt_chars: int
    enable_compose: bool
    enable_lyrics: bool
    request_id_header: str

    @property
    def is_production(self) -> bool:
        return self.runtime_env.lower() == "production"

    @property
    def has_wildcard_cors(self) -> bool:
        return any(origin == "*" for origin in self.cors_origins)

    @classmethod
    def from_env(cls) -> Settings:
        runtime_env = os.getenv("MUSICLENS_ENV", "development").strip().lower() or "development"
        origins = _parse_list(os.getenv("MUSICLENS_CORS_ORIGINS"))

        if not origins:
            origins = ["*"] if runtime_env != "production" else list(DEFAULT_DEV_ORIGINS)

        return cls(
            runtime_env=runtime_env,
            log_level=os.getenv("MUSICLENS_LOG_LEVEL", "INFO").upper(),
            cors_origins=origins,
            max_upload_bytes=max(1024 * 1024, _parse_int(os.getenv("MUSICLENS_MAX_UPLOAD_BYTES"), default=20 * 1024 * 1024)),
            max_prompt_chars=max(200, _parse_int(os.getenv("MUSICLENS_MAX_PROMPT_CHARS"), default=500)),
            enable_compose=_parse_bool(os.getenv("MUSICLENS_ENABLE_COMPOSE"), default=True),
            enable_lyrics=_parse_bool(os.getenv("MUSICLENS_ENABLE_LYRICS"), default=True),
            request_id_header=os.getenv("MUSICLENS_REQUEST_ID_HEADER", "X-Request-ID"),
        )


settings = Settings.from_env()
