import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';

// Janela modal inferior para registar entrada (+) ou saída (-) de mercadoria
class MovimentacaoModal extends StatefulWidget {
  final Produto produto;
  final bool isEntrada;

  const MovimentacaoModal({
    super.key,
    required this.produto,
    required this.isEntrada,
  });

  @override
  State<MovimentacaoModal> createState() => _MovimentacaoModalState();
}

class _MovimentacaoModalState extends State<MovimentacaoModal> {
  late int quantidadeMovimento;

  @override
  void initState() {
    super.initState();
    // Inicia com 5 para entrada e 1 para saída
    quantidadeMovimento = widget.isEntrada ? 5 : 1;
  }

  // Calcula como ficará o estoque após confirmar
  int get novoTotal {
    if (widget.isEntrada) {
      return widget.produto.quantidade + quantidadeMovimento;
    } else {
      final res = widget.produto.quantidade - quantidadeMovimento;
      return res < 0 ? 0 : res;
    }
  }

  @override
  Widget build(BuildContext context) {
    final corDestaque = widget.isEntrada ? TropicalColors.primary : TropicalColors.danger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TropicalColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: corDestaque, width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior indicadora do modal
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Cabeçalho com ícone e nome do produto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TropicalColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TropicalColors.border),
                        ),
                        child: Text(widget.produto.icone, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isEntrada ? 'Chegou Mais\nMercadoria' : 'Registrar\nSaída / Venda',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.produto.nome,
                              style: const TextStyle(color: TropicalColors.subtext, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quadro comparativo: Estoque Hoje vs Novo Total
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TropicalColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TropicalColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('ESTOQUE HOJE:', style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('${widget.produto.quantidade}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        Text(widget.produto.unidade, style: const TextStyle(color: TropicalColors.subtext, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: TropicalColors.border),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('NOVO TOTAL:', style: TextStyle(color: TropicalColors.subtext, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$novoTotal', style: TextStyle(color: corDestaque, fontSize: 24, fontWeight: FontWeight.w900)),
                        Text('na prateleira', style: TextStyle(color: corDestaque, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              widget.isEntrada
                  ? 'Quantos ${widget.produto.unidade} chegaram do fornecedor?'
                  : 'Quantos ${widget.produto.unidade} saíram da prateleira?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Controlador de quantidade com botões - e +
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TropicalColors.base,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: corDestaque, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (quantidadeMovimento > 1) {
                        setState(() => quantidadeMovimento--);
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TropicalColors.cardHighlight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('−', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$quantidadeMovimento',
                        style: TextStyle(color: corDestaque, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        widget.isEntrada ? 'adicionar ao estoque' : 'retirar do estoque',
                        style: const TextStyle(color: TropicalColors.subtext, fontSize: 12),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => setState(() => quantidadeMovimento++),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: corDestaque,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('+', style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botões de ação (Voltar e Salvar)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: TropicalColors.border),
                      backgroundColor: TropicalColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: corDestaque,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await estoqueProvider.atualizarQuantidade(widget.produto, novoTotal);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: TropicalColors.primary,
                            content: Text(
                              widget.isEntrada ? '✅ Entrada salva com sucesso!' : '✅ Saída registrada com sucesso!',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      widget.isEntrada ? '✓ Salvar Entrada' : '✓ Salvar Saída',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}