import '../models/produto.dart';

// Serviço local que armazena os produtos em memória
class ProdutoService {
  final List<Produto> _bancoEmMemoria = [
    Produto(
      id: 1,
      nome: "Feijão Carioca 1kg",
      quantidade: 3, // Estoque baixo e Vencido (Testa prioridade vermelha + triângulo amarelo)
      minimo: 5,
      unidade: "pacotes",
      validade: "15/04/2024",
      icone: "🫘",
    ),
    Produto(
      id: 2,
      nome: "Arroz Tio João 5kg",
      quantidade: 2, // Estoque baixo e Vencendo logo
      minimo: 5,
      unidade: "pacotes",
      validade: "25/10/2026",
      icone: "🌾",
    ),
    Produto(
      id: 3,
      nome: "Café Pilão 500g",
      quantidade: 3, // Estoque baixo, mas validade longa
      minimo: 5,
      unidade: "pacotes",
      validade: "12/11/2027",
      icone: "☕",
    ),
    Produto(
      id: 4,
      nome: "Leite Itambé 1L",
      quantidade: 12, // Estoque normal, mas vencendo logo
      minimo: 10,
      unidade: "caixinhas",
      validade: "20/10/2026",
      icone: "🥛",
    ),
    Produto(
      id: 5,
      nome: "Macarrão Galo 1kg",
      quantidade: 8,
      minimo: 5,
      unidade: "pacotes",
      validade: "18/03/2027",
      icone: "🍝",
    ),
    Produto(
      id: 6,
      nome: "Óleo de Soja 900ml",
      quantidade: 12,
      minimo: 6,
      unidade: "unidades",
      validade: "10/12/2027",
      icone: "🌻",
    ),
  ];

  int _proximoId = 7;

  // Lista todos os produtos
  Future<List<Produto>> listarProdutos() async {
    return List.from(_bancoEmMemoria);
  }

  // Cria novo produto
  Future<Produto> criarProduto(Produto produto) async {
    final novo = produto.copyWith(id: _proximoId++);
    _bancoEmMemoria.add(novo);
    return novo;
  }

  // Atualiza um produto existente
  Future<Produto> atualizarProduto(int id, Produto produto) async {
    final index = _bancoEmMemoria.indexWhere((p) => p.id == id);
    if (index != -1) {
      _bancoEmMemoria[index] = produto.copyWith(id: id);
      return _bancoEmMemoria[index];
    }
    throw Exception('Produto não encontrado');
  }

  // Exclui um produto pelo ID
  Future<void> deletarProduto(int id) async {
    _bancoEmMemoria.removeWhere((p) => p.id == id);
  }
}