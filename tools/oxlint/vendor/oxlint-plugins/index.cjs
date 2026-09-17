Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
//#region src-js/package/define.ts
/**
* Define a plugin.
*
* No-op function, just to provide type safety. Input is passed through unchanged.
*
* @param plugin - Plugin to define
* @returns Same plugin as passed in
*/
function definePlugin(plugin) {
	return plugin;
}
/**
* Define a rule.
*
* No-op function, just to provide type safety. Input is passed through unchanged.
*
* @param rule - Rule to define
* @returns Same rule as passed in
*/
function defineRule(rule) {
	return rule;
}
//#endregion
//#region src-js/package/compat.ts
const EMPTY_VISITOR = {};
/**
* Convert a plugin which used Oxlint's `createOnce` API to also work with ESLint.
*
* If any of the plugin's rules use the Oxlint alternative `createOnce` API,
* add ESLint-compatible `create` methods to those rules, which delegate to `createOnce`.
* This makes the plugin compatible with ESLint.
*
* The `plugin` object passed in is mutated in-place.
*
* @param plugin - Plugin to convert
* @returns Plugin with all rules having `create` method
* @throws {Error} If `plugin` is not an object, or `plugin.rules` is not an object
*/
function eslintCompatPlugin(plugin) {
	if (typeof plugin != "object" || !plugin) throw Error("Plugin must be an object");
	let { rules } = plugin;
	if (typeof rules != "object" || !rules) throw Error("Plugin must have an object as `rules` property");
	let afterHooksState = new AfterHooksState();
	for (let ruleName in rules) Object.hasOwn(rules, ruleName) && convertRule(rules[ruleName], afterHooksState);
	return plugin;
}
/**
* Class containing state for tracking if any `after` hooks for a plugin's rules need to be called.
*
* # Aims
*
* Aims are:
* 1. `after` hook of each rule runs after all other AST visit functions, and CFG event handlers.
* 2. `after` hooks for *all* a plugin's rules run after *all* that plugin's rules have completed visiting AST.
* 3. `after` hooks for *all* a plugin's rules run before *any* of plugin's rules begin linting another file.
* 4. In the case of an error during AST traversal, `after` hooks are always still run.
*
* The above exactly matches the behavior when running a `createOnce` rule in Oxlint.
*
* # Why this is important
*
* All the complication comes from ensuring `after` hooks run even after an error during AST traversal.
*
* In ESLint CLI, an error will crash the process, so it doesn't particularly matter if `after` hooks run or not,
* but language servers will typically swallow errors, and keep the process running.
*
* Rules using `before` and `after` hooks will often rely on both hooks running in a predictable order,
* to maintain some internal state. For example, they may use `before` and `after` hooks to maintain a per-file
* cache of data which is shared between rules. The cache use case is why rule (2) above is important.
*
* Below is an example of using `before` and `after` hooks to maintain a per-file cache, shared between rules.
* It relies on all `before` hooks running before any rule starts visiting the AST,
* and all `after` hooks running after all rules have finished visiting the AST.
*
* ```ts
* let cache: Data | null = null;
*
* let numRunningRules = 0;
*
* const setupCache = (context) => {
*   if (cache === null) cache = new Data(context);
*   numRunningRules++;
* };
*
* const teardownCache = () => {
*   numRunningRules--;
*   if (numRunningRules === 0) cache = null;
* };
*
* const rule1 = {
*   createOnce(context) {
*     return {
*       before() {
*         setupCache(context);
*       },
*       Identifier(node) {
*         // Use `cache`
*       },
*       after: teardownCache,
*     };
*   },
* };
*
* const rule2 = {
*   // Same as above
* };
*
* const rule3 = {
*   // Same as above
* };
* ```
*
* If `after` hooks did not always run, the next lint run could get stale state, and malfunction.
* If `after` hooks ran in the wrong order (e.g. after some `before` hooks for next file),
* `numRunningRules` would never get to 0, and cache would never be cleared.
*
* Note that because all rules run together in a single AST traversal, if a rule from plugin X throws an error,
* it can disrupt rules from plugin Y. This would make it hard to debug.
*
* # Mechanism
*
* ## Initialization
*
* Rules with an `after` hook register themselves by:
*
* 1. Calling `registerResetFunction` to register a function to run `after` hook and clean up internal state.
*    This call adds the reset fn to `resetFunctions`, and adds `AFTER_HOOK_INACTIVE` to `pendingStates`.
* 2. Adding an `onCodePathEnd` CFG event handler to the visitor which calls `ruleFinished` at end of AST traversal.
*
* ## Per-file setup
*
* Before linting a file, `create` will call `setupAfterHook` which is created by `createContextAndVisitor`.
* This registers that the `after` hook for the rule needs to run, by setting `pendingStates[ruleIndex]`
* to `AFTER_HOOK_PENDING`, and incrementing `pendingCount`.
*
* If a cleanup microtask has not been scheduled yet, one is scheduled now (see reason below).
*
* ## Normal operation
*
* AST traversal for each rule ends with `ruleFinished` hook being called from `onCodePathEnd` CFG event handler.
* It increments `lintFinishedCount`. If `lintFinishedCount` equals `pendingCount`, all rules have finished linting
* the file, and `reset` is called, which calls all the pending `after` hooks.
*
* ## Error handling
*
* If an error is thrown during AST traversal, we ensure that `after` hooks are still run by 2 mechanisms:
*
* ### 1. Next microtick
*
* Before any rules began linting files, a microtask was scheduled, which runs on next micro-tick.
* All language servers we're aware of run each lint task in a separate tick, so this microtask will run in next tick
* after a linting run, before the next lint task starts.
*
* If the linting run completed successfully, the microtask does nothing.
*
* But if an error was thrown during AST traversal, this will be visible from the state of `pendingCount`.
* The microtask will run any `after` hooks which need to be run, and reset state to reflect that there are
* no more pending `after` hooks.
*
* ### 2. Fallback: Next lint run
*
* Before linting any file, the state of `pendingCount` is checked.
* If any `after` hooks are still pending, they are run immediately.
* They're run before the `context` objects in `createOnce` closures are updated to the next file,
* so they run with access to the old `context` object from the last file.
*
* This fallback should not be required, but it's included as "belt and braces", to handle if any language server
* or other environment running ESLint programmatically, does not pause a tick between linting runs.
*/
var AfterHooksState = class {
	resetFunctions = [];
	pendingStates = [];
	pendingCount = 0;
	lintFinishedCount = 0;
	resetIsScheduled = !1;
	sourceCode = null;
	resetMicrotask = this.resetMicrotaskImpl.bind(this);
	/**
	* Register a function to run `after` hook for a rule, and reset state.
	* @param reset - Function to run `after` hook and reset state
	* @returns Index of rule
	*/
	registerResetFunction(reset) {
		let { pendingStates } = this, index = pendingStates.length;
		return pendingStates.push(0), this.resetFunctions.push(reset), index;
	}
	/**
	* Register that a rule with `after` hook has completed linting a file.
	* Called by `onCodePathEnd` CFG event handler which is added to visitor for rules with `after` hooks.
	*
	* If all rules with an `after` hook which needs to be run have completed linting the file, run all `after` hooks.
	*/
	ruleFinished() {
		this.lintFinishedCount++, this.lintFinishedCount === this.pendingCount && this.reset(!1);
	}
	/**
	* Call all reset functions where corresponding entry in `pendingStates` is `AFTER_HOOK_PENDING`.
	* Should only be called when some `after` hooks are pending.
	*
	* @param ignoreErrors - `true` to catch and silently ignore any errors which occur in `after` hooks.
	*   `false` to throw them,
	* @throws {unknown} If `ignoreErrors` is `false` and an error occurs in any `after` hooks.
	*/
	reset(ignoreErrors) {
		this.pendingCount;
		let { resetFunctions, pendingStates } = this, hooksLen = pendingStates.length, hasError = !1, error;
		for (let i = 0; i < hooksLen; i++) if (pendingStates[i] !== 0) {
			pendingStates[i] = 0;
			try {
				resetFunctions[i]();
			} catch (e) {
				hasError === !1 && (hasError = !0, error = e);
			}
		}
		if (this.pendingCount = 0, this.lintFinishedCount = 0, this.sourceCode = null, hasError === !0 && ignoreErrors === !1) throw error;
	}
	/**
	* Schedule a microtask to run `reset` functions.
	*/
	scheduleReset() {
		queueMicrotask(this.resetMicrotask), this.resetIsScheduled = !0;
	}
	/**
	* Function which is scheduled as the cleanup microtask.
	* `scheduleReset` uses `resetMicrotask` which is this method bound to `this`.
	*/
	resetMicrotaskImpl() {
		this.resetIsScheduled = !1, this.pendingCount !== 0 && this.reset(!0);
	}
};
/**
* Convert a rule.
*
* The `rule` object passed in is mutated in-place.
*
* @param rule - Rule to convert
* @param afterHooksState - State of `after` hooks
* @throws {Error} If `rule` is not an object
*/
function convertRule(rule, afterHooksState) {
	if (typeof rule != "object" || !rule) throw Error("Rule must be an object");
	if ("create" in rule) return;
	let context = null, visitor, beforeHook, setupAfterHook;
	rule.create = (eslintContext) => {
		context === null && ({context, visitor, beforeHook, setupAfterHook} = createContextAndVisitor(rule, afterHooksState));
		let eslintFileContext = Object.getPrototypeOf(eslintContext);
		if (setupAfterHook !== null) {
			let { sourceCode } = eslintFileContext;
			afterHooksState.sourceCode !== sourceCode && (afterHooksState.sourceCode = sourceCode, afterHooksState.pendingCount !== 0 && afterHooksState.reset(!0));
		}
		return Object.defineProperties(context, {
			id: { value: eslintContext.id },
			options: { value: eslintContext.options },
			report: { value: eslintContext.report }
		}), Object.setPrototypeOf(context, eslintFileContext), beforeHook !== null && beforeHook() === !1 ? EMPTY_VISITOR : (setupAfterHook !== null && (setupAfterHook(eslintFileContext.sourceCode.ast), afterHooksState.resetIsScheduled === !1 && afterHooksState.scheduleReset()), visitor);
	};
}
const FILE_CONTEXT = Object.freeze({
	get filename() {
		throw Error("Cannot access `context.filename` in `createOnce`");
	},
	getFilename() {
		throw Error("Cannot call `context.getFilename` in `createOnce`");
	},
	get physicalFilename() {
		throw Error("Cannot access `context.physicalFilename` in `createOnce`");
	},
	getPhysicalFilename() {
		throw Error("Cannot call `context.getPhysicalFilename` in `createOnce`");
	},
	get cwd() {
		throw Error("Cannot access `context.cwd` in `createOnce`");
	},
	getCwd() {
		throw Error("Cannot call `context.getCwd` in `createOnce`");
	},
	get sourceCode() {
		throw Error("Cannot access `context.sourceCode` in `createOnce`");
	},
	getSourceCode() {
		throw Error("Cannot call `context.getSourceCode` in `createOnce`");
	},
	get languageOptions() {
		throw Error("Cannot access `context.languageOptions` in `createOnce`");
	},
	get settings() {
		throw Error("Cannot access `context.settings` in `createOnce`");
	},
	extend(extension) {
		return Object.freeze(Object.assign(Object.create(this), extension));
	},
	get parserOptions() {
		throw Error("Cannot access `context.parserOptions` in `createOnce`");
	},
	get parserPath() {
		throw Error("Cannot access `context.parserPath` in `createOnce`");
	}
});
/**
* Call `createOnce` method of rule, and return `Context`, `Visitor`, and `beforeHook` (if any).
*
* @param rule - Rule with `createOnce` method
* @param afterHooksState - State of `after` hooks
* @returns Object with `context`, `visitor`, and `beforeHook` properties,
*   and `setupAfterHook` function if visitor has an `after` hook
*/
function createContextAndVisitor(rule, afterHooksState) {
	let { createOnce } = rule;
	if (createOnce == null) throw Error("Rules must define either a `create` or `createOnce` method");
	if (typeof createOnce != "function") throw Error("Rule `createOnce` property must be a function");
	let context = Object.create(FILE_CONTEXT, {
		id: {
			value: null,
			enumerable: !0,
			configurable: !0
		},
		options: {
			value: null,
			enumerable: !0,
			configurable: !0
		},
		report: {
			value() {
				throw Error("Cannot report errors in `createOnce`");
			},
			enumerable: !0,
			configurable: !0
		}
	}), { before: beforeHook, after: afterHook, ...visitor } = createOnce.call(rule, context);
	if (beforeHook === void 0) beforeHook = null;
	else if (beforeHook !== null && typeof beforeHook != "function") throw Error("`before` property of visitor must be a function if defined");
	let setupAfterHook = null;
	if (afterHook != null) {
		if (typeof afterHook != "function") throw Error("`after` property of visitor must be a function if defined");
		let program = null, ruleIndex = afterHooksState.registerResetFunction(() => {
			program = null, afterHook();
		});
		setupAfterHook = (ast) => {
			program = ast, afterHooksState.pendingStates[ruleIndex] = 1, afterHooksState.pendingCount++;
		};
		let onCodePathEnd = visitor.onCodePathEnd;
		visitor.onCodePathEnd = onCodePathEnd == null ? function(_codePath, node) {
			node === program && afterHooksState.ruleFinished();
		} : function(codePath, node) {
			onCodePathEnd.call(this, codePath, node), node === program && afterHooksState.ruleFinished();
		};
	}
	return {
		context,
		visitor,
		beforeHook,
		setupAfterHook
	};
}
exports.definePlugin = definePlugin, exports.defineRule = defineRule, exports.eslintCompatPlugin = eslintCompatPlugin;
