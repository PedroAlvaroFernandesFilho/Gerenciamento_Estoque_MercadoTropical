import 'package:flutter/material.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';

// Cabeçalho superior com logótipo, botão de fonte e saudação
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
              // Logótipo que limpa os filtros ao ser tocado
              InkWell(
                onTap: () => estoqueProvider.definirFiltro('todos'),
                child: Row(
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
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Botões da direita (Tamanho da letra e Utilizador)
              Row(
                children: [
                  InkWell(
                    onTap: estoqueProvider.alternarFonte,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: TropicalColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            estoqueProvider.isLargeFont ? 'Letra\nPadrão' : 'Letra\n+A',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: TropicalColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TropicalColors.border),
                    ),
                    child: const Row(
                      children: [
                        Text('👨‍🌾', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 6),
                        Text(
                          'Olá,\nCarlos',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}