(() => {
  if (window.__avwatchwebMain) return;
  window.__avwatchwebMain = true;

  const emit = (type, data) =>
    window.postMessage(
      { avwatchweb: "avwatchweb", type, data },
      location.origin,
    );
  const mediaIds = new WeakMap();
  const trackedMedia = new Map();
  const trackIds = new WeakMap();
  const userStreams = new Map();
  let nextMediaId = 1;
  let nextTrackId = 1;

  const mediaId = (element) => {
    if (!mediaIds.has(element)) {
      const id = `m${nextMediaId++}`;
      mediaIds.set(element, id);
      trackedMedia.set(id, element);
    }
    return mediaIds.get(element);
  };
  const trackId = (track) => {
    if (!trackIds.has(track)) trackIds.set(track, `t${nextTrackId++}`);
    return trackIds.get(track);
  };

  const meetingSelectors = {
    "meet.google.com": [
      'button[aria-label*="Leave call" i]',
      'button[data-tooltip*="Leave call" i]',
    ],
    "telehealth.px.athena.io": [
      'button[aria-label*="Leave call" i]',
      'button[aria-label*="End call" i]',
    ],
  }[location.hostname];

  let probeTimer;
  const probeMeeting = () => {
    probeTimer = undefined;
    const joined = meetingSelectors.some((selector) =>
      document.querySelector(selector),
    );
    emit("meeting", {
      state: joined ? "joined" : userStreams.size ? "lobby" : "idle",
    });
  };
  const scheduleProbe = () => {
    if (probeTimer === undefined) probeTimer = setTimeout(probeMeeting, 100);
  };

  let mediaCleanupPending = false;
  const scheduleMediaCleanup = () => {
    if (mediaCleanupPending) return;
    mediaCleanupPending = true;
    queueMicrotask(() => {
      mediaCleanupPending = false;
      for (const [id, element] of trackedMedia) {
        if (element.isConnected) continue;
        emit("playback", {
          mediaId: id,
          state: "pause",
          kind: element instanceof HTMLVideoElement ? "video" : "audio",
        });
        trackedMedia.delete(id);
      }
    });
  };

  new MutationObserver(() => {
    scheduleMediaCleanup();
    if (meetingSelectors) scheduleProbe();
  }).observe(document.documentElement || document, {
    childList: true,
    subtree: true,
  });
  if (meetingSelectors) scheduleProbe();

  const watchTrack = (track, streamId, capture) => {
    const id = trackId(track);
    const send = (state) =>
      emit("capture.track", {
        streamId,
        trackId: id,
        capture,
        kind: track.kind,
        state,
        enabled: track.enabled,
        muted: track.muted,
      });

    const descriptor = Object.getOwnPropertyDescriptor(
      MediaStreamTrack.prototype,
      "enabled",
    );
    if (descriptor?.get && descriptor?.set) {
      try {
        Object.defineProperty(track, "enabled", {
          configurable: true,
          get: () => descriptor.get.call(track),
          set: (value) => {
            descriptor.set.call(track, value);
            send("enabled");
          },
        });
      } catch {}
    }

    send("started");
    track.addEventListener(
      "ended",
      () => {
        send("ended");
        if (capture === "user") {
          const tracks = userStreams.get(streamId);
          tracks?.delete(id);
          if (tracks?.size === 0) userStreams.delete(streamId);
          scheduleProbe();
        }
      },
      { once: true },
    );
    track.addEventListener("mute", () => send("mute"));
    track.addEventListener("unmute", () => send("unmute"));
  };

  for (const name of ["getDisplayMedia", "getUserMedia"]) {
    const original = navigator.mediaDevices?.[name];
    if (typeof original !== "function") continue;
    navigator.mediaDevices[name] = function (...args) {
      return original.apply(this, args).then((stream) => {
        const streamId = String(stream.id || "").slice(0, 128);
        if (!streamId) return stream;
        const capture = name === "getDisplayMedia" ? "display" : "user";
        const tracks = stream.getTracks();
        if (capture === "user") {
          userStreams.set(streamId, new Set(tracks.map(trackId)));
          scheduleProbe();
        }
        emit("capture.start", { capture, streamId });
        tracks.forEach((track) => watchTrack(track, streamId, capture));
        return stream;
      });
    };
  }

  const playback = (event) => {
    const target = event.target;
    if (!(target instanceof HTMLMediaElement)) return;
    let state = "pause";
    if (event.type === "ended") state = "end";
    else if (event.type === "play") state = "play";
    emit("playback", {
      mediaId: mediaId(target),
      state,
      kind: target instanceof HTMLVideoElement ? "video" : "audio",
    });
  };
  for (const type of ["play", "pause", "ended", "emptied", "abort", "error"]) {
    document.addEventListener(type, playback, true);
  }
})();
