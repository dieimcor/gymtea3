# NeuroGym — Estado de Progreso del MVP

> **Última actualización:** 2026-11-09
> **Handoff para retomar:** ver `HANDOFF.md`
> **Referencia de diseño:** ver `CONTEXT.md` para especificaciones completas

---

## Estado General

| Fase | Nombre | Estado | Fecha |
|------|--------|--------|-------|
| **1** | Limpieza + Unificación Arquitectura | ✅ Completada | 2026-05-07 |
| **2** | Auth RUT + Home + Perfil | ✅ Completada | 2026-05-07 |
| **3** | Ejercicios del Manual + Sesión 3 Fases | ⚠️ Reemplazada por la Fase 4 | 2026-05-08 |
| **4** | Mapa de Cráteres + Rutinas randomizadas | ✅ Completada | 2026-11-09 |
| **5** | Minijuegos | ⬜ Pendiente | — |
| **6** | Offline-First (SQLite) + Polish | ⬜ Pendiente | — |

---

## Fase 1 — ✅ Completada

### Qué se hizo:
- `main.dart` reescrito — eliminó Firebase, inicializa `StorageService`, lanza `NeuroGymApp` desde `app.dart`
- `app.dart` actualizado con rutas nombradas (`/splash`, `/login`, `/home`)
- Nuevo `splash_screen.dart` en `presentation/screens/splash/` — verifica sesión via `AuthProvider`
- Nuevo `login_screen.dart` placeholder en `presentation/screens/auth/`
- `fondo_app.dart` movido a `presentation/widgets/` con colores de `AppTheme`
- `pubspec.yaml` — SDK ajustado a `^3.5.0`, package name `gymtea3`
- `app_theme.dart` — `CardTheme` → `CardThemeData` (compat SDK)
- `analysis_options.yaml` — excluye carpetas legacy

### Archivos legacy movidos (fuera de `lib/`):
- `screens_legacy_bak/` — 6 screens Firebase + datos_prueba.dart + widgets_old/
- `models_legacy_bak/` — level_model.dart (viejo)

---

## Fase 2 — ✅ Completada

### Qué se hizo:
- `auth_service.dart` — mock retorna padre (María González) + niño (Tomás, 8 años, TEA, control motor moderado, nivel 2)
- `auth_repository.dart` — persiste user+child como JSON en storage, métodos `restoreUser()` / `restoreChild()`
- `auth_provider.dart` — agrega `currentChild`, `childName`, `childLevel`, `greeting` contextual, restaura sesión completa
- `rut_input_field.dart` — widget reusable con auto-formato `XX.XXX.XXX-X` y validación visual en tiempo real
- `login_screen.dart` — usa `RutInputField`, auth via `AuthProvider`
- `home_screen.dart` — Bottom Navigation 3 tabs (Ejercicios/Minijuegos/Perfil), saludo contextual, card nivel actual con barra progreso, card sesión del día, resumen stats
- `profile_screen.dart` — info padre (RUT, email, rol), info niño (nombre, edad, condición, control motor color-coded, nivel), logout con confirmación

### Flujo funcional:
```
Splash → [token?] → Login (RUT + "1234") → Home
                                              ├── Tab Ejercicios (resumen + card nivel)
                                              ├── Tab Minijuegos (placeholder)
                                              └── Tab Perfil (datos padre/niño + logout)
```

---

## Fase 3 — ✅ Completada

