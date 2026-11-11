"""
Card: [back] [tests-extra] Criar testes das regras de estoque

Regras testadas:
- cálculo do status (vencido, vencendo, sem estoque, estoque baixo, normal) e a prioridade entre eles;
- entradas e saídas (contas, saldo insuficiente, produto desativado, histórico);
- resumo do estoque e lista de compras.
"""

from datetime import date, timedelta
import pytest
from pydantic import ValidationError
from app.core.exceptions import InsufficientStockError, ProductNotFoundError
from app.models.movement_stock import StockMovement
from app.models.product import Product
from app.schemas.movement import StockMovementCreate
from app.schemas.product import ProductCreate, ProductStatus
from app.services.inventory_service import InventoryService
from app.services.movement_service import MovementService
from app.services.product_service import ProductService

HOJE = date.today()


def status_de(quantidade, minimo, validade=None):
    produto = Product(name="Teste", quantity=quantidade, minimum_stock=minimo, unit="pacotes", expiration_date=validade)
    return ProductService.calculate_status(produto)


def novo_produto(db, **campos):
    dados = {"name": "Arroz Tipo 1", "quantity": 10, "unit": "pacotes", "minimum_stock": 5}
    dados.update(campos)
    return ProductService.create(db, ProductCreate(**dados))


def entrada(db, product_id, quantidade, motivo=None):
    return MovementService.register_entry(db, product_id, StockMovementCreate(quantity=quantidade, reason=motivo))


def saida(db, product_id, quantidade, motivo=None):
    return MovementService.register_exit(db, product_id, StockMovementCreate(quantity=quantidade, reason=motivo))


# ---------- Status do produto ----------
def test_status_normal_quando_acima_do_minimo_e_sem_validade():
    assert status_de(quantidade=10, minimo=5) == ProductStatus.NORMAL


def test_status_estoque_baixo_quando_igual_ao_minimo():
    assert status_de(quantidade=5, minimo=5) == ProductStatus.LOW_STOCK


def test_status_estoque_baixo_quando_abaixo_do_minimo():
    assert status_de(quantidade=2, minimo=5) == ProductStatus.LOW_STOCK


def test_status_sem_estoque_quando_quantidade_zero():
    assert status_de(quantidade=0, minimo=5) == ProductStatus.OUT_OF_STOCK


def test_sem_estoque_tem_prioridade_sobre_estoque_baixo():
    # 0 também é "menor ou igual ao mínimo", mas deve aparecer como sem estoque
    assert status_de(quantidade=0, minimo=0) == ProductStatus.OUT_OF_STOCK


def test_status_vencido_quando_validade_ja_passou():
    assert status_de(quantidade=10, minimo=5, validade=HOJE - timedelta(days=1)) == ProductStatus.EXPIRED


def test_vence_hoje_ainda_nao_esta_vencido():
    assert status_de(quantidade=10, minimo=5, validade=HOJE) == ProductStatus.EXPIRING_SOON


@pytest.mark.parametrize("dias", [1, 15, 30])
def test_status_vencendo_logo_ate_30_dias(dias):
    assert status_de(quantidade=10, minimo=5, validade=HOJE + timedelta(days=dias)) == ProductStatus.EXPIRING_SOON


def test_com_31_dias_ou_mais_nao_esta_vencendo_logo():
    assert status_de(quantidade=10, minimo=5, validade=HOJE + timedelta(days=31)) == ProductStatus.NORMAL


def test_vencido_tem_prioridade_sobre_sem_estoque_e_estoque_baixo():
    ontem = HOJE - timedelta(days=1)
    assert status_de(quantidade=0, minimo=5, validade=ontem) == ProductStatus.EXPIRED
    assert status_de(quantidade=3, minimo=5, validade=ontem) == ProductStatus.EXPIRED


def test_vencendo_logo_tem_prioridade_sobre_estoque_baixo():
    assert status_de(quantidade=3, minimo=5, validade=HOJE + timedelta(days=5)) == ProductStatus.EXPIRING_SOON


# ---------- Entradas ----------
def test_entrada_soma_ao_estoque(db):
    produto = novo_produto(db, quantity=10)
    resultado = entrada(db, produto.id, 5)

    assert resultado.previous_stock == 10
    assert resultado.quantity_moved == 5
    assert resultado.new_stock == 15
    assert ProductService.get_by_id(db, produto.id).quantity == 15


