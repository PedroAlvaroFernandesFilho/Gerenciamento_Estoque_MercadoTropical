// Teste básico: o app abre e mostra a tela inicial.

import 'package:flutter_test/flutter_test.dart';

import 'package:mercado_tropical_flutter/main.dart';

void main() {
  testWidgets('App abre na tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const MercadoTropicalApp());
    await tester.pump();

    // Textos fixos do topo da Home, aparecem mesmo sem conexão com a API
    expect(find.text('Atualizar'), findsOneWidget);
    expect(find.text('MENU PRINCIPAL'), findsOneWidget);
  });
}