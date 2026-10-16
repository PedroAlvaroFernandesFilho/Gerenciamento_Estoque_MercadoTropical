import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../screens/produto_form_screen.dart';
import '../theme/tropical_theme.dart';
import 'movimentacao_modal.dart';

// Cartão expansível de cada produto na lista
class ProductCard extends StatefulWidget {
  final Produto produto;
  final bool iniciarAberto;

  const ProductCard({
    super.key,
    required this.produto,
    this.iniciarAberto = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _expandido;

  @override
  void initState() {
    super.initState();
    _expandido = widget.iniciarAberto;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final status = p.status;

    // Define cores e selos de acordo com o status do produto
    Color bgCard = TropicalColors.card;
    Color bordaCard = TropicalColors.border;
    Widget badgeStatus;

    if (status == 'vencido') {
      bgCard = TropicalColors.dangerBg;
      bordaCard = Colors.red.shade400;
      badgeStatus = _buildBadge('❌ VENCIDO', Colors.red.shade600, Colors.white);
    } else if (status == 'baixo') {
      bgCard = TropicalColors.warningBg;
      bordaCard = Colors.amber.shade500;
      badgeStatus = _buildBadge('⚠️ Pouco Estoque', const Color(0xFF332711), Colors.amber.shade300);
    } else {
      badgeStatus = _buildBadge('Normal', TropicalColors.surface, TropicalColors.primary);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bordaCard, width: 2),
      ),
      child: Column(
        children: [
          // Cabeçalho do cartão (abre/fecha ao tocar)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(p.icone, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nome,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mínimo: ${p.minimo}',
                                style: const TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      badgeStatus,
                      const SizedBox(width: 8),
                      Text(
                        _expandido ? '▲' : '▼',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Área interna visível quando o cartão está aberto
          if (_expandido)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(color: Colors.white12),
                  // Alerta caso esteja vencido
                  if (status == 'vencido')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: const Text(
                        'Ação Urgente: Tirar estes pacotes da prateleira hoje!',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  // Alerta caso esteja com pouco estoque
                  if (status == 'baixo')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2212),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '📢 Atenção Senhor Carlos: Restam apenas ${p.quantidade}! Anotar para compra.',
                        style: TextStyle(color: Colors.amber.shade200, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),

                  // Informações de quantidade e validade
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TropicalColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tem na Prateleira:', style: TextStyle(color: TropicalColors.subtext, fontSize: 12)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${p.quantidade}',
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 6),
                                Text(p.unidade, style: const TextStyle(color: TropicalColors.subtext, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Validade:', style: TextStyle(color: TropicalColors.subtext, fontSize: 12)),
                            Text(
                              p.validade,
                              style: TextStyle(
                                color: status == 'vencido' ? Colors.red.shade300 : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botões de Entrada (+) e Saída (-)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F4B36),
                            foregroundColor: TropicalColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => MovimentacaoModal(produto: p, isEntrada: true),
                            );
                          },
                          icon: const Text('➕'),
                          label: const Text('Chegou (+)', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B1C1F),
                            foregroundColor: Colors.red.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => MovimentacaoModal(produto: p, isEntrada: false),
                            );
                          },
                          icon: const Text('➖'),
                          label: const Text('Vendeu (−)', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),

                  // Botões para Editar ou Excluir o produto
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductFormScreen(produtoExistente: p)),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16, color: TropicalColors.subtext),
                        label: const Text('Editar produto', style: TextStyle(color: TropicalColors.subtext, fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          if (p.id != null) {
                            await estoqueProvider.removerProduto(p.id!);
                          }
                        },
                        icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                        label: Text('Excluir', style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Etiqueta colorida de status
  Widget _buildBadge(String texto, Color bg, Color corTexto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(color: corTexto, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}