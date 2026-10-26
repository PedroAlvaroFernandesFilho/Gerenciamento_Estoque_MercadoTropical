import 'package:flutter/material.dart';
import '../models/log_movimentacao.dart';
import '../models/produto.dart';
import '../service/produto_service.dart';

class EstoqueProvider extends ChangeNotifier {
  final ProdutoService _service = ProdutoService();

  List<Produto> _produtos = [];
  List<LogMovimentacao> _logs = [];

  bool _carregando = false;
  String? _erro;
  String _filtroStatus = 'todos'; // 'todos', 'baixo', 'sem_estoque', 'vencendo', 'vencido'
  String _termoBusca = '';
  bool _isLargeFont = false;

  List<Produto> get produtos => _produtos;
  List<LogMovimentacao> get logs => _logs;
  bool get carregando => _carregando;
  String? get erroMensagem => _erro;
  String get filtroStatus => _filtroStatus;
  String get termoBusca => _termoBusca;
  bool get isLargeFont => _isLargeFont;

  List<Produto> get todosProdutos => _produtos.where((p) => p.ativo).toList();

  void alternarFonte() {
    _isLargeFont = !_isLargeFont;
    notifyListeners();
  }

  void definirFiltro(String novoFiltro) {
    _filtroStatus = novoFiltro;
    notifyListeners();
  }

  void definirBusca(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }

  List<Produto> get produtosFiltrados {
    return _produtos.where((p) {
      if (!p.ativo) return false; // Garante que só ativos apareçam

      bool bateFiltro = true;
      if (_filtroStatus == 'baixo') bateFiltro = p.isPoucoEstoque;
      if (_filtroStatus == 'sem_estoque') bateFiltro = p.isSemEstoque;
      if (_filtroStatus == 'vencendo') bateFiltro = p.isVencendoLogo;
      if (_filtroStatus == 'vencido') bateFiltro = p.isVencido;

      final bateBusca = p.nome.toLowerCase().contains(_termoBusca.toLowerCase());
      return bateFiltro && bateBusca;
    }).toList();
  }

  // Contadores atualizados
  int get totalItens => _produtos.where((p) => p.ativo).length;
  int get totalPoucoEstoque => _produtos.where((p) => p.ativo && p.isPoucoEstoque).length;
  int get totalSemEstoque => _produtos.where((p) => p.ativo && p.isSemEstoque).length;
  int get totalVencendoLogo => _produtos.where((p) => p.ativo && p.isVencendoLogo).length;
  int get totalVencidos => _produtos.where((p) => p.ativo && p.isVencido).length;

  // Lista de compras inclui quem está com pouco estoque ou zerou
  List<Produto> get listaDeCompras =>
      _produtos.where((p) => p.ativo && (p.isPoucoEstoque || p.isSemEstoque)).toList();

  Future<void> carregarProdutos() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final listaDaApi = await _service.listarProdutos();
      _produtos = listaDaApi.where((p) => p.ativo).toList();
      await carregarHistorico();
    } catch (e) {
      _erro = 'Não foi possível conectar ao servidor da API.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> carregarHistorico() async {
    try {
      final movimentosApi = await _service.listarMovimentacoes();
      final mapaNomes = {for (var p in _produtos) p.id: p.nome};

      _logs = movimentosApi.map((m) {
        final prodId = m['product_id'] as int?;
        final nomeProd = mapaNomes[prodId] ?? 'Produto #$prodId';
        final tipoApi = (m['type'] ?? '').toString();
        final qtd = m['quantity'] ?? 0;
        final motivo = (m['reason'] ?? '').toString();
        final dataIso = (m['created_at'] ?? '').toString();

        final ehEntrada = tipoApi == 'entry';
        return LogMovimentacao(
          tipo: ehEntrada ? 'entrada' : 'saida',
          produtoNome: nomeProd,
          detalhe: '${ehEntrada ? '+' : '-'}$qtd un ${motivo.isNotEmpty ? '($motivo)' : ''}',
          dataHora: DateTime.tryParse(dataIso) ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      // Mantém logs locais se falhar
    }
  }

  Future<void> adicionarProduto(Produto novo) async {
    try {
      final criado = await _service.criarProduto(novo);
      _produtos.add(criado);
      _registrarLogLocal('cadastro', criado.nome, 'Estoque inicial: ${criado.quantidade} ${criado.unidade}');
      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao cadastrar produto: $e';
      notifyListeners();
    }
  }

  Future<void> editarProduto(Produto atualizado) async {
    if (atualizado.id == null) return;
    try {
      final salvo = await _service.atualizarProduto(atualizado.id!, atualizado);
      final index = _produtos.indexWhere((p) => p.id == salvo.id);
      if (index != -1) {
        _produtos[index] = salvo;
      }
      _registrarLogLocal('edicao', salvo.nome, 'Dados atualizados (Mín: ${salvo.minimo} ${salvo.unidade})');
      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao atualizar produto: $e';
      notifyListeners();
    }
  }

  Future<void> registrarEntrada(Produto produto, int quantidade) async {
    if (produto.id == null) return;
    try {
      await _service.registrarEntrada(produto.id!, quantidade);
      _registrarLogLocal('entrada', produto.nome, 'Adicionado +$quantidade ${produto.unidade}');
      await carregarProdutos();
    } catch (e) {
      _erro = 'Erro ao registrar entrada: $e';
      notifyListeners();
    }
  }

  Future<void> registrarSaida(Produto produto, int quantidade, [String motivo = 'Venda']) async {
    if (produto.id == null) return;
    try {
      await _service.registrarSaida(produto.id!, quantidade);
      _registrarLogLocal('saida', produto.nome, 'Retirado -$quantidade ${produto.unidade} ($motivo)');
      await carregarProdutos();
    } catch (e) {
      _erro = 'Erro ao registrar saída: $e';
      notifyListeners();
    }
  }

  // Soft Delete: Desativa o produto mantendo o histórico no Supabase
  Future<void> desativarProduto(Produto produto) async {
    if (produto.id == null) return;
    try {
      await _service.deletarProduto(produto.id!);
      _produtos.removeWhere((p) => p.id == produto.id);
      _registrarLogLocal('exclusao', produto.nome, 'Produto desativado do estoque ativo');
      notifyListeners();
    } catch (e) {
      _erro = 'Erro ao desativar produto: $e';
      notifyListeners();
    }
  }

  // Alias caso algum código antigo chame removerProduto
  Future<void> removerProduto(Produto produto) => desativarProduto(produto);

  void _registrarLogLocal(String tipo, String nome, String detalhe) {
    _logs.insert(
      0,
      LogMovimentacao(
        tipo: tipo,
        produtoNome: nome,
        detalhe: detalhe,
        dataHora: DateTime.now(),
      ),
    );
  }

  String _formatarDataHora(String dataIso) {
    try {
      final dt = DateTime.parse(dataIso).toLocal();
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes às $hora:$min';
    } catch (_) {
      return '';
    }
  }
}

// Instância global única do Provider para controle de estado centralizado
final EstoqueProvider estoqueProvider = EstoqueProvider();