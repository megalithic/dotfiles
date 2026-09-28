/**
 * Geo Workbench
 *
 * Local browser intake UI for image geolocation investigations.
 *
 * Usage:
 *   /geo
 */

import { spawn, spawnSync } from "node:child_process";
import {
  createServer,
  type IncomingMessage,
  type Server,
  type ServerResponse,
} from "node:http";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const EXTENSION_NAME = "geo-workbench";
const MAX_BODY_BYTES = 120 * 1024 * 1024;
const MAX_IMAGES = 24;
const USER_AGENT =
  "pi-geo-workbench/0.1 (local personal OSINT helper; contact: local-user)";

type UploadedImage = {
  name: string;
  mediaType: string;
  data: string;
};

type GeoFacts = {
  country?: string;
  region?: string;
  city?: string;
  businessType?: string;
  dateRange?: string;
  knownFacts?: string;
  exclusions?: string;
  publicImageUrls?: string;
  privacyMode?:
    | "public-business"
    | "public-place"
    | "private-residence"
    | "unknown";
};

type Candidate = {
  rank?: number;
  businessName?: string;
  address?: string;
  city?: string;
  state?: string;
  country?: string;
  latitude?: number;
  longitude?: number;
  confidence?: number;
  accuracy?: string;
  googleMapsUrl?: string;
  googleEarthUrl?: string;
  evidence?: string[];
  evidenceAgainst?: string[];
  nextChecks?: string[];
};

type GeoReport = {
  runId: string;
  summary?: string;
  markdown?: string;
  candidates: Candidate[];
  confidenceNotes?: string;
  json?: unknown;
};

type RunState = {
  id: string;
  createdAt: string;
  dir: string;
  facts: GeoFacts;
  images: Array<{
    originalName: string;
    fileName: string;
    path: string;
    mediaType: string;
    sizeBytes: number;
  }>;
  metadata: unknown[];
  status: "submitted" | "sent_to_pi" | "reported" | "error";
  error?: string;
  report?: GeoReport;
};

let server: Server | undefined;
let serverPort: number | undefined;
let lastNominatimAt = 0;
const runs = new Map<string, RunState>();

const text = (
  res: ServerResponse,
  status: number,
  body: string,
  contentType = "text/plain; charset=utf-8",
  headers: Record<string, string> = {},
) => {
  res.writeHead(status, { "content-type": contentType, ...headers });
  res.end(body);
};

const json = (
  res: ServerResponse,
  status: number,
  body: unknown,
  headers: Record<string, string> = {},
) => {
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    ...headers,
  });
  res.end(JSON.stringify(body, null, 2));
};

const readBody = async (req: IncomingMessage): Promise<string> => {
  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    size += buffer.length;
    if (size > MAX_BODY_BYTES) {
      throw new Error(
        `Request too large. Max ${Math.round(MAX_BODY_BYTES / 1024 / 1024)}MB.`,
      );
    }
    chunks.push(buffer);
  }
  return Buffer.concat(chunks).toString("utf8");
};

const safeFileName = (name: string, fallback: string): string => {
  const base = path
    .basename(name || fallback)
    .replace(/[^a-zA-Z0-9._-]+/g, "_")
    .slice(0, 120);
  return base || fallback;
};

const extensionDataDir = (): string => {
  const base =
    process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share");
  return path.join(base, "pi", EXTENSION_NAME);
};

const runJsonPath = (id: string): string | undefined => {
  if (!/^[a-zA-Z0-9-]+$/.test(id)) return undefined;
  return path.join(extensionDataDir(), "runs", id, "run.json");
};

const getRun = (id: string): RunState | undefined => {
  const inMemory = runs.get(id);
  if (inMemory) return inMemory;

  const filePath = runJsonPath(id);
  if (!filePath || !existsSync(filePath)) return undefined;

  try {
    const run = JSON.parse(readFileSync(filePath, "utf8")) as RunState;
    runs.set(id, run);
    return run;
  } catch {
    return undefined;
  }
};

const newRunId = (): string => {
  const stamp = new Date()
    .toISOString()
    .replace(/[-:.TZ]/g, "")
    .slice(0, 14);
  const rand = Math.random().toString(36).slice(2, 8);
  return `${stamp}-${rand}`;
};

