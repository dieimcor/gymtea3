/// Validación de RUT chileno (Módulo 11)
class RutValidator {
  /// Valida un RUT chileno completo (ej: "12.345.678-5" o "12345678-5")
  static bool isValid(String rut) {
    // Limpiar caracteres no numéricos excepto K
    final cleaned = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();

    if (cleaned.length < 2) return false;

    final body = cleaned.substring(0, cleaned.length - 1);
    final verifier = cleaned[cleaned.length - 1];

    // Verificar que el cuerpo sea numérico
    if (int.tryParse(body) == null) return false;

    // Calcular dígito verificador
    final calculated = _calculateVerifier(body);

    return calculated == verifier;
  }

  /// Calcula el dígito verificador usando módulo 11
  static String _calculateVerifier(String body) {
    int sum = 0;
    int multiplier = 2;

    for (int i = body.length - 1; i >= 0; i--) {
      sum += int.parse(body[i]) * multiplier;
      multiplier = multiplier < 7 ? multiplier + 1 : 2;
    }

    final remainder = sum % 11;
    final result = 11 - remainder;

    if (result == 11) return '0';
    if (result == 10) return 'K';
    return result.toString();
  }

  /// Formatea un RUT a formato XX.XXX.XXX-X
  static String format(String rut) {
    final cleaned = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();

    if (cleaned.length < 2) return rut;

    final body = cleaned.substring(0, cleaned.length - 1);
    final verifier = cleaned[cleaned.length - 1];

    // Agregar puntos cada 3 dígitos de derecha a izquierda
    final buffer = StringBuffer();
    for (int i = 0; i < body.length; i++) {
      if (i > 0 && (body.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(body[i]);
    }

    return '${buffer.toString()}-$verifier';
  }

  /// Limpia un RUT de formato (quita puntos y guión)
  static String clean(String rut) {
    return rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
  }
}
