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
    msg_enter_rows db 'Ingresa las Filas del Tablero: $'
    msg_enter_colums db 'Ingresa las Columnas del Tablero: $'
    msg_enter_bombs db 'Ingresa Bombas del Tablero Maximo $'
    msg_invalid_entry db 'Dato Invalido',0Dh,0Ah,'$'
    msg_enter_move db 'Ingresa tu movimiento (fila, columna): $'
    msg_enter_move_row db 'Ingresa tu movimiento (fila): $'
    msg_enter_move_column db 'Ingresa tu movimiento (columna): $'
    msg_invalid_move db 'Movimiento invalido!',0Dh,0Ah,'$'
    msg_game_over db 'Juego terminado! PERDISTE',0Dh,0Ah,'$'
    msg_victory db 'Felicidades, has ganado!',0Dh,0Ah,'$'
    msg_new_game db 'Presiona X para volver a jugar',0Dh,0Ah,'$'
    msg_new_line db 0Dh,0Ah,'$'
    ;Tablero a imprimir
    tablero db 221 dup(0)

    ;Tablero interno
    tablero_game db 221 dup('O')

    ;Variables
    tablero_rows    dw 0
    tablero_colums  dw 0
    tablero_size    dw 0
    bombas          dw 0
    contador        dw 0
    contador_bombs  dw 0
    fila            dw 0
    columna         dw 0
    posicion_actual dw 0
    posicion_actual_tablero dw 0
    aux             dw 0
    error           equ -1

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

;macro para obtener un numero aleatorio
random macro rango
    LOCAL div_cero
    LOCAL fin_random
    push bx
    push cx
    push dx
    mov ah, 0h
    int 1Ah
    mov ax, dx
    xor dx, dx
    mov bx, rango
    cmp bx,0
    je div_cero
    div bx
    xor ah, ah
    mov al, dl
    jmp fin_random
div_cero:
    mov ax, 0h
fin_random:
    pop dx
    pop cx
    pop bx
endm

;Macro para mezclar las posiciones de un arreglo
mezclar_arreglo macro arr
    LOCAL mezcla_loop
    LOCAL fin_mezcla
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; obtener tamaño
    mov ax, tablero_size
    mov cx, ax
    dec cx              ; comenzamos en tamaño-1

    ; si cx = 0 o negativo, no hacer nada
    cmp cx, 0
    jle fin_mezcla

    lea si, arr
mezcla_loop:
    ; rango = cx+1  -> lo ponemos en BX y llamamos random
    mov bx, cx
    inc bx
    random bx    ; devuelve AX = 0..BX-1

    mov bx, ax         ; índice aleatorio en BX
    ; intercambiar arr[cx] <-> arr[bx]
    mov di, si         ; DI = base offset arr
    add di, cx         ; DI = base + cx
    mov al, [di]       ; AL = arr[cx]
    mov dl, [si+bx]       ; DL = arr[bx]

    mov BYTE PTR [di], dl
    mov BYTE PTR [si+bx], al

    dec cx
    jnz mezcla_loop

fin_mezcla:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
endm

;Main
main PROC
    ; Inicializacion del segmento de datos
    MOV ax, @data
    MOV ds, ax

    ;Empezar el juego    
empezar_game:
    ;limpiar pantalla
    limpiar_pantalla
    ; Mostrar mensaje de bienvenida
    print_msg msg_welcome
    print_msg msg_start_game
    esperar_tecla
    call leer_datos_tablero
    call crear_tablero_ramdom
    call crear_tablero_interfaz
    call empezar_juego

reinicio:
    call crear_tablero_real
    print_msg tablero
    print_msg msg_new_game
    leer_char
    cmp ax, 'X'
    jne fin_programa
    call reiniciar_juego
    jmp empezar_game

    ;Salir del programa
fin_programa:
    mov ah, 4Ch
    int 21h
main ENDP
    
;PROCEDIMIENTOS

