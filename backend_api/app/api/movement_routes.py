from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.movement import (
    MovementType,
    StockMovementCreate,
    StockMovementResponse,
    StockOperationResponse,
)
from app.services.movement_service import MovementService


router = APIRouter(
    tags=["Stock Movements"],
)


@router.post(
    "/products/{product_id}/entries",
    response_model=StockOperationResponse,
    summary="Registrar entrada de itens no estoque",
)
def register_entry(
    product_id: int,
    data: StockMovementCreate,
    db: Session = Depends(get_db),
) -> StockOperationResponse:
    return MovementService.register_entry(db, product_id, data)


@router.post(
    "/products/{product_id}/exits",
    response_model=StockOperationResponse,
    summary="Registrar saída de itens do estoque",
)
def register_exit(
    product_id: int,
    data: StockMovementCreate,
    db: Session = Depends(get_db),
) -> StockOperationResponse:
    return MovementService.register_exit(db, product_id, data)


@router.get(
    "/stock-movements",
    response_model=list[StockMovementResponse],
    summary="Listar histórico de movimentações",
)
def list_movements(
    product_id: int | None = None,
    movement_type: MovementType | None = None,
    db: Session = Depends(get_db),
) -> list[StockMovementResponse]:
    return MovementService.list_movements(
        db=db,
        product_id=product_id,
        movement_type=movement_type,
    )
