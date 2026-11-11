"""
Mercado Tropical — Interface Python (Tkinter)

Segunda interface do sistema, feita em Tkinter, que consome a mesma API do app Flutter.
Tudo o que é feito aqui aparece no app (e vice-versa) depois de atualizar a lista.

Como rodar (com a API já rodando):
    python interface_python/app_tkinter.py

Para usar outro endereço da API:
    set MERCADO_API_URL=http://192.168.0.15:8000      (Windows)
"""

import tkinter as tk
from datetime import datetime
from tkinter import messagebox, ttk

from api_cliente import ApiCliente, ErroApi

# ---------- Cores (mesma paleta do app Flutter, TropicalColors) ----------
BASE = "#06130D"
SURFACE = "#0E241A"
CARD = "#142E22"
CARD_HIGHLIGHT = "#1A3A2C"
PRIMARY = "#00D665"
PRIMARY_HOVER = "#00B856"
ACCENT = "#F59E0B"
DANGER = "#EF4444"
TEXT = "#ECFDF5"
SUBTEXT = "#9DB2A6"
BORDER = "#234937"

FONTE = ("Segoe UI", 10)
FONTE_TITULO = ("Segoe UI", 15, "bold")
FONTE_NEGRITO = ("Segoe UI", 10, "bold")

INTERVALO_ATUALIZACAO_MS = 10_000

# Status da API -> texto mostrado na tela
STATUS = {
    "normal": "Normal",
    "low_stock": "Estoque baixo",
    "out_of_stock": "Sem estoque",
    "expiring_soon": "Vencendo",
    "expired": "Vencido",
}

# Opções do filtro de status (texto -> valor enviado para a API)
FILTROS_STATUS = {"Todos": None, **{texto: valor for valor, texto in STATUS.items()}}

# Tipos de movimentação do histórico
TIPOS_MOVIMENTO = {
    "create": "Cadastro",
    "update": "Edição",
    "entry": "Entrada",
    "exit": "Saída",
    "deactivate": "Desativação",
    "activate": "Reativação",
}

# Mesma lista de unidades do formulário do app (plural -> singular)
UNIDADES = {
    "pacotes": "pacote",
    "unidades": "unidade",
    "caixas": "caixa",
    "latas": "lata",
    "quilos": "quilo",
    "litros": "litro",
    "fardos": "fardo",
}


# ---------- Funções auxiliares ----------

def unidade_para(quantidade: int, unidade: str) -> str:
    """Singular quando a quantidade é 1, plural nos outros casos (igual ao app)."""
    unidade = (unidade or "").strip()
    plural = next((p for p, s in UNIDADES.items() if unidade.lower() in (p, s)), None)
    if plural is None:
        return unidade  # unidade fora da lista aparece como está salva
    return UNIDADES[plural] if quantidade == 1 else plural


def iso_para_br(data_iso: str | None) -> str:
    """'2027-03-15' -> '15/03/2027'. Sem data -> 'Sem validade'."""
    if not data_iso:
        return "Sem validade"
    return datetime.strptime(data_iso[:10], "%Y-%m-%d").strftime("%d/%m/%Y")


def br_para_iso(texto: str) -> str | None:
    """'15/03/2027' -> '2027-03-15'. Campo vazio -> None. Data inválida -> ValueError."""
    texto = texto.strip()
    if not texto:
        return None
    return datetime.strptime(texto, "%d/%m/%Y").strftime("%Y-%m-%d")


def data_hora_br(data_iso: str | None) -> str:
    """'2026-11-11T15:05:00' -> '11/11/2026 15:05'."""
    if not data_iso:
        return "-"
    try:
        return datetime.fromisoformat(data_iso.replace("Z", "")[:19]).strftime("%d/%m/%Y %H:%M")
    except ValueError:
        return data_iso


def limpar_espacos(texto: str) -> str:
    return " ".join(texto.split())


def ler_inteiro(texto: str, campo: str) -> int:
    try:
        return int(texto.strip())
    except ValueError:
        raise ValueError(f"{campo}: digite um número inteiro.") from None


