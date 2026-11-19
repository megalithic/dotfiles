// Hyper layer: while the hyper key (F19, from kanata) is held, the trigger key
// (Return) is consumed and runs onTrigger. onTrigger gets an `arm` callback;
// calling it while the same hyper hold is still down arms the layer, and only
// an armed layer consumes its keys and runs their action. Releasing hyper
// disarms it. Hyper itself always passes through, so v1 Hammerspoon keeps its
// own F19 hotkey and hyper modal, and an unarmed layer passes every key to v1.
//
// No Carbon hotkey on F19 here: two apps registering the same hotkey is the
// one thing that could break v1's hyper. A session event tap only watches.

const F19 = 80; // kVK_F19

// keys: { [keyCode]: action }. onTrigger(arm) runs on the trigger's key down,
// onAction(action) on an armed key's down, onArm() when the layer arms,
// onHyper() when hyper goes down and onRelease() when it goes up (auto-repeat
// ignored). chords: { [keyCode]: chord }, consumed like the trigger whenever
// hyper is held, run onChord(chord).
// Returns handle(type, keyCode) -> true to pass the event on, false to consume.
function createLayer({
  trigger,
  keys,
  onTrigger,
  onAction,
  chords = {},
  onChord = () => {},
  onArm = () => {},
  onHyper = () => {},
  onRelease = () => {},
  hyperKeyCode = F19,
}) {
  let held = false;
  let armed = false;
  // Counts hyper holds, so a late arm() from an earlier hold does nothing.
  let hold = 0;
  // Each physical press keeps its first key down's decision until its key up:
  // repeats and the release of a consumed press are consumed (even after
  // hyper's release), those of a passed press pass (even after arming).
  const consumed = new Set();
  const passed = new Set();

  function armFor(thisHold) {
    return () => {
      if (!held || hold !== thisHold || armed) return;

      armed = true;
      onArm();
    };
  }

  function handle(type, keyCode) {
    if (keyCode === hyperKeyCode) {
      if (type === 'keyDown' && !held) {
        held = true;
        hold += 1;
        onHyper();
      } else if (type === 'keyUp' && held) {
        held = false;
        armed = false;
        onRelease();
      }

      return true;
    }

    if (type === 'keyUp') {
      passed.delete(keyCode);

      return !consumed.delete(keyCode);
    }

    if (type !== 'keyDown') return true;

    if (consumed.has(keyCode)) return false;

    if (passed.has(keyCode)) return true;

    if (keyCode === trigger && held) {
      consumed.add(keyCode);
      onTrigger(armFor(hold));

      return false;
    }

    if (keyCode in chords && held) {
      consumed.add(keyCode);
      onChord(chords[keyCode]);

      return false;
    }

    if (keyCode in keys && armed) {
      consumed.add(keyCode);
      onAction(keys[keyCode]);

      return false;
    }

    passed.add(keyCode);

    return true;
  }

  return { handle, isHeld: () => held, isArmed: () => armed };
}

// Wires a layer to a session event tap. trigger: a key name ("return");
// bindings: [{ key: "n", action }]; chords: key names ("escape"), passed to
// onChord by name. Key names resolve through hs.keycodes.map, which follows
// the current layout.
function startLayer(hs, { trigger, bindings, chords: chordNames = [], ...callbacks }) {
  const keys = {};
  const chords = {};

  for (const { key, action } of bindings) keys[hs.keycodes.map[key]] = action;

  for (const key of chordNames) chords[hs.keycodes.map[key]] = key;

  const layer = createLayer({ trigger: hs.keycodes.map[trigger], keys, chords, ...callbacks });
  const { keyDown, keyUp } = hs.eventtap.eventTypes;
  const typeName = { [keyDown]: 'keyDown', [keyUp]: 'keyUp' };

  // emit (true) passes the event on, consume (false) drops it.
  const tap = hs.eventtap.addWatcher([keyDown, keyUp], (event) =>
    layer.handle(typeName[event.type], event.keyCode) ? hs.eventtap.emit : hs.eventtap.consume,
  );

  tap.start();

  return { layer, tap };
}

module.exports = { F19, createLayer, startLayer };
