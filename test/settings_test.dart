import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtea3/presentation/providers/settings_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('"Animaciones suaves" viene apagado y se guarda', () async {
    final settings = SettingsProvider();
    await settings.load();
    expect(settings.calmMode, isFalse);

    await settings.setCalmMode(true);
    final otra = SettingsProvider();
    await otra.load();
    expect(otra.calmMode, isTrue);
  });

  testWidgets('encendido, la app ve "reducir movimiento"', (tester) async {
    bool? seen;
    Widget app(bool calm) => MaterialApp(
          builder: (context, child) =>
              SettingsProvider.apply(calm: calm, child: child!),
          home: Builder(builder: (context) {
            seen = MediaQuery.of(context).disableAnimations;
            return const SizedBox();
          }),
        );

    await tester.pumpWidget(app(false));
    expect(seen, isFalse);
    await tester.pumpWidget(app(true));
    expect(seen, isTrue);
  });
}
