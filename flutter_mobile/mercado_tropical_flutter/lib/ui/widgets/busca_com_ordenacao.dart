import 'package:flutter/material.dart';
import '../theme/tropical_theme.dart';

// Opções de ordenação da lista de estoque (valor usado no provider -> texto e ícone)
const Map<String, (String, IconData)> opcoesOrdenacao = {
  'nome': ('Nome (A-Z)', Icons.sort_by_alpha_rounded),
  'quantidade': ('Menor quantidade', Icons.inventory_2_outlined),
  'validade': ('Vence primeiro', Icons.event_rounded),
};

// Campo de busca com o botão de ordenação (☰) ao lado.
// O botão abre as opções logo abaixo, e elas se fecham sozinhas depois que uma é escolhida.
class BuscaComOrdenacao extends StatefulWidget {
  final Widget campoBusca;
  final String ordemAtual;
  final ValueChanged<String> onOrdenar;

  const BuscaComOrdenacao({
    super.key,
    required this.campoBusca,
    required this.ordemAtual,
    required this.onOrdenar,
  });

  @override
  State<BuscaComOrdenacao> createState() => _BuscaComOrdenacaoState();
}

class _BuscaComOrdenacaoState extends State<BuscaComOrdenacao> {
  bool _aberto = false;

  void _escolher(String ordem) {
    setState(() => _aberto = false);
    widget.onOrdenar(ordem);
  }

  @override
  Widget build(BuildContext context) {
    // Botão fica verde quando aberto ou quando a lista não está na ordem padrão (nome)
    final destacado = _aberto || widget.ordemAtual != 'nome';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: widget.campoBusca),
            const SizedBox(width: 8),
            Tooltip(
              message: _aberto ? 'Fechar ordenação' : 'Ordenar lista',
              child: Material(
                color: destacado ? TropicalColors.primary : TropicalColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: destacado ? TropicalColors.primary : TropicalColors.border),
                ),
                child: InkWell(
                  key: const Key('botao_ordenacao'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _aberto = !_aberto),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.menu_rounded,
                      size: 26,
                      color: destacado ? Colors.black : TropicalColors.text,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Painel de opções com animação de abrir e fechar
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _aberto ? _painelOpcoes() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _painelOpcoes() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TropicalColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TropicalColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ordenar por',
            style: TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opcao in opcoesOrdenacao.entries) _botaoOpcao(opcao.key, opcao.value.$1, opcao.value.$2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoOpcao(String ordem, String texto, IconData icone) {
    final selecionado = ordem == widget.ordemAtual;
    return ChoiceChip(
      key: Key('ordem_$ordem'),
      avatar: Icon(icone, size: 18, color: selecionado ? Colors.black : TropicalColors.text),
      label: Text(
        texto,
        style: TextStyle(
          color: selecionado ? Colors.black : TropicalColors.text,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
      selected: selecionado,
      showCheckmark: false,
      selectedColor: TropicalColors.primary,
      backgroundColor: TropicalColors.card,
      onSelected: (_) => _escolher(ordem),
    );
  }
}