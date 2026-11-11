"""
Card: [back] [tests-extra] Criar testes automatizados do CRUD de Produto

Testa o ProductService e o ProductRepository direto no banco de teste,
sem passar pelas rotas HTTP.
"""

import pytest
from pydantic import ValidationError
from app.core.exceptions import ProductNotFoundError
from app.models.movement_stock import StockMovement
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductStatus, ProductUpdate
from app.services.product_service import ProductService


def novo_produto(db, **campos):
    dados = {"name": "Arroz Tipo 1", "quantity": 10, "unit": "pacotes", "minimum_stock": 5}
    dados.update(campos)
    return ProductService.create(db, ProductCreate(**dados))


def movimentacoes(db, product_id):
    return db.query(StockMovement).filter_by(product_id=product_id).order_by(StockMovement.id).all()


# ---------- Cadastro ----------
def test_cadastrar_produto_salva_os_dados(db):
    produto = novo_produto(db, name="Feijão Carioca", quantity=20, unit="pacotes", minimum_stock=4)

    assert produto.id is not None
    assert produto.name == "Feijão Carioca"
    assert produto.quantity == 20
    assert produto.unit == "pacotes"
    assert produto.minimum_stock == 4
    assert produto.is_active is True
    assert produto.status == ProductStatus.NORMAL


def test_cadastrar_produto_usa_icone_padrao(db):
    produto = novo_produto(db)
    assert produto.icon == "📦"


def test_cadastrar_produto_remove_espacos_do_nome_e_da_unidade(db):
    produto = novo_produto(db, name="   Café Pilão   ", unit="  pacotes  ")
    assert produto.name == "Café Pilão"
    assert produto.unit == "pacotes"


def test_cadastrar_produto_registra_movimentacao_de_cadastro(db):
    produto = novo_produto(db, quantity=12)

    registros = movimentacoes(db, produto.id)
    assert len(registros) == 1
    assert registros[0].movement_type == "create"
    assert registros[0].quantity == 12
    assert registros[0].previous_stock == 0
    assert registros[0].new_stock == 12


@pytest.mark.parametrize(
    "campos",
    [
        {"name": "ab"},  # nome com menos de 3 letras
        {"name": "     "},  # nome só com espaços
        {"unit": "kg"},  # unidade com menos de 3 letras
        {"quantity": -1},
        {"quantity": 1001},  # acima do limite de 1000
        {"minimum_stock": -1},
        {"minimum_stock": 1001},
        {"name": "A" * 121},  # acima de 120 caracteres
    ],
)
def test_cadastro_recusa_dados_invalidos(campos):
    dados = {"name": "Arroz Tipo 1", "quantity": 10, "unit": "pacotes", "minimum_stock": 5}
    dados.update(campos)
    with pytest.raises(ValidationError):
        ProductCreate(**dados)


# ---------- Consulta ----------
def test_buscar_produto_por_id(db):
    criado = novo_produto(db, name="Leite Integral")
    encontrado = ProductService.get_by_id(db, criado.id)
    assert encontrado.name == "Leite Integral"


def test_buscar_produto_inexistente_gera_erro(db):
    with pytest.raises(ProductNotFoundError):
        ProductService.get_by_id(db, 999)


def test_listar_produtos_em_ordem_alfabetica(db):
    novo_produto(db, name="Macarrao Espaguete")
    novo_produto(db, name="Arroz Tipo 1")
    novo_produto(db, name="Feijao Preto")

    nomes = [p.name for p in ProductService.list_products(db)]
    assert nomes == ["Arroz Tipo 1", "Feijao Preto", "Macarrao Espaguete"]


def test_listar_produtos_com_busca_por_nome(db):
    novo_produto(db, name="Arroz Tipo 1")
    novo_produto(db, name="Arroz Integral")
    novo_produto(db, name="Feijao Preto")

    nomes = [p.name for p in ProductService.list_products(db, search="arroz")]
    assert sorted(nomes) == ["Arroz Integral", "Arroz Tipo 1"]


