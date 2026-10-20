from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "Mercado Tropical API"
    database_url: str = "postgresql://postgres.cwgzaxrerzylahqgbfrn:29!Market09!Tropical2026!-00@aws-0-sa-east-1.pooler.supabase.com:5432/postgres"
    expiring_soon_days: int = 30

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()
