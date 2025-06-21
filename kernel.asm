; ==================================================================
;
;   NiluxOS Kernel By Nihadh Nilabdeen
;
;   A compact 16-bit real mode kernel for basic system interaction.
;   This version is refactored for improved clarity, reduced size,
;   and corrected for 8086/8088 compatibility.
;
; ==================================================================
;
;   Features:
;   - Command-line interface with prompt.
;   - Commands: 'info', 'clear', 'help'.
;   - 'info': Displays detailed hardware information (memory, drives,
;             date/time, video, keyboard, mouse, ports).
;   - 'clear': Clears the screen and resets to the welcome display.
;   - 'help': Lists available commands.
;   - Consistent "home screen" (welcome + hint) on boot and clear.
;   - Improved readability with extra newlines before prompt.
;
; ==================================================================


    BITS 16             ; 16-bit real mode
    ORG 0x0000          ; Loaded at segment base

; --- Constants ---
%define INPUT_BUFFER_MAX_LEN 64
%define BASE_MEMORY_KB       640 ; Standard conventional memory

; ------------------------------------------------------------------
; START OF MAIN KERNEL CODE

os_main:
    cli                 ; Disable interrupts
    cld                 ; Set string operations to increment

    ; Setup segments and stack
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF      ; Stack at end of 64K segment

    sti                 ; Enable interrupts

    ; Initial screen display (Home Screen)
    call os_display_home_screen

; --- Main Command Loop ---
.command_loop:
    call os_print_newline ; Add spacing before prompt
    mov si, prompt_message
    call os_print_string    ; Print "NiluxOS:>" prompt

    mov bx, input_buffer    ; Read user input
    call os_read_line
    call os_print_newline

    ; Command Parsing
    mov si, input_buffer
    mov di, cmd_info
    call os_compare_strings
    cmp ax, 1
    je .handle_info_command

    mov si, input_buffer
    mov di, cmd_clear
    call os_compare_strings
    cmp ax, 1
    je .handle_clear_command

    mov si, input_buffer
    mov di, cmd_help
    call os_compare_strings
    cmp ax, 1
    je .handle_help_command

    ; Handle Unknown Command
    mov si, msg_unknown_cmd
    call os_print_string
    mov si, input_buffer
    call os_print_string
    call os_print_newline
    jmp .command_loop

.handle_info_command:
    call os_show_system_info
    jmp .command_loop

.handle_clear_command:
    call os_display_home_screen ; Re-display home screen
    jmp .command_loop

.handle_help_command:
    mov si, msg_available_commands
    call os_print_string
    call os_print_newline

    mov si, msg_help_info
    call os_print_string
    call os_print_newline

    mov si, msg_help_clear
    call os_print_string
    call os_print_newline
    
    mov si, msg_help_help
    call os_print_string
    call os_print_newline

    call os_print_newline   ; Extra newline for spacing
    jmp .command_loop


; ------------------------------------------------------------------
; KERNEL FUNCTIONS
; ------------------------------------------------------------------

; os_display_home_screen
; Clears screen, displays welcome and hint.
os_display_home_screen:
    call os_clear_screen

    mov si, welcome_message
    call os_print_string
    call os_print_newline

    mov si, msg_initial_hint
    call os_print_string
    call os_print_newline
    call os_print_newline ; Extra newline
    ret

; os_print_string
; Prints a null-terminated string (DS:SI)
os_print_string:
    push ax
    push si
    mov ah, 0x0E ; BIOS teletype function
.char_loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .char_loop
.done:
    pop si
    pop ax
    ret

; os_print_newline
; Prints carriage return and line feed.
os_print_newline:
    push ax
    mov ah, 0x0E
    mov al, 13 ; CR
    int 0x10
    mov al, 10 ; LF
    int 0x10
    pop ax
    ret

; os_clear_screen
; Clears screen and sets cursor to top-left.
os_clear_screen:
    push ax
    mov ah, 0x00 ; BIOS Set Video Mode
    mov al, 0x03 ; 80x25 text mode, clears screen
    int 0x10
    pop ax
    ret

; os_read_line
; Reads line input into buffer (BX).
os_read_line:
    push ax
    push bx
    push cx
    push dx
    push si
    xor si, si ; current buffer position

