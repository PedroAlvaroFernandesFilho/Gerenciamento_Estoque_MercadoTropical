import 'package:flutter/material.dart';
import '../theme/tropical_theme.dart';

// Caixa de diálogo para confirmar ações críticas antes de salvar
Future<bool> mostrarConfirmacao({
  required BuildContext context,
  required String titulo,
  required String mensagem,
  required String textoConfirmar,
  Color corConfirmar = TropicalColors.primary,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: TropicalColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: corConfirmar, width: 2),
        ),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          mensagem,
          style: const TextStyle(color: TropicalColors.text, fontSize: 15, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              // Botão para cancelar a operação
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: TropicalColors.card,
                    side: const BorderSide(color: TropicalColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botão para confirmar a operação
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: corConfirmar,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    textoConfirmar,
                    style: TextStyle(
                      color: corConfirmar == TropicalColors.danger ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  return resultado ?? false;
}