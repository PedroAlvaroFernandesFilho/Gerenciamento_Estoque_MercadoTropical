// Modelo de dados do produto e regras de validade e estoque
class Produto {
  final int? id;
  final String nome;
  final int quantidade;
  final int minimo;
  final String unidade;
  final String validade;
  final String icone;

  Produto({
    this.id,
    required this.nome,
    required this.quantidade,
    required this.minimo,
    required this.unidade,
    required this.validade,
    required this.icone,
  });

  // Converte o texto DD/MM/AAAA em objeto de data
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

  // Verifica se o produto já passou da validade
  bool get isVencido {
    final data = _dataValidade;
    if (data == null) return false;
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    return data.isBefore(hojeSemHora);
  }

  // Verifica se o produto vence nos próximos 30 dias
  bool get isVencendoLogo {
    if (isVencido) return false;
    final data = _dataValidade;
    if (data == null) return false;
    final diferenca = data.difference(DateTime.now()).inDays;
    return diferenca <= 30;
  }

  // Verifica se a quantidade está igual ou abaixo do mínimo
  bool get isPoucoEstoque => quantidade <= minimo;

  // Define a prioridade de status baseada na validade
  String get statusValidade {
    if (isVencido) return 'vencido';
    if (isVencendoLogo) return 'vencendo';
    return 'normal';
  }

  // Cria uma cópia atualizada do produto
  Produto copyWith({
    int? id,
    String? nome,
    int? quantidade,
    int? minimo,
    String? unidade,
    String? validade,
    String? icone,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      minimo: minimo ?? this.minimo,
      unidade: unidade ?? this.unidade,
      validade: validade ?? this.validade,
      icone: icone ?? this.icone,
    );
  }
}