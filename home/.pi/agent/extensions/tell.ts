/** Tell any registered Pi or Ultimate. Discovery reads registry files, never a daemon.
 * Pi delivery uses pi.control.v1; exact offline local session IDs use the bridge spool.
 * Terminal and app messages remain custom messages, never terminal approvals.
 */
import crypto from 'node:crypto';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { getAgentDir, type ExtensionAPI, type ExtensionContext } from '@earendil-works/pi-coding-agent';
import { StringEnum } from '@earendil-works/pi-ai';
import type { AutocompleteProvider } from '@earendil-works/pi-tui';
import { Type } from 'typebox';
import { Check } from 'typebox/value';
import { instructionPreamble } from '../lib/messaging.ts';
import { readRegistry } from '../lib/registry.ts';
import { captureTargetPane, pickTarget, pickerText, type Pick } from '../lib/tell-picker.ts';
import { parseSessionTarget, sessionTarget, targetRoute, type Target } from '../lib/tell-targets.ts';
import { control, listTargets, resolveTargetHint, tellUltimate, type Origin } from '../lib/tell-transport.ts';

type Mode = 'steer' | 'follow_up' | 'quiet';

type Route = { machine?: string; target?: string; message: string; mode?: Mode; replyTo?: string };

type Result = {
  ok: boolean;
  id?: string;
  target?: Target;
  note?: string;
  spooled?: string;
  error?: string;
  response?: Awaited<ReturnType<typeof control>>;
};

const stateDir =
  process.env.PI_STATE_DIR ||
  path.join(process.env.XDG_STATE_HOME || path.join(process.env.HOME || '/tmp', '.local/state'), 'pi');

const MAX_TELL_CHARS = 32 * 1024;

const tellRuntime = {
  version: 'tell.v3',
  loadedAt: new Date().toISOString(),
  sourceHash: crypto
    .createHash('sha256')
    .update(fs.readFileSync(new URL(import.meta.url)))
    .digest('hex'),
};

const makeMessageId = () => `tell-${Date.now().toString(36)}-${crypto.randomBytes(4).toString('hex')}`;

const withNote = (note: string | undefined, text: string) => [note?.trim(), text.trim()].filter(Boolean).join('\n\n');

const routeFromTargetHint = (target: string | undefined, message: string, machine?: string, mode?: Mode): Route => {
  const parsed = targetRoute(target?.trim() || '');

  if (machine && parsed.machine && machine !== parsed.machine) throw new Error('Conflicting machine and target prefix');

  return { target: parsed.target || undefined, machine: machine || parsed.machine, message, mode };
};

const originInfo = (ctx: ExtensionContext): Origin => {
  const registry = readRegistry();
  const current = registry.pis.find((pi) => pi.pid === process.pid);

  const socket =
    current?.socket ||
    (process.env.PI_SOCKET_OWNER_PID && process.env.PI_SOCKET_OWNER_PID !== String(process.pid)
      ? ''
      : process.env.PI_SOCKET) ||
    '';

  const terminal = current?.tmux
    ? `tmux:${current.tmux.session}:${current.tmux.window}${current.tmux.pane ? `.${current.tmux.pane}` : ''}`
    : current?.rex
      ? `rex:${current.rex.session || ''}#${current.rex.block || ''}`
      : '';

  return {
    label: [current?.sessionName || sessionTarget(registry.machine, ctx.sessionManager.getSessionId()), terminal]
      .filter(Boolean)
      .join(' · '),
    socket,
    machine: registry.machine,
    cwd: ctx.cwd,
    sessionId: ctx.sessionManager.getSessionId(),
  };
};

