# dotbot-template

Template files using the `jinja2` templating engine.


## Prerequisites
This plugin requires [`dotbot`](https://github.com/anishathalye/dotbot) to be installed.

## Installation
1. Run `git submodule add https://github.com/ssbanerje/dotbot-template.git`
2. Run `git submodule update --init --recursive`
3. Pass in the CLI argument `--plugin-dir dotbot-template` when executing the `dotbot` executable.


## Usage

Add the `template` directive to the `dotbot` YAML file:

```yaml
- template:
    - ~/.gitconfig:
        source_file: gitconfig
        params:
          NAME: John Doe
          EMAIL: jd@jd.com
          GITHUB_USERNAME: jd
          SIGNING_KEY: ????
          SMTP_SERVER: smtp.gmail.com
          SMTP_PORT: 587
          SMTP_ENCRYPTION: tls
          __UNAME__:
            CREDENTIAL_HELPER:
              Darwin: osxkeychain
              Linux: cache --timeout 36000
```

The corresponding template file looks like:
```toml
[core]
  excludesfile = {{HOME_DIR}}/.global_gitignore

[user]
  name = {{NAME}}
  email = {{EMAIL}}
  signingkey = {{SIGNING_KEY}}

[sendmail]
  smtpserver = {{SMTP_SERVER}}
  smtpserverport = {{SMTP_PORT}}
  smtpencryption = {{SMTP_ENCRYPTION}}
  smtpuser = {{EMAIL}}
  from = {{EMAIL}}

[github]
  user = {{GITHUB_USERNAME}}

[credential]
  helper = {{CREDENTIAL_HELPER}}
```

### Details

The template directive takes a [Jinja](https://jinja.palletsprojects.com/en/3.0.x/) compatible
template file using the `source_file` field. Details about the template syntax and semantics can be
found [here](https://jinja.palletsprojects.com/en/3.0.x/templates/).

Configuration parameters to the templating engine are placed in the `params` field in the `template`
directive.

Platform specific parameters to the templating engine is can be placed in the `__UNAME__` field as
shown in the example above (see `CREDENTIAL_HELPER`). The current system platform is queried using
Python's `platform.system()` command. Potential system names are `Linux`, `Darwin`, `Java`,
`Windows`.

In addition to the user defined parameters the directive has the `HOME_DIR` configuration parameter 
set to the `HOME` environment variable in the calling shell.