.read_char_loop:
    mov ah, 0x00 ; BIOS Read character from keyboard
    int 0x16

    cmp al, 0x08 ; Backspace?
    je .handle_backspace

    cmp al, 0x0D ; Enter?
    je .handle_enter

    cmp si, INPUT_BUFFER_MAX_LEN - 1 ; Buffer full?
    jge .read_char_loop

    mov ah, 0x0E ; Echo character
    int 0x10

    mov [bx + si], al ; Store char
    inc si
    jmp .read_char_loop

.handle_backspace:
    cmp si, 0 ; Buffer empty?
    je .read_char_loop

    dec si
    mov ah, 0x0E
    mov al, 0x08 ; Backspace char
    int 0x10
    mov al, ' '  ; Overwrite with space
    int 0x10
    mov al, 0x08 ; Move cursor back
    int 0x10
    jmp .read_char_loop

.handle_enter:
    mov byte [bx + si], 0 ; Null-terminate string
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; os_compare_strings
; Compares two null-terminated strings (SI, DI).
; Returns AX = 1 if equal, 0 otherwise.
os_compare_strings:
    push bx
    push cx
    push dx

    xor ax, ax              ; Assume unequal (AX=0)
    mov cx, 0xFFFF          ; Max loop count

.compare_loop:
    cmpsb                   ; Compare [DS:SI] with [ES:DI]
    jne .not_equal
    cmp byte [si-1], 0      ; Check for null terminator
    je .is_equal

    loop .compare_loop

.not_equal:
    xor ax, ax
    jmp .done_compare

.is_equal:
    mov ax, 1

.done_compare:
    pop dx
    pop cx
    pop bx
    ret

; os_get_extended_memory_info
; Retrieves total extended memory in KB.
; Returns AX = KB.
os_get_extended_memory_info:
    push bx
    mov ah, 0x88 ; BIOS Get Extended Memory Size
    int 0x15
    pop bx
    ret

; os_print_decimal
; Converts and prints 16-bit number (AX) to decimal.
os_print_decimal:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, decimal_buffer + 5 ; Point to end for null terminator
    mov byte [di], 0

    cmp ax, 0 ; Handle 0 case
    jne .not_zero_decimal
    dec di
    mov byte [di], '0'
    mov si, di
    jmp .print_decimal_string

.not_zero_decimal:
    mov bx, 10 ; Divisor
.divide_loop_decimal:
    xor dx, dx ; Clear DX for division
    div bx     ; AX = AX / 10, DX = AX % 10
    add dl, '0' ; Convert remainder to ASCII
    dec di
    mov byte [di], dl
    cmp ax, 0
    jne .divide_loop_decimal

    mov si, di ; Set SI to start of string

.print_decimal_string:
    call os_print_string
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; os_get_hard_drive_count
; Gets number of hard disk drives.
; Returns AX = count.
os_get_hard_drive_count:
    push bx
    push cx
    push dx
    mov dl, 0x80 ; Start checking from first hard drive
    xor ax, ax   ; Count

.check_hdd_loop:
    mov ah, 0x08 ; BIOS Get Drive Parameters
    int 0x13
    jc .no_more_hdds ; If carry flag set, no more drives
    inc ax           ; Increment count
    inc dl           ; Next drive
    jmp .check_hdd_loop

.no_more_hdds:
    pop dx
    pop cx
    pop bx
    ret

; os_get_time
; Gets current time (CH=Hour, CL=Minute, DH=Second - BCD).
os_get_time:
    push ax
    push dx
    mov ah, 0x02 ; BIOS Get RTC Time
    int 0x1A
    pop dx
    pop ax
    ret

; os_get_date
; Gets current date (CH=Century, CL=Year, DH=Month, DL=Day - BCD).
os_get_date:
    push ax
    push dx
    mov ah, 0x04 ; BIOS Get RTC Date
    int 0x1A
    pop dx
    pop ax
    ret

; os_bcd_to_decimal
; Converts BCD byte (AL) to decimal (AX).
os_bcd_to_decimal:
    push bx
    mov ah, al
    and al, 0x0F ; Units digit
    shr ah, 4    ; Tens digit
    mov bl, 10
    mul bl       ; AL = tens * 10
    add al, ah   ; Add units
    movzx ax, al
    pop bx
    ret

