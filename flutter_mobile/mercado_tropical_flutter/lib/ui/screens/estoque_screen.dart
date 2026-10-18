import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/summary_grid.dart';

// Tela de estoque com painel numérico completo, busca e lista de produtos
class EstoqueScreen extends StatelessWidget {
  const EstoqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        final produtos = estoqueProvider.produtosFiltrados;

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
            title: const Text('Produtos em Estoque', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Painel completo com os números do estoque
              const SummaryGrid(
                abrirTelaEstoqueAoClicar: false,
                apenasAlertas: false,
              ),
              const SizedBox(height: 14),

              // Legenda explicativa de cores e ícones
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TropicalColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TropicalColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cor Vermelha indica produto vencido (prioridade). O triângulo amarelo (⚠️) ao lado do número avisa que o estoque está baixo.',
                        style: TextStyle(color: TropicalColors.text, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Barra de busca
              TextField(
                onChanged: estoqueProvider.definirBusca,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar produto pelo nome...',
                  hintStyle: const TextStyle(color: TropicalColors.subtext, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: TropicalColors.subtext),
                  filled: true,
                  fillColor: TropicalColors.surface,
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

              // Chips de filtro
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildFilterChip(
                    label: 'Todos (${estoqueProvider.totalItens})',
                    selecionado: estoqueProvider.filtroStatus == 'todos',
                    cor: TropicalColors.primary,
                    onTap: () => estoqueProvider.definirFiltro('todos'),
                  ),
                  _buildFilterChip(
                    label: '⚠️ Estoque Baixo (${estoqueProvider.totalPoucoEstoque})',
                    selecionado: estoqueProvider.filtroStatus == 'baixo',
                    cor: Colors.amber.shade300,
                    onTap: () => estoqueProvider.definirFiltro('baixo'),
                  ),
                  _buildFilterChip(
                    label: '⏳ Vencendo (${estoqueProvider.totalVencendoLogo})',
                    selecionado: estoqueProvider.filtroStatus == 'vencendo',
                    cor: Colors.orange.shade300,
                    onTap: () => estoqueProvider.definirFiltro('vencendo'),
                  ),
                  _buildFilterChip(
                    label: '❌ Vencidos (${estoqueProvider.totalVencidos})',
                    selecionado: estoqueProvider.filtroStatus == 'vencido',
                    cor: Colors.red.shade300,
                    onTap: () => estoqueProvider.definirFiltro('vencido'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de cartões de produtos
              if (produtos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Nenhum produto encontrado para este filtro.',
                      style: TextStyle(color: TropicalColors.subtext),
                    ),
                  ),
                )
              else
                ...produtos.map(
                  (prod) => ProductCard(
                    key: ValueKey(prod.id),
                    produto: prod,
                    iniciarAberto: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selecionado,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selecionado ? Colors.black : cor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
      selected: selecionado,
      selectedColor: cor,
      backgroundColor: TropicalColors.card,
      onSelected: (_) => onTap(),
    );
  }
}