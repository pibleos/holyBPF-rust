/**
 * Service Worker for HolyBPF Tutorials
 * Provides offline functionality and caching for better UX
 */

const CACHE_NAME = 'holybpf-tutorials-v1';
const urlsToCache = [
  '/docs/examples/tutorials/',
  '/docs/examples/tutorials/hello-world/',
  '/docs/examples/tutorials/escrow/',
  '/docs/examples/tutorials/solana-token/',
  '/docs/examples/tutorials/amm/',
  '/docs/examples/tutorials/dao-governance/',
  '/docs/examples/tutorials/yield-farming/',
  '/assets/css/style.css',
  '/assets/js/main.js',
  '/assets/favicon.svg'
];

// Install event - cache resources
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('HolyBPF: Service worker caching resources');
        return cache.addAll(urlsToCache);
      })
  );
});

// Fetch event - serve from cache when offline
self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // Return cached version or fetch from network
        if (response) {
          return response;
        }
        return fetch(event.request);
      }
    )
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', function(event) {
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheName !== CACHE_NAME) {
            console.log('HolyBPF: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Background sync for feedback
self.addEventListener('sync', function(event) {
  if (event.tag === 'feedback-sync') {
    event.waitUntil(syncFeedback());
  }
});

function syncFeedback() {
  // In a real implementation, this would sync pending feedback
  console.log('HolyBPF: Syncing feedback data');
  return Promise.resolve();
}