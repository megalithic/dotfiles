/* oxlint-disable anti-slop/no-runtime-typeof -- page script: it probes host objects in an untyped browser realm */
// Pidewave page script. Pi injects it over CDP into every frame of every tab on
// its Phoenix origin (Page.addScriptToEvaluateOnNewDocument) and listens on the
// `__pidewave` binding (Runtime.addBinding). The page never picks the Pi: CDP
// tells Pi which tab called. Clipboard writes still happen, so pasting works.
(() => {
  if (window.__pidewaveShim) return;
  window.__pidewaveShim = true;

  const send = (message) => {
    const binding = window.__pidewave;

    if (typeof binding !== 'function') return;

    try {
      binding(JSON.stringify(message));
    } catch {}
  };

  // Toolbar prompts carry <user_prompt>. On the Connect page every copy button
  // copies agent instructions (sentences), except "Copy MCP server URL" (no spaces).
  const connect = location.pathname === '/tidewave/connect';

  const relevant = (text) =>
    typeof text === 'string' && (text.includes('<user_prompt>') || (connect && /\s/.test(text.trim())));

  let last = '';
  let lastAt = 0;

  const forward = (text) => {
    if (!relevant(text)) return;
    const now = Date.now();

    // writeText and the execCommand fallback's copy event can both see one copy.
    if (text === last && now - lastAt < 2000) return;
    last = text;
    lastAt = now;
    send({ kind: 'prompt', text, href: location.href });
  };

  const clipboard = navigator.clipboard;

  if (clipboard && typeof clipboard.writeText === 'function') {
    const original = clipboard.writeText.bind(clipboard);

    clipboard.writeText = (text) => {
      forward(text);

      return original(text);
    };
  }

  // Bubble phase on window, so a page handler that calls setData has run first.
  window.addEventListener('copy', (event) => {
    const data = event.clipboardData ? event.clipboardData.getData('text/plain') : '';
    const field = document.activeElement;

    const selected =
      field && typeof field.value === 'string' && typeof field.selectionStart === 'number'
        ? field.value.slice(field.selectionStart, field.selectionEnd)
        : String(document.getSelection() || '');

    forward(data || selected);
  });

  let activeAt = 0;

  const active = () => {
    const now = Date.now();

    if (now - activeAt < 1000) return;
    activeAt = now;
    send({ kind: 'active' });
  };

  window.addEventListener('focus', active, true);
  window.addEventListener('pointerdown', active, true);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') active();
  });

  // Cmd+Shift+C: Tidewave Inspect in this tab. Ctrl+Shift+P: bring the Pi's terminal forward.
  window.addEventListener(
    'keydown',
    (event) => {
      const chord = (meta, ctrl, code) =>
        event.metaKey === meta && event.ctrlKey === ctrl && event.shiftKey && !event.altKey && event.code === code;

      const kind = chord(true, false, 'KeyC') ? 'inspect' : chord(false, true, 'KeyP') ? 'focus-pi' : undefined;

      if (!kind) return;
      event.preventDefault();
      event.stopPropagation();
      send({ kind });
    },
    true,
  );

  if (window !== window.top) return;

  window.__pidewaveToast = (text, ok) => {
    const note = document.createElement('div');
    note.textContent = text;
    note.setAttribute('role', 'status');
    note.style.cssText = [
      'position:fixed',
      'right:16px',
      'bottom:16px',
      'z-index:2147483647',
      'padding:8px 12px',
      'border-radius:8px',
      'font:13px/1.3 system-ui,sans-serif',
      'color:#fff',
      `background:${ok ? '#1d6f8f' : '#a33'}`,
      'box-shadow:0 2px 8px rgba(0,0,0,.3)',
    ].join(';');
    document.documentElement.append(note);
    setTimeout(() => note.remove(), 2500);
  };
})();
