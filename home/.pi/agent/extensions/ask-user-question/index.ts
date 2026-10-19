/**
 * ask_user_question: a structured option selector with an automatically appended
 * `Type something.` custom-answer row.
 *
 * Vendored from @juicesharp/rpiv-ask-user-question 2.13.8 (MIT, see LICENSE).
 * Local changes: no rpiv-config (built-in guidance and collapse key), no
 * rpiv-i18n (English only), and every option requires a `preview` context card,
 * shown beside single-select lists and under multi-select ones (a blank preview
 * falls back to the description).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerAskUserQuestionTool } from "./ask-user-question.js";
import { registerAskUserQuestionReconciler } from "./reconcile.js";

export {
	ASK_USER_BLOCKED_EVENT,
	ASK_USER_PROMPT_EVENT,
	type AskUserBlockedEventPayload,
	type AskUserPromptEventPayload,
	type AskUserPromptOption,
	type AskUserPromptQuestion,
} from "./events.js";

export default function (pi: ExtensionAPI) {
	registerAskUserQuestionTool(pi);
	registerAskUserQuestionReconciler(pi);
}
