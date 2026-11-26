import 'package:flutter/material.dart';

import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/presentation/widgets/glass_stat_box.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';

/// Duración de las animaciones del panel (barra y contadores).
const Duration _countDuration = Duration(milliseconds: 1300);

/// Panel de avance del mapa.
///
/// Ocupa el cielo sobre el cometa con lo que de verdad importa: cuánto
/// se lleva del total y el acumulado de entrenamiento.
///
/// Todo está animado: la barra se llena y los números cuentan desde el
/// valor que mostraban antes (la primera vez, desde 0). Si se pasa
/// [cometName], arriba aparece el chip del cometa actual con su color; si
/// se pasa [routeLabel], al lado va el chip de la ruta elegida.
class ProgressPanel extends StatelessWidget {
  final int completed;
  final int total;
  final TrainingStats stats;

  /// Nombre del cometa que se está recorriendo (p. ej. "Cometa Lavanda").
  final String? cometName;

  /// Color del cometa (su halo), para el chip.
  final Color? cometColor;

  /// Número del cometa (1-based) y total, para "1 de 2".
  final int? cometNumber;
  final int? totalComets;

  /// Ruta de entrenamiento actual (etiqueta, ícono y color).
  final String? routeLabel;
  final IconData? routeIcon;
  final Color? routeColor;

  /// Al tocar el chip de la ruta (p. ej. para cambiarla).
  final VoidCallback? onRouteTap;

  const ProgressPanel({
    super.key,
    required this.completed,
    required this.total,
    required this.stats,
    this.cometName,
    this.cometColor,
    this.cometNumber,
    this.totalComets,
    this.routeLabel,
    this.routeIcon,
    this.routeColor,
    this.onRouteTap,
  });


  @override
  Widget build(BuildContext context) {
    // Sin cuadro grande: una línea con el cometa y los cráteres, y las tres
    // cajitas con el borde del color de la ruta (la dificultad elegida).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (cometName != null) Flexible(child: _buildCometChip()),
              const SizedBox(width: 8),
              _buildCraterCount(),
            ],
          ),
          const SizedBox(height: 10),
          _buildStats(),
        ],
      ),
    );
  }

  /// "7 / 16 cráteres", contando hacia arriba al conquistar uno.
  Widget _buildCraterCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (routeColor ?? AppTheme.goldAccent).withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded, size: 15, color: AppTheme.goldAccent),
          const SizedBox(width: 5),
          BumpOnChange(
            trigger: completed,
            child: AnimatedCount(
              value: completed,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.goldAccent,
              ),
            ),
          ),
          Text(
            ' / $total',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  /// Chip con el nombre del cometa. Cambia con un rebote al llegar a otro.
  Widget _buildCometChip() {
    final color = cometColor ?? AppTheme.goldAccent;
    final suffix = cometNumber != null && totalComets != null
        ? '  ·  $cometNumber de $totalComets'
        : '';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey(cometName),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$cometName$suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Las tres cajas de vidrio. Al volver de un cráter suben en cascada
  /// (ejercicios → minutos → sesiones), cada una con su "+N".
  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: GlassStatBox(
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFF66BB6A),
            value: stats.exercises,
            label: 'ejercicios',
            borderColor: routeColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassStatBox(
            icon: Icons.timer_outlined,
            color: const Color(0xFF4DD0C4),
            value: stats.seconds,
            label: 'juntos',
            format: formatTrainingTime,
            formatDelta: (d) => '+${(d / 60).round()} min',
            delay: const Duration(milliseconds: 300),
            borderColor: routeColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassStatBox(
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF8A65),
            value: stats.sessions,
            label: stats.sessions == 1 ? 'sesión' : 'sesiones',
            delay: const Duration(milliseconds: 600),
            borderColor: routeColor,
          ),
        ),
      ],
    );
  }
}

/// "0 min" · "45 min" · "1h 05m"
String formatTrainingTime(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return '${hours}h ${rest.toString().padLeft(2, '0')}m';
}

/// Número que "cuenta" hasta [value] desde el que mostraba antes (la
/// primera vez, desde 0).
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String Function(int value)? format;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: _countDuration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final shown = v.round();
        return Text(format?.call(shown) ?? '$shown', style: style);
      },
    );
  }
}

/// Da un saltito a [child] cada vez que cambia [trigger] (no al montarse).
class BumpOnChange extends StatefulWidget {
  final Object? trigger;
  final Widget child;

  const BumpOnChange({super.key, required this.trigger, required this.child});

  @override
  State<BumpOnChange> createState() => _BumpOnChangeState();
}

class _BumpOnChangeState extends State<BumpOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
    value: 1,
  );

  @override
  void didUpdateWidget(BumpOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Sube rápido y vuelve con un pequeño rebote.
        final scale = 1 + 0.4 * (1 - Curves.elasticOut.transform(t));
        return Transform.scale(scale: scale.clamp(0.8, 1.5), child: child);
      },
      child: widget.child,
    );
  }
}
