import os
import re
import subprocess

import dotbot


INCLUDE_OPTIONS = frozenset(('tap', 'brew', 'cask', 'mas'))
BREWFILE_LINE = re.compile(
    r"""
    ^
        (?P<type>(tap|brew|cask|mas))\s*  # dependency type
        "(?P<name>.*)"\s*                 # name between quotes
        (,\s*id:\s*(?P<id>\d\d*)\s*)?     # id for mas items
    $
    """,
    re.MULTILINE | re.VERBOSE,
)


class Brew(dotbot.Plugin):
    _supported_directives = frozenset((
        'brewfile',
    ))

    _tap_command = 'brew tap homebrew/bundle'
    _install_command = 'brew bundle'

    # Defaults
    _default_filename = 'Brewfile'
    _default_stdout = False
    _default_stderr = False
    _default_include = INCLUDE_OPTIONS

    # API methods

    def can_handle(self, directive):
        return directive in self._supported_directives

    def handle(self, directive, data):
        data = self._maybe_convert_to_dict(data)

        try:
            if not self._does_brewfile_exist(data):
                raise ValueError('Bundle file does not exist.')

            self._handle_tap(data)
            self._handle_install(data)
        except ValueError as e:
            self._log.error(e)
            return False
        else:
            return True

    # Utility

    @property
    def cwd(self):
        return self._context.base_directory()

    # Inner logic

    def _maybe_convert_to_dict(self, data):
        if isinstance(data, str):
            return {'file': data}
        return data

    def _brewfile_path(self, data):
        return os.path.join(
            self.cwd, data.get('file', self._default_filename)
        )

    def _does_brewfile_exist(self, data):
        path = self._brewfile_path(data)
        return os.path.isfile(path)

    def _build_command(self, command, data):
        def build_option(name, value):
            option = '--' + name
            if name != 'file':
                return option
            return '%s=%s' % (option, value)

        options = [command]

        for key, value in data.items():
            if key not in {'stdout', 'stderr', 'include'}:
                options.append(build_option(key, value))
        return ' '.join(options)

    def _get_includes(self, data):
        includes = data.get('include', self._default_include)
        if isinstance(includes, str):
            includes = frozenset((includes,))
        elif isinstance(includes, list):
            includes = frozenset(includes)

        unknown = includes - INCLUDE_OPTIONS
        if unknown:
            raise ValueError('Unknown include(s) provided:', unknown)
        return includes

    def _build_environs(self, data):
        includes = self._get_includes(data)
        ignores = {}

        with open(self._brewfile_path(data)) as f:
            contents = f.read()

        for match in BREWFILE_LINE.finditer(contents):
            type_, name, id_ = match.group('type', 'name', 'id')

            if type_ not in includes:
                env_name = 'HOMEBREW_BUNDLE_{0}_SKIP'.format(type_.upper())
                skips = ignores.setdefault(env_name, [])
                skips.append(id_ or name)  # prefer id when available

        ignores = {
            env: ' '.join(deps)
            for env, deps in ignores.items()
        }
        environs = dict(os.environ)
        environs.update(ignores)
        return environs

    # Handlers

    def _get_options(self, data):
        defaults = self._context.defaults().get('brewfile', {})
        stdout_default = defaults.get('stdout', self._default_stdout)
        stderr_default = defaults.get('stderr', self._default_stderr)

        stdout = data.get('stdout', stdout_default)
        stderr = data.get('stderr', stderr_default)

        return stdout, stderr

    def _handle_tap(self, data):
        stdout, stderr = self._get_options(data)

        with open(os.devnull, 'w') as devnull:
            result = subprocess.call(
                self._tap_command,
                shell=True,
                stdin=devnull,
                stdout=True if stdout else devnull,
                stderr=True if stderr else devnull,
                cwd=self.cwd,
                executable=os.environ.get('SHELL'),
            )

            if result != 0:
                raise ValueError('Failed to tap homebrew/bundle.')

    def _handle_install(self, data):
        environs = self._build_environs(data)
        full_command = self._build_command(self._install_command, data)
        stdout, stderr = self._get_options(data)

        with open(os.devnull, 'w') as devnull:
            result = subprocess.call(
                full_command,
                shell=True,
                stdin=devnull,
                stdout=True if stdout else devnull,
                stderr=True if stderr else devnull,
                cwd=self.cwd,
                executable=os.environ.get('SHELL'),
                env=environs,
            )

            if result != 0:
                raise ValueError('Failed to install a bundle.')
