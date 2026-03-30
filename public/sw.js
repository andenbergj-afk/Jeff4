const STATIC_CACHE = 'focus-static-v3';
const DYNAMIC_CACHE = 'focus-dynamic-v3';

// Essential assets to cache on install (Cache-First strategy)
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing...');
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => {
        console.log('[Service Worker] Caching static assets');
        // Use individual adds so one failing (CDN) doesn't block the rest
        return Promise.allSettled(
          STATIC_ASSETS.map(url => cache.add(url).catch(err => console.warn('[SW] Could not cache', url, err)))
        );
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cache) => {
          if (cache !== STATIC_CACHE && cache !== DYNAMIC_CACHE) {
            console.log('[Service Worker] Deleting old cache:', cache);
            return caches.delete(cache);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - Cache-First for static assets, Network-First for navigation
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests and browser-extension requests
  if (request.method !== 'GET' || url.protocol === 'chrome-extension:') {
    return;
  }

  // Cacheable file extensions
  const CACHEABLE_EXTENSIONS = new Set([
    '.js', '.css', '.png', '.jpg', '.jpeg',
    '.svg', '.gif', '.webp', '.woff', '.woff2', '.ttf', '.ico'
  ]);

  const shouldCache = (pathname) => {
    return Array.from(CACHEABLE_EXTENSIONS).some(ext => pathname.endsWith(ext));
  };

  // Network-First for navigation requests so fresh HTML is served when online
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const clone = networkResponse.clone();
            caches.open(STATIC_CACHE).then(cache => cache.put(request, clone));
          }
          return networkResponse;
        })
        .catch(() => caches.match('/index.html'))
    );
    return;
  }

  // Cache-First strategy for static assets (JS, CSS, images, fonts)
  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }

        return fetch(request)
          .then((networkResponse) => {
            if (!networkResponse || networkResponse.status !== 200 || networkResponse.type === 'error') {
              return networkResponse;
            }

            const responseToCache = networkResponse.clone();

            if (shouldCache(url.pathname)) {
              caches.open(DYNAMIC_CACHE)
                .then((cache) => cache.put(request, responseToCache))
                .catch((error) => console.error('[Service Worker] Cache put error:', error));
            }

            return networkResponse;
          })
          .catch(() => {
            // Offline fallback for image requests: return a minimal transparent SVG
            if (url.pathname.match(/\.(png|jpg|jpeg|svg|gif|webp)$/)) {
              const svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>';
              return new Response(svg, {
                status: 200,
                headers: { 'Content-Type': 'image/svg+xml' }
              });
            }
          });
      })
  );
});