# ---------- Tema ----------

def aplicar_tema(raiz: tk.Tk) -> None:
    estilo = ttk.Style(raiz)
    estilo.theme_use("clam")
    raiz.configure(bg=BASE)

    estilo.configure(".", background=SURFACE, foreground=TEXT, font=FONTE, bordercolor=BORDER,
                     lightcolor=SURFACE, darkcolor=SURFACE, troughcolor=BASE, focuscolor=PRIMARY)
    estilo.configure("TFrame", background=SURFACE)
    estilo.configure("Base.TFrame", background=BASE)
    estilo.configure("TLabel", background=SURFACE, foreground=TEXT)
    estilo.configure("Titulo.TLabel", background=BASE, foreground=PRIMARY, font=FONTE_TITULO)
    estilo.configure("Sub.TLabel", background=SURFACE, foreground=SUBTEXT)
    estilo.configure("Barra.TLabel", background=BASE, foreground=SUBTEXT)
    estilo.configure("Erro.TLabel", background=BASE, foreground=DANGER)

    # Campos de texto, listas e números
    for campo in ("TEntry", "TCombobox", "TSpinbox"):
        estilo.configure(campo, fieldbackground=CARD, foreground=TEXT, insertcolor=TEXT,
                         bordercolor=BORDER, lightcolor=CARD, darkcolor=CARD, arrowcolor=TEXT,
                         background=CARD_HIGHLIGHT, padding=4)
        estilo.map(campo, bordercolor=[("focus", PRIMARY)], fieldbackground=[("readonly", CARD)],
                   foreground=[("readonly", TEXT)])
    raiz.option_add("*TCombobox*Listbox.background", CARD)
    raiz.option_add("*TCombobox*Listbox.foreground", TEXT)
    raiz.option_add("*TCombobox*Listbox.selectBackground", PRIMARY)
    raiz.option_add("*TCombobox*Listbox.selectForeground", BASE)

    # Botões
    estilo.configure("TButton", background=CARD_HIGHLIGHT, foreground=TEXT, padding=(12, 6),
                     bordercolor=BORDER, lightcolor=CARD_HIGHLIGHT, darkcolor=CARD_HIGHLIGHT)
    estilo.map("TButton", background=[("active", BORDER), ("disabled", CARD)],
               foreground=[("disabled", SUBTEXT)])
    estilo.configure("Primario.TButton", background=PRIMARY, foreground=BASE, font=FONTE_NEGRITO,
                     lightcolor=PRIMARY, darkcolor=PRIMARY)
    estilo.map("Primario.TButton", background=[("active", PRIMARY_HOVER)])
    estilo.configure("Perigo.TButton", background=DANGER, foreground=TEXT, lightcolor=DANGER, darkcolor=DANGER)
    estilo.map("Perigo.TButton", background=[("active", "#C93636")])

    estilo.configure("TCheckbutton", background=SURFACE, foreground=TEXT, indicatorbackground=CARD,
                     indicatorforeground=PRIMARY)
    estilo.map("TCheckbutton", background=[("active", SURFACE)], indicatorbackground=[("selected", CARD)])

    # Tabela
    estilo.configure("Treeview", background=CARD, fieldbackground=CARD, foreground=TEXT, rowheight=28,
                     bordercolor=BORDER, lightcolor=CARD, darkcolor=CARD)
    estilo.map("Treeview", background=[("selected", PRIMARY)], foreground=[("selected", BASE)])
    estilo.configure("Treeview.Heading", background=CARD_HIGHLIGHT, foreground=SUBTEXT, font=FONTE_NEGRITO,
                     relief="flat", padding=6)
    estilo.map("Treeview.Heading", background=[("active", BORDER)])
    estilo.configure("Vertical.TScrollbar", background=CARD_HIGHLIGHT, arrowcolor=TEXT, troughcolor=SURFACE)


def configurar_cores_status(tabela: ttk.Treeview) -> None:
    """Cor da linha conforme o status do produto."""
    tabela.tag_configure("expired", foreground=DANGER)
    tabela.tag_configure("expiring_soon", foreground=ACCENT)
    tabela.tag_configure("low_stock", foreground=ACCENT)
    tabela.tag_configure("out_of_stock", foreground=SUBTEXT)


