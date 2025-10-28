;#include "display.asm"
;#include "input.asm"
;#include "logic.asm"
;#include "include.asm"

.model small
.stack
.data
    ; Mensajes de la aplicacion
    msg_invalid_move db 'Movimiento invalido!$'
    msg_game_over db 'Juego terminado!$'
    msg_victory db 'Felicidades, has ganado!$'
    msg_welcome db 'Bienvenido al Buscaminas!$'
    msg_enter_move db 'Ingresa tu movimiento (fila columna): $'
    tablero db 80 dup(0) ; Tablero de juego 8x8




.code

print_msg macro string
    mov dx, offset string
    mov ah, 9h
    int 21h
endm

print_pixel macro x, y, color
    print_line x, y, 1, color
endm

; Macro: print_line
; Draws a horizontal line of pixels on the screen.
; Parameters:
;   x     - Starting X coordinate
;   y     - Y coordinate
;   len   - Length of the line (number of pixels)
;   color - Color attribute for the pixels
print_line macro x, y, len, color
    LOCAL row_loop, end_m
    mov bx, len
    cmp bx, 0
    jle end_m

    add bx, x
    cmp bx, 320
    jnle end_m
    mov bx, 320
    sub bx, x
    continue_m:
    mov cx, x
    mov dx, y
    mov al, color
    mov ah, 0Ch
    row_loop:
        int 10h
        inc cx
        cmp cx, bx 
        jle row_loop
    end_m:
endm


print_rectangle macro x, y, wid, height, color
    LOCAL rect_loop, end_rect
    mov si, height
    cmp si, 0
    jle end_rect

    rect_loop:
        print_line x, y, wid, color
        inc y
        dec si
        jnz rect_loop
    end_rect:
endm

main PROC
    ; Inicializacion del segmento de datos
    MOV ax, @data
    MOV ds, ax

    ; Mostrar mensaje de bienvenida
    print_msg msg_welcome

    ; Inicializar el juego
    ;MODO VIDEO
    mov ah, 00h
    mov ax, 13h
    int 10h

    print_line 100, 100, 30, 10; Ejemplo de pixel rojo en (100,100)
    print_rectangle 50, 50, 60, 40, 14 ; Ejemplo de rectangulo amarillo
    ;Bucle principal del juego
    ;esperar 10 segundos
    mov cx, 0FFFFh
    retraso:
        loop retraso

    ;Salir del programa
    mov ah, 4Ch
    int 21h
main ENDP

end main