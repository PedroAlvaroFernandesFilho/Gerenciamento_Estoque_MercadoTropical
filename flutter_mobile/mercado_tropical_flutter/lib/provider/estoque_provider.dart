import 'package:flutter/material.dart';
import '../models/log_movimentacao.dart';
import '../models/produto.dart';
import '../service/produto_service.dart';

// Instância global para acesso em todas as telas
final estoqueProvider = EstoqueProvider();

// Controlador de estado do estoque e do histórico de logs
class EstoqueProvider extends ChangeNotifier {
  final ProdutoService _service = ProdutoService();

  List<Produto> _produtos = [];
  final List<LogMovimentacao> _logs = [];
  bool _carregando = false;
  String _filtroStatus = 'todos'; // 'todos', 'baixo', 'vencendo', 'vencido'
  String _termoBusca = '';
  bool _isLargeFont = true;

  List<Produto> get todosProdutos => _produtos;
  List<LogMovimentacao> get logs => List.unmodifiable(_logs);
  bool get carregando => _carregando;
  String get filtroStatus => _filtroStatus;
  bool get isLargeFont => _isLargeFont;

  // Retorna a lista filtrada para a tela de estoque
  List<Produto> get produtosFiltrados {
    return _produtos.where((p) {
      bool bateFiltro = true;
      if (_filtroStatus == 'baixo') bateFiltro = p.isPoucoEstoque;
      if (_filtroStatus == 'vencendo') bateFiltro = p.isVencendoLogo;
      if (_filtroStatus == 'vencido') bateFiltro = p.isVencido;

      final bateBusca = p.nome.toLowerCase().contains(_termoBusca.toLowerCase());
      return bateFiltro && bateBusca;
    }).toList();
  }

  // Contadores gerais
  int get totalItens => _produtos.length;
  int get totalPoucoEstoque => _produtos.where((p) => p.isPoucoEstoque).length;
  int get totalVencendoLogo => _produtos.where((p) => p.isVencendoLogo).length;
  int get totalVencidos => _produtos.where((p) => p.isVencido).length;

  // Alterna tamanho da letra
  void alternarFonte() {
    _isLargeFont = !_isLargeFont;
    notifyListeners();
  }

  // Altera o filtro ativo
  void definirFiltro(String novoFiltro) {
    _filtroStatus = novoFiltro;
    notifyListeners();
  }

  // Altera o texto de busca
  void definirBusca(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }

  // Registra uma nova linha no histórico
  void _registrarLog(String tipo, String produtoNome, String detalhe) {
    _logs.insert(
      0,
      LogMovimentacao(
        tipo: tipo,
        produtoNome: produtoNome,
        detalhe: detalhe,
        dataHora: DateTime.now(),
      ),
    );
  }

  // Carrega a lista inicial
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

  // Cadastra um produto novo e gera log
  Future<void> adicionarProduto(Produto novo) async {
    final criado = await _service.criarProduto(novo);
    _produtos.add(criado);
    _registrarLog('cadastro', criado.nome, 'Cadastrado com ${criado.quantidade} ${criado.unidade}');
    notifyListeners();
  }

  // Registra entrada de mercadoria e gera log
  Future<void> registrarEntrada(Produto produto, int qtdAdicionada) async {
    if (produto.id == null) return;
    final novaQtd = produto.quantidade + qtdAdicionada;
    final atualizado = produto.copyWith(quantidade: novaQtd);
    final resposta = await _service.atualizarProduto(produto.id!, atualizado);

    final index = _produtos.indexWhere((p) => p.id == produto.id);
    if (index != -1) {
      _produtos[index] = resposta;
      _registrarLog(
        'entrada',
        produto.nome,
        'Adicionado +$qtdAdicionada ${produto.unidade} (De ${produto.quantidade} para $novaQtd)',
      );
      notifyListeners();
    }
  }

  // Registra saída de mercadoria e gera log
  Future<void> registrarSaida(Produto produto, int qtdRetirada, String motivo) async {
    if (produto.id == null) return;
    final novaQtd = (produto.quantidade - qtdRetirada) < 0 ? 0 : (produto.quantidade - qtdRetirada);
    final atualizado = produto.copyWith(quantidade: novaQtd);
    final resposta = await _service.atualizarProduto(produto.id!, atualizado);

    final index = _produtos.indexWhere((p) => p.id == produto.id);
    if (index != -1) {
      _produtos[index] = resposta;
      _registrarLog(
        'saida',
        produto.nome,
        'Retirado -$qtdRetirada ${produto.unidade} [$motivo] (De ${produto.quantidade} para $novaQtd)',
      );
      notifyListeners();
    }
  }

  // Edita dados cadastrais do produto e gera log
  Future<void> editarProduto(Produto produto) async {
    if (produto.id == null) return;
    final resposta = await _service.atualizarProduto(produto.id!, produto);
    final index = _produtos.indexWhere((p) => p.id == produto.id);
    if (index != -1) {
      _produtos[index] = resposta;
      _registrarLog('edicao', produto.nome, 'Dados atualizados (Estoque: ${produto.quantidade}, Val: ${produto.validade})');
      notifyListeners();
    }
  }

  // Remove um produto do estoque e gera log
  Future<void> removerProduto(Produto produto) async {
    if (produto.id == null) return;
    await _service.deletarProduto(produto.id!);
    _produtos.removeWhere((p) => p.id == produto.id);
    _registrarLog('exclusao', produto.nome, 'Produto removido do sistema');
    notifyListeners();
  }
}