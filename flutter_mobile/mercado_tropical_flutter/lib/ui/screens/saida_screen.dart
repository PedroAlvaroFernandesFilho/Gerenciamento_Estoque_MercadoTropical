import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/confirmacao_dialog.dart';

// Tela de saída com seleção prévia e itens sem estoque em cinza
class SaidaScreen extends StatefulWidget {
  const SaidaScreen({super.key});

  @override
  State<SaidaScreen> createState() => _SaidaScreenState();
}

class _SaidaScreenState extends State<SaidaScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _produtoSelecionadoId;
  int _quantidadeRetirar = 1;
  String _motivo = 'Venda';
  String _buscaLocal = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Confirma se deseja selecionar o item e puxa a tela para o topo
  Future<void> _tentarSelecionarProduto(Produto prod) async {
    if (prod.quantidade == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey.shade800,
          content: Text('O produto "${prod.nome}" está sem estoque (0) para retirada.', style: const TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final confirmado = await mostrarConfirmacao(
      context: context,
      titulo: 'Selecionar para Saída?',
      mensagem: 'Deseja selecionar "${prod.nome}" para retirar unidades do estoque?',
      textoConfirmar: 'Sim, Selecionar',
      corConfirmar: TropicalColors.primary,
    );

    if (confirmado && mounted) {
      setState(() {
        _produtoSelecionadoId = prod.id;
        _quantidadeRetirar = 1;
        _motivo = prod.isVencido ? 'Descarte / Vencido' : 'Venda';
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
          if (idx != -1 && todos[idx].quantidade > 0) {
            produtoEmEdicao = todos[idx];
          } else {
            _produtoSelecionadoId = null;
          }
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
            title: const Text('Registrar Saída (−)', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Painel de Alteração no Topo
              if (produtoEmEdicao != null) ...[
                _buildPainelEdicaoSaida(produtoEmEdicao),
                const SizedBox(height: 22),
              ],

              // 2. Barra de Pesquisa
              const Text(
                'PROCURAR PRODUTO PARA RETIRADA:',
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

              // 3. Lista de Produtos abaixo da pesquisa
              const Text(
                'TOQUE EM UM ITEM ABAIXO PARA RETIRAR:',
                style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (listaInferior.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Nenhum produto encontrado.', style: TextStyle(color: TropicalColors.subtext)),
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

  // Painel superior do item separado para retirada (sem overflow)
  Widget _buildPainelEdicaoSaida(Produto prod) {
    final novoTotal = (prod.quantidade - _quantidadeRetirar) < 0 ? 0 : (prod.quantidade - _quantidadeRetirar);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TropicalColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TropicalColors.danger, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '📌 ITEM SELECIONADO PARA SAÍDA',
                  style: TextStyle(color: TropicalColors.danger, fontSize: 12, fontWeight: FontWeight.w900),
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
                      'Disponível: ${prod.quantidade} ${prod.unidade}',
                      style: const TextStyle(color: TropicalColors.subtext, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Seletor de Motivo
          const Text('MOTIVO DA SAÍDA:', style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('🛒 Venda')),
                  selected: _motivo == 'Venda',
                  selectedColor: TropicalColors.primary,
                  backgroundColor: TropicalColors.card,
                  labelStyle: TextStyle(
                    color: _motivo == 'Venda' ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  onSelected: (_) => setState(() => _motivo = 'Venda'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('🗑️ Descarte')),
                  selected: _motivo == 'Descarte / Vencido',
                  selectedColor: TropicalColors.danger,
                  backgroundColor: TropicalColors.card,
                  labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  onSelected: (_) => setState(() => _motivo = 'Descarte / Vencido'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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
                      const Text('NA PRATELEIRA', style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('${prod.quantidade}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text(prod.unidade, style: const TextStyle(color: TropicalColors.subtext, fontSize: 11)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: TropicalColors.border),
                Expanded(
                  child: Column(
                    children: [
                      const Text('RESTARÁ', style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('$novoTotal', style: const TextStyle(color: TropicalColors.danger, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text(prod.unidade, style: const TextStyle(color: TropicalColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Controle de quantidade a retirar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TropicalColors.base,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TropicalColors.danger, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    if (_quantidadeRetirar > 1) setState(() => _quantidadeRetirar--);
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
                      Text('−$_quantidadeRetirar', style: const TextStyle(color: TropicalColors.danger, fontSize: 30, fontWeight: FontWeight.w900)),
                      Text(
                        'retirar (${prod.unidade})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: TropicalColors.subtext, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (_quantidadeRetirar < prod.quantidade) setState(() => _quantidadeRetirar++);
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: TropicalColors.danger, borderRadius: BorderRadius.circular(12)),
                    child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botão de Salvar Saída com confirmação final
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TropicalColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final confirmado = await mostrarConfirmacao(
                  context: context,
                  titulo: 'Salvar Retirada?',
                  mensagem:
                      'Confirma a saída de $_quantidadeRetirar ${prod.unidade} de "${prod.nome}" ($_motivo)?\n\nRestarão $novoTotal ${prod.unidade} no estoque.',
                  textoConfirmar: 'Sim, Retirar',
                  corConfirmar: TropicalColors.danger,
                );

                if (confirmado && mounted) {
                  await estoqueProvider.registrarSaida(prod, _quantidadeRetirar, _motivo);
                  if (mounted) {
                    setState(() => _produtoSelecionadoId = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: TropicalColors.danger,
                        content: Text('✅ Saída registrada com sucesso!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                '✓ Confirmar Saída',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cartão da lista inferior (Fica cinza se o estoque for 0)
  Widget _buildCardItemLista(Produto prod) {
    final semEstoque = prod.quantidade == 0;

    return InkWell(
      onTap: () => _tentarSelecionarProduto(prod),
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: semEstoque ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: semEstoque ? const Color(0xFF1A1D1B) : TropicalColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: semEstoque
                  ? Colors.grey.shade700
                  : (prod.isVencido ? Colors.red.shade400 : TropicalColors.border),
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
                          semEstoque ? 'ESGOTADO (0)' : 'Disponível: ${prod.quantidade} ${prod.unidade}',
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
                  border: Border.all(color: semEstoque ? Colors.grey : TropicalColors.danger.withValues(alpha: 0.6)),
                ),
                child: Text(
                  semEstoque ? 'Sem Estoque' : 'Selecionar',
                  style: TextStyle(
                    color: semEstoque ? Colors.grey.shade400 : Colors.red.shade300,
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