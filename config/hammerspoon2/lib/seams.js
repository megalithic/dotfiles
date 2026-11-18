// Calls into swifties apps through their CLIs. HS2 0.0.15 (the last build for
// macOS 26) has no hs.socket; once on macOS 27 these become socket calls.
//
// hs.task gives each child a stdin pipe that stays open until the task ends or
// HS2 quits, reloads or crashes, and nothing here closes it. A `--hold` child
// therefore sees EOF exactly when HS2 goes away. CLIs started here must not
// read stdin unless they mean to.

// The CLIs resolve through PATH (the LaunchAgent puts ~/.local/bin and the mise shims on it), so
// launch them through /usr/bin/env: hs.task needs an absolute path. `path`
// replaces PATH for the children (the Atlas end-to-end test uses it).
const ENV = '/usr/bin/env';

function createSeams(hs, { log = (msg) => console.log(msg), path } = {}) {
  function run(command) {
    const args = path ? [`PATH=${path}`, ...command] : command;

    const task = hs.task.create(ENV, args, (code) => {
      if (code !== 0) log(`seams: ${args.join(' ')} exited ${code}`);
    });

    task.start();

    return task;
  }

  return {
    // Shade's toggle verbs: write, tell, capture.
    shadeToggle: (verb) => run(['shade', 'toggle', verb]),
  };
}

module.exports = { createSeams };
