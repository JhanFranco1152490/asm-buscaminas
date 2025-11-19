.code

;Macro para esperar una tecla
esperar_tecla macro
    push ax
    mov ah, 00h
    int 16h
    pop ax
endm

;Macro para leer un char
leer_char macro
    mov ah, 01h 
    int 21h
    xor ah,ah ;Guarda el char en al
endm

;Macro para leer un string
leer_string macro buffer
    push dx
    lea dx, buffer
    mov ah, 0Ah
    int 21h
    pop dx
endm

;Macro para pasar un string a int
string_to_int macro string
    LOCAL convert_loop
    LOCAL convert_fin
    push bx
    push cx
    push dx
    push si
    
    lea si, string
    add si, 2d

    xor ax, ax
    xor bx, bx
    mov cx, 10
    
convert_loop:
    mov bl, [si]
    cmp bl, '0'
    jl convert_fin
    cmp bl, '9'
    jg convert_fin
    
    sub bl, '0'
    mul cx
    add ax, bx ;Guarda en ax
    inc si
    jmp convert_loop

convert_fin:
    pop si
    pop dx
    pop cx
    pop bx
endm