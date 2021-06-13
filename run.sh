#!/bin/bash
[[ -z "$1" ]] && echo "Usgae: $0 <disk image>" && exit 1
qemu-system-x86_64 -nographic -m 1024 -soundhw all -hda $1