### Qué se hizo:
- `exercise_repository.dart` — 77 ejercicios mock completos: 35 fortalecimiento (7 niveles × 5 categorías), 35 activación (5 por nivel), 7 juegos/circuitos (1 por nivel)
- `level_map_screen.dart` — Mapa vertical de 7 niveles con nodos staggered izq/der, estados bloqueado/actual/completado, scroll reverso (nivel 1 abajo)
- `level_node.dart` — Widget de nodo de nivel con animaciones, glow para nivel actual, estados visuales diferenciados
- `phase_indicator.dart` — Indicador horizontal Activación → Fuerza → Juego con colores y checkmarks para fases completadas
- `exercise_card.dart` — Tarjeta de ejercicio con categoría color-coded, badge series×reps, dots de progreso de serie, botón completar
- `session_timer_widget.dart` — Timer circular con CustomPainter, countdown, colores por fase, controles start/pause
- `exercise_session_screen.dart` — Sesión activa con 3 fases secuenciales, tracking de series/reps por ejercicio, pantalla de resumen al completar con stats
- `exercise_provider.dart` — `buildSession()` arma SessionModel completo (activación + fortalecimiento + juego) para cualquier nivel
- `progress_provider.dart` — `recordSessionProgress()` convenience method, getters `todaySessions`, `totalMinutes`, `totalSessions`
- `home_screen.dart` — Card "Sesión del Día" ahora navega a `/exercises/levels`
- `app.dart` — Rutas `/exercises/levels` y `/exercises/session` agregadas

### Tareas completadas:

| # | Tarea | Estado |
|---|-------|--------|
| 3.1 | Completar mock de 35 ejercicios (niveles 3-7) | ✅ |
| 3.2 | Agregar ejercicios de activación y juegos al mock | ✅ |
| 3.3 | Crear mapa vertical de 7 niveles | ✅ |
| 3.4 | Crear widget de nodo de nivel | ✅ |
| 3.5 | Crear indicador de fase | ✅ |
| 3.6 | Crear tarjeta de ejercicio | ✅ |
| 3.7 | Crear timer circular con countdown | ✅ |
| 3.8 | Crear pantalla de sesión activa 3 fases | ✅ |
| 3.9 | Agregar `buildSession()` al provider | ✅ |
| 3.10 | Integrar registro de progreso | ✅ |
| 3.11 | Conectar Home → mapa de niveles | ✅ |
| 3.12 | Agregar rutas en app.dart | ✅ |

### Flujo funcional:
```
Home → "Sesión del Día" → Mapa de Niveles (7 niveles visual)
                              → Tap nivel actual → Sesión Activa
                                  → Fase 1: Activación (2 min, 5 ejercicios, 2×15)
                                  → Fase 2: Fortalecimiento (8 min, 5 ejercicios, 3×10)
                                  → Fase 3: Juego (5 min, 1 circuito)
                                  → Resumen (stats + botón volver)
```

---

## Fase 4 — ✅ Completada (2026-11-09)

Aplica `recursos/actualizacion24oct.txt`. **Reemplaza a la Fase 3**: se
retiró la sesión de 3 fases y la configuración de tiempos.

### Qué se hizo
- **Mapa de cráteres como pantalla principal.** El sprite del cometa *es*
  el menú: los cráteres pintados son los niveles. Se eliminó el Home con
  bottom navigation y el mapa vertical de niveles.
- **Un solo cometa, 4 cráteres por tanda.** Al conquistarlos, los mismos
  cráteres se renumeran con los siguientes. Total: 8 niveles.
- **El arte refleja el avance:** `crater_1` (ninguno conquistado) →
  `crater_5` (los cuatro turquesa).
- **Rutinas:** lista plana de 3/4/5 ejercicios × 2 series × 60 s, con
  descansos incrementales de 20/25/30 s según dificultad.
- **Sorteo sin repetición** entre cráteres, persistido en disco.
- **Pop-up de nivel** (estilo Mario Party) con los ejercicios sorteados.
- **"Califica tu progreso":** desempeño, cansancio y motivación, 1 a 5
  estrellas, al terminar el cráter.
- **Panel de progreso** en el mapa: cráteres conquistados, ejercicios,
  tiempo y sesiones (persistidos).
- **Perfilamiento y evaluación fuera de la UI.** El código queda en el
  repo, sin uso, para retomarlo con el dashboard del psicopedagogo.

