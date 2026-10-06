import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../core/theme.dart';

/// Abre un formulario como hoja inferior que sube con el teclado.
Future<T?> mostrarFormSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: builder(sheetContext),
      ),
    ),
  );
}

/// Texto de error (de la API) dentro de un formulario.
class ErrorDeFormulario extends StatelessWidget {
  const ErrorDeFormulario({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        mensajeDeError(error),
        style: tema.textTheme.bodyMedium
            ?.copyWith(color: tema.colorScheme.error),
      ),
    );
  }
}
