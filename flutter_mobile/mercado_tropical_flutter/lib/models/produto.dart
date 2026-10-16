// Modelo de dados de cada produto do estoque
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

  // Verifica se a data de validade já passou
  bool get isVencido {
    try {
      final partes = validade.split('/');
      if (partes.length != 3) return false;
      final dataVal = DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );
      return dataVal.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  // Verifica se o estoque está igual ou abaixo do mínimo
  bool get isPoucoEstoque => !isVencido && quantidade <= minimo;

  // Retorna o estado atual do produto para os filtros
  String get status {
    if (isVencido) return 'vencido';
    if (isPoucoEstoque) return 'baixo';
    return 'normal';
  }

  // Cria uma cópia do produto alterando apenas os campos necessários
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