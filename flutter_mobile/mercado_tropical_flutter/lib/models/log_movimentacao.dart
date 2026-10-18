// Modelo de dados para cada registro do histórico (Log)
class LogMovimentacao {
  final String tipo; // 'entrada', 'saida', 'cadastro', 'edicao', 'exclusao'
  final String produtoNome;
  final String detalhe;
  final DateTime dataHora;

  LogMovimentacao({
    required this.tipo,
    required this.produtoNome,
    required this.detalhe,
    required this.dataHora,
  });

  // Formata a data e hora para exibição simples
  String get dataFormatada {
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = dataHora.month.toString().padLeft(2, '0');
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final min = dataHora.minute.toString().padLeft(2, '0');
    return '$dia/$mes às $hora:$min';
  }
}