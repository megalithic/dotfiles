// Stub for device emulation state — real implementation lands in ticket
// dot-ezbp (3.4 Device emulation). Until then, scripts run with no
// emulation applied.

export async function applyActiveEmulation(_target) {
  // no-op until 3.4
}

export function readActiveEmulation() {
  return null;
}

export function writeActiveEmulation(_state) {
  // no-op until 3.4
}

export function clearActiveEmulation() {
  // no-op until 3.4
}
