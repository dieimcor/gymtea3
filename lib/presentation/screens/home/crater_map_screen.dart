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

/// Pantalla principal — mapa de cráteres.
///
/// Reemplaza al antiguo Home con bottom navigation. Cada cráter es un
/// nivel: se parte con el cráter 1 abierto y cada cráter completado abre
/// el siguiente. Los cráteres 5-7 se revelan al superar los 4 primeros.
class CraterMapScreen extends StatefulWidget {
  const CraterMapScreen({super.key});

  @override
  State<CraterMapScreen> createState() => _CraterMapScreenState();
}

class _CraterMapScreenState extends State<CraterMapScreen> {
  bool _openingCrater = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadMapState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: exerciseProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMap(exerciseProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Image.asset(
      'assets/images/craters/fondo_espacio.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Container(color: AppTheme.backgroundDark),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final childName = context.watch<AuthProvider>().childName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mapa de Cráteres',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Entrenamiento de $childName',
                  style: TextStyle(
                    fontSize: 13,
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
        color: Colors.white.withValues(alpha: 0.08),
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
    final levels = provider.visibleLevels;
    final allInitialDone =
        provider.visibleCraterCount > AppConstants.initialCraterCount;

    return SingleChildScrollView(
      reverse: true, // el cráter 1 queda abajo, como punto de partida
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          if (!allInitialDone) _buildHint(),
          const SizedBox(height: 16),
          for (int i = levels.length - 1; i >= 0; i--) ...[
            _buildCraterRow(provider, levels[i]),
            if (i > 0) _buildTrail(provider, levels[i - 1]),
          ],
          const SizedBox(height: 8),
          _buildSurface(),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/mascota/alien.png',
            height: 36,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.goldAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Completa los ${AppConstants.initialCraterCount} primeros '
              'cráteres para descubrir el resto del planeta.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCraterRow(ExerciseProvider provider, int level) {
    final status = provider.isCompleted(level)
        ? CraterStatus.completed
        : provider.isUnlocked(level)
            ? CraterStatus.available
            : CraterStatus.locked;

    final isLeft = level.isOdd;

    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(
          left: isLeft ? 0 : 32,
          right: isLeft ? 32 : 0,
          top: 6,
          bottom: 6,
        ),
        child: CraterNode(
          level: level,
          status: status,
          dificultad: Dificultad.forLevel(level),
          onTap: () => _openCrater(level),
        ),
      ),
    );
  }

  /// Huellas entre un cráter y el siguiente.
  Widget _buildTrail(ExerciseProvider provider, int fromLevel) {
    final walked = provider.isCompleted(fromLevel);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(
              left: i.isEven ? 0 : 18,
              top: 3,
              bottom: 3,
            ),
            child: Container(
              width: 10,
              height: 6,
              decoration: BoxDecoration(
                color: walked
                    ? AppTheme.goldAccent.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Superficie del planeta al pie del mapa.
  Widget _buildSurface() {
    return Image.asset(
      'assets/images/craters/crater_base.png',
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  // ------------------------------------------------------------

  Future<void> _openCrater(int level) async {
    if (_openingCrater) return;
    _openingCrater = true;

    final provider = context.read<ExerciseProvider>();
    final childId = context.read<AuthProvider>().currentChild?.id ?? 'mock-child';

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
