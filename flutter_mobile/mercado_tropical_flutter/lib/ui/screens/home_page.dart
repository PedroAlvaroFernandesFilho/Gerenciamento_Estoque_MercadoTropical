import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';
import '../widgets/summary_grid.dart';
import '../widgets/top_header.dart';
import 'entrada_screen.dart';
import 'estoque_screen.dart';
import 'log_screen.dart';
import 'saida_screen.dart';

// Página inicial sincronizada com a API e o banco de dados Supabase
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Busca os produtos reais da API assim que a Home abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      estoqueProvider.carregarProdutos();
    });
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
                  child: RefreshIndicator(
                    color: TropicalColors.primary,
                    backgroundColor: TropicalColors.surface,
                    onRefresh: estoqueProvider.carregarProdutos,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Cabeçalho da seção com botão de sincronizar com o banco
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'ITENS QUE PRECISAM DE ATENÇÃO',
                                style: TextStyle(
                                  color: TropicalColors.subtext,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: estoqueProvider.carregando
                                  ? null
                                  : () => estoqueProvider.carregarProdutos(),
                              icon: const Icon(Icons.sync_rounded, color: TropicalColors.primary, size: 18),
                              label: const Text(
                                'Sincronizar',
                                style: TextStyle(
                                  color: TropicalColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Estado de Carregamento, Erro de Conexão ou Resumo do Banco
                        if (estoqueProvider.carregando)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: TropicalColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: TropicalColors.border),
                            ),
                            child: const Column(
                              children: [
                                CircularProgressIndicator(color: TropicalColors.primary),
                                SizedBox(height: 12),
                                Text(
                                  'Sincronizando com o banco de dados...',
                                  style: TextStyle(color: TropicalColors.text, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else if (estoqueProvider.erroMensagem != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: TropicalColors.dangerBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: TropicalColors.danger, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '⚠️ ${estoqueProvider.erroMensagem}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Verifique se o Uvicorn está rodando (uvicorn app.main:app --reload) e se o CORSMiddleware foi adicionado ao main.py.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: TropicalColors.subtext, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: TropicalColors.primary),
                                  onPressed: estoqueProvider.carregarProdutos,
                                  icon: const Icon(Icons.refresh, color: Colors.black),
                                  label: const Text(
                                    'Tentar Conectar Novamente',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SummaryGrid(
                            abrirTelaEstoqueAoClicar: true,
                            apenasAlertas: true,
                          ),

                        const SizedBox(height: 24),

                        // Menu Principal
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
                          titulo: 'Consultar Estoque (${estoqueProvider.totalItens})',
                          subtitulo: 'Ver todos os produtos do banco, quantidades e validades',
                          onTap: () async {
                            estoqueProvider.definirFiltro('todos');
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EstoqueScreen()));
                            // Recarrega ao voltar para manter a Home sempre em sincronia
                            estoqueProvider.carregarProdutos();
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildMenuButton(
                          context: context,
                          icone: '📥',
                          titulo: 'Registrar Entrada (+)',
                          subtitulo: 'Adicionar mercadoria que chegou ou novo produto',
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EntradaScreen()));
                            estoqueProvider.carregarProdutos();
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildMenuButton(
                          context: context,
                          icone: '📤',
                          titulo: 'Registrar Saída (−)',
                          subtitulo: 'Retirar produtos vendidos ou vencidos',
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const SaidaScreen()));
                            estoqueProvider.carregarProdutos();
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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