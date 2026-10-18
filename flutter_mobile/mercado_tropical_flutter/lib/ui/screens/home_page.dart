import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/summary_grid.dart';
import '../widgets/top_header.dart';
import 'entrada_screen.dart';
import 'estoque_screen.dart';
import 'log_screen.dart';
import 'saida_screen.dart';

// Página inicial com alertas ativos e botões padronizados
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    estoqueProvider.carregarProdutos();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: TropicalColors.base,
          body: SafeArea(
            child: Column(
              children: [
                const TopHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Seção que exibe apenas itens que precisam de atenção
                      const Text(
                        'ITENS QUE PRECISAM DE ATENÇÃO',
                        style: TextStyle(
                          color: TropicalColors.subtext,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SummaryGrid(
                        abrirTelaEstoqueAoClicar: true,
                        apenasAlertas: true,
                      ),
                      const SizedBox(height: 24),

                      // Botões de navegação com cor padrão unificada
                      const Text(
                        'MENU PRINCIPAL',
                        style: TextStyle(
                          color: TropicalColors.subtext,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildMenuButton(
                        context: context,
                        icone: '📦',
                        titulo: 'Consultar Estoque',
                        subtitulo: 'Ver todos os produtos, quantidades e validades',
                        onTap: () {
                          estoqueProvider.definirFiltro('todos');
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EstoqueScreen()));
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuButton(
                        context: context,
                        icone: '📥',
                        titulo: 'Registrar Entrada (+)',
                        subtitulo: 'Adicionar mercadoria que chegou ou novo produto',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EntradaScreen()));
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuButton(
                        context: context,
                        icone: '📤',
                        titulo: 'Registrar Saída (−)',
                        subtitulo: 'Retirar produtos vendidos ou vencidos',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SaidaScreen()));
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildMenuButton(
                        context: context,
                        icone: '📋',
                        titulo: 'Histórico de Movimentações',
                        subtitulo: 'Consultar registro de entradas, saídas e edições',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LogScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Botão padronizado com as cores principais do tema
  Widget _buildMenuButton({
    required BuildContext context,
    required String icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TropicalColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TropicalColors.border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TropicalColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TropicalColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(icone, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: TropicalColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}