import 'package:intl/intl.dart' show DateFormat;

/// Utilidades de formateo
class Formatters {
  Formatters._();

  /// Formato de fecha: "05 Mar 2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'es_CL').format(date);
  }

  /// Formato de fecha corta: "05/03/2026"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formato de tiempo en minutos:segundos
  static String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formato de hora: "14:30"
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Nombre de categoría de ejercicio
  static String categoryName(String code) {
    switch (code.toUpperCase()) {
      case 'RD': return 'Rodilla Dominante';
      case 'CD': return 'Cadera Dominante';
      case 'EM': return 'Empuje';
      case 'JL': return 'Jalón';
      case 'CR': return 'Core';
      default: return code;
    }
  }

  /// Nombre de control motor
  static String controlMotorName(String level) {
    switch (level.toLowerCase()) {
      case 'bajo': return 'Bajo Control Motor';
      case 'moderado': return 'Moderado Control Motor';
      case 'alto': return 'Alto Control Motor';
      default: return level;
    }
  }
}
