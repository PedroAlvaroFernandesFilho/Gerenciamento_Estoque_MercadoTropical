"""
Card: [API] [tests] Criar testes de integração da API

Chama as rotas HTTP de verdade (com o banco de teste) e confere
códigos de resposta, validações e o fluxo completo de uso.
"""

from datetime import date, timedelta

# ---------- Saúde da API ----------
def test_api_esta_no_ar(client):
    resposta = client.get("/")
    assert resposta.status_code == 200
    assert "message" in resposta.json()


# ---------- Produtos ----------
def test_cadastrar_produto(client):
    resposta = client.post(
        "/products",
        json={"name": "Arroz Tipo 1", "quantity": 10, "unit": "pacotes", "minimum_stock": 5,
              "expiration_date": "2030-12-31"},
    )
    assert resposta.status_code == 201
    corpo = resposta.json()
    assert corpo["id"] > 0
    assert corpo["name"] == "Arroz Tipo 1"
    assert corpo["expiration_date"] == "2030-12-31"
    assert corpo["status"] == "normal"


def test_cadastro_com_dados_invalidos_retorna_422(client):
    invalidos = [
        {"name": "ab", "unit": "pacotes"},
        {"name": "Arroz Tipo 1", "unit": "kg"},
        {"name": "Arroz Tipo 1", "unit": "pacotes", "quantity": 1001},
        {"name": "Arroz Tipo 1", "unit": "pacotes", "quantity": -1},
        {"unit": "pacotes"},  # sem nome
    ]
    for dados in invalidos:
        assert client.post("/products", json=dados).status_code == 422, dados


def test_listar_produtos(client, criar_produto):
    criar_produto(name="Feijao Preto")
    criar_produto(name="Arroz Tipo 1")

    resposta = client.get("/products")
    assert resposta.status_code == 200
    assert [p["name"] for p in resposta.json()] == ["Arroz Tipo 1", "Feijao Preto"]


def test_listar_produtos_com_busca(client, criar_produto):
    criar_produto(name="Arroz Tipo 1")
    criar_produto(name="Feijao Preto")

    resposta = client.get("/products", params={"search": "feij"})
    assert [p["name"] for p in resposta.json()] == ["Feijao Preto"]


def test_listar_produtos_por_status(client, criar_produto):
    criar_produto(name="Arroz Tipo 1", quantity=0)
    criar_produto(name="Feijao Preto", quantity=50)

    resposta = client.get("/products", params={"status": "out_of_stock"})
    assert [p["name"] for p in resposta.json()] == ["Arroz Tipo 1"]


def test_buscar_produto_por_id(client, criar_produto):
    produto = criar_produto(name="Leite Integral")
    resposta = client.get(f"/products/{produto['id']}")
    assert resposta.status_code == 200
    assert resposta.json()["name"] == "Leite Integral"


def test_buscar_produto_inexistente_retorna_404(client):
    resposta = client.get("/products/999")
    assert resposta.status_code == 404
    assert "999" in resposta.json()["detail"]


def test_buscar_produto_com_id_invalido_retorna_422(client):
    assert client.get("/products/abc").status_code == 422


def test_editar_produto(client, criar_produto):
    produto = criar_produto(name="Arroz Tipo 1", unit="pacotes")
    resposta = client.patch(f"/products/{produto['id']}", json={"name": "Arroz Integral", "unit": "fardos"})

    assert resposta.status_code == 200
    assert resposta.json()["name"] == "Arroz Integral"
    assert resposta.json()["unit"] == "fardos"


def test_editar_nao_desativa_produto_pelo_campo_is_active(client, criar_produto):
    # Desativar é só pelo DELETE; o campo is_active é ignorado na edição
    produto = criar_produto()
    client.patch(f"/products/{produto['id']}", json={"is_active": False})
    assert client.get(f"/products/{produto['id']}").status_code == 200


def test_editar_produto_inexistente_retorna_404(client):
    assert client.patch("/products/999", json={"name": "Outro Nome"}).status_code == 404


# ---------- Desativar e reativar ----------
def test_desativar_produto(client, criar_produto):
    produto = criar_produto()
    resposta = client.delete(f"/products/{produto['id']}")

    assert resposta.status_code == 204
    assert client.get(f"/products/{produto['id']}").status_code == 404
    assert client.get("/products").json() == []


def test_listar_desativados(client, criar_produto):
    # Também garante que a rota /inactive vem antes de /{product_id}
    produto = criar_produto(name="Feijao Preto")
    client.delete(f"/products/{produto['id']}")

    resposta = client.get("/products/inactive")
    assert resposta.status_code == 200
    assert [p["name"] for p in resposta.json()] == ["Feijao Preto"]