### Archivos nuevos
`difficulty.dart` · `routine_model.dart` · `level_progress_service.dart` ·
`crater_map_screen.dart` · `rating_screen.dart` · `minigames_screen.dart` ·
`crater_node.dart` · `crater_preview_dialog.dart` · `exercise_image.dart` ·
`progress_panel.dart` · `test/routine_test.dart` · `test/crater_map_test.dart`

### Eliminados
`session_model.dart` · `home_screen.dart` · `level_map_screen.dart` ·
`phase_indicator.dart` · `level_node.dart` · `exercise_card.dart` · enum
`FaseSesion`

### Estado
`flutter analyze`: 4 info, 0 errores · `flutter test`: 25 casos en verde ·
verificado en emulador (Pixel 9a).

---

## Fase 5 — ⬜ Pendiente

- Minijuegos (Higiene, Orden, Autonomía, Alimentación)
- Al menos 2-3 minijuegos funcionales tipo quiz
- `data/repositories/minigame_repository.dart`
- La pantalla `minigames_screen.dart` ya existe como placeholder

---

## Fase 6 — ⬜ Pendiente

- SQLite con `database_helper.dart`, `exercise_local_ds.dart`, `progress_local_ds.dart`
- Repositorios usan datasources locales como fuente primaria
- Indicador de conectividad
- Polish visual (animaciones, empty states, loading states)

---

## Estructura Actual de `lib/`

```
lib/app.dart
lib/core/constants/app_constants.dart
lib/core/errors/exceptions.dart
lib/core/network/api_client.dart
lib/core/theme/app_theme.dart
lib/data/datasources/local/exercise_local_ds.dart
lib/data/datasources/remote/exercise_remote_ds.dart
lib/data/models/child_model.dart
lib/data/models/difficulty.dart
lib/data/models/evaluation_model.dart
lib/data/models/exercise_model.dart
lib/data/models/progress_model.dart
lib/data/models/routine_model.dart
lib/data/models/user_model.dart
lib/data/repositories/auth_repository.dart
lib/data/repositories/exercise_repository.dart
lib/data/repositories/progress_repository.dart
lib/data/repositories/repositories.dart
lib/data/services/auth_service.dart
lib/data/services/level_progress_service.dart
lib/data/services/storage_service.dart
lib/main.dart
lib/presentation/providers/auth_provider.dart
lib/presentation/providers/exercise_provider.dart
lib/presentation/providers/progress_provider.dart
lib/presentation/screens/auth/login_screen.dart
lib/presentation/screens/exercises/exercise_session_screen.dart
lib/presentation/screens/exercises/rating_screen.dart
lib/presentation/screens/home/crater_map_screen.dart
lib/presentation/screens/minigames/minigames_screen.dart
lib/presentation/screens/profile/profile_screen.dart
lib/presentation/screens/splash/splash_screen.dart
lib/presentation/widgets/crater_node.dart
lib/presentation/widgets/crater_preview_dialog.dart
lib/presentation/widgets/exercise_image.dart
lib/presentation/widgets/fondo_app.dart
lib/presentation/widgets/progress_panel.dart
lib/presentation/widgets/rut_input_field.dart
lib/presentation/widgets/session_timer_widget.dart
lib/utils/formatters.dart
lib/utils/rut_validator.dart
test/crater_map_test.dart
test/routine_test.dart
```

## Notas Técnicas
- **Package name:** `gymtea3` (en pubspec.yaml)
- **Dart SDK:** `^3.5.0` (instalado: 3.9.2)
- **Flutter analyze:** 4 info, 0 errores
- **Tests:** 25 casos (`test/routine_test.dart`, `test/crater_map_test.dart`)
- **Assets:** `recursos/` (material fuente, 271 MB) está en `.gitignore`
- **Firebase:** Eliminado de dependencias activas, comentado en pubspec
- **Legacy backup:** `screens_legacy_bak/` y `models_legacy_bak/` en raíz del proyecto (fuera de `lib/`)
