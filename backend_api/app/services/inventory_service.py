from sqlalchemy.orm import Session

from app.repositories.product_repository import ProductRepository
from app.schemas.inventory import InventorySummaryResponse, ShoppingListItem
from app.schemas.product import ProductStatus
from app.services.product_service import ProductService

class InventoryService:
    @staticmethod
    def summary(db: Session) -> InventorySummaryResponse:
        products = ProductRepository.get_all(db)
        statuses = [ProductService.calculate_status(product) for product in products]

        low_stock = sum(status == ProductStatus.LOW_STOCK for status in statuses)
        expiring = sum(status == ProductStatus.EXPIRING_SOON for status in statuses)
        expired = sum(status == ProductStatus.EXPIRED for status in statuses)

        shopping_items = sum(
            product.quantity <= product.minimum_stock
            for product in products
        )

        return InventorySummaryResponse(
            total_items=len(products),
            low_stock=low_stock,
            expiring_soon=expiring,
            expired=expired,
            shopping_items=shopping_items,
        )

    @staticmethod
    def shopping_list(db: Session) -> list[ShoppingListItem]:
        products = ProductRepository.get_all(db)

        result = []
        for product in products:
            if product.quantity <= product.minimum_stock:
                result.append(
                    ShoppingListItem(
                        id=product.id,
                        name=product.name,
                        quantity=product.quantity,
                        minimum_stock=product.minimum_stock,
                        unit=product.unit,
                        suggested_purchase=max(
                            0,
                            product.minimum_stock - product.quantity,
                        ),
                    )
                )

        return result