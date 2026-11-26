# NeuroGym — Contexto del Proyecto

> Plataforma de apoyo motor para niños neurodivergentes mediante rutinas de fuerza y juegos.
> Auspiciado por **VerdeDigital** · Flutter + Node.js + PostgreSQL

---

## 1. Descripción del Proyecto

NeuroGym asiste a niños neurodivergentes (hasta 13 años) con rutinas de fuerza basadas en el **"Manual de Fuerza y Juegos"** (USAC, 2022). Opera dentro del ecosistema educativo chileno conectando:

- **PIE** (Programa de Integración Escolar) → detecta la necesidad
- **Psicopedagogo / TO** → evalúa, perfila y asigna ejercicios
- **Padre** → ejecuta rutinas con su hijo mediante la app

### Condiciones soportadas
`TEA` · `TDAH` · `TEL` · `MIXTO` · `OTRO`

### Escalabilidad de Ejercicios
- **Categorías:** String-based dinámicas (no enum). Se agregan desde el backend sin tocar la app.
- **Niveles de progresión:** Sin límite fijo. El manual base define 1-7, pero puede crecer indefinidamente.
- **Catálogo:** Nuevos ejercicios se insertan en la BD y llegan a la app vía sync automático.

### Roles de usuario
| Rol | Plataforma | Acciones |
|-----|-----------|----------|
| PADRE | App Móvil | Ejecuta ejercicios, ve progreso |
| PSICOPEDAGOGO | Dashboard Web | Evalúa, enrola, asigna, monitorea |
| TO | Dashboard Web | Mismo que psicopedagogo |
| ADMIN | Dashboard Web | Administración general |

> El rol de enrolador es extensible (ej: profesor PIE en el futuro).

---

## 2. Flujo Principal

```
1. PIE/colegio recomienda evaluación
2. Psicopedagogo evalúa al niño (planilla propia)
3. Carga evaluación en dashboard → IA sugiere nivel + ejercicios
4. Psicopedagogo ajusta y confirma → crea cuenta del padre
5. Padre recibe email con credenciales (RUT + password)
6. Padre instala app → login → ejercicios ya están perfilados
7. Sesiones diarias de 15 min (offline-first)
8. Progreso se sincroniza cuando hay conexión
9. Informe mensual de progreso al padre
10. Psicopedagogo monitorea desde dashboard
```

---

## 3. Stack Tecnológico

### App Móvil (Flutter)
| Componente | Tecnología |
|-----------|-----------|
| Framework | Flutter + Dart |
| State Management | Provider + ChangeNotifier |
| Cache Offline | SQLite (sqflite) |
| Storage Seguro | flutter_secure_storage |
| Conectividad | connectivity_plus |
| HTTP | http (package) |
| Internacionalización | intl |

### Backend (Sprint 4+)
| Componente | Tecnología |
|-----------|-----------|
| Runtime | Node.js 20 LTS |
| Framework | Express.js + TypeScript |
| ORM | Prisma |
| Base de Datos | PostgreSQL |
| Auth | JWT (access + refresh tokens) |
| Email | Nodemailer |
| IA | OpenAI API |

### Dashboard Web (Sprint 5+)
| Componente | Tecnología |
|-----------|-----------|
| Framework | React + Next.js |
| Estilo | Tailwind CSS o CSS Modules (TBD) |

---

## 4. Arquitectura App Móvil — Clean Architecture

