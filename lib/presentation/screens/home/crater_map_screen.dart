import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gymtea3/core/constants/app_constants.dart';
import 'package:gymtea3/core/theme/app_theme.dart';
import 'package:gymtea3/data/models/difficulty.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';
import 'package:gymtea3/presentation/animations/comet_travel.dart';
import 'package:gymtea3/presentation/animations/comet_turn.dart';
import 'package:gymtea3/presentation/animations/space_backdrop.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/screens/profile/profile_screen.dart';
import 'package:gymtea3/presentation/widgets/bouncy_tap.dart';
import 'package:gymtea3/presentation/widgets/crater_node.dart';
import 'package:gymtea3/presentation/widgets/crater_preview_dialog.dart';
import 'package:gymtea3/presentation/widgets/progress_panel.dart';

/// Proporción del sprite del cometa (1080 × 982).
const double _cometAspect = 1080 / 982;

/// Cráteres pintados en cada sprite (una cara del cometa).
const int cratersPerSprite = 4;

/// Cuánto puede salirse el cometa del ancho de pantalla. Pasado esto, los
/// cráteres de los extremos quedarían fuera.
const double _maxCometOverflow = 1.30;

/// Espera antes de copiar el estado nuevo al volver al mapa, para que la
/// pantalla que se cierra termine su transición y se vea la animación.
const Duration mapSyncDelay = Duration(milliseconds: 350);

/// Sprite del cometa según cuántos de sus cráteres se conquistaron.
///
/// El arte trae un estado por cada cantidad, de 0 a 4:
/// `crater_1` ninguno · `crater_2` uno · `crater_3` dos · `crater_4` tres ·
/// `crater_5` los cuatro (viene de "crater 4_1.png").
String cometSpriteFor(int completed) {
  final step = completed.clamp(0, cratersPerSprite) + 1;
  return 'assets/images/craters/crater_$step.png';
}

/// Mensajes cálidos para el padre que rotan en el aviso del mapa.
///
/// [childName] es el primer nombre del niño y [crater] el número del
/// cráter disponible. Todos mantienen la idea de hacerlo juntos.
///
/// [lastFace] indica si la cara actual es la última del cometa: al
/// terminarla se viaja al siguiente; si no, el cometa da la vuelta.
List<String> mapHintMessages(String childName, int crater,
    {bool lastFace = true}) {
  final goal = lastFace
      ? 'viajarán juntos al siguiente cometa'
      : 'darán juntos la vuelta al cometa';
  return [
    'Hoy $childName y tú van por el cráter $crater. '
        '¡Un ratito juntos hace la diferencia!',
    'Cada cráter es una aventura de los dos. Conquisten estos '
        '${AppConstants.initialCraterCount} y $goal.',
    'Celebra cada intento de $childName, no solo cuando sale perfecto.',
    'El cráter $crater los espera. Vayan a su ritmo: lo importante es '
        'pasarlo bien juntos.',
    'Conquisten estos ${AppConstants.initialCraterCount} cráteres y $goal.',
  ];
}

/// Mensaje del día: depende del día y del cráter, así no cambia en cada
/// visita pero sí de un día a otro y al avanzar. [offset] permite pasar
/// al siguiente al tocar el aviso.
String mapHintFor(
  String childName,
  int crater, {
  DateTime? today,
  int offset = 0,
  bool lastFace = true,
}) {
  final messages = mapHintMessages(childName, crater, lastFace: lastFace);
  final day = (today ?? DateTime.now()).difference(DateTime(2026)).inDays.abs();
  return messages[(day + crater + offset) % messages.length];
}

/// Pantalla principal — mapa de cráteres.
///
/// El sprite del cometa **es** el menú: los cráteres pintados en la
/// ilustración son los niveles. La imagen cambia de estado según cuántos
/// se completaron (`crater_1` ninguno → `crater_5` los cuatro) y encima
/// solo va el marcador con el número, el candado o el visto.
///
/// Hay **un solo cometa**: al conquistar sus 4 cráteres, los marcadores se
/// renumeran con los siguientes niveles y el cometa vuelve a empezar. Cada
/// vuelta se pinta con otro [CometTheme] y, al pasar de una a otra, se
/// reproduce el viaje ([CometTravel]). Los cometas son los de la ruta de
/// entrenamiento elegida (`ExerciseProvider.cometTheme`).
///
/// Con "reducir movimiento" activo el cometa y el marciano quedan quietos,
/// los cráteres no laten y el viaje es un fundido corto.
class CraterMapScreen extends StatefulWidget {
  /// Indicador mientras se prepara el cráter tocado.
  static const preparingKey = Key('crater_preparing');

