[org 0]
[bits 16]

; Kernel entry point
kernel_start:
    ; Set up segments
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFF0

    ; Set video mode (text mode 80x25, 16 colors)
    ; But don't clear the screen to preserve bootloader messages
    mov ax, 0x0003
    int 0x10

    ; Display kernel loaded message
    mov si, kernel_loaded_msg
    mov dh, 12          ; Row (below bootloader messages)
    mov dl, 25          ; Column
    mov bl, 0x1F        ; Blue background, white text
    call print_at

    ; Wait for a keypress to continue
    mov si, press_key_msg
    mov dh, 14          ; Row
    mov dl, 20          ; Column
    mov bl, 0x07        ; Black background, white text
    call print_at

    ; Wait for any key
    mov ah, 0x00
    int 0x16

    ; Start login process
    call login_screen

    ; If we get here, login was successful
    call clear_screen

    ; Initialize terminal variables
    mov byte [current_row], 0    ; Start at the top of the screen

    ; Display welcome message
    mov si, welcome_msg
    mov bl, 0x2F        ; Green background, white text
    call print_line

    ; Add a blank line
    mov si, empty_line
    mov bl, 0x07        ; Black background, white text
    call print_line

    ; Infinite loop - wait for commands
command_loop:
    ; Display command prompt
    mov si, prompt_msg
    mov bl, 0x07        ; Black background, white text
    call print_string_no_newline

    ; Calculate prompt length to position cursor correctly
    mov cx, 0
    mov si, prompt_msg
.count_prompt:
    lodsb
    or al, al
    jz .done_count
    inc cx
    jmp .count_prompt
.done_count:

    ; Position cursor after prompt
    mov ah, 0x02        ; Set cursor position
    mov bh, 0           ; Page number
    mov dh, [current_row] ; Current row
    mov dl, cl          ; Column = prompt length
    int 0x10

    ; Get user input
    mov di, command_buffer
    call get_input

    ; Process command
    call process_command

    ; Loop for next command
    jmp command_loop

; ===== Login Screen =====
login_screen:
    ; Clear screen but preserve bootloader-style appearance
    mov ax, 0x0600      ; AH=06 (scroll up/clear), AL=00 (clear entire window)
    mov bh, 0x07        ; BH=attribute (black background, white text)
    mov cx, 0x0000      ; CH=row of upper left corner, CL=column of upper left corner
    mov dx, 0x184F      ; DH=row of lower right corner, DL=column of lower right corner
    int 0x10            ; BIOS video interrupt

    ; Display bootloader-style header
    mov si, line1
    mov dh, 2           ; Row
    mov dl, 20          ; Column
    mov bl, 0x07        ; Black background, white text
    call print_at

    mov si, line2
    mov dh, 3           ; Row
    mov dl, 20          ; Column
    mov bl, 0x07        ; Black background, white text
    call print_at

    mov si, line3
    mov dh, 4           ; Row
    mov dl, 20          ; Column
    mov bl, 0x07        ; Black background, white text
    call print_at

    mov si, line4
    mov dh, 5           ; Row
    mov dl, 20          ; Column
    mov bl, 0x07        ; Black background, white text
    call print_at

    ; Display login header
    mov si, login_header
    mov dh, 7           ; Row
    mov dl, 25          ; Column
    mov bl, 0x1F        ; Blue background, white text
    call print_at

    ; Display username prompt
    mov si, username_prompt
    mov dh, 9           ; Row
    mov dl, 20          ; Column
    mov bl, 0x07        ; Black background, white text
    call print_at

    ; Get username input
    mov ah, 0x02        ; Set cursor position
    mov bh, 0           ; Page number
    mov dh, 9           ; Row
    mov dl, 30          ; Column (after "Username: ")
    int 0x10

    mov di, username_buffer
    call get_input

    ; Display password prompt
    mov si, password_prompt
    mov dh, 11          ; Row
    mov dl, 20          ; Column
    mov bl, 0x07        ; Black background, white text
    call print_at

    ; Get password input (display * for each character)
    mov ah, 0x02        ; Set cursor position
    mov bh, 0           ; Page number
    mov dh, 11          ; Row
    mov dl, 30          ; Column (after "Password: ")
    int 0x10

    mov di, password_buffer
    mov byte [show_input], 0    ; Don't show actual characters
    call get_input
    mov byte [show_input], 1    ; Reset for future inputs

    ; Authenticate user
    call authenticate
    cmp byte [auth_success], 1
    je .login_success

    ; Authentication failed
    mov si, auth_fail_msg
    mov dh, 13          ; Row
    mov dl, 20          ; Column
    mov bl, 0x4F        ; Red background, white text
    call print_at

    ; Wait for a keypress
    mov ah, 0x00
    int 0x16

    ; Try again
    jmp login_screen

