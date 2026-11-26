import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/exercise_rating.dart';
import 'package:gymtea3/presentation/widgets/bouncy_tap.dart';

/// Hoja "¿Cómo le fue?" que aparece al terminar cada ejercicio (tras su
/// última serie). El padre valora con 1 a 3 estrellas cómo le fue al niño.
///
/// Devuelve la [ExerciseRating] elegida, o `null` si se saltó.
class HowDidItGoSheet extends StatefulWidget {
  final String childName;
  final String exerciseName;

  /// Valoración previa (si se repite el ejercicio con "anterior").
  final ExerciseRating? initial;

  static const skipKey = Key('how_did_it_go_skip');
  static const doneKey = Key('how_did_it_go_done');
  static Key starKey(int stars) => Key('how_did_it_go_star_$stars');

  const HowDidItGoSheet({
    super.key,
    required this.childName,
    required this.exerciseName,
    this.initial,
  });

  /// Muestra la hoja y espera la respuesta del padre.
  static Future<ExerciseRating?> show(
    BuildContext context, {
    required String childName,
    required String exerciseName,
    ExerciseRating? initial,
  }) {
    return showModalBottomSheet<ExerciseRating>(
      context: context,
      isScrollControlled: true,
      // Con el niño cerca es fácil tocar el fondo sin querer: solo se
      // cierra con "Saltar" o "¡Listo!".
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      // El botón atrás de Android tampoco la cierra: se responde o se salta.
      builder: (_) => PopScope(
        canPop: false,
        child: HowDidItGoSheet(
          childName: childName,
          exerciseName: exerciseName,
          initial: initial,
        ),
      ),
    );
  }

  @override
  State<HowDidItGoSheet> createState() => _HowDidItGoSheetState();
}

class _HowDidItGoSheetState extends State<HowDidItGoSheet>
    with SingleTickerProviderStateMixin {
  ExerciseRating? _selected;

  /// Entrada escalonada de las estrellas (una tras otra, con resorte).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Curva de entrada de cada estrella (una tras otra), creadas una sola
  /// vez para no generar animaciones nuevas en cada rebuild.
  late final List<CurvedAnimation> _starIntros = [
    for (var i = 0; i < ExerciseRating.values.length; i++)
      CurvedAnimation(
        parent: _intro,
        curve: Interval(i * 0.2, (i * 0.2 + 0.6).clamp(0, 1),
            curve: Curves.elasticOut),
      ),
  ];

  /// Igual que [_starIntros] pero sin resorte, para animaciones reducidas.
  late final List<CurvedAnimation> _starFades = [
    for (var i = 0; i < ExerciseRating.values.length; i++)
      CurvedAnimation(
        parent: _intro,
        curve: Interval(i * 0.2, (i * 0.2 + 0.6).clamp(0, 1),
            curve: Curves.easeOut),
      ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  /// Animaciones reducidas: las estrellas entran con un fundido, sin
  /// resorte ni escala.
  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void dispose() {
    for (final a in [..._starIntros, ..._starFades]) {
      a.dispose();
    }
    _intro.dispose();
    super.dispose();
  }

  void _select(ExerciseRating rating) => setState(() => _selected = rating);

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(
              '¿Cómo le fue a ${widget.childName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.goldAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'con ${widget.exerciseName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final rating in ExerciseRating.values)
                  _buildStar(rating, selected),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  selected?.label ?? 'Toca una estrella',
                  key: ValueKey(selected),
                  style: TextStyle(
                    fontSize: selected == null ? 14 : 20,
                    fontWeight:
                        selected == null ? FontWeight.w500 : FontWeight.w800,
                    color: selected == null
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  key: HowDidItGoSheet.skipKey,
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Saltar',
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
                const Spacer(),
                BouncyTap(
                  child: ElevatedButton(
                    key: HowDidItGoSheet.doneKey,
                    onPressed: selected == null
                        ? null
                        : () => Navigator.pop(context, selected),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('¡Listo!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStar(ExerciseRating rating, ExerciseRating? selected) {
    final index = rating.stars - 1;
    final lit = selected != null && rating.stars <= selected.stars;
    final isChosen = selected == rating;

    // Cada estrella entra un poco después que la anterior.
    final intro = _starIntros[index];
    final reduce = _reduceMotion;

    final star = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: BouncyTap(
        pressedScale: 0.8,
        child: GestureDetector(
          key: HowDidItGoSheet.starKey(rating.stars),
          behavior: HitTestBehavior.opaque,
          onTap: () => _select(rating),
          child: AnimatedScale(
            // La elegida rebota más grande.
            scale: isChosen ? 1.25 : (lit ? 1.08 : 1),
            duration: Duration(milliseconds: reduce ? 150 : 450),
            curve: reduce ? Curves.easeOut : Curves.elasticOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                lit ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(lit),
                size: 68,
                color: lit ? AppTheme.goldAccent : Colors.white38,
                shadows: lit
                    ? [
                        Shadow(
                          color: AppTheme.goldAccent.withValues(alpha: 0.6),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );

    // Cada estrella entra un poco después que la anterior.
    if (reduce) {
      return FadeTransition(
        opacity: _starFades[index],
        child: star,
      );
    }
    return ScaleTransition(scale: intro, child: star);
  }
}