; os_get_video_info
; Detects and prints video adapter type and current mode.
os_get_video_info:
    push ax
    push bx
    push si

    mov si, msg_video_adapter
    call os_print_string

    call os_get_equipment_list ; AX has equipment list
    and ax, 0x0030             ; Isolate video bits (5-4)
    shr ax, 4                  ; Shift to bits 1-0

    ; Print video type
    cmp al, 0x00
    je .print_ega_vga
    cmp al, 0x01
    je .print_cga_40
    cmp al, 0x02
    je .print_cga_80
    cmp al, 0x03
    je .print_mono
    mov si, msg_video_unknown
    jmp .print_video_type_and_mode

.print_ega_vga:
    mov si, msg_video_ega_vga
    jmp .print_video_type_and_mode
.print_cga_40:
    mov si, msg_video_cga_40
    jmp .print_video_type_and_mode
.print_cga_80:
    mov si, msg_video_cga_80
    jmp .print_video_type_and_mode
.print_mono:
    mov si, msg_video_mono

.print_video_type_and_mode:
    call os_print_string

    mov si, msg_current_mode
    call os_print_string

    mov ah, 0x0F ; BIOS Get Current Video Mode
    int 0x10     ; Returns AL=mode
    movzx ax, al ; Put mode in AX
    call os_print_decimal
    call os_print_newline

    pop si
    pop bx
    pop ax
    ret

; os_get_keyboard_info
; Detects and prints keyboard type.
os_get_keyboard_info:
    push ax
    push si

    mov si, msg_keyboard_type
    call os_print_string

    mov ah, 0x02 ; BIOS Get Keyboard Status Flags
    int 0x16     ; Returns AX=flags

    mov si, msg_keyboard_unknown ; Default

    test al, 0x10 ; Bit 4: 1=AT-compatible
    jz .check_xt

    test al, 0x20 ; Bit 5: 1=Enhanced keyboard
    jnz .print_enhanced_at
    
    mov si, msg_keyboard_at
    jmp .print_keyboard_type

.check_xt:
    mov si, msg_keyboard_xt
    jmp .print_keyboard_type

.print_enhanced_at:
    mov si, msg_keyboard_enhanced_at

.print_keyboard_type:
    call os_print_string
    call os_print_newline

    pop si
    pop ax
    ret

; os_get_mouse_info
; Detects if a mouse driver is installed.
os_get_mouse_info:
    push ax
    push bx
    push si

    mov si, msg_mouse_status
    call os_print_string

    mov ax, 0x0000 ; Mouse Reset and Status
    int 0x33       ; Call mouse handler

    cmp ax, 0xFFFF ; If AX returns FFFFh, driver is installed
    je .mouse_found

    mov si, msg_mouse_not_found
    jmp .print_mouse_status

.mouse_found:
    mov si, msg_mouse_found

.print_mouse_status:
    call os_print_string
    call os_print_newline

    pop si
    pop bx
    pop ax
    ret

; os_get_equipment_list
; Calls BIOS INT 0x11 to get equipment list.
; Returns AX = equipment list word.
os_get_equipment_list:
    int 0x11
    ret

