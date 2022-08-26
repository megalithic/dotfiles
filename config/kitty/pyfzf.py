#!/usr/bin/env python
# coding: utf-8
# Copyright (c) 2022 Nagarjuna Kumarappan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Author: Nagarjuna Kumarappan <nagarjuna.412@gmail.com>

import os
import tempfile
from shutil import which

# constants
FZF_URL = "https://github.com/junegunn/fzf"


class FzfPrompt:
    def __init__(self, executable_path=None):
        if executable_path:
            self.executable_path = executable_path
        elif not which("fzf") and not executable_path:
            raise SystemError(f"Cannot find 'fzf' installed on PATH. ({FZF_URL})")
        else:
            self.executable_path = "fzf"

    def prompt(self, choices=None, fzf_options="", delimiter="\n"):
        # convert lists to strings [ 1, 2, 3 ] => "1\n2\n3"
        choices_str = delimiter.join(map(str, choices))
        selection = []

        with tempfile.NamedTemporaryFile(delete=False) as input_file:
            with tempfile.NamedTemporaryFile(delete=False) as output_file:
                # Create an temp file with list entries as lines
                input_file.write(choices_str.encode("utf-8"))
                input_file.flush()

        # Invoke fzf externally and write to output file
        os.system(
            f'{self.executable_path} {fzf_options} < "{input_file.name}" > "{output_file.name}"'
        )

        # get selected options
        with open(output_file.name, encoding="utf-8") as f:
            for line in f:
                selection.append(line.strip("\n"))

        os.unlink(input_file.name)
        os.unlink(output_file.name)

        return selection
