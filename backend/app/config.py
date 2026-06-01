from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    database_url: str = "postgresql+asyncpg://kundliai:kundliai_dev@db:5432/kundliai"
    postgres_db: str = "kundliai"
    postgres_user: str = "kundliai"
    postgres_password: str = "kundliai_dev"

    # Redis / Celery
    redis_url: str = "redis://redis:6379/0"

    # Firebase
    firebase_service_account_json: str = "{}"

    # OpenAI
    openai_api_key: str = ""

    # Razorpay
    razorpay_key_id: str = ""
    razorpay_key_secret: str = ""
    razorpay_webhook_secret: str = ""
    razorpay_plan_id_monthly: str = ""

    # Meta / WhatsApp
    meta_whatsapp_token: str = ""
    meta_phone_number_id: str = ""
    meta_template_daily_en: str = "daily_horoscope_en"
    meta_template_daily_hi: str = "daily_horoscope_hi"

    # Google Geocoding
    google_geocoding_api_key: str = ""

    # Meta webhook verification token (set when registering webhook in Meta dashboard)
    meta_webhook_verify_token: str = "kundliai_whatsapp_verify"

    # App
    secret_key: str = "dev-secret-key-change-in-production"
    environment: str = "development"
    log_level: str = "info"
    admin_api_key: str = "dev-admin-key-change-in-production"

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

    @property
    def celery_broker_url(self) -> str:
        return self.redis_url

    @property
    def celery_result_backend(self) -> str:
        return self.redis_url


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