```
lib/
├── main.dart                         → Entry point
├── app.dart                          → MaterialApp + MultiProvider + Tema
├── core/
│   ├── constants/app_constants.dart   → URLs API, tiempos fijos, keys
│   ├── theme/app_theme.dart          → ThemeData dark + colores por categoría
│   ├── theme/comet_theme.dart        → Tono + halo del cometa por vuelta (CometTheme)
│   ├── network/api_client.dart       → HTTP client centralizado con JWT
│   └── errors/exceptions.dart        → AuthException, NetworkException, etc.
├── data/
│   ├── models/
│   │   ├── user_model.dart           → Padre (RUT, email, rol)
│   │   ├── child_model.dart          → Niño
│   │   ├── evaluation_model.dart     → Rúbrica (en pausa, sin uso en la UI)
│   │   ├── difficulty.dart           → Dificultad: ejercicios, series, descanso
│   │   ├── exercise_model.dart       → Ejercicio + categoría + dificultad + imagen
│   │   ├── routine_model.dart        → Rutina plana de un cráter
│   │   ├── progress_model.dart       → Progreso + calificaciones por ejercicio + flag sync
│   │   ├── exercise_rating.dart      → "¿Cómo le fue?": 1 a 3 estrellas
│   │   ├── session_step.dart         → Pasos planos de la sesión (prep · serie · descanso)
│   │   └── reward_messages.dart      → Avisos al padre de la recompensa del cometa
│   ├── repositories/
│   │   ├── auth_repository.dart      → Login RUT + JWT + session
│   │   ├── exercise_repository.dart  → Pools por dificultad + sorteo aleatorio
│   │   └── progress_repository.dart  → Cache local + sync backend
│   ├── datasources/
│   │   ├── local/exercise_local_ds.dart   → SQLite (Sprint 3)
│   │   └── remote/exercise_remote_ds.dart → API REST (Sprint 4+)
│   └── services/
│       ├── auth_service.dart         → Lógica auth (mock → API)
│       ├── storage_service.dart      → Token seguro + SharedPreferences
│       └── level_progress_service.dart → Desbloqueo + ejercicios ya sorteados
├── presentation/
│   ├── screens/
│   │   ├── splash/splash_screen.dart
│   │   ├── auth/login_screen.dart
│   │   ├── home/crater_map_screen.dart     → Pantalla principal (cráteres)
│   │   ├── exercises/
│   │   │   └── exercise_session_screen.dart → Rutina plana + prep 5s + timers
│   │   ├── rewards/comet_reward_screen.dart → Recompensa al conquistar el cometa
│   │   ├── minigames/minigames_screen.dart
│   │   └── profile/profile_screen.dart
│   ├── widgets/
│   │   ├── fondo_app.dart            → Background existente del proyecto
│   │   ├── rut_input_field.dart
│   │   ├── crater_node.dart          → Nodo de cráter del mapa
│   │   ├── crater_preview_dialog.dart → Pop-up de ejercicios del nivel
│   │   ├── exercise_media_slot.dart  → Espacio reservado del recurso (imagen/GIF/video)
│   │   ├── session_timer_widget.dart → Timer circular (serie / descanso)
│   │   ├── session_controls.dart     → Anterior · pausa (anillo de prep) · siguiente
│   │   ├── how_did_it_go_sheet.dart  → Hoja "¿Cómo le fue?" tras cada ejercicio
│   │   └── bouncy_tap.dart           → Rebote al tocar
│   ├── animations/
│   │   ├── comet_travel.dart         → Viaje animado al siguiente cometa
│   │   └── confetti.dart             → Confeti de la recompensa
│   └── providers/
│       ├── auth_provider.dart        → Estado login/logout/sesión
│       ├── exercise_provider.dart    → Mapa de cráteres + sorteo de rutinas
│       └── progress_provider.dart    → Registro + calificaciones + averageRatingFor + sync
├── utils/
│   ├── rut_validator.dart            → Validación RUT módulo 11
│   └── formatters.dart               → Fechas, duración, categorías
assets/images/
├── craters/      → fondo_espacio, crater_base, crater_1..7
├── mascota/      → alien, alien_calificacion
└── ejercicios/   → recursos de ejercicios (hoy vacía: solo espacio reservado)
```

---

## 5. Sistema de Ejercicios

> **Actualizado (nov 2026).** Se retiró la sesión de 3 fases y la pantalla de
> configuración de tiempos. El perfilamiento y la evaluación funcional quedan
> **fuera de alcance por ahora**: el avance lo define el mapa de cráteres.

### Mapa de Cráteres (pantalla principal)

La pantalla principal es el mapa: **un cráter por nivel**.

- Se parte con el **cráter 1** abierto; completar un cráter abre el siguiente.
- **8 niveles** en total (`AppConstants.totalCraterCount`), en tandas de **4 cráteres**
  sobre un solo cometa: al conquistar los 4, los mismos cráteres se renumeran
  con los niveles 5-8.
