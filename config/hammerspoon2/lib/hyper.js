// What the hyper layer does, wired to sup and Shade (init.js runs this; the
// tests run it with a mock hs):
// - hyper down: sup's actions hint over its target toast (esc Dismiss,
//   ⏎ Open), until hyper goes up or a chord acts. Without a target sup
//   exits at once and nothing shows.
// - hyper+Return: `sup open` opens the target toast's source; with none (exit
//   3) it toggles Shade on `verb`, and when Shade shows, the layer arms its
//   bindings (Shade's verbs) for the rest of the hold.
// - hyper+Escape: `sup dismiss --action`, which removes what sup's config
//   `actions.dismiss` names (every toast); exit 3 (nothing to dismiss) is normal.

const { startLayer } = require('./hyper_layer.js');

function startHyper(hs, { seams, hud, bindings, verb }) {
  let actions = null;

  function endActions() {
    actions?.terminate();
    actions = null;
  }

  return startLayer(hs, {
    trigger: 'return',
    bindings,
    chords: ['escape'],
    onHyper: () => {
      endActions();
      actions = seams.supActions();
    },
    onTrigger: (arm) => {
      endActions();
      seams.supOpen(() =>
        seams.shadeToggle(verb, (visible) => {
          if (visible) arm();
        }),
      );
    },
    onChord: () => {
      endActions();
      seams.supDismissAction();
    },
    onArm: () => hud.show(),
    onAction: (action) => {
      hud.dismiss();
      seams.shadeShow(action);
    },
    onRelease: () => {
      endActions();
      hud.dismiss();
    },
  });
}

module.exports = { startHyper };