def criar_tabela(pai, colunas: dict[str, tuple[str, int, str]], altura: int = 12) -> ttk.Treeview:
    """Cria uma Treeview com barra de rolagem. colunas = {id: (título, largura, alinhamento)}."""
    quadro = ttk.Frame(pai)
    quadro.pack(fill="both", expand=True)
    tabela = ttk.Treeview(quadro, columns=list(colunas), show="headings", height=altura, selectmode="browse")
    for chave, (titulo, largura, alinhamento) in colunas.items():
        tabela.heading(chave, text=titulo, anchor=alinhamento)
        tabela.column(chave, width=largura, anchor=alinhamento, stretch=chave == "nome")
    rolagem = ttk.Scrollbar(quadro, orient="vertical", command=tabela.yview)
    tabela.configure(yscrollcommand=rolagem.set)
    tabela.pack(side="left", fill="both", expand=True)
    rolagem.pack(side="right", fill="y")
    return tabela


# ---------- Janelas auxiliares ----------

class Dialogo(tk.Toplevel):
    """Janela modal base: bloqueia a janela principal até ser fechada."""

    def __init__(self, pai, titulo: str):
        super().__init__(pai)
        self.title(titulo)
        self.configure(bg=SURFACE)
        self.transient(pai)
        self.resizable(False, False)
        self.resultado = None
        self.conteudo = ttk.Frame(self, padding=18)
        self.conteudo.pack(fill="both", expand=True)
        self.bind("<Escape>", lambda _: self.destroy())

    def mostrar(self):
        # Centraliza sobre a janela principal
        self.update_idletasks()
        pai = self.master
        x = pai.winfo_rootx() + (pai.winfo_width() - self.winfo_width()) // 2
        y = pai.winfo_rooty() + (pai.winfo_height() - self.winfo_height()) // 3
        self.geometry(f"+{max(x, 0)}+{max(y, 0)}")
        self.grab_set()
        self.wait_window()
        return self.resultado

    def campo(self, linha: int, rotulo: str, widget, dica: str = "") -> None:
        ttk.Label(self.conteudo, text=rotulo).grid(row=linha * 2, column=0, sticky="w", pady=(8, 2))
        widget.grid(row=linha * 2 + 1, column=0, sticky="ew")
        if dica:
            ttk.Label(self.conteudo, text=dica, style="Sub.TLabel").grid(row=linha * 2, column=1, sticky="e", padx=(12, 0))

    def botoes(self, linha: int, texto_ok: str, acao) -> None:
        quadro = ttk.Frame(self.conteudo)
        quadro.grid(row=linha * 2, column=0, columnspan=2, sticky="e", pady=(18, 0))
        ttk.Button(quadro, text="Cancelar", command=self.destroy).pack(side="left", padx=(0, 8))
        ttk.Button(quadro, text=texto_ok, style="Primario.TButton", command=acao).pack(side="left")
        self.bind("<Return>", lambda _: acao())


