import 'package:flutter/material.dart';
import '../../provider/configuracoes_provider.dart';
import '../theme/tropical_theme.dart';

// Tela de Configurações: padronização dos nomes e ícones automáticos
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: configuracoesProvider,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: TropicalColors.base,
          appBar: AppBar(
            backgroundColor: TropicalColors.surface,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 28),
              tooltip: 'Voltar',
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTituloSecao('NOME DOS PRODUTOS'),
              _OpcaoConfiguracao(
                titulo: 'Padronizar nome no cadastro',
                ativado: configuracoesProvider.padronizarCadastro,
                aoMudar: configuracoesProvider.definirPadronizarCadastro,
                textoAtivado:
                    'o nome é salvo com a primeira letra de cada palavra em maiúsculo. Palavras como "de", "da" e "com" ficam minúsculas, e palavras com número não mudam.',
                textoDesativado: 'o nome é salvo exatamente como foi digitado.',
                exemplo: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExemploNome(antes: 'arroz 5kg ouro fino', depois: 'Arroz 5kg Ouro Fino'),
                    SizedBox(height: 12),
                    _ExemploNome(antes: 'PÃO DE FORMA', depois: 'Pão de Forma'),
                  ],
                ),
              ),
              _OpcaoConfiguracao(
                titulo: 'Padronizar nome na edição',
                ativado: configuracoesProvider.padronizarEdicao,
                aoMudar: configuracoesProvider.definirPadronizarEdicao,
                textoAtivado: 'ao editar um produto, o nome também é padronizado.',
                textoDesativado:
                    'ao editar, o nome é salvo exatamente como foi digitado. Útil para ajustar marcas e siglas.',
                exemplo: const _ExemploNome(antes: 'Café PILÃO', depois: 'Café Pilão'),
              ),
              const SizedBox(height: 8),
              _buildTituloSecao('APARÊNCIA'),
              _OpcaoConfiguracao(
                titulo: 'Ícones automáticos',
                ativado: configuracoesProvider.iconesAtivos,
                aoMudar: configuracoesProvider.definirIconesAtivos,
                textoAtivado: 'cada produto recebe um ícone de acordo com o nome (arroz, café, leite, frutas...).',
                textoDesativado: 'todos os produtos usam o ícone padrão de caixa.',
                exemplo: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExemploIcones(rotulo: 'Ativado', icones: ['🌾', '☕'], nomes: ['Arroz', 'Café']),
                    SizedBox(height: 8),
                    _ExemploIcones(rotulo: 'Desativado', icones: ['📦', '📦'], nomes: ['Arroz', 'Café']),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, bottom: 16),
                child: Text(
                  'As configurações ficam salvas neste aparelho.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TropicalColors.subtext, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTituloSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10, top: 4),
      child: Text(
        texto,
        style: const TextStyle(color: TropicalColors.subtext, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

// Cartão de uma opção: título, botão Ativado/Desativado e "Detalhes" que expande a explicação
class _OpcaoConfiguracao extends StatefulWidget {
  final String titulo;
  final bool ativado;
  final ValueChanged<bool> aoMudar;
  final String textoAtivado;
  final String textoDesativado;
  final Widget exemplo;

  const _OpcaoConfiguracao({
    required this.titulo,
    required this.ativado,
    required this.aoMudar,
    required this.textoAtivado,
    required this.textoDesativado,
    required this.exemplo,
  });

  @override
  State<_OpcaoConfiguracao> createState() => _OpcaoConfiguracaoState();
}

class _OpcaoConfiguracaoState extends State<_OpcaoConfiguracao> {
  bool _detalhesAbertos = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TropicalColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TropicalColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.titulo,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),

          // Botão em duas partes: a opção marcada fica destacada
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: TropicalColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TropicalColors.border),
            ),
            child: Row(
              children: [
                _buildParte('Ativado', selecionado: widget.ativado, valor: true),
                _buildParte('Desativado', selecionado: !widget.ativado, valor: false),
              ],
            ),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: () => setState(() => _detalhesAbertos = !_detalhesAbertos),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Detalhes',
                    style: TextStyle(color: TropicalColors.primary, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _detalhesAbertos ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right_rounded, color: TropicalColors.primary, size: 20),
                  ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _detalhesAbertos ? _buildZonaExplicacao() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildParte(String texto, {required bool selecionado, required bool valor}) {
    final destaque = selecionado && valor;
    final desativadoMarcado = selecionado && !valor;

    return Expanded(
      child: InkWell(
        onTap: () => widget.aoMudar(valor),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: destaque
                ? TropicalColors.primary
                : (desativadoMarcado ? TropicalColors.cardHighlight : Colors.transparent),
            borderRadius: BorderRadius.circular(9),
          ),
          // scaleDown: em telas estreitas ou com letra grande o texto diminui em vez de quebrar
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              texto,
              maxLines: 1,
              style: TextStyle(
                color: destaque ? Colors.black : (desativadoMarcado ? Colors.white : TropicalColors.subtext),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZonaExplicacao() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TropicalColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TropicalColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O QUE ESTA OPÇÃO FAZ',
              style: TextStyle(color: TropicalColors.primary, fontSize: 11, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _buildExplicacao('Ativado: ', widget.textoAtivado),
            const SizedBox(height: 8),
            _buildExplicacao('Desativado: ', widget.textoDesativado),
            const SizedBox(height: 14),
            widget.exemplo,
          ],
        ),
      ),
    );
  }

  Widget _buildExplicacao(String rotulo, String texto) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: rotulo, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          TextSpan(text: texto),
        ],
      ),
      style: const TextStyle(color: TropicalColors.text, fontSize: 13, height: 1.4),
    );
  }
}

class _ExemploNome extends StatelessWidget {
  final String antes;
  final String depois;

  const _ExemploNome({required this.antes, required this.depois});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tag(antes, destaque: false),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Icon(Icons.arrow_downward_rounded, color: TropicalColors.subtext, size: 16),
        ),
        _tag(depois, destaque: true),
      ],
    );
  }

  Widget _tag(String texto, {required bool destaque}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: destaque ? TropicalColors.cardHighlight : TropicalColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: destaque ? TropicalColors.primary : TropicalColors.border),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: destaque ? TropicalColors.primary : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Exemplo dos ícones: Wrap leva os itens para a linha de baixo quando falta espaço
class _ExemploIcones extends StatelessWidget {
  final String rotulo;
  final List<String> icones;
  final List<String> nomes;

  const _ExemploIcones({required this.rotulo, required this.icones, required this.nomes});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < nomes.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: TropicalColors.cardHighlight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${icones[i]}  ${nomes[i]}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        Text(
          '→ $rotulo',
          style: const TextStyle(color: TropicalColors.subtext, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}