# Handoff — Mapa de Cráteres

> **Fecha:** 2026-11-26 · **Rama:** `main` · **Último commit:** `c845522` (las tandas
> de 2026-11-25 y 2026-11-26 están en el árbol de trabajo, **sin commit**)
> **Estado:** Fase 4.1 (animaciones, recompensa, viaje) y Fase 4.2 (rutas de
> entrenamiento) terminadas y verificadas con tests y en emulador. Fases 5 y 6 en pausa.

Este documento es para retomar el trabajo. La especificación completa
está en `CONTEXT.md` (sección 5) y el historial por fases en `PROGRESS.md`.

---

## ⏩ RETOMAR AQUÍ (2026-11-26, sesión cortada por contexto)

**Estado del árbol:** todo en `main` y subido a `origin` (commit
`6e83a99` y siguientes). `flutter analyze`
limpio (4 info preexistentes). `flutter test`: 124/125 — falla 1 test que
quedó a medio ajustar (ver punto 1).

**Lo último que se hizo (sin verificar en emulador):**
- Panel de progreso sin cuadro grande: una línea con chip del cometa +
  contador "7 / 16" y las **3 cajitas de vidrio** compactas (ícono a la
  izquierda) con **borde del color de la ruta** (`glass_stat_box.dart`,
  param `borderColor`; `progress_panel.dart` ya no tiene barra ni "% del
  viaje").
- Se quitó el título "Mapa de Cráteres / Entrenamiento de…" de la barra
  superior del mapa (`_buildTopBar` deja solo minijuegos y perfil).
- **Cometa cortado en los bordes**: corregido en `_buildMap` —el ancho del
  sprite nunca baja del ancho de pantalla (si no cabe a lo alto, sobra el
  espacio de arriba). Revisar en emulador y el test de 360×640.

**Hecho después del corte (verificado en emulador, cráter 12, Cometa Menta):**
- Test del panel arreglado (era timing de la cascada).
- **Un solo marciano**: se quitó el que cruzaba aparte; el del cometa
  sigue al cráter actual y tiene un ciclo de 16 s (`alienMotion` en
  `crater_map_screen.dart`): flota, se acerca a la pantalla, da una vuelta
  y salta.
- **Fondo fijo "viaje en movimiento"** (`space_backdrop.dart`,
  `ParallaxPainter`): colores fijos; intensidad por ruta (velocidad y
  asteroides: Explorador 1, Astronauta 2, Comandante 4). El cometa se
  **sacude** de a ratos en Astronauta (leve) y Comandante (fuerte).
- **El tono del cometa ya no tiñe el fondo**: sin halo detrás del sprite,
  estrellas del viaje/despegue blancas y fondo de la recompensa con color
  fijo. Solo el asset cambia de tono.
- **Luz en el fondo**: las estrellas cercanas tienen resplandor que titila,
  algunas brillantes con halo amplio y destello en cruz, y el planeta un
  halo de atmósfera (todo con colores fijos).

**Corregido al final de la sesión:**
- El cometa de 4 llega hasta el borde inferior (`SafeArea(bottom: false)` +
  2 px de desborde): ya no se ve su corte recto abajo.
- Giro de cara (`comet_turn.dart`) y entrada del tablero: el sprite de 4
  **nunca se achica** (solo se acerca un poco o se funde); el que se aleja,
  gira y vuelve es el cometa completo. La entrada tras el viaje/giro llega
  "desde cerca" (escala 1.12 → 1). **Falta mirarlo en el emulador.**

**Hecho (2026-11-26, sesión siguiente) — marciano por encima de todo:**
el cometa solo guarda un ancla (`CompositedTransformTarget` en
`_buildAlien`); el marciano se dibuja en la capa superior del `Stack`
(`_buildAlienOverlay`, `CompositedTransformFollower` + `IgnorePointer`),
encima del panel, el aviso y los marcadores y debajo del viaje/giro (se
oculta mientras ocurren). Hereda vaivén y zoom del cometa y el fundido de
entrada. El "acercarse" ahora sube y crece más (escala 1.9, sube 34 px).
Test nuevo en `crater_map_test.dart`. 127/127 tests, analyze limpio.
**Falta que el usuario lo mire en el emulador** (se reinstaló: hay que
volver a entrar).

**~~PRÓXIMA SESIÓN — primero esto~~ (hecho, ver arriba):**
- **El marciano debe sobreponerse a todo.** Hoy vive dentro del
  `ClipRect`/`OverflowBox` del cometa (`_buildAlien` en
  `crater_map_screen.dart`), así que queda **debajo** del panel de
  estadísticas y del aviso, y se recorta al salir del área del cometa.
  Debe dibujarse en una capa superior del `Stack` de la pantalla (por
  encima del panel, el aviso y los marcadores; debajo solo del viaje/giro),
  manteniendo su posición junto al cráter actual (convertir coordenadas
  del cometa a la pantalla, p. ej. con un `GlobalKey` del área del cometa
  o `CompositedTransformFollower`). Así, cuando flota hacia arriba o "se
  acerca a la pantalla" (escala 1.55 en `alienMotion`), pasa **por encima**
  del tablero y da la idea de que flota de verdad. Verificar que el
  acercamiento se note (subir escala/desplazamiento si hace falta) y que
  no bloquee toques (`IgnorePointer`).

**Revisión de UX hecha (2026-11-26, leyendo el código):** ver
`docs/revision-ux-2026-11-26.md` (32 hallazgos Alta/Media/Baja + causas
de los puntos de la sesión). Ojo: `docs/` está en `.gitignore`, el
archivo es solo local.

**Arreglados los 6 de prioridad alta** (2026-11-26):
1. Perfil con AppBar "Perfil" (flecha atrás) y SafeArea.
2. Cerrar sesión limpia toda la pila (`pushNamedAndRemoveUntil`).
3. Recompensa: "¡8 de 8 cráteres!" (`AppConstants.cratersPerComet`).
4. Portada de la sesión: **espera el toque** ("Toca cuando estén listos",
   botón dorado), fondo **opaco** (no se trasluce el contador) y sale con
   un fundido de 350 ms. Constantes `introEntrance`/`introExit`.
5. Sacudida del cometa → balanceo lento `cometSway` (3 vaivenes, ~2 Hz,
   una vez por ciclo de 16 s del marciano, 2 px Astronauta / 4 px
   Comandante). Test en `space_backdrop_test.dart`.
6. Letras: etiqueta del cráter 9→12, etiquetas de las cajas 10→12 (w600),
   chips del pop-up 10→12.

**Despegue: el fuego envuelve al marciano** (pedido del usuario):
`FireAura` en `launch_screen.dart` reemplaza a `_Flame`. Capa detrás
(resplandor + envoltura en gota que lo rodea y se estira en la cola +
lenguas) y capa delante (borde caliente abajo + lenguas por los costados).
Antes de encender solo hay una llamita; crece con `ignition`.

**Tanda 1 de Media/Baja hecha** (arreglos rápidos): aviso demo del login
solo en `kDebugMode` (nota del psicopedagogo a 14 pt); sin botón de
Minijuegos en el mapa (Fase 5 en pausa) y perfil de 48 dp; "45s por
serie" en el pop-up; salida "Llevan 2 min 10 s" contando la serie en
curso (`spokenDuration`); "En pausa" visible en serie y descanso;
"¿Cómo le fue?" sin handle y con `PopScope` (atrás no la cierra); error
de guardado nombra "Reintentar"; panel sin "+0 min" (dice "+40 s");
SnackBar al reiniciar el mapa.

**Tanda 2 hecha (avisos):** cráter bloqueado → SnackBar "Primero
conquisten el cráter N" (`CraterMarker.onLockedTap`,
`lockedCraterMessage`); al abrir un cráter, indicador si tarda más de
250 ms y aviso si falla (`craterPrepareError`); "Sortear" nunca queda
pegado (`craterReshuffleError`); el cierre muestra "Guardando…" y solo al
guardar "¡Cráter conquistado!" 900 ms (400 con movimiento reducido),
fondo opaco.

