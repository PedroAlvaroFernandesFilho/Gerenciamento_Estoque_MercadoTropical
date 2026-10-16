import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';

// Grelha 2x2 com os cartões de resumo do estoque
class SummaryGrid extends StatelessWidget {
  const SummaryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _buildCard(
              titulo: 'TOTAL ITENS',
              valor: '${estoqueProvider.totalItens}',
              subtitulo: 'Produtos no sistema',
              bg: TropicalColors.card,
              borda: TropicalColors.border,
              corTitulo: TropicalColors.subtext,
              corValor: Colors.white,
              corSub: TropicalColors.primary,
              onTap: () => estoqueProvider.definirFiltro('todos'),
            ),
            _buildCard(
              titulo: 'FALTA POUCO',
              valor: '${estoqueProvider.totalPoucoEstoque}',
              subtitulo: 'Ver para Comprar →',
              bg: const Color(0xFF332711),
              borda: Colors.amber.withValues(alpha: 0.6),
              corTitulo: Colors.amber.shade300,
              corValor: Colors.amber.shade300,
              corSub: Colors.amber.shade100,
              onTap: () => estoqueProvider.definirFiltro('baixo'),
            ),
            _buildCard(
              titulo: 'VENCENDO LOGO',
              valor: '${estoqueProvider.totalPoucoEstoque}',
              subtitulo: 'Atenção na prateleira',
              bg: TropicalColors.card,
              borda: Colors.amber.withValues(alpha: 0.3),
              corTitulo: Colors.amber.shade100,
              corValor: Colors.amber.shade300,
              corSub: TropicalColors.subtext,
              onTap: () => estoqueProvider.definirFiltro('baixo'),
            ),
            _buildCard(
              titulo: 'VENCIDO!',
              valor: '${estoqueProvider.totalVencidos}',
              subtitulo: 'Tirar da loja hoje!',
              bg: const Color(0xFF2E1517),
              borda: Colors.red.withValues(alpha: 0.6),
              corTitulo: Colors.red.shade300,
              corValor: Colors.red.shade400,
              corSub: Colors.red.shade100,
              onTap: () => estoqueProvider.definirFiltro('vencido'),
            ),
          ],
        );
      },
    );
  }

  // Estrutura individual de cada cartão da grelha
  Widget _buildCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required Color bg,
    required Color borda,
    required Color corTitulo,
    required Color corValor,
    required Color corSub,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borda, width: 1.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(titulo, style: TextStyle(color: corTitulo, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(valor, style: TextStyle(color: corValor, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitulo, style: TextStyle(color: corSub, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}