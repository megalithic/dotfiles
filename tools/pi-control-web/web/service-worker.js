const CACHE = "pi-control-web-v1";
const SHELL = [
	"/",
	"/app.js",
	"/styles.css",
	"/manifest.webmanifest",
	"/icon.svg",
];

self.addEventListener("install", (event) => {
	event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)));
	self.skipWaiting();
});

self.addEventListener("activate", (event) => {
	event.waitUntil(
		caches
			.keys()
			.then((keys) =>
				Promise.all(
					keys.filter((key) => key !== CACHE).map((key) => caches.delete(key)),
				),
			),
	);
	self.clients.claim();
});

self.addEventListener("fetch", (event) => {
	const url = new URL(event.request.url);
	if (url.origin !== self.location.origin || url.pathname.startsWith("/api/"))
		return;

	const cacheKey = event.request.mode === "navigate" ? "/" : event.request;
	event.respondWith(
		fetch(event.request)
			.then((response) => {
				if (response.ok && event.request.method === "GET") {
					const copy = response.clone();
					event.waitUntil(
						caches.open(CACHE).then((cache) => cache.put(cacheKey, copy)),
					);
				}
				return response;
			})
			.catch(() =>
				caches
					.match(cacheKey)
					.then((response) => response || caches.match("/")),
			),
	);
});

self.addEventListener("push", (event) => {
	let payload = {};
	try {
		payload = event.data?.json() || {};
	} catch {
		payload = { body: event.data?.text() || "Pi needs attention." };
	}

	const sessionId =
		typeof payload.sessionId === "string" ? payload.sessionId : null;
	const url = sessionId ? `/?session=${encodeURIComponent(sessionId)}` : "/";
	event.waitUntil(
		self.registration.showNotification(payload.title || "Pi", {
			body: payload.body || "Pi needs attention.",
			data: { url },
			icon: "/icon.svg",
			badge: "/icon.svg",
			tag: sessionId ? `pi-${sessionId}` : "pi-control",
		}),
	);
});

self.addEventListener("notificationclick", (event) => {
	event.notification.close();
	const target = new URL(
		event.notification.data?.url || "/",
		self.location.origin,
	).href;
	event.waitUntil(
		self.clients
			.matchAll({ type: "window", includeUncontrolled: true })
			.then((clients) => {
				for (const client of clients) {
					if ("navigate" in client) {
						client.navigate(target);
						return client.focus();
					}
				}
				return self.clients.openWindow(target);
			}),
	);
});
