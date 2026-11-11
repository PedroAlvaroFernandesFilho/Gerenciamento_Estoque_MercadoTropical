import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/configuracoes_provider.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/confirmacao_dialog.dart';

// Formulário de cadastro e edição com ícone detectado automaticamente pelo nome
class ProdutoFormScreen extends StatefulWidget {
  final Produto? produtoExistente;

  const ProdutoFormScreen({super.key, this.produtoExistente});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;

  String _unidadeSelecionada = 'pacotes';
  int _estoqueInicial = 10;
  int _estoqueMinimo = 5;
  DateTime _dataValidade = DateTime.now().add(const Duration(days: 180));

  final List<String> _unidades = ['pacotes', 'unidades', 'caixas', 'latas', 'quilos', 'litros', 'fardos'];

  // Valores ao abrir a tela, para saber se algo foi alterado antes de sair
  late final String _nomeOriginal;
  late final String _unidadeOriginal;
  late final int _estoqueOriginal;
  late final int _minimoOriginal;
  late final DateTime _validadeOriginal;

  // Evita salvar duas vezes com toques repetidos no botão
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.produtoExistente;
    _nomeCtrl = TextEditingController(text: p?.nome ?? '');

    if (p != null) {
      final unidadeAtual = p.unidade.toLowerCase();
      // 'kg' passa a ser 'quilos' (a API exige pelo menos 3 letras na unidade)
      // Mesma unidade na forma plural da lista ("lata" e "latas" viram "latas")
      final unidadeNaLista = Produto.unidadePara(2, unidadeAtual);
      _unidadeSelecionada = unidadeAtual == 'kg'
          ? 'quilos'
          : (_unidades.contains(unidadeNaLista) ? unidadeNaLista : 'unidades');
      _estoqueInicial = p.quantidade;
      _estoqueMinimo = p.minimo;
      _dataValidade = _converterTextoParaData(p.validade) ?? DateTime.now().add(const Duration(days: 90));
    }

