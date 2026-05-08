import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/widgets/level_node.dart';

/// Mapa vertical de 7 niveles con estados bloqueado/desbloqueado
/// Navega a la sesión activa al tocar el nivel actual
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().loadAvailableFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final childLevel = authProvider.childLevel;
    final childName = authProvider.childName;
    final levels = exerciseProvider.availableLevels.isNotEmpty
        ? exerciseProvider.availableLevels
        : List.generate(7, (i) => i + 1);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Niveles de $childName',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryGreen.withValues(alpha: 0.2),
                    AppTheme.accentTeal.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Toca tu nivel actual para iniciar la sesión del día',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Level map (scrollable, bottom to top)
          Expanded(
            child: SingleChildScrollView(
              reverse: true, // Start from bottom (level 1)
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  for (int i = levels.length - 1; i >= 0; i--) ...[
                    _buildLevelRow(levels[i], childLevel, context),
                    if (i > 0) _buildConnector(levels[i], childLevel),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow(int level, int childLevel, BuildContext context) {
    final status = level < childLevel
        ? LevelStatus.completed
        : level == childLevel
            ? LevelStatus.current
            : LevelStatus.locked;

    // Stagger nodes left/right for visual interest
    final isLeft = level.isOdd;
    final alignment = isLeft ? Alignment.centerLeft : Alignment.centerRight;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: isLeft ? 0 : 40,
          right: isLeft ? 40 : 0,
        ),
        child: LevelNode(
          level: level,
          status: status,
          completedSessions: 0, // TODO: load from progress
          onTap: () {
            if (status == LevelStatus.current || status == LevelStatus.completed) {
              Navigator.pushNamed(
                context,
                '/exercises/session',
                arguments: level,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildConnector(int level, int childLevel) {
    final isCompleted = level <= childLevel;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: List.generate(3, (i) {
          return Container(
            width: 3,
            height: 6,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
