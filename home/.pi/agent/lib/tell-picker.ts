import { execFile } from 'node:child_process';
import { stripVTControlCharacters } from 'node:util';
import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Editor, Input, matchesKey, truncateToWidth, visibleWidth, wrapTextWithAnsi } from '@earendil-works/pi-tui';
import { matchesTargetQuery, type Target } from './tell-targets.ts';

export const pickerText = (text: string): string => stripVTControlCharacters(text).replace(/\p{Cc}/gu, ' ');

export type Pick = { candidate: Target; note?: string };

// Keep the live tmux preview only while this Pi owns the tty's foreground job.
export const captureTargetPane = async (target: Target, signal: AbortSignal): Promise<string | undefined> => {
  const pane = target.pi?.tmux?.pane;

  if (!pane || target.host || !target.pi || signal.aborted) return undefined;

  const run = (file: string, args: string[]): Promise<string | undefined> =>
    new Promise((resolve) => {
      if (signal.aborted) return resolve(undefined);
      execFile(file, args, { encoding: 'utf8', timeout: 800, maxBuffer: 128 * 1024, signal }, (error, stdout) =>
        resolve(error ? undefined : stdout),
      );
    });

  const tty = (await run('tmux', ['display-message', '-p', '-t', pane, '#{pane_tty}']))?.trim();

  if (!tty?.startsWith('/dev/')) return undefined;
  const processes = await run('ps', ['-t', tty.slice(5), '-o', 'pid=,pgid=,tpgid=,comm=']);

  const foreground = processes?.split('\n').some((line) => {
    const match = line.trim().match(/^(\d+)\s+(\d+)\s+(\d+)\s+(.*)$/);

    return (
      match && Number(match[1]) === target.pi?.pid && match[2] === match[3] && match[4]?.split('/').at(-1) === 'pi'
    );
  });

  return foreground ? run('tmux', ['capture-pane', '-p', '-t', pane, '-S', '-120']) : undefined;
};

const kinds = ['pi', 'tmux', 'rex', 'ultimate'] as const;

const headings = { pi: 'Pis', tmux: 'tmux', rex: 'Rex', ultimate: 'Ultimate' };

const activityTime = (target: Target): number => Date.parse(target.pi?.statusUpdatedAt || '') || 0;

export const groupedTargets = (targets: Target[]): Target[] =>
  [...targets].sort(
    (a, b) =>
      kinds.indexOf(a.kind) - kinds.indexOf(b.kind) ||
      activityTime(b) - activityTime(a) ||
      a.label.localeCompare(b.label),
  );

