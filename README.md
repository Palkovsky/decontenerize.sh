# decontenerize.sh
Proof of concept. Turn docker container into bootable disk image. Contains a lot of hardcoded stuff and has some dependecis.

## What it does
- Pulls rootfs out of docker contaienr
- Creates a qcow2 disk image with one parititon spanning it.
- Copies rootfs onto the partition.
- Copies current kernel and installs grub.
- Copies `overlay` onto the partition.

## Overlay
It conatins minimalistic [init binary](https://github.com/Yelp/dumb-init), some config files and scriptable init hook (`overlay/sbin/init.sh`).

## Demo
[![asciicast](https://asciinema.org/a/T9xij1txELITLY7xPrG52d00H.svg)](https://asciinema.org/a/T9xij1txELITLY7xPrG52d00H)
