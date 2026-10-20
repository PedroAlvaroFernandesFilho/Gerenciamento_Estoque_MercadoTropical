from pydantic import BaseModel

from app.schemas.product import ProductResponse

class InventorySummaryResponse(BaseModel):
    total_items: int
    low_stock: int
    expiring_soon: int
    expired: int
    shopping_items: int

class ShoppingListItem(BaseModel):
    id: int
    name: str
    quantity: int
    minimum_stock: int
    unit: str
    suggested_purchase: int