/** The Input/Editor picker: grouped two-line options, preview card, note editor. */
export const pickTarget = async (
  choices: Target[],
  ctx: ExtensionContext,
  previewTarget: (target: Target, signal: AbortSignal) => Promise<string>,
  options: { signal?: AbortSignal; query?: string; overlay?: boolean; allowNote?: boolean } = {},
): Promise<Pick | undefined> => {
  if (options.signal?.aborted) return undefined;
  choices = groupedTargets(choices.filter((target) => target.reachable !== false));

  if (ctx.mode !== 'tui') {
    const labels = choices.map((target) => `[${headings[target.kind]}] ${target.label} · ${target.id}`);
    const selected = await ctx.ui.select('Tell an agent', labels);
    const candidate = choices[labels.indexOf(selected || '')];

    return candidate ? { candidate } : undefined;
  }

  return ctx.ui.custom<Pick | undefined>(
    (tui, theme, keybindings, done) => {
      const input = new Input({
        prompt: 'Filter: ',
        placeholder: 'type to filter',
        placeholderStyle: (s) => theme.fg('dim', s),
      });

      if (options.query) input.handleInput(options.query);

      const editor = new Editor(tui, {
        borderColor: (s) => theme.fg('borderMuted', s),
        selectList: {
          selectedPrefix: (s) => theme.fg('accent', s),
          selectedText: (s) => theme.fg('accent', s),
          description: (s) => theme.fg('muted', s),
          scrollInfo: (s) => theme.fg('dim', s),
          noMatch: (s) => theme.fg('warning', s),
        },
      });

      const accent = (s: string) => theme.fg('accent', s);
      let visible = choices;
      let selected = 0;
      let note = '';
      let noteOpen = false;
      let focused = false;
      let closed = false;
      let preview = 'Loading…';
      let previewId: string | undefined | null = null;
      let generation = 0;
      let previewAbort = new AbortController();
      let timer: ReturnType<typeof setTimeout> | undefined;
      let notice = '';

      const dispose = () => {
        closed = true;
        clearTimeout(timer);
        previewAbort.abort();
        options.signal?.removeEventListener('abort', abort);
      };

      const close = (result?: Pick) => {
        if (closed) return;
        dispose();
        done(result);
      };

      const abort = () => close();

      const syncFocus = () => {
        input.focused = focused && !noteOpen;
        editor.focused = focused && noteOpen;
      };

      const filter = () => {
        const query = input.getValue().toLowerCase();
        visible = choices.filter((target) => matchesTargetQuery(target, query));
        selected = 0;
      };

      const loadPreview = async (candidate: Target, version: number, signal: AbortSignal) => {
        const text = await previewTarget(candidate, signal).catch(() => 'Preview unavailable.');

        if (closed || signal.aborted || generation !== version) return;
        preview = stripVTControlCharacters(text)
          .replace(/\r\n?/g, '\n')
          .replace(/[\p{Cc}\p{Cf}]/gu, (c) => (c === '\n' ? c : ' '))
          .slice(0, 4000);
        tui.requestRender();
        timer = setTimeout(() => void loadPreview(candidate, version, signal), 1000);
      };

      const updatePreview = () => {
        const candidate = visible[selected];

        if (candidate?.id === previewId) return;
        previewId = candidate?.id;
        clearTimeout(timer);
        previewAbort.abort();
        previewAbort = new AbortController();
        generation += 1;
        preview = candidate ? 'Loading…' : 'No matching agents.';

        if (candidate) void loadPreview(candidate, generation, previewAbort.signal);
      };

      const card = (candidate: Target | undefined, width: number, rows: number): string[] => {
        const edge = (left: string, label: string, right: string) => {
          const text = truncateToWidth(` ${label} `, Math.max(0, width - 3), '');

          return accent(`${left}─${text}${'─'.repeat(Math.max(0, width - 3 - visibleWidth(text)))}${right}`);
        };

        const count = Math.max(1, rows - 2);
        const lines = wrapTextWithAnsi(preview, Math.max(1, width - 4)).slice(0, count);

        return [
          edge('┌', `Preview · ${candidate?.state || candidate?.kind || ''}`, '┐'),
          ...Array.from(
            { length: count },
            (_, i) =>
              `${accent('│')} ${truncateToWidth(lines[i] || '', Math.max(1, width - 4), '', true)} ${accent('│')}`,
          ),
          edge('└', pickerText(candidate?.cwd || ''), '┘'),
        ];
      };

      const optionRows = (width: number, rows: number): string[] => {
        const capacity = Math.max(1, Math.min(10, Math.floor((rows - 1) / 3)));
        const start = Math.max(0, Math.min(selected - Math.floor(capacity / 2), visible.length - capacity));
        let previous: Target['kind'] | undefined;
        const lines: string[] = [];

        for (const [offset, candidate] of visible.slice(start, start + capacity).entries()) {
          const active = start + offset === selected;

          if (candidate.kind !== previous) lines.push(theme.fg('dim', ` ${headings[candidate.kind]}`));
          previous = candidate.kind;
          const summary = pickerText(candidate.label);
          const prefix = `${active ? '❯' : ' '} ${start + offset + 1}. `;
          lines.push(
            truncateToWidth(
              `${active ? accent(prefix) : prefix}${active ? accent(theme.bold(summary)) : summary}`,
              width,
            ),
          );
          lines.push(
            theme.fg('muted', truncateToWidth(`    ${pickerText(candidate.id)} · ${candidate.machine}`, width)),
          );
        }

        if (!lines.length) lines.push(theme.fg('warning', ' No matching agents'));

        if (visible.length > capacity) lines.push(theme.fg('dim', ` (${selected + 1}/${visible.length})`));

        return lines.slice(0, rows);
      };

      options.signal?.addEventListener('abort', abort, { once: true });
      filter();
      updatePreview();

      return {
        get focused() {
          return focused;
        },
        set focused(value: boolean) {
          focused = value;
          syncFocus();
        },
        render(width: number) {
          const rows = options.overlay
            ? tui.terminal.rows
            : Math.min(tui.terminal.rows, Math.max(12, Math.floor(tui.terminal.rows * 0.7)));

          const candidate = visible[selected];

          const top = [
            accent('─'.repeat(width)),
            ` ${theme.bold('Tell an agent')}`,
            ...input.render(Math.max(1, width - 1)).map((s) => ` ${s}`),
          ];

          const bottom = [
            ...(noteOpen ? [theme.fg('muted', ' Note:'), ...editor.render(Math.max(1, width - 2))] : []),
            ...(options.allowNote && !noteOpen
              ? [theme.fg('dim', note ? ` Note: ${pickerText(note)}` : ' Ctrl+N to add a note')]
              : []),
            ...(notice ? [theme.fg('warning', notice)] : []),
            accent('─'.repeat(width)),
            theme.fg(
              'dim',
              noteOpen
                ? ' Enter to save note · Shift+Enter newline · Esc to close'
                : ' Enter to select · ↑/↓ navigate · Ctrl+G go to tmux pane · Esc cancel',
            ),
          ];

          const room = Math.max(2, rows - top.length - bottom.length);
          let body: string[];

          if (width >= 100) {
            const leftWidth = Math.floor(width * 0.55);
            const left = optionRows(leftWidth, room);
            const right = card(candidate, width - leftWidth - 2, room);
            body = Array.from(
              { length: room },
              (_, i) => `${truncateToWidth(left[i] || '', leftWidth, '', true)}  ${right[i] || ''}`,
            );
          } else {
            const list = optionRows(width, Math.max(2, room - 5));
            body = [...list, ...card(candidate, width, Math.max(3, room - list.length))];
          }

          return [...top, ...body.slice(0, room), ...bottom].slice(0, rows).map((s) => truncateToWidth(s, width, ''));
        },
        invalidate: () => {
          input.invalidate();
          editor.invalidate();
        },
        dispose,
        handleInput(data: string) {
          if (closed) return;
          notice = '';

          if (noteOpen) {
            const newline = keybindings.matches(data, 'tui.input.newLine');

            if (
              (!newline &&
                (keybindings.matches(data, 'tui.select.confirm') || keybindings.matches(data, 'tui.input.submit'))) ||
              keybindings.matches(data, 'tui.select.cancel')
            ) {
              note = editor.getText().trim();
              noteOpen = false;
              syncFocus();
            } else editor.handleInput(data);
          } else if (keybindings.matches(data, 'tui.select.confirm')) {
            const candidate = visible[selected];

            if (candidate) close({ candidate, note: note || undefined });
          } else if (keybindings.matches(data, 'tui.select.cancel')) close();
          else if (options.allowNote && matchesKey(data, 'ctrl+n')) {
            noteOpen = true;
            editor.setText(note);
            syncFocus();
          } else if (matchesKey(data, 'ctrl+g')) {
            const candidate = visible[selected];

            if (candidate?.pi?.tmux?.pane && !candidate.host && process.env.TMUX) {
              execFile(
                'tmux',
                [
                  'switch-client',
                  '-t',
                  `=${candidate.pi.tmux.session}`,
                  ';',
                  'select-window',
                  '-t',
                  candidate.pi.tmux.pane,
                  ';',
                  'select-pane',
                  '-t',
                  candidate.pi.tmux.pane,
                ],
                { timeout: 2000 },
                (error) => {
                  if (!error || closed) return;
                  notice = `Could not switch panes: ${error.message}`;
                  tui.requestRender();
                },
              );
            }
          } else if (keybindings.matches(data, 'tui.select.up') || matchesKey(data, 'up'))
            selected = visible.length ? (selected - 1 + visible.length) % visible.length : 0;
          else if (keybindings.matches(data, 'tui.select.down') || matchesKey(data, 'down'))
            selected = visible.length ? (selected + 1) % visible.length : 0;
          else {
            const before = input.getValue();
            input.handleInput(data);

            if (before !== input.getValue()) filter();
          }

          if (!closed) {
            updatePreview();
            tui.requestRender();
          }
        },
      };
    },
    options.overlay
      ? {
          overlay: true,
          overlayOptions: {
            anchor: 'bottom-center',
            width: '100%',
            maxHeight: '100%',
            margin: { left: 0, right: 0, bottom: 0 },
          },
        }
      : undefined,
  );
};
