import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto.dart';

// Serviço HTTP que conecta o Flutter à API FastAPI + Supabase
class ProdutoService {
  // Para testar no navegador (Edge/Chrome) ou Windows, use 127.0.0.1:8000
  // (Para testar no Emulador Android, mude para http://10.0.2.2:8000)
  static const String _baseUrl = 'http://127.0.0.1:8000';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  // GET /products
  Future<List<Produto>> listarProdutos() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> lista = jsonDecode(utf8.decode(response.bodyBytes));
      return lista.map((item) => Produto.fromJson(item)).toList();
    }
    throw Exception('Erro ao carregar produtos do servidor (${response.statusCode})');
  }

  // POST /products
  Future<Produto> criarProduto(Produto produto) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: _headers,
      body: jsonEncode(produto.toCreateJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> dados = jsonDecode(utf8.decode(response.bodyBytes));
      return Produto.fromJson(dados);
    }
    throw Exception('Erro ao cadastrar produto (${response.statusCode})');
  }

  // PATCH /products/{id}
  Future<Produto> atualizarProduto(int id, Produto produto) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _headers,
      body: jsonEncode(produto.toUpdateJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> dados = jsonDecode(utf8.decode(response.bodyBytes));
      return Produto.fromJson(dados);
    }
    throw Exception('Erro ao atualizar produto (${response.statusCode})');
  }

  // DELETE /products/{id}
  Future<void> deletarProduto(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$id'),
      headers: _headers,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erro ao excluir produto (${response.statusCode})');
    }
  }

  // POST /products/{id}/entries
  Future<int> registrarEntrada(int productId, int quantidade) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products/$productId/entries'),
      headers: _headers,
      body: jsonEncode({'quantity': quantidade}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> dados = jsonDecode(utf8.decode(response.bodyBytes));
      return (dados['new_stock'] as int);
    }
    throw Exception('Erro ao registrar entrada (${response.statusCode})');
  }

  // POST /products/{id}/exits
  Future<int> registrarSaida(int productId, int quantidade) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products/$productId/exits'),
      headers: _headers,
      body: jsonEncode({'quantity': quantidade}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> dados = jsonDecode(utf8.decode(response.bodyBytes));
      return (dados['new_stock'] as int);
    }
    throw Exception('Erro ao registrar saída (${response.statusCode})');
  }

  // GET /stock-movements (Busca o histórico salvo no Supabase)
  Future<List<Map<String, dynamic>>> listarMovimentacoes() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stock-movements'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> lista = jsonDecode(utf8.decode(response.bodyBytes));
      return lista.cast<Map<String, dynamic>>();
    }
    return [];
  }
}