const maybeExtractMetadata = (filePath: string): unknown => {
  const exiftool = spawnSync("exiftool", ["-json", "-n", filePath], {
    encoding: "utf8",
  });
  if (exiftool.status === 0 && exiftool.stdout.trim()) {
    try {
      return { source: "exiftool", data: JSON.parse(exiftool.stdout)[0] };
    } catch {
      return { source: "exiftool", raw: exiftool.stdout.slice(0, 4000) };
    }
  }

  if (process.platform === "darwin") {
    const mdls = spawnSync("mdls", [filePath], { encoding: "utf8" });
    if (mdls.status === 0 && mdls.stdout.trim()) {
      return { source: "mdls", raw: mdls.stdout.slice(0, 4000) };
    }
  }

  return {
    source: "none",
    note: "Install exiftool for richer local metadata extraction.",
  };
};

const googleMapsUrl = (candidate: Candidate): string => {
  if (
    typeof candidate.latitude === "number" &&
    typeof candidate.longitude === "number"
  ) {
    return `https://www.google.com/maps/search/?api=1&query=${candidate.latitude},${candidate.longitude}`;
  }
  const query = [
    candidate.businessName,
    candidate.address,
    candidate.city,
    candidate.state,
    candidate.country,
  ]
    .filter(Boolean)
    .join(", ");
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`;
};

const googleEarthUrl = (candidate: Candidate): string => {
  if (
    typeof candidate.latitude === "number" &&
    typeof candidate.longitude === "number"
  ) {
    return `https://earth.google.com/web/@${candidate.latitude},${candidate.longitude},100a,1000d,35y,0h,0t,0r`;
  }
  const query = [
    candidate.businessName,
    candidate.address,
    candidate.city,
    candidate.state,
    candidate.country,
  ]
    .filter(Boolean)
    .join(", ");
  return `https://earth.google.com/web/search/${encodeURIComponent(query)}`;
};

const normalizeReport = (report: GeoReport): GeoReport => {
  const candidates = (report.candidates || []).map((candidate, index) => {
    const withRank = { ...candidate, rank: candidate.rank ?? index + 1 };
    return {
      ...withRank,
      googleMapsUrl: candidate.googleMapsUrl || googleMapsUrl(withRank),
      googleEarthUrl: candidate.googleEarthUrl || googleEarthUrl(withRank),
    };
  });
  return { ...report, candidates };
};

const reportToMarkdown = (report: GeoReport): string => {
  if (report.markdown?.trim()) return report.markdown;

  const lines = [
    "# Geo workbench report",
    "",
    report.summary || "",
    "",
    "## Candidates",
    "",
  ];
  for (const candidate of report.candidates || []) {
    lines.push(
      `### ${candidate.rank ?? "?"}. ${candidate.businessName || candidate.address || "Unknown candidate"}`,
    );
    lines.push(`- Address: ${candidate.address || "unknown"}`);
    lines.push(
      `- Location: ${[candidate.city, candidate.state, candidate.country].filter(Boolean).join(", ") || "unknown"}`,
    );
    lines.push(
      `- Coordinates: ${typeof candidate.latitude === "number" && typeof candidate.longitude === "number" ? `${candidate.latitude}, ${candidate.longitude}` : "unknown"}`,
    );
    lines.push(`- Confidence: ${candidate.confidence ?? "unknown"}`);
    lines.push(`- Accuracy: ${candidate.accuracy || "unknown"}`);
    lines.push(`- Google Maps: ${candidate.googleMapsUrl || ""}`);
    lines.push(`- Google Earth: ${candidate.googleEarthUrl || ""}`);
    if (candidate.evidence?.length)
      lines.push(`- Evidence: ${candidate.evidence.join("; ")}`);
    if (candidate.evidenceAgainst?.length)
      lines.push(`- Evidence against: ${candidate.evidenceAgainst.join("; ")}`);
    if (candidate.nextChecks?.length)
      lines.push(`- Next checks: ${candidate.nextChecks.join("; ")}`);
    lines.push("");
  }
  if (report.confidenceNotes)
    lines.push("## Confidence notes", "", report.confidenceNotes, "");
  return lines.join("\n");
};

const csvEscape = (value: unknown): string => {
  const textValue = value === undefined || value === null ? "" : String(value);
  return `"${textValue.replace(/"/g, '""')}"`;
};

