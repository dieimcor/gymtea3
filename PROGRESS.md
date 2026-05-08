# NeuroGym — Estado de Progreso del MVP

> **Última actualización:** 2026-05-08
> **Referencia de diseño:** ver `CONTEXT.md` para especificaciones completas

---

## Estado General

| Fase | Nombre | Estado | Fecha |
|------|--------|--------|-------|
| **1** | Limpieza + Unificación Arquitectura | ✅ Completada | 2026-05-07 |
| **2** | Auth RUT + Home + Perfil | ✅ Completada | 2026-05-07 |
| **3** | Ejercicios del Manual + Sesión 3 Fases | ✅ Completada | 2026-05-08 |
| **4** | Home Enriquecido + Minijuegos | ⬜ Pendiente | — |
| **5** | Offline-First (SQLite) + Polish | ⬜ Pendiente | — |

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

## Fase 4 — ⬜ Pendiente

- Enriquecer Home con widgets informativos (racha, sesiones del día)
- Crear sección de minijuegos (Higiene, Orden, Autonomía, Alimentación)
- Al menos 2-3 minijuegos funcionales tipo quiz
- `data/repositories/minigame_repository.dart`

---

## Fase 5 — ⬜ Pendiente

- SQLite con `database_helper.dart`, `exercise_local_ds.dart`, `progress_local_ds.dart`
- Repositorios usan datasources locales como fuente primaria
- Indicador de conectividad
- Polish visual (animaciones, empty states, loading states)

---

## Estructura Actual de `lib/`

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/app_constants.dart
│   ├── errors/exceptions.dart
│   ├── network/api_client.dart
│   └── theme/app_theme.dart
├── data/
│   ├── datasources/
│   │   ├── local/exercise_local_ds.dart    (placeholder)
│   │   └── remote/exercise_remote_ds.dart  (placeholder)
│   ├── models/
│   │   ├── child_model.dart
│   │   ├── evaluation_model.dart
│   │   ├── exercise_model.dart
│   │   ├── progress_model.dart
│   │   ├── session_model.dart
│   │   └── user_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── exercise_repository.dart  (77 ejercicios mock: 35 fort + 35 act + 7 juegos)
│   │   ├── progress_repository.dart
│   │   └── repositories.dart
│   └── services/
│       ├── auth_service.dart         (mock: RUT + "1234")
│       └── storage_service.dart
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── exercise_provider.dart    (+buildSession)
│   │   └── progress_provider.dart    (+recordSessionProgress)
│   ├── screens/
│   │   ├── auth/login_screen.dart
│   │   ├── exercises/
│   │   │   ├── level_map_screen.dart          (Fase 3)
│   │   │   └── exercise_session_screen.dart   (Fase 3)
│   │   ├── home/home_screen.dart       (3 tabs, conectado a niveles)
│   │   ├── profile/profile_screen.dart
│   │   └── splash/splash_screen.dart
│   └── widgets/
│       ├── exercise_card.dart          (Fase 3)
│       ├── fondo_app.dart
│       ├── level_node.dart             (Fase 3)
│       ├── phase_indicator.dart        (Fase 3)
│       ├── rut_input_field.dart
│       └── session_timer_widget.dart   (Fase 3)
└── utils/
    ├── formatters.dart
    └── rut_validator.dart
```

## Notas Técnicas
- **Package name:** `gymtea3` (en pubspec.yaml)
- **Dart SDK:** `^3.5.0` (instalado: 3.9.2)
- **Flutter analyze:** 4 info, 0 errores
- **Firebase:** Eliminado de dependencias activas, comentado en pubspec
- **Legacy backup:** `screens_legacy_bak/` y `models_legacy_bak/` en raíz del proyecto (fuera de `lib/`)
