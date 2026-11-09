import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';

// Cabeçalho superior sem nomes pessoais e com controle de tamanho da fonte
class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: TropicalColors.surface,
            border: Border(bottom: BorderSide(color: TropicalColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logotipo do sistema
              // Flexible + ellipsis: em telas estreitas o texto encolhe em vez de estourar a tela
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: TropicalColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TropicalColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🌴', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'MERCADO\nTROPICAL',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Botão para alternar tamanho da letra
              Flexible(
                child: InkWell(
                  onTap: estoqueProvider.alternarFonte,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: TropicalColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            estoqueProvider.isLargeFont ? 'Letra Padrão' : 'Letra Grande (+A)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}