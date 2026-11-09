import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/screens/profile/profile_screen.dart';
import 'package:gymtea3/presentation/widgets/crater_node.dart';
import 'package:gymtea3/presentation/widgets/crater_preview_dialog.dart';

/// Proporción del sprite del cometa (1080 × 982).
const double _cometAspect = 1080 / 982;

/// Cráteres pintados en cada sprite.
const int cratersPerComet = 4;

/// Sprite del cometa según cuántos de sus cráteres se conquistaron.
///
/// El arte trae un estado por cada cantidad, de 0 a 4:
/// `crater_1` ninguno · `crater_2` uno · `crater_3` dos · `crater_4` tres ·
/// `crater_5` los cuatro (viene de "crater 4_1.png").
String cometSpriteFor(int completed) {
  final step = completed.clamp(0, cratersPerComet) + 1;
  return 'assets/images/craters/crater_$step.png';
}

/// Pantalla principal — mapa de cráteres.
///
/// El sprite del cometa **es** el menú: los cráteres pintados en la
/// ilustración son los niveles. La imagen cambia de estado según cuántos
/// se completaron (`crater_1` ninguno → `crater_4` tres turquesa) y encima
/// solo va el marcador con el número, el candado o el visto.
class CraterMapScreen extends StatefulWidget {
  const CraterMapScreen({super.key});

  @override
  State<CraterMapScreen> createState() => _CraterMapScreenState();
}

