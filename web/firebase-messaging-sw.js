importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyD5TE3bnLBpC2L0IjuLBWOoQ5D-Co3ADNU",
  authDomain: "sabo-96f81.firebaseapp.com",
  projectId: "sabo-96f81",
  storageBucket: "sabo-96f81.firebasestorage.app",
  messagingSenderId: "310909747679",
  appId: "1:310909747679:web:18da67c965d1812134c46a",
  measurementId: "G-5BYGST2XRB"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
