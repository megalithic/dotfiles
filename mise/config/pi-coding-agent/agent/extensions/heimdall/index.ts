// @ts-nocheck
/**
 * Heimdall bridges Pi agents to extension slash-command behavior.
 *
 * Pi intentionally blocks agents from dispatching slash commands
 * (earendil-works/pi #4754, #6010). Heimdall works around that boundary by
 * registering agent tools that call target extensions' exported modules and
 * functions directly. Adapters must preserve their slash commands' lifecycle
 * and semantics; they are not new implementations of target features.
 *
 * Heimdall is extension-agnostic. Each bridged extension gets one adapter;
 * Plannotator is only the first. Shared loading/lifecycle glue lives in lib.ts.
 * Missing or incompatible target packages must return clear tool errors and
 * never crash Heimdall or Pi startup.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerPlannotatorTools } from "./plannotator.ts";

// @lat: [[pi-coding-agent#Session and routing extensions]]
export default function (pi: ExtensionAPI) {
 registerPlannotatorTools(pi);
}
