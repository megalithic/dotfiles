(() => {
  const allowed = new Set(["capture.start", "capture.track", "playback", "meeting"]);
  const captures = new Set(["display", "user"]), kinds = new Set(["audio", "video"]);
  const states = new Set(["started", "ended", "mute", "unmute", "enabled"]);
  const text = (v, max) => typeof v === "string" && v.length > 0 && v.length <= max;
  window.addEventListener("message", (event) => {
    if (event.source !== window || event.origin !== location.origin) return;
    const m = event.data, d = m && m.data;
    if (!m || m.avwatchweb !== "avwatchweb" || !allowed.has(m.type) || !d || typeof d !== "object") return;
    const out = { type: m.type };
    if (m.type === "capture.start") {
      if (!captures.has(d.capture) || !text(d.streamId, 128)) return;
      Object.assign(out, { capture: d.capture, streamId: d.streamId });
    } else if (m.type === "capture.track") {
      if (!captures.has(d.capture) || !kinds.has(d.kind) || !states.has(d.state) || !text(d.streamId, 128) || !text(d.trackId, 64)) return;
      if (typeof d.enabled !== "boolean" || typeof d.muted !== "boolean") return;
      Object.assign(out, { capture: d.capture, streamId: d.streamId, trackId: d.trackId, kind: d.kind, state: d.state, enabled: d.enabled, muted: d.muted });
    } else if (m.type === "playback") {
      if (!text(d.mediaId, 64) || !kinds.has(d.kind) || !["play", "pause", "end"].includes(d.state)) return;
      Object.assign(out, { mediaId: d.mediaId, kind: d.kind, state: d.state });
    } else {
      if (!["idle", "lobby", "joined"].includes(d.state)) return;
      out.state = d.state;
    }
    chrome.runtime.sendMessage({ v: 1, event: out });
  });
})();
