from sqlalchemy.orm import Session

from app.core.exceptions import InsufficientStockError
from app.repositories.movement_repository import MovementRepository
from app.schemas.movement import (
    MovementType,
    StockMovementCreate,
    StockMovementResponse,
    StockOperationResponse,
)
from app.services.product_service import ProductService

class MovementService:
    @staticmethod
    def register_entry(
        db: Session,
        product_id: int,
        data: StockMovementCreate,
    ) -> StockOperationResponse:
        product = ProductService.get_model_by_id(db, product_id)

        previous = product.quantity
        product.quantity += data.quantity
        new_stock = product.quantity

        movement = MovementRepository.create(
            db=db,
            product_id=product.id,
            movement_type=MovementType.ENTRY.value,
            quantity=data.quantity,
            previous_stock=previous,
            new_stock=new_stock,
        )

        db.add(product)
        db.commit()
        db.refresh(product)

        return StockOperationResponse(
            movement=StockMovementResponse.model_validate(movement),
            product_id=product.id,
            product_name=product.name,
            previous_stock=previous,
            quantity_moved=data.quantity,
            new_stock=new_stock,
        )

    @staticmethod
    def register_exit(
        db: Session,
        product_id: int,
        data: StockMovementCreate,
    ) -> StockOperationResponse:
        product = ProductService.get_model_by_id(db, product_id)

        if data.quantity > product.quantity:
            raise InsufficientStockError(
                available=product.quantity,
                requested=data.quantity,
            )

        previous = product.quantity
        product.quantity -= data.quantity
        new_stock = product.quantity

        movement = MovementRepository.create(
            db=db,
            product_id=product.id,
            movement_type=MovementType.EXIT.value,
            quantity=data.quantity,
            previous_stock=previous,
            new_stock=new_stock,
        )

        db.add(product)
        db.commit()
        db.refresh(product)

        return StockOperationResponse(
            movement=StockMovementResponse.model_validate(movement),
            product_id=product.id,
            product_name=product.name,
            previous_stock=previous,
            quantity_moved=data.quantity,
            new_stock=new_stock,
        )

    @staticmethod
    def list_movements(
        db: Session,
        product_id: int | None = None,
        movement_type: MovementType | None = None,
    ) -> list[StockMovementResponse]:
        movements = MovementRepository.get_all(
            db=db,
            product_id=product_id,
            movement_type=movement_type.value if movement_type else None,
        )
        return [
            StockMovementResponse.model_validate(movement)
            for movement in movements
        ]