// Modelo de dados do produto com suporte a ativação/desativação, sem estoque e ícone automático
class Produto {
  final int? id;
  final String nome;
  final int quantidade;
  final int minimo;
  final String unidade;
  final String validade; // Formato na tela: DD/MM/AAAA
  final String _icone;
  final bool ativo;

  // Definido pela tela de Configurações; desativado, todos os produtos mostram 📦
  static bool iconesAtivos = true;

  String get icone => iconesAtivos ? _icone : '📦';

  Produto({
    this.id,
    required this.nome,
    required this.quantidade,
    required this.minimo,
    required this.unidade,
    required this.validade,
    String? icone,
    this.ativo = true,
  }) : _icone = (icone != null && icone.isNotEmpty) ? icone : iconePorNome(nome);

  // Emoji de cada categoria e suas palavras-chave (sem acento), testados em ordem: o primeiro que combinar vence.
  // Itens mais específicos vêm antes (ex: "água sanitária" é limpeza, não bebida).
  static const List<(String, List<String>)> _icones = [
    // Expressões que não podem cair na categoria da palavra solta ("massa", "queijo")
    ('🥫', ['massa de tomate', 'extrato de tomate']),
    ('🍞', ['pao de queijo']),
    ('🧼', ['agua sanitaria', 'sabao', 'detergente', 'desinfetante', 'amaciante', 'alvejante', 'multiuso', 'limpeza', 'esponja', 'sabonete']),
    ('🧻', ['papel higienico', 'papel toalha', 'guardanapo', 'lenco']),
    ('🦷', ['creme dental', 'pasta de dente', 'escova de dente', 'fio dental']),
    ('🧴', ['shampoo', 'xampu', 'condicionador', 'hidratante', 'desodorante', 'protetor solar']),
    ('🧀', ['queijo', 'requeijao', 'manteiga', 'margarina']),
    ('🥛', ['leite', 'iogurte', 'creme de leite', 'coalhada']),
    ('🌾', ['arroz', 'trigo', 'aveia', 'farinha', 'fuba', 'granola']),
    ('🫘', ['feijao', 'lentilha', 'grao de bico', 'graos']),
    ('☕', ['cafe', 'cha', 'achocolatado', 'cappuccino', 'capuccino', 'ovomaltine']),
    ('🍝', ['macarrao', 'massa', 'miojo', 'lasanha', 'espaguete', 'talharim']),
    ('🌻', ['oleo', 'azeite', 'vinagre']),
    ('🍺', ['cerveja', 'chope']),
    ('🍷', ['vinho']),
    ('🥥', ['agua de coco', 'coco']),
    ('🥤', ['refrigerante', 'refri', 'energetico', 'coca', 'guarana']),
    ('🧃', ['suco', 'bebida', 'agua']),
    ('🍫', ['chocolate', 'bombom']),
    ('🍦', ['sorvete', 'picole']),
    ('🍪', ['biscoito', 'bolacha', 'cookie', 'wafer']),
    ('🍬', ['bala', 'doce', 'pirulito', 'acucar', 'adocante']),
    ('🍯', ['mel']),
    ('🥫', ['molho', 'extrato', 'milho', 'ervilha', 'sardinha', 'atum', 'conserva', 'enlatado']),
    ('🥓', ['bacon', 'linguica', 'salsicha', 'presunto', 'mortadela', 'salame']),
    ('🍗', ['frango', 'galinha', 'peru']),
    ('🐟', ['peixe', 'tilapia', 'salmao', 'bacalhau']),
    ('🥩', ['carne', 'bife', 'picanha', 'alcatra', 'patinho', 'costela']),
    ('🥚', ['ovo']),
    ('🍞', ['pao', 'paes', 'bisnaguinha', 'torrada']),
    ('🍰', ['bolo']),
    ('🍌', ['banana']),
    ('🍎', ['maca']),
    ('🍊', ['laranja', 'tangerina', 'mexerica']),
    ('🍋', ['limao', 'limoes']),
    ('🍇', ['uva']),
    ('🍓', ['morango']),
    ('🍉', ['melancia']),
    ('🍍', ['abacaxi']),
    ('🥭', ['manga']),
    ('🥑', ['abacate']),
    ('🍅', ['tomate']),
    ('🥔', ['batata']),
    ('🥕', ['cenoura']),
    ('🧅', ['cebola']),
    ('🧄', ['alho']),
    ('🥬', ['alface', 'couve', 'repolho']),
    ('🥦', ['brocolis']),
    ('🌶️', ['pimenta']),
    ('🥜', ['amendoim']),
    ('🍿', ['pipoca', 'salgadinho', 'chips']),
    ('🧂', ['sal', 'tempero', 'oregano']),
    ('🧊', ['gelo']),
    ('🐾', ['racao']),
  ];

