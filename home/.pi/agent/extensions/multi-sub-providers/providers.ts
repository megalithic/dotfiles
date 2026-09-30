// Providers-only multi-sub entry for restricted children. No index.ts here, so
// Pi never auto-discovers it; launchers load it with an explicit `-e`.
export { registerSubscriptionProviders as default } from "../multi-sub";
