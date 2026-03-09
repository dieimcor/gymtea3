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
│   ├── constants/app_constants.dart   → URLs API, duraciones, keys
│   ├── theme/app_theme.dart          → ThemeData dark + colores por categoría
│   ├── network/api_client.dart       → HTTP client centralizado con JWT
│   └── errors/exceptions.dart        → AuthException, NetworkException, etc.
├── data/
│   ├── models/
│   │   ├── user_model.dart           → Padre (RUT, email, rol)
│   │   ├── child_model.dart          → Niño (condición, control motor, nivel)
│   │   ├── evaluation_model.dart     → Rúbrica 5 ejercicios, cálculo nivel
│   │   ├── exercise_model.dart       → Ejercicio + categoría + nivel + fase
│   │   ├── session_model.dart        → Sesión 3 fases (15 min)
│   │   └── progress_model.dart       → Progreso + flag sincronizado
│   ├── repositories/
│   │   ├── auth_repository.dart      → Login RUT + JWT + session
│   │   ├── exercise_repository.dart  → Ejercicios por nivel (mock → API)
│   │   └── progress_repository.dart  → Cache local + sync backend
│   ├── datasources/
│   │   ├── local/exercise_local_ds.dart   → SQLite (Sprint 3)
│   │   └── remote/exercise_remote_ds.dart → API REST (Sprint 4+)
│   └── services/
│       ├── auth_service.dart         → Lógica auth (mock → API)
│       └── storage_service.dart      → Token seguro + SharedPreferences
├── presentation/
│   ├── screens/
│   │   ├── splash/splash_screen.dart
│   │   ├── auth/login_screen.dart
│   │   ├── home/home_screen.dart
│   │   ├── exercises/
│   │   │   ├── level_map_screen.dart
│   │   │   └── exercise_session_screen.dart
│   │   ├── minigames/minigames_screen.dart
│   │   └── profile/profile_screen.dart
│   ├── widgets/
│   │   ├── fondo_app.dart            → Background existente del proyecto
│   │   ├── rut_input_field.dart
│   │   └── session_timer_widget.dart
│   └── providers/
│       ├── auth_provider.dart        → Estado login/logout/sesión
│       ├── exercise_provider.dart    → Ejercicios por nivel y categoría
│       └── progress_provider.dart    → Registro + sync progreso
└── utils/
    ├── rut_validator.dart            → Validación RUT módulo 11
    └── formatters.dart               → Fechas, duración, categorías
```

---

## 5. Sistema de Ejercicios

### Evaluación Funcional (5 ejercicios, puntaje 1-4 cada uno)
1. Sentadilla de arranque → Flexión rodilla/cadera
2. Bisagra de cadera → Activación cadera
3. Lanzamiento balón medicinal → Fuerza desde rodillas
4. Arrastre de corebag → Jalón + estabilidad
5. Superman → Core + extensión

### Clasificación Control Motor
| Puntaje Total | Clasificación |
|--------------|---------------|
| 5-10 | BAJO |
| 11-15 | MODERADO |
| 16-20 | ALTO (+1 al promedio) |

**Cálculo nivel:** `Promedio = Total ÷ 5` → redondeado → Si ALTO, sumar +1 → Nivel inicial (1-7)

### Tabla de Progresión (7 niveles × 5 categorías = 35 ejercicios)

| Categoría | Código | Ejemplo Nivel 1 |
|-----------|--------|-----------------|
| Rodilla Dominante | RD | Pararse/sentarse de banco |
| Cadera Dominante | CD | Puente glúteo dinámico |
| Empuje | EM | Empuje balón medicinal acostado |
| Jalón | JL | Remo al pecho elástico 2 manos |
| Core | CR | Extensiones tronco 1 brazo |
| *(nuevas)* | *Backend* | *Se agregan sin tocar la app* |

### Estructura de Sesión (15 minutos — AMRAP adaptado)
| Fase | Duración | Detalle |
|------|----------|---------|
| Activación | 2 min | 5 ejercicios neuromuscular, 2×15 reps |
| Fortalecimiento | 8 min | 5 ejercicios (1 por categoría), 3×10 reps |
| Juego | 5 min | Circuito o juego de fuerza |

---

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
  NO → Login (RUT + pass) → Home
  SÍ → Home
          ├── Ejercicios → Mapa 7 Niveles → Sesión Activa (3 fases) → Resumen
          ├── Minijuegos → Lista → Juego Activo
          └── Perfil → Info padre + niño · Cerrar sesión
```

---

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

## 14. Estado Actual (Sprint 0 — Completado)

### Archivos creados
- **Core:** `app_constants.dart`, `app_theme.dart`, `api_client.dart`, `exceptions.dart`
- **Models:** 6 modelos con JSON serialization y enums
- **Repos:** `auth_repository.dart`, `exercise_repository.dart` (con mock data niveles 1-2), `progress_repository.dart`
- **Services:** `auth_service.dart` (mock), `storage_service.dart`
- **DataSources:** Placeholders para SQLite y API
- **Providers:** `auth_provider.dart`, `exercise_provider.dart`, `progress_provider.dart`
- **Utils:** `rut_validator.dart` (módulo 11), `formatters.dart`
- **App:** `app.dart` con MultiProvider

### Dependencias activas (pubspec.yaml)
```yaml
provider: ^6.1.1
http: ^1.1.0
flutter_secure_storage: ^9.0.0
sqflite: ^2.3.0
connectivity_plus: ^5.0.2
intl: ^0.19.0
shared_preferences: ^2.2.2
```

### Dependencias comentadas (Firebase)
```yaml
# firebase_core: ^3.8.1
# firebase_auth: ^5.4.1
# google_sign_in: ^6.2.2
```

### .gitignore
- `Manual Ejercicios/` y PDFs/DOCs del manual
- `docs/` (informes técnicos locales)

---

## 15. Decisiones de Diseño

1. **Offline-first:** La app funciona sin conexión, sincroniza cuando puede
2. **RUT como login:** Reemplaza Firebase Auth, más natural para el contexto chileno
3. **Firebase comentado:** No eliminado, por si se necesita reactivar
4. **Mock data primero:** Repositorios con datos mock hasta tener backend
5. **Psicopedagogo decide:** La IA sugiere, nunca impone
6. **Minijuegos sin sync:** No envían datos al backend, son locales
7. **Sesiones de 15 min:** Formato AMRAP adaptado para niños
8. **Progresión por nivel:** 7 niveles × 5 categorías × 3 fases de sesión
9. **Informe al padre solo mensual:** No sobrecargar con datos diarios
10. **Tema oscuro:** Definido en `app_theme.dart` con colores por categoría de ejercicio