const createOutboundPolicy = (now: () => number = Date.now) => {
  const sent: number[] = [];
  const bodies = new Map<string, number>();

  return {
    check(body: string, text: string, target: string): string | undefined {
      if (text.length > MAX_TELL_CHARS)
        return `Message exceeds the cap of ${MAX_TELL_CHARS} chars. Send a summary and file path instead.`;
      const last = bodies.get(`${target}\u0000${body}`);

      if (last !== undefined && now() - last < 10_000)
        return 'Identical message to the same target less than 10s ago; dropped to break loops.';

      while (sent.length && sent[0]! <= now() - 30_000) sent.shift();

      if (sent.length >= 8) return 'Rate limited: at most 8 tells per 30s from this session.';

      return undefined;
    },
    record(body: string, target: string) {
      sent.push(now());
      bodies.set(`${target}\u0000${body}`, now());

      for (const [key, time] of bodies) if (now() - time >= 10_000) bodies.delete(key);
    },
  };
};

const policy = createOutboundPolicy();

const previewTarget = async (target: Target): Promise<string> => {
  if (target.ultimate) return `${target.label}\n${target.socket}`;

  return (
    (await captureTargetPane(target))?.trim().slice(-4000) ||
    (await control(target, 'message.last')).data?.message?.content ||
    'No assistant message yet.'
  );
};

const selectTarget = async (
  target: string | undefined,
  ctx: ExtensionContext,
  inventory: Target[],
  signal?: AbortSignal,
): Promise<Pick | undefined> => {
  if (signal?.aborted) return undefined;
  const choices = target ? await resolveTargetHint(inventory, target) : inventory.filter((entry) => !entry.current);

  if (choices.length === 1 && target) return { candidate: choices[0]! };

  if (ctx.hasUI && choices.length) return pickTarget(choices, ctx, previewTarget, { signal, allowNote: true });
  throw new Error(
    `${choices.length ? 'Ambiguous target' : 'No matching target'}${target ? `: ${target}` : ''}. Candidates:\n${inventory.map((entry) => `- ${entry.id} · ${entry.label}`).join('\n')}`,
  );
};

const sessionFileExists = async (sessionId: string): Promise<boolean> => {
  try {
    const root = path.join(getAgentDir(), 'sessions');

    for (const dir of await fsp.readdir(root, { withFileTypes: true })) {
      if (
        dir.isDirectory() &&
        (await fsp.readdir(path.join(root, dir.name))).some((file) => file.endsWith(`_${sessionId}.jsonl`))
      )
        return true;
    }
  } catch {
    /* No local session history. */
  }

  return false;
};

const guidanceText = (from: Origin, message: string, id: string, replyTo?: string): string =>
  `[TELL:${id}${replyTo ? ` reply to ${replyTo}` : ''} from ${from.label}]\n${message.trim()}\n\nReply only if asked, using tell_pi target ${JSON.stringify(sessionTarget(from.machine, from.sessionId))} and replyTo ${JSON.stringify(id)}.`;

const spoolTell = async (route: Route, id: string, from: Origin, inventory: Target[]): Promise<Result | undefined> => {
  const identity = route.target && parseSessionTarget(route.target);

  if (
    !identity ||
    ![from.machine, 'localhost', '127.0.0.1'].includes(identity.machine) ||
    inventory.some((target) => target.pi?.sessionId === identity.sessionId)
  )
    return undefined;

  if (!(await sessionFileExists(identity.sessionId))) return undefined;
  const text = guidanceText(from, route.message, id, route.replyTo);
  const refused = policy.check(route.message, text, route.target!);

  if (refused) return { ok: false, error: refused };
  const directory = path.join(stateDir, 'spool', encodeURIComponent(identity.sessionId));
  const file = path.join(directory, `${id}.json`);
  await fsp.mkdir(directory, { recursive: true, mode: 0o700 });
  // Spool records retain their existing shape for bridges already running.
  await fsp.writeFile(
    `${file}.tmp`,
    JSON.stringify({
      type: 'tell',
      id,
      text,
      from: from.label,
      fromSocket: from.socket || undefined,
      sessionId: from.sessionId,
      mode: route.mode,
      replyTo: route.replyTo,
    }) + '\n',
    { mode: 0o600 },
  );
  await fsp.rename(`${file}.tmp`, file);
  policy.record(route.message, route.target!);

  return { ok: true, id, spooled: file };
};

