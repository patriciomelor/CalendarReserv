# AgendApp - Sistema de Reservas para Salones

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)

**AgendApp** es una completa aplicación multiplataforma, desarrollada con Flutter y Firebase, diseñada para gestionar la reserva de citas en salones de belleza, barberías u otros negocios que requieran agendamiento. La plataforma está estructurada para soportar diferentes roles de usuario, cada uno con funcionalidades específicas para cubrir todas las necesidades del negocio.

---

## ✨ Funcionalidades Principales

El sistema se divide en varios módulos y funcionalidades según el rol del usuario.

### 👤 Rol: Super-Administrador
El Super-Administrador tiene el control total sobre la plataforma y es responsable de gestionar los salones clientes.

- **Gestión de Salones (CRUD):**
  - **Crear:** Registrar nuevos salones en la plataforma. Al crear un salón, se genera automáticamente una cuenta de administrador para ese salón con un correo y contraseña provisional.
  - **Leer:** Visualizar la lista completa de salones registrados.
  - **Actualizar:** Editar la información de los salones existentes.
  - **Eliminar:** Dar de baja salones de la plataforma.
- **Panel de Control Centralizado:** Una vista única para supervisar todos los salones clientes.

### 👨‍💼 Rol: Administrador de Salón
Cada salón tiene un administrador que gestiona las operaciones diarias de su propio negocio.

- **Gestión de Profesionales:** Añadir, editar o eliminar los perfiles de los profesionales que trabajan en el salón.
- **Gestión de Servicios:** Definir y administrar la lista de servicios que ofrece el salón, incluyendo nombres, duraciones y precios.
- **Agenda del Salón:** Visualizar todas las citas agendadas para todos los profesionales del salón en una vista de calendario unificada.
- **Configuración del Salón:** Ajustar detalles operativos como horarios de apertura y días laborables.

### ✂️ Rol: Profesional
Los profesionales tienen acceso a su propia agenda para gestionar su trabajo diario.

- **Visualización de Agenda Personal:** Acceder a una vista de calendario que muestra únicamente sus citas confirmadas, pendientes o canceladas.
- **Gestión de Citas:** Posibilidad de cancelar citas, lo que notifica automáticamente al cliente por correo electrónico.
- **Enlace de Reserva Público:** Copiar un enlace único para compartir con clientes, que les dirige a la página de reserva pública específicamente con ese profesional preseleccionado.

### 🧍 Rol: Cliente (Invitado o Registrado)
Los clientes pueden reservar citas de manera fácil e intuitiva a través de una interfaz web pública.

- **Flujo de Reserva Sencillo:**
  1.  **Seleccionar Salón:** Ver una lista de salones disponibles y elegir uno.
  2.  **Seleccionar Servicio:** Escoger el servicio deseado de la lista que ofrece el salón.
  3.  **Seleccionar Profesional:** Elegir con qué profesional desea ser atendido.
  4.  **Elegir Fecha y Hora:** Navegar por un calendario de disponibilidad y seleccionar un horario libre.
  5.  **Confirmar Reserva:** Ingresar datos básicos (nombre, correo) para confirmar la cita.
- **Autenticación Anónima:** Los clientes no necesitan crear una cuenta para reservar, ya que el sistema utiliza la autenticación anónima de Firebase para gestionar la sesión de invitado.
- **Notificaciones por Correo:** Recepción de correos electrónicos para confirmar o notificar cancelaciones de citas.

---

## 🚀 Tecnologías Utilizadas

- **Frontend (Multiplataforma):**
  - **Flutter:** Framework principal para construir la interfaz de usuario para web, iOS y Android desde una única base de código.
- **Backend y Base de Datos:**
  - **Firebase:** Plataforma integral de Google utilizada para:
    - **Firestore:** Base de datos NoSQL en tiempo real para almacenar toda la información (salones, usuarios, citas, etc.).
    - **Firebase Authentication:** Para gestionar la autenticación de usuarios por correo/contraseña y sesiones de invitados (anónimas).
    - **Cloud Functions for Firebase:** Para ejecutar lógica de backend, como el envío de notificaciones por correo electrónico tras la creación o cancelación de una cita.
- **Lenguajes de Programación:**
  - **Dart:** Lenguaje principal para el desarrollo en Flutter.
  - **JavaScript:** Utilizado para escribir las Cloud Functions en el entorno de Node.js.

---

## ⚙️ Primeros Pasos (Getting Started)

Para ejecutar este proyecto en tu entorno local, sigue estos pasos:

### Prerrequisitos
- Tener Flutter SDK instalado.
- Tener una cuenta de Firebase y un proyecto creado.
- Configurar el CLI de Firebase.

### Instalación
1.  **Clonar el repositorio:**
    ```sh
    git clone <URL_DEL_REPOSITORIO>
    cd CalendarReserv/app_agendamiento
    ```

2.  **Instalar dependencias de Flutter:**
    ```sh
    flutter pub get
    ```

3.  **Configurar Firebase:**
    - Sigue las instrucciones de la documentación de FlutterFire para conectar tu proyecto de Firebase con la aplicación en cada plataforma (Android, iOS, Web).
    - Asegúrate de colocar los archivos de configuración correspondientes (`google-services.json` para Android, `GoogleService-Info.plist` para iOS) en las carpetas correctas.
    - Habilita los servicios de **Firestore**, **Authentication** (con proveedores de Email/Contraseña y Anónimo) y **Cloud Functions** en tu consola de Firebase.

4.  **Desplegar Cloud Functions:**
    - Navega a la carpeta de funciones:
      ```sh
      cd functions
      ```
    - Instala las dependencias de Node.js:
      ```sh
      npm install
      ```
    - Despliega las funciones en tu proyecto de Firebase:
      ```sh
      firebase deploy --only functions
      ```

5.  **Ejecutar la aplicación:**
    ```sh
    flutter run
    ```

---

## 📂 Estructura del Proyecto

El proyecto está organizado de la siguiente manera para mantener una arquitectura limpia y escalable:

```
app_agendamiento/
├── lib/
│   ├── screens/       # Contiene todas las pantallas principales de la aplicación.
│   ├── widgets/       # Widgets reutilizables (botones, campos de texto, etc.).
│   ├── services/      # Lógica de servicios (ej. notificaciones).
│   └── main.dart      # Punto de entrada de la aplicación.
│
├── functions/         # Código de las Cloud Functions (backend).
│   ├── index.js       # Lógica principal de las funciones.
│   └── package.json   # Dependencias de las funciones.
│
├── android/           # Configuración específica de Android.
├── ios/               # Configuración específica de iOS.
└── web/               # Configuración específica para la web.
```