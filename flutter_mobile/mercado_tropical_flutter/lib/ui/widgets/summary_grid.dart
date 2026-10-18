import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../screens/estoque_screen.dart';
import '../theme/tropical_theme.dart';

// Painel de resumo que pode exibir todos os números ou apenas os alertas ativos
class SummaryGrid extends StatelessWidget {
  final bool abrirTelaEstoqueAoClicar;
  final bool apenasAlertas;

  const SummaryGrid({
    super.key,
    this.abrirTelaEstoqueAoClicar = false,
    this.apenasAlertas = false,
  });

  void _selecionarFiltro(BuildContext context, String filtro) {
    estoqueProvider.definirFiltro(filtro);
    if (abrirTelaEstoqueAoClicar) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EstoqueScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        final qtdBaixo = estoqueProvider.totalPoucoEstoque;
        final qtdVencendo = estoqueProvider.totalVencendoLogo;
        final qtdVencidos = estoqueProvider.totalVencidos;

        // Se estiver no modo apenasAlertas (na Home) e não houver nenhum problema:
        if (apenasAlertas && qtdBaixo == 0 && qtdVencendo == 0 && qtdVencidos == 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: TropicalColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TropicalColors.primary.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Row(
              children: [
                Text('✅', style: TextStyle(fontSize: 26)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tudo certo por aqui, nenhum item precisa de atenção.',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }

        // Monta a lista de cartões conforme o modo
        final List<Widget> cartoes = [];

        if (!apenasAlertas) {
          cartoes.add(
            _buildCard(
              titulo: 'TOTAL ITENS',
              valor: '${estoqueProvider.totalItens}',
              subtitulo: 'Produtos no sistema',
              bg: TropicalColors.card,
              borda: TropicalColors.border,
              corTitulo: TropicalColors.subtext,
              corValor: Colors.white,
              corSub: TropicalColors.primary,
              onTap: () => _selecionarFiltro(context, 'todos'),
            ),
          );
        }

        if (!apenasAlertas || qtdVencidos > 0) {
          cartoes.add(
            _buildCard(
              titulo: 'VENCIDOS!',
              valor: '$qtdVencidos',
              subtitulo: 'Retirar da prateleira!',
              bg: const Color(0xFF2E1517),
              borda: Colors.red.withValues(alpha: 0.6),
              corTitulo: Colors.red.shade300,
              corValor: Colors.red.shade400,
              corSub: Colors.red.shade100,
              onTap: () => _selecionarFiltro(context, 'vencido'),
            ),
          );
        }

        if (!apenasAlertas || qtdVencendo > 0) {
          cartoes.add(
            _buildCard(
              titulo: 'VENCENDO LOGO',
              valor: '$qtdVencendo',
              subtitulo: 'Próximos 30 dias',
              bg: TropicalColors.card,
              borda: Colors.amber.withValues(alpha: 0.5),
              corTitulo: Colors.amber.shade200,
              corValor: Colors.amber.shade400,
              corSub: TropicalColors.subtext,
              onTap: () => _selecionarFiltro(context, 'vencendo'),
            ),
          );
        }

        if (!apenasAlertas || qtdBaixo > 0) {
          cartoes.add(
            _buildCard(
              titulo: 'ESTOQUE BAIXO',
              valor: '$qtdBaixo',
              subtitulo: 'Ver para Comprar →',
              bg: const Color(0xFF332711),
              borda: Colors.amber.withValues(alpha: 0.6),
              corTitulo: Colors.amber.shade300,
              corValor: Colors.amber.shade300,
              corSub: Colors.amber.shade100,
              onTap: () => _selecionarFiltro(context, 'baixo'),
            ),
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: cartoes,
        );
      },
    );
  }

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