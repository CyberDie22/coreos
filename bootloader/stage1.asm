[BITS 16]
[ORG 0x7C00]  ; BIOS loads boot sector to 0x7C00

bootloader_real_mode:
    mov si, int13_dap
    mov ah, 0x42
    mov dl, 0x80
    int 0x13            ; read one sector starting at sector two

    cli  ; disable interrupts

    xor ax, ax
    mov ds, ax  ; clear ax, ds registers

    lgdt [gdt_desc]  ; load GDT

    mov eax, cr0
    or eax, 1      ; set bit 0 in CR0 register to enable protected mode
    mov cr0, eax

    jmp 08h:bootloader_protected_mode  ; clear instruction pipeline with far jump
                                       ; seg id = 0x08, segment 0 (code) * 8 = 0x08

[BITS 32]
bootloader_protected_mode:
    mov ax, 0x10
    mov ds, ax  ; set data segment to 0x08 (segment 1)
    mov ss, ax  ; set stack segment to 0x08 (segment 1)

    mov esp, 0x90000  ; set stack pointer to 0x90000 to avoid code and BIOS memory segments

    call enable_A20

    jmp 0x10000

enable_A20:
    pushad

    ; tell QEMU to disable A20 line
    ; in al, 0xEE

    mov word [0xB8000], 0x0441
    call test_A20
    jne A20_on
    mov word [0xB8000], 0x0442

    call enable_a20_keyboard_controller
    mov word [0xB8000], 0x0443
    ; jump out if keyboard worked
    call test_A20
    jne A20_on

    ; FAST A20
    in al, 0x92
    test al, 2
    jnz fast_A20_set
    or al, 2
    and al, 0xFE
    out 0x92, al
fast_A20_set:
    mov word [0xB8000], 0x0444
    ; jump out if fast a20 worked
    call test_A20
    jne A20_on

A20_failed:
    mov word [0xB8000], 0x0441
    mov word [0xB8002], 0x0432
    mov word [0xB8004], 0x0430
    mov word [0xB8006], 0x0420
    mov word [0xB8008], 0x0446
    mov word [0xB800A], 0x0441
    mov word [0xB800C], 0x0449
    mov word [0xB800E], 0x044C
    hlt ; Cannot continue without a20

A20_on:
    popad
    ret

enable_a20_keyboard_controller:
	cli

	call .wait_io1
	mov al, 0xad
	out 0x64, al

	call .wait_io1
	mov al, 0xd0
	out 0x64, al

	call .wait_io2
	in al, 0x60
	push eax

	call .wait_io1
	mov al, 0xd1
	out 0x64, al

	call .wait_io1
	pop eax
	or al, 2
	out 0x60, al

	call .wait_io1
	mov al, 0xae
	out 0x64, al

	call .wait_io1
	sti
	ret
.wait_io1:
	in al, 0x64
	test al, 2
	jnz .wait_io1
	ret
.wait_io2:
	in al, 0x64
	test al, 1
	jz .wait_io2
	ret

test_A20:
    pushad
    mov edi, 0x112345   ; odd megabyte addr
    mov esi, 0x012345   ; even megabyte addr
    mov [esi], esi      ; both addrs contain different values
    mov [edi], edi      ; if A20 line is cleared, both pointers will contain 0x112345
    cmpsd               ; compare addrs
    pushf
    popad
    popf
    ret


; http://www.osdever.net/tutorials/view/the-world-of-protected-mode
gdt:

gdt_null:
    dq 0  ; reserved by Intel

gdt_code:
    dw 0xFFFF  ; size of code segment (first 16 bits of segment limiter)
    dw 0       ; start of code segment (0-15) (first 16 bits of base address)
    db 0       ; start of code segment (16-23) (middle 8 bits of base address)
    db 10011010b  ; access(0), readable(1), conforming(0), code/data(1), data_or_code(1), privilege/rings(00), present(1)
    db 11001111b  ; segment_limit(1111, 16-19 of segment limiter), sys_prog_use(0), intel_reserved(0), size_16/32(1), granularity_x4k(1)
    db 0  ; start of code segment (24-31) (last 8 bits of base address)

gdt_data:
    dw 0xFFFF  ; size of data segment (first 16 bits of segment limiter)
    dw 0       ; start of data segment (0-15) (first 16 bits of base address)
    db 0       ; start of data segment (16-23) (middle 8 bits of base address)
    db 10010010b  ; access(0), writeable(1), expand_down/up(0), code/data(0), data_or_code(1), privilege/rings(00), present(1)
    db 11001111b  ; segment_limit(1111, 16-19 of segment limiter), sys_prog_use(0), intel_reserved(0), big_16/32(1), granularity_x4k(1)
    db 0

gdt_end:

gdt_desc:
    dw gdt_end - gdt
    dd gdt


int13_dap:
    db 0x10     ; length of dap
    db 0        ; must be 0
    dw 1        ; sectors to read
    dw 0x0000   ; memory offset
    dw 0x1000   ; memory segment
    dq 1        ; sector to start reading from


; Boot Sector Identifier
times 510-($-$$) db 0
    dw 0xAA55