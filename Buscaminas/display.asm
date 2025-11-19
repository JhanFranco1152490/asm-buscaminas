.code 

;Macro para limpiar la pantalla
limpiar_pantalla macro
    push ax
    mov ah, 00h
    mov al, 3h
    int 10h
    pop ax
endm

;Macro para imprimir char
print_char macro char
    push ax
    push dx
    mov dx, char
    mov ah, 02h
    int 21h
    pop dx
    pop ax
endm

;Macro para imprimir mensajes
print_msg macro string
    push ax
    push dx
    lea dx, string
    mov ah, 9h
    int 21h
    pop dx
    pop ax
endm

;Macro para imprimir un numero
print_number macro number
    LOCAL no_cero
    LOCAL extraer_digitos
    LOCAL imprimir_digitos
    LOCAL print_fin
    push ax
    push bx
    push cx
    push dx

    mov ax,number
    cmp ax, 0
    jne no_cero
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp print_fin
    
no_cero:
    mov cx, 0
    mov bx, 10
    
extraer_digitos:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne extraer_digitos
    
imprimir_digitos:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop imprimir_digitos
    
print_fin:
    pop dx
    pop cx
    pop bx
    pop ax
endm