; os_show_system_info
; Displays basic system information.
os_show_system_info:
    push bx ; Save BX for equipment list storage

    mov si, msg_cpu_info
    call os_print_string
    call os_print_newline

    mov si, msg_base_memory
    call os_print_string
    mov ax, BASE_MEMORY_KB
    call os_print_decimal
    mov si, msg_kb
    call os_print_string
    call os_print_newline

    mov si, msg_extended_memory
    call os_print_string
    call os_get_extended_memory_info ; AX = extended memory in KB
    call os_print_decimal
    mov si, msg_kb
    call os_print_string
    call os_print_newline

    ; Get equipment list once
    call os_get_equipment_list ; AX has equipment list
    mov bx, ax                  ; Store it in BX for later use

    ; Floppy Drive count (bits 7-6 of AX from INT 11h)
    mov si, msg_floppy_drives
    call os_print_string
    mov ax, bx                  ; Get equipment list back into AX
    shr ax, 6                   ; Shift floppy bits to AL
    and al, 0x03                ; Mask to get count (0-2)
    movzx ax, al
    call os_print_decimal
    call os_print_newline

    ; Hard Drive count
    mov si, msg_hard_drives
    call os_print_string
    call os_get_hard_drive_count ; AX will contain count
    call os_print_decimal
    call os_print_newline

    ; Current Date and Time (DD/MM/YYYY HH:MM:SS)
    mov si, msg_current_date_time
    call os_print_string
    
    call os_get_date ; CH=century, CL=year, DH=month, DL=day (BCD)
    
    mov al, dl ; Print Day
    call os_bcd_to_decimal
    call os_print_decimal
    mov si, msg_slash
    call os_print_string

    mov al, dh ; Print Month
    call os_bcd_to_decimal
    call os_print_decimal
    mov si, msg_slash
    call os_print_string

    mov al, ch ; Print Century
    call os_bcd_to_decimal
    call os_print_decimal

    mov al, cl ; Print Year
    call os_bcd_to_decimal
    call os_print_decimal
    
    mov si, msg_space
    call os_print_string

    call os_get_time ; CH=hour, CL=minute, DH=second (BCD)
    mov al, ch ; Hour
    call os_bcd_to_decimal
    call os_print_decimal
    mov si, msg_colon
    call os_print_string
    mov al, cl ; Minute
    call os_bcd_to_decimal
    call os_print_decimal
    mov si, msg_colon
    call os_print_string
    mov al, dh ; Second
    call os_bcd_to_decimal
    call os_print_decimal
    
    call os_print_newline

    ; Serial Port count (bits 9-8 of AX from INT 11h)
    mov si, msg_serial_ports
    call os_print_string
    mov ax, bx              ; Get equipment list back into AX
    and ax, 0x0300          ; Isolate serial port bits (9-8)
    shr ax, 8               ; Shift to AL
    call os_print_decimal
    call os_print_newline

    ; Parallel Port count (bits 15-14 of AX from INT 11h)
    mov si, msg_parallel_ports
    call os_print_string
    mov ax, bx              ; Get equipment list back into AX
    and ax, 0xC000          ; Isolate parallel port bits (15-14)
    shr ax, 14              ; Shift to AL
    call os_print_decimal
    call os_print_newline

    call os_get_video_info
    call os_get_keyboard_info
    call os_get_mouse_info

    pop bx ; Restore BX
    ret

; ------------------------------------------------------------------
; KERNEL DATA
; ------------------------------------------------------------------

decimal_buffer          times 6 db 0

welcome_message         db 'Welcome to NiluxOS By Nihadh Nilabdeen', 0
prompt_message          db 'NiluxOS:>', 0

input_buffer            times INPUT_BUFFER_MAX_LEN db 0

; Command strings
cmd_info                db 'info', 0
cmd_clear               db 'clear', 0
cmd_help                db 'help', 0

; Information messages
msg_cpu_info            db 'CPU: Generic x86 Processor', 0
msg_base_memory         db 'Conventional Memory: ', 0
msg_extended_memory     db 'Extended Memory: ', 0
msg_floppy_drives       db 'Floppy Drives: ', 0
msg_hard_drives         db 'Hard Drives: ', 0
msg_current_date_time   db 'Date/Time: ', 0
msg_serial_ports        db 'Serial Ports: ', 0
msg_parallel_ports      db 'Parallel Ports: ', 0
msg_kb                  db ' KB', 0
msg_unknown_cmd         db 'Unknown command: ', 0
msg_slash               db '/', 0
msg_colon               db ':', 0
msg_space               db ' ', 0

; Video and keyboard messages
msg_video_adapter       db 'Video Adapter: ', 0
msg_video_ega_vga       db 'EGA/VGA', 0
msg_video_cga_40        db 'CGA (40x25)', 0
msg_video_cga_80        db 'CGA (80x25)', 0
msg_video_mono          db 'Monochrome', 0
msg_video_unknown       db 'Unknown', 0
msg_current_mode        db ' Mode: ', 0

msg_keyboard_type       db 'Keyboard Type: ', 0
msg_keyboard_at         db 'AT (83/84-key)', 0
msg_keyboard_enhanced_at db 'Enhanced AT (101/102-key)', 0
msg_keyboard_xt         db 'XT (83-key)', 0
msg_keyboard_unknown    db 'Unknown', 0

; Mouse messages
msg_mouse_status        db 'Mouse: ', 0
msg_mouse_found         db 'Detected', 0
msg_mouse_not_found     db 'Not Detected', 0

; Help messages
msg_available_commands  db 'Available Commands:', 0
msg_help_info           db '  info  - Displays system hardware information.', 0
msg_help_clear          db '  clear - Clears the screen.', 0
msg_help_help           db '  help  - Shows this list of commands.', 0

; Initial hint
msg_initial_hint        db "Type 'help' to see available commands.", 0


; ==================================================================
; END OF KERNEL
; ==================================================================