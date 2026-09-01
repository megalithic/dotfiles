/**
 * heimdall - bridge other pi extensions' exported functions into
 * agent-callable tools.
 *
 * Pi intentionally blocks agents from dispatching slash commands
 * (earendil-works/pi #4754, #6010), so extensions whose value lives behind
 * user-only commands are unreachable for agents. Heimdall registers plain
 * tools that call those extensions' exported functions directly.
 *
 * One adapter file per bridged extension; shared glue lives in lib.ts.
 * Adapters must degrade to clear tool errors when their target package is
 * missing or incompatible — never crash session startup.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerPlannotatorTools } from "./plannotator.ts";

export default function (pi: ExtensionAPI) {
	registerPlannotatorTools(pi);
}
