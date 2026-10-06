import 'package:flutter/material.dart';

/// Diálogo de confirmación. Devuelve `true` solo si la usuaria confirma.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.textoConfirmar = 'Aceptar',
    this.textoCancelar = 'Cancelar',
  });

  final String titulo;
  final String mensaje;
  final String textoConfirmar;
  final String textoCancelar;

  static Future<bool> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Aceptar',
    String textoCancelar = 'Cancelar',
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        titulo: titulo,
        mensaje: mensaje,
        textoConfirmar: textoConfirmar,
        textoCancelar: textoCancelar,
      ),
    );
    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(textoCancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(textoConfirmar),
        ),
      ],
    );
  }
}