const reportToCsv = (report: GeoReport): string => {
  const headers = [
    "rank",
    "business_name",
    "address",
    "city",
    "state",
    "country",
    "latitude",
    "longitude",
    "confidence",
    "accuracy",
    "google_maps_url",
    "google_earth_url",
    "evidence",
    "evidence_against",
    "next_checks",
  ];
  const rows = (report.candidates || []).map((candidate) => [
    candidate.rank,
    candidate.businessName,
    candidate.address,
    candidate.city,
    candidate.state,
    candidate.country,
    candidate.latitude,
    candidate.longitude,
    candidate.confidence,
    candidate.accuracy,
    candidate.googleMapsUrl,
    candidate.googleEarthUrl,
    candidate.evidence?.join(" | "),
    candidate.evidenceAgainst?.join(" | "),
    candidate.nextChecks?.join(" | "),
  ]);
  return [headers, ...rows]
    .map((row) => row.map(csvEscape).join(","))
    .join("\n");
};

const servicesCatalog = () => ({
  freeNoKey: [
    {
      name: "OpenStreetMap Nominatim",
      endpoint:
        "https://nominatim.openstreetmap.org/search?format=jsonv2&q=...",
      uses: "Free geocoding/reverse geocoding from OSM. Strict rate limits; no bulk scraping.",
    },
    {
      name: "Google Maps/Earth links",
      endpoint: "https://www.google.com/maps/search/?api=1&query=...",
      uses: "Free link generation; no API key needed for opening candidate locations.",
    },
    {
      name: "Local EXIF metadata",
      endpoint: "exiftool or macOS mdls if installed",
      uses: "Reads GPS/camera/date metadata locally before model reasoning.",
    },
  ],
  optionalKeys: [
    {
      name: "SerpAPI Google Lens",
      env: "SERPAPI_API_KEY",
      configured: Boolean(process.env.SERPAPI_API_KEY),
      endpoint: "https://serpapi.com/search?engine=google_lens&url=...",
      note: "Useful for visual matches. Usually needs a public image URL, not localhost upload.",
    },
    {
      name: "Google Maps Platform",
      env: "GOOGLE_MAPS_API_KEY",
      configured: Boolean(
        process.env.GOOGLE_MAPS_API_KEY || process.env.GOOGLE_API_KEY,
      ),
      endpoint: "Places/Geocoding APIs",
      note: "Billing-backed pay-as-you-go with free monthly usage caps/credits depending SKU/account. Not truly anonymous-free.",
    },
    {
      name: "Mapillary",
      env: "MAPILLARY_ACCESS_TOKEN",
      configured: Boolean(process.env.MAPILLARY_ACCESS_TOKEN),
      endpoint: "https://graph.mapillary.com/...",
      note: "Street-level imagery metadata near candidate coords.",
    },
  ],
});

const buildPrompt = (
  run: RunState,
): string => `You are running Geo Workbench image geolocation run ${run.id}.

Goal: identify likely location and, if possible, business/place name. Return possible addresses, GPS coordinates, city/state/country, confidence, confidence/accuracy notes, Google Maps links, and Google Earth links.

Safety boundary:
- Public business/place exact coordinates are allowed.
- Private residence exact coordinates are allowed only when the user marks the run as private residence/consensual and the context looks legitimate.
- If images appear to identify a private person, school child, shelter, clinic patient, or stalking-sensitive target, do not provide exact address/coordinates. Give safety-limited high-level location clues only.

Known user facts:
${JSON.stringify(run.facts, null, 2)}

Local metadata already extracted:
${JSON.stringify(run.metadata, null, 2)}

Free/default services configured:
${JSON.stringify(servicesCatalog(), null, 2)}

Required workflow:
1. Inspect all images as one set.
2. Extract visible clues: signs/OCR text, business names, phone numbers, road signs, brands, license plates, architecture, road markings, terrain, vegetation, shadows, utility poles, storefront features.
3. If EXIF/GPS metadata exists, use it but still verify visually.
4. Use exact text clues with available web search tools. Try quoted searches for storefront/sign text plus country/region.
5. Use geo_lookup for free Nominatim geocoding/reverse geocoding candidates when useful.
6. If public image URLs are provided and SERPAPI_API_KEY is configured, mention SerpAPI Google Lens as an optional check. Do not claim it ran unless you used a tool or API.
7. Rank candidates. Include evidence for and against each. Prefer low confidence over hallucination.
8. End by calling geo_report with runId=${run.id}. Include candidates with coords when possible. Include markdown report text. After geo_report, provide a concise summary in chat.

Output expectations in geo_report:
- summary
- markdown
- candidates array with: rank, businessName, address, city, state, country, latitude, longitude, confidence 0-1, accuracy, evidence, evidenceAgainst, nextChecks
- confidenceNotes
`;

