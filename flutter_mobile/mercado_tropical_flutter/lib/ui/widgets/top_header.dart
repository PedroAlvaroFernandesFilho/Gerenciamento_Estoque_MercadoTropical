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
              Row(
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
                  const Text(
                    'MERCADO\nTROPICAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1.1,
                    ),
                  ),
                ],
              ),

              // Botão para alternar tamanho da letra
              InkWell(
                onTap: estoqueProvider.alternarFonte,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: TropicalColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        estoqueProvider.isLargeFont ? 'Letra Padrão' : 'Letra Grande (+A)',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
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