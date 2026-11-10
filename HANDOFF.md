# Handoff — Mapa de Cráteres

> **Fecha:** 2026-11-09 · **Rama:** `main` · **Último commit:** `4048a52`
> **Estado:** rediseño terminado, verificado en emulador. Nada a medias.

Este documento es para retomar el trabajo. La especificación completa
está en `CONTEXT.md` (sección 5) y el historial por fases en `PROGRESS.md`.

---

## 1. Qué se hizo

Se aplicaron los cambios de `recursos/actualizacion24oct.txt`, y después
cuatro rondas de ajuste sobre el resultado visto en el emulador.

| Requerimiento original | Dónde quedó |
|---|---|
| Menú de cráteres | `crater_map_screen.dart` — reemplaza al Home con bottom nav |
| Sacar settings de tiempos | Eliminado; valores fijos en `AppConstants` y `Dificultad` |
| Imagen por ejercicio | `exercise_image.dart` + campo `imagenAsset`, con placeholder |
| 30 s → 1 minuto | `AppConstants.exerciseSeconds = 60` |
| Descanso 20 s, incremental | 20 / 25 / 30 s según dificultad |
| Randomizar sin repetir | `level_progress_service.dart` persiste los ids usados |
| Pop-up tipo Mario Party | `crater_preview_dialog.dart` |
| 3/4/5 ejercicios × 2 series | `Dificultad.forLevel()` |
| Califica tu progreso | `rating_screen.dart` — 3 ejes × 5 estrellas |

**Fuera de alcance por decisión del usuario:** "Matar al alien" (el alien
quedó solo como mascota) y todo el perfilamiento/evaluación previa del
niño (el código sigue en el repo, sin uso en la UI).

---

## 2. Cómo funciona el mapa

El sprite del cometa **es** el menú. Los cráteres pintados en la
ilustración son los niveles; encima solo va un marcador con el número, el
candado o el visto.

- **4 cráteres por tanda**, en el orden que definió el usuario:
  **1 cima · 2 arriba-izquierda · 3 arriba-derecha · 4 abajo-izquierda.**
  Las posiciones están medidas sobre el arte en `CraterSpot.all`.
- **Un solo cometa.** Al conquistar los 4, los mismos cráteres se
  renumeran con los siguientes niveles. No hay scroll ni segunda página.
- **El sprite cambia con el avance:** `cometSpriteFor(n)` mapea 0→`crater_1`
  … 4→`crater_5`. Así el cráter conquistado se pone turquesa con el arte
  original.
- **8 niveles en total**, múltiplo de 4 para que las tandas calcen. Hay un
  test que falla si eso deja de cumplirse.
- El marcador de la cima flota sobre el cometa (`cy` negativa) y el
  marciano acompaña al cráter disponible con un vaivén.

### Cómo se descubrió el orden
Los sprites son **estados de progreso del mismo cometa**, no imágenes por
nivel. Se determinó comparando los PNG entre sí: la laguna de la cima pasa
de turquesa apagada en `crater 1.png` a encendida en `crater 2.png`, y
`crater 4_1.png` tiene las cuatro bocas turquesa. Si se agregan sprites,
conviene repetir esa comparación antes de asumir qué significa cada uno.

---

## 3. Estado del código

```
flutter analyze   → 4 info, 0 errores (las 4 son preexistentes)
flutter test      → 25 casos, todos en verde
```

Archivos nuevos o reescritos en esta tanda:

```
lib/data/models/difficulty.dart            Dificultad: ejercicios, series, descanso
lib/data/models/routine_model.dart         Rutina plana (reemplaza SessionModel)
lib/data/services/level_progress_service.dart  Desbloqueo, anti-repetición, acumulados
lib/presentation/screens/home/crater_map_screen.dart
lib/presentation/screens/exercises/rating_screen.dart
lib/presentation/widgets/crater_node.dart      CraterSpot + CraterMarker
lib/presentation/widgets/crater_preview_dialog.dart
lib/presentation/widgets/exercise_image.dart
lib/presentation/widgets/progress_panel.dart
test/routine_test.dart, test/crater_map_test.dart
```

Eliminados: `session_model.dart`, `home_screen.dart`, `level_map_screen.dart`,
`phase_indicator.dart`, `level_node.dart`, `exercise_card.dart` y el enum
`FaseSesion` (se fue la sesión de 3 fases).

---

## 4. Pendientes y decisiones abiertas

1. **El pool difícil queda justo.** Con 8 niveles, difícil son 3 niveles ×
   5 ejercicios = 15, y el pool tiene 16. Si se agregan niveles difíciles
   hay que sumar ejercicios. El test `cada pool alcanza para todos sus
   cráteres sin repetir` avisa si no alcanza.
2. **Imágenes de ejercicios: todas son placeholder.** Por decisión del
   usuario, las ilustraciones definitivas entran en una versión
   posterior. Para agregar una, basta dejar el archivo en
   `assets/images/ejercicios/<id>.png` — sin tocar código ni pubspec.
   Ver el README de esa carpeta. Hay un test que falla si algún ejercicio
   apunta a una ruta propia en vez de la convención por id.
3. **El panel cuenta ejercicios, no series ni repeticiones.** Si se
   prefiere otra métrica, se cambia qué acumula `addSession`.
4. **`ProgressRepository` sigue siendo en memoria.** Las calificaciones
   (desempeño/cansancio/motivación) se guardan ahí y se pierden al
   reiniciar. Los acumulados del panel sí se persisten, por separado, en
   `LevelProgressService`. Unificar esto cuando entre SQLite.
5. **Perfilamiento en pausa.** `evaluation_model.dart` y los campos de
   `ChildModel` quedaron sin uso, para retomarlos con el dashboard.

---

## 5. Cómo probarlo en el emulador

Hay un par de cosas que cuestan tiempo si no se saben:

- **El APK debug pesa 167 MB** (3 arquitecturas) y el emulador se queda sin
  espacio al instalarlo. Compilar solo la del emulador:
  ```
  flutter build apk --debug --split-per-abi
  adb install -r build/app/outputs/flutter-apk/app-x86_64-debug.apk
  ```
- **El emulador Pixel_9a es inestable** y se cae solo (ANR del SystemUI).
  Conviene esperar `sys.boot_completed` antes de instalar.
- **Login demo:** RUT `11.111.111-1`, contraseña `1234`.
  Ojo: `KEYCODE_BACK` en el login cierra la app, no baja el teclado.
- **Para saltar al estado que se quiera** sin encadenar taps, se escriben
  las preferencias directamente (la app es debuggable):
  ```
  adb shell am force-stop com.example.gymtea3
  adb shell run-as com.example.gymtea3 cat shared_prefs/FlutterSharedPreferences.xml
  ```
  Las listas usan el prefijo `VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!`
  seguido del JSON. Ejemplo para dejar 2 cráteres conquistados:
  ```xml
  <string name="flutter.completed_levels">VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!["1","2"]</string>
  <int name="flutter.total_exercises" value="6" />
  ```

---

## 6. Assets

`recursos/` (271 MB de material fuente) está en `.gitignore`. Lo que la
app usa ya está copiado y redimensionado en `assets/images/`:

```
craters/     crater_1..5.png (estados del cometa) + fondo_estrellas.png
mascota/     alien.png, alien_calificacion.png
ejercicios/  vacía (solo README) — todos los ejercicios van con placeholder
```

`fondo_estrellas.png` es un recorte del cielo de `Ilustracion_Base1.png`;
la ilustración original completa trae planeta y alien, así que **no sirve
como fondo** — ese fue el primer error de esta tanda.