  const CraterMapScreen({super.key});

  @override
  State<CraterMapScreen> createState() => _CraterMapScreenState();
}

/// Lo que el mapa está mostrando. Se copia del provider solo cuando el
/// mapa está a la vista, así las animaciones (conteo, "pop" del cráter,
/// viaje) ocurren cuando el padre vuelve al mapa y no detrás de la sesión
/// o de la recompensa.
@immutable
class _MapView {
  final Set<int> completed;
  final int highestUnlocked;
  final int roundIndex;
  final int cometIndex;
  final int firstLevel;
  final List<int> levels;
  final bool hasNextRound;
  final TrainingStats stats;

  const _MapView({
    required this.completed,
    required this.highestUnlocked,
    required this.roundIndex,
    required this.cometIndex,
    required this.firstLevel,
    required this.levels,
    required this.hasNextRound,
    required this.stats,
  });

  factory _MapView.of(ExerciseProvider p) => _MapView(
        completed: Set.unmodifiable(p.completedLevels),
        highestUnlocked: p.highestUnlockedLevel,
        roundIndex: p.roundIndex,
        cometIndex: p.cometIndex,
        firstLevel: p.firstLevelInRound,
        levels: List.unmodifiable(p.levelsInRound),
        hasNextRound: p.hasNextRound,
        stats: p.stats,
      );

  bool isCompleted(int level) => completed.contains(level);
  bool isUnlocked(int level) => level <= highestUnlocked;

  /// `true` si es la última cara de su cometa.
  bool get isLastFace =>
      roundIndex % AppConstants.facesPerComet == AppConstants.facesPerComet - 1;

  bool sameAs(_MapView other) =>
      setEquals(completed, other.completed) &&
      highestUnlocked == other.highestUnlocked &&
      roundIndex == other.roundIndex &&
      stats.exercises == other.stats.exercises &&
      stats.seconds == other.stats.seconds &&
      stats.sessions == other.stats.sessions;
}

/// Viaje en curso entre dos cometas.
@immutable
class _Travel {
  final int from;
  final int to;
  const _Travel(this.from, this.to);
}