    _nomeOriginal = _nomeCtrl.text.trim();
    _unidadeOriginal = _unidadeSelecionada;
    _estoqueOriginal = _estoqueInicial;
    _minimoOriginal = _estoqueMinimo;
    _validadeOriginal = _dataValidade;
  }

  // True se o usuário preencheu ou mudou algo desde que abriu a tela
  bool get _temAlteracoes =>
      _nomeCtrl.text.trim() != _nomeOriginal ||
      _unidadeSelecionada != _unidadeOriginal ||
      _estoqueInicial != _estoqueOriginal ||
      _estoqueMinimo != _minimoOriginal ||
      _dataValidade != _validadeOriginal;

  // Pergunta antes de sair com dados não salvos (seta, botão voltar do Android e do navegador)
  Future<void> _confirmarSaida() async {
    final editando = widget.produtoExistente != null;
    final sair = await mostrarConfirmacao(
      context: context,
      titulo: editando ? 'Descartar Alterações?' : 'Cancelar Registro?',
      mensagem: editando
          ? 'Deseja mesmo descartar as alterações feitas neste produto?'
          : 'Deseja mesmo cancelar o registro? Os dados preenchidos serão perdidos.',
      textoConfirmar: 'Sim',
      textoCancelar: 'Não',
      corConfirmar: TropicalColors.danger,
    );
    if (sair && mounted) Navigator.pop(context);
  }

  void _avisar(String texto, {bool erro = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: erro ? TropicalColors.danger : TropicalColors.primary,
        content: Text(
          texto,
          style: TextStyle(color: erro ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Verifica se já existe produto com nome igual ou parecido.
  // Retorna true se o salvamento pode continuar.
  Future<bool> _verificarNomeRepetido(String nome) async {
    final existente = widget.produtoExistente;
    final editando = existente != null;

    // Na edição, só verifica se o nome mudou
    if (existente != null && Produto.normalizarNome(nome) == Produto.normalizarNome(existente.nome)) return true;

    NomeExistente? achado;
    try {
      achado = await estoqueProvider.buscarNomeExistente(nome, ignorarId: existente?.id);
    } catch (e) {
      debugPrint('Erro ao verificar nome repetido: $e');
      if (mounted) _avisar('Não foi possível verificar se o produto já existe. Tente novamente.');
      return false;
    }
    if (achado == null) return true;
    if (!mounted) return false;

    final p = achado.produto;

    // Nome igual a um produto ativo: não cadastra outro
    if (achado.igual && !achado.desativado) {
      _avisar(editando
          ? 'Já existe outro produto chamado "${p.nome}". Escolha outro nome.'
          : 'Já existe um produto chamado "${p.nome}" no estoque. Para adicionar unidades, use a tela de Entrada.');
      return false;
    }

    // Nome igual a um produto desativado: sugere reativar
    if (achado.igual && achado.desativado) {
      if (editando) {
        _avisar('Já existe um produto desativado chamado "${p.nome}". Reative-o em Produtos Desativados.');
        return false;
      }
      final reativar = await mostrarConfirmacao(
        context: context,
        titulo: 'Produto Já Cadastrado',
        mensagem: '"${p.nome}" já existe e está desativado.\n\nDeseja reativá-lo? '
            '${_estoqueInicial > 0 ? 'A quantidade informada (${Produto.quantidadeComUnidade(_estoqueInicial, _unidadeSelecionada)}) será registrada como entrada e a validade será atualizada.' : 'A validade informada será atualizada.'}',
        textoConfirmar: 'Sim, Reativar',
        textoCancelar: 'Não',
      );
      if (reativar && mounted) await _reativarExistente(p);
      return false;
    }

    // Nome parecido (possível erro de digitação): o usuário decide
    final situacao = achado.desativado ? 'desativado' : 'no estoque';
    final mesmo = await mostrarConfirmacao(
      context: context,
      titulo: 'Produto Parecido Encontrado',
      mensagem: editando
          ? 'Já existe um produto com nome parecido: "${p.nome}" ($situacao).\n\nDeseja salvar mesmo assim?'
          : 'Encontramos um produto parecido: "${p.nome}" ($situacao).\n\nÉ o mesmo produto?',
      textoConfirmar: editando ? 'Não, Corrigir' : 'Sim, É o Mesmo',
      textoCancelar: editando ? 'Salvar Assim' : 'Não, É Outro',
    );
    // Botão da esquerda: segue com o salvamento
    if (!mesmo) return true;
    if (!mounted || editando) return false;

    if (achado.desativado) {
      await _reativarExistente(p);
    } else {
      _avisar('"${p.nome}" já está no estoque. Para adicionar unidades, use a tela de Entrada.');
    }
    return false;
  }

  // Reativa o produto encontrado e aproveita a quantidade e a validade digitadas
  Future<void> _reativarExistente(Produto p) async {
    final resultado = await estoqueProvider.reativarComEntrada(
      p,
      quantidade: _estoqueInicial,
      validade: _validadeFormatada,
    );
    if (!mounted) return;

    if (!resultado.reativado) {
      _avisar(resultado.aviso ?? 'Não foi possível reativar o produto.');
      return;
    }
    if (resultado.aviso != null) {
      _avisar(resultado.aviso!);
    } else {
      _avisar('✅ "${p.nome}" foi reativado.', erro: false);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  DateTime? _converterTextoParaData(String texto) {
    try {
      final partes = texto.split('/');
      if (partes.length != 3) return null;
      return DateTime(int.parse(partes[2]), int.parse(partes[1]), int.parse(partes[0]));
    } catch (_) {
      return null;
    }
  }

  String get _validadeFormatada {
    final dia = _dataValidade.day.toString().padLeft(2, '0');
    final mes = _dataValidade.month.toString().padLeft(2, '0');
    final ano = _dataValidade.year.toString();
    return '$dia/$mes/$ano';
  }

  Future<void> _selecionarDataCalendario() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataValidade,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'SELECIONE A DATA DE VALIDADE',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar Data',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: TropicalColors.primary,
              onPrimary: Colors.black,
              surface: TropicalColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (escolhida != null) {
      setState(() => _dataValidade = escolhida);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.produtoExistente != null;
    final padronizar = editando ? configuracoesProvider.padronizarEdicao : configuracoesProvider.padronizarCadastro;
    final nomeAtual = padronizar ? Produto.formatarNome(_nomeCtrl.text) : Produto.limparEspacos(_nomeCtrl.text);
    final iconeAutomatico = Produto.iconesAtivos ? Produto.iconePorNome(nomeAtual) : '📦';

    // Com dados não salvos, voltar pede confirmação antes de sair
    return PopScope(
      canPop: !_temAlteracoes,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSaida();
      },
      child: Scaffold(
        backgroundColor: TropicalColors.base,
        appBar: AppBar(
          backgroundColor: TropicalColors.surface,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            tooltip: 'Voltar',
            // maybePop passa pelo PopScope (pergunta antes de sair se houver alterações)
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            editando ? 'Editar Dados do Produto' : 'Cadastrar Novo Produto',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cartão de Pré-visualização com Ícone Automático
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TropicalColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TropicalColors.primary.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TropicalColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(iconeAutomatico, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomeAtual.isEmpty ? 'Digite o nome abaixo...' : nomeAtual,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              editando
                                  ? 'Ícone automático • Unidade: $_unidadeSelecionada'
                                  : 'Ícone automático • Val: $_validadeFormatada • Mín: ${Produto.quantidadeComUnidade(_estoqueMinimo, _unidadeSelecionada)}',
                              style: const TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Nome do Produto
                _buildTituloSecao('1. NOME / DESCRIÇÃO DO PRODUTO (DEFINE O ÍCONE AUTOMATICAMENTE):'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomeCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  // A API recusa nomes com menos de 3 letras; avisa aqui antes de enviar
                  validator: (val) {
                    final nome = val?.trim() ?? '';
                    if (nome.isEmpty) return 'Digite o nome do produto';
                    if (nome.length < 3) return 'O nome precisa ter pelo menos 3 letras';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Ex: Arroz Tio João 5kg, Café Pilão, Leite...',
                    hintStyle: const TextStyle(color: TropicalColors.subtext),
                    filled: true,
                    fillColor: TropicalColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: TropicalColors.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: TropicalColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Tipo de Unidade
                _buildTituloSecao('2. COMO ESTE ITEM É CONTADO?'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _unidades.map((un) {
                    final selecionado = un == _unidadeSelecionada;
                    return ChoiceChip(
                      label: Text(
                        un.toUpperCase(),
                        style: TextStyle(
                          color: selecionado ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      selected: selecionado,
                      selectedColor: TropicalColors.primary,
                      backgroundColor: TropicalColors.card,
                      onSelected: (_) => setState(() => _unidadeSelecionada = un),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 4. Data de Validade (apenas no cadastro)
                if (!editando) ...[
                _buildTituloSecao('3. DATA DE VALIDADE DO LOTE:'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selecionarDataCalendario,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: TropicalColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: TropicalColors.primary.withValues(alpha: 0.7), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: TropicalColors.primary, size: 26),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vence no dia:',
                                  style: TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _validadeFormatada,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: TropicalColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: TropicalColors.border),
                          ),
                          child: const Text(
                            'Trocar Data',
                            style: TextStyle(color: TropicalColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Estoque Mínimo (apenas no cadastro)
                _buildTituloSecao('4. AVISAR ESTOQUE BAIXO (⚠️) QUANDO CHEGAR EM:'),
                const SizedBox(height: 8),
                _buildContadorVisual(
                  valor: _estoqueMinimo,
                  subtitulo: 'mínimo ideal ($_unidadeSelecionada)',
                  corDestaque: Colors.amber,
                  onDiminuir: () {
                    if (_estoqueMinimo > 0) setState(() => _estoqueMinimo--);
                  },
                  onAumentar: () => setState(() => _estoqueMinimo++),
                ),
                const SizedBox(height: 20),
                ],

                // 6. Estoque Inicial (Apenas na criação)
                if (!editando) ...[
                  _buildTituloSecao('5. QUANTIDADE INICIAL NA PRATELEIRA:'),
                  const SizedBox(height: 8),
                  _buildContadorVisual(
                    valor: _estoqueInicial,
                    subtitulo: 'estoque inicial ($_unidadeSelecionada)',
                    corDestaque: TropicalColors.primary,
                    onDiminuir: () {
                      if (_estoqueInicial > 0) setState(() => _estoqueInicial--);
                    },
                    onAumentar: () => setState(() => _estoqueInicial++),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TropicalColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TropicalColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: TropicalColors.subtext, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aqui você altera apenas o nome e a unidade do produto.\nEstoque atual: ${Produto.quantidadeComUnidade(_estoqueInicial, _unidadeSelecionada)}. Para somar ou retirar unidades, use as telas de Entrada e Saída.',
                            style: const TextStyle(color: TropicalColors.subtext, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 7. Botão de Salvar no Supabase
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TropicalColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (_salvando) return;
                      if (_formKey.currentState!.validate()) {
                        _salvando = true;
                        try {
                          // Nome igual ou parecido com outro produto: avisa, sugere reativar ou interrompe
                          final podeSeguir = await _verificarNomeRepetido(nomeAtual);
                          if (!podeSeguir || !context.mounted) return;

                          // Na edição, só nome e unidade mudam; quantidade, mínimo e validade são preservados.
                          final produtoSalvo = editando
                              ? widget.produtoExistente!.copyWith(
                                  nome: nomeAtual,
                                  unidade: _unidadeSelecionada,
                                )
                              : Produto(
                                  nome: nomeAtual,
                                  quantidade: _estoqueInicial,
                                  minimo: _estoqueMinimo,
                                  unidade: _unidadeSelecionada,
                                  validade: _validadeFormatada,
                                  icone: iconeAutomatico,
                                );

                          final confirmado = await mostrarConfirmacao(
                            context: context,
                            titulo: editando ? 'Salvar Alterações?' : 'Cadastrar Produto?',
                            mensagem: editando
                                ? 'Deseja salvar as alterações em "${produtoSalvo.nome}"?'
                                : 'Deseja cadastrar "${produtoSalvo.nome}" com ${Produto.quantidadeComUnidade(_estoqueInicial, _unidadeSelecionada)}?',
                            textoConfirmar: 'Sim, Salvar',
                          );

                          if (confirmado && context.mounted) {
                            final erro = editando
                                ? await estoqueProvider.editarProduto(produtoSalvo)
                                : await estoqueProvider.adicionarProduto(produtoSalvo);
                            if (!context.mounted) return;

                            // Em caso de erro, mostra o aviso e continua no formulário
                            if (erro != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: TropicalColors.danger,
                                  content: Text(
                                    erro,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context);
                          }
                        } finally {
                          _salvando = false;
                        }
                      }
                    },
                    child: Text(
                      editando ? '✓ Salvar Alterações' : '➕ Cadastrar Produto',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),

                // 8. Desativar produto (apenas na edição)
                if (editando) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade300,
                        side: BorderSide(color: Colors.orange.shade700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final p = widget.produtoExistente!;
                        final confirmado = await mostrarConfirmacao(
                          context: context,
                          titulo: 'Desativar Produto?',
                          mensagem:
                              'Deseja desativar "${p.nome}"?\n\nEle não aparecerá mais na lista ativa do estoque, mas todo o histórico de movimentações será preservado.\nVocê pode reativá-lo em "Produtos Desativados".',
                          textoConfirmar: 'Sim, Desativar',
                          corConfirmar: TropicalColors.danger,
                        );
                        if (!confirmado || !context.mounted) return;

                        final ok = await estoqueProvider.desativarProduto(p);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: ok ? TropicalColors.primary : TropicalColors.danger,
                            content: Text(
                              ok ? '✅ Produto desativado.' : 'Não foi possível desativar o produto.',
                              style: TextStyle(
                                color: ok ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                        if (ok) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.visibility_off_outlined, size: 18),
                      label: const Text('Desativar Produto', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTituloSecao(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: TropicalColors.subtext,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildContadorVisual({
    required int valor,
    required String subtitulo,
    required Color corDestaque,
    required VoidCallback onDiminuir,
    required VoidCallback onAumentar,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TropicalColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corDestaque.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onDiminuir,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TropicalColors.cardHighlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('−', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$valor',
                  style: TextStyle(color: corDestaque, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onAumentar,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: corDestaque,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('+', style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}