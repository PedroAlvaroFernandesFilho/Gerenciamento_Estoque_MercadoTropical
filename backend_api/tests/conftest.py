"""
Configuração compartilhada dos testes da API.

Os testes usam um banco SQLite em memória, criado do zero a cada teste:
não acessam o Supabase e não precisam do arquivo .env.
"""

import os
import sys
from pathlib import Path

# A API exige DATABASE_URL ao ser importada; aqui ela aponta para SQLite em memória.
# EXPIRING_SOON_DAYS fixo em 30 para os testes não dependerem do .env de cada máquina.
os.environ["DATABASE_URL"] = "sqlite://"
os.environ["EXPIRING_SOON_DAYS"] = "30"

# Permite "import app" rodando o pytest de dentro da pasta backend_api
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app.core.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture
def engine():
    # StaticPool: todas as sessões do teste usam o mesmo banco em memória
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()


@pytest.fixture
def sessao_factory(engine):
    return sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)


@pytest.fixture
def db(sessao_factory):
    """Sessão do banco para testar services e repositories diretamente."""
    sessao = sessao_factory()
    yield sessao
    sessao.close()


@pytest.fixture
def client(sessao_factory):
    """Cliente HTTP da API usando o banco de teste no lugar do Supabase."""

    def get_db_teste():
        sessao = sessao_factory()
        try:
            yield sessao
        finally:
            sessao.close()

    app.dependency_overrides[get_db] = get_db_teste
    with TestClient(app) as cliente:
        yield cliente
    app.dependency_overrides.clear()


@pytest.fixture
def criar_produto(client):
    """Cadastra um produto pela API e devolve o JSON da resposta."""

    def _criar(**campos):
        dados = {
            "name": "Arroz Tipo 1",
            "quantity": 10,
            "unit": "pacotes",
            "minimum_stock": 5,
            "expiration_date": None,
        }
        dados.update(campos)
        resposta = client.post("/products", json=dados)
        assert resposta.status_code == 201, resposta.text
        return resposta.json()

    return _criar
