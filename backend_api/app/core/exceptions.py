class ProductNotFoundError(Exception):
    def __init__(self, product_id: int):
        self.product_id = product_id
        super().__init__(f"Produto com ID {product_id} não encontrado.")


class InsufficientStockError(Exception):
    def __init__(self, available: int, requested: int):
        self.available = available
        self.requested = requested
        super().__init__(
            f"Estoque insuficiente. Disponível: {available}. Solicitado: {requested}."
        )
