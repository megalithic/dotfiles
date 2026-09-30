// Vendored from github.com/amosblomqvist/pi-observational-memory at 78a1efc
// (2026-08-25, MIT, see LICENSE) and adapted locally; no upstream sync.
// Worker entry is agent/worker.ts, a folder without index.ts, so Pi never
// auto-discovers it; src/spawn/launch.ts passes it with an explicit -e.
export { default } from "./src/index.ts";