def test_entrada_registra_no_historico_com_motivo(db):
    produto = novo_produto(db, quantity=10)
    entrada(db, produto.id, 5, motivo="Reposição")

    registro = db.query(StockMovement).filter_by(product_id=produto.id, movement_type="entry").one()
    assert registro.quantity == 5
    assert registro.previous_stock == 10
    assert registro.new_stock == 15
    assert registro.reason == "Reposição"


def test_entrada_em_produto_desativado_gera_erro(db):
    produto = novo_produto(db)
    ProductService.delete(db, produto.id)
    with pytest.raises(ProductNotFoundError):
        entrada(db, produto.id, 5)


def test_entrada_em_produto_inexistente_gera_erro(db):
    with pytest.raises(ProductNotFoundError):
        entrada(db, 999, 5)


# ---------- Saídas ----------
def test_saida_subtrai_do_estoque(db):
    produto = novo_produto(db, quantity=10)
    resultado = saida(db, produto.id, 4, motivo="Venda")

    assert resultado.previous_stock == 10
    assert resultado.new_stock == 6
    assert ProductService.get_by_id(db, produto.id).quantity == 6


def test_saida_de_todo_o_estoque_deixa_produto_sem_estoque(db):
    produto = novo_produto(db, quantity=3)
    saida(db, produto.id, 3)

    atualizado = ProductService.get_by_id(db, produto.id)
    assert atualizado.quantity == 0
    assert atualizado.status == ProductStatus.OUT_OF_STOCK


def test_saida_maior_que_o_estoque_gera_erro_e_nao_altera_nada(db):
    produto = novo_produto(db, quantity=3)

    with pytest.raises(InsufficientStockError) as erro:
        saida(db, produto.id, 4)

    assert erro.value.available == 3
    assert erro.value.requested == 4
    assert ProductService.get_by_id(db, produto.id).quantity == 3
    assert db.query(StockMovement).filter_by(product_id=produto.id, movement_type="exit").count() == 0


def test_saida_em_produto_desativado_gera_erro(db):
    produto = novo_produto(db)
    ProductService.delete(db, produto.id)
    with pytest.raises(ProductNotFoundError):
        saida(db, produto.id, 1)


def test_saida_deixa_produto_com_estoque_baixo(db):
    produto = novo_produto(db, quantity=10, minimum_stock=5)
    saida(db, produto.id, 6)
    assert ProductService.get_by_id(db, produto.id).status == ProductStatus.LOW_STOCK


@pytest.mark.parametrize(
    "campos",
    [
        {"quantity": 0},
        {"quantity": -5},
        {"quantity": 1001},  # acima do limite de 1000 por operação
        {"quantity": 1, "reason": "x" * 61},  # motivo acima de 60 caracteres
    ],
)
def test_movimentacao_recusa_dados_invalidos(campos):
    with pytest.raises(ValidationError):
        StockMovementCreate(**campos)


def test_sequencia_de_entradas_e_saidas(db):
    produto = novo_produto(db, quantity=10)
    entrada(db, produto.id, 20)
    saida(db, produto.id, 5)
    entrada(db, produto.id, 3)
    saida(db, produto.id, 28)

    assert ProductService.get_by_id(db, produto.id).quantity == 0


# ---------- Resumo e lista de compras ----------
def test_resumo_do_estoque(db):
    novo_produto(db, name="Arroz Tipo 1", quantity=50, minimum_stock=5)  # normal
    novo_produto(db, name="Feijao Preto", quantity=2, minimum_stock=5)  # baixo
    novo_produto(db, name="Leite Integral", quantity=10, minimum_stock=5,
                 expiration_date=HOJE + timedelta(days=3))  # vencendo
    novo_produto(db, name="Iogurte Natural", quantity=10, minimum_stock=5,
                 expiration_date=HOJE - timedelta(days=2))  # vencido
    desativado = novo_produto(db, name="Sabao em Po", quantity=1, minimum_stock=5)
    ProductService.delete(db, desativado.id)  # não deve entrar no resumo

    resumo = InventoryService.summary(db)

    assert resumo.total_items == 4
    assert resumo.low_stock == 1
    assert resumo.expiring_soon == 1
    assert resumo.expired == 1
    assert resumo.shopping_items == 1


def test_lista_de_compras_sugere_o_que_falta_para_o_minimo(db):
    novo_produto(db, name="Arroz Tipo 1", quantity=50, minimum_stock=5)
    novo_produto(db, name="Feijao Preto", quantity=2, minimum_stock=8)

    lista = InventoryService.shopping_list(db)

    assert len(lista) == 1
    assert lista[0].name == "Feijao Preto"
    assert lista[0].suggested_purchase == 6
