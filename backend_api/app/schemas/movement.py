from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field


class MovementType(str, Enum):
    ENTRY = "entry"
    EXIT = "exit"


class StockMovementCreate(BaseModel):
    quantity: int = Field(gt=0)


class StockMovementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    product_id: int
    movement_type: MovementType
    quantity: int
    previous_stock: int
    new_stock: int
    created_at: datetime


class StockOperationResponse(BaseModel):
    movement: StockMovementResponse
    product_id: int
    product_name: str
    previous_stock: int
    quantity_moved: int
    new_stock: int
