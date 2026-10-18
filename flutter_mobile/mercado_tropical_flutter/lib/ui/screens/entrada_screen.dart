import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/confirmacao_dialog.dart';
import 'produto_form_screen.dart';

// Tela de entrada com item selecionado destacado acima da barra de pesquisa
class EntradaScreen extends StatefulWidget {
  const EntradaScreen({super.key});

  @override
  State<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends State<EntradaScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _produtoSelecionadoId;
  int _quantidadeAdicionar = 5;
  String _buscaLocal = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Pergunta ao utilizador se deseja selecionar o item e rola a tela para o topo
  Future<void> _tentarSelecionarProduto(Produto prod) async {
    final confirmado = await mostrarConfirmacao(
      context: context,
      titulo: 'Selecionar Produto?',
      mensagem: 'Deseja selecionar "${prod.nome}" para adicionar estoque?',
      textoConfirmar: 'Sim, Selecionar',
      corConfirmar: TropicalColors.primary,
    );

    if (confirmado && mounted) {
      setState(() {
        _produtoSelecionadoId = prod.id;
        _quantidadeAdicionar = 5;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        final todos = estoqueProvider.todosProdutos;

        Produto? produtoEmEdicao;
        if (_produtoSelecionadoId != null) {
          final idx = todos.indexWhere((p) => p.id == _produtoSelecionadoId);
          if (idx != -1) produtoEmEdicao = todos[idx];
        }

        final listaInferior = todos.where((p) {
          final naoEstaEmEdicao = p.id != _produtoSelecionadoId;
          final bateBusca = p.nome.toLowerCase().contains(_buscaLocal.toLowerCase());
          return naoEstaEmEdicao && bateBusca;
        }).toList();

        return Scaffold(
          backgroundColor: TropicalColors.base,
          appBar: AppBar(
            backgroundColor: TropicalColors.surface,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 28),
              tooltip: 'Voltar ao Início',
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Registrar Entrada (+)', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Botão de Novo Produto sempre em primeiro no topo
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    backgroundColor: TropicalColors.card,
                    side: const BorderSide(color: TropicalColors.primary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdutoFormScreen()));
                  },
                  icon: const Text('➕', style: TextStyle(fontSize: 18)),
                  label: const Flexible(
                    child: Text(
                      'Cadastrar um Produto Novo no Sistema',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TropicalColors.primary, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Área do Item Separado para Alteração
              if (produtoEmEdicao != null) ...[
                _buildPainelEdicaoEntrada(produtoEmEdicao),
                const SizedBox(height: 22),
              ],

              // 3. Barra de Pesquisa
              const Text(
                'PROCURAR PRODUTO PARA ENTRADA:',
                style: TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (val) => setState(() => _buscaLocal = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Digite o nome do produto...',
                  hintStyle: const TextStyle(color: TropicalColors.subtext, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: TropicalColors.subtext),
                  filled: true,
                  fillColor: TropicalColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TropicalColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TropicalColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Lista de itens do estoque
              const Text(
                'TOQUE EM UM ITEM ABAIXO PARA SELECIONAR:',
                style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (listaInferior.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Nenhum outro produto encontrado.', style: TextStyle(color: TropicalColors.subtext)),
                  ),
                )
              else
                ...listaInferior.map((prod) => _buildCardItemLista(prod)),
            ],
          ),
        );
      },
    );
  }

  // Painel expandido protegido contra overflow horizontal
  Widget _buildPainelEdicaoEntrada(Produto prod) {
    final novoTotal = prod.quantidade + _quantidadeAdicionar;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TropicalColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TropicalColors.primary, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do item separado com Expanded para evitar overflow
          Row(
            children: [
              const Expanded(
                child: Text(
                  '📌 ITEM SELECIONADO PARA ENTRADA',
                  style: TextStyle(color: TropicalColors.primary, fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _produtoSelecionadoId = null),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: TropicalColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TropicalColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 15, color: TropicalColors.subtext),
                      SizedBox(width: 4),
                      Text('Trocar', style: TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: TropicalColors.border, height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: TropicalColors.card, borderRadius: BorderRadius.circular(12)),
                child: Text(prod.icone, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prod.nome, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(
                      'Estoque atual: ${prod.quantidade} ${prod.unidade}',
                      style: const TextStyle(color: TropicalColors.subtext, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Comparativo Antes vs Depois
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TropicalColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TropicalColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('HOJE', style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('${prod.quantidade}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text(prod.unidade, style: const TextStyle(color: TropicalColors.subtext, fontSize: 11)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: TropicalColors.border),
                Expanded(
                  child: Column(
                    children: [
                      const Text('NOVO TOTAL', style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('$novoTotal', style: const TextStyle(color: TropicalColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text(prod.unidade, style: const TextStyle(color: TropicalColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Botões de ajuste de quantidade
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TropicalColors.base,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TropicalColors.primary, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    if (_quantidadeAdicionar > 1) setState(() => _quantidadeAdicionar--);
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: TropicalColors.cardHighlight, borderRadius: BorderRadius.circular(12)),
                    child: const Text('−', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('+$_quantidadeAdicionar', style: const TextStyle(color: TropicalColors.primary, fontSize: 30, fontWeight: FontWeight.w900)),
                      Text(
                        'adicionar (${prod.unidade})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: TropicalColors.subtext, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _quantidadeAdicionar++),
                  child: Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: TropicalColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: const Text('+', style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botão de Salvar Entrada com verificação final
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TropicalColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final confirmado = await mostrarConfirmacao(
                  context: context,
                  titulo: 'Salvar Entrada?',
                  mensagem:
                      'Confirma a adição de +$_quantidadeAdicionar ${prod.unidade} em "${prod.nome}"?\n\nO estoque passará para $novoTotal ${prod.unidade}.',
                  textoConfirmar: 'Sim, Salvar',
                  corConfirmar: TropicalColors.primary,
                );

                if (confirmado && mounted) {
                  await estoqueProvider.registrarEntrada(prod, _quantidadeAdicionar);
                  if (mounted) {
                    setState(() => _produtoSelecionadoId = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: TropicalColors.primary,
                        content: Text('✅ Entrada registrada com sucesso!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                '✓ Confirmar Entrada',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cartão compacto da lista inferior
  Widget _buildCardItemLista(Produto prod) {
    final semEstoque = prod.quantidade == 0;

    return InkWell(
      onTap: () => _tentarSelecionarProduto(prod),
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: semEstoque ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: semEstoque ? const Color(0xFF1A1D1B) : TropicalColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: semEstoque ? Colors.grey.shade700 : TropicalColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: semEstoque ? Colors.grey.shade800 : TropicalColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(prod.icone, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.nome,
                      style: TextStyle(
                        color: semEstoque ? Colors.grey.shade400 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          semEstoque ? 'Sem estoque (0)' : 'Estoque: ${prod.quantidade} ${prod.unidade}',
                          style: TextStyle(
                            color: semEstoque
                                ? Colors.grey.shade400
                                : (prod.isPoucoEstoque ? Colors.amber.shade300 : TropicalColors.subtext),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (prod.isPoucoEstoque && !semEstoque)
                          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: semEstoque ? Colors.grey.shade800 : TropicalColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: semEstoque ? Colors.grey : TropicalColors.primary.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Selecionar',
                  style: TextStyle(
                    color: semEstoque ? Colors.grey.shade300 : TropicalColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}