.login_success:
    ; Authentication succeeded
    mov si, auth_success_msg
    mov dh, 13          ; Row
    mov dl, 20          ; Column
    mov bl, 0x2F        ; Green background, white text
    call print_at

    ; Wait a moment
    mov cx, 0xFFFF
.delay:
    loop .delay

    ; Return to caller (which will clear screen and show command prompt)
    ret

; ===== Authenticate User =====
; Compares username and password with stored credentials
authenticate:
    ; Reset auth_success flag
    mov byte [auth_success], 0

    ; Check username
    mov si, username_buffer
    mov di, valid_username
    call strcmp
    jne .auth_fail

    ; Check password
    mov si, password_buffer
    mov di, valid_password
    call strcmp
    jne .auth_fail

    ; If we get here, authentication succeeded
    mov byte [auth_success], 1
    ret

.auth_fail:
    ret

; ===== Process Command =====
process_command:
    ; Check if command is empty
    cmp byte [command_buffer], 0
    je .done

    ; Compare with "help" command
    mov si, command_buffer
    mov di, help_cmd
    call strcmp
    je .help_command

    ; Compare with "clear" command
    mov si, command_buffer
    mov di, clear_cmd
    call strcmp
    je .clear_command

    ; Compare with "logout" command
    mov si, command_buffer
    mov di, logout_cmd
    call strcmp
    je .logout_command

    ; Compare with "shutdown" command
    mov si, command_buffer
    mov di, shutdown_cmd
    call strcmp
    je .shutdown_command

    ; If we get here, command not recognized
    mov si, unknown_cmd_msg
    mov bl, 0x07        ; Black background, white text
    call print_line
    jmp .done

.help_command:
    ; Print help header
    mov si, help_msg
    mov bl, 0x07        ; Black background, white text
    call print_line

    ; Print each command on a new line
    mov si, help_cmd_1
    call print_line

    mov si, help_cmd_2
    call print_line

    mov si, help_cmd_3
    call print_line

    mov si, help_cmd_4
    call print_line

    ; Add an empty line
    mov si, empty_line
    call print_line

    jmp .done

.clear_command:
    call clear_screen
    mov byte [current_row], 0    ; Reset current row

    ; Redisplay welcome message
    mov si, welcome_msg
    mov bl, 0x2F        ; Green background, white text
    call print_line

    ; Add a blank line
    mov si, empty_line
    mov bl, 0x07        ; Black background, white text
    call print_line

    jmp .done

.logout_command:
    ; Go back to login screen
    call login_screen

    ; After successful login, clear screen and reset terminal
    call clear_screen
    mov byte [current_row], 0    ; Reset current row

    ; Redisplay welcome message
    mov si, welcome_msg
    mov bl, 0x2F        ; Green background, white text
    call print_line

    ; Add a blank line
    mov si, empty_line
    mov bl, 0x07        ; Black background, white text
    call print_line

    jmp .done

.shutdown_command:
    mov si, shutdown_msg
    mov bl, 0x07        ; Black background, white text
    call print_line

    ; Wait a moment
    mov cx, 0xFFFF
.delay:
    loop .delay

    ; Halt the system
    hlt
    jmp $

.done:
    ret

; ===== String Compare =====
; Compare strings at SI and DI
; Sets zero flag if equal
strcmp:
    pusha
    mov cx, 32          ; Maximum string length to compare

.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, 0           ; Check for end of SI string
    je .check_di
    cmp ah, 0           ; Check for end of DI string
    je .not_equal
    cmp al, ah          ; Compare characters
    jne .not_equal
    inc si
    inc di
    loop .loop
    jmp .equal          ; Strings are equal up to max length

