import 'package:flutter_test/flutter_test.dart';

import 'package:gymtea3/data/models/progress_model.dart';

void main() {
  ProgressModel sample({Map<String, int> calificaciones = const {}}) =>
      ProgressModel(
        id: 'p1',
        childId: 'c1',
        sessionId: 's1',
        nivelCompletado: 3,
        ejerciciosCompletadosIds: const ['ex1', 'ex2'],
        tiempoRealSeg: 420,
        fecha: DateTime(2026, 11, 25, 10, 30),
        calificaciones: calificaciones,
      );

  group('ProgressModel ida y vuelta', () {
    test('fromJson(toJson()) conserva las calificaciones', () {
      final original = sample(calificaciones: const {'ex1': 3, 'ex2': 1});
      final copia = ProgressModel.fromJson(original.toJson());

      expect(copia.calificaciones, {'ex1': 3, 'ex2': 1});
      expect(copia.ejerciciosCompletadosIds, ['ex1', 'ex2']);
      expect(copia.promedioCalificacion, 2);
    });

    test('una calificación como texto o inválida no tumba el registro', () {
      final json = sample().toJson()
        ..['calificaciones'] = {'ex1': '3', 'ex2': 'x', 'ex3': 2};
      expect(ProgressModel.fromJson(json).calificaciones, {'ex1': 3, 'ex3': 2});
    });

    test('fromJson(toMap()) del cache SQLite conserva las calificaciones', () {
      final original = sample(calificaciones: const {'ex1': 3, 'ex2': 2});
      final copia = ProgressModel.fromJson(original.toMap());

      expect(copia.calificaciones, {'ex1': 3, 'ex2': 2});
      expect(copia.ejerciciosCompletadosIds, ['ex1', 'ex2']);
      expect(copia.nivelCompletado, 3);
      expect(copia.fecha, original.fecha);
    });

    test('sin calificaciones vuelve como mapa vacío en ambos formatos', () {
      final original = sample();
      expect(ProgressModel.fromJson(original.toJson()).calificaciones, isEmpty);
      expect(ProgressModel.fromJson(original.toMap()).calificaciones, isEmpty);
      expect(
          ProgressModel.fromJson(original.toMap()).tieneCalificacion, isFalse);
    });

    test('sincronizado guardado como 0/1 se lee como bool', () {
      final map = sample().toMap()..['sincronizado'] = 1;
      expect(ProgressModel.fromJson(map).sincronizado, isTrue);
    });
  });
}
