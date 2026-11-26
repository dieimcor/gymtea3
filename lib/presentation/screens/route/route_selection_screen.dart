import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/screens/route/launch_screen.dart';
import 'package:gymtea3/presentation/widgets/bouncy_tap.dart';

/// Colores del "Cuestionario" original, llevados al tema oscuro.
class _Cuestionario {
  static const Color crema = Color(0xFFFFF8E7);
  static const Color borde = Color(0xFFFFE082);
  static const Color cafe = Color(0xFF7A2E0E);
  static const Color barraLlena = Color(0xFF7EC8DC);
}

/// Elección de la ruta de entrenamiento.
///
/// Se muestra la primera vez (después del login) y desde Perfil para
/// cambiarla (`arguments: {'changing': true}`). Usa el lenguaje visual del
/// "Cuestionario": el marciano con su portapapeles pregunta en un globo y
/// cada ruta es una tarjeta crema con borde amarillo y barras de nivel.
///
/// Al confirmar guarda la ruta (cada una conserva su avance) y abre el
/// despegue ([LaunchScreen]).
class RouteSelectionScreen extends StatefulWidget {
  static const String routeName = '/route';

  /// Fuerza el modo "cambiar ruta". Si es null se lee de los argumentos
  /// de la ruta (`{'changing': true}`).
  final bool? changing;

  const RouteSelectionScreen({super.key, this.changing});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen>
    with SingleTickerProviderStateMixin {
  /// Entrada escalonada: marciano, globo y luego cada tarjeta.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  TrainingRoute? _selected;
  bool _changing = false;
  bool _saving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _changing = widget.changing ?? (args is Map && args['changing'] == true);

    if (_changing) {
      // Al cambiar, parte marcada la ruta actual.
      _selected = context.read<ExerciseProvider>().route;
    }

    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Primer nombre del niño, o "tu hijo/a" si no hay (o no hay sesión).
  String get _childFirstName {
    try {
      final name = context.read<AuthProvider>().currentChild?.nombre.trim();
      if (name == null || name.isEmpty) return 'tu hijo/a';
      return name.split(RegExp(r'\s+')).first;
    } on ProviderNotFoundException {
      return 'tu hijo/a';
    }
  }

  Future<void> _confirm() async {
    final route = _selected;
    if (route == null || _saving) return;
    setState(() => _saving = true);

    final provider = context.read<ExerciseProvider>();
    await provider.selectRoute(route);
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      LaunchScreen.routeName,
      (_) => false,
    );
  }

  /// Animación de entrada de un elemento entre [begin] y [end] (0 a 1).
  Widget _staggered({
    required double begin,
    required double end,
    required Widget child,
    double dy = 24,
  }) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - anim.value) * dy),
          child: child,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/craters/fondo_estrellas.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppTheme.backgroundDark),
          ),
          SafeArea(
            child: Column(
              children: [
                if (_changing) _buildBackRow(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 18),
                            for (var i = 0;
                                i < TrainingRoute.values.length;
                                i++) ...[
                              _staggered(
                                begin: 0.3 + i * 0.15,
                                end: 0.75 + i * 0.08,
                                child: _RouteCard(
                                  route: TrainingRoute.values[i],
                                  selected:
                                      _selected == TrainingRoute.values[i],
                                  onTap: _saving
                                      ? null
                                      : () => setState(() =>
                                          _selected = TrainingRoute.values[i]),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_changing)
                              _staggered(
                                begin: 0.8,
                                end: 1,
                                child: _buildChangingNote(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildLaunchButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackRow(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: IconButton(
          tooltip: 'Volver',
          onPressed: _saving ? null : () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
      ),
    );
  }

  /// Marciano con portapapeles arriba a la derecha y el globo de diálogo.
  Widget _buildHeader() {
    return SizedBox(
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 150,
            child: _staggered(
              begin: 0,
              end: 0.45,
              dy: 40,
              child: Image.asset(
                'assets/images/mascota/alien_portapapeles.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.assignment_rounded,
                  size: 80,
                  color: _Cuestionario.barraLlena,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 130,
            top: 10,
            child: _staggered(
              begin: 0.12,
              end: 0.55,
              child: _SpeechBubble(
                text: '¿Qué tan lejos viajamos con $_childFirstName?',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangingNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Cuestionario.borde.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded,
              size: 18, color: _Cuestionario.borde),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'El avance de cada ruta se guarda. Si vuelven a una ruta, '
              'siguen donde la dejaron.',
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchButton() {
    final enabled = _selected != null && !_saving;
    final color = _selected?.color ?? AppTheme.primaryGreen;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: BouncyTap(
        pressedScale: 0.94,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: enabled ? 1 : 0.5,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: enabled ? _confirm : null,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: const Text(
                '¡Despegar!',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Globo de diálogo crema con borde amarillo grueso y texto café.
class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Cuestionario.crema,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _Cuestionario.borde, width: 5),
        boxShadow: [
          BoxShadow(
            color: _Cuestionario.borde.withValues(alpha: 0.25),
            blurRadius: 18,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: _Cuestionario.cafe,
        ),
      ),
    );
  }
}

/// Tarjeta de una ruta, al estilo de las opciones del Cuestionario.
class _RouteCard extends StatelessWidget {
  final TrainingRoute route;
  final bool selected;
  final VoidCallback? onTap;

  const _RouteCard({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  String get _seriesText {
    // La ruta Comandante suma un ejercicio por cráter (3-5 → 4-6).
    final min = 3 + route.extraExercises;
    final max = 5 + route.extraExercises;
    return 'Series de ${route.seriesSeconds} s · $min a $max ejercicios';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Ruta ${route.label}',
      child: BouncyTap(
        pressedScale: 0.97,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: selected ? 1.03 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: _Cuestionario.crema,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? route.color : _Cuestionario.borde,
                  width: 5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? route.color.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.25),
                    blurRadius: selected ? 22 : 8,
                    spreadRadius: selected ? 2 : 0,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _LevelBars(filled: route.nivel),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildBody()),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(selected),
                      color: selected
                          ? route.color
                          : _Cuestionario.cafe.withValues(alpha: 0.3),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final detailStyle = TextStyle(
      fontSize: 12.5,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: _Cuestionario.cafe.withValues(alpha: 0.85),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(route.icon, size: 20, color: route.color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                route.label,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _Cuestionario.cafe,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          route.tagline,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _Cuestionario.cafe,
          ),
        ),
        const SizedBox(height: 8),
        _detail(Icons.timer_outlined, _seriesText, detailStyle),
        const SizedBox(height: 3),
        _detail(Icons.backpack_outlined, route.equipoTexto, detailStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final comet in route.comets)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: comet.glow,
                      border: Border.all(
                        color: _Cuestionario.cafe.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(comet.name, style: detailStyle),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _detail(IconData icon, String text, TextStyle style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _Cuestionario.cafe.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Barras de nivel crecientes: las primeras [filled] van celestes y el
/// resto amarillo pálido, como en el Cuestionario.
class _LevelBars extends StatelessWidget {
  final int filled;

  const _LevelBars({required this.filled});

  @override
  Widget build(BuildContext context) {
    const total = TrainingRoute.maxNivel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 10,
            height: 18.0 + i * 11,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color:
                  i < filled ? _Cuestionario.barraLlena : _Cuestionario.borde,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