.check_di:
    cmp ah, 0           ; If both strings end at same point, they're equal
    je .equal

.not_equal:
    popa
    cmp ax, bx          ; Set zero flag = 0 (not equal)
    ret

.equal:
    popa
    cmp ax, ax          ; Set zero flag = 1 (equal)
    ret

; ===== Get Input =====
; Gets user input and stores at DI
; Returns when Enter is pressed
get_input:
    push ax
    push cx
    push dx

    ; Save current cursor position
    mov ah, 0x03        ; Get cursor position
    mov bh, 0           ; Page number
    int 0x10
    push dx             ; Save cursor position (DH=row, DL=column)

    mov cx, 0           ; Character count

.loop:
    mov ah, 0x00        ; Wait for keypress
    int 0x16

    cmp al, 0x0D        ; Check for Enter key
    je .done

    cmp al, 0x08        ; Check for Backspace
    je .backspace

    cmp cx, 31          ; Check if buffer is full
    je .loop

    ; Store character
    stosb
    inc cx

    ; Echo character to screen
    mov ah, 0x0E
    cmp byte [show_input], 0
    jne .show_char

    ; Show * instead of actual character
    push ax
    mov al, '*'
    int 0x10
    pop ax
    jmp .loop

.show_char:
    int 0x10
    jmp .loop

.backspace:
    cmp cx, 0           ; Check if buffer is empty
    je .loop

    ; Remove last character
    dec di
    dec cx

    ; Echo backspace
    mov ah, 0x0E
    mov al, 0x08        ; Backspace
    int 0x10
    mov al, ' '         ; Space (to clear the character)
    int 0x10
    mov al, 0x08        ; Backspace again (to move cursor back)
    int 0x10

    jmp .loop

.done:
    ; Null-terminate the string
    mov byte [di], 0

    ; Add a newline for the terminal
    mov si, empty_line
    mov bl, 0x07        ; Black background, white text
    call print_line

    pop dx              ; Restore saved cursor position
    pop dx
    pop cx
    pop ax
    ret

; ===== Print At =====
; SI = string to print
; DH = row, DL = column
; BL = attribute
print_at:
    pusha

    ; Set cursor position
    mov ah, 0x02
    mov bh, 0
    int 0x10

    ; Get string length
    mov cx, 0
    mov di, si
.count:
    cmp byte [di], 0
    je .print
    inc cx
    inc di
    jmp .count

.print:
    ; Print string
    mov ax, 0x1300      ; AH=13 (print string), AL=00 (attribute in BL, cursor unchanged)
    mov bp, si          ; ES:BP points to string
    int 0x10

    popa
    ret

; ===== Print String No Newline =====
; SI = string to print
; BL = attribute
print_string_no_newline:
    pusha

    ; Set cursor position based on current_row
    mov ah, 0x02
    mov bh, 0
    mov dh, [current_row]
    mov dl, 0
    int 0x10

    ; Get string length
    mov cx, 0
    mov di, si
.count:
    cmp byte [di], 0
    je .print
    inc cx
    inc di
    jmp .count

.print:
    ; Print string
    mov ax, 0x1300      ; AH=13 (print string), AL=01 (attribute in BL, update cursor)
    mov bp, si          ; ES:BP points to string
    int 0x10

    popa
    ret

; ===== Print Line =====
; SI = string to print
; BL = attribute
; Prints a string and advances to the next line
print_line:
    pusha

    ; Set cursor position based on current_row
    mov ah, 0x02
    mov bh, 0
    mov dh, [current_row]
    mov dl, 0
    int 0x10

    ; Get string length
    mov cx, 0
    mov di, si
.count:
    cmp byte [di], 0
    je .print
    inc cx
    inc di
    jmp .count

.print:
    ; Print string
    mov ax, 0x1300      ; AH=13 (print string), AL=00 (attribute in BL, cursor unchanged)
    mov bp, si          ; ES:BP points to string
    int 0x10

    ; Advance to next line
    inc byte [current_row]

    ; Check if we need to scroll
    cmp byte [current_row], 24  ; Screen height - 1
    jl .done

    ; Scroll the screen
    call scroll_screen
    mov byte [current_row], 23  ; Set to last line

