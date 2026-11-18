// Hyper layer: while the hyper key (F19, from kanata) is held, the layer's
// keys are consumed and run their action. Hyper itself always passes through,
// so v1 Hammerspoon keeps its own F19 hotkey and hyper modal.
//
// No Carbon hotkey on F19 here: two apps registering the same hotkey is the
// one thing that could break v1's hyper. A session event tap only watches.

const F19 = 80; // kVK_F19

// keys: { [keyCode]: action }. onAction(action) runs on key down; onHold() and
// onRelease() fire when hyper goes down and up (auto-repeat ignored).
// Returns handle(type, keyCode) -> true to pass the event on, false to consume.
function createLayer({ keys, onAction, onHold = () => {}, onRelease = () => {}, hyperKeyCode = F19 }) {
  let held = false;
  // Layer keys pressed while hyper was held: their key up is consumed too,
  // even when hyper is released first.
  const down = new Set();

  function handle(type, keyCode) {
    if (keyCode === hyperKeyCode) {
      if (type === 'keyDown' && !held) {
        held = true;
        onHold();
      } else if (type === 'keyUp' && held) {
        held = false;
        onRelease();
      }

      return true;
    }

    if (!(keyCode in keys)) return true;

    if (type === 'keyDown') {
      if (!held) return true;

      if (!down.has(keyCode)) onAction(keys[keyCode]);
      down.add(keyCode);

      return false;
    }

    if (type === 'keyUp' && down.has(keyCode)) {
      down.delete(keyCode);

      return false;
    }

    return true;
  }

  return { handle, isHeld: () => held };
}

// Wires a layer to a session event tap. bindings: [{ key: "n", action }].
// Key names resolve through hs.keycodes.map, which follows the current layout.
function startLayer(hs, { bindings, onAction, onHold, onRelease }) {
  const keys = {};

  for (const { key, action } of bindings) keys[hs.keycodes.map[key]] = action;
  const layer = createLayer({ keys, onAction, onHold, onRelease });
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
