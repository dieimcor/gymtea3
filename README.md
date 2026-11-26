# NeuroGym (gymtea3)

App Flutter de apoyo motor para niños neurodivergentes (TEA, TDAH, TEL;
hasta 13 años). El padre ejecuta con su hijo rutinas de fuerza basadas en el
*Manual de Fuerza y Juegos* (USAC, 2022), organizadas como un mapa de
cráteres que se van conquistando.

## Estado

- **Hecho:** login con RUT (mock), mapa de cráteres de 8 niveles, rutinas
  sorteadas sin repetición (3/4/5 ejercicios × 2 series × 60 s), pop-up de
  nivel, "Califica tu progreso" y panel de progreso. Todo local, sin backend.
- **Pendiente:** minijuegos, offline con SQLite, backend (Node + PostgreSQL)
  y dashboard del psicopedagogo.

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
- Las ilustraciones de ejercicios van en `assets/images/ejercicios/<id>.png`;
  si falta el archivo se muestra un placeholder con el nombre.
