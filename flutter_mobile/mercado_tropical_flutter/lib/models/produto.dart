// Modelo de dados do produto com suporte a ativação/desativação, sem estoque e ícone automático
class Produto {
  final int? id;
  final String nome;
  final int quantidade;
  final int minimo;
  final String unidade;
  final String validade; // Formato na tela: DD/MM/AAAA
  final String icone;
  final bool ativo;

  Produto({
    this.id,
    required this.nome,
    required this.quantidade,
    required this.minimo,
    required this.unidade,
    required this.validade,
    String? icone,
    this.ativo = true,
  }) : icone = (icone != null && icone.isNotEmpty) ? icone : iconePorNome(nome);

  static String iconePorNome(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('arroz') || n.contains('trigo') || n.contains('aveia') || n.contains('farinha')) return '🌾';
    if (n.contains('feijao') || n.contains('feijão') || n.contains('lentilha') || n.contains('grão')) return '🫘';
    if (n.contains('cafe') || n.contains('café') || n.contains('chá') || n.contains('cha') || n.contains('achocolatado')) return '☕';
    if (n.contains('leite') || n.contains('iogurte') || n.contains('creme')) return '🥛';
    if (n.contains('queijo') || n.contains('manteiga') || n.contains('margarina')) return '🧀';
    if (n.contains('macarrao') || n.contains('macarrão') || n.contains('massa') || n.contains('miojo')) return '🍝';
    if (n.contains('oleo') || n.contains('óleo') || n.contains('azeite') || n.contains('vinagre')) return '🌻';
    if (n.contains('suco') || n.contains('refrigerante') || n.contains('agua') || n.contains('água') || n.contains('bebida')) return '🧃';
    if (n.contains('biscoito') || n.contains('bolacha') || n.contains('doce') || n.contains('chocolate') || n.contains('açúcar') || n.contains('acucar')) return '🍪';
    if (n.contains('molho') || n.contains('extrato') || n.contains('milho') || n.contains('ervilha') || n.contains('sardinha') || n.contains('atum')) return '🥫';
    if (n.contains('sabao') || n.contains('sabão') || n.contains('detergente') || n.contains('limpeza') || n.contains('papel') || n.contains('sabonete')) return '🧼';
    if (n.contains('carne') || n.contains('frango') || n.contains('peixe') || n.contains('ovo')) return '🥩';
    if (n.contains('pao') || n.contains('pão') || n.contains('bolo')) return '🍞';
    if (n.contains('sal') || n.contains('tempero') || n.contains('alho')) return '🧂';
    return '📦';
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