- El avance se guarda local (`SharedPreferences`), sin backend ni evaluación.
- **Tablero vivo:** al aparecer, el cometa entra con fade + zoom y el panel
  baja; el aviso del mapa es un mensaje cálido para el padre que va
  cambiando ("Hoy Tomás y tú van por el cráter 3…"). El panel muestra la
  ruta y el planeta actual.
- **Progreso animado** (`ProgressPanel`, `CraterMarker`): la barra se llena,
  los números cuentan, el cráter recién conquistado salta con destellos y el
  disponible late. Mientras el mapa sincroniza o viaja, ignora los toques.

### Rutas de entrenamiento (se eligen al inicio)

Después del login, si no hay ruta guardada, el padre elige una de **3
rutas** en `RouteSelectionScreen` (`/route`): el marciano con portapapeles
del arte "Cuestionario" (`mascota/alien_portapapeles.png`) pregunta
"¿Qué tan lejos viajamos con {niño}?" y cada ruta es una tarjeta con barras
de nivel al estilo del cuestionario. Al confirmar se reproduce el
**despegue** (`LaunchScreen`, `/launch`: 3·2·1, el marciano sube, estrellas
a velocidad y llega el primer planeta) y recién ahí aparece el tablero.
Se puede cambiar desde **Perfil → Cambiar ruta**; cada ruta **guarda su
propio avance** (claves `completed_levels_<ruta>` / `used_exercise_ids_<ruta>`);
los acumulados del niño son globales.

| Ruta (`TrainingRoute`) | Serie | Ejercicios por cráter | Equipo | Planetas |
|---|---|---|---|---|
| Explorador | 30 s | 3 → 4 → 5 | Solo el cuerpo y una silla (`Equipo.libre`) | Limón · Menta |
| Astronauta | 45 s | 3 → 4 → 5 | + cosas de la casa: botella, pelota, toalla (`basico`) | Lavanda · Frutilla |
| Comandante | 60 s | **4 → 5 → 6** (+1) | + equipo especial, con reemplazo seguro (`especial`) | Océano · Volcán |

La cantidad de ejercicios sigue creciendo con los cráteres y los descansos
(20/25/30 s) no cambian entre rutas.

**Equipo pensado para niños.** Cada ejercicio tiene `equipo`, `implemento`
(lo que pide el manual) y `reemplazo` (juguete o cosa de la casa: botella
de agua chica, pelota o cojín, toalla que sostiene el padre, silla firme,
mochila con libros livianos…). La sesión muestra "Usa: …" en "Así se hace"
y el pop-up lista lo que **necesitan** para el cráter. Los ejercicios con
carga o poco recomendables para niños (hip thrust con carga, peso muerto
sumo, rueda abdominal, dominadas, TRX) quedan solo en Comandante y siempre
con una alternativa suave. El catálogo de una ruta se filtra por equipo y,
si queda corto, se completa con ejercicios permitidos de las dificultades
vecinas (`ExerciseRepository.poolFor`).

### Dificultad por nivel

| Niveles | Dificultad | Ejercicios (Comandante) | Series | Descanso |
|---------|-----------|-----------|--------|----------|
| 1-2 | Fácil | 3 (4) | 2 | 20 s |
| 3-5 | Medio | 4 (5) | 2 | 25 s |
| 6-8 | Difícil | 5 (6) | 2 | 30 s |

La duración de la serie la define la ruta (30/45/60 s). El descanso es
**incremental según la dificultad** y aplica tanto entre series como entre
ejercicios.

### Rutina (`RoutineModel`)

Lista plana de bloques: `serie (30/45/60 s según la ruta) → descanso → serie → …`, sin descanso
final. La secuencia la arma `ExerciseSessionScreen` con `SessionPlan`
(`session_step.dart`).

### Sesión: preparación y controles

- **Preparación de 5 s** (`AppConstants.prepSeconds`) antes de **cada serie**
  (los descansos no la tienen). El "¡Prepárate!" vive **solo alrededor del
  botón central**: un anillo dorado se llena y el botón respira. Al
  completarse, la serie arranca sola.
