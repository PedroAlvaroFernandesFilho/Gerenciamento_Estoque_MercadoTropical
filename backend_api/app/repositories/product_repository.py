from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.product import Product
from app.schemas.product import ProductCreate, ProductUpdate


class ProductRepository:
    @staticmethod
    def create(db: Session, data: ProductCreate) -> Product:
        product = Product(**data.model_dump())
        db.add(product)
        db.commit()
        db.refresh(product)
        return product

    @staticmethod
    def get_all(db: Session) -> list[Product]:
        stmt = select(Product).order_by(Product.name.asc())
        return list(db.scalars(stmt).all())

    @staticmethod
    def get_by_id(db: Session, product_id: int) -> Product | None:
        return db.get(Product, product_id)

    @staticmethod
    def update(db: Session, product: Product, data: ProductUpdate) -> Product:
        values = data.model_dump(exclude_unset=True)
        for field, value in values.items():
            setattr(product, field, value)

        db.add(product)
        db.commit()
        db.refresh(product)
        return product

    @staticmethod
    def delete(db: Session, product: Product) -> None:
        db.delete(product)
        db.commit()

    @staticmethod
    def search_by_name(db: Session, search: str) -> list[Product]:
        stmt = (
            select(Product)
            .where(Product.name.ilike(f"%{search.strip()}%"))
            .order_by(Product.name.asc())
        )
        return list(db.scalars(stmt).all())
