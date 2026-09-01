const EXPECTED_ID = "ogfaajbfamngmlmkppahdpkoliobdemk";
const DEFAULT = {
  nativeHost: "com.megadots.avwatchd",
  meetingOrigins: [
    "https://meet.google.com",
    "https://telehealth.px.athena.io",
  ],
  meetingUrlPrefixes: [
    "https://meet.google.com/",
    "https://telehealth.px.athena.io/",
  ],
  playbackEnabled: true,
  mediaSessionMetadata: false,
  reconnectDelayMs: 1000,
};
let config, port, retry;
const state = new Map();
const nonce = crypto.randomUUID();
const send = (type, fields = {}) => {
  if (port) {
    try {
      port.postMessage(Object.assign({ v: 1, type, nonce }, fields));
    } catch {}
  }
};
const meetingUrl = (url) => {
  try {
    const u = new URL(url);
    return (
      config.meetingOrigins.includes(u.origin) &&
      config.meetingUrlPrefixes.some((p) => url.startsWith(p))
    );
  } catch {
    return false;
  }
};
const validConfig = (c) =>
  c &&
  c.nativeHost === DEFAULT.nativeHost &&
  Array.isArray(c.meetingOrigins) &&
  Array.isArray(c.meetingUrlPrefixes) &&
  typeof c.playbackEnabled === "boolean" &&
  c.mediaSessionMetadata === false &&
  Number.isInteger(c.reconnectDelayMs) &&
  c.reconnectDelayMs >= 100 &&
  c.reconnectDelayMs <= 30000;
const load = async () => {
  const c = await fetch(chrome.runtime.getURL("config.json")).then((r) =>
    r.json(),
  );
  if (!validConfig(c)) throw new Error("invalid avwatchweb config");
  config = Object.assign({}, DEFAULT, c);
  if (chrome.runtime.id !== EXPECTED_ID)
    throw new Error("unexpected extension id");
};
const persist = () =>
  chrome.storage.session
    .set({ avwatchwebState: Array.from(state.values()) })
    .catch(() => {});