- **Diseño de una serie:** lo protagonista es el ejercicio. Arriba el
  nombre; al centro el **recurso grande** (`ExerciseMediaSlot`, 4:3, todo el
  ancho útil hasta 360 px); el **contador** es una insignia chica en la
  **esquina superior derecha del recurso** (`SessionTimerWidget(compact:
  true)`) que aparece con un "pop" al terminar la preparación; abajo la
  tarjeta **"Así se hace"** con 2-3 pasos simples (`ExerciseModel.pasos`,
  escritos para leerlos en voz alta; si faltan se usa `descripcion`). La
  tarjeta va destacada en dorado durante la preparación y se suaviza al
  arrancar.
- **Descanso:** mascota flotando y el anillo grande del contador al centro.
- **Controles** (`SessionControls`), como los originales pero actualizados:
  **anterior** (`skip_previous`) · círculo blanco grande con **pausa/play** ·
  **siguiente** (`skip_next`). Pausar congela también la preparación.
- Al terminar: se guarda el progreso (con las calificaciones) y
  `completeLevel` devuelve `LevelCompletion`; si `cometCompleted`, se abre la
  recompensa con `pushReplacementNamed`; si no, `pop` al mapa. Si el guardado
  falla, un SnackBar ofrece "Reintentar" sin duplicar el historial.

### Sorteo aleatorio sin repetición

Cada vez que se abre un cráter se **re-randomiza** su rutina:

1. Se toma el pool de la dificultad del nivel.
2. Se excluyen los ejercicios ya sorteados en otros cráteres (persistido).
3. Si el pool restante no alcanza, el registro de esa dificultad se reinicia solo.

Volver a sortear desde el pop-up libera la selección anterior, para no quemar
ejercicios que no se van a ejecutar.

### Pop-up de nivel (estilo Mario Party)

Al tocar un cráter se abre `CraterPreviewDialog` con los ejercicios que
tocaron (imagen + nombre + categoría), la dificultad, los tiempos y la
duración estimada. Botones: **Sortear** y **¡Comenzar!**.

### Recurso visual de ejercicios (espacio reservado)

Las gráficas, GIFs y videos de cada ejercicio **se están diseñando**. Por
eso cada ejercicio muestra solo un **espacio reservado** (`ExerciseMediaSlot`,
4:3; 200 px de ancho en la sesión y miniatura de 64 px en el pop-up) con un
ícono y el nombre del ejercicio.

Cuando un recurso esté listo se asigna en el catálogo
(`exercise_repository.dart`) con el campo `media` de `ExerciseModel`:

```dart
media: ExerciseMedia.gif('assets/images/ejercicios/rd-1.gif'),
// o ExerciseMedia.imagen(...) / ExerciseMedia.video(...) / una URL https
```

y aparece en ese mismo espacio, sin tocar pantallas. Imagen y GIF se
dibujan con `Image` (el GIF se anima solo). **Video:** el espacio queda
reservado con un ícono de reproducción; falta sumar un reproductor
(p. ej. `video_player`) cuando lleguen los videos. El JSON usa
`"media": {"tipo": "gif", "ruta": "..."}` y sigue leyendo el formato
antiguo `imagen_asset` / `imagen_url`.

### "¿Cómo le fue?" por ejercicio

Tras la **última serie de cada ejercicio**, `HowDidItGoSheet` le pregunta al
padre cómo le fue **al niño**, con **1 a 3 estrellas** (`ExerciseRating`:
le costó · bien · ¡excelente!). Se guarda por ejercicio en
`ProgressModel.calificaciones` (`exerciseId → 1..3`) junto al progreso local
(`sincronizado = false`); `ProgressProvider.averageRatingFor(id)` da el
promedio para el resumen futuro. Se puede saltar. Reemplaza al antiguo
"Califica tu progreso" (3 ejes × 5 estrellas), que se eliminó.

### Recompensa del cometa y viaje

