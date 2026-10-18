import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';

// Tela de histórico com o registro de todas as ações confirmadas
class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        final logs = estoqueProvider.logs;

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
            title: const Text('Histórico de Movimentações', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: logs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma movimentação registrada ainda.\nAs entradas, saídas e alterações aparecerão aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TropicalColors.subtext, fontSize: 14),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final item = logs[index];
                    Color corBorda = TropicalColors.border;
                    String icone = '📝';

                    if (item.tipo == 'entrada' || item.tipo == 'cadastro') {
                      corBorda = TropicalColors.primary;
                      icone = '📥';
                    } else if (item.tipo == 'saida' || item.tipo == 'exclusao') {
                      corBorda = TropicalColors.danger;
                      icone = '📤';
                    } else if (item.tipo == 'edicao') {
                      corBorda = Colors.amber;
                      icone = '✏️';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TropicalColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: corBorda.withValues(alpha: 0.7), width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(icone, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.produtoNome,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                                      ),
                                    ),
                                    Text(
                                      item.dataFormatada,
                                      style: const TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.detalhe,
                                  style: const TextStyle(color: TropicalColors.text, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}