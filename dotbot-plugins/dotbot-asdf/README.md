# dotbot-asdf

Install [`asdf`](https://github.com/asdf-vm/asdf) plugins and programming languages with `dotbot`.

## Prerequirements

This plugin requires [`dotbot`](https://github.com/anishathalye/dotbot/) to be installed.

Also, at runtime this plugin requires `asdf` command to be installed.

## Installation

1. Run:

```bash
git submodule add https://github.com/sobolevn/dotbot-asdf.git
```

2. Modify your `./install` with new plugin directory:

```bash
"${BASEDIR}/${DOTBOT_DIR}/${DOTBOT_BIN}" -d "${BASEDIR}" --plugin-dir dotbot-asdf -c "${CONFIG}" "${@}"
```

## Usage

Add required options to your [`install.conf.yaml`](/example.yaml):

```yaml
# This example uses python, nodejs and ruby plugins:

- asdf:
  - plugin: python
    url: https://github.com/tuvistavie/asdf-python.git
  - plugin: nodejs
    url: https://github.com/asdf-vm/asdf-nodejs.git
  - plugin: ruby
    url: https://github.com/asdf-vm/asdf-ruby.git
```

Plugins can also be specified with just a name for [known plugins](https://asdf-vm.com/#/plugins-all?id=plugin-list):

```yaml
# This example uses python, nodejs and ruby plugins:

- asdf:
  - plugin: python
  - plugin: nodejs
  - plugin: ruby
```

You can even install desired versions of languages and the global version:

```yaml
# This example installs python 3.7.4, nodejs 12.10 and ruby 2.6.4:

- asdf:
  - plugin: python
    url: https://github.com/tuvistavie/asdf-python.git
    global: 3.7.4
    versions:
      - 3.7.4
  - plugin: nodejs
    url: https://github.com/asdf-vm/asdf-nodejs.git
    global: 12.10
    versions:
      - 12.10
  - plugin: ruby
    url: https://github.com/asdf-vm/asdf-ruby.git
    global: 2.6.4
    versions:
      - 2.6.4
```

That's it!

## License

MIT. See [LICENSE](/LICENSE) for more details.
