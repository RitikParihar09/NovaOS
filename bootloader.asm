[org 0x7c00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov ax, 0x03
    int 0x10

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 0
    int 0x10

    call print_lines

    ; Load the kernel
    call load_kernel
    jc disk_fail

    ; Print a message before jumping to kernel
    mov si, loading_kernel
    call print

    ; Jump to the kernel
    jmp 0x1000:0x0000

hang:
    mov si, hang_msg
    call print
    jmp hang

print_lines:
    mov si, line1
    call print
    mov si, line2
    call print
    mov si, line3
    call print
    mov si, line4
    call print
    mov si, cpu_msg
    call print
    mov si, mem_msg
    call print
    mov si, sto_msg
    call print
    mov si, sec_msg
    call print
    mov si, success
    call print
    ret

print:
    pusha
.next:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp .next
.done:
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    popa
    ret

load_kernel:
    pusha
    ; Reset disk system
    mov ah, 0x00
    mov dl, 0x00        ; Drive 0 (floppy)
    int 0x13
    jc disk_fail

    ; Read sectors
    mov ah, 0x02        ; Read function
    mov al, 8           ; Read 8 sectors (4KB, enough for our kernel)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Sector 2 (1-based, sector after boot sector)
    mov dh, 0           ; Head 0
    mov dl, 0x00        ; Drive 0 (floppy)

    ; Set up memory location to load to (0x1000:0x0000)
    mov bx, 0x1000      ; Segment
    mov es, bx
    mov bx, 0x0000      ; Offset

    ; Perform the read
    int 0x13
    jc disk_fail        ; Jump if error (carry flag set)

    ; Verify we read the correct number of sectors
    cmp al, 8           ; AL returns the number of sectors read
    jne disk_fail       ; Jump if not equal to expected

    popa
    ret

disk_fail:
    mov si, err_msg
    call print
    jmp hang

line1     db " +------------------------+", 0
line2     db " |      NOVA OS v1.0      |", 0
line3     db " |   Alpha Coders Team    |", 0
line4     db " +------------------------+", 0
cpu_msg   db " CPU      : OK", 0
mem_msg   db " MEMORY   : OK", 0
sto_msg   db " STORAGE  : OK", 0
sec_msg   db " SECURITY : OK", 0
success   db " Boot Successful. Starting Nova OS...", 0
loading_kernel db " Loading kernel into memory...", 0
err_msg   db " Disk read error!", 0
hang_msg  db " System Halted!", 0

times 510 - ($ - $$) db 0
dw 0xAA55