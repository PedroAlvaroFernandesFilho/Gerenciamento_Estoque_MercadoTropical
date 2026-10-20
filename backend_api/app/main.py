from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.inventory_routes import router as inventory_router
from app.api.movement_routes import router as movement_router
from app.api.product_routes import router as product_router
from app.core.config import settings
from app.core.database import Base, engine
from app.core.exceptions import InsufficientStockError, ProductNotFoundError
from app import models  # noqa: F401
from fastapi.middleware.cors import CORSMiddleware

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description=(
        "API RESTful para gerenciamento de produtos e movimentações "
        "de estoque do Mercado Tropical, utilizando PostgreSQL no Supabase."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(ProductNotFoundError)
async def product_not_found_handler(request: Request, exc: ProductNotFoundError) -> JSONResponse:
    return JSONResponse(status_code=404, content={"detail": str(exc)})

@app.exception_handler(InsufficientStockError)
async def insufficient_stock_handler(request: Request, exc: InsufficientStockError) -> JSONResponse:
    return JSONResponse(
        status_code=400,
        content={
            "detail": str(exc),
            "available": exc.available,
            "requested": exc.requested,
        },
    )

@app.get("/", tags=["Health"], summary="Verificar funcionamento da API")
def health_check() -> dict[str, str]:
    return {
        "message": "Mercado Tropical API funcionando.",
        "database": "Supabase PostgreSQL",
        "docs": "/docs",
    }

app.include_router(product_router)
app.include_router(movement_router)
app.include_router(inventory_router)