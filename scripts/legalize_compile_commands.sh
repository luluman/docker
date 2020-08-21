#!/bin/sh
set -e

if [ ! -f "WORKSPACE" ]; then
    echo "Not in a Bazel root directory (WORKSPACE file does not exist), aborted!"
    exit 1
fi

force=0

if [ "$1" = "-f" ]; then
  force=1
fi

current_file=tools/actions/prune_compile_command.py
if [ "$force" -eq 1 ] || [ ! -f "$current_file" ]; then
    current_file_dir="$(dirname "$current_file")"

    mkdir -p "$current_file_dir"
    echo "Create $current_file" 1>&2
    more > "$current_file" <<'//MY_CODE_STREAM'
# This is a extra tool which can legalize compile_command.json.
# It deduplicate command and files.

import sys
import os
import json
import re

'''
Args:
  None
Return convert *.json to list of dictionary.
'''
def _getCompd():
    mainlist = []
    with open('compile_commands.json.orig', 'r') as infile:
        data = json.loads(infile.read())
        mainlist.extend(data)
        return mainlist

'''
Args:
  mess_str: command string.
Return unique compile command string.
'''
def cleanDuplicateMessage(mess_str):
    patten = r"\ -"
    mess_split = re.split(patten, mess_str)
    mess_split = ["-" + x for x in mess_split]
    out_Rmess = []
    for item in mess_split[::-1]:
        if item not in out_Rmess:
            out_Rmess.append(item)
    out_Rmess[-1] = out_Rmess[-1][1:]
    return " ".join(out_Rmess[::-1])

'''
Args:
  list_in: a list of compile command items.
Return unique compile command items.
'''
def _keepOneFile(list_in):
    keys_ = []
    ones = []
    for item in list_in:
        if item['file'] in keys_:
            continue
        item['command'] = cleanDuplicateMessage(item['command'])
        ones.append(item)
        keys_.append(item['file'])
    return ones


def main(argv):
    os.rename('compile_commands.json', 'compile_commands.json.orig')
    with open("compile_commands.json", 'w') as export_file:
        json.dump(_keepOneFile(_getCompd()), export_file, indent=2)


if __name__ == '__main__':
    sys.exit(main(sys.argv))
//MY_CODE_STREAM
else
echo "File $current_file already exists, aborted! (you can use -f to force overwrite)"
exit 1
fi

python3 ./tools/actions/prune_compile_command.py
exit 0
