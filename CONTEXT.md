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
│   │   └── progress_model.dart       → Progreso + calificación + flag sync
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
│   │   │   ├── exercise_session_screen.dart → Rutina plana + timers
│   │   │   └── rating_screen.dart           → Califica tu progreso + resumen
│   │   ├── minigames/minigames_screen.dart
│   │   └── profile/profile_screen.dart
│   ├── widgets/
│   │   ├── fondo_app.dart            → Background existente del proyecto
│   │   ├── rut_input_field.dart
│   │   ├── crater_node.dart          → Nodo de cráter del mapa
│   │   ├── crater_preview_dialog.dart → Pop-up de ejercicios del nivel
│   │   ├── exercise_image.dart       → Imagen con placeholder por nombre
│   │   └── session_timer_widget.dart → Timer circular (serie / descanso)
│   └── providers/
│       ├── auth_provider.dart        → Estado login/logout/sesión
│       ├── exercise_provider.dart    → Mapa de cráteres + sorteo de rutinas
│       └── progress_provider.dart    → Registro + calificación + sync
├── utils/
│   ├── rut_validator.dart            → Validación RUT módulo 11
│   └── formatters.dart               → Fechas, duración, categorías
assets/images/
├── craters/      → fondo_espacio, crater_base, crater_1..7
├── mascota/      → alien, alien_calificacion
└── ejercicios/   → <id>.png (opcional; si falta → placeholder)
```

---

## 5. Sistema de Ejercicios

> **Actualizado (nov 2026).** Se retiró la sesión de 3 fases y la pantalla de
> configuración de tiempos. El perfilamiento y la evaluación funcional quedan
> **fuera de alcance por ahora**: el avance lo define el mapa de cráteres.

### Mapa de Cráteres (pantalla principal)

La pantalla principal es el mapa: **un cráter por nivel**.

- Se parte con el **cráter 1** abierto; completar un cráter abre el siguiente.
- Se muestran **4 cráteres**; los niveles 5-7 se revelan al superar esos cuatro.
- El avance se guarda local (`SharedPreferences`), sin backend ni evaluación.

### Dificultad por nivel

| Niveles | Dificultad | Ejercicios | Series | Trabajo | Descanso |
|---------|-----------|-----------|--------|---------|----------|
| 1-2 | Fácil | 3 | 2 | 60 s | 20 s |
| 3-5 | Medio | 4 | 2 | 60 s | 25 s |
| 6-7 | Difícil | 5 | 2 | 60 s | 30 s |

El descanso es **incremental según la dificultad** y aplica tanto entre series
como entre ejercicios. Los valores son fijos: el padre ya no los elige.

### Rutina (`RoutineModel`)

Lista plana de bloques: `serie (60 s) → descanso → serie → …`, sin descanso
final. La secuencia la arma `ExerciseSessionScreen`.

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

### Imágenes de ejercicios

Cada ejercicio tiene `imagenAsset`, por defecto
`assets/images/ejercicios/<id>.png`. Si el PNG no existe, `ExerciseImage`
muestra un **placeholder con el nombre** del ejercicio: basta dejar caer el
archivo con ese nombre para que aparezca, sin tocar código.

### Califica tu progreso

Al terminar el cráter, antes del resumen, `RatingScreen` pide **1 a 5
estrellas** en **desempeño**, **cansancio** y **motivación**. Se guarda junto
al progreso local (`sincronizado = false`) para enviarse al backend cuando
exista. Se puede saltar.

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
          ├── Cráter N → Pop-up de ejercicios → Sesión → Califica tu progreso → Resumen
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
| Imagen por ejercicio (placeholder de texto) | ✅ `ExerciseImage` + campo `imagenAsset` |
| Tiempos de 30 s → 1 minuto | ✅ `AppConstants.exerciseSeconds = 60` |
| Descanso de 20 s entre ejercicios | ✅ Piso del nivel fácil |
| Descansos incrementales por dificultad | ✅ 20 / 25 / 30 s |
| Randomizar al elegir cráter, sin repetir | ✅ Pools + registro persistido |
| Pop-up de ejercicios del nivel (Mario Party) | ✅ `CraterPreviewDialog` |
| 3 / 4 / 5 ejercicios × 2 series | ✅ `Dificultad.exerciseCount` |
| "Califica tu progreso" (1-5 estrellas × 3) | ✅ `RatingScreen` |

**Fuera de alcance por ahora:** "Matar al alien" (el alien queda solo como
mascota), perfilamiento y evaluación previa del niño.

### Retirado del código

- `session_model.dart` (sesión de 3 fases) → `routine_model.dart`
- `home_screen.dart`, `level_map_screen.dart` → `crater_map_screen.dart`
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
`test/routine_test.dart` cubre el mapeo nivel → dificultad, los tiempos y el
sorteo sin repetición (incluido el caso de pool agotado).

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
