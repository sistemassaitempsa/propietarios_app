# Residencial App 🏠🚗

Una aplicación Flutter para la gestión de residentes y vehículos en conjuntos residenciales, diseñada para facilitar la comunicación en caso de bloqueos de parqueadero.

## ✨ Características Principales

- **Gestión de Perfil:** Los residentes pueden registrar sus datos personales, dirección (Unidad, Torre, Apartamento) y foto de perfil tomada directamente desde la cámara.
- **Contactos de Emergencia:** Módulo para agregar múltiples contactos que serán notificados en caso de problemas con un vehículo.
- **Gestión de Vehículos:** Registro de carros y motos asociados a un contacto de emergencia específico.
- **Consulta de Placas:** Módulo de seguridad que permite buscar un vehículo por su placa para obtener rápidamente el contacto del propietario y llamarlo o escribirle por WhatsApp.

## 📱 Capturas de Pantalla (Próximamente)
*(Aquí puedes añadir imágenes de la app)*

---

## 🗄️ Documentación de la Base de Datos

La aplicación utiliza **SQLite** para el almacenamiento local de datos, garantizando rapidez y persistencia sin necesidad de conexión constante a internet.

### Estructura de Tablas (ER)

#### 1. Tabla: `users` (Residentes)
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `id` | INTEGER | Clave primaria autoincremental. |
| `email` | TEXT | Correo electrónico (Único). |
| `password` | TEXT | Contraseña de acceso. |
| `firstName` | TEXT | Nombres del residente. |
| `lastName` | TEXT | Apellidos del residente. |
| `phone` | TEXT | Teléfono principal. |
| `unit` | TEXT | Conjunto residencial. |
| `tower` | TEXT | Torre / Bloque. |
| `apartment` | TEXT | Número de apto. |
| `profileImagePath`| TEXT | Ruta local de la foto de perfil. |

#### 2. Tabla: `emergency_contacts`
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `id` | INTEGER | Clave primaria. |
| `user_id` | INTEGER | Relación con el usuario (FK). |
| `name` | TEXT | Nombre del contacto. |
| `phone` | TEXT | Teléfono de contacto. |
| `has_whatsapp` | INTEGER | Indica si tiene WhatsApp (0/1). |

#### 3. Tabla: `vehicles`
| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `id` | INTEGER | Clave primaria. |
| `user_id` | INTEGER | Propietario (FK). |
| `type` | TEXT | Tipo ('Carro' o 'Moto'). |
| `brand` | TEXT | Marca del vehículo. |
| `color` | TEXT | Color. |
| `plate` | TEXT | Placa (Normalizada en MAYÚSCULAS). |
| `emergency_contact_id`| INTEGER | Contacto asignado (FK). |

### Historial de Versiones (Versión Actual: 7)
- **v7:** Soporte para fotos de perfil desde cámara.
- **v6:** Soporte para indicación de WhatsApp en contactos.
- **v5:** Migración a sistema multi-contacto y vinculación de vehículos.

---

## 🛠️ Tecnologías y Dependencias

- **Flutter SDK:** ^3.11.4
- **sqflite:** Para la gestión de base de datos local.
- **image_picker:** Para la captura de fotos con la cámara.
- **url_launcher:** Para llamadas telefónicas y apertura de WhatsApp.
- **path_provider:** Para la gestión de rutas de archivos internos.

## 🚀 Cómo Ejecutar el Proyecto

1. Clona este repositorio.
2. Asegúrate de tener Flutter instalado y configurado.
3. Ejecuta los siguientes comandos en la terminal:

```bash
flutter pub get
flutter run
```

---

## ⚖️ Licencia
Este proyecto es de uso libre bajo la licencia MIT.
