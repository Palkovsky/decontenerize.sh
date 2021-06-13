#!/bin/bash
fail() {
    echo "$1"
    exit 1
}

[  "$EUID" -ne 0 ] && fail "The must be run as root user"

# 1. Extract rootfs
IMAGE="$1"
ROOTFS="$IMAGE-rootfs"
[ -z "$IMAGE" ] && fail "Usage: $0 <image_name>"
rm -rf $ROOTFS && mkdir $ROOTFS
docker export $(docker create $IMAGE) | tar -C $ROOTFS -xvf -
# TODO: This doesn't remove container

# 2. Create disk image, partition it and copy rootfs
nbd_connect() {
    qemu-nbd --connect=/dev/nbd$1 $2 || return 1
}

nbd_disconnect() {
    umount mnt/sys > /dev/null 2>&1
    umount mnt/dev > /dev/null 2>&1
    umount mnt/proc > /dev/null 2>&1
    umount mnt > /dev/null 2>&1
    qemu-nbd --disconnect /dev/nbd$1 || return 1
}

QCOW="$IMAGE.qcow2" ; rm -rf $QCOW
qemu-img create -f qcow2 $QCOW 10G
modprobe nbd max_part=8 || fail "Failed inserting 'nbd' module"
nbd_disconnect 0 > /dev/null 2>&1
nbd_connect 0 $QCOW || fail "Failed connecting to /dev/nbd0"
echo -e 'n\np\n1\n\n\na\nw\n' | fdisk /dev/nbd0
mkfs -t ext4 /dev/nbd0p1 || fail "Failed to format /dev/nbd0p1 as ext4"
umount mnt > /dev/null 2>&1 ; mkdir -p mnt ; rm -rf mnt/*
mount /dev/nbd0p1 mnt || fail "Unable to mount /dev/nbd0p1"
rsync -a $ROOTFS/* mnt/ ; rm -rf $ROOTFS

# 3. Copy kernel, rootfs, System.map, overlay and install GRUB
rsync -a /boot/initrd* /boot/System.map* /boot/vmlinuz* mnt/boot/
rsync -a overlay/* mnt/
grub-install /dev/nbd0 --skip-fs-probe --boot-directory=mnt/boot

umount mnt
nbd_disconnect 0
rmdir mnt