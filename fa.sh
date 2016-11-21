#!/bin/bash
find /l4/obj/l4 -type f -name '*.[ao]' | xargs nm 2> /dev/null | grep -e "^/l4" -e " [^Uw ] $1" | grep -B1 '^[^/]'
