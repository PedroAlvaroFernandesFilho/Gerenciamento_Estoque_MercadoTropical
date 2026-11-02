import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/confirmacao_dialog.dart';

// Tela de produtos desativados: o item selecionado sobe para o topo e pode ser reativado
class DesativadosScreen extends StatefulWidget {
  const DesativadosScreen({super.key});

  @override
  State<DesativadosScreen> createState() => _DesativadosScreenState();
}

class _DesativadosScreenState extends State<DesativadosScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _produtoSelecionadoId;
  String _buscaLocal = '';

  @override
  void initState() {
    super.initState();
    // Busca a lista de desativados ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      estoqueProvider.carregarDesativados();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Confirma a seleção e rola a tela para o topo
  Future<void> _tentarSelecionarProduto(Produto prod) async {
    final confirmado = await mostrarConfirmacao(
      context: context,
      titulo: 'Selecionar Produto?',
      mensagem: 'Deseja selecionar "${prod.nome}" para reativá-lo?',
      textoConfirmar: 'Sim, Selecionar',
      corConfirmar: TropicalColors.primary,
    );

    if (confirmado && mounted) {
      setState(() => _produtoSelecionadoId = prod.id);
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
        final desativados = estoqueProvider.produtosDesativados;

        Produto? produtoSelecionado;
        if (_produtoSelecionadoId != null) {
          final idx = desativados.indexWhere((p) => p.id == _produtoSelecionadoId);
          if (idx != -1) produtoSelecionado = desativados[idx];
        }

        final listaInferior = desativados.where((p) {
          final naoEstaSelecionado = p.id != _produtoSelecionadoId;
          final bateBusca = p.nome.toLowerCase().contains(_buscaLocal.toLowerCase());
          return naoEstaSelecionado && bateBusca;
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
            title: const Text('Produtos Desativados', style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync_rounded, color: TropicalColors.primary, size: 26),
                tooltip: 'Atualizar lista',
                onPressed: estoqueProvider.carregandoDesativados ? null : estoqueProvider.carregarDesativados,
              ),
            ],
          ),
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Explicação
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TropicalColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TropicalColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: TropicalColors.subtext, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Produtos desativados não aparecem no estoque, na entrada nem na saída. O histórico deles é mantido.',
                        style: TextStyle(color: TropicalColors.text, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Produto selecionado para reativar
              if (produtoSelecionado != null) ...[
                _buildPainelReativacao(produtoSelecionado),
                const SizedBox(height: 22),
              ],

              // 3. Barra de Pesquisa
              const Text(
                'PROCURAR PRODUTO DESATIVADO:',
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

              // 4. Lista de desativados
              const Text(
                'TOQUE EM UM ITEM ABAIXO PARA SELECIONAR:',
                style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (estoqueProvider.carregandoDesativados)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: TropicalColors.primary)),
                )
              else if (estoqueProvider.erroDesativados != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: TropicalColors.dangerBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TropicalColors.danger),
                  ),
                  child: Column(
                    children: [
                      Text(
                        estoqueProvider.erroDesativados!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: TropicalColors.primary),
                        onPressed: estoqueProvider.carregarDesativados,
                        child: const Text('Tentar Novamente', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              else if (listaInferior.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      desativados.isEmpty ? 'Nenhum produto desativado.' : 'Nenhum outro produto encontrado.',
                      style: const TextStyle(color: TropicalColors.subtext),
                    ),
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

  // Painel do produto selecionado com o botão de reativar
  Widget _buildPainelReativacao(Produto prod) {
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '📌 PRODUTO SELECIONADO PARA REATIVAR',
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
                      'Estoque registrado: ${prod.quantidade} ${prod.unidade}',
                      style: const TextStyle(color: TropicalColors.subtext, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Validade: ${prod.validade} • Mín: ${prod.minimo} ${prod.unidade}',
                      style: const TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: TropicalColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final confirmado = await mostrarConfirmacao(
                  context: context,
                  titulo: 'Reativar Produto?',
                  mensagem:
                      'Deseja reativar "${prod.nome}"?\n\nEle voltará a aparecer no estoque com ${prod.quantidade} ${prod.unidade}.',
                  textoConfirmar: 'Sim, Reativar',
                  corConfirmar: TropicalColors.primary,
                );

                if (confirmado && mounted) {
                  final erro = await estoqueProvider.reativarProduto(prod);
                  if (mounted) {
                    setState(() => _produtoSelecionadoId = null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: erro == null ? TropicalColors.primary : TropicalColors.danger,
                        content: Text(
                          erro ?? '✅ Produto reativado com sucesso!',
                          style: TextStyle(
                            color: erro == null ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.restore_rounded, size: 22),
              label: const Text(
                'Reativar Produto',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cartão acinzentado da lista (mesmo estilo dos itens sem estoque da entrada)
  Widget _buildCardItemLista(Produto prod) {
    return InkWell(
      onTap: () => _tentarSelecionarProduto(prod),
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: 0.6,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D1B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade700, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
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
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Desativado • ${prod.quantidade} ${prod.unidade}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Text(
                  'Selecionar',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
