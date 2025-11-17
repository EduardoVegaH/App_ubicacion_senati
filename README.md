# App Ubicación SENATI

Aplicación móvil para gestión de ubicación y servicios del campus SENATI.

## Funcionalidades

### Sistema de Estado de Baños

La aplicación incluye un sistema completo para gestionar el estado de los baños en tiempo real.

#### Características principales:

- **Vista para usuarios comunes**: Permite ver el estado de todos los baños organizados por piso
- **Vista para personal de limpieza**: Permite cambiar el estado de los baños (operativo, en limpieza, inoperativo)
- **Actualización en tiempo real**: Los cambios se reflejan inmediatamente usando Firebase Firestore
- **Estados disponibles**:
  - ✅ **Operativo**: Baño disponible para uso
  - 🚫 **En Limpieza**: Baño actualmente en proceso de limpieza
  - ⚠️ **Inoperativo**: Baño fuera de servicio

#### Estructura de datos en Firebase:

La colección `bathrooms` en Firestore almacena documentos con la siguiente estructura:

```json
{
  "nombre": "Baño Hombres 7mo Piso",
  "piso": 7,
  "estado": "operativo", // o "en_limpieza", "inoperativo"
  "tipo": "hombres", // opcional: "hombres", "mujeres", "mixto"
  "usuarioLimpiezaId": "uid_del_usuario",
  "usuarioLimpiezaNombre": "Nombre del usuario",
  "inicioLimpieza": Timestamp,
  "finLimpieza": Timestamp,
  "ultimaActualizacion": Timestamp
}
```

#### Inicialización de datos de ejemplo:

Para crear baños de ejemplo en Firebase, puedes usar el script de utilidad:

```dart
import 'package:your_app/utils/initialize_bathrooms.dart';

final initializer = BathroomInitializer();
await initializer.initializeSampleBathrooms();
```

O ejecutar manualmente desde la consola de Firebase agregando documentos a la colección `bathrooms`.

#### Uso:

1. **Para usuarios comunes**:
   - Accede a la vista de baños desde el botón "Baños" en la pantalla principal
   - Visualiza el estado de todos los baños organizados por piso
   - Los estados se actualizan automáticamente en tiempo real

2. **Para personal de limpieza**:
   - Accede a la vista de gestión de baños (puede agregarse un botón específico o acceso por rol)
   - Toca un baño para cambiar su estado
   - Selecciona el nuevo estado (Operativo, En Limpieza, Inoperativo)
   - El sistema registra automáticamente quién realizó el cambio y cuándo

#### Navegación:

- La vista de estado de baños está accesible desde el botón "Baños" en la pantalla principal (`StudentHomeScreen`)
- La vista de gestión está disponible en `BathroomManagementScreen` (puede integrarse con un sistema de roles)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
