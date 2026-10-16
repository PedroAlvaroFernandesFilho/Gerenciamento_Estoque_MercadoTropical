import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/movimentacao_modal.dart';
import '../widgets/product_card.dart';
import '../widgets/summary_grid.dart';
import '../widgets/top_header.dart';
import 'produto_form_screen.dart';

// Tela principal do estoque
class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega os produtos ao iniciar a tela
    estoqueProvider.carregarProdutos();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        final produtos = estoqueProvider.produtosFiltrados;

        return Scaffold(
          backgroundColor: TropicalColors.base,
          body: SafeArea(
            child: Column(
              children: [
                const TopHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: estoqueProvider.carregarProdutos,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Caixa de dica de utilização
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: TropicalColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TropicalColors.border),
                          ),
                          child: const Row(
                            children: [
                              Text('💡', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Dica amiga para o Carlos:\n',
                                        style: TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: 'Toque em qualquer produto para abrir os detalhes e botões de '),
                                      TextSpan(text: 'Entrada ', style: TextStyle(color: TropicalColors.primary, fontWeight: FontWeight.w900)),
                                      TextSpan(text: 'ou '),
                                      TextSpan(text: 'Saída.', style: TextStyle(color: TropicalColors.danger, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  style: TextStyle(color: TropicalColors.text, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Grelha 2x2 de resumo
                        const SummaryGrid(),
                        const SizedBox(height: 14),

                        // Campo de pesquisa por nome
                        TextField(
                          onChanged: estoqueProvider.definirBusca,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Escreva o nome do produto (ex: arroz, café)...',
                            hintStyle: const TextStyle(color: TropicalColors.subtext, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: TropicalColors.subtext),
                            filled: true,
                            fillColor: TropicalColors.surface,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: TropicalColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: TropicalColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Botões rápidos de filtro
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            _buildFilterChip(
                              label: '⚠️ Pouco Estoque (${estoqueProvider.totalPoucoEstoque})',
                              corTexto: Colors.amber.shade300,
                              bg: const Color(0xFF1E2519),
                              onTap: () => estoqueProvider.definirFiltro('baixo'),
                            ),
                            _buildFilterChip(
                              label: '❌ Vencidos (${estoqueProvider.totalVencidos})',
                              corTexto: Colors.red.shade300,
                              bg: const Color(0xFF281518),
                              onTap: () => estoqueProvider.definirFiltro('vencido'),
                            ),
                            if (estoqueProvider.filtroStatus != 'todos')
                              _buildFilterChip(
                                label: 'Ver Todos (${estoqueProvider.totalItens})',
                                corTexto: TropicalColors.primary,
                                bg: TropicalColors.card,
                                onTap: () => estoqueProvider.definirFiltro('todos'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Listagem dos cartões de produtos
                        if (estoqueProvider.carregando)
                          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        else if (produtos.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Nenhum produto encontrado.', style: TextStyle(color: TropicalColors.subtext)),
                            ),
                          )
                        else
                          ...produtos.asMap().entries.map(
                                (entry) => ProductCard(
                                  key: ValueKey(entry.value.id),
                                  produto: entry.value,
                                  iniciarAberto: entry.key == 1,
                                ),
                              ),

                        const SizedBox(height: 8),

                        // Botão principal para cadastrar novo produto
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TropicalColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                            );
                          },
                          icon: const Text('➕', style: TextStyle(fontSize: 18)),
                          label: const Text(
                            'Cadastrar Novo Produto',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barra de navegação inferior
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF0A1912),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: TropicalColors.primary,
            unselectedItemColor: TropicalColors.subtext,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            onTap: (index) {
              if (index == 0) estoqueProvider.definirFiltro('todos');
              if (index == 1 && produtos.isNotEmpty) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MovimentacaoModal(produto: produtos.first, isEntrada: true),
                );
              }
              if (index == 2 && produtos.isNotEmpty) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MovimentacaoModal(produto: produtos.first, isEntrada: false),
                );
              }
              if (index == 3) estoqueProvider.definirFiltro('baixo');
              if (index == 4) estoqueProvider.alternarFonte();
            },
            items: const [
              BottomNavigationBarItem(icon: Text('📦', style: TextStyle(fontSize: 20)), label: 'Estoque'),
              BottomNavigationBarItem(icon: Text('📥', style: TextStyle(fontSize: 20)), label: 'Entradas'),
              BottomNavigationBarItem(icon: Text('📤', style: TextStyle(fontSize: 20)), label: 'Saídas'),
              BottomNavigationBarItem(icon: Text('🛒', style: TextStyle(fontSize: 20)), label: 'Comprar'),
              BottomNavigationBarItem(icon: Text('⚙️', style: TextStyle(fontSize: 20)), label: 'Ajustes'),
            ],
          ),
        );
      },
    );
  }

  // Botão individual de filtro rápido
  Widget _buildFilterChip({
    required String label,
    required Color corTexto,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      backgroundColor: bg,
      onPressed: onTap,
      label: Text(label, style: TextStyle(color: corTexto, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}