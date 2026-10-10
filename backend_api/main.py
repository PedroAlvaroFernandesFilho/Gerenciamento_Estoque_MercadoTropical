from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
from sqlalchemy import create_engine, Column, Integer, String, Boolean
from sqlalchemy.orm import declarative_base, sessionmaker, Session

DATABASE_URL = "postgresql://postgres.cwgzaxrerzylahqgbfrn:29!Market09!Tropical2026!-00@aws-0-sa-east-1.pooler.supabase.com:5432/postgres"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class TarefaDB(Base):
    __tablename__ = "tarefas"
    id = Column(Integer, primary_key=True, index=True)
    titulo = Column(String, nullable=False)
    concluida = Column(Boolean, default=False)

# Cria a tabela 'tarefas' automaticamente no Supabase ao iniciar a API pela primeira vez
Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- MODELOS DE DADOS (Pydantic) ---
class TarefaCreate(BaseModel):
    titulo: str
    concluida: bool = False

class TarefaResponse(TarefaCreate):
    id: int
    class Config:
        from_attributes = True

# --- APLICAÇÃO FASTAPI ---
app = FastAPI(title="API de Tarefas - Supabase & FastAPI", version="1.0.0")

# Libera o CORS para permitir requisições do Flutter e da interface Python Desktop
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. CREATE (Criar Tarefa)
@app.post("/tarefas", response_model=TarefaResponse, status_code=201)
def criar_tarefa(tarefa: TarefaCreate, db: Session = Depends(get_db)):
    nova_tarefa = TarefaDB(titulo=tarefa.titulo, concluida=tarefa.concluida)
    db.add(nova_tarefa)
    db.commit()
    db.refresh(nova_tarefa)
    return nova_tarefa

# 2. READ ALL (Listar todas as Tarefas)
@app.get("/tarefas", response_model=List[TarefaResponse])
def listar_tarefas(db: Session = Depends(get_db)):
    return db.query(TarefaDB).all()

# 3. READ ONE (Buscar Tarefa por ID)
@app.get("/tarefas/{tarefa_id}", response_model=TarefaResponse)
def buscar_tarefa(tarefa_id: int, db: Session = Depends(get_db)):
    tarefa = db.query(TarefaDB).filter(TarefaDB.id == tarefa_id).first()
    if not tarefa:
        raise HTTPException(status_code=404, detail="Tarefa não encontrada")
    return tarefa

# 4. UPDATE (Atualizar Tarefa)
@app.put("/tarefas/{tarefa_id}", response_model=TarefaResponse)
def atualizar_tarefa(tarefa_id: int, dados: TarefaCreate, db: Session = Depends(get_db)):
    tarefa = db.query(TarefaDB).filter(TarefaDB.id == tarefa_id).first()
    if not tarefa:
        raise HTTPException(status_code=404, detail="Tarefa não encontrada")
    tarefa.titulo = dados.titulo
    tarefa.concluida = dados.concluida
    db.commit()
    db.refresh(tarefa)
    return tarefa

# 5. DELETE (Excluir Tarefa)
@app.delete("/tarefas/{tarefa_id}", status_code=204)
def deletar_tarefa(tarefa_id: int, db: Session = Depends(get_db)):
    tarefa = db.query(TarefaDB).filter(TarefaDB.id == tarefa_id).first()
    if not tarefa:
        raise HTTPException(status_code=404, detail="Tarefa não encontrada")
    db.delete(tarefa)
    db.commit()
    return None