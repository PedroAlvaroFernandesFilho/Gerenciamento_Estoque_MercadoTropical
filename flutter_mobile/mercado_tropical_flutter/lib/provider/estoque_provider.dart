import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../service/produto_service.dart';

// Instância global nativa para ser acedida por todas as telas sem pacotes externos
final estoqueProvider = EstoqueProvider();

// Controlador de estado da aplicação
class EstoqueProvider extends ChangeNotifier {
  final ProdutoService _service = ProdutoService();

  List<Produto> _produtos = [];
  bool _carregando = false;
  String _filtroStatus = 'todos';
  String _termoBusca = '';
  bool _isLargeFont = true;

  // Filtra os produtos conforme o botão selecionado e o texto pesquisado
  List<Produto> get produtosFiltrados {
    return _produtos.where((p) {
      final bateFiltro = _filtroStatus == 'todos' || p.status == _filtroStatus;
      final bateBusca = p.nome.toLowerCase().contains(_termoBusca.toLowerCase());
      return bateFiltro && bateBusca;
    }).toList();
  }

  bool get carregando => _carregando;
  String get filtroStatus => _filtroStatus;
  bool get isLargeFont => _isLargeFont;

  // Contadores para os cartões de resumo
  int get totalItens => _produtos.length;
  int get totalPoucoEstoque => _produtos.where((p) => p.status == 'baixo').length;
  int get totalVencidos => _produtos.where((p) => p.status == 'vencido').length;

  // Alterna entre fonte grande e normal
  void alternarFonte() {
    _isLargeFont = !_isLargeFont;
    notifyListeners();
  }

  // Altera o filtro de status atual
  void definirFiltro(String novoFiltro) {
    _filtroStatus = novoFiltro;
    notifyListeners();
  }

  // Atualiza o texto da barra de pesquisa
  void definirBusca(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }

  // Carrega a lista inicial de produtos
  Future<void> carregarProdutos() async {
    _carregando = true;
    notifyListeners();
    try {
      _produtos = await _service.listarProdutos();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // Cadastra um novo produto e atualiza a tela
  Future<void> adicionarProduto(Produto novo) async {
    final criado = await _service.criarProduto(novo);
    _produtos.add(criado);
    notifyListeners();
  }

  // Altera apenas a quantidade em estoque (Entrada ou Saída)
  Future<void> atualizarQuantidade(Produto produto, int novaQuantidade) async {
    if (produto.id == null) return;
    final atualizado = produto.copyWith(quantidade: novaQuantidade);
    final resposta = await _service.atualizarProduto(produto.id!, atualizado);
    final index = _produtos.indexWhere((p) => p.id == produto.id);
    if (index != -1) {
      _produtos[index] = resposta;
      notifyListeners();
    }
  }

  // Salva a edição completa de um produto
  Future<void> editarProduto(Produto produto) async {
    if (produto.id == null) return;
    final resposta = await _service.atualizarProduto(produto.id!, produto);
    final index = _produtos.indexWhere((p) => p.id == produto.id);
    if (index != -1) {
      _produtos[index] = resposta;
      notifyListeners();
    }
  }

  // Exclui o produto e atualiza a tela
  Future<void> removerProduto(int id) async {
    await _service.deletarProduto(id);
    _produtos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}