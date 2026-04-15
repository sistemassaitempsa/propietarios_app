# Documentación Técnica: Integración API + SQLite

Esta aplicación utiliza un **Patrón de Repositorio** para gestionar los datos. Esto permite que la app funcione tanto online (sincronizando con una API) como offline (usando una base de datos local SQLite).

## 1. Archivos Clave

| Archivo | Responsabilidad |
| :--- | :--- |
| `lib/api_service.dart` | Comunicación directa con el servidor (HTTP). Maneja el **Token de Autenticación**. |
| `lib/database_helper.dart` | Gestión de la base de datos local **SQLite**. Persistencia offline. |
| `lib/data_repository.dart` | **Cerebro de la lógica**. Decide si usar la API o la BD local y las sincroniza. |
| `pubspec.yaml` | Contiene las dependencias `http` y `shared_preferences`. |

---

## 2. Configuración de la API

Para conectar tu servidor real, abre `lib/api_service.dart` y modifica la variable:
```dart
final String baseUrl = "https://tu-api.com/api"; // Cambia esto por tu URL real
```

### Seguridad (Token)
El sistema guarda automáticamente el token en el dispositivo después del login exitoso. Todas las peticiones CRUD incluirán esta cabecera automáticamente:
`Authorization: Bearer <tu_token>`

---

## 3. Guía de Uso en la Interfaz (UI)

Para usar la conexión a la API en tus pantallas, sigue estos ejemplos:

### Iniciar Sesión (Login)
En tu `login_page.dart`, usa el repositorio para validar las credenciales:
```dart
final repository = DataRepository();

void _handleLogin() async {
  var user = await repository.login(emailController.text, passwordController.text);
  if (user != null) {
    // Éxito: El token se guardó y los datos se sincronizaron localmente.
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    // Error: Mostrar mensaje al usuario.
  }
}
```

### Actualizar Perfil
```dart
final repository = DataRepository();

void _updateData() async {
  bool success = await repository.updateProfile(userId, email, {
    'firstName': 'Juan',
    'phone': '123456789'
  });
  
  if (success) {
    // Se actualizó en la nube y en la base de datos local.
  }
}
```

### Cerrar Sesión (Logout)
```dart
final repository = DataRepository();

void _onLogout() async {
  await repository.logout();
  // El token se borró, pero los datos locales se mantienen para consulta offline.
  Navigator.pushReplacementNamed(context, '/login');
}
```

---

## 4. Consideraciones Técnicas

1.  **Sincronización**: Al hacer login, el sistema descarga los datos de la API y actualiza la base de datos local (`sqflite`).
2.  **Modo Offline**: Si el usuario intenta loguearse sin internet, el `DataRepository` consultará la contraseña guardada localmente para permitir el acceso.
3.  **Formato de Respuesta API**: El sistema espera que el login devuelva un JSON con un campo `token` o `access_token`. Ejemplo:
    ```json
    {
      "id": 1,
      "email": "user@example.com",
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6..."
    }
    ```

---
*Documento generado automáticamente para la integración del CRUD y Auth.*
