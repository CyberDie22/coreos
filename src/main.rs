#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
#[unsafe(link_section = ".text.kmain")]
pub extern "C" fn kernel_main() -> ! {
    write_vga("Rust Code!");

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}


fn write_vga(string: &str) {
    let vga_memory = 0xB8000 as *mut u8;

    unsafe { // This is safe since 0xB8000 is guaranteed to be VGA color memory
        for (i, &byte) in string.as_bytes().iter().enumerate() {
            // Write character byte (even offset)
            *vga_memory.add(i * 2) = byte;
            // Write attribute byte (odd offset) - white on black
            *vga_memory.add(i * 2 + 1) = 0x0Fu8;
        }
    }
}