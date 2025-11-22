# 🔥 **1. PROBLEMA PRINCIPAL DE TU ARQUITECTURA ACTUAL**

En tu estructura actual veo:

```
features/
│
├── auth/
├── bathrooms/
├── chatbot/
├── friends/
├── home/
├── navigation/
│
models/
services/
ui/
```

### ❌ Problemas identificados:

* **models/** está suelto → muy mal para escalabilidad.
* **services/** mezclados → deben dividirse por feature.
* **ui/** comiéndose partes de features → rompe el encapsulamiento.
* **home** aparece dos veces: una en features y otra dentro de ui/home → duplicación.
* Algunas cosas deberían estar en `/core`.

---

# 🚀 **2. ARQUITECTURA FINAL IDEAL (REFACTORIZADA)**

Esta es la estructura final que recomiendo y usaré:

```
lib/
│
├── app/
│   ├── routes/
│   ├── theme/
│   ├── di/
│   └── app.dart
│
├── core/
│   ├── utils/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   └── widgets/
│
└── features/
    ├── auth/
    │   ├── presentation/
    │   ├── data/
    │   ├── domain/
    │   └── models/
    │
    ├── bathrooms/
    ├── chatbot/
    ├── friends/
    ├── home/
    ├── navigation/
    │
    └── [...]
│
└── main.dart
```

---

# 🎯 **3. CÓMO MOVER LOS ARCHIVOS QUE YA EXISTEN**

Voy a tomar lo que tú tienes y decirte exactamente dónde debe ir.

---

# 📁 **A. Carpeta /models (actual)**

Contiene:

```
friend_model.dart
student_model.dart
user_model.dart
```

### ✔ REFACCIÓN:

Cada uno debe ir dentro de **su feature**:

| Archivo              | Nueva ubicación                                                       |
| -------------------- | --------------------------------------------------------------------- |
| `friend_model.dart`  | `features/friends/data/models/`                                       |
| `student_model.dart` | `features/auth/data/models/` o `features/home/data/models/` según uso |
| `user_model.dart`    | `features/auth/data/models/`                                          |

📌 **La carpeta `/models` debe eliminarse completamente.**

---

# 📁 **B. Carpeta /services (actual)**

Contiene:

```
auth_service.dart
chatbot_service.dart
firebase_service.dart
friends_service.dart
location_service.dart
notification_service.dart
```

### ✔ REFACCIÓN:

| Servicio                    | Nueva ubicación                      |
| --------------------------- | ------------------------------------ |
| `auth_service.dart`         | `features/auth/data/datasources/`    |
| `chatbot_service.dart`      | `features/chatbot/data/datasources/` |
| `friends_service.dart`      | `features/friends/data/datasources/` |
| `location_service.dart`     | ❗ **Si es GPS → core/services**      |
| `firebase_service.dart`     | `core/services/firebase/`            |
| `notification_service.dart` | `core/services/notifications/`       |

📌 **La carpeta /services se elimina** (porque ya no tendrá nada suelto).

---

# 📁 **C. Carpeta /ui (actual)**

Dentro tienes:

```
ui/
 ├── home/
 └── login/
 └── widgets/
```

### ❌ Problemas:

* La UI de cada feature debe vivir dentro de ese feature.
* /ui es un “basurero común”.

### ✔ REFACCIÓN:

| Carpeta/archivo | Nueva ubicación                                     |
| --------------- | --------------------------------------------------- |
| `ui/login`      | `features/auth/presentation/pages/login/`           |
| `ui/home`       | `features/home/presentation/pages/`                 |
| `ui/widgets`    | `core/widgets/` → solo si son widgets reutilizables |

📌 **La carpeta /ui debe eliminarse.**

---

# 📁 **D. Carpeta /utils**

Esta sí está bien estructurada.

👉 Se queda dentro de **core**:

```
lib/core/utils/
```

Si no está allí aún, muévela.

---

# 📁 **E. features/auth, features/home, etc.**

Estas carpetas están bien pero deben organizarse internamente así:

```
auth/
 ├── presentation/
 │   ├── pages/
 │   ├── widgets/
 │   └── controllers/
 ├── domain/
 │   ├── entities/
 │   ├── repositories/
 │   └── usecases/
 ├── data/
 │   ├── datasources/
 │   ├── models/
 │   └── repositories_impl/
```

---

# 🧨 **4. ARCHITECTURE FINAL YA APLICADA A TU PROYECTO**

Después de mover tus archivos, tu proyecto debe quedar así:

```
lib/
│
├── app/
│   ├── routes/
│   ├── theme/
│   ├── di/
│   └── app.dart
│
├── core/
│   ├── utils/
│   ├── errors/
│   ├── constants/
│   ├── services/
│   │    ├── firebase/
│   │    ├── notifications/
│   │    └── location/
│   └── widgets/
│
└── features/
    ├── auth/
    │   ├── presentation/
    │   ├── data/
    │   │   ├── datasources/auth_service.dart
    │   │   ├── models/user_model.dart
    │   │   └── repositories_impl/
    │   ├── domain/
    │   └── models/student_model.dart
    │
    ├── friends/
    │   ├── data/
    │   │   ├── datasources/friends_service.dart
    │   │   ├── models/friend_model.dart
    │   └── presentation/
    │
    ├── chatbot/
    │   └── data/datasources/chatbot_service.dart
    │
    ├── navigation/
    │   └── (tu mapa, sensores, rutas indoor)
    │
    ├── home/
    │   └── presentation/pages/
│
└── main.dart
```

---
