# pongloader

<p align="center">
    <a href="https://demo.mat.dev/pongloader/">
        <strong>Click here to open an online demo.</strong>
    </a>
</p>

<p align="center">
    <a href="https://demo.mat.dev/pongloader/">
        <img src="https://raw.githubusercontent.com/mat-sz/pongloader/master/screenshot.png" alt="Screenshot">
    </a>
</p>

Bootloader version of pong, fits in 512 bytes.

**This project is optimized for the resulting binary size, not performance.**

You can download prebuilt binaries [here](https://github.com/mat-sz/pongloader/releases).

## Running in QEMU

```
make && qemu-system-x86_64 out/pong.bin
```