# pongloader

<p align="center">
    <img src="https://raw.githubusercontent.com/mat-sz/pongloader/master/screenshot.png" alt="Screenshot">
</p>

Bootloader version of pong, fits in 512 bytes.

**This project is optimized for the resulting binary size, not performance.**

You can download prebuilt binaries [here](https://github.com/mat-sz/pongloader/releases).

## Running in QEMU

```
make && qemu-system-x86_64 pong.bin
```