;Procedimiento para pedir datos del tablero
leer_datos_tablero PROC
pedir_row:
    limpiar_pantalla
    print_msg msg_enter_rows
    call pedir_dimension_tablero
    esperar_tecla
    cmp ax, error
    je pedir_row
    mov tablero_rows,ax
pedir_colum:
    limpiar_pantalla
    print_msg msg_enter_colums
    call pedir_dimension_tablero
    esperar_tecla
    mov tablero_colums,ax
    cmp ax, error
    je pedir_colum

    ;Calcular tamaño del tablero
    mov ax, tablero_rows
    mov bx, tablero_colums
    mul bx
    mov tablero_size, ax  

pedir_bombas:
    limpiar_pantalla
    print_msg msg_enter_bombs
    call pedir_dimension_tablero
    cmp ax, error
    je pedir_bombas
    mov bombas, ax

    mov ax, tablero_size
    sub ax, 1
    cmp bombas, ax
    jg bombas_invalidas
    esperar_tecla
    ret

bombas_invalidas:
    print_msg msg_new_line
    print_msg msg_invalid_entry
    esperar_tecla
    jmp pedir_bombas
leer_datos_tablero ENDP

pedir_dimension_tablero PROC
    leer_char
    cmp al, '0'
    jle error_enter_tablero 
    mov ah, '0'
    add ah, 10d
    cmp al, ah
    jge error_enter_tablero
    xor ah,ah
    sub al, '0'
    ret
error_enter_tablero:
    print_msg msg_new_line
    print_msg msg_invalid_entry
    mov ax, error
    ret
pedir_dimension_tablero ENDP

;Procedimiento para crear el tablero de juego aleatoriamente
crear_tablero_ramdom PROC
    push ax
    push bx
    push cx
    push si
    push di

    lea si, tablero_game

    ; Cargar tamaño del tablero en CX
    mov ax, tablero_size
    mov cx, ax

    ; Colocar 'bombas' X en las primeras posiciones
    mov cx, bombas     ; número de bombas a colocar
    xor bx, bx                  ; inicio en índice 0
.colocar:
    mov byte ptr [si + bx], 'X'
    inc bx
    dec cx
    jnz .colocar

    mov bx, ax
    mov byte ptr [si + bx], '$'
    ; Llamar a mezclar_arreglo (espera DS:SI con base del arreglo)
    print_msg msg_new_line
    mezclar_arreglo tablero_game
    print_msg tablero_game
    esperar_tecla
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
crear_tablero_ramdom ENDP

crear_tablero_interfaz PROC
    push cx
    push dx
    mov ax, tablero_colums
    mov cx, 2d
    mul cx
    sub ax, 1d
    mov cx, ax
    lea si, tablero
    mov bx, 0d
    mov BYTE PTR [si+bx],' '
    inc bx
    mov BYTE PTR [si+bx],' '
    inc bx
dibujar_letras:
    test bx,1
    jz letra
    jmp espacio 
letra:
    mov ax, bx
    push bx
    mov bx, 2d
    div bx
    pop bx
    sub ax, 1
    add ax, 'A'
    mov BYTE PTR [si+bx], al
    jmp fin_crear
espacio:
    mov BYTE PTR [si+bx], ' '
fin_crear:
    inc bx
    loop dibujar_letras

    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx

    mov cx, tablero_rows
    mov contador, 1d
dibujar_row:
    mov ax, contador
    add ax, '0'  
    mov BYTE PTR [si+bx], al
    inc bx
    inc contador
    mov dx, tablero_colums
dibujar_casillas:
    mov BYTE PTR [si+bx], ' '
    inc bx
    mov al, '-'  
    mov BYTE PTR [si+bx], al
    inc bx
    dec dx
    jnz dibujar_casillas

    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx
    loop dibujar_row

    mov BYTE PTR [si+bx], '$'
    pop dx
    pop cx
    ret
crear_tablero_interfaz ENDP

