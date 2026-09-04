# 🤟 Deaf and Mute - Aprende LSN

> **Hackathon MINED El Rama 2026**  
> Aplicación web para el aprendizaje del Lenguaje de Señas Nicaragüense (LSN)

---

## 📋 Descripción

**Deaf and Mute** es una aplicación educativa desarrollada para apoyar el aprendizaje y la enseñanza del Lenguaje de Señas Nicaragüense. Facilita la comunicación de personas sordas y mudas, promoviendo la inclusión social y el uso de la tecnología educativa.

### Características principales
- 📖 **5 Niveles de aprendizaje**: Abecedario, Palabras Básicas, Frases, Conversaciones e Historias
- 🎯 **Más de 200 señas** con representaciones visuales
- 📝 **Evaluaciones interactivas** con seguimiento de progreso
- 🔊 **Sistema de audio** para usuarios con dificultades del habla
- 👤 **3 Roles de usuario**: Admin, Usuario y Auditor
- 📊 **Panel de progreso** personalizado
- 🖼️ **Galería de señas** consultable
- ♿ **Opciones de accesibilidad**: alto contraste y texto grande

---

## 🚀 Instalación y Ejecución Local

### Requisitos previos
- Navegador web moderno (Chrome, Firefox, Edge, Safari)
- [Opcional] Servidor local para pruebas (Live Server, Python, Node.js)

### Opción 1: Abrir directamente
1. Descarga o clona este repositorio
2. Haz doble clic en `index.html`
3. ¡Listo! La aplicación se abre en tu navegador

### Opción 2: Servidor local con Python
```bash
# Navega a la carpeta del proyecto
cd deaf-and-mute

# Python 3
python -m http.server 8000

# Abre en tu navegador
http://localhost:8000
```

### Opción 3: Servidor local con Node.js
```bash
# Instala http-server globalmente
npm install -g http-server

# Ejecuta
http-server -p 8000

# Abre en tu navegador
http://localhost:8000
```

### Opción 4: Extensión Live Server (VS Code)
1. Instala la extensión **Live Server** en VS Code
2. Abre el proyecto
3. Clic derecho en `index.html` → **Open with Live Server**

---

## 🗄️ Base de Datos

### Esquema relacional (2FN)
El proyecto incluye un modelo entidad-relación en **Segunda Forma Normal** con las siguientes tablas:

| Tabla | Descripción |
|-------|-------------|
| `roles` | Catálogo de roles (Admin, Usuario, Auditor) |
| `users` | Usuarios registrados con autenticación |
| `levels` | Niveles de aprendizaje (1-5) |
| `lessons` | Lecciones dentro de cada nivel |
| `signs` | Señas del vocabulario LSN |
| `progress` | Progreso de cada usuario por lección |
| `evaluations` | Evaluaciones asociadas a lecciones |
| `results` | Resultados de evaluaciones por usuario |
| `audit_logs` | Registro de auditoría para trazabilidad |

### Instalación de la base de datos (PostgreSQL)
```bash
# Crear base de datos
createdb deaf_mute_db

# Ejecutar el esquema
psql -d deaf_mute_db -f database_schema.sql
```

---

## 👥 Roles y Permisos

| Rol | Permisos |
|-----|----------|
| **Admin** | CRUD de usuarios, gestión de contenido, reportes, configuración del sistema |
| **Usuario** | Acceso a lecciones, práctica interactiva, evaluaciones, seguimiento de progreso |
| **Auditor** | Solo lectura de usuarios, reportes de progreso, logs de auditoría y actividad |

---

## 🛡️ Seguridad y Buenas Prácticas

- ✅ Contraseñas hasheadas con bcrypt (preparado para backend)
- ✅ Validación de formularios en cliente y servidor
- ✅ Control de acceso basado en roles (RBAC)
- ✅ Logs de auditoría automáticos
- ✅ Código modular y comentado
- ✅ Variables de entorno para configuración sensible
- ✅ Sanitización de inputs contra XSS

---

## 📁 Estructura del Proyecto

```
deaf-and-mute/
├── index.html              # Aplicación principal (frontend)
├── database_schema.sql     # Esquema de base de datos PostgreSQL
├── diagrama_er.png         # Diagrama Entidad-Relación
├── README.md               # Este archivo
├── docs/
│   ├── git_guide.md        # Guía de control de versiones
│   └── roles.md            # Documentación de roles y permisos
└── assets/
    ├── css/                # Estilos adicionales
    ├── js/                 # Scripts adicionales
    └── images/             # Imágenes de señas
```

---

## 🤝 Equipo

| Nombre | Rol |
|--------|-----|
| Melisa García | Desarrolladora |
| Jasnary Pilarte | Diseñadora / Documentación |
| Jasiel López | Desarrollador / Base de Datos |

**Institución:** Colegio Madre Guadalupe Caldera, El Rama, Nicaragua

---

## 📜 Licencia

Proyecto desarrollado para fines educativos en el marco del Hackathon MINED El Rama 2026.

© 2026 Deaf and Mute. Todos los derechos reservados.
