import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymtea3/presentation/widgets/progress_panel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/data/models/training_route.dart';
import 'package:gymtea3/data/repositories/auth_repository.dart';
import 'package:gymtea3/data/repositories/exercise_repository.dart';
import 'package:gymtea3/data/services/auth_service.dart';
import 'package:gymtea3/data/services/level_progress_service.dart';
import 'package:gymtea3/data/services/storage_service.dart';
import 'package:gymtea3/presentation/animations/comet_travel.dart';
import 'package:gymtea3/presentation/providers/auth_provider.dart';
import 'package:gymtea3/presentation/providers/exercise_provider.dart';
import 'package:gymtea3/presentation/screens/home/crater_map_screen.dart';
import 'package:gymtea3/presentation/screens/route/launch_screen.dart';
import 'package:gymtea3/presentation/screens/route/route_selection_screen.dart';
import 'package:gymtea3/presentation/widgets/crater_node.dart';

/// Botón "¡Despegar!" (ElevatedButton.icon es una subclase).
Finder _launchButton() => find.ancestor(
      of: find.text('¡Despegar!'),
      matching: find.byWidgetPredicate((w) => w is ElevatedButton),
    );

/// Fuerza "reducir movimiento" en toda la app de prueba.
Widget _reduceMotion(BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExerciseProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = ExerciseProvider(
      exerciseRepository: ExerciseRepository(),
      levelProgressService: LevelProgressService(),
    );
  });

  /// App mínima: selección de ruta, despegue y un "mapa" de mentira.
  Widget flowApp({
    Widget home = const RouteSelectionScreen(),
    bool reduced = false,
  }) {
    return ChangeNotifierProvider<ExerciseProvider>.value(
      value: provider,
      child: MaterialApp(
        builder: reduced ? _reduceMotion : null,
        home: home,
        routes: {
          LaunchScreen.routeName: (_) => const LaunchScreen(),
          '/home': (_) => const Scaffold(body: Text('MAPA')),
        },
      ),
    );
  }

  group('Selección de ruta', () {
    testWidgets('muestra las 3 rutas con sus datos y el globo del marciano',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(flowApp());
      await tester.pump(const Duration(milliseconds: 1500));

      for (final route in TrainingRoute.values) {
        expect(find.text(route.label), findsOneWidget);
        expect(find.text(route.tagline), findsOneWidget);
        expect(find.text(route.equipoTexto), findsOneWidget);
        for (final comet in route.comets) {
          expect(find.text(comet.name), findsOneWidget);
        }
      }
      expect(find.text('Series de 30 s · 3 a 5 ejercicios'), findsOneWidget);
      expect(find.text('Series de 45 s · 3 a 5 ejercicios'), findsOneWidget);
      expect(find.text('Series de 60 s · 4 a 6 ejercicios'), findsOneWidget);
      // Sin AuthProvider usa el genérico.
      expect(
          find.text('¿Qué tan lejos viajamos con tu hijo/a?'), findsOneWidget);
      // Sin "cambiar ruta" no hay volver ni la nota.
      expect(find.byTooltip('Volver'), findsNothing);
      expect(find.textContaining('El avance de cada ruta'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('¡Despegar! queda deshabilitado hasta elegir una ruta',
        (tester) async {
      await tester.pumpWidget(flowApp());
      await tester.pump(const Duration(milliseconds: 1500));

      final button = _launchButton();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      await tester.tap(find.text('Explorador'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    });

    testWidgets('elegir y despegar guarda la ruta y abre el despegue',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(flowApp());
      await tester.pump(const Duration(milliseconds: 1500));

      await tester.tap(find.text('Astronauta'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('¡Despegar!'));
      // selectRoute usa SharedPreferences: se deja correr con tiempo real.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(provider.route, TrainingRoute.astronauta);
      expect(provider.hasSelectedRoute, isTrue);
      final saved = await tester
          .runAsync(() => LevelProgressService().getSelectedRoute());
      expect(saved, TrainingRoute.astronauta);

      expect(find.byType(LaunchScreen), findsOneWidget);
      expect(find.byType(RouteSelectionScreen), findsNothing);

      // Deja terminar el despegue para no dejar animaciones pendientes.
      await tester.pump(LaunchScreen.duration);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('MAPA'), findsOneWidget);
    });

    testWidgets('al cambiar ruta parte marcada la actual, con nota y volver',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester
          .runAsync(() => provider.selectRoute(TrainingRoute.comandante));

      await tester.pumpWidget(
          flowApp(home: const RouteSelectionScreen(changing: true)));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.byTooltip('Volver'), findsOneWidget);
      expect(find.textContaining('El avance de cada ruta se guarda'),
          findsOneWidget);
      final button = _launchButton();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
      final selected = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.selected == true)
          .map((s) => s.properties.label)
          .toList();
      expect(selected, ['Ruta Comandante']);
    });

    testWidgets('lee {changing: true} de los argumentos de la ruta',
        (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<ExerciseProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(arguments: {'changing': true}),
                  builder: (_) => const RouteSelectionScreen(),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.byTooltip('Volver'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(RouteSelectionScreen), findsNothing);
    });

    testWidgets('con reducir movimiento aparece todo de inmediato',
        (tester) async {
      await tester.pumpWidget(flowApp(reduced: true));
      await tester.pump();

      // Entrada escalonada de la última tarjeta y del globo: ya completa.
      final opacities = tester
          .widgetList<FadeTransition>(find.ancestor(
            of: find.text('Comandante').first,
            matching: find.byType(FadeTransition),
          ))
          .map((f) => f.opacity.value)
          .toList();
      expect(opacities, everyElement(1.0));
    });
  });

  group('Despegue', () {
    Future<void> loaded() => provider.selectRoute(TrainingRoute.explorador);

    testWidgets('cuenta 3·2·1, muestra el planeta de la ruta y va al mapa',
        (tester) async {
      await tester.runAsync(loaded);
      await tester.pumpWidget(flowApp(home: const LaunchScreen()));

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('countdown-3')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('countdown-2')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('countdown-1')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));
      final comet = provider.cometTheme(provider.cometIndex);
      expect(find.text(CometTravel.messageFor(comet)), findsOneWidget);
      expect(find.text('Ruta Explorador'), findsOneWidget);
      expect(find.text('MAPA'), findsNothing);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('MAPA'), findsOneWidget);
      expect(find.byType(LaunchScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar la pantalla salta el despegue', (tester) async {
      await tester.runAsync(loaded);
      await tester.pumpWidget(flowApp(home: const LaunchScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(LaunchScreen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('MAPA'), findsOneWidget);
      expect(find.byType(LaunchScreen), findsNothing);
    });

    testWidgets('con reducir movimiento es un fundido corto sin cuenta',
        (tester) async {
      await tester
          .runAsync(() => provider.selectRoute(TrainingRoute.astronauta));
      await tester
          .pumpWidget(flowApp(home: const LaunchScreen(), reduced: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('countdown-3')), findsNothing);
      expect(find.text('¡Rumbo al Cometa Lavanda!'), findsOneWidget);

      await tester.pump(LaunchScreen.reducedDuration);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('MAPA'), findsOneWidget);
    });
  });

  group('Mapa con la ruta', () {
    Widget mapApp({bool reduced = false}) => MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                authRepository: AuthRepository(
                  authService: AuthService(),
                  storageService: StorageService(),
                ),
              ),
            ),
            ChangeNotifierProvider<ExerciseProvider>.value(value: provider),
          ],
          child: MaterialApp(
            builder: reduced ? _reduceMotion : null,
            home: const CraterMapScreen(),
          ),
        );

    Future<void> mount(WidgetTester tester, {bool reduced = false}) async {
      await tester.pumpWidget(mapApp(reduced: reduced));
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
    }

    testWidgets('pinta los planetas y el chip de la ruta elegida',
        (tester) async {
      await tester
          .runAsync(() => provider.selectRoute(TrainingRoute.comandante));
      await mount(tester);

      expect(find.textContaining('Cometa Océano'), findsOneWidget);
      // La ruta ya no va en un chip: el borde del panel lleva su color.
      final panel = tester.widget<ProgressPanel>(find.byType(ProgressPanel));
      expect(panel.routeColor, TrainingRoute.comandante.color);
      // Comandante suma un ejercicio por cráter: el fácil muestra 4.
      expect(find.text('Fácil · 4'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con reducir movimiento el mapa queda quieto', (tester) async {
      await tester
          .runAsync(() => provider.selectRoute(TrainingRoute.explorador));
      await mount(tester, reduced: true);

      // Sin vaivén ni latidos no quedan frames pendientes.
      await tester.pumpAndSettle();
      expect(find.byType(CraterMarker), findsNWidgets(4));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('Avisos del mapa', () {
    test('usan el nombre del niño y el cráter, y no cambian en el día', () {
      final day = DateTime(2026, 11, 26);
      final a = mapHintFor('Tomás', 3, today: day);
      final b = mapHintFor('Tomás', 3, today: day);
      expect(a, b);
      expect(mapHintMessages('Tomás', 3).contains(a), isTrue);

      final all = mapHintMessages('Tomás', 3);
      expect(all.any((m) => m.contains('Tomás')), isTrue);
      expect(all.any((m) => m.contains('cráter 3')), isTrue);
      expect(all.any((m) => m.contains('viajarán juntos')), isTrue);

      // Otro día u otro toque muestran otro mensaje.
      expect(mapHintFor('Tomás', 3, today: day, offset: 1), isNot(a));
      expect(mapHintFor('Tomás', 3, today: day.add(const Duration(days: 1))),
          isNot(a));
    });
  });
}
