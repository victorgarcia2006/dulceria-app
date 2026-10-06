import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/validators.dart';

/// Campo de dinero en pesos (acepta punto o coma). Valida con [validarDinero].
class CampoDinero extends StatelessWidget {
  const CampoDinero({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.textInputAction = TextInputAction.next,
    this.alEnviar,
  });

  final TextEditingController controller;
  final String etiqueta;
  final TextInputAction textInputAction;
  final VoidCallback? alEnviar;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: etiqueta, prefixText: '\$ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validarDinero,
      onFieldSubmitted: alEnviar == null ? null : (_) => alEnviar!(),
    );
  }
}

/// Campo de cantidad entera. Valida con [validarCantidad].
class CampoCantidad extends StatelessWidget {
  const CampoCantidad({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String etiqueta;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(labelText: etiqueta),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validarCantidad,
    );
  }
}
