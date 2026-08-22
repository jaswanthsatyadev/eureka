from typing import List, Optional
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application Settings adhering to Pydantic v2 BaseSettings.
    Reads environment variables from system or .env file.
    """
    # Environment & Server
    ENVIRONMENT: str = Field(default="development", description="Runtime environment")
    BACKEND_HOST: str = Field(default="0.0.0.0", description="Backend host bind")
    BACKEND_PORT: int = Field(default=8000, description="Backend port")
    LOG_LEVEL: str = Field(default="INFO", description="Logging verbosity")
    CORS_ORIGINS: str = Field(
        default="http://localhost:3000,http://127.0.0.1:3000",
        description="Comma-separated CORS origins"
    )

    # Supabase Credentials (Database & Auth)
    SUPABASE_URL: str = Field(default="", description="Supabase project URL")
    SUPABASE_ANON_KEY: str = Field(default="", description="Supabase anonymous key")
    SUPABASE_SERVICE_ROLE_KEY: str = Field(default="", description="Supabase service role secret")
    SUPABASE_JWT_SECRET: Optional[str] = Field(default=None, description="Supabase JWT secret for verification")

    # AI Model Provider (Google Gemini API Only - Free Tier for MVP)
    GEMINI_API_KEY: Optional[str] = Field(default=None, description="Google Gemini API key from AI Studio")
    GEMINI_FAST_MODEL: str = Field(default="gemini-2.0-flash", description="Fast model for requirements/search")
    GEMINI_REASONING_MODEL: str = Field(
        default="gemini-2.0-flash",
        description="Reasoning model for circuit construction & editing"
    )

    # Cloudflare R2 Storage (Only Storage Provider)
    R2_ACCOUNT_ID: Optional[str] = Field(default=None, description="Cloudflare Account ID")
    R2_ACCESS_KEY_ID: Optional[str] = Field(default=None, description="R2 S3 Access Key ID")
    R2_SECRET_ACCESS_KEY: Optional[str] = Field(default=None, description="R2 S3 Secret Access Key")
    R2_ENDPOINT: Optional[str] = Field(default=None, description="R2 custom S3 endpoint")
    R2_PUBLIC_ASSET_BUCKET: str = Field(default="eureka-public-assets", description="Public component SVG assets")
    R2_PUBLIC_ASSET_URL: Optional[str] = Field(default=None, description="Public CDN domain for assets")
    R2_PRIVATE_OUTPUT_BUCKET: str = Field(default="eureka-private-outputs", description="Private PDF/ZIP exports")

    # AI Run Bounds (Convention #11)
    AI_MAX_TOOL_CALLS: int = Field(default=25, description="Max tool calls per LangGraph run")
    AI_RUN_TIMEOUT_SECONDS: int = Field(default=180, description="Max execution time per AI run in seconds")

    model_config = SettingsConfigDict(
        env_file=(".env", "apps/backend/.env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

    @property
    def cors_origin_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


settings = Settings()
