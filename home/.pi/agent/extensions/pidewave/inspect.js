// Tidewave Inspect, run in an app or Connect tab over CDP (Runtime.evaluate, awaitPromise).
// The toolbar collapses to its logo pill until hovered, so a hidden button gets one
// synthetic mouseover first. On a Connect tab it acts in the session frame shown on top.
// Resolves 'active' or a short reason. Moved unchanged from Hammerspoon pidewave.lua.
(expectedOrigin) =>
  new Promise((resolve) => {
    const deadline = Date.now() + 4000;
    let clicked = false;
    let expanded = false;

    const inspect = () => {
      let doc = document;

      if (location.origin === expectedOrigin && location.pathname === '/tidewave/connect') {
        const frames = [...document.querySelectorAll('iframe[name^="tidewave-control-session-"]')];

        const shown = frames.filter((f) => {
          const r = f.getBoundingClientRect();

          return r.width > 0 && r.height > 0 && document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2) === f;
        });

        const frame = shown.length === 1 ? shown[0] : frames.find((f) => f === document.activeElement);
        doc = frame && frame.contentDocument;

        if (!doc) {
          resolve(`no-session:${frames.length}:${shown.length}`);

          return;
        }
      }

      const localApp =
        doc.location.origin === expectedOrigin &&
        doc.location.pathname !== '/tidewave' &&
        !doc.location.pathname.startsWith('/tidewave/');

      if (!localApp) {
        resolve(`location-mismatch:${doc.location.href}`);

        return;
      }

      const host = doc.getElementById('tidewave-toolbar');
      const root = host && host.shadowRoot;

      const button =
        root &&
        [...root.querySelectorAll('button,[role=button]')].find((b) =>
          /inspect/i.test(b.getAttribute('aria-label') || b.title || b.textContent || ''),
        );

      const enabled = button && !button.disabled && button.getAttribute('aria-disabled') !== 'true';
      const rect = button && button.getBoundingClientRect();

      const visible =
        enabled &&
        button.isConnected &&
        (button.checkVisibility
          ? button.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })
          : rect.width > 0 && rect.height > 0);

      const selected = visible && button.classList.contains('bg-accent');
      const active = selected && root.querySelector('[data-testid="inspector-panel"]');
      const ready = doc.readyState === 'complete' && doc.visibilityState === 'visible';

      if (ready && active) {
        resolve('active');

        return;
      }

      const logo = root && root.querySelector('[aria-label="Tidewave"]');
      const pill = logo && logo.parentElement;

      if (ready && enabled && !visible && pill && !expanded) {
        pill.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
        expanded = true;
      }

      if (ready && visible && !selected && !clicked) {
        button.click();
        clicked = true;
      }

      if (Date.now() >= deadline) {
        const buttonState = !button
          ? 'no-button'
          : !enabled
            ? 'button-disabled'
            : !visible
              ? expanded
                ? 'expand-unconfirmed'
                : 'button-hidden'
              : clicked
                ? 'click-unconfirmed'
                : 'button';

        resolve(`not-ready:${doc.readyState}:${doc.visibilityState}:${host ? 'toolbar' : 'no-toolbar'}:${buttonState}`);

        return;
      }

      setTimeout(inspect, 100);
    };

    inspect();
  });
