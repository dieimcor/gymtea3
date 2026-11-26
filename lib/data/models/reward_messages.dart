import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/data/models/training_route.dart';

/// Mensaje que la pantalla de recompensa le muestra al **padre** al
/// conquistar un cometa completo.
///
/// La idea de fondo es el vínculo: no es un premio "de la app", es una
/// invitación a que el papá o la mamá celebre con su hijo/a.
class RewardMessage {
  /// Título grande de la pantalla ("¡Sofía conquistó el Cometa Limón!").
  final String title;

  /// Encabezado de la tarjeta para el padre ("¡Recompensa a Sofía, lo logró!").
  final String headline;

  /// Mensaje con la invitación concreta.
  final String message;

  /// Gesto sugerido, corto ("Abrazo de oso").
  final String gesture;

  const RewardMessage({
    required this.title,
    required this.headline,
    required this.message,
    required this.gesture,
  });
}

/// Plantilla interna: `{n}` se reemplaza por el nombre del niño.
class _Template {
  final String headline;
  final String message;
  final String gesture;

  const _Template(this.headline, this.message, this.gesture);
}

/// Mensajes dinámicos al padre, con el nombre del niño.
///
/// La selección es **determinística** (cometa + semilla) para poder
/// testearla; la pantalla pasa una semilla al azar para que varíe.
class RewardMessages {
  RewardMessages._();

  /// Nombre que se usa si no llega el del niño.
  static const String fallbackName = 'tu hijo/a';

  static const List<_Template> _cometTemplates = [
    _Template(
      '¡Recompensa a {n}, lo logró!',
      'Dale un abrazo bien apretado a {n} y dile lo orgulloso/a que estás '
          'de su esfuerzo.',
      'Abrazo de oso',
    ),
    _Template(
      '¡Choquen esos cinco!',
      'Levanta la mano y que {n} te choque los cinco con toda su fuerza. '
          '¡Se lo ganó!',
      'Chocar los cinco',
    ),
    _Template(
      'Díselo con palabras',
      'Dile a {n}: "Estoy muy orgulloso/a de ti, trabajaste súper bien". '
          'Escucharlo de ti vale muchísimo.',
      'Decirle lo orgulloso/a que estás',
    ),
    _Template(
      '¿Qué fue lo que más le gustó?',
      'Pregúntale a {n} qué ejercicio le gustó más y por qué. Escucha su '
          'respuesta con calma, sin apuro.',
      'Conversar juntos',
    ),
    _Template(
      '¡Baile de la victoria!',
      'Pongan la canción favorita de {n} y bailen juntos un ratito para '
          'celebrar el cometa.',
      'Bailar juntos',
    ),
    _Template(
      '¡Que se entere la familia!',
      'Cuéntenle juntos a alguien de la familia lo que logró {n} hoy. '
          '¡Que se sienta como un campeón/a!',
      'Contarle a la familia',
    ),
    _Template(
      'Un momento para los dos',
      'Elijan juntos algo que le guste a {n}: un cuento, un juego o una '
          'colación rica. Es su premio por el esfuerzo.',
      'Elegir un premio juntos',
    ),
    _Template(
      '¡Celebren a lo grande!',
      'Aplaudan juntos y que {n} haga su pose de campeón/a. Si quiere, '
          'sáquenle una foto para recordar este día.',
      'Pose de campeón/a',
    ),
  ];

  static const List<_Template> _journeyTemplates = [
    _Template(
      '¡Viaje completo! Recompensa a {n}',
      '{n} recorrió todos los cometas contigo. Denle un abrazo largo y '
          'recuérdenle todo lo que avanzó en este viaje.',
      'Abrazo largo',
    ),
    _Template(
      '¡Lo lograron juntos!',
      'Este viaje lo hicieron en equipo. Dile a {n} lo orgulloso/a que estás '
          'y elijan juntos cómo celebrar en grande.',
      'Celebrar en equipo',
    ),
    _Template(
      '¡{n} es un astronauta de verdad!',
      'Pregúntale a {n} cuál fue su cometa favorito y qué ejercicio quiere '
          'repetir. ¡Prepárense para el próximo viaje!',
      'Recordar el viaje juntos',
    ),
  ];

  /// Cantidad de variantes por cometa (útil para tests).
  static int get cometVariantCount => _cometTemplates.length;

  /// Mensaje para el cometa [cometIndex] (0-based) conquistado por
  /// [childName].
  ///
  /// [seed] desplaza la plantilla elegida, para que la misma vuelta no
  /// repita siempre el mismo mensaje. Si [journeyCompleted] es `true` se
  /// usa la variante especial de fin de viaje.
  ///
  /// El nombre del cometa sale de [cometName] si llega; si no, del planeta
  /// [cometIndex] de la [route] del padre; y si tampoco hay ruta, de la
  /// paleta general ([CometTheme.forRound]).
  static RewardMessage forComet(
    String childName,
    int cometIndex, {
    int seed = 0,
    bool journeyCompleted = false,
    String? cometName,
    TrainingRoute? route,
  }) {
    final name = _cleanName(childName);
    final comet = cometName ?? cometNameFor(cometIndex, route: route);

    final templates = journeyCompleted ? _journeyTemplates : _cometTemplates;
    // Paso 3 (coprimo con 8): cometas consecutivos nunca repiten mensaje.
    final index = _positiveMod(cometIndex * 3 + seed, templates.length);
    final t = templates[index];

    final title = journeyCompleted
        ? '¡${_capitalize(name)} completó el viaje!'
        : '¡${_capitalize(name)} conquistó el $comet!';

    return RewardMessage(
      title: title,
      headline: _capitalize(_fill(t.headline, name)),
      message: _capitalize(_fill(t.message, name)),
      gesture: t.gesture,
    );
  }

  /// Nombre del cometa [cometIndex]: el de la ruta si la hay.
  static String cometNameFor(int cometIndex, {TrainingRoute? route}) =>
      (route?.cometAt(cometIndex) ?? CometTheme.forRound(cometIndex)).name;

  static String _cleanName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return fallbackName;
    // El genérico ("tu hijo/a") va completo: recortarlo dejaría "tu".
    if (trimmed.toLowerCase() == fallbackName) return fallbackName;
    // Solo el primer nombre: suena más cercano.
    return trimmed.split(RegExp(r'\s+')).first;
  }

  static String _fill(String template, String name) =>
      template.replaceAll('{n}', name);

  /// Pone en mayúscula la primera letra, saltando signos iniciales
  /// como "¡" o "¿".
  static String _capitalize(String s) {
    var i = 0;
    while (i < s.length && '¡¿"'.contains(s[i])) {
      i++;
    }
    if (i >= s.length) return s;
    return s.substring(0, i) + s[i].toUpperCase() + s.substring(i + 1);
  }

  static int _positiveMod(int a, int m) => ((a % m) + m) % m;
}