def test_listar_produtos_filtrando_por_status(db):
    novo_produto(db, name="Arroz Tipo 1", quantity=50, minimum_stock=5)
    novo_produto(db, name="Feijao Preto", quantity=2, minimum_stock=5)

    baixos = ProductService.list_products(db, status=ProductStatus.LOW_STOCK)
    assert [p.name for p in baixos] == ["Feijao Preto"]


# ---------- Edição ----------
def test_editar_nome_e_unidade(db):
    criado = novo_produto(db, name="Arroz Tipo 1", unit="pacotes")
    editado = ProductService.update(db, criado.id, ProductUpdate(name="Arroz Integral", unit="fardos"))

    assert editado.name == "Arroz Integral"
    assert editado.unit == "fardos"


def test_editar_apenas_um_campo_mantem_os_outros(db):
    criado = novo_produto(db, name="Arroz Tipo 1", unit="pacotes", minimum_stock=5)
    editado = ProductService.update(db, criado.id, ProductUpdate(minimum_stock=8))

    assert editado.minimum_stock == 8
    assert editado.name == "Arroz Tipo 1"
    assert editado.unit == "pacotes"


def test_editar_registra_o_que_mudou_no_historico(db):
    criado = novo_produto(db, name="Arroz Tipo 1")
    ProductService.update(db, criado.id, ProductUpdate(name="Arroz Integral"))

    ultimo = movimentacoes(db, criado.id)[-1]
    assert ultimo.movement_type == "update"
    assert ultimo.reason == "name: Arroz Tipo 1 -> Arroz Integral"


def test_editar_produto_inexistente_gera_erro(db):
    with pytest.raises(ProductNotFoundError):
        ProductService.update(db, 999, ProductUpdate(name="Qualquer Nome"))


# ---------- Desativação (soft delete) e reativação ----------
def test_desativar_produto_mantem_o_registro_no_banco(db):
    criado = novo_produto(db)
    ProductService.delete(db, criado.id)

    registro = db.get(Product, criado.id)
    assert registro is not None
    assert registro.is_active is False


def test_produto_desativado_some_da_listagem_e_da_busca(db):
    criado = novo_produto(db)
    ProductService.delete(db, criado.id)

    assert ProductService.list_products(db) == []
    with pytest.raises(ProductNotFoundError):
        ProductService.get_by_id(db, criado.id)


def test_produto_desativado_aparece_na_lista_de_desativados(db):
    criado = novo_produto(db, name="Feijao Preto")
    novo_produto(db, name="Arroz Tipo 1")
    ProductService.delete(db, criado.id)

    desativados = ProductService.list_inactive(db)
    assert [p.name for p in desativados] == ["Feijao Preto"]


def test_desativar_registra_no_historico(db):
    criado = novo_produto(db)
    ProductService.delete(db, criado.id)
    assert movimentacoes(db, criado.id)[-1].movement_type == "deactivate"


def test_editar_produto_desativado_gera_erro(db):
    criado = novo_produto(db)
    ProductService.delete(db, criado.id)
    with pytest.raises(ProductNotFoundError):
        ProductService.update(db, criado.id, ProductUpdate(name="Outro Nome"))


def test_desativar_produto_ja_desativado_gera_erro(db):
    criado = novo_produto(db)
    ProductService.delete(db, criado.id)
    with pytest.raises(ProductNotFoundError):
        ProductService.delete(db, criado.id)


def test_reativar_produto(db):
    criado = novo_produto(db, quantity=7)
    ProductService.delete(db, criado.id)

    reativado = ProductService.reactivate(db, criado.id)

    assert reativado.is_active is True
    assert reativado.quantity == 7
    assert [p.id for p in ProductService.list_products(db)] == [criado.id]
    assert ProductService.list_inactive(db) == []
    assert movimentacoes(db, criado.id)[-1].movement_type == "activate"


def test_reativar_produto_inexistente_gera_erro(db):
    with pytest.raises(ProductNotFoundError):
        ProductService.reactivate(db, 999)