;Procedimiento para empezar un juego
empezar_juego PROC
    mov contador, 0
empezar:
    limpiar_pantalla
    print_msg msg_buscaminas
    print_msg tablero
    print_msg msg_new_line

    ; Leer columna (letra)
    print_msg msg_enter_move_column
    leer_char
    call convertir_a_letra
    cmp ax, error
    je seguir_juego
    print_msg msg_new_line
    mov columna, ax

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
    esperar_tecla
    cmp bl, 'X'
    je derrota

    ;Si se realiza un movimiento ya hecho no se cuenta
    call calcular_posicion_tablero
    lea si, tablero
    add si, posicion_actual_tablero
    mov al,[si]
    cmp al,'-'
    jne seguir_juego

    ;Calcular numero de bombas adyacentes a la casilla actual
    call calcular_numero_bombas
    mov bx,contador_bombs
    add bl,'0'
    call revelar_casilla        ; Revela en tablero
    
    inc contador
    mov ax, tablero_size
    sub ax, bombas
    cmp contador, ax
    je victoria

seguir_juego:
    jmp empezar

victoria:
    limpiar_pantalla
    print_msg msg_victory
    ret

derrota:
    limpiar_pantalla
    print_msg msg_game_over
    ret
empezar_juego ENDP

;Procedimiento para convertir a columna un letra
convertir_a_letra PROC
    push bx
    cmp ax, 'A'
    jl convertir_error_letra
    mov bx, tablero_colums
    dec bx
    add bx, 'A'
    cmp ax, bx
    jg convertir_error_letra
    jmp convertir_fin_letra 
convertir_error_letra:
    print_msg msg_new_line
    print_msg msg_invalid_move
    esperar_tecla
    mov ax, error
    pop bx
    ret
convertir_fin_letra:
    sub ax, 'A'
fin_letra:
    pop bx
    ret
convertir_a_letra ENDP

;Procedimiento para convertir a fila un char
convertir_a_entero PROC
    push bx
    cmp ax, '1'
    jl convertir_error_entero
    mov bx, tablero_rows
    add bx, '0'
    cmp ax, bx
    jg convertir_error_entero
    sub ax, '1'
    pop bx
    ret
convertir_error_entero:
    print_msg msg_new_line
    print_msg msg_invalid_move
    esperar_tecla
    mov ax, error
    pop bx
    ret
convertir_a_entero ENDP

;Procedimiento para determinar que hay en la casilla
determinar_casilla PROC
    lea si, tablero_game
    call calcular_posicion_actual
    mov bx,posicion_actual
    mov al,[si+bx]
    ret
determinar_casilla ENDP

;Procedimiento para calcular la posicion actual dentro del array
calcular_posicion_actual PROC
    ;Calcular centro
    mov ax, tablero_colums
    mul fila
    add ax, columna
    mov posicion_actual, ax
    ret
calcular_posicion_actual ENDP

calcular_posicion_tablero PROC
    push cx
    mov ax, tablero_colums
    mov cx, 2d
    mul cx
    add ax, 3d
    mov posicion_actual_tablero, ax
    add posicion_actual_tablero, 2d ;Primer Numero para empezar en la coordenada 0,0
    mul fila
    add posicion_actual_tablero, ax
    mov ax, 2d
    mul columna
    add posicion_actual_tablero, ax
    pop cx
    ret
calcular_posicion_tablero ENDP

;Procedimiento para calcular el numero de bombas cercanas
calcular_numero_bombas PROC
    push bx
    push cx
    push dx
    mov contador_bombs, 0
    lea si, tablero_game
    mov bx, posicion_actual
    mov cx, tablero_colums
    dec cx

;Fila Superior
    ;Mirar si esta en la primera fila
    mov ax, tablero_colums
    cmp posicion_actual, ax
    jl fila_central
    sub bx, tablero_colums
    dec bx
    cmp columna, 0
    je casilla2
    call verificar_bomba
