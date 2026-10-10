import tkinter as tk
from tkinter import messagebox
import requests

# URL base da nossa API FastAPI rodando localmente
API_URL = "http://127.0.0.1:8000"

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Painel Desktop - Tarefas FastAPI")
        self.geometry("450x420")
        self.tarefas_cache = []

        # --- CAMPO DE CADASTRO ---
        tk.Label(self, text="Título da Nova Tarefa:", font=("Arial", 10, "bold")).pack(pady=5)
        self.entry_titulo = tk.Entry(self, width=45, font=("Arial", 11))
        self.entry_titulo.pack(pady=5)

        btn_criar = tk.Button(self, text="Adicionar Tarefa", command=self.criar_tarefa, bg="#4CAF50", fg="white", font=("Arial", 10, "bold"))
        btn_criar.pack(pady=5)

        # --- BOTÃO DE ATUALIZAR LISTA ---
        btn_listar = tk.Button(self, text="🔄 Atualizar Lista", command=self.carregar_tarefas, font=("Arial", 9))
        btn_listar.pack(pady=5)

        # --- LISTA DE TAREFAS ---
        tk.Label(self, text="Tarefas no Banco (Supabase via API):", font=("Arial", 10, "bold")).pack(pady=5)
        self.lista_tarefas = tk.Listbox(self, width=60, height=12, font=("Arial", 10))
        self.lista_tarefas.pack(pady=5)

        # --- BOTÃO DE EXCLUIR ---
        btn_deletar = tk.Button(self, text="Excluir Tarefa Selecionada", command=self.deletar_tarefa, bg="#f44336", fg="white", font=("Arial", 9, "bold"))
        btn_deletar.pack(pady=10)

        # Carrega os dados ao abrir a janela
        self.carregar_tarefas()

    def carregar_tarefas(self):
        self.lista_tarefas.delete(0, tk.END)
        try:
            response = requests.get(f"{API_URL}/tarefas")
            if response.status_code == 200:
                self.tarefas_cache = response.json()
                for t in self.tarefas_cache:
                    status = "✔️ Concluída" | "❌ Pendente" if "concluida" in t else ""
                    status_txt = "✔️" if t.get("concluida") else "❌"
                    self.lista_tarefas.insert(tk.END, f"ID: {t['id']} | {t['titulo']} [{status_txt}]")
            else:
                messagebox.showerror("Erro", "Falha ao carregar dados da API.")
        except requests.exceptions.ConnectionError:
            messagebox.showerror("Erro de Conexão", "A API FastAPI não está rodando no momento!\nInicie com: uvicorn main:app --reload")

    def criar_tarefa(self):
        titulo = self.entry_titulo.get().strip()
        if not titulo:
            messagebox.showwarning("Aviso", "O campo de título não pode estar vazio!")
            return
        
        response = requests.post(f"{API_URL}/tarefas", json={"titulo": titulo, "concluida": False})
        if response.status_code == 201:
            self.entry_titulo.delete(0, tk.END)
            self.carregar_tarefas()
        else:
            messagebox.showerror("Erro", "Não foi possível criar a tarefa.")

    def deletar_tarefa(self):
        try:
            selected_idx = self.lista_tarefas.curselection()[0]
            tarefa_id = self.tarefas_cache[selected_idx]["id"]
            
            response = requests.delete(f"{API_URL}/tarefas/{tarefa_id}")
            if response.status_code == 204:
                self.carregar_tarefas()
            else:
                messagebox.showerror("Erro", "Não foi possível excluir a tarefa.")
        except IndexError:
            messagebox.showwarning("Aviso", "Selecione uma tarefa na lista para excluir!")

if __name__ == "__main__":
    app = App()
    app.mainloop()