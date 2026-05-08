import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/screens/profile/profile_screen.dart';

/// Home Screen — hub central con bottom navigation
/// Tabs: Ejercicios (placeholder) · Minijuegos (placeholder) · Perfil
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ExercisesTab(),
          _MinigamesTab(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon: Icon(Icons.fitness_center_rounded),
              label: 'Ejercicios',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(Icons.sports_esports_rounded),
              label: 'Minijuegos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return 'Ejercicios';
      case 1:
        return 'Minijuegos';
      case 2:
        return 'Perfil';
      default:
        return 'NeuroGym';
    }
  }
}

/// Tab de Ejercicios — placeholder con resumen y acceso al mapa de niveles
class _ExercisesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final childName = authProvider.childName;
    final childLevel = authProvider.childLevel;
    final greeting = authProvider.greeting;
    final parentName = authProvider.currentUser?.nombre.split(' ').first ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo contextual
          Text(
            '$greeting, $parentName 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Entrenamiento de $childName',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textLight.withValues(alpha: 0.6),
            ),
          ),

          const SizedBox(height: 28),

          // Card: Nivel actual
          _buildLevelCard(childLevel, childName),

          const SizedBox(height: 16),

          // Card: Sesión del día
          _buildSessionCard(context),

          const SizedBox(height: 16),

          // Card: Progreso rápido
          _buildProgressCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLevelCard(int level, String childName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.3),
            AppTheme.accentTeal.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Nivel badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$level',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nivel Actual',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nivel $level de 7',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: level / 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/exercises/levels');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.goldAccent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.play_circle_filled_rounded,
                color: AppTheme.goldAccent,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesión del Día',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '15 min · 3 fases · 5 ejercicios',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textLight.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight.withValues(alpha: 0.4),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.calendar_today_rounded,
                value: '0',
                label: 'Sesiones hoy',
                color: AppTheme.categoryRD,
              ),
              _buildStatItem(
                icon: Icons.local_fire_department_rounded,
                value: '0',
                label: 'Racha',
                color: AppTheme.categoryEM,
              ),
              _buildStatItem(
                icon: Icons.timer_outlined,
                value: '0m',
                label: 'Tiempo total',
                color: AppTheme.categoryJL,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textLight.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Tab de Minijuegos — placeholder
class _MinigamesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_esports_rounded,
                size: 64,
                color: AppTheme.accentTeal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Minijuegos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Juegos educativos de higiene, orden,\nautonomía y alimentación.\n\nDisponible en Fase 4.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