const restore = async () => {
  const saved = await chrome.storage.session.get("avwatchwebState");
  if (!Array.isArray(saved.avwatchwebState)) return;
  for (const tab of saved.avwatchwebState) {
    if (
      !tab ||
      !Number.isInteger(tab.tabId) ||
      !Number.isInteger(tab.windowId) ||
      typeof tab.url !== "string"
    )
      continue;
    try {
      if (!["http:", "https:"].includes(new URL(tab.url).protocol)) continue;
    } catch {
      continue;
    }
    tab.meetingState = ["idle", "lobby", "joined"].includes(tab.meetingState)
      ? tab.meetingState
      : "idle";
    tab.playback ||= {};
    tab.display ||= {};
    tab.user ||= {};
    state.set(tab.tabId, tab);
  }
};
const trackMode = (tracks, kind) => {
  const values = Object.values(tracks).filter(
    (t) => t.kind === kind && t.state !== "ended",
  );
  if (!values.length) return "off";
  if (values.some((t) => t.muted)) return "muted";
  if (values.some((t) => !t.enabled)) return "off";
  return "on";
};
const tabSnapshot = (s) => ({
  tabId: s.tabId,
  windowId: s.windowId,
  url: s.url,
  meetingState: s.meetingState,
  displaySharing: Object.values(s.display).some(
    (stream) => Object.keys(stream.tracks).length > 0,
  ),
  userMedia: {
    audio: trackMode(
      Object.assign({}, ...Object.values(s.user).map((x) => x.tracks)),
      "audio",
    ),
    video: trackMode(
      Object.assign({}, ...Object.values(s.user).map((x) => x.tracks)),
      "video",
    ),
  },
  playback: {
    active: Object.values(s.playback).some((m) => m.state === "play"),
    kinds: [
      ...new Set(
        Object.values(s.playback)
          .filter((m) => m.state === "play")
          .map((m) => m.kind),
      ),
    ],
  },
});
const snapshot = () => Array.from(state.values()).map(tabSnapshot);
const scheduleReconnect = () => {
  if (!retry)
    retry = setTimeout(() => {
      retry = null;
      connect();
    }, config.reconnectDelayMs);
};
const connect = () => {
  if (port || !config) return;
  try {
    port = chrome.runtime.connectNative(config.nativeHost);
    port.onMessage.addListener(inbound);
    port.onDisconnect.addListener(() => {
      port = null;
      scheduleReconnect();
    });
    send("hello", { extensionId: chrome.runtime.id });
    send("reset");
    send("snapshot", { tabs: snapshot() });
  } catch {
    port = null;
    scheduleReconnect();
  }
};
const inbound = (m) => {
  if (
    !m ||
    m.v !== 1 ||
    m.nonce !== nonce ||
    (m.type !== "focus" && m.type !== "status")
  )
    return;
  if (m.type === "status") {
    if (m.connected === true) {
      send("reset");
      send("snapshot", { requestId: m.requestId, tabs: snapshot() });
    }
    return;
  }
  if (
    !Number.isInteger(m.tabId) ||
    !Number.isInteger(m.windowId) ||
    typeof m.requestId !== "string" ||
    m.requestId.length > 128 ||
    !["meeting", "playback"].includes(m.target)
  )
    return;
  const s = state.get(m.tabId);
  const active =
    s &&
    s.windowId === m.windowId &&
    (m.target === "meeting"
      ? s.meetingState === "joined" ||
        s.meetingState === "lobby" ||
        Object.keys(s.display).length > 0 ||
        Object.keys(s.user).length > 0
      : Object.values(s.playback).some((x) => x.state === "play"));
  if (!active) {
    send("focus-result", {
      requestId: m.requestId,
      ok: false,
      tabId: m.tabId,
      windowId: m.windowId,
    });
    return;
  }
  Promise.all([
    chrome.tabs.update(m.tabId, { active: true }),
    chrome.windows.update(m.windowId, { focused: true }),
  ])
    .then(() =>
      send("focus-result", {
        requestId: m.requestId,
        ok: true,
        tabId: m.tabId,
        windowId: m.windowId,
      }),
    )
    .catch(() =>
      send("focus-result", {
        requestId: m.requestId,
        ok: false,
        tabId: m.tabId,
        windowId: m.windowId,
      }),
    );
};
const accept = (m, sender) => {
  if (
    !config ||
    !sender.id ||
    sender.id !== chrome.runtime.id ||
    !sender.tab ||
    !Number.isInteger(sender.tab.id) ||
    !Number.isInteger(sender.tab.windowId) ||
    typeof sender.tab.url !== "string"
  )
    return;
  let u;
  try {
    u = new URL(sender.tab.url);
  } catch {
    return;
  }
  if (!["http:", "https:"].includes(u.protocol)) return;
  const meeting = meetingUrl(sender.tab.url),
    e = m && m.event;
  if (
    !e ||
    m.v !== 1 ||
    typeof e.type !== "string" ||
    (e.type === "meeting" && !meeting) ||
    (e.type !== "meeting" &&
      e.type !== "playback" &&
      e.type !== "capture.start" &&
      e.type !== "capture.track")
  )
    return;
  if (
    e.type === "playback" &&
    (!config.playbackEnabled ||
      !["play", "pause", "end"].includes(e.state) ||
      !["audio", "video"].includes(e.kind) ||
      typeof e.mediaId !== "string")
  )
    return;
  if (
    (e.type === "capture.start" || e.type === "capture.track") &&
    e.capture === "user" &&
    !meeting
  )
    return;
  const id = sender.tab.id;
  let s = state.get(id);
  if (!s) {
    s = {
      tabId: id,
      windowId: sender.tab.windowId,
      url: sender.tab.url,
      meetingState: "idle",
      display: {},
      user: {},
      playback: {},
    };
    state.set(id, s);
  }
  s.windowId = sender.tab.windowId;
  s.url = sender.tab.url;
  if (e.type === "meeting") s.meetingState = e.state;
  else if (e.type === "playback")
    s.playback[e.mediaId] = { state: e.state, kind: e.kind };
  else if (e.type === "capture.start") {
    s[e.capture][e.streamId] = { tracks: {} };
    if (e.capture === "user" && s.meetingState === "idle")
      s.meetingState = "lobby";
  } else {
    const stream =
      s[e.capture][e.streamId] || (s[e.capture][e.streamId] = { tracks: {} });
    stream.tracks[e.trackId] = {
      state: e.state,
      kind: e.kind,
      enabled: e.enabled,
      muted: e.muted,
    };
    if (e.state === "ended") delete stream.tracks[e.trackId];
    if (!Object.keys(stream.tracks).length) delete s[e.capture][e.streamId];
  }
  persist();
  send("event", { tab: tabSnapshot(s), event: e.type });
};
chrome.runtime.onMessage.addListener(accept);
chrome.tabs.onRemoved.addListener((tabId) => {
  state.delete(tabId);
  persist();
  send("tab-removed", { tabId });
});
chrome.tabs.onUpdated.addListener((tabId, change) => {
  if (change.status === "loading") {
    state.delete(tabId);
    persist();
    send("tab-reset", { tabId });
  }
});
load()
  .then(restore)
  .then(connect)
  .catch(() => {
    config = null;
  });
