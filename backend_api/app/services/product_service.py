from datetime import date, timedelta

from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import ProductNotFoundError
from app.models.product import Product
from app.repositories.product_repository import ProductRepository
from app.schemas.product import (
    ProductCreate,
    ProductResponse,
    ProductStatus,
    ProductUpdate,
)

class ProductService:
    @staticmethod
    def calculate_status(product: Product) -> ProductStatus:
        today = date.today()

        if product.expiration_date is not None:
            if product.expiration_date < today:
                return ProductStatus.EXPIRED

            if product.expiration_date <= today + timedelta(
                days=settings.expiring_soon_days
            ):
                return ProductStatus.EXPIRING_SOON

        if product.quantity == 0:
            return ProductStatus.OUT_OF_STOCK

        if product.quantity <= product.minimum_stock:
            return ProductStatus.LOW_STOCK

        return ProductStatus.NORMAL

    @classmethod
    def to_response(cls, product: Product) -> ProductResponse:
        return ProductResponse(
            id=product.id,
            name=product.name,
            quantity=product.quantity,
            unit=product.unit,
            icon=product.icon,
            minimum_stock=product.minimum_stock,
            expiration_date=product.expiration_date,
            status=cls.calculate_status(product),
            created_at=product.created_at,
            updated_at=product.updated_at,
        )

    @classmethod
    def create(cls, db: Session, data: ProductCreate) -> ProductResponse:
        product = ProductRepository.create(db, data)
        return cls.to_response(product)

    @classmethod
    def get_by_id(cls, db: Session, product_id: int) -> ProductResponse:
        product = ProductRepository.get_by_id(db, product_id)
        if product is None:
            raise ProductNotFoundError(product_id)
        return cls.to_response(product)

    @classmethod
    def get_model_by_id(cls, db: Session, product_id: int) -> Product:
        product = ProductRepository.get_by_id(db, product_id)
        if product is None:
            raise ProductNotFoundError(product_id)
        return product

    @classmethod
    def list_products(
        cls,
        db: Session,
        search: str | None = None,
        status: ProductStatus | None = None,
    ) -> list[ProductResponse]:
        if search:
            products = ProductRepository.search_by_name(db, search)
        else:
            products = ProductRepository.get_all(db)

        responses = [cls.to_response(product) for product in products]

        if status is not None:
            responses = [product for product in responses if product.status == status]

        return responses

    @classmethod
    def update(
        cls,
        db: Session,
        product_id: int,
        data: ProductUpdate,
    ) -> ProductResponse:
        product = cls.get_model_by_id(db, product_id)
        updated = ProductRepository.update(db, product, data)
        return cls.to_response(updated)

    @classmethod
    def delete(cls, db: Session, product_id: int) -> None:
        product = cls.get_model_by_id(db, product_id)
        ProductRepository.delete(db, product)