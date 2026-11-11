import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/produto.dart';

// Preferências do app, salvas no aparelho
class ConfiguracoesProvider extends ChangeNotifier {
  static const _chavePadronizarCadastro = 'padronizar_cadastro';
  static const _chavePadronizarEdicao = 'padronizar_edicao';
  static const _chaveIconesAtivos = 'icones_ativos';

  bool _padronizarCadastro = true;
  bool _padronizarEdicao = false;
  bool _iconesAtivos = true;

  bool get padronizarCadastro => _padronizarCadastro;
  bool get padronizarEdicao => _padronizarEdicao;
  bool get iconesAtivos => _iconesAtivos;

  // Lê as preferências salvas; se não conseguir, mantém os valores padrão
  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _padronizarCadastro = prefs.getBool(_chavePadronizarCadastro) ?? true;
      _padronizarEdicao = prefs.getBool(_chavePadronizarEdicao) ?? false;
      _iconesAtivos = prefs.getBool(_chaveIconesAtivos) ?? true;
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
    }
    Produto.iconesAtivos = _iconesAtivos;
    notifyListeners();
  }

  Future<void> definirPadronizarCadastro(bool valor) async {
    _padronizarCadastro = valor;
    await _salvar(_chavePadronizarCadastro, valor);
  }

  Future<void> definirPadronizarEdicao(bool valor) async {
    _padronizarEdicao = valor;
    await _salvar(_chavePadronizarEdicao, valor);
  }

  Future<void> definirIconesAtivos(bool valor) async {
    _iconesAtivos = valor;
    Produto.iconesAtivos = valor;
    await _salvar(_chaveIconesAtivos, valor);
  }

  Future<void> _salvar(String chave, bool valor) async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(chave, valor);
    } catch (e) {
      debugPrint('Erro ao salvar configuração: $e');
    }
  }
}

// Instância global, no mesmo padrão do estoqueProvider
final ConfiguracoesProvider configuracoesProvider = ConfiguracoesProvider();