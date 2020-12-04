Vim�UnDo� �����'?�������H�mz�yN8��4	V   Z                                   [�uP    _�                             ����                                                                                                                                                                                                                                                                                                                                                             [�uG     �                   �               5�_�                            ����                                                                                                                                                                                                                                                                                                                               �          �       V   �    [�uM    �                  �https://gist.githubusercontent.com/MaximeWack/388c393b7db290dd732f0a2d403118c5/raw/0e2f7c2765ff1d1a00089f45818ac88cb2b78006/elmtags.py�               5�_�                             ����                                                                                                                                                                                                                                                                                                                               �          �       V   �    [�uO    �               Z   #! /usr/bin/env python   # -*- coding: utf-8 -*-       %from __future__ import print_function       help_text = """   ;Extracts tags from Elm files. Useful for the Tagbar plugin.       Usage:   IInstall Tagbar (http://majutsushi.github.io/tagbar/). Then, put this file   .anywhere and add the following to your .vimrc:       let g:tagbar_type_elm = {             \   'ctagstype':'elm'   F          \ , 'kinds':['h:header', 'i:import', 't:type', 'f:function']             \ , 'sro':'&&&'   M          \ , 'kind2scope':{'h':'header', 'i:import', 't:type', 'f:function'}             \ , 'sort':0   .          \ , 'ctagsbin':'/path/to/elmtags.py'             \ }   """       
import sys   	import re       if len(sys.argv) < 2:       print(help_text)   
    exit()       filename = sys.argv[1]       $re_header = re.compile(r"^-- (.*)$")   Tre_import = re.compile(r"^import ([^ \n]+)( as ([^ \n]+))?( exposing (\([^)]+\)))?")   7re_type = re.compile(r"^type( alias)? ([^ \n]+)( =)?$")   -re_function = re.compile(r"^([^ ]+) : (.*)$")           file_content = []   try:   +    with open(filename, "r") as vim_buffer:   -        file_content = vim_buffer.readlines()   except:   
    exit()       cur_head = ""   *for lnum, line in enumerate(file_content):       (    match_header = re_header.match(line)   (    match_import = re_import.match(line)   $    match_type = re_type.match(line)   ,    match_function = re_function.match(line)       cur_searchterm = ""       cur_kind = ""       args = ""       lines = ""           if match_header:   (        cur_head = match_header.group(1)           cur_tag = cur_head   /        cur_searchterm = "^-- " + cur_tag + "$"           cur_kind = "h"       elif match_import:   '        cur_tag = match_import.group(1)   -        cur_searchterm = "^import " + cur_tag           cur_kind = "i"   %        args = "\theader:" + cur_head   !        if match_import.group(3):   9            args = args + "\tsignature:(" + cur_tag + ")"   +            cur_tag = match_import.group(3)   !        if match_import.group(5):   T            exposing = match_import.group(5).strip("()").replace(" ", "").split(",")   $            for exposed in exposing:   �                lines = lines + '\n{0}\t{1}\t/{2}/;"\t{3}\tline:{4}{5}'.format(exposed, filename, cur_searchterm, "e", str(lnum+1), "\taccess:public\timport:" + cur_head + "&&&" + cur_tag)       elif match_type:   %        cur_tag = match_type.group(2)   +        if match_type.group(1) == " alias":   '            args = "\taccess:protected"   1        cur_searchterm = "^type " + cur_tag + "$"           cur_kind = "t"   ,        args = args + "\theader:" + cur_head       elif match_function:   )        cur_tag = match_function.group(1)   -        cur_searchterm = "^" + cur_tag + " :"           cur_kind = "f"   W        args = "\theader:" + cur_head + "\tsignature:(" + match_function.group(2) + ")"   	    else:           continue       7    print('{0}\t{1}\t/{2}/;"\t{3}\tline:{4}{5}'.format(   P        cur_tag, filename, cur_searchterm, cur_kind, str(lnum+1), args) + lines)5��