casilla2:
    inc bx
    call verificar_bomba
    inc bx
    cmp columna, cx
    je fila_central
    call verificar_bomba

;Fila Central
fila_central:
    mov bx, posicion_actual
    dec bx
    cmp columna, 0
    je casilla5
    call verificar_bomba
casilla5:
    add bx, 2d
    cmp columna, cx
    je fila_inferior
    call verificar_bomba

;Fila Inferior
fila_inferior:
    mov ax, tablero_size
    sub ax, tablero_colums
    cmp posicion_actual, ax
    jge fin_calcular_bombas
    add bx, tablero_colums
    sub bx, 2d
    cmp columna, 0
    je casilla7
    call verificar_bomba
casilla7:
    inc bx
    call verificar_bomba
casilla8:
    inc bx
    cmp columna, cx
    je fin_calcular_bombas
    call verificar_bomba

fin_calcular_bombas:
    pop dx
    pop cx
    pop bx
    ret
calcular_numero_bombas ENDP

verificar_bomba PROC
    cmp bx, 0
    jl no_bomba
    mov ax, tablero_size
    cmp bx, ax
    jge no_bomba
    mov al, [si+bx]
    cmp al, 'X'
    jne no_bomba
    inc contador_bombs
no_bomba:
    ret
verificar_bomba ENDP

;Procedimiento para revelar la casilla
revelar_casilla PROC
    lea si, tablero
    call calcular_posicion_tablero
    add si, posicion_actual_tablero
    mov BYTE PTR [si], bl
    ret
revelar_casilla ENDP

crear_tablero_real PROC
    push cx
    push dx
    mov ax, tablero_colums
    mov cx, 2d
    mul cx
    sub ax, 1d
    mov cx, ax
    lea si, tablero
    mov bx, 0d
    mov BYTE PTR [si+bx],' '
    inc bx
    mov BYTE PTR [si+bx],' '
    inc bx
dibujar_letras_real:
    test bx,1
    jz letra_real
    jmp espacio_real 
letra_real:
    mov ax, bx
    push bx
    mov bx, 2d
    div bx
    pop bx
    sub ax, 1
    add ax, 'A'
    mov BYTE PTR [si+bx], al
    jmp fin_crear_real
espacio_real:
    mov BYTE PTR [si+bx], ' '
fin_crear_real:
    inc bx
    loop dibujar_letras_real

    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx

    mov cx, tablero_rows
    mov contador, 1d
    mov aux, 0d
dibujar_row_real:
    mov ax, contador
    add ax, '0'  
    mov BYTE PTR [si+bx], al
    inc bx
    inc contador
    mov dx, tablero_colums
dibujar_casillas_real:
    mov BYTE PTR [si+bx], ' '
    inc bx
    push bx
    push si
    lea si, tablero_game
    mov bx, aux
    mov al, [si+bx]
    inc aux
    pop si
    pop bx
    mov BYTE PTR [si+bx], al
    inc bx
    dec dx
    jnz dibujar_casillas_real

    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx
    loop dibujar_row_real

    mov BYTE PTR [si+bx], '$'
    pop dx
    pop cx
    ret
crear_tablero_real ENDP

reiniciar_juego PROC
    ;Reinicia contadores y variables
    mov contador, 0
    mov contador_bombs, 0
    mov fila, 0
    mov columna, 0
    mov posicion_actual, 0

    ;Limpiar tablero interno (tablero_game)
    push cx
    push si
    lea si, tablero_game
    mov cx, tablero_size
    mov al, 'O'
llenar_tablero:
    mov [si], al
    inc si
    loop llenar_tablero
    pop si
    pop cx

    ;Limpiar tablero visible (tablero)
    push cx
    push si
    lea si, tablero
    mov cx, 221; Tamaño fijo del buffer
    mov al, 0
limpiar_tablero:
    mov [si], al
    inc si
    loop limpiar_tablero
    pop si
    pop cx
    ret
reiniciar_juego ENDP

end main