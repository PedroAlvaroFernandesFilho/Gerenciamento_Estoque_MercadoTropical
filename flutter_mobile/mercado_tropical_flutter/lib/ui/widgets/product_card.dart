import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../screens/produto_form_screen.dart';
import '../theme/tropical_theme.dart';
import 'confirmacao_dialog.dart';

class ProductCard extends StatelessWidget {
  final Produto produto;

  const ProductCard({super.key, required this.produto});

  @override
  Widget build(BuildContext context) {
    final p = produto;

    // Define a cor da borda conforme a prioridade de alerta (incluindo Sem Estoque)
    Color corBorda = TropicalColors.border;
    if (p.isVencido) {
      corBorda = Colors.redAccent;
    } else if (p.isSemEstoque) {
      corBorda = Colors.red.shade400;
    } else if (p.isPoucoEstoque || p.isVencendoLogo) {
      corBorda = Colors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TropicalColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: corBorda.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho: Ícone + Nome + Quantidade Atual
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TropicalColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TropicalColors.border),
                ),
                child: Text(p.icone, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Validade: ${p.validade} • Mín: ${p.minimo} ${p.unidade}',
                      style: const TextStyle(
                        color: TropicalColors.subtext,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Caixa de quantidade destacada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: TropicalColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: corBorda.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${p.quantidade}',
                      style: TextStyle(
                        color: p.isSemEstoque
                            ? Colors.redAccent
                            : (p.isPoucoEstoque ? Colors.amber : TropicalColors.primary),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      p.unidade,
                      style: const TextStyle(
                        color: TropicalColors.subtext,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Etiquetas de Alerta (Vencido, Vencendo, Sem Estoque, Pouco Estoque)
          if (p.isVencido || p.isVencendoLogo || p.isSemEstoque || p.isPoucoEstoque) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (p.isVencido)
                  _buildBadge('🚨 VENCIDO', Colors.redAccent),
                if (p.isVencendoLogo)
                  _buildBadge('⏳ VENCE LOGO', Colors.orangeAccent),
                if (p.isSemEstoque)
                  _buildBadge('🚫 SEM ESTOQUE (0)', Colors.red.shade400),
                if (p.isPoucoEstoque)
                  _buildBadge('⚠️ POUCO ESTOQUE', Colors.amber),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // 3. Botões de Ação (Entrada, Saída, Editar e Desativar)
          Row(
            children: [
              // Botão de Entrada (+)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TropicalColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _abrirModalMovimentacao(context, p, isEntrada: true),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Entrada', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),

              // Botão de Saída (-) -> Desabilitado se já estiver sem estoque (0)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: TropicalColors.border, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: p.isSemEstoque
                      ? null
                      : () => _abrirModalMovimentacao(context, p, isEntrada: false),
                  icon: const Icon(Icons.remove_rounded, size: 20),
                  label: const Text('Saída', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Botão Editar
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TropicalColors.subtext,
                    side: const BorderSide(color: TropicalColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProdutoFormScreen(produtoExistente: p),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),

              // Botão Desativar (Soft Delete) - Corrigido com corConfirmar
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade300,
                    side: BorderSide(color: Colors.orange.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final confirmado = await mostrarConfirmacao(
                      context: context,
                      titulo: 'Desativar Produto?',
                      mensagem:
                          'Deseja desativar "${p.nome}"?\n\nEle não aparecerá mais na lista ativa do estoque, mas todo o histórico de movimentações será preservado.',
                      textoConfirmar: 'Sim, Desativar',
                      corConfirmar: TropicalColors.danger,
                    );
                    if (confirmado) {
                      estoqueProvider.desativarProduto(p);
                    }
                  },
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('Desativar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.6)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Modal de Entrada (+) e Saída (-) embutido direto no Card
  void _abrirModalMovimentacao(BuildContext context, Produto p, {required bool isEntrada}) {
    int qtd = 1;
    final corTema = isEntrada ? TropicalColors.primary : Colors.orangeAccent;

    showModalBottomSheet(
      context: context,
      backgroundColor: TropicalColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEntrada ? '➕ ENTRADA DE ESTOQUE' : '➖ SAÍDA DE ESTOQUE',
                      style: TextStyle(
                        color: corTema,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${p.icone} ${p.nome} (Atual: ${p.quantidade} ${p.unidade})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: TropicalColors.card,
                            minimumSize: const Size(54, 54),
                          ),
                          onPressed: qtd > 1 ? () => setModalState(() => qtd--) : null,
                          icon: const Icon(Icons.remove, color: Colors.white, size: 28),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            '$qtd',
                            style: TextStyle(
                              color: corTema,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: corTema,
                            minimumSize: const Size(54, 54),
                          ),
                          onPressed: (!isEntrada && qtd >= p.quantidade)
                              ? null
                              : () => setModalState(() => qtd++),
                          icon: const Icon(Icons.add, color: Colors.black, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corTema,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (isEntrada) {
                            await estoqueProvider.registrarEntrada(p, qtd);
                          } else {
                            await estoqueProvider.registrarSaida(p, qtd);
                          }
                        },
                        child: Text(
                          isEntrada
                              ? 'Confirmar Entrada (+$qtd ${p.unidade})'
                              : 'Confirmar Saída (-$qtd ${p.unidade})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}