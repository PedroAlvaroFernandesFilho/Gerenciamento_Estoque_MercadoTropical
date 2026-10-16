import 'package:flutter/material.dart';
import '../../models/produto.dart';
import '../../provider/estoque_provider.dart';
import '../theme/tropical_theme.dart';

// Tela de formulário para criar ou editar um produto
class ProductFormScreen extends StatefulWidget {
  final Produto? produtoExistente;

  const ProductFormScreen({super.key, this.produtoExistente});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _qtdCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _unidadeCtrl;
  late TextEditingController _validadeCtrl;
  String _iconeSelecionado = '📦';

  final List<String> _icones = ['🌾', '🫘', '☕', '🥛', '🍝', '🌻', '🧃', '🍪', '📦'];

  @override
  void initState() {
    super.initState();
    // Preenche os campos caso seja edição de um produto existente
    final p = widget.produtoExistente;
    _nomeCtrl = TextEditingController(text: p?.nome ?? '');
    _qtdCtrl = TextEditingController(text: p != null ? '${p.quantidade}' : '10');
    _minCtrl = TextEditingController(text: p != null ? '${p.minimo}' : '5');
    _unidadeCtrl = TextEditingController(text: p?.unidade ?? 'pacotes');
    _validadeCtrl = TextEditingController(text: p?.validade ?? '20/12/2026');
    _iconeSelecionado = p?.icone ?? '🌾';
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.produtoExistente != null;

    return Scaffold(
      backgroundColor: TropicalColors.base,
      appBar: AppBar(
        backgroundColor: TropicalColors.surface,
        foregroundColor: Colors.white,
        title: Text(editando ? 'Editar Produto' : 'Cadastrar Novo Produto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Escolha um Ícone:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Lista de ícones selecionáveis
              Wrap(
                spacing: 10,
                children: _icones.map((ic) {
                  final selecionado = ic == _iconeSelecionado;
                  return ChoiceChip(
                    label: Text(ic, style: const TextStyle(fontSize: 22)),
                    selected: selecionado,
                    selectedColor: TropicalColors.primary,
                    backgroundColor: TropicalColors.card,
                    onSelected: (_) => setState(() => _iconeSelecionado = ic),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _campoTexto('Nome do Produto (ex: Arroz Tio João 5kg)', _nomeCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _campoTexto('Quantidade Atual', _qtdCtrl, isNumero: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _campoTexto('Estoque Mínimo', _minCtrl, isNumero: true)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _campoTexto('Unidade (pacotes, un)', _unidadeCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _campoTexto('Validade (DD/MM/AAAA)', _validadeCtrl)),
                ],
              ),
              const SizedBox(height: 24),
              // Botão para salvar o formulário
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TropicalColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final novo = Produto(
                        id: widget.produtoExistente?.id,
                        nome: _nomeCtrl.text.trim(),
                        quantidade: int.tryParse(_qtdCtrl.text) ?? 0,
                        minimo: int.tryParse(_minCtrl.text) ?? 5,
                        unidade: _unidadeCtrl.text.trim(),
                        validade: _validadeCtrl.text.trim(),
                        icone: _iconeSelecionado,
                      );

                      if (editando) {
                        await estoqueProvider.editarProduto(novo);
                      } else {
                        await estoqueProvider.adicionarProduto(novo);
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(
                    editando ? 'Salvar Alterações' : '➕ Salvar Novo Produto',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construtor padrão para os campos de texto do formulário
  Widget _campoTexto(String label, TextEditingController ctrl, {bool isNumero = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumero ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      validator: (val) => (val == null || val.isEmpty) ? 'Campo obrigatório' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: TropicalColors.subtext),
        filled: true,
        fillColor: TropicalColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TropicalColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TropicalColors.primary),
        ),
      ),
    );
  }
}