.done:
    popa
    ret

; We've removed the print_multiline function since we're using print_line directly

; ===== Scroll Screen =====
; Scrolls the screen up one line
scroll_screen:
    pusha

    ; Scroll up one line
    mov ax, 0x0601      ; AH=06 (scroll up), AL=01 (one line)
    mov bh, 0x07        ; Attribute for blank lines
    mov cx, 0x0000      ; Upper left corner (0,0)
    mov dx, 0x184F      ; Lower right corner (24,79)
    int 0x10

    popa
    ret

; ===== Clear Screen =====
clear_screen:
    pusha

    ; Set video mode (text mode 80x25, 16 colors)
    mov ax, 0x0003
    int 0x10

    popa
    ret

; ===== Data Section =====
; System messages
kernel_loaded_msg db 'NOVA OS KERNEL LOADED!', 0
press_key_msg db 'Press any key to continue to login...', 0
login_header db 'NOVA OS LOGIN', 0
username_prompt db 'Username: ', 0
password_prompt db 'Password: ', 0
auth_success_msg db 'Login successful! Welcome to Nova OS.', 0
auth_fail_msg db 'Invalid username or password. Please try again.', 0
welcome_msg db 'Welcome to Nova OS v1.0', 0
prompt_msg db 'nova> ', 0
unknown_cmd_msg db 'Unknown command. Type "help" for available commands.', 0
help_msg db 'Available commands:', 0
help_cmd_1 db '  help     - Display this help message', 0
help_cmd_2 db '  clear    - Clear the screen', 0
help_cmd_3 db '  logout   - Log out and return to login screen', 0
help_cmd_4 db '  shutdown - Shut down the system', 0
shutdown_msg db 'System shutting down...', 0

; Banner lines (same as bootloader)
line1 db '+------------------------+', 0
line2 db '|      NOVA OS v1.0      |', 0
line3 db '|   Alpha Coders Team    |', 0
line4 db '+------------------------+', 0

; Commands
help_cmd db 'help', 0
clear_cmd db 'clear', 0
logout_cmd db 'logout', 0
shutdown_cmd db 'shutdown', 0
ls_cmd db 'ls', 0
mkdir_cmd db 'mkdir', 0
cd_cmd db 'cd', 0
touch_cmd db 'touch', 0
cat_cmd db 'cat', 0
rm_cmd db 'rm', 0
pwd_cmd db 'pwd', 0

; User credentials (hardcoded for simplicity)
valid_username db 'admin', 0
valid_password db 'password', 0

; Buffers
username_buffer times 32 db 0
password_buffer times 32 db 0
command_buffer times 32 db 0

; Flags and variables
auth_success db 0       ; 1 if authentication succeeded, 0 otherwise
show_input db 1         ; 1 to show input characters, 0 to show * instead
current_row db 0        ; Current row for terminal output

; File system variables
MAX_FILES equ 16        ; Maximum number of files in the system
MAX_DIRS equ 8          ; Maximum number of directories
MAX_NAME_LEN equ 12     ; Maximum length of file/directory names
MAX_CONTENT_LEN equ 256 ; Maximum content length per file
current_dir db 0        ; Current directory index

; File system structures
; Directory structure: index, parent_index, name
dir_indices times MAX_DIRS db 0        ; 0 = unused, 1 = used
dir_parents times MAX_DIRS db 0        ; Parent directory index (0 = root)
dir_names times MAX_DIRS*MAX_NAME_LEN db 0  ; Directory names

; File structure: index, directory_index, name, content
file_indices times MAX_FILES db 0      ; 0 = unused, 1 = used
file_dirs times MAX_FILES db 0         ; Directory index
file_names times MAX_FILES*MAX_NAME_LEN db 0  ; File names
file_contents times MAX_FILES*MAX_CONTENT_LEN db 0  ; File contents

; File system strings
root_dir db '/', 0
current_path db '/', 0
path_separator db '/', 0
parent_dir db '..', 0

; Additional strings
empty_line db '', 0     ; Empty line for spacing
arg_buffer times 32 db 0  ; Buffer for command arguments

; Our kernel is larger than one sector, so we don't need padding
