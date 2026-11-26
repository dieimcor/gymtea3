# NeuroGym (gymtea3)

App Flutter de apoyo motor para niños neurodivergentes (TEA, TDAH, TEL;
hasta 13 años). El padre ejecuta con su hijo rutinas de fuerza basadas en el
*Manual de Fuerza y Juegos* (USAC, 2022), organizadas como un mapa de
cráteres que se van conquistando.

## Estado

- **Hecho:** login con RUT (mock), mapa de cráteres de 8 niveles, rutinas
  sorteadas sin repetición (3/4/5 ejercicios × 2 series × 60 s), pop-up de
  nivel, 3 rutas de entrenamiento elegibles (series de 30/45/60 s, equipo con reemplazos de casa, planetas propios), sesión con prep de 5 s y controles anterior · pausa · siguiente,
  "¿Cómo le fue?" por ejercicio (1 a 3 estrellas), recompensa al conquistar
  cada cometa con viaje animado al siguiente (cada vuelta con su propio
  tono de cometa), panel de progreso animado y transiciones suaves. Todo
  local, sin backend. 120 tests en verde (Fase 4.2, 2026-11-26).
- **En pausa (decisión del usuario):** minijuegos (Fase 5) y offline con
  SQLite + polish (Fase 6).
- **Pendiente:** backend (Node + PostgreSQL) y dashboard del psicopedagogo.

## Documentación

| Archivo | Para qué |
|---|---|
| [`CONTEXT.md`](CONTEXT.md) | Especificación completa: roles, flujo, arquitectura, reglas de ejercicios, API planificada |
| [`PROGRESS.md`](PROGRESS.md) | Avance por fases del MVP |
| [`HANDOFF.md`](HANDOFF.md) | Cómo retomar: estado del código, pendientes y cómo probar en el emulador |

## Correr la app

```bash
flutter pub get
flutter run
flutter test
```

Login demo: RUT `11.111.111-1`, contraseña `1234`.

En el emulador conviene compilar solo su arquitectura (el APK completo pesa
167 MB):

```bash
flutter build apk --debug --split-per-abi
adb install -r build/app/outputs/flutter-apk/app-x86_64-debug.apk
```

## Notas

- `recursos/` (material fuente, 271 MB) y `docs/` no están versionados.
- Cada ejercicio muestra un **espacio reservado** para su gráfica, GIF o
  video (se están diseñando). Cuando estén listos se asignan con `media:`
  en `exercise_repository.dart`; ver `assets/images/ejercicios/README.md`.