class ProdutoDialogo(Dialogo):
    """Cadastro (produto=None) ou edição de produto."""

    def __init__(self, pai, api: ApiCliente, produto: dict | None = None):
        self.api = api
        self.produto = produto
        super().__init__(pai, "Editar produto" if produto else "Novo produto")
        self.conteudo.columnconfigure(0, minsize=320)

        self.nome = ttk.Entry(self.conteudo, width=40)
        self.unidade = ttk.Combobox(self.conteudo, values=list(UNIDADES), width=38)
        self.quantidade = ttk.Spinbox(self.conteudo, from_=0, to=1000, width=38)
        self.minimo = ttk.Spinbox(self.conteudo, from_=0, to=1000, width=38)
        self.validade = ttk.Entry(self.conteudo, width=40)

        self.campo(0, "Nome do produto", self.nome, "3 a 120 letras")
        self.campo(1, "Unidade", self.unidade, "pode digitar outra")
        linha = 2
        if produto is None:
            # A quantidade só é informada no cadastro; depois ela muda por entradas e saídas
            self.campo(linha, "Quantidade inicial", self.quantidade, "0 a 1000")
            linha += 1
        self.campo(linha, "Estoque mínimo", self.minimo, "avisa quando chegar nele")
        self.campo(linha + 1, "Validade (DD/MM/AAAA)", self.validade, "deixe vazio se não tiver")
        self.botoes(linha + 2, "Salvar" if produto else "Cadastrar", self.salvar)

        if produto:
            self.nome.insert(0, produto["name"])
            self.unidade.set(produto["unit"])
            self.minimo.set(produto["minimum_stock"])
            if produto.get("expiration_date"):
                self.validade.insert(0, iso_para_br(produto["expiration_date"]))
        else:
            self.unidade.set("unidades")
            self.quantidade.set(0)
            self.minimo.set(0)
        self.nome.focus_set()

    def salvar(self):
        try:
            dados = {
                "name": limpar_espacos(self.nome.get()),
                "unit": limpar_espacos(self.unidade.get()),
                "minimum_stock": ler_inteiro(self.minimo.get(), "Estoque mínimo"),
                "expiration_date": br_para_iso(self.validade.get()),
            }
            if self.produto is None:
                dados["quantity"] = ler_inteiro(self.quantidade.get(), "Quantidade inicial")
        except ValueError as erro:
            texto = str(erro)
            if "does not match format" in texto or "unconverted data" in texto or "out of range" in texto:
                texto = "Validade: use o formato DD/MM/AAAA (ex.: 15/03/2027)."
            messagebox.showwarning("Confira os dados", texto, parent=self)
            return

        if len(dados["name"]) < 3:
            messagebox.showwarning("Confira os dados", "Nome: digite pelo menos 3 letras.", parent=self)
            return
        if len(dados["unit"]) < 3:
            messagebox.showwarning("Confira os dados", "Unidade: digite pelo menos 3 letras.", parent=self)
            return

        try:
            if self.produto is None:
                self.resultado = self.api.cadastrar_produto(dados)
            else:
                self.resultado = self.api.atualizar_produto(self.produto["id"], dados)
        except ErroApi as erro:
            messagebox.showerror("Não foi possível salvar", str(erro), parent=self)
            return
        self.destroy()


class MovimentoDialogo(Dialogo):
    """Registra uma entrada ou uma saída de estoque."""

    MOTIVOS = {"entrada": ["Reposição", "Compra", "Devolução"], "saida": ["Venda", "Descarte"]}

    def __init__(self, pai, api: ApiCliente, produto: dict, tipo: str):
        self.api = api
        self.produto = produto
        self.tipo = tipo
        super().__init__(pai, "Registrar entrada" if tipo == "entrada" else "Registrar saída")
        self.conteudo.columnconfigure(0, minsize=300)

        estoque = f"{produto['quantity']} {unidade_para(produto['quantity'], produto['unit'])}"
        ttk.Label(self.conteudo, text=produto["name"], font=FONTE_NEGRITO).grid(row=0, column=0, columnspan=2, sticky="w")
        ttk.Label(self.conteudo, text=f"Estoque atual: {estoque}", style="Sub.TLabel").grid(
            row=1, column=0, columnspan=2, sticky="w")

        self.quantidade = ttk.Spinbox(self.conteudo, from_=1, to=1000, width=36)
        self.quantidade.set(1)
        self.motivo = ttk.Combobox(self.conteudo, values=self.MOTIVOS[tipo], width=34)
        self.motivo.set(self.MOTIVOS[tipo][0])

        self.campo(1, "Quantidade", self.quantidade, "1 a 1000")
        self.campo(2, "Motivo (opcional)", self.motivo, "até 60 letras")
        self.botoes(3, "Registrar", self.registrar)
        self.quantidade.focus_set()

    def registrar(self):
        try:
            quantidade = ler_inteiro(self.quantidade.get(), "Quantidade")
        except ValueError as erro:
            messagebox.showwarning("Confira os dados", str(erro), parent=self)
            return

        motivo = limpar_espacos(self.motivo.get()) or None
        try:
            if self.tipo == "entrada":
                self.resultado = self.api.registrar_entrada(self.produto["id"], quantidade, motivo)
            else:
                self.resultado = self.api.registrar_saida(self.produto["id"], quantidade, motivo)
        except ErroApi as erro:
            messagebox.showerror("Não foi possível registrar", str(erro), parent=self)
            return
        self.destroy()


