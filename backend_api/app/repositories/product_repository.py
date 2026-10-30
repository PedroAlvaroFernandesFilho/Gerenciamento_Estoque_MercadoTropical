from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.product import Product
from app.schemas.product import ProductCreate, ProductUpdate

class ProductRepository:
    @staticmethod
    def create(db: Session, data: ProductCreate) -> Product:
        product = Product(**data.model_dump(), is_active=True)
        db.add(product)
        db.commit()
        db.refresh(product)
        return product

    @staticmethod
    def get_all(db: Session, search: str | None = None) -> list[Product]:
        stmt = select(Product).where(Product.is_active.is_(True)).order_by(Product.name.asc())

        if search:
            stmt = stmt.where(Product.name.ilike(f"%{search.strip()}%"))

        return list(db.scalars(stmt).all())

    @staticmethod
    def get_by_id(db: Session, product_id: int) -> Product | None:
        stmt = select(Product).where(
            Product.id == product_id,
            Product.is_active.is_(True),
        )
        return db.scalars(stmt).first()

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
        product.is_active = False
        db.add(product)
        db.commit()

    @staticmethod
    def get_inactive(db: Session) -> list[Product]:
        stmt = select(Product).where(Product.is_active.is_(False)).order_by(Product.name.asc())
        return list(db.scalars(stmt).all())