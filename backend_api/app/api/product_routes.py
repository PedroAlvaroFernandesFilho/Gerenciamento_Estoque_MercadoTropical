from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.product import (
    ProductCreate,
    ProductResponse,
    ProductStatus,
    ProductUpdate,
)
from app.services.product_service import ProductService


router = APIRouter(
    prefix="/products",
    tags=["Products"],
)


@router.post(
    "",
    response_model=ProductResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Cadastrar produto",
)
def create_product(
    data: ProductCreate,
    db: Session = Depends(get_db),
) -> ProductResponse:
    return ProductService.create(db, data)


@router.get(
    "",
    response_model=list[ProductResponse],
    summary="Listar produtos",
)
def list_products(
    search: str | None = None,
    status_filter: ProductStatus | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
) -> list[ProductResponse]:
    return ProductService.list_products(
        db=db,
        search=search,
        status=status_filter,
    )


@router.get(
    "/{product_id}",
    response_model=ProductResponse,
    summary="Buscar produto por ID",
)
def get_product(
    product_id: int,
    db: Session = Depends(get_db),
) -> ProductResponse:
    return ProductService.get_by_id(db, product_id)


@router.patch(
    "/{product_id}",
    response_model=ProductResponse,
    summary="Atualizar produto",
)
def update_product(
    product_id: int,
    data: ProductUpdate,
    db: Session = Depends(get_db),
) -> ProductResponse:
    return ProductService.update(db, product_id, data)


@router.delete(
    "/{product_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Excluir produto",
)
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
) -> Response:
    ProductService.delete(db, product_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
