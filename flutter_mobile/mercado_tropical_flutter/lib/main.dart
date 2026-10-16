import 'package:flutter/material.dart';
import 'provider/estoque_provider.dart';
import 'ui/screens/estoque_screen.dart';

// Ponto de entrada da aplicação
void main() {
  runApp(const MercadoTropicalApp());
}

class MercadoTropicalApp extends StatelessWidget {
  const MercadoTropicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta alterações no tamanho da letra para atualizar toda a aplicação
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Mercado Tropical',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true),
          builder: (context, child) {
            // Aplica o aumento de 14% na fonte quando ativado
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(estoqueProvider.isLargeFont ? 1.14 : 1.0),
              ),
              child: child!,
            );
          },
          home: const EstoqueScreen(),
        );
      },
    );
  }
}