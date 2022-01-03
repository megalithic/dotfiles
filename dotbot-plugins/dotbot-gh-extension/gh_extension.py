import os
import subprocess

import dotbot

"""
gh extension install https://github.com/vilmibm/gh-user-status.git

"""


class GHExtension(dotbot.Plugin):
    """
    Install GH exstations
    """

    _default_flags = [""]

    def __init__(self, context):
        super(GHExtension, self).__init__(context)
        self._directives = {"ghe": self._get}

    # Dotbot methods

    def can_handle(self, directive):
        return directive in self._directives

    def handle(self, directive, data):
        try:
            for entry in data:
                self._directives[directive](entry)
            command = "gh extension upgrade --all"
            subprocess.call(command, cwd=self.cwd, shell=True)
            return True
        except ValueError as e:
            self._log.error(e)
            return False

    # Utility

    @property
    def cwd(self):
        return self._context.base_directory()

    # Inner methods

    def _get(self, data):
        repo, flags = self._parse(data, "repo")
        command = "gh extension install {} {}".format(repo, flags)
        subprocess.call(command, cwd=self.cwd, shell=True)

    def _parse(self, data, key):
        if type(data) is dict:
            if key not in data:
                raise ValueError("Key '{}' not found in {}".format(key, data))

            if "flags" not in data:
                self._log.warning("Key 'flags' not found in {}".format(data))
                self._log.warning(
                    "Using default flags {}".format(self._default_flags))

            value = data[key]
            flags = data.get("flags", self._default_flags)
        else:
            value = data
            flags = self._default_flags

        return value, " ".join(flags)
