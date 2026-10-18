import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../screens/produto_form_screen.dart';
import '../theme/tropical_theme.dart';
import 'confirmacao_dialog.dart';

// Cartão de exibição de cada produto no estoque
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
    final semEstoque = p.quantidade == 0;
    final statusVal = p.statusValidade; // 'vencido', 'vencendo', 'normal'

    // Se estiver sem estoque (0), perde a cor e fica em cinza.
    // Caso contrário, prioriza a cor de acordo com a validade.
    Color bgCard = TropicalColors.card;
    Color bordaCard = TropicalColors.border;
    Widget badgeValidade;

    if (semEstoque) {
      bgCard = const Color(0xFF1A1D1B);
      bordaCard = Colors.grey.shade700;
      badgeValidade = _buildBadge('SEM ESTOQUE', Colors.grey.shade700, Colors.white);
    } else if (statusVal == 'vencido') {
      bgCard = TropicalColors.dangerBg;
      bordaCard = Colors.red.shade500;
      badgeValidade = _buildBadge('❌ VENCIDO', Colors.red.shade600, Colors.white);
    } else if (statusVal == 'vencendo') {
      bgCard = TropicalColors.warningBg;
      bordaCard = Colors.amber.shade600;
      badgeValidade = _buildBadge('⏳ Vencendo', const Color(0xFF332711), Colors.amber.shade300);
    } else {
      badgeValidade = _buildBadge('Validade OK', TropicalColors.surface, TropicalColors.primary);
    }

    return Opacity(
      opacity: semEstoque ? 0.65 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bordaCard, width: 2),
        ),
        child: Column(
          children: [
            // Cabeçalho clicável do produto (Responsivo contra overflow)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expandido = !_expandido),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: semEstoque ? Colors.grey.shade800 : Colors.black26,
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
                            style: TextStyle(
                              color: semEstoque ? Colors.grey.shade400 : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Wrap impede que o texto + triângulo amarelo estourem a largura da tela
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                semEstoque ? 'Esgotado (0 ${p.unidade})' : 'Estoque: ${p.quantidade} ${p.unidade}',
                                style: TextStyle(
                                  color: semEstoque
                                      ? Colors.grey.shade400
                                      : (p.isPoucoEstoque ? Colors.amber.shade300 : TropicalColors.subtext),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (p.isPoucoEstoque && !semEstoque)
                                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    badgeValidade,
                    const SizedBox(width: 6),
                    Text(
                      _expandido ? '▲' : '▼',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Corpo expandido com detalhes
            if (_expandido)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    const Divider(color: Colors.white12),
                    if (semEstoque)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade600),
                        ),
                        child: Text(
                          'Produto esgotado. Registre uma entrada quando chegar nova remessa.',
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (p.isVencido && !semEstoque)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: const Text(
                          '❌ Ação Urgente: Produto vencido! Retirar da prateleira.',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (p.isPoucoEstoque && !semEstoque)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B2212),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estoque Baixo: Restam ${p.quantidade} ${p.unidade} (Mínimo ideal: ${p.minimo}).',
                                style: TextStyle(color: Colors.amber.shade200, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Caixa de Quantidade e Validade
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: semEstoque ? Colors.grey.shade700 : TropicalColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Na Prateleira:', style: TextStyle(color: TropicalColors.subtext, fontSize: 12)),
                                const SizedBox(height: 2),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      '${p.quantidade}',
                                      style: TextStyle(
                                        color: semEstoque
                                            ? Colors.grey.shade400
                                            : (p.isPoucoEstoque ? Colors.amber.shade300 : Colors.white),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      p.unidade,
                                      style: const TextStyle(color: TropicalColors.subtext, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    if (p.isPoucoEstoque && !semEstoque)
                                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Validade:', style: TextStyle(color: TropicalColors.subtext, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                p.validade,
                                style: TextStyle(
                                  color: semEstoque
                                      ? Colors.grey.shade400
                                      : (p.isVencido
                                          ? Colors.red.shade300
                                          : (p.isVencendoLogo ? Colors.amber.shade300 : Colors.white)),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botões de Editar e Excluir
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProdutoFormScreen(produtoExistente: p)),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18, color: TropicalColors.subtext),
                          label: const Text('Editar Dados', style: TextStyle(color: TropicalColors.subtext, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () async {
                            final confirmado = await mostrarConfirmacao(
                              context: context,
                              titulo: 'Excluir Produto?',
                              mensagem: 'Deseja realmente apagar "${p.nome}" do sistema? Esta ação não pode ser desfeita.',
                              textoConfirmar: 'Sim, Excluir',
                              corConfirmar: TropicalColors.danger,
                            );
                            if (confirmado) {
                              await estoqueProvider.removerProduto(p);
                            }
                          },
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                          label: Text('Excluir', style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String texto, Color bg, Color corTexto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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