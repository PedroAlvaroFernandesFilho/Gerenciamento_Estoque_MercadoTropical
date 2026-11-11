// Testes das regras do modelo Produto (nome, ícones, unidades, datas e status)
import 'package:flutter_test/flutter_test.dart';

import 'package:mercado_tropical_flutter/models/produto.dart';

String dataBr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

Produto produto({int quantidade = 10, int minimo = 5, String validade = 'Sem validade', String nome = 'Arroz'}) {
  return Produto(nome: nome, quantidade: quantidade, minimo: minimo, unidade: 'pacotes', validade: validade);
}

void main() {
  group('formatarNome', () {
    test('deixa a inicial de cada palavra em maiúsculo', () {
      expect(Produto.formatarNome('arroz 5kg ouro fino'), 'Arroz 5kg Ouro Fino');
    });

    test('nome todo em maiúsculo vira o padrão', () {
      expect(Produto.formatarNome('FEIJÃO CARIOCA'), 'Feijão Carioca');
    });

    test('conectivos ficam minúsculos no meio do nome', () {
      expect(Produto.formatarNome('pão DE forma'), 'Pão de Forma');
    });

    test('mantém siglas curtas em maiúsculo', () {
      expect(Produto.formatarNome('leite UHT integral'), 'Leite UHT Integral');
    });

    test('palavras com número não mudam', () {
      expect(Produto.formatarNome('refri 2L'), 'Refri 2L');
    });

    test('remove espaços extras', () {
      expect(Produto.formatarNome('  café   pilão '), 'Café Pilão');
    });
  });

  test('limparEspacos tira espaços sobrando sem mudar maiúsculas', () {
    expect(Produto.limparEspacos('  Café   PILÃO '), 'Café PILÃO');
  });

  group('comparação de nomes', () {
    test('normalizarNome ignora maiúsculas, acentos e espaços', () {
      expect(Produto.normalizarNome('Café  Pilão'), Produto.normalizarNome('cafe pilao'));
    });

    test('detecta erro de digitação', () {
      expect(Produto.nomesParecidos('Aroz 5kg Ouro Fino', 'Arroz 5kg Ouro Fino'), isTrue);
    });

    test('números diferentes nunca são parecidos', () {
      expect(Produto.nomesParecidos('Arroz 1kg Ouro Fino', 'Arroz 5kg Ouro Fino'), isFalse);
    });

    test('nomes iguais não contam como parecidos (são tratados à parte)', () {
      expect(Produto.nomesParecidos('Feijão Preto', 'feijao preto'), isFalse);
    });

    test('nomes diferentes não são parecidos', () {
      expect(Produto.nomesParecidos('Café Pilão', 'Café Melitta'), isFalse);
    });
  });

  group('ícones automáticos', () {
    tearDown(() => Produto.iconesAtivos = true);

    test('escolhe o ícone pela palavra inteira', () {
      expect(Produto.iconePorNome('Bolacha Recheada'), '🍪');
      expect(Produto.iconePorNome('Salsicha Hot Dog'), '🥓');
      expect(Produto.iconePorNome('Ovos Brancos'), '🥚');
    });

    test('expressões específicas vêm antes da palavra solta', () {
      expect(Produto.iconePorNome('Água Sanitária 1L'), '🧼');
      expect(Produto.iconePorNome('Massa de Tomate'), '🥫');
    });

    test('nome desconhecido usa a caixa', () {
      expect(Produto.iconePorNome('Produto Xyz'), '📦');
    });

    test('com ícones desativados todos usam a caixa', () {
      Produto.iconesAtivos = false;
      expect(produto(nome: 'Café Pilão').icone, '📦');
    });
  });

  group('unidades no singular e plural', () {
    test('quantidade 1 fica no singular', () {
      expect(Produto.unidadePara(1, 'latas'), 'lata');
      expect(Produto.quantidadeComUnidade(1, 'litros'), '1 litro');
    });

    test('zero e mais de um ficam no plural', () {
      expect(Produto.unidadePara(0, 'lata'), 'latas');
      expect(Produto.quantidadeComUnidade(5, 'caixa'), '5 caixas');
    });

    test('unidade fora da lista aparece como está salva', () {
      expect(Produto.unidadePara(1, 'kg'), 'kg');
    });
  });

  group('conversão com a API', () {
    test('fromJson converte a data para o formato brasileiro', () {
      final p = Produto.fromJson({
        'id': 1,
        'name': 'Arroz Tipo 1',
        'quantity': 3,
        'minimum_stock': 5,
        'unit': 'pacotes',
        'expiration_date': '2030-12-31',
        'is_active': true,
      });
      expect(p.id, 1);
      expect(p.validade, '31/12/2030');
      expect(p.quantidade, 3);
    });

    test('fromJson sem validade', () {
      final p = Produto.fromJson({'id': 2, 'name': 'Sal', 'quantity': 1, 'minimum_stock': 0, 'unit': 'pacotes'});
      expect(p.validade, 'Sem validade');
    });

    test('toCreateJson converte a data para o formato da API', () {
      expect(produto(validade: '05/01/2031').toCreateJson()['expiration_date'], '2031-01-05');
      expect(produto().toCreateJson()['expiration_date'], isNull);
    });
  });

  group('status do produto', () {
    final hoje = DateTime.now();

    test('vencido quando a validade já passou', () {
      final p = produto(validade: dataBr(hoje.subtract(const Duration(days: 1))));
      expect(p.isVencido, isTrue);
      expect(p.isVencendoLogo, isFalse);
    });

    test('vencendo logo nos próximos 30 dias', () {
      expect(produto(validade: dataBr(hoje.add(const Duration(days: 10)))).isVencendoLogo, isTrue);
      expect(produto(validade: dataBr(hoje.add(const Duration(days: 60)))).isVencendoLogo, isFalse);
    });

    test('sem validade nunca vence', () {
      expect(produto().isVencido, isFalse);
      expect(produto().isVencendoLogo, isFalse);
    });

    test('sem estoque e pouco estoque', () {
      expect(produto(quantidade: 0).isSemEstoque, isTrue);
      expect(produto(quantidade: 0).isPoucoEstoque, isFalse);
      expect(produto(quantidade: 5, minimo: 5).isPoucoEstoque, isTrue);
      expect(produto(quantidade: 6, minimo: 5).isPoucoEstoque, isFalse);
    });
  });
}