  // Escolhe o emoji comparando palavras inteiras e sem acento ("bolacha" não cai mais em "chá").
  // Aceita plural simples: "ovos", "bananas", "limoes".
  static String iconePorNome(String nome) {
    final texto = ' ${normalizarNome(nome).replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()} ';
    for (final (emoji, palavras) in _icones) {
      for (final palavra in palavras) {
        if (texto.contains(' $palavra ') || texto.contains(' ${palavra}s ') || texto.contains(' ${palavra}es ')) {
          return emoji;
        }
      }
    }
    return '📦';
  }

  // Palavras que ficam minúsculas no meio do nome (ex: "Pão de Forma")
  static const Set<String> _conectivos = {'de', 'da', 'do', 'das', 'dos', 'e', 'com', 'sem', 'em', 'na', 'no', 'para'};

  // Padroniza o nome: "arroz 5kg ouro fino" -> "Arroz 5kg Ouro Fino"
  // Palavras com número ficam como digitadas; siglas curtas em maiúsculo (UHT) são mantidas,
  // a não ser que o nome inteiro tenha sido digitado em maiúsculo.
  static String formatarNome(String nome) {
    final palavras = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final tudoMaiusculo = nome == nome.toUpperCase();
    final resultado = <String>[];

    for (var i = 0; i < palavras.length; i++) {
      final palavra = palavras[i];
      final minuscula = palavra.toLowerCase();

      if (RegExp(r'\d').hasMatch(palavra)) {
        resultado.add(palavra);
      } else if (i > 0 && _conectivos.contains(minuscula)) {
        resultado.add(minuscula);
      } else if (!tudoMaiusculo && palavra.length <= 3 && palavra == palavra.toUpperCase() && palavra != minuscula) {
        resultado.add(palavra);
      } else {
        resultado.add(minuscula[0].toUpperCase() + minuscula.substring(1));
      }
    }
    return resultado.join(' ');
  }

  // Pares singular/plural das unidades
  static const Map<String, String> _plurais = {
    'pacote': 'pacotes',
    'unidade': 'unidades',
    'caixa': 'caixas',
    'lata': 'latas',
    'quilo': 'quilos',
    'litro': 'litros',
    'fardo': 'fardos',
  };

  // Unidade conforme a quantidade: 1 lata, 0 latas, 5 latas.
  // Aceita a unidade salva no singular ou no plural; uma unidade fora da lista aparece como está.
  static String unidadePara(int quantidade, String unidade) {
    final u = unidade.trim().toLowerCase();
    for (final par in _plurais.entries) {
      if (u == par.key || u == par.value) return quantidade == 1 ? par.key : par.value;
    }
    return unidade;
  }

  // Ex: "5 latas", "1 lata"
  static String quantidadeComUnidade(int quantidade, String unidade) =>
      '$quantidade ${unidadePara(quantidade, unidade)}';

  // Nome sem padronização: tira espaços do começo, do fim e repetidos
  static String limparEspacos(String nome) => nome.trim().replaceAll(RegExp(r'\s+'), ' ');