class DesativadosJanela(Dialogo):
    """Lista os produtos desativados e permite reativá-los."""

    def __init__(self, pai, api: ApiCliente, ao_reativar):
        self.api = api
        self.ao_reativar = ao_reativar
        super().__init__(pai, "Produtos desativados")
        self.resizable(True, True)
        self.geometry("620x380")

        self.tabela = criar_tabela(self.conteudo, {
            "id": ("ID", 60, "center"),
            "nome": ("Nome", 280, "w"),
            "estoque": ("Estoque", 140, "center"),
        })
        rodape = ttk.Frame(self.conteudo)
        rodape.pack(fill="x", pady=(12, 0))
        self.aviso = ttk.Label(rodape, text="", style="Sub.TLabel")
        self.aviso.pack(side="left")
        ttk.Button(rodape, text="Fechar", command=self.destroy).pack(side="right")
        ttk.Button(rodape, text="Reativar", style="Primario.TButton", command=self.reativar).pack(side="right", padx=8)
        self.carregar()

    def carregar(self):
        self.tabela.delete(*self.tabela.get_children())
        try:
            produtos = self.api.listar_desativados()
        except ErroApi as erro:
            self.aviso.configure(text=str(erro).splitlines()[0])
            return
        for p in produtos:
            estoque = f"{p['quantity']} {unidade_para(p['quantity'], p['unit'])}"
            self.tabela.insert("", "end", iid=str(p["id"]), values=(p["id"], p["name"], estoque))
        self.aviso.configure(text=f"{len(produtos)} desativado(s)" if produtos else "Nenhum produto desativado.")

    def reativar(self):
        selecao = self.tabela.selection()
        if not selecao:
            messagebox.showinfo("Reativar", "Selecione um produto na lista.", parent=self)
            return
        try:
            produto = self.api.reativar_produto(int(selecao[0]))
        except ErroApi as erro:
            messagebox.showerror("Não foi possível reativar", str(erro), parent=self)
            return
        messagebox.showinfo("Reativar", f"{produto['name']} voltou para o estoque.", parent=self)
        self.carregar()
        self.ao_reativar()


class HistoricoJanela(Dialogo):
    """Histórico de movimentações, de todos os produtos ou de um só."""

    def __init__(self, pai, api: ApiCliente, nomes: dict[int, str], produto: dict | None = None):
        self.api = api
        self.nomes = nomes
        self.produto = produto
        titulo = f"Histórico — {produto['name']}" if produto else "Histórico de movimentações"
        super().__init__(pai, titulo)
        self.resizable(True, True)
        self.geometry("900x460")

        self.tabela = criar_tabela(self.conteudo, {
            "data": ("Data", 130, "center"),
            "nome": ("Produto", 220, "w"),
            "tipo": ("Tipo", 100, "center"),
            "quantidade": ("Qtd.", 60, "center"),
            "antes": ("Antes", 60, "center"),
            "depois": ("Depois", 60, "center"),
            "motivo": ("Motivo", 180, "w"),
        }, altura=14)
        self.tabela.tag_configure("exit", foreground=ACCENT)
        self.tabela.tag_configure("entry", foreground=PRIMARY)
        self.tabela.tag_configure("deactivate", foreground=SUBTEXT)

        rodape = ttk.Frame(self.conteudo)
        rodape.pack(fill="x", pady=(12, 0))
        self.aviso = ttk.Label(rodape, text="", style="Sub.TLabel")
        self.aviso.pack(side="left")
        ttk.Button(rodape, text="Fechar", command=self.destroy).pack(side="right")
        ttk.Button(rodape, text="Atualizar", command=self.carregar).pack(side="right", padx=8)
        self.carregar()

    def carregar(self):
        self.tabela.delete(*self.tabela.get_children())
        try:
            movimentos = self.api.historico(self.produto["id"] if self.produto else None)
        except ErroApi as erro:
            self.aviso.configure(text=str(erro).splitlines()[0])
            return
        for m in movimentos:
            tipo = m.get("movement_type", "")
            self.tabela.insert("", "end", tags=(tipo,), values=(
                data_hora_br(m.get("created_at")),
                self.nomes.get(m.get("product_id"), f"Produto #{m.get('product_id')}"),
                TIPOS_MOVIMENTO.get(tipo, tipo),
                m.get("quantity", ""),
                m.get("previous_stock", ""),
                m.get("new_stock", ""),
                m.get("reason") or "",
            ))
        self.aviso.configure(text=f"{len(movimentos)} movimentação(ões)")


