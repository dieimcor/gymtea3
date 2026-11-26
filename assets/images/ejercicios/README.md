# Recursos de ejercicios

Esta carpeta está vacía a propósito: las gráficas, GIFs y videos de los
ejercicios **se están diseñando**. Mientras tanto, cada ejercicio muestra
solo un **espacio reservado** (`ExerciseMediaSlot`, proporción 4:3) con
el nombre del ejercicio.

## Cómo poner un recurso cuando esté listo

1. Deja el archivo aquí, idealmente con el **id del ejercicio** como
   nombre: `rd-1.gif`, `rd-1.png`, `rd-1.mp4`…
2. En `lib/data/repositories/exercise_repository.dart`, agrega `media:`
   a ese ejercicio:

```dart
ExerciseModel(
  id: 'rd-1',
  // ...
  media: ExerciseMedia.gif('assets/images/ejercicios/rd-1.gif'),
),
```

Variantes: `ExerciseMedia.imagen(...)`, `ExerciseMedia.gif(...)`,
`ExerciseMedia.video(...)`, o una URL `https://...` en vez de un asset.

El recurso aparece en el mismo espacio de la sesión y del pop-up del
cráter, sin tocar pantallas ni `pubspec.yaml` (esta carpeta ya está
declarada como assets). Un formato 4:3 llena el espacio sin recortes.

> **Video:** hoy el espacio queda reservado con un ícono de reproducción.
> Para reproducirlo hay que sumar un reproductor (p. ej. `video_player`)
> en `exercise_media_slot.dart`.

Los ids están en `lib/data/repositories/exercise_repository.dart`. Hay un
test (`routine_test.dart`) que falla si algún ejercicio ya trae `media`:
cuando asignes el primero, actualiza ese test.
