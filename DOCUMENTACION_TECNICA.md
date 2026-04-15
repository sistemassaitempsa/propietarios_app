# Documentación Técnica: Integración API + SQLite

Esta aplicación utiliza un **Patrón de Repositorio** para gestionar los datos de forma híbrida (Online/Offline).

## 1. Archivos Clave

| Archivo | Responsabilidad |
| :--- | :--- |
| `lib/api_service.dart` | Comunicación directa con el servidor (Laravel). Maneja el **Token JWT**. |
| `lib/database_helper.dart` | Gestión de la base de datos local **SQLite**. Persistencia offline. |
| `lib/data_repository.dart` | Orquestador de la sincronización entre API y SQLite. |

---

## 2. Configuración de la API

El endpoint del servidor se configura de manera centralizada en `lib/api_service.dart`:
```dart
static const String baseUrl = "http://10.0.2.2:8000/api"; 
```
*   **Emulador Android:** Usar `10.0.2.2`.
*   **Dispositivo Físico:** Usar la IP local de tu PC (ej: `192.168.1.x`).
*   **Producción:** Usar tu dominio HTTPS.

---

## 3. Endpoints Utilizados

| Acción | Método | Ruta |
| :--- | :--- | :--- |
| Registro | POST | `/users/register` |
| Login | POST | `/users/login` |
| Perfil | GET | `/users/{id}` |
| Actualizar | PUT | `/users/{id}` |
| Subir Foto | POST | `/users/{id}/upload-image` |
| Contactos | GET | `/emergency-contacts?user_id={id}` |
| Vehículos | GET | `/vehicles?user_id={id}` |
| Buscar Placa| GET | `/search/plate/{plate}` |

---

## 4. Gestión de Archivos (Fotos de Perfil)

Cuando el usuario sube una foto:
1.  Se captura con `image_picker`.
2.  Se envía a la API mediante un `MultipartRequest`.
3.  El servidor la guarda en `public/uploads/{user_id}/`.
4.  La API retorna la URL pública que se guarda en SQLite para visualización rápida.

---

## 5. Seguridad

- Se utiliza **JWT (JSON Web Tokens)** para proteger las rutas de la API.
- El token se guarda en `shared_preferences` y se adjunta automáticamente en las cabeceras `Authorization: Bearer <token>`.

---
*Documento generado automáticamente para la arquitectura de sincronización.*
