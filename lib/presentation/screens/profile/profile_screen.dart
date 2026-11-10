import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';

/// Pantalla de Perfil — muestra datos del padre e hijo, cerrar sesión
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final user = authProvider.currentUser;
    final child = authProvider.currentChild;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar del padre
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.accentTeal,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nombre del padre
            Text(
              user?.nombre ?? 'Usuario',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 30),

            // Sección: Datos del padre
            _buildSectionTitle('Información Personal'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'RUT',
                value: user?.rut ?? '-',
              ),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user?.email ?? '-',
              ),
              _InfoRow(
                icon: Icons.shield_outlined,
                label: 'Rol',
                value: _formatRole(user?.rol),
              ),
            ]),

            const SizedBox(height: 24),

            // Sección: Datos del niño
            _buildSectionTitle('Datos del Niño'),
            const SizedBox(height: 12),
            if (child != null)
              _buildInfoCard([
                _InfoRow(
                  icon: Icons.child_care_rounded,
                  label: 'Nombre',
                  value: child.nombre,
                ),
                _InfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Edad',
                  value: '${child.edad} años',
                ),
                // El perfilamiento (condición, control motor, nivel asignado)
                // queda fuera por ahora: el avance lo define el mapa.
                _InfoRow(
                  icon: Icons.trending_up_rounded,
                  label: 'Cráteres completados',
                  value: '${exerciseProvider.completedLevels.length}'
                      ' / ${exerciseProvider.totalCraters}',
                  valueColor: AppTheme.primaryGreen,
                ),
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Cráter disponible',
                  value: '${exerciseProvider.highestUnlockedLevel}',
                ),
              ])
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.textLight.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No hay niño asignado aún',
                      style: TextStyle(
                        color: AppTheme.textLight.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Sección: App
            _buildSectionTitle('Aplicación'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: 'Versión',
                value: '1.0.0 (MVP)',
              ),
              _InfoRow(
                icon: Icons.code_rounded,
                label: 'Auspicio',
                value: 'VerdeDigital',
              ),
            ]),

            const SizedBox(height: 32),

            // Reiniciar el avance del mapa de cráteres
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmResetProgress(context),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text(
                  'Reiniciar avance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldAccent,
                  side: BorderSide(
                    color: AppTheme.goldAccent.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Botón cerrar sesión
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmResetProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Reiniciar el avance?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Todos los cráteres volverán a bloquearse y los ejercicios ya '
          'sorteados podrán repetirse.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final provider = dialogContext.read<ExerciseProvider>();
              Navigator.pop(dialogContext);
              await provider.resetProgress();
            },
            child: Text(
              'Reiniciar',
              style: TextStyle(color: AppTheme.goldAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textLight.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isLast = index == rows.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        row.icon,
                        size: 18,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: row.valueColor ?? Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deberás ingresar tu RUT y contraseña nuevamente.',
          style: TextStyle(
            color: AppTheme.textLight.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppTheme.textLight.withValues(alpha: 0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String? role) {
    switch (role) {
      case 'PADRE':
        return 'Padre / Tutor';
      case 'PSICOPEDAGOGO':
        return 'Psicopedagogo';
      case 'TO':
        return 'Terapeuta Ocupacional';
      case 'ADMIN':
        return 'Administrador';
      default:
        return role ?? '-';
    }
  }



}

/// Helper para filas de información
class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}
