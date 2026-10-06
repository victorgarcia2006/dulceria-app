import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Diálogo informativo con un solo botón (éxito o aviso).
class MessageDialog extends StatelessWidget {
  const MessageDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.icono = Icons.info_outline,
    this.colorIcono,
    this.textoBoton = 'Entendido',
  });

  final String titulo;
  final String mensaje;
  final IconData icono;
  final Color? colorIcono;
  final String textoBoton;

  static Future<void> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    IconData icono = Icons.info_outline,
    Color? colorIcono,
    String textoBoton = 'Entendido',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => MessageDialog(
        titulo: titulo,
        mensaje: mensaje,
        icono: icono,
        colorIcono: colorIcono,
        textoBoton: textoBoton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AlertDialog(
      icon: Icon(
        icono,
        size: AppSpacing.xl,
        color: colorIcono ?? tema.colorScheme.primary,
      ),
      title: Text(titulo, textAlign: TextAlign.center),
      content: Text(mensaje, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(textoBoton),
        ),
      ],
    );
  }
}
