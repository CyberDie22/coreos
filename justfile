#!/usr/bin/env just --justfile

clean:
    cargo clean

build: kernel bootloader combine
    @echo "Built Kernel"

bootloader:
    nasm -fbin bootloader/stage1.asm -o target/x86_64-unknown-none/release/bootloader-stage1

kernel:
    cargo build --release
    rust-objcopy -O binary --strip-debug --gap-fill=0x00 target/x86_64-unknown-none/release/coreos target/x86_64-unknown-none/release/kernel_flat.img

combine: bootloader kernel
    cat target/x86_64-unknown-none/release/bootloader-stage1 target/x86_64-unknown-none/release/kernel_flat.img > target/x86_64-unknown-none/release/vm-image.img

qemu: build
    qemu-system-i386 -nodefaults -vga std -device ahci,id=ahci0 -drive id=drive0,file=target/x86_64-unknown-none/release/vm-image.img,format=raw -m 4G