**Tanda 3 — propuestas de la pantalla de sesión** (lienzo privado):
https://claude.ai/artifact/NS2qHBLduQKFuJ5RzFEg7Y — A "Panel único",
B "Solo lo esencial", C "El tiempo en el botón" (serie + descanso cada
una). **Eligió B e implementada** (2026-11-26): tramos por ejercicio en
la barra (`segmentsKey`, sin "Cráter N" ni "Ejercicio X de Y"), puntitos
+ "Primera vuelta" (`vueltaName`, cambio en dos tiempos sin
superponerse), insignia de 88 px bajo el recurso, pasos con puntos,
descanso con "Descansen", marciano dentro del anillo de 250 px, el
número abajo y qué viene después. Cifras con `AppTheme.numbers`
(tabulares). "¿Cómo le fue?" con barrera casi opaca. Prepárate, portada
y controles sin cambios. Quedan de la tanda 3: letras chicas #7, #8, #16
(mapa/pop-up).

**Siguiente — Tanda 3:** datos del ejercicio (ver arriba) + letras chicas que
quedan (#7, #8, #16, #17). **Consultar al usuario:** "modo calma" propio
(#21) y suavizar el giro/escala del marciano (#13). Resto: #12, #26, #27,
#29, #30 (títulos), #31, #32.

~~**PRÓXIMA SESIÓN — super revisión de UX**~~ (pedida por el usuario):
recorrer toda la app como padre (login → ruta → despegue → mapa → pop-up →
sesión → "¿Cómo le fue?" → recompensa → giro/viaje → perfil) y anotar
fricciones, textos, tamaños, tiempos y animaciones. Ya visto: en la sesión,
el chip "Descanso · 25s" / "Serie 2 de 2" superpone ambos textos durante
el AnimatedSwitcher.

**DESPUÉS DE LA REVISIÓN DE UX — datos de los ejercicios** (pedido
2026-11-26): textos, tablas y elementos gráficos de la sesión. Los botones
están perfectos; no cambiarlos.
- Demasiados números con fuentes distintas: unificar la tipografía de
  cifras (contador, series, descanso, tiempos).
- La hoja "¿Cómo le fue?" deja ver la pantalla de atrás: debe tapar el
  fondo (a lo sumo dejar ver el contador en espera, nada más).
- Lo mismo al empezar el ejercicio: la pantalla del contador no debe
  traslucirse.
- Criterio general del usuario: que todo se vea **más acabado y
  ordenado**. Si quedan cifras de estilos distintos, juntarlas en **un
  solo panel claro**; mejor aún, mostrar solo lo que importa en cada
  momento y sacar el resto.
- Sonido: hoy la app **no tiene ningún sonido** (ni paquete de audio ni
  assets); solo vibración en la recompensa (`comet_reward_screen.dart`
  líneas 94 y 137). Queda pendiente decidir con el usuario si agregar
  sonidos (opcionales, suaves, con interruptor, por la sensibilidad
  sensorial).

**Pendientes:**
1. ~~Sprites de pisadas~~ — descartado: el usuario verificó que el avance
   de pisadas ya funciona con los sprites `crater_1..5` (2026-11-26).
3. Opcional: franja oscura bajo el cometa (`bottomAir` = 20 px).

**Lienzo de diseño (claude.ai, privado):**
https://claude.ai/artifact/6ecRbfKRCejXoLF5kJDMhX — propuestas A–F, J–L
(videojuego), M–O (fondos) y G–I descartadas. Del J gustaron las 3 cajas
de estadísticas; de los fondos, N y sobre todo O.

## 0c. Tanda 2026-11-26 (tarde) — Cometas de dos caras, panel y fondos vivos

| Pedido | Dónde quedó |
|---|---|
| Cada cometa = 8 cráteres en **dos caras de 4** (16 por ruta) | `AppConstants.totalCraterCount = 16`, `cratersPerComet = 8`, `facesPerComet`; `ExerciseProvider.cometIndex` / `faceInComet`; dificultad 1-4 fácil · 5-10 medio · 11-16 difícil |
| Al terminar la cara 1: "giro" natural sin mostrar el recorte | `animations/comet_turn.dart`: el sprite de 4 se aleja, aparece el **cometa completo** (`assets/images/craters/cometa_completo.png`), da media vuelta y se acerca como la cara nueva |
| Viaje entre cometas y despegue con el cometa completo | `CometTravel` y `LaunchScreen` usan `kFullCometAsset`; al terminar el viaje el tablero de 4 entra con zoom |
| "¿Cómo le fue?" después del último descanso | `SessionPlan.asksRatingAt`: tras el descanso que cierra el ejercicio (o al final de la rutina) |
| Panel: borde del color de la ruta + 3 cajas | `progress_panel.dart` (sin chip de ruta) + `widgets/glass_stat_box.dart` (vidrio, cuentan en cascada con "+N") |
| Fondos vivos que no se repiten + marciano que cruza | `animations/space_backdrop.dart`: Nebulosa / Parallax alternados por cara (`BackdropKind.forFace`), `FloatingAlienPass` cerca/lejos; todo quieto con "reducir movimiento" |

```
flutter analyze   → 4 info preexistentes, 0 errores, 0 warnings
flutter test      → 125 casos, todos en verde (10 archivos en test/)
```

Pendiente: sprites de **pisadas** (ver tareas abajo) y validar en el
emulador el giro de cara con calma (los tests lo cubren).

## 0b. Tanda 2026-11-26 — Rutas de entrenamiento

| Pedido | Dónde quedó |
|---|---|
| Elegir 1 de 3 dificultades al inicio, con la temática | `screens/route/route_selection_screen.dart` (marciano del Cuestionario recortado en `mascota/alien_portapapeles.png`, tarjetas con barras) |
| Cambia el tiempo de las series | `TrainingRoute.seriesSeconds` 30/45/60 → `RoutineModel.exerciseSeconds` |
| Ejercicios con equipo, reemplazables por cosas de la casa | `Equipo` (libre/basico/especial) + `implemento`/`reemplazo` en los 46 ejercicios; chip "Usa: …" y "Para este cráter necesitan" (`widgets/equipment_chip.dart`) |
| Planetas únicos por ruta | `TrainingRoute.comets` (Limón·Menta / Lavanda·Frutilla / Océano·Volcán), `ExerciseProvider.cometTheme(i)` |
| Difícil: un ejercicio extra por cráter | `TrainingRoute.extraExercises` (Comandante +1: 4/5/6) |
| Tablero tras una animación de inicio | `screens/route/launch_screen.dart` (despegue 3·2·1); el mapa entra con fade + zoom |
| App "viva" pensada en el vínculo | Saludo rotativo al padre en el mapa, intro "¡A entrenar juntos!" al abrir un cráter, ruta y planeta en el premio |
| (revisión anterior) reducir animaciones | `MediaQuery.disableAnimations`: sin confeti, viaje corto, sin latidos ni flotar |

Cada ruta guarda su propio avance; Perfil → "Cambiar ruta". "Reiniciar
mapa de esta ruta" ya no borra los acumulados del niño.

```
flutter analyze   → 4 info preexistentes, 0 errores, 0 warnings
flutter test      → 120 casos, todos en verde (9 archivos en test/)
```

**Tareas pendientes (en orden):**
1. Elegir e implementar el **tablero de progreso final** (propuestas en el
   lienzo de diseño "NeuroGym — Propuestas de panel de progreso").
   Las transiciones del cometa deben usar el asset completo
   `assets/images/craters/cometa_completo.png` (sin recortes), con un
   "giro" o desplazamiento al terminar cada cráter (ilusión de caminar
   sobre el cometa).
2. ~~Pisadas que avanzan~~ (descartado, ya funciona). Nota original:
   (`crater_1..5.png`, y los `crater X_Y.png` de `recursos/Asset app/`)
   para reforzar la sensación de progreso; definir cómo calzan con el
   cometa completo y el giro.

**Para revisar con alguien del área:** los reemplazos de equipo y la
clasificación de qué ejercicio va en qué ruta (en
`exercise_repository.dart`), y los pasos simplificados.

## 0. Qué se hizo en la tanda 2026-11-25

| Pedido | Dónde quedó |
|---|---|
| Progreso del mapa animado | `progress_panel.dart` (barra que se llena, números que cuentan), `crater_node.dart` (pop del recién conquistado, latido del disponible) |
| Controles anterior · pausa · siguiente | `widgets/session_controls.dart` (como `screens_legacy_bak/exercise_session_screen.dart`, actualizado) |
| 5 s de preparación por serie (antes 2 s) | `AppConstants.prepSeconds`, `SessionStep.prepSeconds`; anillo + "¡Prepárate!" solo alrededor del botón central; arranca sola |
| Ejercicio protagonista | Recurso grande al centro, contador como insignia en su esquina superior derecha (`SessionTimerWidget(compact: true)`), tarjeta "Así se hace" con 2-3 pasos simples (`ExerciseModel.pasos`, escritos para los 46 ejercicios) |
| App más animada, sin dependencias nuevas | `SoftPageTransitionsBuilder` (`app_theme.dart`), `BouncyTap`, `AnimatedSwitcher` en la sesión |
| "¿Cómo le fue?" por ejercicio | `widgets/how_did_it_go_sheet.dart` + `ExerciseRating` (1-3) → `ProgressModel.calificaciones`; `averageRatingFor(id)`. `rating_screen.dart` eliminado |
| Recompensa solo al cerrar el cometa | `screens/rewards/comet_reward_screen.dart` + `reward_messages.dart` (variantes con el nombre del niño) + confeti |
| Viaje al siguiente cometa | `animations/comet_travel.dart`, disparado por el mapa cuando cambia `roundIndex` |
| Un cometa distinto por vuelta | `core/theme/comet_theme.dart` (`CometTheme.forRound`: tono + halo sobre el mismo sprite) |

Además: el guardado al terminar se puede reintentar si falla, `fromJson`
acepta el formato de `toMap()` (SQLite), el mapa ignora toques mientras
sincroniza o viaja y los 4 cráteres caben en 360×640. Cada ejercicio
muestra ahora un **espacio reservado** (`ExerciseMediaSlot`) para la
gráfica, GIF o video que se está diseñando.

```
flutter analyze   → 4 info preexistentes, 0 errores, 0 warnings
flutter test      → 88 casos, todos en verde (6 archivos en test/)
```

**Pendientes de esta tanda:**
1. Probar el flujo completo en el emulador (prep, hoja "¿Cómo le fue?",
   recompensa tras el cráter 4, viaje al Cometa Lavanda).
2. Hacer commit de la tanda (no se commiteó).
3. Ver nota 4 de la sección 4: las calificaciones siguen en memoria hasta
   que entre SQLite (Fase 6, en pausa).
4. Pulido sugerido por la revisión (no bloqueante): respetar
   `MediaQuery.disableAnimations` (reducir confeti, viaje y latidos para
   niños con sensibilidad sensorial); envolver el cometa del mapa en un
   `RepaintBoundary` (hoy se redibuja cada frame por el flotar) y
   cambiar el `AnimatedContainer` del brillo del cráter por un
   `Container` simple.

---

## 1. Qué se hizo (tanda 2026-11-09)

Se aplicaron los cambios de `recursos/actualizacion24oct.txt`, y después
cuatro rondas de ajuste sobre el resultado visto en el emulador.

| Requerimiento original | Dónde quedó |
|---|---|
| Menú de cráteres | `crater_map_screen.dart` — reemplaza al Home con bottom nav |
| Sacar settings de tiempos | Eliminado; valores fijos en `AppConstants` y `Dificultad` |
| Recurso por ejercicio | `exercise_media_slot.dart` + campo `media` (espacio reservado) |
| 30 s → 1 minuto | `AppConstants.exerciseSeconds = 60` |
| Descanso 20 s, incremental | 20 / 25 / 30 s según dificultad |
| Randomizar sin repetir | `level_progress_service.dart` persiste los ids usados |
| Pop-up tipo Mario Party | `crater_preview_dialog.dart` |
| 3/4/5 ejercicios × 2 series | `Dificultad.forLevel()` |
| ~~Califica tu progreso~~ → "¿Cómo le fue?" | `how_did_it_go_sheet.dart` — 1 a 3 estrellas por ejercicio, en `ProgressModel.calificaciones` (exerciseId → 1..3). `rating_screen.dart` se eliminó |
| Recompensa solo al cerrar el cometa | `rewards/comet_reward_screen.dart` (`/rewards/comet`) + viaje `animations/comet_travel.dart` + `core/theme/comet_theme.dart` |

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

Estado actual: ver sección 0b (120 tests). Al cierre de la tanda del
2026-11-09 eran 25 casos.

Archivos nuevos o reescritos en la tanda del 2026-11-09:

```
lib/data/models/difficulty.dart            Dificultad: ejercicios, series, descanso
lib/data/models/routine_model.dart         Rutina plana (reemplaza SessionModel)
lib/data/services/level_progress_service.dart  Desbloqueo, anti-repetición, acumulados
lib/presentation/screens/home/crater_map_screen.dart
lib/presentation/screens/exercises/rating_screen.dart   (eliminado después: ver "¿Cómo le fue?")
lib/presentation/widgets/crater_node.dart      CraterSpot + CraterMarker
lib/presentation/widgets/crater_preview_dialog.dart
lib/presentation/widgets/exercise_media_slot.dart
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
2. **Recursos de ejercicios: solo espacio reservado.** Las gráficas,
   GIFs y videos se están diseñando. Cada ejercicio muestra
   `ExerciseMediaSlot` vacío; cuando llegue el recurso se asigna con
   `media:` en `exercise_repository.dart` (ver README de
   `assets/images/ejercicios/`). Para **video** falta sumar un reproductor
   (`video_player`). Hay un test que falla si algún ejercicio ya trae
   `media`, para que el cambio sea consciente.
3. **El panel cuenta ejercicios, no series ni repeticiones.** Si se
   prefiere otra métrica, se cambia qué acumula `addSession`.
4. **`ProgressRepository` sigue siendo en memoria.** Las calificaciones
   "¿Cómo le fue?" (`calificaciones`, exerciseId → 1..3) se guardan ahí y se pierden al
   reiniciar. Los acumulados del panel sí se persisten, por separado, en
   `LevelProgressService`. Unificar esto cuando entre SQLite.
5. **Perfilamiento en pausa.** `evaluation_model.dart` y los campos de
   `ChildModel` quedaron sin uso, para retomarlos con el dashboard.
6. **Fases 5 (minijuegos) y 6 (offline + polish) en pausa** por decisión
   del usuario (2026-11-25). `minigames_screen.dart` sigue como placeholder.
7. **Paleta de cometas:** son 5 temas en ciclo; con 8 niveles solo se ven
   Limón y Lavanda. Si se agregan niveles, los temas ya están listos.

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
ejercicios/  vacía (solo README) — todos los ejercicios muestran el espacio reservado
```

`fondo_estrellas.png` es un recorte del cielo de `Ilustracion_Base1.png`;
la ilustración original completa trae planeta y alien, así que **no sirve
como fondo** — ese fue el primer error de esta tanda.