class _CraterMapScreenState extends State<CraterMapScreen>
    with SingleTickerProviderStateMixin {
  bool _openingCrater = false;

  /// Vaiven del marciano para que no se vea estatico.
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadMapState();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildStarfield(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, provider),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMap(provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarfield() {
    return Image.asset(
      'assets/images/craters/fondo_estrellas.png',
      fit: BoxFit.cover,
      repeat: ImageRepeat.repeatY,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Container(color: AppTheme.backgroundDark),
    );
  }

  Widget _buildTopBar(BuildContext context, ExerciseProvider provider) {
    final childName = context.watch<AuthProvider>().childName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mapa de Cráteres',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$childName · ${provider.completedLevels.length} de '
                  '${provider.visibleCraterCount} conquistados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          _buildIconButton(
            icon: Icons.sports_esports_rounded,
            tooltip: 'Minijuegos',
            onTap: () => Navigator.pushNamed(context, '/minigames'),
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.person_rounded,
            tooltip: 'Perfil',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(ExerciseProvider provider) {
    // Cada cometa lleva hasta 4 cráteres; con 7 niveles son dos cometas.
    final zones = (provider.visibleCraterCount / cratersPerComet).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // El cometa se escala para llenar buena parte del alto disponible.
        // Puede salirse de ancho (se recorta por los costados), pero con un
        // tope: pasado 1.30x, los crateres de los extremos quedarian fuera
        // de pantalla.
        const maxOverflow = 1.30;
        var cometWidth = (constraints.maxHeight * 0.62) * _cometAspect;
        cometWidth = cometWidth.clamp(
          constraints.maxWidth,
          constraints.maxWidth * maxOverflow,
        );
        final cometHeight = cometWidth / _cometAspect;

        return SingleChildScrollView(
          reverse: true, // el cometa del cráter 1 queda abajo
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (provider.visibleCraterCount ==
                    AppConstants.initialCraterCount)
                  _buildHint(),
                for (int zone = zones - 1; zone >= 0; zone--)
                  _buildComet(
                    provider: provider,
                    zone: zone,
                    viewportWidth: constraints.maxWidth,
                    width: cometWidth,
                    height: cometHeight,
                  ),
                // aire para que el marcador mas bajo no quede pegado al borde
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppTheme.goldAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Conquista los ${AppConstants.initialCraterCount} cráteres '
              'para descubrir un nuevo cometa.',
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Un cometa con sus cráteres. El sprite cambia según cuántos de los
  /// cráteres de **esta** zona ya se completaron.
  Widget _buildComet({
    required ExerciseProvider provider,
    required int zone,
    required double viewportWidth,
    required double width,
    required double height,
  }) {
    final firstLevel = zone * cratersPerComet + 1;
    final levels = <int>[
      for (int i = 0; i < cratersPerComet; i++)
        if (firstLevel + i <= provider.visibleCraterCount) firstLevel + i,
    ];

    final sprite = cometSpriteFor(levels.where(provider.isCompleted).length);

    // Aire sobre el cometa para los marcadores que flotan en el espacio
    // (el de la cima) y para el marciano.
    const headroom = 96.0;
    final totalHeight = height + headroom;

    return SizedBox(
      width: viewportWidth,
      height: totalHeight,
      child: ClipRect(
        child: OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: totalHeight,
          maxHeight: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: headroom,
                width: width,
                height: height,
                child: Image.asset(
                  sprite,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              for (final level in levels)
                _buildMarker(
                  provider: provider,
                  level: level,
                  spot: CraterSpot.all[(level - firstLevel) % cratersPerComet],
                  width: width,
                  height: height,
                  headroom: headroom,
                ),
              if (levels.contains(provider.highestUnlockedLevel))
                _buildAlien(
                  spot: CraterSpot.all[
                      (provider.highestUnlockedLevel - firstLevel) %
                          cratersPerComet],
                  width: width,
                  height: height,
                  headroom: headroom,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// El marciano acompana al crater actual y flota suavemente. Al
  /// conquistar un crater se desplaza al siguiente.
  Widget _buildAlien({
    required CraterSpot spot,
    required double width,
    required double height,
    required double headroom,
  }) {
    const size = 72.0;

    // Se para al costado del crater, un poco mas arriba. El clamp evita
    // que se corte contra los bordes de la zona (el crater de la cima
    // tiene cy negativa).
    var left = spot.cx * width + spot.rx * width * 0.9;
    if (left + size > width) {
      left = spot.cx * width - spot.rx * width * 0.9 - size;
    }
    left = left.clamp(4.0, width - size - 4);

    final top = (headroom + spot.cy * height - size * 1.15)
        .clamp(10.0, headroom + height - size);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      left: left,
      top: top,
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_floatController.value);
          return Transform.translate(
            offset: Offset(0, -6 + t * 12),
            child: child,
          );
        },
        child: Image.asset(
          'assets/images/mascota/alien.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildMarker({
    required ExerciseProvider provider,
    required int level,
    required CraterSpot spot,
    required double width,
    required double height,
    required double headroom,
  }) {
    final status = provider.isCompleted(level)
        ? CraterStatus.completed
        : provider.isUnlocked(level)
            ? CraterStatus.available
            : CraterStatus.locked;

    final w = spot.rx * 2 * width;
    final h = spot.ry * 2 * height;

    return Positioned(
      left: spot.cx * width - w / 2,
      top: headroom + spot.cy * height - h / 2,
      width: w,
      height: h,
      child: CraterMarker(
        level: level,
        status: status,
        dificultad: Dificultad.forLevel(level),
        craterSize: Size(w, h),
        onTap: () => _openCrater(level),
      ),
    );
  }

  // ------------------------------------------------------------

  Future<void> _openCrater(int level) async {
    if (_openingCrater) return;
    _openingCrater = true;

    final provider = context.read<ExerciseProvider>();
    final childId =
        context.read<AuthProvider>().currentChild?.id ?? 'mock-child';

    try {
      await provider.buildRoutine(childId: childId, level: level);
      if (!mounted) return;

      var reshuffling = false;

      final start = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Consumer<ExerciseProvider>(
                builder: (_, p, __) {
                  final routine = p.previewRoutine;
                  if (routine == null) return const SizedBox.shrink();

                  return CraterPreviewDialog(
                    routine: routine,
                    isReshuffling: reshuffling,
                    onReshuffle: () async {
                      setDialogState(() => reshuffling = true);
                      await p.buildRoutine(childId: childId, level: level);
                      setDialogState(() => reshuffling = false);
                    },
                  );
                },
              );
            },
          );
        },
      );

      if (!mounted) return;

      if (start == true) {
        await Navigator.pushNamed(context, '/exercises/session');
        if (!mounted) return;
        await provider.loadMapState();
      } else {
        await provider.discardPreview();
      }
    } finally {
      _openingCrater = false;
    }
  }
}
