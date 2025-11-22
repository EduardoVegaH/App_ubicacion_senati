# 🚀 **ARQUITECTURA ESTÁNDAR (Feature-Based + Clean Architecture)**

La estructura recomendada es esta:

```
lib/
│
├── app/
│   ├── routes/
│   ├── theme/
│   ├── di/ (opcional - inyección de dependencias)
│   └── app.dart
│
├── core/
│   ├── errors/
│   ├── utils/
│   ├── constants/
│   ├── services/
│   └── widgets/
│
└── features/
    ├── feature_name/
    │   ├── presentation/
    │   │   ├── pages/
    │   │   ├── widgets/
    │   │   ├── controllers/ (o blocs, providers…)
    │   │   └── states/
    │   │
    │   ├── domain/
    │   │   ├── entities/
    │   │   ├── repositories/
    │   │   └── usecases/
    │   │
    │   ├── data/
    │   │   ├── datasources/
    │   │   ├── models/
    │   │   └── repositories_impl/
    │   │
    │   └── feature_name.dart
    │
    ├── another_feature/
    └── [...]
│
├── main.dart
└── firebase_options.dart (si usas Firebase)
```

---

# 🧩 **¿QUÉ VA EN CADA CARPETA? (EXPLICADO)**

---

# 📁 **/app**

Contiene lo que afecta a TODA la aplicación.

### ✔ `/app/routes/`

* Rutas de la aplicación
* Generador de rutas
* Route names

Ej:

```
app_routes.dart
route_names.dart
```

### ✔ `/app/theme/`

* Colores globales
* Tipografías
* Temas light/dark

Ej:

```
app_theme.dart
color_schemes.dart
```

### ✔ `/app/di/` *(opcional)*

* Inyección de dependencias (GetIt o Riverpod)
* Registrar repositorios, controladores, servicios

### ✔ `/app/app.dart`

* Widget principal con MaterialApp
* Configuración inicial de la app

---

# 📁 **/core**

Todo lo que es **reutilizable por varios features**.

### ✔ `/core/errors/`

* Manejo de errores
* Excepciones globales
* Failure classes

Ej:

```
server_failure.dart
not_found_failure.dart
exception_messages.dart
```

### ✔ `/core/utils/`

Utilidades genéricas:

* Convertidores
* Extensiones
* Matemática
* Validadores
* Formatters

Ej:

```
date_formatter.dart
validators.dart
math_utils.dart
```

### ✔ `/core/constants/`

Valores globales:

```
app_strings.dart
app_colors.dart
api_endpoints.dart
```

### ✔ `/core/services/`

Servicios globales que NO pertenecen a un feature:

* LocalStorage
* GPS
* Sensores (acelerómetro, magnetómetro)
* NetworkService
* FirebaseService

Ej:

```
gps_service.dart
sensors_service.dart
permissions_service.dart
```

### ✔ `/core/widgets/`

Widgets reutilizables en toda la app:

* CustomButton
* Loader
* Card genérico
* AppBar custom

---

# 📁 **/features**

Cada **funcionalidad completa** vive aquí.

Ejemplos:

```
auth/
chat/
navigation/
map/
friends/
bathrooms/
home/
```

Cada feature contiene **3 capas** (Clean Architecture):

---

# 🧱 **CAPA 1: presentation/**

Solo UI + lógica de interfaz.

```
presentation/
    pages/
    widgets/
    controllers/  (o blocs, providers)
    states/
```

### Qué va aquí:

✔ Pantallas
✔ Widgets
✔ Estado (Provider, Bloc, MobX, Riverpod…)
✔ Controladores de UI
✔ Animaciones

**NO van servicios ni lógica de negocio aquí.**

---

# 🧱 **CAPA 2: domain/**

Es lo más **puro, sin dependencias externas**.

```
domain/
    entities/
    repositories/
    usecases/
```

### Qué va aquí:

✔ Entidades (modelo puro sin JSON)
✔ Casos de uso (reglas del negocio)
✔ Definición de repositorios (interfaces)

Ejemplo de caso de uso:

```
GetUserLocation()
LoginUser()
CalculateRoute()
```

---

# 🧱 **CAPA 3: data/**

Manejo de datos reales.

```
data/
    datasources/
    models/
    repositories_impl/
```

### Qué va aquí:

✔ Modelos que transforman JSON 🔄 Entities
✔ Conexión a Firebase, REST API o base local
✔ Implementación de los repositorios del domain

Ejemplo:

```
navigation_repository_impl.dart
bathroom_remote_datasource.dart
user_model.dart
```

---

# 🏁 **main.dart**

Aquí solo se hace:

* runApp()
* Inicialización de Firebase
* Inicialización de DI
* Seteo del `App()`

---

# ⭐ RESUMEN CLARO

### ✔ UI → `presentation/`

### ✔ Lógica → `domain/`

### ✔ Datos → `data/`

### ✔ Reutilizable → `core/`

### ✔ Config global → `app/`

### ✔ Cada “feature” tiene sus propias carpetas

---