const sendTell = async (
  ctx: ExtensionContext,
  route: Route,
  signal?: AbortSignal,
  id = makeMessageId(),
  reply = false,
  selected?: Pick,
): Promise<Result> => {
  try {
    const inventory = await listTargets(route.machine);
    const from = originInfo(ctx);
    const queued = signal?.aborted ? undefined : await spoolTell(route, id, from, inventory);

    if (queued) return queued;

    const fresh =
      selected &&
      inventory.find((target) => target.id === selected.candidate.id && target.socket === selected.candidate.socket);

    if (selected && !fresh) return { ok: false, error: 'Selected agent is no longer registered.' };

    const pick = fresh
      ? { candidate: fresh, note: selected?.note }
      : await selectTarget(route.target, ctx, inventory, signal);

    if (!pick || signal?.aborted) return { ok: false, error: 'Cancelled' };
    const { candidate: target, note } = pick;
    const body = withNote(note, route.message);
    const text = guidanceText(from, body, id, route.replyTo);
    const refused = policy.check(body, text, `${target.host || ''}\u0000${target.socket}`);

    if (refused) return { ok: false, error: refused };
    let response: Result['response'];

    if (target.ultimate) await tellUltimate(target, `${instructionPreamble(from.label)}\n\n${text}`, reply, from, id);
    else
      response = await control(
        target,
        'message.send',
        {
          text,
          messageId: id,
          from: from.label,
          fromSocket: from.socket || undefined,
          sessionId: from.sessionId,
          sessionName: ctx.sessionManager.getSessionName() || undefined,
          timestamp: Math.floor(Date.now() / 1000),
          mode: route.mode || 'follow_up',
          replyTo: route.replyTo,
        },
        id,
      );
    policy.record(body, `${target.host || ''}\u0000${target.socket}`);

    return { ok: true, target, id, note, response };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
};

const splitCommandArgs = (input: string): Partial<Route> => {
  const tokens = [
    ...input
      .trim()
      .replace(/^to\s+/i, '')
      .matchAll(/"((?:\\.|[^"\\])*)"|'([^']*)'|(\S+)/g),
  ].map((m) => (m[1] ?? m[2] ?? m[3]!).replace(/\\"/g, '"'));

  let mode: Mode | undefined;

  if (tokens[0] === '--steer') {
    mode = 'steer';
    tokens.shift();
  } else if (['--follow-up', '--follow_up'].includes(tokens[0] || '')) {
    mode = 'follow_up';
    tokens.shift();
  } else if (tokens[0] === '--quiet') {
    mode = 'quiet';
    tokens.shift();
  }

  // Keep the existing [machine] target command form alongside machine/kind:target.
  const machine =
    tokens.length > 1 && /^(?:megabookpro|workbookpro|[^:/\s]+[.@][^:/\s]+)$/.test(tokens[0] || '')
      ? tokens.shift()
      : undefined;

  return { machine, target: tokens.shift(), message: tokens.join(' '), mode };
};

const createTellAutocompleteProvider = (current: AutocompleteProvider, ctx: ExtensionContext): AutocompleteProvider => {
  const completed = new WeakSet<object>();

  const position = (lines: string[], row: number, col: number) => {
    const draft = lines[0];

    if (lines.length !== 1 || row !== 0 || draft?.length !== col || !/^\s*\/tell\s/.test(draft)) return undefined;
    const trailingSpace = /\s$/.test(draft);
    const tokens = draft.trim().split(/\s+/).slice(1);

    if (['--steer', '--quiet', '--follow-up', '--follow_up'].includes(tokens[0] || '')) {
      if (tokens.length === 1 && !trailingSpace) return undefined;
      tokens.shift();
    }

    if (tokens[0] === 'id' || tokens[0]?.startsWith('--')) return undefined;

    const machine =
      tokens[0] &&
      /^(?:megabookpro|workbookpro|[^:/\s]+[.@][^:/\s]+)$/.test(tokens[0]) &&
      (tokens.length > 1 || trailingSpace)
        ? tokens.shift()
        : undefined;

    if (tokens.length > 1 || (tokens.length === 1 && trailingSpace)) return undefined;
    const word = tokens[0] || '';
    const route = targetRoute(word);

    return { machine: machine || route.machine, query: route.target, prefix: word, start: draft.length - word.length };
  };

  return {
    triggerCharacters: current.triggerCharacters,
    async getSuggestions(lines, row, col, options) {
      const pos = options.force && position(lines, row, col);

      if (!pos) return current.getSuggestions(lines, row, col, options);

      if (options.signal.aborted) return null;

      const pick = await pickTarget(
        (await listTargets(pos.machine)).filter((target) => !target.current),
        ctx,
        previewTarget,
        { signal: options.signal, query: pos.query, overlay: true, allowNote: true },
      );

      if (!pick || options.signal.aborted) return null;
      const target = pick.candidate;
      const address = target.host ? `${target.host}/${target.id}` : target.id;

      const item = {
        value: `${JSON.stringify(address)}${pick.note ? ` ${pickerText(pick.note)}` : ''}`,
        label: target.label,
      };

      completed.add(item);

      return { items: [item], prefix: pos.prefix };
    },
    applyCompletion(lines, row, col, item, prefix) {
      const pos = position(lines, row, col);

      if (!pos || !completed.has(item) || pos.prefix !== prefix)
        return current.applyCompletion(lines, row, col, item, prefix);
      completed.delete(item);
      const line = lines[0]!.slice(0, pos.start) + item.value + ' ';

      return { lines: [line], cursorLine: 0, cursorCol: line.length };
    },
    shouldTriggerFileCompletion(lines, row, col) {
      return Boolean(position(lines, row, col)) || (current.shouldTriggerFileCompletion?.(lines, row, col) ?? true);
    },
  };
};

type Watch = { label: string; socket: string; state: string; target: Target };

const createPresenceWatcher = (notify: (watch: Watch, previous: string) => void, inventory = listTargets) => {
  const watches = new Map<string, Watch>();
  let timer: ReturnType<typeof setInterval> | undefined;
  let polling = false;

  const presence = async (target: Target) => {
    const found = (await inventory(target.host)).find((entry) => entry.id === target.id);

    return !found ? 'offline' : found.state === 'input_needed' ? 'asking' : found.state || 'idle';
  };

  const tick = async () => {
    if (polling) return;
    polling = true;

    try {
      for (const watch of watches.values()) {
        const next = await presence(watch.target).catch(() => 'offline');

        if (next === watch.state) continue;
        const previous = watch.state;
        watch.state = next;
        notify(watch, previous);
      }
    } finally {
      polling = false;
    }
  };

  return {
    async add(target: Target) {
      if (target.ultimate) throw new Error('watch_pi requires a Pi target');
      const watch = { label: pickerText(target.label), socket: target.socket, state: await presence(target), target };
      watches.set(`${target.host || ''}\u0000${target.socket}`, watch);

      if (!timer) {
        timer = setInterval(() => void tick(), 5000);
        timer.unref?.();
      }

      return watch;
    },
    tick,
    clear() {
      clearInterval(timer);
      timer = undefined;
      watches.clear();
    },
  };
};

const replySchema = Type.Object({
  replyTo: Type.String(),
  id: Type.String(),
  from: Type.String(),
  text: Type.String(),
  claimed: Type.Boolean(),
});

const listenerSchema = Type.Object({ error: Type.Union([Type.String(), Type.Null()]) });

type Answer = { replied: true; id: string; from: string; text: string } | { replied: false; reason: string };

const receivedTellSchema = Type.Object({
  direction: Type.Literal('received'),
  from: Type.Optional(Type.String()),
  text: Type.String({ minLength: 1 }),
  timestamp: Type.Optional(Type.Number()),
});

const restoreRecentTellWidget = (ctx: ExtensionContext): void => {
  if (!ctx.hasUI) return;
  const entries = ctx.sessionManager.getEntries();

  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index];

    if (entry?.type !== 'custom' || entry.customType !== 'tell-message' || !Check(receivedTellSchema, entry.data))
      continue;

    if (Date.now() - (entry.data.timestamp || 0) * 1000 > 60 * 60 * 1000) return;
    ctx.ui.setWidget('tell', [
      ctx.ui.theme.fg('accent', `Recent tell from ${pickerText(entry.data.from || 'unknown')}`),
      pickerText(entry.data.text).replace(/\s+/g, ' ').slice(0, 160),
      ctx.ui.theme.fg('muted', 'Persisted in session history'),
    ]);

    return;
  }
};

