importScripts(
  "https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js",
);

firebase.initializeApp({
  apiKey: "AIzaSyDrmfReCLTrQqiORPrqazVYIgOZjtLXLVU",
  authDomain: "raihanhchnd.firebaseapp.com",
  projectId: "raihanhchnd",
  storageBucket: "raihanhchnd.firebasestorage.app",
  messagingSenderId: "89505330466",
  appId: "1:89505330466:web:d65b3e962e97043878617b",
  measurementId: "G-HPNJ51EPDS",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Background message:", payload);

  const notificationTitle = payload.notification?.title || "Notifikasi Baru";
  const notificationOptions = {
    body: payload.notification?.body || "Ada pesan baru.",
    icon: "/icons/Icon-192.png",
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  event.waitUntil(clients.openWindow("/"));
});
