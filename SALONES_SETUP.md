# Configuración de Salones en Firebase

Este documento explica cómo inicializar la base de datos de salones en Firebase Firestore para que la aplicación pueda trabajar con datos reales.

## 📋 Requisitos Previos

- Firebase configurado en el proyecto
- Acceso a Firebase Console o permisos para escribir en Firestore
- La aplicación debe tener `cloud_firestore` configurado

## 🚀 Inicialización de Salones

### Opción 1: Desde la Aplicación (Recomendado)

1. Abre la aplicación en tu dispositivo/emulador
2. Abre el menú lateral (drawer)
3. Selecciona **"Administración de Salones"**
4. Toca el botón **"Inicializar Salones en Firebase"**
5. Espera a que se complete la inicialización
6. Verás un mensaje de confirmación cuando termine

### Opción 2: Desde el Código

Puedes inicializar los salones programáticamente:

```dart
import 'package:your_app/utils/initialize_salones.dart';

final initializer = SalonesInitializer();
await initializer.initializeSalones();
```

## 📊 Estructura de Datos

Cada salón en Firestore tiene la siguiente estructura:

```json
{
  "id": "salon-A-201",
  "nombre": "Salón A-201",
  "piso": 2,
  "torre": "A",
  "x": 100.0,
  "y": 500.0,
  "conexiones": ["pasillo-A-2", "salon-A-202"],
  "tipo": "aula",
  "capacidad": 35,
  "descripcion": "Aula de clases generales",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### Campos:

- **id**: Identificador único del salón (usado como ID del documento)
- **nombre**: Nombre descriptivo del salón
- **piso**: Número de piso (1, 2, 3, etc.)
- **torre**: Torre a la que pertenece (A, B, C, etc.)
- **x**: Coordenada X en el sistema de coordenadas del mapa
- **y**: Coordenada Y en el sistema de coordenadas del mapa
- **conexiones**: Lista de IDs de nodos conectados (pasillos, escaleras, otros salones)
- **tipo**: Tipo de espacio (aula, laboratorio, pasillo, escaleras, entrada, etc.)
- **capacidad**: Capacidad del salón (opcional, null para pasillos/escaleras)
- **descripcion**: Descripción adicional del salón

## 🗺️ Salones Incluidos

La inicialización crea salones para:

### Torre A
- **Piso 1**: Salones A-101, A-102, A-103
- **Piso 2**: Salones A-201, A-202, A-203
- **Piso 3**: Salones A-301, A-302, A-303 (Laboratorios)

### Torre B
- **Piso 1**: Salones B-101, B-102, B-103
- **Piso 2**: Salones B-201, B-202, B-203

### Torre C
- **Piso 1**: Salones C-101, C-102, C-103
- **Piso 2**: Salones C-201, C-202, C-203

### Infraestructura
- Pasillos principales por piso
- Escaleras entre pisos
- Conexiones entre torres
- Punto inicial de navegación

## 🔄 Actualización de Datos

### Limpiar Todos los Salones

⚠️ **ADVERTENCIA**: Esto eliminará TODOS los salones de Firebase.

1. Abre "Administración de Salones" desde el menú
2. Toca "Limpiar Todos los Salones"
3. Confirma la acción

### Actualizar un Salón Específico

Puedes actualizar salones directamente desde Firebase Console o mediante código:

```dart
final firestore = FirebaseFirestore.instance;
await firestore.collection('salones').doc('salon-A-201').update({
  'capacidad': 40,
  'updatedAt': FieldValue.serverTimestamp(),
});
```

## 🔍 Verificación

Para verificar que los salones se crearon correctamente:

1. Abre Firebase Console
2. Ve a Firestore Database
3. Busca la colección `salones`
4. Deberías ver todos los documentos creados

## 📱 Uso en la Aplicación

Una vez inicializados, los salones se cargarán automáticamente en:

- **Pantalla de Navegación**: Al abrir la navegación en tiempo real
- **Chatbot**: El chatbot puede responder preguntas sobre salones
- **Cálculo de Rutas**: El algoritmo de Dijkstra usa estos datos para calcular rutas

## 🛠️ Solución de Problemas

### Los salones no se cargan

1. Verifica que Firebase esté configurado correctamente
2. Verifica que la colección `salones` exista en Firestore
3. Verifica los permisos de lectura en Firestore Rules

### Error al inicializar

- Verifica tu conexión a internet
- Verifica que tengas permisos de escritura en Firestore
- Revisa la consola de Firebase para ver errores específicos

### Los salones no aparecen en el mapa

- Verifica que las coordenadas (x, y) sean correctas
- Verifica que el mapa SVG tenga los elementos con los IDs correctos
- Revisa la consola para ver errores de carga

## 📝 Notas

- Los salones se cargan desde Firestore primero
- Si Firestore está vacío, la app intenta cargar desde `assets/nodos_mapa.json`
- Si no existe el archivo JSON, se usan nodos de ejemplo
- Los cambios en Firestore se reflejan en tiempo real si usas `escucharDesdeFirestore()`

## 🔐 Permisos de Firestore

Asegúrate de que tus reglas de Firestore permitan lectura y escritura:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /salones/{document=**} {
      allow read: if true;
      allow write: if request.auth != null; // Solo usuarios autenticados pueden escribir
    }
  }
}
```

