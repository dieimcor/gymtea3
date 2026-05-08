import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/utils/rut_validator.dart';

/// Campo de texto especializado para RUT chileno
/// Formatea automáticamente a XX.XXX.XXX-X mientras se escribe
class RutInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  const RutInputField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
  });

  @override
  State<RutInputField> createState() => _RutInputFieldState();
}

class _RutInputFieldState extends State<RutInputField> {
  bool _isValid = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.isNotEmpty) {
      _hasInteracted = true;
    }
    setState(() {
      _isValid = RutValidator.isValid(text);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  /// Formatea el RUT mientras se escribe
  void _formatRut(String value) {
    // Limpiar todo excepto números y K
    final cleaned = value.replaceAll(RegExp(r'[^0-9kK]'), '').toUpperCase();

    if (cleaned.isEmpty) {
      widget.controller.value = TextEditingValue.empty;
      widget.onChanged?.call('');
      return;
    }

    // No formatear si es muy corto
    if (cleaned.length < 2) {
      widget.onChanged?.call(cleaned);
      return;
    }

    // Formatear con puntos y guión
    final formatted = RutValidator.format(cleaned);

    // Solo actualizar si cambió (evita loop infinito)
    if (formatted != value) {
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    widget.onChanged?.call(formatted);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        LengthLimitingTextInputFormatter(12), // XX.XXX.XXX-X = 12 chars max
      ],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        letterSpacing: 1.2,
      ),
      onChanged: _formatRut,
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
        labelText: 'RUT',
        hintText: '12.345.678-5',
        hintStyle: TextStyle(
          color: AppTheme.textLight.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          color: AppTheme.primaryGreen,
        ),
        suffixIcon: _hasInteracted && widget.controller.text.isNotEmpty
            ? Icon(
                _isValid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: _isValid ? AppTheme.primaryGreen : Colors.redAccent,
                size: 22,
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _isValid ? AppTheme.primaryGreen : AppTheme.accentTeal,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2,
          ),
        ),
      ),
      validator: widget.validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa tu RUT';
            }
            if (!RutValidator.isValid(value)) {
              return 'RUT inválido';
            }
            return null;
          },
    );
  }
}
