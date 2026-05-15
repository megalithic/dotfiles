// Stub for device presets — real implementation lands in ticket
// dot-ezbp (3.4 Device emulation). screenshot.js imports the named exports
// below; they all no-op until 3.4.

export function listDevicePresets() {
  return [];
}

export function resolveDevicePreset(_name) {
  return null;
}

export async function applyDevicePreset(_target, _preset) {
  // no-op until 3.4
}

export async function clearDeviceEmulation(_target) {
  // no-op until 3.4
}
