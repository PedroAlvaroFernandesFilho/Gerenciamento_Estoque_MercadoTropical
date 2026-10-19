from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ProductStatus(str, Enum):
    NORMAL = "normal"
    LOW_STOCK = "low_stock"
    EXPIRING_SOON = "expiring_soon"
    EXPIRED = "expired"


class ProductCreate(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    quantity: int = Field(default=0, ge=0)
    unit: str = Field(min_length=1, max_length=30)
    minimum_stock: int = Field(default=0, ge=0)
    expiration_date: date | None = None

    @field_validator("name", "unit")
    @classmethod
    def strip_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("O campo não pode ficar vazio.")
        return value


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=120)
    quantity: int | None = Field(default=None, ge=0)
    unit: str | None = Field(default=None, min_length=1, max_length=30)
    minimum_stock: int | None = Field(default=None, ge=0)
    expiration_date: date | None = None

    @field_validator("name", "unit")
    @classmethod
    def strip_optional_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("O campo não pode ficar vazio.")
        return value


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    quantity: int
    unit: str
    minimum_stock: int
    expiration_date: date | None
    status: ProductStatus
    created_at: datetime
    updated_at: datetime
