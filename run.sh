#!/bin/bash
set -eu
cp $1 /modules

set -- $(basename $1)

cd /modules
qemu-system-x86_64 -device isa-debug-exit -nographic -m 1024 \
    -kernel bootstrap -initrd "fiasco,sigma0,moe --init=rom/$1,l4re,$1" || exit $(($?>>1))
echo "qemu exited unexpectedly"; exit 99
