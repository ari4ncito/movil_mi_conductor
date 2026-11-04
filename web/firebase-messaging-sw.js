importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyC0GVYe6znMuGB5hXfO2MXiTHhnGcRzFFU",
  authDomain: "mi-conductor-d8cf2.firebaseapp.com",
  projectId: "mi-conductor-d8cf2",
  storageBucket: "mi-conductor-d8cf2.firebasestorage.app",
  messagingSenderId: "641245801833",
  appId: "1:641245801833:web:5f3f9375cdf7f3ace861f8"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Mensaje en segundo plano recibido: ", payload);
  const notificationTitle = payload.notification ? payload.notification.title : (payload.data ? payload.data.titulo : "Mi Conductor");
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : (payload.data ? payload.data.mensaje : ""),
    icon: "/icons/Icon-192.png",
    data: payload.data || {}
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

