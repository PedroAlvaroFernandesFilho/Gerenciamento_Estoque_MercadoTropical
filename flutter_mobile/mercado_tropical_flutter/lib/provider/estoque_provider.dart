import 'package:flutter/material.dart';
import '../models/log_movimentacao.dart';
import '../models/produto.dart';
import '../service/produto_service.dart';

class EstoqueProvider extends ChangeNotifier {
  final ProdutoService _service = ProdutoService();

  List<Produto> _produtos = [];
  List<LogMovimentacao> _logs = [];
  List<Produto> _desativados = [];
  bool _carregandoDesativados = false;
  String? _erroDesativados;

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
  List<Produto> get produtosDesativados => _desativados;
  bool get carregandoDesativados => _carregandoDesativados;
  String? get erroDesativados => _erroDesativados;

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

  // Itens sem estoque vão para o final da lista; a ordem original (nome) é preservada em cada grupo.
  List<Produto> get produtosFiltrados {
    final filtrados = _produtos.where((p) {
      if (!p.ativo) return false; // Garante que só ativos apareçam

      bool bateFiltro = true;
      if (_filtroStatus == 'baixo') bateFiltro = p.isPoucoEstoque;
      if (_filtroStatus == 'sem_estoque') bateFiltro = p.isSemEstoque;
      // Vencendo/vencido ignoram itens sem estoque (não há nada na prateleira)
      if (_filtroStatus == 'vencendo') bateFiltro = p.isVencendoLogo && !p.isSemEstoque;
      if (_filtroStatus == 'vencido') bateFiltro = p.isVencido && !p.isSemEstoque;

      final bateBusca = p.nome.toLowerCase().contains(_termoBusca.toLowerCase());
      return bateFiltro && bateBusca;
    }).toList();

    return [
      ...filtrados.where((p) => !p.isSemEstoque),
      ...filtrados.where((p) => p.isSemEstoque),
    ];
  }

