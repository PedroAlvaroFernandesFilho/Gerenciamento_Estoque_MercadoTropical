from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.movement_stock import StockMovement

class MovementRepository:

    @staticmethod
    def create(
        db: Session,
        product_id: int,
        movement_type: str,
        quantity: int,
        previous_stock: int,
        new_stock: int,
    ) -> StockMovement:
        movement = StockMovement(
            product_id=product_id,
            movement_type=movement_type,
            quantity=quantity,
            previous_stock=previous_stock,
            new_stock=new_stock,
        )
        db.add(movement)
        db.commit()
        db.refresh(movement)
        return movement

    @staticmethod
    def get_all(
        db: Session,
        product_id: int | None = None,
        movement_type: str | None = None,
    ) -> list[StockMovement]:
        stmt = select(StockMovement)

        if product_id is not None:
            stmt = stmt.where(StockMovement.product_id == product_id)

        if movement_type is not None:
            stmt = stmt.where(StockMovement.movement_type == movement_type)

        stmt = stmt.order_by(StockMovement.created_at.desc(), StockMovement.id.desc())
        return list(db.scalars(stmt).all())