const htmlPage = () => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Pi Geo Workbench</title>
<style>
:root { color-scheme: light dark; font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
html { min-height: 100%; }
body { margin: 0; min-height: 100vh; background: Canvas; color: CanvasText; }
main { max-width: 1100px; margin: 0 auto; padding: 28px; }
h1 { margin: 0 0 8px; font-size: 30px; }
p { line-height: 1.45; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 14px; }
.card { border: 1px solid color-mix(in srgb, CanvasText 20%, transparent); border-radius: 16px; padding: 16px; background: color-mix(in srgb, Canvas 94%, CanvasText 6%); }
.drop { border: 3px dashed color-mix(in srgb, #4f46e5 55%, CanvasText 25%); border-radius: 18px; min-height: 220px; display: grid; place-items: center; text-align: center; padding: 24px; cursor: pointer; background: color-mix(in srgb, #4f46e5 7%, Canvas); transition: border-color .15s, background .15s, transform .15s; }
.drop.drag, body.dragging .drop { border-color: #4f46e5; background: color-mix(in srgb, #4f46e5 16%, Canvas); transform: scale(1.005); }
.dropOverlay { display: none; position: fixed; inset: 12px; z-index: 9999; border: 4px dashed #4f46e5; border-radius: 22px; background: color-mix(in srgb, #4f46e5 18%, Canvas); place-items: center; text-align: center; font-size: clamp(22px, 4vw, 42px); font-weight: 800; pointer-events: none; box-shadow: 0 18px 80px color-mix(in srgb, black 30%, transparent); }
body.dragging .dropOverlay { display: grid; }
.preview { display: grid; grid-template-columns: repeat(auto-fill, minmax(130px, 1fr)); gap: 10px; margin-top: 12px; }
.thumb { border: 1px solid color-mix(in srgb, CanvasText 15%, transparent); border-radius: 12px; overflow: hidden; }
.thumb img { display: block; width: 100%; height: 110px; object-fit: cover; }
.thumb small { display: block; padding: 6px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
label { display: grid; gap: 6px; font-weight: 650; }
input, textarea, select, button { font: inherit; border-radius: 10px; border: 1px solid color-mix(in srgb, CanvasText 22%, transparent); padding: 10px 12px; background: Canvas; color: CanvasText; }
textarea { min-height: 92px; resize: vertical; }
button { background: #4f46e5; color: white; border: 0; font-weight: 750; cursor: pointer; }
button.secondary { background: color-mix(in srgb, CanvasText 12%, Canvas); color: CanvasText; border: 1px solid color-mix(in srgb, CanvasText 20%, transparent); }
button:disabled { opacity: .55; cursor: not-allowed; }
.actions { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 14px; }
.status { white-space: pre-wrap; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 13px; }
table { width: 100%; border-collapse: collapse; font-size: 14px; }
th, td { border-bottom: 1px solid color-mix(in srgb, CanvasText 14%, transparent); padding: 8px; text-align: left; vertical-align: top; }
.report { display: none; }
.report.show { display: block; }
.links a { display: inline-block; margin-right: 8px; }
@media (max-width: 720px) {
  main { padding: 16px; }
  h1 { font-size: 24px; }
  .drop { min-height: 180px; }
  table { font-size: 12px; }
}
</style>
</head>
<body>
<div id="dropOverlay" class="dropOverlay">Drop images anywhere</div>
<main>
  <h1>Pi Geo Workbench</h1>
  <p>Drop images, add what you know, then pi investigates with local metadata, vision reasoning, free lookup endpoints, and any configured optional APIs.</p>

  <section class="card">
    <div id="drop" class="drop">
      <div><strong>Drag images here</strong><br/>or click to choose files<br/><small>JPEG/PNG/WebP/GIF supported. Max ${MAX_IMAGES} images.</small></div>
      <input id="files" type="file" accept="image/*" multiple hidden />
    </div>
    <div id="preview" class="preview"></div>
  </section>

  <section class="grid" style="margin-top:14px">
    <label>Country<input id="country" placeholder="e.g. Mexico" /></label>
    <label>Region/state/province<input id="region" placeholder="Known or suspected region" /></label>
    <label>City/area<input id="city" placeholder="Known/suspected city" /></label>
    <label>Business type<input id="businessType" placeholder="e.g. pharmacy, restaurant, gas station" /></label>
    <label>Date range<input id="dateRange" placeholder="e.g. taken around 2023" /></label>
    <label>Privacy mode<select id="privacyMode"><option value="public-business">Public business</option><option value="public-place">Public place</option><option value="private-residence">Private residence / consensual</option><option value="unknown">Unknown / be cautious</option></select></label>
  </section>

  <section class="grid" style="margin-top:14px">
    <label>Known facts<textarea id="knownFacts" placeholder="Anything you know: country, route, language, signs, who took it, nearby coast/mountains, etc."></textarea></label>
    <label>Exclude / don't assume<textarea id="exclusions" placeholder="Locations already ruled out, false clues, privacy limits"></textarea></label>
    <label>Public image URLs<textarea id="publicImageUrls" placeholder="Optional. Public URLs help reverse image / SerpAPI Lens checks."></textarea></label>
  </section>

  <section class="card" style="margin-top:14px">
    <strong>Free-first services</strong>
    <div id="services" class="status">Loading...</div>
  </section>

  <div class="actions">
    <button id="submit">Start investigation in pi</button>
    <button id="clear" class="secondary">Clear</button>
  </div>

  <section class="card" style="margin-top:14px">
    <strong>Status</strong>
    <div id="status" class="status">Waiting for images.</div>
  </section>

  <section id="report" class="card report" style="margin-top:14px">
    <h2>Report</h2>
    <div class="actions">
      <a id="exportMd"><button class="secondary">Export markdown</button></a>
      <a id="exportJson"><button class="secondary">Export JSON</button></a>
      <a id="exportCsv"><button class="secondary">Export CSV</button></a>
    </div>
    <div id="candidateTable"></div>
    <h3>Markdown</h3>
    <pre id="markdown" class="status"></pre>
  </section>
</main>
<script>
const filesInput = document.getElementById('files');
const drop = document.getElementById('drop');
const preview = document.getElementById('preview');
const statusEl = document.getElementById('status');
const submit = document.getElementById('submit');
const clear = document.getElementById('clear');
const reportEl = document.getElementById('report');
let images = [];
let currentRunId = null;

const setStatus = (msg) => { statusEl.textContent = msg; };
const fileToData = (file) => new Promise((resolve, reject) => {
  const reader = new FileReader();
  reader.onerror = () => reject(reader.error);
  reader.onload = () => {
    const value = String(reader.result);
    const comma = value.indexOf(',');
    resolve({ name: file.name, mediaType: file.type || 'application/octet-stream', data: value.slice(comma + 1) });
  };
  reader.readAsDataURL(file);
});

async function addFiles(fileList) {
  const picked = [...fileList].filter(f => f.type.startsWith('image/')).slice(0, ${MAX_IMAGES} - images.length);
  for (const file of picked) images.push(await fileToData(file));
  renderPreview();
  setStatus(images.length ? images.length + ' image(s) ready.' : 'Waiting for images.');
}
function renderPreview() {
  preview.innerHTML = images.map((img, i) => '<div class="thumb"><img src="data:' + img.mediaType + ';base64,' + img.data + '"/><small>' + (i + 1) + '. ' + escapeHtml(img.name) + '</small></div>').join('');
}
function escapeHtml(s) { return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

drop.addEventListener('click', () => filesInput.click());
filesInput.addEventListener('change', () => addFiles(filesInput.files));

function hasImageFiles(event) {
  const types = [...(event.dataTransfer?.types || [])];
  const items = [...(event.dataTransfer?.items || [])];
  return types.includes('Files') || items.some(item => item.kind === 'file' && (!item.type || item.type.startsWith('image/')));
}
function setDragging(value) {
  document.body.classList.toggle('dragging', value);
  drop.classList.toggle('drag', value);
}
for (const eventName of ['dragenter','dragover']) {
  window.addEventListener(eventName, event => {
    if (!hasImageFiles(event)) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
    setDragging(true);
  });
}
window.addEventListener('dragleave', event => {
  if (event.clientX <= 0 || event.clientY <= 0 || event.clientX >= window.innerWidth || event.clientY >= window.innerHeight) setDragging(false);
});
window.addEventListener('drop', event => {
  if (!event.dataTransfer?.files?.length) return;
  event.preventDefault();
  setDragging(false);
  addFiles(event.dataTransfer.files);
});
window.addEventListener('dragover', event => event.preventDefault());
clear.addEventListener('click', () => { images = []; currentRunId = null; renderPreview(); reportEl.classList.remove('show'); setStatus('Cleared.'); });

fetch('/api/config').then(r => r.json()).then(config => {
  document.getElementById('services').textContent = JSON.stringify(config.services, null, 2);
});

submit.addEventListener('click', async () => {
  if (!images.length) { setStatus('Add images first.'); return; }
  submit.disabled = true;
  setStatus('Uploading to local pi extension...');
  const facts = {};
  for (const id of ['country','region','city','businessType','dateRange','knownFacts','exclusions','publicImageUrls','privacyMode']) facts[id] = document.getElementById(id).value;
  try {
    const res = await fetch('/api/submit', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ facts, images }) });
    if (!res.ok) throw new Error(await res.text());
    const body = await res.json();
    currentRunId = body.runId;
    setStatus('Sent to pi. Watch pi chat. Waiting for geo_report tool call...\\nRun: ' + currentRunId);
    pollReport();
  } catch (err) {
    setStatus('Error: ' + (err && err.message ? err.message : err));
  } finally {
    submit.disabled = false;
  }
});

async function pollReport() {
  if (!currentRunId) return;
  const res = await fetch('/api/runs/' + encodeURIComponent(currentRunId));
  const run = await res.json();
  if (run.status === 'reported' && run.report) {
    renderReport(run);
    setStatus('Report ready.');
    return;
  }
  setStatus('Pi status: ' + run.status + '\\nRun: ' + currentRunId + '\\nWaiting for final report...');
  setTimeout(pollReport, 2500);
}
function renderReport(run) {
  const report = run.report;
  reportEl.classList.add('show');
  const md = document.getElementById('exportMd');
  const js = document.getElementById('exportJson');
  const csv = document.getElementById('exportCsv');
  md.href = '/api/runs/' + run.id + '/export.md'; md.download = run.id + '-geo-report.md';
  js.href = '/api/runs/' + run.id + '/export.json'; js.download = run.id + '-geo-report.json';
  csv.href = '/api/runs/' + run.id + '/export.csv'; csv.download = run.id + '-geo-report.csv';
  const rows = (report.candidates || []).map(c => '<tr><td>' + escapeHtml(c.rank || '') + '</td><td>' + escapeHtml(c.businessName || '') + '</td><td>' + escapeHtml(c.address || '') + '</td><td>' + escapeHtml([c.city,c.state,c.country].filter(Boolean).join(', ')) + '</td><td>' + escapeHtml(c.latitude && c.longitude ? c.latitude + ', ' + c.longitude : '') + '</td><td>' + escapeHtml(c.confidence ?? '') + '</td><td class="links"><a href="' + escapeHtml(c.googleMapsUrl || '#') + '" target="_blank">Maps</a><a href="' + escapeHtml(c.googleEarthUrl || '#') + '" target="_blank">Earth</a></td></tr>').join('');
  document.getElementById('candidateTable').innerHTML = '<table><thead><tr><th>#</th><th>Business</th><th>Address</th><th>Location</th><th>Coords</th><th>Conf.</th><th>Links</th></tr></thead><tbody>' + rows + '</tbody></table>';
  document.getElementById('markdown').textContent = report.markdown || '';
  reportEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
}
</script>
</body>
</html>`;

const handleSubmit = async (
  body: string,
  pi: ExtensionAPI,
  res: ServerResponse,
) => {
  let parsed: { facts?: GeoFacts; images?: UploadedImage[] };
  try {
    parsed = JSON.parse(body) as {
      facts?: GeoFacts;
      images?: UploadedImage[];
    };
  } catch {
    json(res, 400, { error: "Invalid JSON." });
    return;
  }

  const images = (parsed.images || []).slice(0, MAX_IMAGES);
  if (!images.length) {
    json(res, 400, { error: "No images uploaded." });
    return;
  }

  const id = newRunId();
  const dir = path.join(extensionDataDir(), "runs", id);
  mkdirSync(dir, { recursive: true });

  const savedImages: RunState["images"] = [];
  const content: Array<
    | { type: "text"; text: string }
    | { type: "image"; data: string; mimeType: string }
  > = [];

  for (let index = 0; index < images.length; index++) {
    const image = images[index];
    if (!image.mediaType?.startsWith("image/")) {
      json(res, 400, { error: `Unsupported media type for ${image.name}.` });
      return;
    }

    const fileName = `${String(index + 1).padStart(2, "0")}-${safeFileName(image.name, `image-${index + 1}`)}`;
    const filePath = path.join(dir, fileName);
    const buffer = Buffer.from(image.data, "base64");
    writeFileSync(filePath, buffer);
    savedImages.push({
      originalName: image.name,
      fileName,
      path: filePath,
      mediaType: image.mediaType,
      sizeBytes: buffer.length,
    });
    content.push({
      type: "image",
      data: image.data,
      mimeType: image.mediaType,
    });
  }

  const run: RunState = {
    id,
    createdAt: new Date().toISOString(),
    dir,
    facts: parsed.facts || {},
    images: savedImages,
    metadata: savedImages.map((image) => ({
      fileName: image.fileName,
      metadata: maybeExtractMetadata(image.path),
    })),
    status: "submitted",
  };
  runs.set(id, run);
  writeFileSync(path.join(dir, "run.json"), JSON.stringify(run, null, 2));

  content.unshift({ type: "text", text: buildPrompt(run) });
  pi.sendUserMessage(content);
  run.status = "sent_to_pi";
  writeFileSync(path.join(dir, "run.json"), JSON.stringify(run, null, 2));

  json(res, 200, { runId: id, status: run.status });
};

const ensureServer = async (pi: ExtensionAPI): Promise<number> => {
  if (server && serverPort) return serverPort;

  server = createServer(async (req, res) => {
    try {
      const url = new URL(
        req.url || "/",
        `http://${req.headers.host || "127.0.0.1"}`,
      );

      if (req.method === "GET" && url.pathname === "/") {
        text(res, 200, htmlPage(), "text/html; charset=utf-8");
        return;
      }

      if (req.method === "GET" && url.pathname === "/api/config") {
        json(res, 200, { services: servicesCatalog(), maxImages: MAX_IMAGES });
        return;
      }

      if (req.method === "POST" && url.pathname === "/api/submit") {
        await handleSubmit(await readBody(req), pi, res);
        return;
      }

      const runMatch = url.pathname.match(
        /^\/api\/runs\/([^/]+)(?:\/(export\.(md|json|csv)))?$/,
      );
      if (req.method === "GET" && runMatch) {
        const run = getRun(runMatch[1]);
        if (!run) {
          json(res, 404, { error: "Run not found." });
          return;
        }

        const exportType = runMatch[3];
        if (!exportType) {
          json(res, 200, run);
          return;
        }

        if (!run.report) {
          json(res, 404, { error: "Report not ready." });
          return;
        }

        if (exportType === "md") {
          text(
            res,
            200,
            reportToMarkdown(run.report),
            "text/markdown; charset=utf-8",
            {
              "content-disposition": `attachment; filename="${run.id}-geo-report.md"`,
            },
          );
          return;
        }
        if (exportType === "json") {
          json(res, 200, run.report, {
            "content-disposition": `attachment; filename="${run.id}-geo-report.json"`,
          });
          return;
        }
        if (exportType === "csv") {
          text(res, 200, reportToCsv(run.report), "text/csv; charset=utf-8", {
            "content-disposition": `attachment; filename="${run.id}-geo-report.csv"`,
          });
          return;
        }
      }

      json(res, 404, { error: "Not found." });
    } catch (error) {
      json(res, 500, {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });

  await new Promise<void>((resolve, reject) => {
    server!.once("error", reject);
    server!.listen(0, "127.0.0.1", () => {
      const address = server!.address();
      if (!address || typeof address === "string") {
        reject(new Error("Could not bind Geo Workbench server."));
        return;
      }
      serverPort = address.port;
      resolve();
    });
  });

  return serverPort!;
};

const openBrowser = (url: string) => {
  if (process.platform === "darwin") {
    spawn("open", [url], { detached: true, stdio: "ignore" }).unref();
    return;
  }
  spawn("xdg-open", [url], { detached: true, stdio: "ignore" }).unref();
};

const lookupNominatim = async (params: {
  query?: string;
  latitude?: number;
  longitude?: number;
  limit?: number;
}) => {
  let url: URL;
  if (
    typeof params.latitude === "number" &&
    typeof params.longitude === "number"
  ) {
    url = new URL("https://nominatim.openstreetmap.org/reverse");
    url.searchParams.set("format", "jsonv2");
    url.searchParams.set("lat", String(params.latitude));
    url.searchParams.set("lon", String(params.longitude));
    url.searchParams.set("addressdetails", "1");
  } else if (params.query?.trim()) {
    url = new URL("https://nominatim.openstreetmap.org/search");
    url.searchParams.set("format", "jsonv2");
    url.searchParams.set("q", params.query.trim());
    url.searchParams.set("addressdetails", "1");
    url.searchParams.set(
      "limit",
      String(Math.min(Math.max(params.limit || 5, 1), 10)),
    );
  } else {
    throw new Error("Provide query or latitude+longitude.");
  }

  const elapsed = Date.now() - lastNominatimAt;
  if (elapsed < 1100) {
    await new Promise((resolve) => setTimeout(resolve, 1100 - elapsed));
  }
  lastNominatimAt = Date.now();

  const response = await fetch(url, {
    headers: { "user-agent": USER_AGENT, accept: "application/json" },
  });
  if (!response.ok)
    throw new Error(`Nominatim ${response.status}: ${await response.text()}`);
  return { endpoint: url.toString(), results: await response.json() };
};

export default function (pi: ExtensionAPI) {
  pi.registerCommand("geo", {
    description: "Open local browser UI for image geolocation workbench",
    handler: async (_args, ctx) => {
      const port = await ensureServer(pi);
      const url = `http://127.0.0.1:${port}/`;
      openBrowser(url);
      ctx.ui.notify(`Geo Workbench: ${url}`, "info");
    },
  });

  pi.registerTool({
    name: "geo_lookup",
    label: "Geo lookup",
    description:
      "Free geocoding/reverse geocoding lookup using OpenStreetMap Nominatim. Use sparingly; public service has strict rate limits.",
    promptSnippet:
      "Free OSM/Nominatim geocoding or reverse geocoding for geo-workbench candidates",
    promptGuidelines: [
      "Use geo_lookup sparingly when validating candidate addresses or coordinates during geolocation investigations.",
    ],
    parameters: Type.Object({
      query: Type.Optional(
        Type.String({
          description: "Address, business name, or place search text",
        }),
      ),
      latitude: Type.Optional(
        Type.Number({ description: "Latitude for reverse geocoding" }),
      ),
      longitude: Type.Optional(
        Type.Number({ description: "Longitude for reverse geocoding" }),
      ),
      limit: Type.Optional(
        Type.Number({ description: "Max search results 1-10" }),
      ),
    }),
    async execute(_toolCallId, params) {
      const result = await lookupNominatim(params);
      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
        details: result,
      };
    },
  });

  pi.registerTool({
    name: "geo_report",
    label: "Geo report",
    description:
      "Submit final structured report for a Geo Workbench browser run.",
    promptSnippet:
      "Submit final Geo Workbench candidates so browser report/export can update",
    promptGuidelines: [
      "Always call geo_report at the end of a Geo Workbench run with the requested runId and ranked candidates.",
    ],
    parameters: Type.Object({
      runId: Type.String(),
      summary: Type.Optional(Type.String()),
      markdown: Type.Optional(Type.String()),
      confidenceNotes: Type.Optional(Type.String()),
      candidates: Type.Array(
        Type.Object({
          rank: Type.Optional(Type.Number()),
          businessName: Type.Optional(Type.String()),
          address: Type.Optional(Type.String()),
          city: Type.Optional(Type.String()),
          state: Type.Optional(Type.String()),
          country: Type.Optional(Type.String()),
          latitude: Type.Optional(Type.Number()),
          longitude: Type.Optional(Type.Number()),
          confidence: Type.Optional(Type.Number()),
          accuracy: Type.Optional(Type.String()),
          googleMapsUrl: Type.Optional(Type.String()),
          googleEarthUrl: Type.Optional(Type.String()),
          evidence: Type.Optional(Type.Array(Type.String())),
          evidenceAgainst: Type.Optional(Type.Array(Type.String())),
          nextChecks: Type.Optional(Type.Array(Type.String())),
        }),
      ),
    }),
    async execute(_toolCallId, params) {
      const run = getRun(params.runId);
      if (!run) {
        return {
          content: [
            {
              type: "text",
              text: `Geo Workbench run not found: ${params.runId}`,
            },
          ],
          isError: true,
        };
      }

      const report = normalizeReport({
        runId: params.runId,
        summary: params.summary,
        markdown: params.markdown,
        confidenceNotes: params.confidenceNotes,
        candidates: params.candidates || [],
        json: params,
      });
      report.markdown = reportToMarkdown(report);
      run.report = report;
      run.status = "reported";
      writeFileSync(
        path.join(run.dir, "report.json"),
        JSON.stringify(report, null, 2),
      );
      writeFileSync(path.join(run.dir, "report.md"), reportToMarkdown(report));
      writeFileSync(path.join(run.dir, "report.csv"), reportToCsv(report));
      writeFileSync(
        path.join(run.dir, "run.json"),
        JSON.stringify(run, null, 2),
      );

      return {
        content: [
          {
            type: "text",
            text: `Geo Workbench report saved for ${params.runId}. Browser exports are ready.`,
          },
        ],
        details: { runId: params.runId, candidates: report.candidates.length },
      };
    },
  });

  pi.on("session_shutdown", async () => {
    if (server) {
      server.close();
      server = undefined;
      serverPort = undefined;
    }
  });
}