const modeSchema = Type.Optional(StringEnum(['steer', 'follow_up', 'quiet'] as const));

const machineSchema = Type.Optional(Type.String({ description: 'Optional machine/SSH host.' }));

const targetSchema = Type.String({
  description:
    'pi:<machine>:<sessionId>, session name/folder, tmux:<session>[:<window>[.<pane>]], rex:<session>[/<tab>][#<block>], ultimate:<project|hub>; prefix any kind with machine/.',
});

const formatSessions = (targets: Target[]) =>
  targets.map((target) => `- ${target.id} · ${target.label} (${target.machine})`).join('\n') ||
  'No registered agents found.';

const sentText = (result: Result) =>
  result.spooled
    ? `Queued ${result.id}; that Pi session is not running. Its bridge delivers the message on session start.`
    : `Sent ${result.id} to ${result.target?.label}`;

export const _test = {
  sendTell,
  splitCommandArgs,
  routeFromTargetHint,
  createOutboundPolicy,
  createPresenceWatcher,
  tellRuntime,
  originInfo,
  MAX_TELL_CHARS,
};

export default function (pi: ExtensionAPI): void {
  const watcher = createPresenceWatcher((watch, previous) =>
    pi.sendMessage(
      {
        customType: 'tell:presence',
        content: `watch_pi: ${watch.label} is now ${watch.state} (was ${previous}).`,
        display: true,
        details: { socket: watch.socket, state: watch.state, previous },
      },
      { triggerTurn: false },
    ),
  );

  const waiters = new Map<string, (answer: Answer) => void>();
  const subscriptions: (() => void)[] = [];
  let listenerError: string | null = null;

  const unreachableNote = () =>
    listenerError ? `\nThis session is not reachable; replies cannot arrive: ${listenerError}` : '';

  const cleanup = () => {
    watcher.clear();

    for (const unsubscribe of subscriptions.splice(0)) unsubscribe();

    for (const settle of waiters.values()) settle({ replied: false, reason: 'Session closed.' });
  };

  const waitForReply = (id: string, timeout: number, signal?: AbortSignal): Promise<Answer> =>
    new Promise((resolve) => {
      const settle = (answer: Answer) => {
        clearTimeout(timer);
        signal?.removeEventListener('abort', abort);
        waiters.delete(id);
        resolve(answer);
      };

      const abort = () => settle({ replied: false, reason: 'Cancelled before a reply arrived.' });

      const timer = setTimeout(
        () => settle({ replied: false, reason: `No reply within ${timeout / 1000}s.` }),
        timeout,
      );

      waiters.set(id, settle);

      if (signal?.aborted) abort();
      else signal?.addEventListener('abort', abort, { once: true });
    });

  const record = (result: Result, route: Route) =>
    pi.appendEntry('tell-message', {
      id: result.id,
      direction: 'sent',
      target: result.target?.label || route.target,
      socket: result.target?.socket,
      spooled: result.spooled,
      message: withNote(result.note, route.message),
      mode: route.mode || 'follow_up',
      replyTo: route.replyTo,
      timestamp: Date.now(),
    });

  const failure = (result: Result) => ({
    isError: true,
    content: [{ type: 'text' as const, text: result.error || 'Tell failed' }],
    details: result,
  });

  pi.on('session_shutdown', cleanup);
  pi.on('session_start', (_event, ctx) => {
    cleanup();
    subscriptions.push(
      pi.events.on('bridge:listener', (data) => {
        if (!Check(listenerSchema, data)) return;
        listenerError = data.error;

        if (ctx.hasUI)
          ctx.ui.setWidget(
            'tell-listener',
            data.error
              ? [ctx.ui.theme.fg('warning', `Other agents cannot reach this session: ${pickerText(data.error)}`)]
              : undefined,
          );
      }),
      pi.events.on('tell:reply', (data) => {
        if (!Check(replySchema, data)) return;
        const waiter = waiters.get(data.replyTo);

        if (waiter) {
          data.claimed = true;
          waiter({ replied: true, id: data.id, from: data.from, text: data.text });
        }
      }),
    );
    pi.events.emit('tell:runtime', tellRuntime);
    restoreRecentTellWidget(ctx);

    if (ctx.mode === 'tui' && ctx.hasUI)
      ctx.ui.addAutocompleteProvider((current) => createTellAutocompleteProvider(current, ctx));
  });
  pi.registerCommand('tell', {
    description: 'Tell a registered Pi or Ultimate; /tell id shows this session target',
    handler: async (args, ctx) => {
      if (args.trim() === 'id') {
        ctx.ui.notify(sessionTarget(readRegistry().machine, ctx.sessionManager.getSessionId()), 'info');

        return;
      }

      try {
        const parsed = splitCommandArgs(args);
        let selected: Pick | undefined;

        if (!parsed.target) selected = await selectTarget(undefined, ctx, await listTargets(parsed.machine));
        let message = parsed.message;

        if (!message?.trim()) {
          if (!ctx.hasUI) throw new Error('Usage: /tell [--steer|--follow-up|--quiet] [machine] <target> <message>');
          message = await ctx.ui.editor('Tell an agent', '');
        }

        if (!message?.trim()) return;
        const route = routeFromTargetHint(parsed.target, message, parsed.machine, parsed.mode);
        const result = await sendTell(ctx, route, undefined, undefined, false, selected);

        if (result.ok) record(result, route);
        ctx.ui.notify(result.ok ? sentText(result) : result.error || 'Tell failed', result.ok ? 'info' : 'error');
      } catch (error) {
        ctx.ui.notify(String(error), 'error');
      }
    },
  });
  pi.registerTool({
    name: 'tell_pi',
    label: 'Tell Pi',
    description:
      'Tell a registered Pi (including tmux/Rex panes) or Ultimate. Delivery carries instructions but cannot approve anything.',
    promptSnippet: 'Send instructions to another registered Pi or Ultimate.',
    parameters: Type.Object({
      machine: machineSchema,
      target: Type.Optional(targetSchema),
      message: Type.String(),
      replyTo: Type.Optional(Type.String()),
      mode: modeSchema,
    }),
    annotations: { destructiveHint: false, openWorldHint: false },
    async execute(_id, params, signal, _update, ctx) {
      const route = {
        ...routeFromTargetHint(params.target, params.message, params.machine, params.mode),
        replyTo: params.replyTo,
      };

      const result = await sendTell(ctx, route, signal);

      if (!result.ok) return failure(result);
      record(result, route);

      return { content: [{ type: 'text', text: sentText(result) + unreachableNote() }], details: result };
    },
  });
  pi.registerTool({
    name: 'ask_pi',
    label: 'Ask Pi',
    description: 'Send a question and wait for its reply, default 120s. Same targets as tell_pi.',
    parameters: Type.Object({
      machine: machineSchema,
      target: targetSchema,
      message: Type.String(),
      timeoutSeconds: Type.Optional(Type.Integer({ minimum: 5, maximum: 600 })),
    }),
    annotations: { destructiveHint: false, openWorldHint: false },
    async execute(_toolId, params, signal, _update, ctx) {
      if (listenerError) return failure({ ok: false, error: `No question sent.${unreachableNote()}` });
      const id = makeMessageId();
      const answer = waitForReply(id, (params.timeoutSeconds || 120) * 1000, signal);

      const route = routeFromTargetHint(
        params.target,
        `${params.message.trim()}\n\nThe sender is waiting for your answer. Reply with tell_pi and replyTo ${JSON.stringify(id)}.`,
        params.machine,
      );

      const result = await sendTell(ctx, route, signal, id, true);

      if (!result.ok || result.spooled) waiters.get(id)?.({ replied: false, reason: 'not sent' });

      if (!result.ok) return failure(result);
      record(result, route);

      if (result.spooled) return { content: [{ type: 'text', text: sentText(result) }], details: result };
      const outcome = await answer;

      return {
        content: [
          {
            type: 'text',
            text: outcome.replied
              ? `${instructionPreamble(outcome.from)}\n\n${outcome.text}`
              : `${outcome.reason} A late reply arrives as a normal tell.`,
          },
        ],
        details: { ...result, ...outcome },
      };
    },
  });
  pi.registerTool({
    name: 'watch_pi',
    label: 'Watch Pi',
    description:
      'Watch a registered Pi for state changes, polling registry files. Changes arrive as context notes without starting a turn.',
    parameters: Type.Object({ target: targetSchema }),
    annotations: { readOnlyHint: true, openWorldHint: false },
    async execute(_id, params, signal, _update, ctx) {
      try {
        const route = routeFromTargetHint(params.target, '');
        const pick = await selectTarget(route.target, ctx, await listTargets(route.machine), signal);

        if (!pick) throw new Error('Cancelled');
        const watch = await watcher.add(pick.candidate);

        return {
          content: [{ type: 'text', text: `Watching ${watch.label}; it is ${watch.state} now.` }],
          details: watch,
        };
      } catch (error) {
        return failure({ ok: false, error: String(error) });
      }
    },
  });
  pi.registerTool({
    name: 'list_pi_sessions',
    label: 'List Pi Sessions',
    description: 'List registered Pis and Ultimates locally or over SSH.',
    parameters: Type.Object({ machine: machineSchema }),
    annotations: { readOnlyHint: true, openWorldHint: false },
    async execute(_id, params) {
      const candidates = await listTargets(params.machine);

      return {
        content: [{ type: 'text', text: formatSessions(candidates) + unreachableNote() }],
        details: { candidates },
      };
    },
  });

  const lastMessage = async (
    target: string,
    machine: string | undefined,
    ctx: ExtensionContext,
    signal?: AbortSignal,
  ) => {
    const route = routeFromTargetHint(target, '', machine);
    const pick = await selectTarget(route.target, ctx, await listTargets(route.machine), signal);

    if (!pick) throw new Error('Cancelled');

    return { target: pick.candidate, message: (await control(pick.candidate, 'message.last')).data?.message };
  };

  pi.registerTool({
    name: 'get_pi_last_message',
    label: 'Get Pi Last Message',
    description: 'Retrieve the last assistant message from a Pi target.',
    parameters: Type.Object({ machine: machineSchema, target: targetSchema }),
    annotations: { readOnlyHint: true, openWorldHint: false },
    async execute(_id, params, signal, _update, ctx) {
      try {
        const result = await lastMessage(params.target, params.machine, ctx, signal);

        return {
          content: [{ type: 'text', text: result.message?.content.slice(0, 30_000) || 'No assistant message yet.' }],
          details: result,
        };
      } catch (error) {
        return failure({ ok: false, error: String(error) });
      }
    },
  });
  pi.registerCommand('tell-sessions', {
    description: 'List registered local or remote agents',
    handler: async (args, ctx) => {
      try {
        ctx.ui.notify(formatSessions(await listTargets(args.trim() || undefined)), 'info');
      } catch (error) {
        ctx.ui.notify(String(error), 'error');
      }
    },
  });
  pi.registerCommand('tell-last', {
    description: 'Show the last assistant message from a Pi',
    handler: async (args, ctx) => {
      try {
        const parsed = splitCommandArgs(args);

        if (!parsed.target) throw new Error('Usage: /tell-last [machine] <target>');
        const result = await lastMessage(parsed.target, parsed.machine, ctx);
        await ctx.ui.editor(
          `Last assistant message from ${result.target.label}`,
          result.message?.content || 'No assistant message yet.',
        );
      } catch (error) {
        ctx.ui.notify(String(error), 'error');
      }
    },
  });
}
