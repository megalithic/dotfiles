# dotbot-brewfile

Install brew packages with dotbot. `bundle` style!


## Prerequirements

This plugin requires [`dotbot`](https://github.com/anishathalye/dotbot/) to be installed.


## How does it work

There's such a cool thing as [`homebrew-bundle`](https://github.com/Homebrew/homebrew-bundle), which allows to dump and install all your `brew` dependencies with ease. Why not use such a tool?

There are two main commands to be aware of:

1. `brew bundle dump` - creates a `Brewfile` with all your dependencies, casks, taps and even services
2. `brew bundle` - tries to read a `Brewfile` and install everything from it

Looks pretty much the same as a well-known `bundler`.


## Installation

1. Run:

```bash
git submodule add https://github.com/sobolevn/dotbot-brewfile.git
```

2. Modify your `./install` with new plugin directory:

```bash
"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" --plugin-dir dotbot-brewfile -c "${CONFIG}" "${@}"
```

3. Add required options to your [`install.conf.yaml`](/example.yaml):

```yaml
# This apply to all commands that come after setting the defaults.
- defaults:
    brewfile:
      stdout: false
      stderr: false
      include: ['tap', 'brew', 'cask', 'mas']

- brewfile:
    # This accepts the same options as `brew bundle` command:
    file: Brewfile
```

That's it!


## Alternatives

If you need just some basic yet useful `brew` setup, check out [`dotbot-brew`](https://github.com/d12frosted/dotbot-brew).


## License

MIT. See [LICENSE](/LICENSE) for more details.
