import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/core/theme/comet_theme.dart';
import 'package:gymtea3/data/models/reward_messages.dart';
import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/presentation/animations/confetti.dart';
import 'package:gymtea3/presentation/widgets/bouncy_tap.dart';

/// Argumentos de [CometRewardScreen].
class CometRewardArgs {
  /// Nombre del niño, para personalizar el mensaje al padre.
  final String childName;

  /// Cometa recién conquistado (0-based).
  final int cometIndex;

  /// `true` si era el último cometa: se terminó el viaje completo.
  final bool journeyCompleted;

  /// Ruta del padre: define qué planeta se conquistó (y su color). Si es
  /// `null` se usa la paleta general.
  final TrainingRoute? route;

  const CometRewardArgs({
    required this.childName,
    required this.cometIndex,
    required this.journeyCompleted,
    this.route,
  });

  /// Planeta conquistado.
  CometTheme get comet =>
      route?.cometAt(cometIndex) ?? CometTheme.forRound(cometIndex);
}

/// Recompensa al conquistar un cometa completo (sus 4 cráteres).
///
/// Le habla al **padre**: lo invita a celebrar con su hijo (abrazo,
/// chocar los cinco…) con mensajes que cambian. Al cerrarla se hace
/// `Navigator.pop` y el mapa reproduce el viaje al siguiente cometa.
class CometRewardScreen extends StatefulWidget {
  static const routeName = '/rewards/comet';

  /// Semilla del mensaje. Si es `null` se elige al azar (cada visita
  /// muestra una invitación distinta); los tests la fijan.
  final int? seed;

  /// Argumentos directos; si es `null` se leen de la ruta.
  final CometRewardArgs? args;

  const CometRewardScreen({super.key, this.seed, this.args});

  @override
  State<CometRewardScreen> createState() => _CometRewardScreenState();
}

