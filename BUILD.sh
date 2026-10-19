#!/bin/sh
set -eu
clang -D_GNU_SOURCE -fPIC -shared -std=c11 \
  -Wall -Wextra \
  -Wl,--version-script=exports.txt \
  shmem.c -o libandroid-shmem-test.so -llog
readelf -d libandroid-shmem-test.so | grep NEEDED
