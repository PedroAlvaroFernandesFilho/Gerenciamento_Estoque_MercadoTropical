from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.inventory import InventorySummaryResponse, ShoppingListItem
from app.services.inventory_service import InventoryService

router = APIRouter(
    tags=["Inventory"],
)

@router.get(
    "/inventory/summary",
    response_model=InventorySummaryResponse,
    summary="Obter resumo da quantidade de estoque",
)
def inventory_summary(
    db: Session = Depends(get_db),
) -> InventorySummaryResponse:
    return InventoryService.summary(db)


@router.get(
    "/shopping-list",
    response_model=list[ShoppingListItem],
    summary="Listar produtos que precisam de reposição",
)
def shopping_list(
    db: Session = Depends(get_db),
) -> list[ShoppingListItem]:
    return InventoryService.shopping_list(db)
