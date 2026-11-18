// Minimal stand-in for the parts of HS2 0.0.15's `hs` global this config uses.
// Event type values are CGEventType's (keyDown 10, keyUp 11).

const TYPES = { keyDown: 10, keyUp: 11 };

export function mockHs() {
  const hs = {
    tap: null,
    tasks: [],
    timers: [],
    canvases: [],
    keycodes: { map: { n: 45, t: 17, c: 8, j: 38 } },
    fs: { homeDirectory: () => '/Users/test' },
    eventtap: {
      eventTypes: TYPES,
      emit: true,
      consume: false,
      addWatcher(types, callback) {
        hs.tap = {
          types,
          callback,
          started: false,
          start() {
            this.started = true;

            return this;
          },
        };

        return hs.tap;
      },
    },
    // Feeds one event through the tap; returns true when it passes on.
    press(type, keyCode) {
      return hs.tap.callback({ type: TYPES[type], keyCode });
    },
    task: {
      create(path, args, onTermination) {
        const task = {
          path,
          args,
          onTermination,
          started: false,
          terminated: false,
          inputClosed: false,
          start() {
            this.started = true;

            return this;
          },
          // SIGTERM: like HS2, the termination callback still runs.
          terminate() {
            this.terminated = true;
            this.exit(15, 'uncaughtSignal');
          },
          exit(code, reason = 'exit') {
            this.onTermination?.(code, reason);
          },
          closeInput() {
            this.inputClosed = true;
          },
        };

        hs.tasks.push(task);

        return task;
      },
    },
    timer: {
      doAfter(seconds, callback) {
        const timer = {
          seconds,
          stopped: false,
          stop() {
            this.stopped = true;

            return this;
          },
          fire() {
            callback();

            return this;
          },
        };

        hs.timers.push(timer);

        return timer;
      },
    },
    screen: { main: () => ({ fullFrame: { x: 0, y: 0, w: 1600, h: 1000 } }) },
    canvas: {
      create(frame) {
        const canvas = {
          frame,
          elements: [],
          shown: false,
          destroyed: false,
          levelName: null,
          level(name) {
            this.levelName = name;

            return this;
          },
          behavior() {
            return this;
          },
          ignoreMouseEvents() {
            return this;
          },
          appendElements(elements) {
            this.elements.push(...elements);

            return this;
          },
          show() {
            this.shown = true;

            return this;
          },
          destroy() {
            this.destroyed = true;
          },
        };

        hs.canvases.push(canvas);

        return canvas;
      },
    },
  };

  return hs;
}
