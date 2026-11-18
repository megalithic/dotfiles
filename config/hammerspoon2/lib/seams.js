// Calls into swifties apps through their CLIs. HS2 0.0.15 (the last build for
// macOS 26) has no hs.socket; once on macOS 27 these become socket calls.
//
// The CLIs run through their mise shims by absolute path, never through PATH:
// ~/.local/bin/shade was the retired old Shade. A shim execs the real binary,
// so terminate() reaches it.
//
// hs.task gives each child a stdin pipe that stays open until the task ends or
// HS2 quits, reloads or crashes, and nothing here closes it. A `--hold` child
// therefore sees EOF exactly when HS2 goes away.

// bin: the folder holding the CLIs (the Atlas end-to-end test points it at a
// stub). log: where failures are reported.
function createSeams(
  hs,
  { bin = `${hs.fs.homeDirectory()}/.local/share/mise/shims`, log = (msg) => console.log(msg) } = {},
) {
  // onExit(code) replaces the default report of a non-zero exit.
  function run(cli, args, onExit) {
    const report = (code) => {
      if (code !== 0) log(`seams: ${cli} ${args.join(' ')} exited ${code}`);
    };

    const task = hs.task.create(`${bin}/${cli}`, args, onExit ?? report);

    task.start();

    return task;
  }

  // Runs a Shade command and passes its reply's result to onResult. Exit 1 is
  // an error reply ("unknown verb"), 69 Shade not running.
  function shade(args, onResult = () => {}) {
    hs.task
      .runAsync(`${bin}/shade`, args, {})
      .then(({ stdout }) => onResult(JSON.parse(stdout).result ?? {}))
      .catch((error) => log(`seams: shade ${args.join(' ')} failed: ${error?.exitCode ?? error}`));
  }

  return {
    // onShown(visible): whether the panel shows after the toggle.
    shadeToggle: (verb, onShown = () => {}) => shade(['toggle', verb], ({ visible }) => onShown(visible === 'true')),
    // Show the panel on a verb; never hides it.
    shadeShow: (verb) => shade(['show', verb]),
    // sup's key hint, up until the returned task is terminated (or HS2 dies).
    // rows: [{ key: "n", label: "Note" }].
    supHint: (rows, onExit) =>
      run('sup', ['show', 'hint', ...rows.flatMap(({ key, label }) => ['--key', `${key}=${label}`]), '--hold'], onExit),
  };
}

module.exports = { createSeams };
