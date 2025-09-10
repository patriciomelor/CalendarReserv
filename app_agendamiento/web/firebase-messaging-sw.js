// Scripts for firebase and firebase messaging
importScripts('[https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js](https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js)');
importScripts('[https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js](https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js)');

// Initialize the Firebase app in the service worker by passing in the
// messagingSenderId.
// NOTA: No necesitas cambiar nada aquí, Firebase lo configurará automáticamente.
firebase.initializeApp({
    apiKey: "api-key",
    authDomain: "project-id.firebaseapp.com",
    databaseURL: "[https://project-id.firebaseio.com](https://project-id.firebaseio.com)",
    projectId: "project-id",
    storageBucket: "project-id.appspot.com",
    messagingSenderId: "sender-id",
    appId: "app-id",
    measurementId: "G-measurement-id",
});


// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

// Si quieres manejar notificaciones en segundo plano, puedes añadir lógica aquí.
// Por ahora, lo dejamos así para que funcione por defecto.
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = 'Background Message Title';
  const notificationOptions = {
    body: 'Background Message body.',
    icon: '/flutter-logo.png'
  };

  self.registration.showNotification(notificationTitle,
    notificationOptions);
});