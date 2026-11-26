import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de la app que elige el padre.
///
/// - [calmMode] ("Animaciones suaves"): la app entera se comporta como con
///   "reducir movimiento" del teléfono (sin confeti, sin vaivén del
///   cometa, viajes cortos), para niños con sensibilidad sensorial.
///   Viene apagado: la app se ve animada salvo que el padre lo encienda.
class SettingsProvider extends ChangeNotifier {
  static const calmModeKey = 'settings_calm_mode';

  bool _calmMode = false;
  bool get calmMode => _calmMode;

  /// Lee lo guardado. Si falla, queda el valor por defecto (apagado).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(calmModeKey) ?? false;
      if (saved != _calmMode) {
        _calmMode = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setCalmMode(bool value) async {
    if (value == _calmMode) return;
    _calmMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(calmModeKey, value);
    } catch (_) {}
  }

  /// Aplica el modo calma a todo lo que cuelga de [child]: las pantallas ya
  /// leen `MediaQuery.disableAnimations`, así que basta con encenderlo.
  static Widget apply({required bool calm, required Widget child}) {
    return Builder(builder: (context) {
      final mq = MediaQuery.of(context);
      if (!calm || mq.disableAnimations) return child;
      return MediaQuery(
        data: mq.copyWith(disableAnimations: true),
        child: child,
      );
    });
  }
}