  // Contadores atualizados
  int get totalItens => _produtos.where((p) => p.ativo).length;
  int get totalPoucoEstoque => _produtos.where((p) => p.ativo && p.isPoucoEstoque).length;
  int get totalSemEstoque => _produtos.where((p) => p.ativo && p.isSemEstoque).length;
  // Vencendo/vencidos não contam itens sem estoque, para bater com o filtro acima
  int get totalVencendoLogo => _produtos.where((p) => p.ativo && p.isVencendoLogo && !p.isSemEstoque).length;
  int get totalVencidos => _produtos.where((p) => p.ativo && p.isVencido && !p.isSemEstoque).length;

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
      // Detalhe técnico só no console; o usuário vê uma mensagem simples
      debugPrint('Erro ao carregar produtos: $e');
      _erro = 'Não foi possível carregar os produtos.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> carregarHistorico() async {
    try {
      final movimentosApi = await _service.listarMovimentacoes();
      // Inclui os desativados para o histórico mostrar o nome deles
      final mapaNomes = {for (var p in [..._produtos, ..._desativados]) p.id: p.nome};

      _logs = movimentosApi.map((m) {
        final prodId = m['product_id'] as int?;
        // Produto fora da lista de ativos (desativado) aparece sem o número interno
        final nomeProd = mapaNomes[prodId] ?? 'Produto desativado';
        final tipoApi = (m['movement_type'] ?? '').toString();
        final qtd = m['quantity'] ?? 0;
        final motivo = (m['reason'] ?? '').toString();
        final dataIso = (m['created_at'] ?? '').toString();

        // Tipos gravados pela API: entry, exit, create, update, deactivate, activate
        // (antes, tudo que não era entrada aparecia como saída)
        final complemento = motivo.isNotEmpty ? ' ($motivo)' : '';
        String tipo;
        String detalhe;
        if (tipoApi == 'entry') {
          tipo = 'entrada';
          detalhe = '+$qtd un$complemento';
        } else if (tipoApi == 'exit') {
          tipo = 'saida';
          detalhe = '-$qtd un$complemento';
        } else if (tipoApi == 'create') {
          tipo = 'cadastro';
          detalhe = 'Produto cadastrado • Estoque inicial: $qtd un';
        } else if (tipoApi == 'update') {
          tipo = 'edicao';
          detalhe = _traduzirAlteracoes(motivo);
        } else if (tipoApi == 'deactivate') {
          tipo = 'exclusao';
          detalhe = 'Produto desativado';
        } else if (tipoApi == 'activate') {
          tipo = 'reativacao';
          detalhe = 'Produto reativado';
        } else {
          tipo = 'edicao';
          detalhe = motivo.isNotEmpty ? motivo : 'Movimentação registrada';
        }

        return LogMovimentacao(
          tipo: tipo,
          produtoNome: nomeProd,
          detalhe: detalhe,
          dataHora: DateTime.tryParse(dataIso) ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      // Mantém logs locais se falhar
    }
  }

  // Retorna null se deu certo, ou a mensagem de erro.
  // O erro não vai para _erro, para não esconder a lista do estoque (a tela mostra o aviso).
  Future<String?> adicionarProduto(Produto novo) async {
    try {
      final criado = await _service.criarProduto(novo);
      _produtos.add(criado);
      _registrarLogLocal('cadastro', criado.nome, 'Estoque inicial: ${Produto.quantidadeComUnidade(criado.quantidade, criado.unidade)}');
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Erro ao cadastrar produto: $e');
      return 'Não foi possível cadastrar o produto. Confira os dados e tente novamente.';
    }
  }

  // Retorna null se deu certo, ou a mensagem de erro (mesmo motivo do cadastro)
  Future<String?> editarProduto(Produto atualizado) async {
    if (atualizado.id == null) return 'Produto inválido.';
    try {
      final salvo = await _service.atualizarProduto(atualizado.id!, atualizado);
      final index = _produtos.indexWhere((p) => p.id == salvo.id);
      if (index != -1) {
        _produtos[index] = salvo;
      }
      _registrarLogLocal('edicao', salvo.nome, 'Dados atualizados (Mín: ${Produto.quantidadeComUnidade(salvo.minimo, salvo.unidade)})');
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Erro ao editar produto: $e');
      return 'Não foi possível salvar as alterações. Tente novamente.';
    }
  }

  // novaValidade (DD/MM/AAAA) é opcional: atualiza a validade do produto junto com a entrada
  // Retorna null se deu certo, ou a mensagem de erro para a tela mostrar
  Future<String?> registrarEntrada(Produto produto, int quantidade, {String? novaValidade}) async {
    if (produto.id == null) return 'Produto inválido.';
    try {
      await _service.registrarEntrada(produto.id!, quantidade);

      String? erroValidade;
      final alterarValidade = novaValidade != null && novaValidade != produto.validade;
      if (alterarValidade) {
        try {
          await _service.atualizarProduto(produto.id!, produto.copyWith(validade: novaValidade));
        } catch (_) {
          erroValidade = 'Entrada registrada, mas não foi possível atualizar a validade.';
        }
      }

      _registrarLogLocal(
        'entrada',
        produto.nome,
        'Adicionado +${Produto.quantidadeComUnidade(quantidade, produto.unidade)}'
        '${alterarValidade && erroValidade == null ? ' • Nova validade: $novaValidade' : ''}',
      );
      await carregarProdutos();
      return erroValidade;
    } catch (e) {
      debugPrint('Erro ao registrar entrada: $e');
      return 'Não foi possível registrar a entrada. Tente novamente.';
    }
  }

  // Retorna null se deu certo, ou a mensagem de erro (antes a tela mostrava sucesso mesmo com falha)
  Future<String?> registrarSaida(Produto produto, int quantidade, [String motivo = 'Venda']) async {
    if (produto.id == null) return 'Produto inválido.';
    try {
      // Envia o motivo para a API, assim ele fica salvo no histórico
      await _service.registrarSaida(produto.id!, quantidade, motivo: motivo);
      _registrarLogLocal('saida', produto.nome, 'Retirado -${Produto.quantidadeComUnidade(quantidade, produto.unidade)} ($motivo)');
      await carregarProdutos();
      return null;
    } catch (e) {
      debugPrint('Erro ao registrar saída: $e');
      return 'Não foi possível registrar a saída. Confira a quantidade disponível e tente novamente.';
    }
  }

  // Soft Delete: Desativa o produto mantendo o histórico no Supabase
  // Retorna true se deu certo (a tela mostra o aviso)
  Future<bool> desativarProduto(Produto produto) async {
    if (produto.id == null) return false;
    try {
      await _service.deletarProduto(produto.id!);
      _produtos.removeWhere((p) => p.id == produto.id);
      _desativados
        ..add(produto)
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      _registrarLogLocal('exclusao', produto.nome, 'Produto desativado do estoque ativo');
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Busca na API a lista de produtos desativados
  Future<void> carregarDesativados() async {
    _carregandoDesativados = true;
    _erroDesativados = null;
    notifyListeners();

    try {
      _desativados = await _service.listarDesativados();
    } catch (_) {
      _erroDesativados = 'Não foi possível carregar os produtos desativados.';
    } finally {
      _carregandoDesativados = false;
      notifyListeners();
    }
  }

  // Reativa o produto e recarrega o estoque. Retorna null se deu certo, ou a mensagem de erro
  Future<String?> reativarProduto(Produto produto) async {
    if (produto.id == null) return 'Produto inválido.';
    try {
      await _service.reativarProduto(produto.id!);
      _desativados.removeWhere((p) => p.id == produto.id);
      _registrarLogLocal('reativacao', produto.nome, 'Produto reativado no estoque');
      await carregarProdutos();
      return null;
    } catch (_) {
      return 'Não foi possível reativar o produto.';
    }
  }

  // Reativação feita pelo cadastro: a quantidade e a validade digitadas viram uma entrada.
  // reativado = false se nem a reativação deu certo; aviso traz o problema, se houver.
  Future<({bool reativado, String? aviso})> reativarComEntrada(
    Produto produto, {
    required int quantidade,
    String? validade,
  }) async {
    final erro = await reativarProduto(produto);
    if (erro != null) return (reativado: false, aviso: erro);

    try {
      if (validade != null && validade != produto.validade) {
        await _service.atualizarProduto(produto.id!, produto.copyWith(validade: validade));
      }
      if (quantidade > 0) {
        await _service.registrarEntrada(produto.id!, quantidade, motivo: 'Reposição na reativação');
      }
      await carregarProdutos();
      return (reativado: true, aviso: null);
    } catch (e) {
      debugPrint('Erro ao registrar reposição na reativação: $e');
      await carregarProdutos();
      return (
        reativado: true,
        aviso: 'Produto reativado, mas não foi possível registrar a quantidade informada. Use a tela de Entrada.',
      );
    }
  }

  // Procura um produto com nome igual ou parecido entre os ativos e os desativados.
  // ignorarId: produto que está sendo editado (não conta como repetido).
  // Lança exceção se não conseguir buscar os desativados (a tela não deixa seguir sem verificar).
  Future<NomeExistente?> buscarNomeExistente(String nome, {int? ignorarId}) async {
    _desativados = await _service.listarDesativados();
    final ativos = _produtos.where((p) => p.id != ignorarId).toList();
    final desativados = _desativados.where((p) => p.id != ignorarId).toList();
    final normalizado = Produto.normalizarNome(nome);

    for (final p in ativos) {
      if (Produto.normalizarNome(p.nome) == normalizado) return NomeExistente(p, desativado: false, igual: true);
    }
    for (final p in desativados) {
      if (Produto.normalizarNome(p.nome) == normalizado) return NomeExistente(p, desativado: true, igual: true);
    }
    for (final p in ativos) {
      if (Produto.nomesParecidos(p.nome, nome)) return NomeExistente(p, desativado: false, igual: false);
    }
    for (final p in desativados) {
      if (Produto.nomesParecidos(p.nome, nome)) return NomeExistente(p, desativado: true, igual: false);
    }
    return null;
  }

  // Deixa o texto das edições vindo da API legível ("name: A -> B" vira "Nome: A → B")
  String _traduzirAlteracoes(String motivo) {
    if (motivo.isEmpty) return 'Dados atualizados';
    return motivo
        .replaceAll('name:', 'Nome:')
        .replaceAll('unit:', 'Unidade:')
        .replaceAll(' -> ', ' → ');
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

}

// Resultado da busca por nome repetido no cadastro/edição
class NomeExistente {
  final Produto produto;
  final bool desativado;
  final bool igual; // false = nome apenas parecido (possível erro de digitação)

  NomeExistente(this.produto, {required this.desativado, required this.igual});
}

// Instância global única do Provider para controle de estado centralizado
final EstoqueProvider estoqueProvider = EstoqueProvider();