// Scripts for firebase and firebase messaging
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker with your project's configuration
firebase.initializeApp({
  apiKey: "AIzaSyCWn41yfy4LNG1hoBHVJlPWpA29F6b_7ww",
  appId: "1:994018420997:web:3cfb8ba107a564fa0baf6c",
  messagingSenderId: "994018420997",
  projectId: "appagendamiento-ddbd0",
  authDomain: "appagendamiento-ddbd0.firebaseapp.com",
  storageBucket: "appagendamiento-ddbd0.firebasestorage.app",
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

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
