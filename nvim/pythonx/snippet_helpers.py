import os
import re


def pascal_case_basename(basename):
    return ''.join(x[0].upper() + x[1:] for x in basename.split('-'))


def dasherize_basename(basename):
    return '-'.join(filter(None, _convert_camel_case(basename).split('_')))


# http://stackoverflow.com/a/1176023/18986
def _convert_camel_case(string):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1-\2', string)
    return re.sub('([a-z0-9])([A-Z])', r'\1-\2', s1).lower()


def _clean_basename(basename):
    return re.sub('(_spec|-test|.test|.spec|-diffux)$', '', basename or 'ModuleName')


'''
If path ends in `index.jsx`, this function will return the PascalCased directory
name. Otherwise, it returns the PascalCased filename. This allows me to use my
snippets with modules that are like `/path/to/module_name.jsx` and modules that
are like `/path/to/ModuleName/index.jsx`.
'''
def path_to_component_name(path, case_fn):
    dirname, filename = os.path.split(path)
    basename = os.path.splitext(filename)[0]
    if basename in ['index', 'index-test', 'index-diffux', 'index.test', 'index.spec']:
        # Pop the last directory name off the dirname
        return case_fn(_clean_basename(os.path.basename(dirname)))
    else:
        return case_fn(_clean_basename(basename))


def complete(text, opts):
    if text:
        opts = [m[len(text):] for m in opts if m.startswith(text)]
    if len(opts) == 1:
        return opts[0]
    if len(opts) > 0:
        return '(' + '|'.join(opts) + ')'
    return ''
