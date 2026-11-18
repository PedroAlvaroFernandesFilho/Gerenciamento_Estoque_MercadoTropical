// Testes da ordenação da lista de estoque e do botão de ordenação (☰)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mercado_tropical_flutter/models/produto.dart';
import 'package:mercado_tropical_flutter/provider/estoque_provider.dart';
import 'package:mercado_tropical_flutter/ui/widgets/busca_com_ordenacao.dart';

Produto produto(String nome, {int quantidade = 10, String validade = 'Sem validade'}) {
  return Produto(nome: nome, quantidade: quantidade, minimo: 5, unidade: 'pacotes', validade: validade);
}

List<String> nomes(List<Produto> lista) => lista.map((p) => p.nome).toList();

void main() {
  group('ordenarProdutos', () {
    final lista = [
      produto('Feijão', quantidade: 3, validade: '10/01/2031'),
      produto('café', quantidade: 8),
      produto('Arroz', quantidade: 3, validade: '05/01/2031'),
      produto('Água Mineral', quantidade: 20, validade: '05/01/2031'),
    ];

    test('por nome: A-Z ignorando maiúsculas e acentos', () {
      expect(nomes(EstoqueProvider.ordenarProdutos(lista, 'nome')), ['Água Mineral', 'Arroz', 'café', 'Feijão']);
    });

    test('por quantidade: menor primeiro, empate em ordem alfabética', () {
      expect(nomes(EstoqueProvider.ordenarProdutos(lista, 'quantidade')), ['Arroz', 'Feijão', 'café', 'Água Mineral']);
    });

    test('por validade: vence primeiro, sem validade no final', () {
      expect(nomes(EstoqueProvider.ordenarProdutos(lista, 'validade')), ['Água Mineral', 'Arroz', 'Feijão', 'café']);
    });

    test('não altera a lista original', () {
      EstoqueProvider.ordenarProdutos(lista, 'quantidade');
      expect(nomes(lista), ['Feijão', 'café', 'Arroz', 'Água Mineral']);
    });

    test('ordem desconhecida cai no padrão por nome', () {
      expect(nomes(EstoqueProvider.ordenarProdutos(lista, 'xyz')), ['Água Mineral', 'Arroz', 'café', 'Feijão']);
    });
  });

  test('definirOrdem guarda a escolha e avisa a tela', () {
    final provider = EstoqueProvider();
    var avisos = 0;
    provider.addListener(() => avisos++);

    expect(provider.ordem, 'nome');
    provider.definirOrdem('validade');
    expect(provider.ordem, 'validade');
    expect(avisos, 1);
  });

  group('botão de ordenação', () {
    Future<List<String>> montar(WidgetTester tester) async {
      final escolhas = <String>[];
      var ordem = 'nome';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => BuscaComOrdenacao(
                campoBusca: const TextField(),
                ordemAtual: ordem,
                onOrdenar: (nova) => setState(() {
                  ordem = nova;
                  escolhas.add(nova);
                }),
              ),
            ),
          ),
        ),
      );
      return escolhas;
    }

    testWidgets('começa fechado', (tester) async {
      await montar(tester);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.text('Menor quantidade'), findsNothing);
    });

    testWidgets('abre ao tocar e fecha sozinho depois de escolher', (tester) async {
      final escolhas = await montar(tester);

      await tester.tap(find.byKey(const Key('botao_ordenacao')));
      await tester.pumpAndSettle();
      expect(find.text('Nome (A-Z)'), findsOneWidget);
      expect(find.text('Menor quantidade'), findsOneWidget);
      expect(find.text('Vence primeiro'), findsOneWidget);

      await tester.tap(find.text('Menor quantidade'));
      await tester.pumpAndSettle();
      expect(escolhas, ['quantidade']);
      expect(find.text('Menor quantidade'), findsNothing);
    });

    testWidgets('tocar de novo no botão fecha sem mudar a ordem', (tester) async {
      final escolhas = await montar(tester);

      await tester.tap(find.byKey(const Key('botao_ordenacao')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('botao_ordenacao')));
      await tester.pumpAndSettle();

      expect(find.text('Vence primeiro'), findsNothing);
      expect(escolhas, isEmpty);
    });
  });
}