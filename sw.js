const CACHE_NAME = 'deaf-mute-cache';
const urlsToCache = [
    './',
    './index.html',
    './logo1.jpeg'
];

// 1. Instalación e inicialización
self.addEventListener('install', event => {
    self.skipWaiting(); // Obliga al nuevo Service Worker a activarse de inmediato
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => cache.addAll(urlsToCache))
    );
});

// 2. Activación y toma de control
self.addEventListener('activate', event => {
    event.waitUntil(
        clients.claim() // Toma control inmediato de todas las pestañas abiertas
    );
});

// 3. Estrategia Network First (Red primero, respaldo en caché)
self.addEventListener('fetch', event => {
    // Solo procesar peticiones HTTP/HTTPS
    if (!event.request.url.startsWith('http')) return;

    event.respondWith(
        fetch(event.request)
            .then(networkResponse => {
                // Si hay internet y la respuesta es válida, actualizamos la caché
                if (networkResponse && networkResponse.status === 200) {
                    const responseClone = networkResponse.clone();
                    caches.open(CACHE_NAME).then(cache => {
                        cache.put(event.request, responseClone);
                    });
                }
                return networkResponse;
            })
            .catch(() => {
                // Si NO hay internet (offline), servir desde la caché
                return caches.match(event.request);
            })
    );
});