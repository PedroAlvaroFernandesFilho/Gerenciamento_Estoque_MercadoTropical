# Sistema de Controle de Estoque - (Mercado Tropical)

Sistema de gestão de estoque para mercados e comércios locais. É composto por uma **API RESTful em FastAPI** e um **aplicativo em Flutter** (web e mobile) que consome essa API.

O sistema controla produtos, quantidades, validades e o histórico de movimentações, e avisa automaticamente sobre itens vencidos, perto do vencimento, com estoque baixo ou sem estoque.

---

## Sumário

- [Tecnologias](#tecnologias)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Como rodar a API](#como-rodar-a-api)
- [Como rodar o aplicativo Flutter](#como-rodar-o-aplicativo-flutter)
- [Rotas da API](#rotas-da-api)
- [Exemplos de requisições](#exemplos-de-requisições)
- [Regras de negócio](#regras-de-negócio)
- [Testes](#testes)
- [Decisões de projeto](#decisões-de-projeto)

---

## Tecnologias

| Parte | Tecnologia |
|---|---|
| Backend | Python, FastAPI, SQLAlchemy, Pydantic |
| Banco de dados | PostgreSQL no Supabase |
| Aplicativo | Flutter (web e Android) |
| Testes | pytest (API) e flutter_test (app) |

---

## Estrutura do repositório

```text
Gerenciamento_Estoque_MercadoTropical/
├── backend_api/
│   ├── app/
│   │   ├── api/            # Rotas (endpoints)
│   │   ├── core/           # Configuração, conexão com o banco e exceções
│   │   ├── models/         # Tabelas do banco (SQLAlchemy)
│   │   ├── repositories/   # Consultas e gravações no banco
│   │   ├── schemas/        # Validação dos dados de entrada e saída (Pydantic)
│   │   ├── services/       # Regras de negócio
│   │   └── main.py         # Ponto de entrada da API
│   ├── tests/              # Testes automatizados da API
│   ├── .env.example        # Modelo do arquivo de configuração
│   └── requirements.txt
└── flutter_mobile/
    └── mercado_tropical_flutter/
        ├── lib/
        │   ├── models/     # Modelos (Produto, Log de movimentação)
        │   ├── provider/   # Estado do app e configurações
        │   ├── service/    # Comunicação HTTP com a API
        │   └── ui/         # Telas, componentes e tema
        └── test/           # Testes do app
```

---

## Como rodar a API

**Pré-requisito:** Python 3.10 ou superior.

1. Entre na pasta da API e instale as dependências:

   ```bash
   cd backend_api
   pip install -r requirements.txt
   ```

2. Crie o arquivo `.env` a partir do modelo `.env.example` e preencha com a conexão do banco:

   ```env
   DATABASE_URL=postgresql://USUARIO:SENHA@HOST:5432/postgres
   EXPIRING_SOON_DAYS=30
   ```

   > O `.env` contém a senha do banco e **não deve ser enviado ao repositório** (ele já está no `.gitignore`).

3. Inicie a API (ainda dentro de `backend_api`):

   ```bash
   uvicorn app.main:app --reload
   ```

4. Acesse:
   - API: `http://127.0.0.1:8000`
   - **Documentação Swagger:** `http://127.0.0.1:8000/docs`

As tabelas são criadas automaticamente no banco na primeira execução.

---

## Como rodar o aplicativo Flutter

**Pré-requisito:** Flutter SDK instalado e a API rodando.

```bash
cd flutter_mobile/mercado_tropical_flutter
flutter pub get
flutter run -d chrome
```

O endereço da API fica em `lib/service/produto_service.dart`:

```dart
static const String _baseUrl = 'http://127.0.0.1:8000';
```

> Para rodar no **celular**, troque `127.0.0.1` pelo IP do computador na rede Wi-Fi (ex.: `http://192.168.0.15:8000`) e inicie a API com `uvicorn app.main:app --host 0.0.0.0`. No emulador Android, use `http://10.0.2.2:8000`.

### Funcionalidades do app

- **Início:** resumo com produtos vencidos, vencendo, com estoque baixo e total cadastrado.
- **Estoque:** lista com filtros (todos, estoque baixo, sem estoque, vencendo, vencidos) e busca por nome. Itens sem estoque aparecem em cinza no final da lista.
- **Entrada:** adiciona unidades a um produto e permite informar a validade do lote; também dá acesso ao cadastro de produto novo.
- **Saída:** retira unidades informando o motivo (venda ou descarte).
- **Cadastro e edição:** padroniza o nome (ex.: "arroz 5kg" → "Arroz 5kg"), escolhe um ícone pelo nome e avisa quando já existe um produto igual ou parecido, sugerindo reativá-lo se estiver desativado.
- **Produtos desativados:** lista os produtos desativados e permite reativá-los.
- **Histórico:** todas as movimentações (cadastro, edição, entrada, saída, desativação e reativação).
- **Configurações:** ativa ou desativa a padronização do nome (no cadastro e na edição) e os ícones automáticos.
- **Acessibilidade:** botão para aumentar o tamanho da letra.

---

## Rotas da API

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/` | Verifica se a API está funcionando |
| `POST` | `/products` | Cadastra um produto |
| `GET` | `/products` | Lista os produtos ativos (aceita `search` e `status`) |
| `GET` | `/products/{id}` | Busca um produto pelo ID |
| `PATCH` | `/products/{id}` | Atualiza os dados de um produto |
| `DELETE` | `/products/{id}` | Desativa um produto (veja [Decisões de projeto](#decisões-de-projeto)) |
| `GET` | `/products/inactive` | Lista os produtos desativados |
| `PATCH` | `/products/{id}/reactivate` | Reativa um produto desativado |
| `POST` | `/products/{id}/entries` | Registra uma entrada no estoque |
| `POST` | `/products/{id}/exits` | Registra uma saída do estoque |
| `GET` | `/stock-movements` | Lista o histórico (aceita `product_id` e `movement_type`) |
| `GET` | `/inventory/summary` | Resumo do estoque |
| `GET` | `/shopping-list` | Produtos que precisam de reposição |

Valores aceitos no filtro `status`: `normal`, `low_stock`, `out_of_stock`, `expiring_soon`, `expired`.

---

## Exemplos de requisições

Os exemplos usam `curl`. Também é possível testar tudo pelo Swagger em `http://127.0.0.1:8000/docs`, no botão **Try it out** de cada rota.

> **No Windows (PowerShell)**, use `curl.exe` em vez de `curl`, e troque as aspas simples do `-d` por aspas duplas com as internas escapadas, ou use o Swagger.

### Cadastrar produto (Create)

```bash
curl -X POST http://127.0.0.1:8000/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Arroz Tipo 1", "quantity": 20, "unit": "pacotes", "minimum_stock": 5, "expiration_date": "2027-03-15"}'
```

Resposta `201 Created`:

```json
{
  "id": 1,
  "name": "Arroz Tipo 1",
  "quantity": 20,
  "unit": "pacotes",
  "icon": "📦",
  "is_active": true,
  "minimum_stock": 5,
  "expiration_date": "2027-03-15",
  "status": "normal",
  "created_at": "2026-11-11T15:00:00",
  "updated_at": "2026-11-11T15:00:00"
}
```

### Listar produtos (Read)

```bash
curl http://127.0.0.1:8000/products
curl "http://127.0.0.1:8000/products?search=arroz"
curl "http://127.0.0.1:8000/products?status=low_stock"
```

### Buscar produto por ID (Read)

```bash
curl http://127.0.0.1:8000/products/1
```

### Atualizar produto (Update)

Só os campos enviados são alterados:

```bash
curl -X PATCH http://127.0.0.1:8000/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Arroz Integral", "minimum_stock": 8}'
```

### Excluir (desativar) produto (Delete)

```bash
curl -X DELETE http://127.0.0.1:8000/products/1
```

Resposta `204 No Content`. O produto deixa de aparecer na listagem e passa a aparecer em `/products/inactive`.

### Reativar produto

```bash
curl -X PATCH http://127.0.0.1:8000/products/1/reactivate
```

### Registrar entrada e saída

```bash
curl -X POST http://127.0.0.1:8000/products/1/entries \
  -H "Content-Type: application/json" \
  -d '{"quantity": 10, "reason": "Reposição"}'

curl -X POST http://127.0.0.1:8000/products/1/exits \
  -H "Content-Type: application/json" \
  -d '{"quantity": 3, "reason": "Venda"}'
```

Resposta `200 OK` (saída):

```json
{
  "movement": {
    "id": 6,
    "product_id": 1,
    "reason": "Venda",
    "movement_type": "exit",
    "quantity": 3,
    "previous_stock": 30,
    "new_stock": 27,
    "created_at": "2026-11-11T15:05:00"
  },
  "product_id": 1,
  "product_name": "Arroz Integral",
  "previous_stock": 30,
  "quantity_moved": 3,
  "new_stock": 27
}
```

### Consultar histórico, resumo e lista de compras

```bash
curl "http://127.0.0.1:8000/stock-movements?product_id=1"
curl http://127.0.0.1:8000/inventory/summary
curl http://127.0.0.1:8000/shopping-list
```

### Respostas de erro

A API devolve mensagens claras quando algo não pode ser feito:

| Situação | Código | Exemplo de resposta |
|---|---|---|
| Produto não existe ou está desativado | `404` | `{"detail": "Produto com ID 99 não encontrado."}` |
| Saída maior que o estoque | `400` | `{"detail": "Estoque insuficiente. Disponível: 3. Solicitado: 5.", "available": 3, "requested": 5}` |
| Dados inválidos (ex.: nome com menos de 3 letras) | `422` | Lista com o campo e o motivo do erro |

---

## Regras de negócio

**Status do produto**, calculado automaticamente nesta ordem de prioridade:

1. **Vencido** (`expired`): a validade é anterior a hoje.
2. **Vencendo logo** (`expiring_soon`): vence nos próximos 30 dias (configurável em `EXPIRING_SOON_DAYS`).
3. **Sem estoque** (`out_of_stock`): quantidade igual a 0.
4. **Estoque baixo** (`low_stock`): quantidade maior que 0 e menor ou igual ao estoque mínimo.
5. **Normal** (`normal`): nenhuma das situações acima.

**Validações:**

- Nome do produto: de 3 a 120 caracteres. Unidade: de 3 a 30 caracteres no cadastro.
- Quantidades: de 0 a 1000 no cadastro; cada entrada ou saída precisa ser de 1 a 1000 unidades.
- Uma saída não pode ser maior que o estoque disponível.
- Produtos desativados não recebem entradas nem saídas.
- Toda operação fica registrada no histórico (`/stock-movements`).

---

## Testes

**API** (dentro de `backend_api`). Os testes usam um banco SQLite em memória e não acessam o Supabase:

```bash
pytest -v
```

**Aplicativo** (dentro de `flutter_mobile/mercado_tropical_flutter`):

```bash
flutter test
```

---

## Decisões de projeto

- **Exclusão lógica (soft delete):** o `DELETE` desativa o produto em vez de apagá-lo do banco. Assim o histórico de movimentações é preservado, e o produto pode ser reativado depois, sem precisar ser cadastrado de novo.
- **Uma validade por produto:** o sistema não controla lotes separados. Para manter o uso simples no dia a dia de um mercado pequeno, cada produto tem uma data de validade, e os alertas de "vencido" e "vencendo logo" cobrem o controle de vencimento.
- **Configurações no aparelho:** as preferências do app (padronização do nome e ícones) ficam salvas em cada dispositivo.