La recompensa al niño llega **solo al conquistar los 4 cráteres de un
cometa**, no en cada cráter: `CometRewardScreen` (`/rewards/comet`) muestra un
aviso dinámico al padre con el nombre del niño ("¡Recompensa a tu hijo, lo
logró!", un abrazo, chocar los cinco…). Al volver al mapa, `CometTravel`
anima el viaje al siguiente cometa, que se pinta con su `CometTheme` (tono +
halo sobre el mismo sprite) para que cada vuelta parezca un cometa distinto.

- Avisos: `RewardMessages.forComet(nombre, …)` rota variantes (recompensa,
  abrazo, chocar los cinco, decirle lo orgulloso/a que estás, preguntarle
  qué ejercicio le gustó) con confeti (`ConfettiBurst`).
- Temas: `CometTheme.forRound(i)` → Limón (arte original), Lavanda, Menta,
  Frutilla, Océano (rotación de tono con `ColorFilter.matrix` + halo).
- El mapa detecta que `roundIndex` cambió respecto del que mostraba y
  reproduce `CometTravel` ("¡Rumbo al Cometa …!") antes de mostrar la nueva
  tanda.
- Transiciones de página suaves (`SoftPageTransitionsBuilder` en
  `app_theme.dart`) y rebote al tocar (`BouncyTap`), sin dependencias nuevas.

### Categorías de ejercicios

| Categoría | Código | Ejemplo |
|-----------|--------|---------|
| Rodilla Dominante | RD | Pararse/sentarse de banco |
| Cadera Dominante | CD | Puente glúteo dinámico |
| Empuje | EM | Empuje balón medicinal acostado |
| Jalón | JL | Remo al pecho elástico 2 manos |
| Core | CR | Extensiones tronco 1 brazo |
| Movilidad y Juego | MOV | Rayuela, salto estrella, paso lateral |
| *(nuevas)* | *Backend* | *Se agregan sin tocar la app* |

### Evaluación Funcional — en pausa

La rúbrica de 5 ejercicios, la clasificación de control motor y el nivel
asignado **siguen modelados** (`evaluation_model.dart`, campos de
`ChildModel`) pero **ninguna pantalla los usa**. Se retoman cuando exista el
dashboard del psicopedagogo.

## 6. Minijuegos

Disponibles para **todos los perfiles** sin evaluación. Sin sync con backend. Almacenados localmente.

| Categoría | Ejemplos |
|-----------|----------|
| Higiene personal | Lavarse los dientes, las manos |
| Orden | Ordenar su pieza, hacer la cama |
| Autonomía | Vestirse solo, preparar mochila |
| Alimentación | Identificar alimentos saludables |

---

## 7. Base de Datos (PostgreSQL)

### Entidades principales

**Users:** `id (UUID PK)`, `rut (UK)`, `nombre`, `email`, `password_hash`, `rol (ENUM)`, `created_at`

**Children:** `id`, `nombre`, `edad`, `parent_id (FK→Users)`, `enrolled_by (FK→Users)`, `condicion (ENUM)`, `control_motor (ENUM)`, `nivel_progresion_actual (1-7)`

**Evaluations:** `id`, `child_id (FK)`, `evaluator_id (FK)`, 5 campos puntaje INT, `puntaje_total`, `clasificacion (ENUM)`, `nivel_asignado`, `observaciones`, `fecha`

**Exercises:** `id`, `nombre`, `descripcion`, `categoria (ENUM: RD|CD|EM|JL|CR)`, `nivel_progresion (1-7)`, `tipo_fase (ENUM)`, `sugerencias`, `variaciones`

**ChildExercises:** Asignación personalizada por niño (activar/desactivar, custom series/reps)

**Sessions:** Registro de rutinas completadas con `sincronizado (BOOL)` para offline-first

**SessionExercises:** Ejercicios realizados dentro de una sesión

---

## 8. API Endpoints

### Auth
- `POST /auth/login` → RUT + password → JWT
- `POST /auth/refresh` → Renovar token
- `POST /auth/logout` → Invalidar sesión

### Usuarios
- `POST /users/enroll` → Crear padre + niño (envía email)
- `GET /users/me` → Perfil autenticado
- `GET /users/:id/children` → Hijos del padre

### Evaluaciones
- `POST /evaluations` → Cargar evaluación funcional
- `POST /evaluations/:id/ai-suggest` → IA sugiere ejercicios
- `PUT /evaluations/:id/adjust` → Ajustar nivel

### Ejercicios
- `GET /exercises?nivel=N&categoria=X` → Filtrar
- `GET /children/:id/exercises` → Asignados al niño
- `PUT /children/:id/exercises` → Actualizar asignación

### Progreso
- `POST /sessions` → Registrar sesión completada
- `POST /sync/progress` → Bulk sync offline
- `GET /children/:id/progress` → Historial
- `GET /children/:id/report/monthly` → Informe mensual

---

## 9. Estrategia Offline-First

```
Login exitoso → Cache ejercicios en SQLite
  ↓
Padre ejecuta sesión (sin conexión)
  ↓
Progreso guardado local (sincronizado = false)
  ↓
¿Hay conexión? (connectivity_plus)
  SÍ → POST /sync/progress → marcar sincronizado = true
  NO → Sigue acumulando local
```

**Tokens:** JWT almacenado en `flutter_secure_storage` (cifrado a nivel de OS).

---

## 10. Módulo IA

El módulo interpreta la evaluación funcional y sugiere:
- Ejercicios específicos del catálogo de 35
- Nivel de progresión inicial
- Adaptaciones por condición

**Input:** Evaluación (5 puntajes) + condición del niño + historial  
**Output:** Sugerencias que el psicopedagogo **revisa y confirma** (siempre tiene última palabra)  
**Tecnología:** OpenAI API con prompt especializado

---

## 11. Seguridad

| Aspecto | Implementación |
|---------|---------------|
| Auth | JWT + refresh token, expiración 24h |
| Tokens locales | flutter_secure_storage |
| Passwords | bcrypt en backend |
| RUT | Validación módulo 11 frontend + backend |
| API | Rate limiting, CORS, helmet.js |
| Datos menores | Cumplimiento Ley 19.628 (Chile) |
| Comunicación | HTTPS obligatorio en producción |
| Roles | Middleware de autorización por endpoint |

---

## 12. Navegación de la App

```
Splash → ¿JWT válido?
  NO → Login (RUT + pass) → Mapa de Cráteres
  SÍ → Mapa de Cráteres
          ├── Cráter N → Pop-up de ejercicios → Sesión (prep 5s → serie → descanso;
          │      "¿Cómo le fue?" tras cada ejercicio) → [Recompensa si cerró el
          │      cometa → viaje al siguiente] → Mapa
          ├── Minijuegos (icono superior)
          └── Perfil (icono superior) → Datos · Reiniciar avance · Cerrar sesión
```

> El antiguo Home con bottom navigation y el mapa vertical de 7 niveles fueron
> reemplazados por el mapa de cráteres. No hay pantalla de configuración de
> tiempos.

## 13. Plan de Sprints (~10 semanas)

| Sprint | Foco | Duración | Entregables clave |
|--------|------|----------|-------------------|
| **0** | Setup estructura | 1 sem | Clean Architecture, modelos, providers, tema |
| **1** | Auth + Navegación | 1 sem | Login RUT, JWT, splash, home, navegación |
| **2** | Ejercicios + Sesiones | 2 sem | 35 ejercicios, mapa niveles, sesión 3 fases, timer |
| **3** | Offline + Minijuegos | 1 sem | SQLite cache, sync flag, 3-4 minijuegos |
| **4** | Backend Base | 2 sem | API REST, PostgreSQL, Prisma, IA, Nodemailer |
| **5** | Dashboard Web | 2 sem | Enrolamiento, evaluación, progreso, informes |
| **6** | Integración + QA | 1 sem | E2E testing, sync offline, deploy, QA |

### Hitos ANID
- 📅 **Inscripción:** 19 de Marzo 2026
- 🏆 **Fallo Final:** Agosto 2026

---

## 14. Estado Actual

### Actualización de requerimientos (nov 2026)

Aplicados los cambios de `recursos/actualizacion24oct.txt`:

| Requerimiento | Estado |
|---------------|--------|
| Menú de cráteres como pantalla principal | ✅ `CraterMapScreen` reemplaza al Home con bottom nav |
| Sacar la configuración de tiempos (settings) | ✅ Tiempos fijos en `AppConstants` / `Dificultad` |
| Recurso por ejercicio (espacio reservado) | ✅ `ExerciseMediaSlot` + campo `media` (imagen/GIF/video) |
| Tiempos de 30 s → 1 minuto | ✅ `AppConstants.exerciseSeconds = 60` |
| Descanso de 20 s entre ejercicios | ✅ Piso del nivel fácil |
| Descansos incrementales por dificultad | ✅ 20 / 25 / 30 s |
| Randomizar al elegir cráter, sin repetir | ✅ Pools + registro persistido |
| Pop-up de ejercicios del nivel (Mario Party) | ✅ `CraterPreviewDialog` |
| 3 / 4 / 5 ejercicios × 2 series | ✅ `Dificultad.exerciseCount` |
| "¿Cómo le fue?" por ejercicio (1-3 estrellas) | ✅ `HowDidItGoSheet` + `ProgressModel.calificaciones` |
| Recompensa solo al terminar el cometa + viaje | ✅ `CometRewardScreen` + `CometTravel` + `CometTheme` |
| Controles anterior · pausa · siguiente + prep 5s | ✅ `SessionControls` |

**Fuera de alcance por ahora:** "Matar al alien" (el alien queda solo como
mascota), perfilamiento y evaluación previa del niño.

### Retirado del código

- `session_model.dart` (sesión de 3 fases) → `routine_model.dart`
- `home_screen.dart`, `level_map_screen.dart` → `crater_map_screen.dart`
- `rating_screen.dart` ("Califica tu progreso", 3 ejes × 5 estrellas) → `how_did_it_go_sheet.dart`
- `phase_indicator.dart`, `level_node.dart`, `exercise_card.dart`
- Enum `FaseSesion` y el reparto activación/fortalecimiento/juego

### Dependencias activas (pubspec.yaml)
```yaml
provider: ^6.1.2
http: ^1.2.0
flutter_secure_storage: ^9.0.0
sqflite: ^2.3.0
connectivity_plus: ^5.0.0
intl: ^0.19.0
shared_preferences: ^2.2.2
```

### Tests
120 casos en verde (`flutter test`, 2026-11-26); `flutter analyze` deja solo
las 4 info preexistentes.

| Archivo | Casos | Cubre |
|---|---|---|
| `routine_test.dart` | 9 | Nivel → dificultad, tiempos, sorteo sin repetición |
| `crater_map_test.dart` | 33 | Tandas, panel animado, viaje, bloqueo de toques, 360×640 |
| `session_test.dart` | 14 | Plan con prep, controles, "¿Cómo le fue?", recompensa, reintento de guardado |
| `reward_test.dart` | 12 | Avisos al padre con el nombre, confeti, pantalla de recompensa |
| `comet_theme_test.dart` | 10 | Temas por vuelta, matriz de color, `CometTravel` |
| `progress_model_test.dart` | 4 | `fromJson` ↔ `toJson` / `toMap`, calificaciones |

---

## 15. Decisiones de Diseño

1. **Offline-first:** La app funciona sin conexión, sincroniza cuando puede
2. **RUT como login:** Reemplaza Firebase Auth, más natural para el contexto chileno
3. **Firebase comentado:** No eliminado, por si se necesita reactivar
4. **Mock data primero:** Repositorios con datos mock hasta tener backend
5. **Psicopedagogo decide:** La IA sugiere, nunca impone (en pausa hasta el dashboard)
6. **Minijuegos sin sync:** No envían datos al backend, son locales
7. **Rutina por cráter:** 3/4/5 ejercicios × 2 series × 60 s, sin fases
8. **Progresión por cráter:** completar uno abre el siguiente; sin evaluación previa
9. **Informe al padre solo mensual:** No sobrecargar con datos diarios
10. **Tema oscuro:** Definido en `app_theme.dart` con colores por categoría de ejercicio
