ENTRY(kernel_main)

SECTIONS {
    . = 0x10000; /* Start address for the kernel */

    .text : {
        *(.text.kmain)
        *(.text .text.*)
    }

    .rodata : { *(.rodata .rodata.*) }
    .data : { *(.data .data.*) }
    .bss : { *(.bss .bss.*) }

    .dynsym : { *(.dynsym .dynsym.*) }
    .gnu.hash : { *(.gnu.hash) }
    .hash : { *(.hash) }
    .dynstr : { *(.dynstr) }
}