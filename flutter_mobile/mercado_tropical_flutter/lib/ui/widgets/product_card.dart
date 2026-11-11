import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../screens/produto_form_screen.dart';
import '../theme/tropical_theme.dart';

class ProductCard extends StatefulWidget {
  final Produto produto;

  const ProductCard({super.key, required this.produto});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // Começa recolhido; ao tocar no card ele expande e mostra o botão Editar
  bool _expandido = false;

  // Tons de cinza ameno usados quando o produto está sem estoque
  static const Color _cinzaCard = Color(0xFF222826);
  static const Color _cinzaSuperficie = Color(0xFF1B201E);
  static const Color _cinzaBorda = Color(0xFF4A524F);
  static const Color _cinzaTexto = Color(0xFF8A9490);
  static const Color _cinzaSubtexto = Color(0xFF69726E);

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    final semEstoque = p.isSemEstoque;

    // Sem estoque tem prioridade: o card inteiro fica cinza (não há o que vencer na prateleira).
    // Nos demais casos, a borda segue a prioridade de alerta.
    Color corBorda = TropicalColors.border;
    if (semEstoque) {
      corBorda = _cinzaBorda;
    } else if (p.isVencido) {
      corBorda = Colors.redAccent;
    } else if (p.isPoucoEstoque || p.isVencendoLogo) {
      corBorda = Colors.amber;
    }

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semEstoque ? _cinzaCard : TropicalColors.card,
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
                  color: semEstoque ? _cinzaSuperficie : TropicalColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: semEstoque ? _cinzaBorda : TropicalColors.border),
                ),
                child: semEstoque
                    ? ColorFiltered(
                        // Emoji em escala de cinza e levemente apagado
                        colorFilter: const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 0.55, 0,
                        ]),
                        child: Text(p.icone, style: const TextStyle(fontSize: 28)),
                      )
                    : Text(p.icone, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nome,
                      style: TextStyle(
                        color: semEstoque ? _cinzaTexto : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Validade: ${p.validade} • Mín: ${Produto.quantidadeComUnidade(p.minimo, p.unidade)}',
                      style: TextStyle(
                        color: semEstoque ? _cinzaSubtexto : TropicalColors.subtext,
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
                  color: semEstoque ? _cinzaSuperficie : TropicalColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: corBorda.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${p.quantidade}',
                      style: TextStyle(
                        color: semEstoque
                            ? _cinzaTexto
                            : (p.isPoucoEstoque ? Colors.amber : TropicalColors.primary),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      Produto.unidadePara(p.quantidade, p.unidade),
                      style: TextStyle(
                        color: semEstoque ? _cinzaSubtexto : TropicalColors.subtext,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Seta que gira ao expandir/recolher
              AnimatedRotation(
                turns: _expandido ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 22,
                  color: semEstoque ? _cinzaSubtexto : TropicalColors.subtext,
                ),
              ),
            ],
          ),

          // 2. Etiquetas de Alerta (Vencido, Vencendo, Pouco Estoque).
          // Sem estoque não exibe etiqueta: o card cinza já comunica o estado.
          if (!semEstoque && (p.isVencido || p.isVencendoLogo || p.isPoucoEstoque)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (p.isVencido)
                  _buildBadge('🚨 VENCIDO', Colors.redAccent),
                if (p.isVencendoLogo)
                  _buildBadge('⏳ VENCE LOGO', Colors.orangeAccent),
                if (p.isPoucoEstoque)
                  _buildBadge('⚠️ POUCO ESTOQUE', Colors.amber),
              ],
            ),
          ],

          // 3. Única ação do card: editar nome e unidade (só aparece com o card expandido).
          // Entrada e saída ficam nas telas próprias de Entrada e Saída.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expandido
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: semEstoque ? _cinzaSubtexto : TropicalColors.subtext,
                          side: BorderSide(color: semEstoque ? _cinzaBorda : TropicalColors.border),
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
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
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
}