  // Versão do nome usada só para comparar: sem acentos, minúscula e sem espaços extras
  static String normalizarNome(String nome) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
    final buffer = StringBuffer();
    for (final letra in nome.toLowerCase().trim().split('')) {
      final i = comAcento.indexOf(letra);
      buffer.write(i >= 0 ? semAcento[i] : letra);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Nomes quase iguais (erro de digitação). Nomes com números diferentes ("1kg" x "5kg") nunca são parecidos.
  static bool nomesParecidos(String a, String b) {
    final na = normalizarNome(a);
    final nb = normalizarNome(b);
    if (na == nb) return false; // nomes iguais são tratados à parte

    final numerosA = RegExp(r'\d+').allMatches(na).map((m) => m.group(0)).join(',');
    final numerosB = RegExp(r'\d+').allMatches(nb).map((m) => m.group(0)).join(',');
    if (numerosA != numerosB) return false;

    final maior = na.length > nb.length ? na.length : nb.length;
    if (maior < 5) return false;
    final limite = maior <= 10 ? 1 : 2;
    return _distancia(na, nb) <= limite;
  }

  // Quantas letras precisam mudar para um texto virar o outro (distância de Levenshtein)
  static int _distancia(String a, String b) {
    var anterior = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final atual = List<int>.filled(b.length + 1, 0);
      atual[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final custo = a[i - 1] == b[j - 1] ? 0 : 1;
        final remover = anterior[j] + 1;
        final inserir = atual[j - 1] + 1;
        final trocar = anterior[j - 1] + custo;
        atual[j] = remover < inserir ? (remover < trocar ? remover : trocar) : (inserir < trocar ? inserir : trocar);
      }
      anterior = atual;
    }
    return anterior[b.length];
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    final nomeProd = (json['name'] ?? '').toString();
    return Produto(
      id: json['id'] as int?,
      nome: nomeProd,
      quantidade: (json['quantity'] ?? 0) as int,
      minimo: (json['minimum_stock'] ?? 0) as int,
      unidade: (json['unit'] ?? 'unidade').toString(),
      validade: _isoParaBr(json['expiration_date']?.toString()),
      icone: iconePorNome(nomeProd),
      ativo: (json['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': nome,
      'quantity': quantidade,
      'unit': unidade,
      'minimum_stock': minimo,
      'expiration_date': _brParaIso(validade),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': nome,
      'unit': unidade,
      'minimum_stock': minimo,
      'expiration_date': _brParaIso(validade),
      'is_active': ativo,
    };
  }

  static String _isoParaBr(String? iso) {
    if (iso == null || iso.isEmpty) return 'Sem validade';
    final partes = iso.split('T').first.split('-');
    if (partes.length != 3) return iso;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  static String? _brParaIso(String br) {
    final partes = br.split('/');
    if (partes.length != 3) return null;
    final dia = partes[0].padLeft(2, '0');
    final mes = partes[1].padLeft(2, '0');
    final ano = partes[2];
    return '$ano-$mes-$dia';
  }

  DateTime? get _dataValidade {
    try {
      final partes = validade.split('/');
      if (partes.length != 3) return null;
      return DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isVencido {
    final data = _dataValidade;
    if (data == null) return false;
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    return data.isBefore(hojeSemHora);
  }

  bool get isVencendoLogo {
    if (isVencido) return false;
    final data = _dataValidade;
    if (data == null) return false;
    final diferenca = data.difference(DateTime.now()).inDays;
    return diferenca <= 30;
  }

  // Novo: Retorna true apenas quando o estoque zerou completamente
  bool get isSemEstoque => quantidade == 0;

  // Atualizado: Pouco estoque apenas quando ainda tem produto (> 0), mas chegou no mínimo
  bool get isPoucoEstoque => quantidade > 0 && quantidade <= minimo;

  Produto copyWith({
    int? id,
    String? nome,
    int? quantidade,
    int? minimo,
    String? unidade,
    String? validade,
    String? icone,
    bool? ativo,
  }) {
    final novoNome = nome ?? this.nome;
    return Produto(
      id: id ?? this.id,
      nome: novoNome,
      quantidade: quantidade ?? this.quantidade,
      minimo: minimo ?? this.minimo,
      unidade: unidade ?? this.unidade,
      validade: validade ?? this.validade,
      icone: icone ?? iconePorNome(novoNome),
      ativo: ativo ?? this.ativo,
    );
  }
}