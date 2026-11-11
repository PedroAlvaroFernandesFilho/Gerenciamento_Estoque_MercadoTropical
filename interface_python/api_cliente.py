"""
Cliente HTTP da API do Mercado Tropical.

Usa só a biblioteca padrão do Python (urllib), então não precisa instalar nada.
O endereço da API pode ser trocado pela variável de ambiente MERCADO_API_URL.
"""

import json
import os
from urllib import error, parse, request

URL_PADRAO = os.environ.get("MERCADO_API_URL", "http://127.0.0.1:8000")

# Nomes dos campos da API como aparecem para o usuário nas mensagens de erro
NOMES_CAMPOS = {
    "name": "Nome",
    "unit": "Unidade",
    "quantity": "Quantidade",
    "minimum_stock": "Estoque mínimo",
    "expiration_date": "Validade",
    "reason": "Motivo",
}


class ErroApi(Exception):
    """Erro devolvido pela API (ou falha de conexão), já com mensagem em português."""

    def __init__(self, mensagem: str, status: int | None = None):
        super().__init__(mensagem)
        self.status = status


class ApiCliente:
    def __init__(self, url_base: str = URL_PADRAO, timeout: float = 10):
        self.url_base = url_base.rstrip("/")
        self.timeout = timeout
        # Ignora proxies do sistema: a API normalmente roda na própria máquina
        self._abridor = request.build_opener(request.ProxyHandler({}))

    # ---------- Produtos (CRUD) ----------

    def listar_produtos(self, busca: str | None = None, status: str | None = None) -> list[dict]:
        return self._requisitar("GET", "/products", params={"search": busca, "status": status})

    def buscar_produto(self, produto_id: int) -> dict:
        return self._requisitar("GET", f"/products/{produto_id}")

    def cadastrar_produto(self, dados: dict) -> dict:
        return self._requisitar("POST", "/products", dados=dados)

    def atualizar_produto(self, produto_id: int, dados: dict) -> dict:
        return self._requisitar("PATCH", f"/products/{produto_id}", dados=dados)

    def excluir_produto(self, produto_id: int) -> None:
        self._requisitar("DELETE", f"/products/{produto_id}")

    # ---------- Desativados ----------

    def listar_desativados(self) -> list[dict]:
        return self._requisitar("GET", "/products/inactive")

    def reativar_produto(self, produto_id: int) -> dict:
        return self._requisitar("PATCH", f"/products/{produto_id}/reactivate")

    # ---------- Movimentações ----------

    def registrar_entrada(self, produto_id: int, quantidade: int, motivo: str | None = None) -> dict:
        return self._requisitar(
            "POST", f"/products/{produto_id}/entries", dados={"quantity": quantidade, "reason": motivo or None}
        )

    def registrar_saida(self, produto_id: int, quantidade: int, motivo: str | None = None) -> dict:
        return self._requisitar(
            "POST", f"/products/{produto_id}/exits", dados={"quantity": quantidade, "reason": motivo or None}
        )

    def historico(self, produto_id: int | None = None) -> list[dict]:
        return self._requisitar("GET", "/stock-movements", params={"product_id": produto_id})

    # ---------- Comunicação ----------

    def _requisitar(self, metodo: str, caminho: str, dados: dict | None = None, params: dict | None = None):
        url = self.url_base + caminho
        if params:
            filtrados = {chave: valor for chave, valor in params.items() if valor not in (None, "")}
            if filtrados:
                url += "?" + parse.urlencode(filtrados)

        corpo = json.dumps(dados).encode("utf-8") if dados is not None else None
        req = request.Request(
            url,
            data=corpo,
            method=metodo,
            headers={"Content-Type": "application/json", "Accept": "application/json"},
        )

        try:
            with self._abridor.open(req, timeout=self.timeout) as resposta:
                conteudo = resposta.read()
                return json.loads(conteudo.decode("utf-8")) if conteudo else None
        except error.HTTPError as erro:
            raise ErroApi(self._mensagem_de_erro(erro), erro.code) from None
        except (error.URLError, TimeoutError, ConnectionError, OSError):
            raise ErroApi(
                f"Não foi possível conectar à API em {self.url_base}.\nVerifique se ela está rodando."
            ) from None

    @staticmethod
    def _mensagem_de_erro(erro: error.HTTPError) -> str:
        try:
            corpo = json.loads(erro.read().decode("utf-8"))
        except (ValueError, UnicodeDecodeError):
            return f"Erro {erro.code} na API."

        detalhe = corpo.get("detail") if isinstance(corpo, dict) else None

        # 400 e 404: a API já manda a mensagem pronta
        if isinstance(detalhe, str):
            return detalhe

        # 422: lista de campos inválidos
        if isinstance(detalhe, list):
            linhas = [ApiCliente._traduzir_validacao(item) for item in detalhe]
            return "Dados inválidos:\n" + "\n".join(f"• {linha}" for linha in linhas)

        return f"Erro {erro.code} na API."

    @staticmethod
    def _traduzir_validacao(item: dict) -> str:
        local = item.get("loc") or []
        campo = NOMES_CAMPOS.get(str(local[-1]), str(local[-1])) if local else "Campo"
        tipo = item.get("type", "")
        ctx = item.get("ctx") or {}

        if tipo == "missing":
            texto = "é obrigatório"
        elif tipo == "less_than_equal":
            texto = f"deve ser no máximo {ctx.get('le')}"
        elif tipo == "greater_than_equal":
            texto = f"deve ser no mínimo {ctx.get('ge')}"
        elif tipo == "greater_than":
            texto = f"deve ser maior que {ctx.get('gt')}"
        elif tipo == "string_too_long":
            texto = f"deve ter no máximo {ctx.get('max_length')} caracteres"
        elif tipo == "string_too_short":
            texto = f"deve ter no mínimo {ctx.get('min_length')} caracteres"
        elif tipo.startswith("date"):
            texto = "data inválida"
        elif tipo.startswith("int"):
            texto = "deve ser um número inteiro"
        else:
            # Mensagens criadas nos validadores da API (ex: "Value error, O campo...")
            texto = str(item.get("msg", "valor inválido")).removeprefix("Value error, ")

        return f"{campo}: {texto}"
