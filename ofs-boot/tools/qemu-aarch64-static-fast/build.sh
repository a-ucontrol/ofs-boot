#/bin/sh

echo "create /tmp/qemu-aarch64"

gcc -O3 qemu-aarch64-static-fast.c -static -o /tmp/qemu-aarch64
