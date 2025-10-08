// web/firebase-messaging-sw.js

importScripts(
  "https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyCWn41yfy4LNG1hoBHVJlPWpA29F6b_7ww",
  authDomain: "appagendamiento-ddbd0.firebaseapp.com",
  projectId: "appagendamiento-ddbd0",
  storageBucket: "appagendamiento-ddbd0.firebasestorage.app",
  messagingSenderId: "994018420997",
  appId: "1:994018420997:web:3cfb8ba107a564fa0baf6c",
});

const messaging = firebase.messaging();

// Manejar notificaciones cuando la app está en segundo plano
messaging.onBackgroundMessage((payload) => {
  console.log('🔔 Notificación recibida en segundo plano:', payload);

  const notificationTitle = payload.notification?.title || 'Nueva notificación';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png', // Ícono de tu app
    badge: '/icons/Icon-192.png',
    tag: 'agendamiento-notification',
    requireInteraction: false, // Se cierra automáticamente
    data: payload.data, // Datos adicionales
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

// Manejar clics en las notificaciones
self.addEventListener('notificationclick', (event) => {
  console.log('🖱️ Usuario hizo clic en la notificación');
  
  event.notification.close(); // Cerrar la notificación

  // Abrir o enfocar la ventana de la app
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Si ya hay una ventana abierta, enfocarla
      for (let client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Si no hay ventana abierta, abrir una nueva
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

console.log('✅ Service Worker de Firebase Messaging cargado correctamente');