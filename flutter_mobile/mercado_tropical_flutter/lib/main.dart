import 'package:flutter/material.dart';
import 'provider/estoque_provider.dart';
import 'ui/screens/home_page.dart';

// Inicialização da aplicação apontando para a HomePage
void main() {
  runApp(const MercadoTropicalApp());
}

class MercadoTropicalApp extends StatelessWidget {
  const MercadoTropicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estoqueProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Mercado Tropical',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(estoqueProvider.isLargeFont ? 1.14 : 1.0),
              ),
              child: child!,
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}