// Key-hint HUD for the hyper layer: shown when the layer arms (Shade just
// opened with hyper still held), hidden on a layer key or hyper's release.
//
// sup draws it (`sup show hint … --hold`, through `seams`). When sup can't
// (its daemon isn't running), this falls back to its own canvas.

const ROW = 30;

const PAD = 18;

const WIDTH = 240;

// rows: [{ key: "n", label: "Note" }]
function hudElements(rows) {
  const elements = [
    {
      type: 'rectangle',
      action: 'fill',
      roundedRectRadii: 12,
      fillColor: { red: 0.1, green: 0.1, blue: 0.12, alpha: 0.92 },
    },
  ];

  rows.forEach(({ key, label }, i) => {
    const y = PAD + i * ROW;
    elements.push(
      {
        type: 'text',
        text: key,
        frame: { x: PAD, y, w: 32, h: ROW },
        textSize: 18,
        textDesign: 'monospaced',
        textWeight: 'bold',
        textColor: { red: 0.98, green: 0.78, blue: 0.35, alpha: 1 },
      },
      {
        type: 'text',
        text: label,
        frame: { x: PAD + 40, y, w: WIDTH - PAD * 2 - 40, h: ROW },
        textSize: 18,
        textColor: { white: 0.95, alpha: 1 },
      },
    );
  });

  return elements;
}

function createHud(hs, { rows, seams }) {
  let sup = null;
  let canvas = null;

  function showCanvas() {
    const h = PAD * 2 + rows.length * ROW;
    // Centred on the main screen; centring makes AppKit's bottom-up window
    // origin and the screen's top-down frame agree.
    const f = hs.screen.main().fullFrame;
    canvas = hs.canvas.create({ x: f.x + (f.w - WIDTH) / 2, y: f.y + (f.h - h) / 2, w: WIDTH, h });
    canvas
      .level('overlay')
      .behavior('canJoinAllSpaces')
      .ignoreMouseEvents(true)
      .appendElements(hudElements(rows))
      .show(0.1);
  }

  function show() {
    const task = seams.supHint(rows, (code) => {
      // Only sup ending on its own counts: dismiss() clears `sup` first.
      if (sup !== task) return;
      sup = null;

      if (code !== 0 && !canvas) showCanvas();
    });

    sup = task;
  }

  return {
    show() {
      if (!sup && !canvas) show();
    },
    dismiss() {
      const task = sup;
      sup = null;

      if (task) task.terminate();

      if (canvas) canvas.destroy(0.1);
      canvas = null;
    },
    isShowing: () => sup !== null || canvas !== null,
  };
}

module.exports = { createHud, hudElements };
