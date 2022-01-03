#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os
import platform
import dotbot


def _inject():
    # Find submodules
    root_dir = os.path.dirname(os.path.realpath(__file__))
    path_jinja = os.path.join(root_dir, 'lib/jinja/src/')
    path_markupsafe = os.path.join(root_dir, 'lib/markupsafe/src')
    # Update path
    sys.path.insert(0, path_markupsafe)
    sys.path.insert(0, path_jinja)


_inject()
from jinja2 import Environment, FileSystemLoader


class Template(dotbot.Plugin):
    _directive = 'template'

    def can_handle(self, directive):
        return directive == self._directive

    def handle(self, directive, data):
        if directive == self._directive:
            for temp in data:
                target, opts = list(temp.items())[0]
                self._log.info("Rendering template %s" % target)
                try:
                    # Get target path
                    target = os.path.expanduser(target)
                    # Get parameters for render
                    params = self._parse_params(opts['params'])
                    # Load template and render
                    self._render_template(opts['source_file'], params, target)
                except:
                    self._log.error("Could not render %s" % target)
                    return False
            return True
        else:
            raise ValueError('Cannot handle this directive %s' % directive)

    def _parse_params(self, params):
        params = self._add_homedir(params)
        params = self._parse_platform_specific(params)
        return params

    def _add_homedir(self, params):
        params['HOME_DIR'] = os.environ['HOME']
        return params

    def _parse_platform_specific(self, params):
        if '__UNAME__' in params:
            uname = platform.system()
            for k in params['__UNAME__'].keys():
                params[k] = params['__UNAME__'][k][uname]
            del params['__UNAME__']
        return params

    def _render_template(self, template_file, params, target):
        # Load template
        cwd = self._context.base_directory()
        template_dir = os.path.dirname(os.path.abspath(cwd + '/' + template_file))
        jinja_env = Environment(loader=FileSystemLoader(template_dir))
        template = jinja_env.get_template(os.path.basename(template_file))
        # Template and write output
        with open(target, 'w') as target_file:
            target_file.write(template.render(params))