# ---------- Janela principal ----------

class App:
    def __init__(self, raiz: tk.Tk, api: ApiCliente):
        self.raiz = raiz
        self.api = api
        self.produtos: dict[int, dict] = {}
        self.id_agendamento = None

        raiz.title("Mercado Tropical — Controle de Estoque")
        raiz.geometry("1000x620")
        raiz.minsize(820, 480)
        aplicar_tema(raiz)

        self.montar_cabecalho()
        self.montar_filtros()
        self.montar_tabela()
        self.montar_acoes()
        self.montar_barra_status()

        self.atualizar(mostrar_erro=True)
        self.agendar_atualizacao()

    # ----- Montagem da tela -----

    def montar_cabecalho(self):
        topo = ttk.Frame(self.raiz, style="Base.TFrame", padding=(16, 12, 16, 4))
        topo.pack(fill="x")
        ttk.Label(topo, text="🌴 Mercado Tropical", style="Titulo.TLabel").pack(side="left")
        ttk.Label(topo, text=f"API: {self.api.url_base}", style="Barra.TLabel").pack(side="right")

    def montar_filtros(self):
        barra = ttk.Frame(self.raiz, padding=12)
        barra.pack(fill="x", padx=16, pady=(8, 0))

        ttk.Label(barra, text="Buscar nome:").pack(side="left")
        self.busca = ttk.Entry(barra, width=24)
        self.busca.pack(side="left", padx=(6, 14))
        self.busca.bind("<Return>", lambda _: self.atualizar(mostrar_erro=True))

        ttk.Label(barra, text="Status:").pack(side="left")
        self.filtro_status = ttk.Combobox(barra, values=list(FILTROS_STATUS), state="readonly", width=14)
        self.filtro_status.set("Todos")
        self.filtro_status.pack(side="left", padx=(6, 14))
        self.filtro_status.bind("<<ComboboxSelected>>", lambda _: self.atualizar(mostrar_erro=True))

        ttk.Button(barra, text="Filtrar", command=lambda: self.atualizar(mostrar_erro=True)).pack(side="left")

        # Lado direito: busca por ID e atualização automática
        self.auto = tk.BooleanVar(value=True)
        ttk.Checkbutton(barra, text="Atualizar a cada 10 s", variable=self.auto,
                        command=self.agendar_atualizacao).pack(side="right")
        ttk.Button(barra, text="Buscar ID", command=self.buscar_por_id).pack(side="right", padx=(6, 14))
        self.busca_id = ttk.Entry(barra, width=6)
        self.busca_id.pack(side="right")
        self.busca_id.bind("<Return>", lambda _: self.buscar_por_id())
        ttk.Label(barra, text="ID:").pack(side="right", padx=(0, 6))

    def montar_tabela(self):
        quadro = ttk.Frame(self.raiz, padding=(12, 0, 12, 12))
        quadro.pack(fill="both", expand=True, padx=16)
        self.tabela = criar_tabela(quadro, {
            "id": ("ID", 60, "center"),
            "nome": ("Nome", 300, "w"),
            "estoque": ("Estoque", 130, "center"),
            "minimo": ("Mínimo", 80, "center"),
            "validade": ("Validade", 110, "center"),
            "status": ("Status", 130, "center"),
        })
        configurar_cores_status(self.tabela)
        self.tabela.bind("<Double-1>", lambda _: self.editar())
        self.tabela.bind("<Delete>", lambda _: self.excluir())

    def montar_acoes(self):
        barra = ttk.Frame(self.raiz, padding=12)
        barra.pack(fill="x", padx=16)
        ttk.Button(barra, text="+ Novo", style="Primario.TButton", command=self.novo).pack(side="left")
        ttk.Button(barra, text="Editar", command=self.editar).pack(side="left", padx=6)
        ttk.Button(barra, text="Excluir", style="Perigo.TButton", command=self.excluir).pack(side="left")
        ttk.Button(barra, text="↓ Entrada", command=lambda: self.movimentar("entrada")).pack(side="left", padx=(18, 6))
        ttk.Button(barra, text="↑ Saída", command=lambda: self.movimentar("saida")).pack(side="left")
        ttk.Button(barra, text="Histórico", command=self.abrir_historico).pack(side="right")
        ttk.Button(barra, text="Desativados", command=self.abrir_desativados).pack(side="right", padx=6)
        ttk.Button(barra, text="⟳ Atualizar", command=lambda: self.atualizar(mostrar_erro=True)).pack(side="right")

    def montar_barra_status(self):
        rodape = ttk.Frame(self.raiz, style="Base.TFrame", padding=(16, 4, 16, 10))
        rodape.pack(fill="x")
        self.status = ttk.Label(rodape, text="Carregando...", style="Barra.TLabel")
        self.status.pack(side="left")
        ttk.Label(rodape, text="Duplo clique edita • Delete exclui", style="Barra.TLabel").pack(side="right")

    # ----- Lista de produtos -----

    def atualizar(self, mostrar_erro: bool = False):
        """Busca os produtos na API e redesenha a tabela, mantendo a seleção."""
        selecionado = self.tabela.selection()
        status = FILTROS_STATUS.get(self.filtro_status.get())
        try:
            produtos = self.api.listar_produtos(limpar_espacos(self.busca.get()) or None, status)
        except ErroApi as erro:
            self.status.configure(text=str(erro).splitlines()[0], style="Erro.TLabel")
            if mostrar_erro:
                messagebox.showerror("Erro de conexão", str(erro), parent=self.raiz)
            return

        self.produtos = {p["id"]: p for p in produtos}
        self.tabela.delete(*self.tabela.get_children())
        for p in produtos:
            estoque = f"{p['quantity']} {unidade_para(p['quantity'], p['unit'])}"
            self.tabela.insert("", "end", iid=str(p["id"]), tags=(p["status"],), values=(
                p["id"], p["name"], estoque, p["minimum_stock"],
                iso_para_br(p.get("expiration_date")), STATUS.get(p["status"], p["status"]),
            ))
        if selecionado and self.tabela.exists(selecionado[0]):
            self.tabela.selection_set(selecionado[0])

        hora = datetime.now().strftime("%H:%M:%S")
        self.status.configure(text=f"{len(produtos)} produto(s) • atualizado às {hora}", style="Barra.TLabel")

    def agendar_atualizacao(self):
        """Liga ou desliga a atualização automática (mostra o que foi feito no app Flutter)."""
        if self.id_agendamento:
            self.raiz.after_cancel(self.id_agendamento)
            self.id_agendamento = None
        if self.auto.get():
            self.id_agendamento = self.raiz.after(INTERVALO_ATUALIZACAO_MS, self._atualizacao_automatica)

    def _atualizacao_automatica(self):
        self.id_agendamento = None
        self.atualizar()
        self.agendar_atualizacao()

    def produto_selecionado(self, acao: str) -> dict | None:
        selecao = self.tabela.selection()
        if not selecao:
            messagebox.showinfo(acao, "Selecione um produto na lista.", parent=self.raiz)
            return None
        return self.produtos.get(int(selecao[0]))

    # ----- Ações -----

    def buscar_por_id(self):
        texto = self.busca_id.get().strip()
        if not texto.isdigit():
            messagebox.showwarning("Buscar por ID", "Digite o número do ID.", parent=self.raiz)
            return
        try:
            p = self.api.buscar_produto(int(texto))
        except ErroApi as erro:
            messagebox.showerror("Buscar por ID", str(erro), parent=self.raiz)
            return

        if self.tabela.exists(str(p["id"])):
            self.tabela.selection_set(str(p["id"]))
            self.tabela.see(str(p["id"]))
        estoque = f"{p['quantity']} {unidade_para(p['quantity'], p['unit'])}"
        messagebox.showinfo(f"Produto #{p['id']}", (
            f"{p['name']}\n\n"
            f"Estoque: {estoque}\n"
            f"Estoque mínimo: {p['minimum_stock']}\n"
            f"Validade: {iso_para_br(p.get('expiration_date'))}\n"
            f"Status: {STATUS.get(p['status'], p['status'])}\n"
            f"Cadastrado em: {data_hora_br(p.get('created_at'))}\n"
            f"Última alteração: {data_hora_br(p.get('updated_at'))}"
        ), parent=self.raiz)

    def novo(self):
        produto = ProdutoDialogo(self.raiz, self.api).mostrar()
        if produto:
            self.atualizar()
            if self.tabela.exists(str(produto["id"])):
                self.tabela.selection_set(str(produto["id"]))
                self.tabela.see(str(produto["id"]))
            self.status.configure(text=f"{produto['name']} cadastrado (ID {produto['id']}).")

    def editar(self):
        produto = self.produto_selecionado("Editar")
        if produto and ProdutoDialogo(self.raiz, self.api, produto).mostrar():
            self.atualizar()

    def excluir(self):
        produto = self.produto_selecionado("Excluir")
        if not produto:
            return
        confirmar = messagebox.askyesno(
            "Excluir produto",
            f"Excluir \"{produto['name']}\"?\n\nEle sai da lista, mas o histórico é mantido e "
            "dá para reativá-lo em \"Desativados\".",
            icon="warning", parent=self.raiz,
        )
        if not confirmar:
            return
        try:
            self.api.excluir_produto(produto["id"])
        except ErroApi as erro:
            messagebox.showerror("Não foi possível excluir", str(erro), parent=self.raiz)
            return
        self.atualizar()
        self.status.configure(text=f"{produto['name']} excluído (desativado).")

    def movimentar(self, tipo: str):
        produto = self.produto_selecionado("Entrada" if tipo == "entrada" else "Saída")
        if not produto:
            return
        resultado = MovimentoDialogo(self.raiz, self.api, produto, tipo).mostrar()
        if resultado:
            self.atualizar()
            novo = resultado["new_stock"]
            self.status.configure(
                text=f"{resultado['product_name']}: {resultado['previous_stock']} → {novo} "
                     f"{unidade_para(novo, produto['unit'])}")

    def abrir_desativados(self):
        DesativadosJanela(self.raiz, self.api, ao_reativar=self.atualizar).mostrar()

    def abrir_historico(self):
        # Nomes de ativos e desativados, para mostrar o produto em cada movimentação
        nomes = {pid: p["name"] for pid, p in self.produtos.items()}
        try:
            nomes.update({p["id"]: p["name"] for p in self.api.listar_desativados()})
            if self.filtro_status.get() != "Todos" or self.busca.get().strip():
                nomes.update({p["id"]: p["name"] for p in self.api.listar_produtos()})
        except ErroApi:
            pass  # sem os nomes extras, a janela mostra "Produto #ID"

        selecao = self.tabela.selection()
        produto = self.produtos.get(int(selecao[0])) if selecao else None
        if produto and not messagebox.askyesno(
            "Histórico", f"Mostrar só o histórico de \"{produto['name']}\"?\n\n"
                         "Escolha \"Não\" para ver todos os produtos.", parent=self.raiz):
            produto = None
        HistoricoJanela(self.raiz, self.api, nomes, produto).mostrar()


def main():
    raiz = tk.Tk()
    App(raiz, ApiCliente())
    raiz.mainloop()


if __name__ == "__main__":
    main()