def test_reativar_produto(client, criar_produto):
    produto = criar_produto(quantity=7)
    client.delete(f"/products/{produto['id']}")

    resposta = client.patch(f"/products/{produto['id']}/reactivate")

    assert resposta.status_code == 200
    assert resposta.json()["quantity"] == 7
    assert client.get(f"/products/{produto['id']}").status_code == 200
    assert client.get("/products/inactive").json() == []


def test_reativar_produto_inexistente_retorna_404(client):
    assert client.patch("/products/999/reactivate").status_code == 404


# ---------- Entradas e saídas ----------
def test_registrar_entrada(client, criar_produto):
    produto = criar_produto(quantity=10)
    resposta = client.post(f"/products/{produto['id']}/entries", json={"quantity": 5, "reason": "Reposição"})

    assert resposta.status_code == 200
    corpo = resposta.json()
    assert corpo["previous_stock"] == 10
    assert corpo["new_stock"] == 15
    assert corpo["movement"]["movement_type"] == "entry"
    assert corpo["movement"]["reason"] == "Reposição"


def test_registrar_saida(client, criar_produto):
    produto = criar_produto(quantity=10)
    resposta = client.post(f"/products/{produto['id']}/exits", json={"quantity": 4, "reason": "Venda"})

    assert resposta.status_code == 200
    assert resposta.json()["new_stock"] == 6


def test_saida_maior_que_o_estoque_retorna_400(client, criar_produto):
    produto = criar_produto(quantity=3)
    resposta = client.post(f"/products/{produto['id']}/exits", json={"quantity": 4})

    assert resposta.status_code == 400
    corpo = resposta.json()
    assert corpo["available"] == 3
    assert corpo["requested"] == 4
    assert client.get(f"/products/{produto['id']}").json()["quantity"] == 3


def test_movimentacao_invalida_retorna_422(client, criar_produto):
    produto = criar_produto()
    rota = f"/products/{produto['id']}/entries"
    assert client.post(rota, json={"quantity": 0}).status_code == 422
    assert client.post(rota, json={"quantity": 1001}).status_code == 422
    assert client.post(rota, json={"quantity": 1, "reason": "x" * 61}).status_code == 422


def test_movimentacao_em_produto_desativado_retorna_404(client, criar_produto):
    produto = criar_produto()
    client.delete(f"/products/{produto['id']}")
    assert client.post(f"/products/{produto['id']}/entries", json={"quantity": 1}).status_code == 404
    assert client.post(f"/products/{produto['id']}/exits", json={"quantity": 1}).status_code == 404


# ---------- Histórico ----------
def test_historico_registra_todo_o_ciclo_do_produto(client, criar_produto):
    produto = criar_produto(quantity=10)
    pid = produto["id"]
    client.post(f"/products/{pid}/entries", json={"quantity": 5})
    client.post(f"/products/{pid}/exits", json={"quantity": 3})
    client.patch(f"/products/{pid}", json={"name": "Arroz Integral"})
    client.delete(f"/products/{pid}")
    client.patch(f"/products/{pid}/reactivate")

    resposta = client.get("/stock-movements", params={"product_id": pid})
    assert resposta.status_code == 200
    tipos = [m["movement_type"] for m in resposta.json()]
    # Mais recente primeiro
    assert tipos == ["activate", "deactivate", "update", "exit", "entry", "create"]


def test_historico_filtrado_por_tipo(client, criar_produto):
    produto = criar_produto(quantity=10)
    client.post(f"/products/{produto['id']}/entries", json={"quantity": 5})
    client.post(f"/products/{produto['id']}/exits", json={"quantity": 2})

    resposta = client.get("/stock-movements", params={"movement_type": "exit"})
    corpo = resposta.json()
    assert len(corpo) == 1
    assert corpo[0]["quantity"] == 2


# ---------- Resumo e lista de compras ----------
def test_resumo_do_estoque(client, criar_produto):
    hoje = date.today()
    criar_produto(name="Arroz Tipo 1", quantity=50, minimum_stock=5)
    criar_produto(name="Feijao Preto", quantity=2, minimum_stock=5)
    criar_produto(name="Iogurte Natural", quantity=10, expiration_date=(hoje - timedelta(days=1)).isoformat())

    resposta = client.get("/inventory/summary")
    assert resposta.status_code == 200
    corpo = resposta.json()
    assert corpo["total_items"] == 3
    assert corpo["low_stock"] == 1
    assert corpo["expired"] == 1


def test_lista_de_compras(client, criar_produto):
    criar_produto(name="Arroz Tipo 1", quantity=50, minimum_stock=5)
    criar_produto(name="Feijao Preto", quantity=1, minimum_stock=6)

    resposta = client.get("/shopping-list")
    assert resposta.status_code == 200
    corpo = resposta.json()
    assert [item["name"] for item in corpo] == ["Feijao Preto"]
    assert corpo[0]["suggested_purchase"] == 5