class _CraterMapScreenState extends State<CraterMapScreen>
    with TickerProviderStateMixin {
  bool _openingCrater = false;

  /// Se está sorteando la rutina del cráter tocado. El indicador solo
  /// aparece si tarda (ver [_spinnerDelay]) para no parpadear.
  bool _showCraterSpinner = false;
  Timer? _spinnerTimer;
  static const _spinnerDelay = Duration(milliseconds: 250);

  /// Vaiven del marciano y del cometa para que no se vean estaticos.
  late final AnimationController _floatController;

  /// Ciclo de animaciones del marciano (flota, se acerca, da una vuelta,
  /// salta). Ver [alienMotion].
  late final AnimationController _alienController;

  /// Entrada del tablero la primera vez: el cometa aparece con un zoom y
  /// el panel baja desde arriba.
  late final AnimationController _entranceController;

  /// `true` si el sistema pide reducir el movimiento.
  bool _reduceMotion = false;

  /// Mensajes que el padre ya pasó tocando el aviso.
  int _hintOffset = 0;

  /// Estado que se esta dibujando (null hasta la primera carga).
  _MapView? _view;

  /// Lo que muestra el panel. Durante el viaje se queda con lo anterior y
  /// cuenta cuando el mapa nuevo ya esta a la vista.
  _MapView? _panelView;

  /// Viaje al siguiente cometa que se esta reproduciendo.
  _Travel? _travel;

  /// Vuelta del cometa hacia su otra cara (pasa por el cometa completo).
  bool _turning = false;

  Timer? _syncTimer;

  /// Une el lugar del marciano dentro del cometa con su dibujo en la capa
  /// superior de la pantalla (ver [_buildAlienOverlay]).
  final LayerLink _alienLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      value: 0.5,
    );
    _alienController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialLoad());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduceMotion) {
      // Quieto en el medio del vaivén.
      _floatController
        ..stop()
        ..value = 0.5;
      _alienController
        ..stop()
        ..value = 0;
    } else {
      if (!_floatController.isAnimating) {
        _floatController.repeat(reverse: true);
      }
      if (!_alienController.isAnimating) _alienController.repeat();
    }
  }

  Future<void> _initialLoad() async {
    final provider = context.read<ExerciseProvider>();
    await provider.loadMapState();
    if (!mounted) return;
    // Primera carga: se muestra tal cual, sin viaje, con la entrada.
    setState(() => _view = _panelView = _MapView.of(provider));
    if (_reduceMotion) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _spinnerTimer?.cancel();
    _floatController.dispose();
    _alienController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  /// Si el provider cambio y el mapa esta a la vista, programa la copia.
  void _maybeSync(ExerciseProvider provider, bool isCurrent) {
    final view = _view;
    if (view == null || provider.isLoading || !isCurrent) return;
    if (_syncTimer != null || _travel != null || _turning) return;
    if (_MapView.of(provider).sameAs(view)) return;

    _syncTimer = Timer(mapSyncDelay, _applySync);
  }

  void _applySync() {
    _syncTimer = null;
    if (!mounted) return;

    // Si en la espera se tapó el mapa (otra ruta encima), no se copia:
    // se reintenta en el próximo build con el mapa a la vista.
    if (!(ModalRoute.isCurrentOf(context) ?? true)) {
      setState(() {});
      return;
    }

    final provider = context.read<ExerciseProvider>();
    if (provider.isLoading) {
      // Se esta recargando: se reintenta en el proximo build.
      setState(() {});
      return;
    }

    final next = _MapView.of(provider);
    final previous = _view!;
    setState(() {
      if (next.cometIndex > previous.cometIndex) {
        // Se conquisto el cometa: viaje al siguiente. El panel espera.
        _travel = _Travel(previous.cometIndex, next.cometIndex);
      } else if (next.roundIndex > previous.roundIndex) {
        // Se terminó la primera cara: el cometa da la vuelta. El panel
        // espera a que la cara nueva esté a la vista.
        _turning = true;
      } else {
        _panelView = next;
      }
      _view = next;
    });
  }

  void _finishTravel() {
    if (!mounted) return;
    setState(() {
      _travel = null;
      _panelView = _view;
    });
    // Tras el cometa completo, el tablero de 4 cráteres llega con un zoom.
    if (!_reduceMotion) _entranceController.forward(from: 0.25);
  }

  void _finishTurn() {
    if (!mounted) return;
    setState(() {
      _turning = false;
      _panelView = _view;
    });
    // Los marcadores de la cara nueva aparecen con la entrada suave.
    if (!_reduceMotion) _entranceController.forward(from: 0.55);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    // Depender de la ruta hace que se reconstruya al volver a ser visible
    // (al cerrar la sesion, el pop-up o la recompensa).
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    _maybeSync(provider, isCurrent);

    final view = _view;
    final travel = _travel;
    // Mientras viaja o mientras espera copiar el estado nuevo, el mapa
    // muestra datos viejos: no se aceptan toques.
    final busy = travel != null || _turning || _syncTimer != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildStarfield(),
          // Fondo vivo "viaje en movimiento": colores fijos (el tono del
          // cometa solo cambia sus assets) e intensidad según la ruta.
          SpaceBackdrop(intensity: provider.route.nivel - 1),
          AbsorbPointer(
            absorbing: busy,
            child: SafeArea(
              // Abajo sin margen: el cometa llega hasta el borde y su corte
              // recto queda fuera de la pantalla.
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1)
                              .animate(animation),
                          child: child,
                        ),
                      ),
                      child: view == null
                          ? const Center(
                              key: ValueKey('loading'),
                              child: CircularProgressIndicator(),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('map'),
                              child: _buildMap(provider, view),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // El marciano va por encima de todo el tablero (panel, aviso y
          // marcadores) y solo queda debajo del viaje.
          if (view != null && travel == null && !_turning) _buildAlienOverlay(),
          if (_showCraterSpinner)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    key: CraterMapScreen.preparingKey,
                    child: CircularProgressIndicator(
                      color: AppTheme.goldAccent,
                    ),
                  ),
                ),
              ),
            ),
          if (travel != null)
            Positioned.fill(
              child: CometTravel(
                key: ValueKey('travel-${travel.from}-${travel.to}'),
                from: provider.cometTheme(travel.from),
                to: provider.cometTheme(travel.to),
                onFinished: _finishTravel,
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

  /// Barra superior mínima: solo el acceso al perfil. El
  /// título "Mapa de Cráteres" se omite para darle espacio al tablero; el
  /// encabezado con el nombre del niño vive en la elección de ruta.
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          const Spacer(),
          // Minijuegos (Fase 5) está en pausa: su botón vuelve cuando haya
          // juegos; hoy solo llevaba a "Próximamente".
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
      child: BouncyTap(
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              // 13 + 22 + 13 = 48 dp, el mínimo cómodo para tocar.
              padding: const EdgeInsets.all(13),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap(ExerciseProvider provider, _MapView view) {
    final levels = view.levels;
    final panel = _panelView ?? view;
    final panelTheme = provider.cometTheme(panel.cometIndex);
    final route = provider.route;

    // El panel y el aviso bajan desde arriba en la primera aparición.
    final panelIn = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    return Column(
      children: [
        const SizedBox(height: 4),
        FadeTransition(
          opacity: panelIn,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(panelIn),
            child: Column(
              children: [
                ProgressPanel(
                  completed: panel.completed.length,
                  total: provider.totalCraters,
                  stats: panel.stats,
                  cometName: panelTheme.name,
                  cometColor: panelTheme.glow,
                  cometNumber: panel.cometIndex + 1,
                  totalComets: provider.totalComets,
                  routeLabel: route.label,
                  routeIcon: route.icon,
                  routeColor: route.color,
                  onRouteTap: () => Navigator.pushNamed(
                    context,
                    '/route',
                    arguments: const {'changing': true},
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: view.hasNextRound
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _buildHint(view),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
        // El cometa se queda con el espacio que sobre, nunca mas.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const headroom = 96.0;
              const bottomAir = 20.0;

              final available = math.max(
                0.0,
                constraints.maxHeight - headroom - bottomAir,
              );

              var cometWidth = constraints.maxWidth * _maxCometOverflow;
              var cometHeight = cometWidth / _cometAspect;

              // Si no cabe a lo alto, manda el alto y se recalcula el ancho.
              // En pantallas bajas (p. ej. 360x640) el cometa queda mas
              // angosto que la pantalla: es preferible a recortar el
              // crater de abajo, que es el mas grande.
              if (cometHeight > available) {
                cometHeight = available;
                cometWidth = cometHeight * _cometAspect;
              }
              // Nunca más angosto que la pantalla: el sprite es un recorte
              // del cometa y sus bordes rectos no deben verse. Si no cabe a
              // lo alto, el sobrante sale del espacio de arriba.
              if (cometWidth < constraints.maxWidth) {
                cometWidth = constraints.maxWidth;
                cometHeight = cometWidth / _cometAspect;
              }

              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.zero,
                  // Sobresale un poco por abajo: el borde inferior del sprite
                  // (un recorte recto) nunca se ve.
                  child: Transform.translate(
                    offset: const Offset(0, 2),
                    child: _buildComet(
                      view: view,
                      levels: levels,
                      viewportWidth: constraints.maxWidth,
                      width: cometWidth,
                      height: cometHeight,
                      headroom: headroom,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Primer nombre del niño, o "tu hijo/a" si no hay.
  String _childFirstName() {
    final name = context.read<AuthProvider>().currentChild?.nombre.trim();
    if (name == null || name.isEmpty) return 'tu hijo/a';
    return name.split(RegExp(r'\s+')).first;
  }

  /// Aviso cálido para el padre. El mensaje depende del día y del cráter
  /// disponible; tocarlo pasa al siguiente.
  Widget _buildHint(_MapView view) {
    final message = mapHintFor(
      _childFirstName(),
      view.highestUnlocked,
      offset: _hintOffset,
      lastFace: view.isLastFace,
    );

    return GestureDetector(
      onTap: () => setState(() => _hintOffset++),
      child: Container(
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
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: _reduceMotion ? 150 : 450),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, _reduceMotion ? 0 : 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, if (current != null) current],
                ),
                child: Text(
                  message,
                  key: ValueKey(message),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Pista de que tocarlo trae otro consejo.
            Icon(
              Icons.refresh_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.5),
              semanticLabel: 'Otro consejo',
            ),
          ],
        ),
      ),
    );
  }

  /// El cometa con los cráteres de la tanda actual. El sprite cambia
  /// según cuántos de esos cráteres ya se conquistaron y se pinta con el
  /// tema de la vuelta (tono + halo).
  Widget _buildComet({
    required _MapView view,
    required List<int> levels,
    required double viewportWidth,
    required double width,
    required double height,
    required double headroom,
  }) {
    final firstLevel = view.firstLevel;
    final sprite = cometSpriteFor(levels.where(view.isCompleted).length);
    final theme = context.read<ExerciseProvider>().cometTheme(view.cometIndex);

    final totalHeight = height + headroom;

    // Vuelta de cara: en el mismo lugar y tamaño, pasando por el cometa
    // completo para que el giro no muestre el recorte del sprite.
    if (_turning) {
      return SizedBox(
        width: viewportWidth,
        height: totalHeight,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.bottomCenter,
            minWidth: width,
            maxWidth: width,
            minHeight: totalHeight,
            maxHeight: totalHeight,
            child: CometTurn(
              key: ValueKey('turn-${view.roundIndex}'),
              theme: theme,
              fromSprite: cometSpriteFor(cratersPerSprite),
              toSprite: sprite,
              width: width,
              height: height,
              headroom: headroom,
              onFinished: _finishTurn,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: viewportWidth,
      height: totalHeight,
      child: ClipRect(
        child: OverflowBox(
          // Si llegara a sobrar alto, el recorte sale del espacio de arriba
          // y no del sprite.
          alignment: Alignment.bottomCenter,
          minWidth: width,
          maxWidth: width,
          minHeight: totalHeight,
          maxHeight: totalHeight,
          // Primera aparición: el cometa llega con un fundido y un zoom.
          child: _buildEntrance(
            // El cometa entero (sprite + marcadores) flota y se mece apenas,
            // asi los marcadores nunca se despegan de sus crateres. Solo se
            // mueven transformaciones sobre un hijo que no se reconstruye.
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatController, _alienController]),
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_floatController.value);
                final shake = _shakeOffset(_alienController.value);
                return Transform.translate(
                  offset: Offset(shake, -3 + t * 6),
                  child: Transform.rotate(
                    angle: (t - 0.5) * 0.012 + shake * 0.002,
                    child: child,
                  ),
                );
              },
              child: RepaintBoundary(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: headroom,
                      width: width,
                      height: height,
                      // El halo respira con opacidad; el sprite filtrado no se
                      // vuelve a construir (ver ThemedCometSprite).
                      child: ThemedCometSprite(
                        sprite: sprite,
                        theme: theme,
                        glowStrength: 0,
                      ),
                    ),
                    for (final level in levels)
                      _buildMarker(
                        view: view,
                        level: level,
                        spot: CraterSpot.all[level - firstLevel],
                        width: width,
                        height: height,
                        headroom: headroom,
                      ),
                    if (levels.contains(view.highestUnlocked))
                      _buildAlien(
                        spot: CraterSpot.all[view.highestUnlocked - firstLevel],
                        viewportWidth: viewportWidth,
                        width: width,
                        height: height,
                        headroom: headroom,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Desplazamiento horizontal del balanceo del cometa (ver [cometSway]).
  double _shakeOffset(double t) {
    if (_reduceMotion) return 0;
    return cometSway(t, context.read<ExerciseProvider>().route.nivel);
  }

  /// Fundido + zoom del cometa en la primera aparición del tablero.
  Widget _buildEntrance({required Widget child}) {
    final cometIn = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.85, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        // Llega "desde cerca" (más grande) y nunca más chico que la
        // pantalla: así no se ven los bordes rectos del sprite.
        scale: Tween<double>(begin: 1.12, end: 1).animate(cometIn),
        child: child,
      ),
    );
  }

  /// Tamaño del marciano en el tablero.
  static const double _alienSize = 72.0;

  /// Ancla del marciano dentro del cometa: acompaña al cráter actual y se
  /// desplaza al siguiente al conquistarlo. No dibuja nada; el marciano se
  /// pinta en la capa superior ([_buildAlienOverlay]) siguiendo esta ancla,
  /// así hereda el vaivén y el zoom del cometa sin quedar recortado ni
  /// debajo del panel.
  Widget _buildAlien({
    required CraterSpot spot,
    required double viewportWidth,
    required double width,
    required double height,
    required double headroom,
  }) {
    const size = _alienSize;

    // El cometa es mas ancho que la pantalla y va centrado, asi que los
    // limites utiles son los de la franja visible, no los del cometa.
    final offset = (width - viewportWidth) / 2;
    final minLeft = offset + 4;
    final maxLeft = offset + viewportWidth - size - 4;

    // Se para al costado del crater, un poco mas arriba.
    var left = spot.cx * width + spot.rx * width * 0.9;
    if (left > maxLeft) {
      left = spot.cx * width - spot.rx * width * 0.9 - size;
    }
    left = left.clamp(minLeft, maxLeft);

    final top = (headroom + spot.cy * height - size * 1.15)
        .clamp(10.0, headroom + height - size);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutBack,
      left: left,
      top: top,
      width: size,
      height: size,
      child: CompositedTransformTarget(
        link: _alienLink,
        child: const SizedBox.expand(),
      ),
    );
  }

  /// El marciano dibujado sobre todo el tablero, pegado a su ancla en el
  /// cometa. No recibe toques: los cráteres de abajo siguen respondiendo.
  Widget _buildAlienOverlay() {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    return Positioned(
      left: 0,
      top: 0,
      width: _alienSize,
      height: _alienSize,
      child: IgnorePointer(
        child: CompositedTransformFollower(
          link: _alienLink,
          showWhenUnlinked: false,
          child: FadeTransition(
            opacity: fade,
            child: AnimatedBuilder(
              animation: _alienController,
              builder: (context, child) {
                final m = alienMotion(_alienController.value);
                return Transform.translate(
                  offset: m.offset,
                  child: Transform.rotate(
                    angle: m.angle,
                    child: Transform.scale(scale: m.scale, child: child),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/mascota/alien.png',
                key: const ValueKey('map-alien'),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarker({
    required _MapView view,
    required int level,
    required CraterSpot spot,
    required double width,
    required double height,
    required double headroom,
  }) {
    final status = view.isCompleted(level)
        ? CraterStatus.completed
        : view.isUnlocked(level)
            ? CraterStatus.available
            : CraterStatus.locked;

    final w = spot.rx * 2 * width;
    final h = spot.ry * 2 * height;

    return Positioned(
      // La key es la posicion en el sprite: al renumerar la tanda, el
      // marcador sigue siendo el mismo y no "celebra" por error.
      key: ValueKey('crater-spot-${level - view.firstLevel}'),
      left: spot.cx * width - w / 2,
      top: headroom + spot.cy * height - h / 2,
      width: w,
      height: h,
      child: CraterMarker(
        level: level,
        status: status,
        dificultad: Dificultad.forLevel(level),
        exerciseCount: Dificultad.forLevel(level).exerciseCount +
            context.read<ExerciseProvider>().route.extraExercises,
        craterSize: Size(w, h),
        onTap: () => _openCrater(level),
        onLockedTap: () => _explainLocked(view),
      ),
    );
  }

  /// Aviso breve al tocar un cráter bloqueado: cuál va primero.
  void _explainLocked(_MapView view) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(lockedCraterMessage(view.highestUnlocked)),
        ),
      );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _setPreparing(bool preparing) {
    _spinnerTimer?.cancel();
    _spinnerTimer = null;
    if (preparing) {
      _spinnerTimer = Timer(_spinnerDelay, () {
        if (mounted) setState(() => _showCraterSpinner = true);
      });
    } else if (_showCraterSpinner && mounted) {
      setState(() => _showCraterSpinner = false);
    }
  }

  // ------------------------------------------------------------

  Future<void> _openCrater(int level) async {
    if (_openingCrater || _travel != null || _turning || _syncTimer != null) {
      return;
    }
    _openingCrater = true;

    final provider = context.read<ExerciseProvider>();
    final childId =
        context.read<AuthProvider>().currentChild?.id ?? 'mock-child';

    try {
      _setPreparing(true);
      try {
        await provider.buildRoutine(childId: childId, level: level);
      } catch (_) {
        if (mounted) _showError(craterPrepareError);
        return;
      } finally {
        _setPreparing(false);
      }
      if (!mounted) return;

      var reshuffling = false;

      // El pop-up hace su propia entrada con rebote (ver CraterPreviewDialog).
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
                      try {
                        await p.buildRoutine(childId: childId, level: level);
                      } catch (_) {
                        // Se queda la rutina que ya estaba a la vista.
                        if (mounted) _showError(craterReshuffleError);
                      } finally {
                        // Nunca queda pegado el botón "Sortear".
                        if (dialogContext.mounted) {
                          setDialogState(() => reshuffling = false);
                        }
                      }
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
        // Si la sesion termino el cometa, aqui puede estar encima la
        // recompensa: el mapa solo anima cuando vuelve a estar a la vista.
        await provider.loadMapState();
      } else {
        await provider.discardPreview();
      }
    } finally {
      _openingCrater = false;
    }
  }
}

/// Ventana del ciclo del marciano (16 s) en que el cometa se balancea:
/// ~1,6 s, lejos del acercamiento, la vuelta y el salto del marciano.
const cometSwayWindow = (start: 0.66, end: 0.76);

/// Balanceo horizontal del cometa en las rutas exigentes (t = ciclo del
/// marciano, de 0 a 1). Es lento y suave a propósito: 3 vaivenes (~2 por
/// segundo) una vez cada 16 s, nunca un temblor rápido, pensando en niños
/// con sensibilidad sensorial. Explorador no se mueve; Astronauta apenas
/// (2 px) y Comandante algo más (4 px).
double cometSway(double t, int routeLevel) {
  if (routeLevel <= 1) return 0;
  final (:start, :end) = cometSwayWindow;
  if (t < start || t > end) return 0;
  final k = (t - start) / (end - start);
  final envelope = math.sin(k * math.pi);
  final amp = routeLevel >= 3 ? 4.0 : 2.0;
  return math.sin(k * math.pi * 2 * 3) * amp * envelope;
}

/// Pose del marciano en un instante de su ciclo de flotación.
typedef AlienPose = ({Offset offset, double angle, double scale});

/// Ciclo del marciano (t de 0 a 1, ~16 s). Mezcla varias animaciones para
/// que no se vea siempre igual:
/// - flota suave (la mayor parte del tiempo),
/// - se acerca a la pantalla (crece) y vuelve,
/// - da una vuelta completa en el aire,
/// - pega un salto.
AlienPose alienMotion(double t) {
  double win(double a, double b) =>
      t < a || t > b ? 0 : math.sin((t - a) / (b - a) * math.pi);
  final bob = math.sin(t * math.pi * 2 * 5) * 6;
  final sway = math.sin(t * math.pi * 2 * 3) * 0.06;

  final closer = win(0.22, 0.38); // se acerca
  final spin = t >= 0.52 && t <= 0.62 ? (t - 0.52) / 0.1 : 0.0;
  final hop = win(0.78, 0.86);

  return (
    // Al acercarse sube y crece: pasa por encima del panel, como si
    // flotara hacia quien mira.
    offset: Offset(-22 * closer, bob - 40 * hop - 34 * closer),
    angle: sway + spin * math.pi * 2,
    scale: 1 + 0.9 * closer,
  );
}

/// Aviso al tocar un cráter bloqueado.
String lockedCraterMessage(int next) =>
    'Este cráter aún está cerrado. Primero conquisten el cráter $next.';

/// Errores al abrir o volver a sortear un cráter.
const craterPrepareError =
    'No pudimos preparar el cráter. Intenten de nuevo en un momento.';
const craterReshuffleError =
    'No pudimos sortear otros ejercicios. Siguen los de antes.';