class _CometRewardScreenState extends State<CometRewardScreen>
    with TickerProviderStateMixin {
  /// Si no llegan argumentos, la pantalla igual se ve bien.
  static const _fallbackArgs = CometRewardArgs(
    childName: '',
    cometIndex: 0,
    journeyCompleted: false,
  );

  /// Entrada escalonada: alien → título → tarjeta → botón.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  /// Flotar suave del alien, en bucle.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final int _seed = widget.seed ?? math.Random().nextInt(1 << 16);

  /// Cada toque al alien relanza el confeti (al niño le encanta).
  int _confettiTrigger = 0;

  /// Animaciones reducidas (accesibilidad): sin rebotes ni flotar.
  bool _reduceMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (_reduceMotion) {
      _float.stop();
      _float.value = 0;
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
    if (!_started) {
      _started = true;
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  CometRewardArgs _readArgs(BuildContext context) {
    if (widget.args != null) return widget.args!;
    final raw = ModalRoute.of(context)?.settings.arguments;
    return raw is CometRewardArgs ? raw : _fallbackArgs;
  }

  /// Curva de entrada para el tramo [begin]..[end] de [_entrance].
  Animation<double> _interval(double begin, double end,
          [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(
        parent: _entrance,
        // Con animaciones reducidas, solo fundidos suaves (sin rebotes).
        curve:
            Interval(begin, end, curve: _reduceMotion ? Curves.easeOut : curve),
      );

  void _celebrateAgain() {
    HapticFeedback.lightImpact();
    setState(() => _confettiTrigger++);
  }

  @override
  Widget build(BuildContext context) {
    final args = _readArgs(context);
    final comet = args.comet;
    final reward = RewardMessages.forComet(
      args.childName,
      args.cometIndex,
      seed: _seed,
      journeyCompleted: args.journeyCompleted,
      cometName: comet.name,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con color fijo: el tono del cometa no tiñe el fondo.
          const _SpaceBackground(glow: Color(0xFF7FD8E8)),
          ConfettiBurst(
            trigger: _confettiTrigger,
            seed: _seed,
            particleCount: args.journeyCompleted ? 140 : 90,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      _buildMascot(comet),
                      const SizedBox(height: 20),
                      _EntranceSlide(
                        animation: _interval(0.30, 0.60),
                        child: _buildTitle(reward, comet, args.route),
                      ),
                      const SizedBox(height: 24),
                      _EntranceSlide(
                        animation: _interval(0.50, 0.85),
                        offsetY: 40,
                        child: _ParentCard(reward: reward, glow: comet.glow),
                      ),
                      const SizedBox(height: 28),
                      _EntranceSlide(
                        animation: _interval(0.70, 1.0, Curves.easeOutBack),
                        child: _buildButton(args.journeyCompleted),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot(CometTheme comet) {
    final pop = _interval(0.0, 0.45, Curves.elasticOut);
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _float]),
      builder: (context, child) {
        if (_reduceMotion) {
          // Sin escala ni flotar: el alien solo aparece.
          return Opacity(opacity: pop.value.clamp(0.0, 1.0), child: child);
        }
        final bob = math.sin(_float.value * math.pi) * 8;
        return Transform.translate(
          offset: Offset(0, -bob),
          child: Transform.scale(scale: pop.value, child: child),
        );
      },
      child: BouncyTap(
        child: GestureDetector(
          onTap: _celebrateAgain,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  comet.glow.withValues(alpha: 0.45),
                  comet.glow.withValues(alpha: 0.0),
                ],
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Image.asset(
              'assets/images/mascota/alien_calificacion.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.emoji_events_rounded,
                size: 110,
                color: AppTheme.goldAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(
      RewardMessage reward, CometTheme comet, TrainingRoute? route) {
    return Column(
      children: [
        Text(
          reward.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [
              Shadow(color: comet.glow.withValues(alpha: 0.8), blurRadius: 18),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCratersPill(comet),
            if (route != null) _buildRoutePill(route),
          ],
        ),
      ],
    );
  }

  /// "Ruta Comandante": la ruta en la que lo lograron, en su color.
  Widget _buildRoutePill(TrainingRoute route) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: route.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: route.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(route.icon, size: 16, color: route.color),
          const SizedBox(width: 6),
          Text(
            'Ruta ${route.label}',
            style: TextStyle(
              color: route.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCratersPill(CometTheme comet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: comet.glow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: comet.glow.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: comet.glow),
          const SizedBox(width: 6),
          Text(
            '¡${AppConstants.cratersPerComet} de ${AppConstants.cratersPerComet} cráteres!',
            style: TextStyle(
              color: comet.glow,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(bool journeyCompleted) {
    return BouncyTap(
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: Icon(journeyCompleted
              ? Icons.home_rounded
              : Icons.rocket_launch_rounded),
          label: Text(
            journeyCompleted
                ? '¡Viaje completo! Volver al mapa'
                : '¡Al siguiente cometa!',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.goldAccent,
            foregroundColor: AppTheme.backgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 6,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta destacada para el padre: qué hacer para celebrar con su hijo.
class _ParentCard extends StatelessWidget {
  final RewardMessage reward;
  final Color glow;

  const _ParentCard({required this.reward, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: AppTheme.goldAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'PARA TI, PAPÁ O MAMÁ',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldAccent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reward.headline,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reward.message,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppTheme.textLight.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volunteer_activism_rounded,
                    size: 18, color: AppTheme.goldAccent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Gesto sugerido: ${reward.gesture}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aparece deslizándose hacia arriba con un fundido.
class _EntranceSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double offsetY;

  const _EntranceSlide({
    required this.animation,
    required this.child,
    this.offsetY = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Fondo espacial: estrellas del mapa + halo del color del cometa.
class _SpaceBackground extends StatelessWidget {
  final Color glow;

  const _SpaceBackground({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/craters/fondo_estrellas.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: AppTheme.backgroundDark),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.45),
              radius: 1.1,
              colors: [
                glow.withValues(alpha: 0.35),
                AppTheme.backgroundDark.withValues(alpha: 0.55),
                AppTheme.backgroundDark.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
