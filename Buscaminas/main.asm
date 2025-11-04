;#include "display.asm"
;#include "input.asm"
;#include "logic.asm"
;#include "include.asm"

.model small
.stack
.data
    ; Mensajes de la aplicacion
    msg_welcome db 'Bienvenido al Buscaminas!',0Dh,0Ah,'$'
    msg_start_game db 'Presiona para empezar el juego',0Dh,0Ah,'$'
    msg_buscaminas db 'BUSCAMINAS ASSEMBLER',0Dh,0Ah,'$'
    msg_enter_move db 'Ingresa tu movimiento (fila, columna): $'
    msg_enter_move_row db 'Ingresa tu movimiento (fila): $'
    msg_enter_move_column db 'Ingresa tu movimiento (columna): $'
    msg_invalid_move db 'Movimiento invalido!',0Dh,0Ah,'$'
    msg_game_over db 'Juego terminado! PERDISTE',0Dh,0Ah,'$'
    msg_victory db 'Felicidades, has ganado!',0Dh,0Ah,'$'
    msg_new_game db 'Presiona X para volver a jugar',0Dh,0Ah,'$'
    msg_new_line db 0Dh,0Ah,'$'
    ;Tablero a imprimir
    tablero db '  A B C D E F G H',0Dh,0Ah
            db '1',8 dup(' ', '-'),0Dh,0Ah
            db '2',8 dup(' ', '-'),0Dh,0Ah
            db '3',8 dup(' ', '-'),0Dh,0Ah
            db '4',8 dup(' ', '-'),0Dh,0Ah
            db '5',8 dup(' ', '-'),0Dh,0Ah
            db '6',8 dup(' ', '-'),0Dh,0Ah
            db '7',8 dup(' ', '-'),0Dh,0Ah
            db '8',8 dup(' ', '-'),0Dh,0Ah,'$'

    tablero_aux db '  A B C D E F G H',0Dh,0Ah
                db '1',8 dup(' ', '-'),0Dh,0Ah
                db '2',8 dup(' ', '-'),0Dh,0Ah
                db '3',8 dup(' ', '-'),0Dh,0Ah
                db '4',8 dup(' ', '-'),0Dh,0Ah
                db '5',8 dup(' ', '-'),0Dh,0Ah
                db '6',8 dup(' ', '-'),0Dh,0Ah
                db '7',8 dup(' ', '-'),0Dh,0Ah
                db '8',8 dup(' ', '-'),0Dh,0Ah,'$'

    ;Tablero interno
    tablero_game    db 7 dup('O'),'X'
                    db 'X',7 dup('O')
                    db 7 dup('O'),'X'
                    db 'X',7 dup('O')
                    db 7 dup('O'),'X'
                    db 'X',7 dup('O')
                    db 7 dup('O'),'X'
                    db 'X',7 dup('O')
    ;Variables
    bombas dw 8
    contador dw 0
    tablero_size dw 64d
    fila     dw 0
    columna  dw 0
    error    equ -1

.code

;Macro para imprimir mensajes
print_msg macro string
    push ax
    push dx

    mov dx, offset string
    mov ah, 9h
    int 21h

    pop dx
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

;Macro para esperar una tecla
esperar_tecla macro
    push ax

    mov ah, 00h
    int 16h

    pop ax
endm

;macro para leer un char
leer_char macro
    mov ah, 01h 
    int 21h
    xor ah,ah
endm

;macro para limpiar la pantalla
limpiar_pantalla macro
    push ax

    mov ah, 00h
    mov al, 3h
    int 10h

    pop ax
endm

;Main
main PROC
    ; Inicializacion del segmento de datos
    MOV ax, @data
    MOV ds, ax

    ;limpiar pantalla
    limpiar_pantalla

    ; Mostrar mensaje de bienvenida
    print_msg msg_welcome

    print_msg msg_start_game
    esperar_tecla

    ;Empezar el juego    
empezar_game:
    call empezar_juego

reinicio:
    print_msg msg_new_game
    leer_char
    cmp ax, 'X'
    jne fin_programa
    call reiniciar_tablero
    jmp empezar_game

    ;Salir del programa
fin_programa:
    mov ah, 4Ch
    int 21h
main ENDP
    
;PROCEDIMIENTOS

;Procedimiento para empezar un juego
empezar_juego PROC
empezar:
    limpiar_pantalla
    print_msg msg_buscaminas
    print_msg tablero

    ; Leer columna (letra)
    print_msg msg_enter_move_column
    leer_char
    call convertir_a_letra
    cmp ax, error
    je seguir_juego
    mov columna, ax
    print_msg msg_new_line

    ; Leer fila (número)
    print_msg msg_enter_move_row
    leer_char
    call convertir_a_entero
    cmp ax, error
    je seguir_juego
    mov fila, ax
    print_msg msg_new_line

    ; Determinar casilla
    call determinar_casilla     ; al = valor casilla
    mov bl, al                  ; bl guarda contenido ('X' o 'O')
    call revelar_casilla        ; Revela en tablero

    esperar_tecla
    cmp bl, 'X'
    je derrota
    inc contador
    mov ax, contador
    add ax, bombas
    cmp ax, tablero_size
    je victoria
    jmp seguir_juego

seguir_juego:
    jmp empezar

victoria:
    limpiar_pantalla
    print_msg msg_victory
    print_msg tablero
    ret

derrota:
    limpiar_pantalla
    print_msg msg_game_over
    print_msg tablero
    ret
empezar_juego ENDP

;Procedimiento para convertir a columna un letra
convertir_a_letra PROC
    cmp ax, 'A'
    jl convertir_error_letra
    cmp ax, 'H'
    jg convertir_error_letra
    jmp convertir_fin_letra 
convertir_error_letra:
    print_msg msg_new_line
    print_msg msg_invalid_move
    esperar_tecla
    mov ax, error
    ret
convertir_fin_letra:
    sub ax, 'A'
fin_letra:
    ret
convertir_a_letra ENDP

;Procedimiento para convertir a fila un char
convertir_a_entero PROC
    cmp ax, '1'
    jl convertir_error_entero
    cmp ax, '8'
    jg convertir_error_entero
    jmp convertir_fin_entero 
convertir_error_entero:
    print_msg msg_new_line
    print_msg msg_invalid_move
    esperar_tecla
    mov ax, error
    ret
convertir_fin_entero:
    sub ax, '1'
fin_entero:
    ret
convertir_a_entero ENDP

determinar_casilla PROC
    mov si, offset tablero_game
    mov ax, 8
    mul fila
    add ax, columna
    add si, ax
    mov al, [si]
    ret
determinar_casilla ENDP

revelar_casilla PROC
    mov si, offset tablero
    add si, 21d
    mov ax, 19d
    mul fila
    add si, ax
    mov ax, 2d
    mul columna
    add si, ax 
    mov BYTE PTR [si], bl
    ret
revelar_casilla ENDP

reiniciar_tablero PROC
    push si
    push di
    push cx

    mov si, offset tablero_aux
    mov di, offset tablero        
    mov cx, 172d   
    ciclo:                
        mov al, [si]    
        mov BYTE PTR [di], al
        inc si
        inc di
        dec cx
        cmp cx,0
        jne ciclo
    pop cx
    pop di
    pop si
    ret
reiniciar_tablero ENDP

end main