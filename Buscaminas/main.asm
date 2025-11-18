;#include "display.asm"
;#include "input.asm"
;#include "logic.asm"
;#include "include.asm"

.model small
.stack
.data

    ; Mensajes de la aplicacion
    msg_title_buscaminas        db  0C9h,30 dup(0CDh),0BBh,0Dh,0Ah
                                db  0BAh,'        BUSCAMINAS ASM        ',0BAh,0Dh,0Ah
                                db  0BAh,30 dup(0CDh),0BAh,0Dh,0Ah,'$'
    msg_start_interface         db  0BAh,'   Presiona [S] para jugar    ',0BAh,0Dh,0Ah
                                db  0BAh,'   Presiona [X] para salir    ',0BAh,0Dh,0Ah
                                db  0C8h,30 dup(0CDh),0BCh,0Dh,0Ah,'$'
    msg_enter_rows              db 'Ingresa las Filas del Tablero(1-9): $'
    msg_enter_colums            db 'Ingresa las Columnas del Tablero(1-9): $'
    msg_enter_bombs             db 'Ingresa Bombas del Tablero (Maximo $'
    msg_enter_bombs2            db '): $'
    msg_invalid_entry           db 'Dato Invalido',0Dh,0Ah,'$'
    ;Interfaz Bucle Principal
    msg_interface_buscaminas1   db 0BAh,'  Bombas: $'
    msg_interface_buscaminas2   db '                  ',0BAh,0Dh,0Ah
                                db 0BAh,'  Banderas colocadas: $'
    msg_interface_buscaminas3   db '      ',0BAh,0Dh,0Ah
                                db 0C8h,30 dup(0CDh),0BCh,0Dh,0Ah,'$'
    msg_enter_move_type         db 'Ingresa el tipo de movimiento([R]:Revelar,[F]:Flag,[X]:Salir): $'
    msg_enter_move_row          db 'Ingresa tu movimiento (fila): $'
    msg_enter_move_column       db 'Ingresa tu movimiento (columna): $'
    msg_invalid_move            db 'Movimiento invalido!',0Dh,0Ah,'$'
    msg_game_over_interface     db  0BAh,'          GAME OVER           ',0BAh,0Dh,0Ah
                                db  0BAh,'    Has perdido la partida    ',0BAh,0Dh,0Ah
                                db  0BAh,'                              ',0BAh,0Dh,0Ah
                                db  0BAh,'   Presiona [X] para volver   ',0BAh,0Dh,0Ah
                                db  0BAh,'         al menu.             ',0BAh,0Dh,0Ah
                                db  0C8h,30 dup(0CDh),0BCh,0Dh,0Ah,'$'
    msg_victory_interface       db  0BAh,'          |VICTORIA!          ',0BAh,0Dh,0Ah
                                db  0BAh,'    Has limpiado el tablero   ',0BAh,0Dh,0Ah
                                db  0BAh,'       exitosamente.          ',0BAh,0Dh,0Ah
                                db  0BAh,'                              ',0BAh,0Dh,0Ah
                                db  0BAh,'   Presiona [X] para volver   ',0BAh,0Dh,0Ah
                                db  0BAh,'         al menu.             ',0BAh,0Dh,0Ah
                                db  0C8h,30 dup(0CDh),0BCh,0Dh,0Ah,'$'
    msg_revealed_board          db  'Tablero del juego revelado:',0Dh,0Ah,'$'
    msg_new_line                db 0Dh,0Ah,'$'

    ;Tablero a imprimir
    display_board db 211 dup(0) ;211 = (1+(2*9columnas)+1(0A)+1(0D))*10filas+1($)

    ;Tablero interno
    hidden_board db 81 dup('O')
    
    ;Buffer para ints
    input_buffer db 10, 0, 10 dup(0) ;10 Espacios

    ;Variables
    board_rows          dw 0
    board_cols          dw 0
    board_size          dw 0
    total_bombs         dw 0
    revealed_cells      dw 0
    adjacent_bombs      dw 0
    placed_flags        dw 0
    move_type           dw 0
    row_index           dw 0
    col_index           dw 0
    cell_index          dw 0
    screen_index        dw 0
    temp_counter        dw 0
    ERROR_CODE          equ -1

.code

;MACROS

;Macro para limpiar la pantalla
limpiar_pantalla macro
    push ax
    mov ah, 00h
    mov al, 3h
    int 10h
    pop ax
endm

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

;Macro para leer un string
leer_string macro buffer
    push dx
    lea dx, buffer
    mov ah, 0Ah
    int 21h
    pop dx
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

;Macro para obtener un numero aleatorio
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
    mov al, dl ;Guarda el random en al
    jmp fin_random 
div_cero:
    mov ax, 0h
fin_random:
    pop dx
    pop cx
    pop bx
endm

;Macro para mezclar las posiciones de un arreglo
mezclar_arreglo macro arr, size
    LOCAL bucle_mezclar
    LOCAL fin_mezclar_arreglo
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; obtener tamaño
    mov ax, size
    mov cx, ax
    dec cx              ; comenzamos en tamaño-1

    ; si cx = 0 o negativo, no hacer nada
    cmp cx, 0
    jle fin_mezclar_arreglo

    lea si, arr
bucle_mezclar:
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
    jnz bucle_mezclar

fin_mezclar_arreglo:
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
inicio_juego:
    ;limpiar pantalla
    limpiar_pantalla
    ; Mostrar Interfaz Inicial
    print_msg msg_title_buscaminas
    print_msg msg_start_interface
    leer_char
    cmp ax, 'X'
    je terminar_programa
    cmp ax, 'x'
    je terminar_programa
    cmp ax, 'S'
    je pedir_datos
    cmp ax, 's'
    je pedir_datos
    jmp inicio_juego

pedir_datos:
    call leer_configuracion_tablero
    call generar_bombas_aleatorias
    call dibujar_tablero_inicial
    call bucle_principal

reiniciar_partida:
    print_msg msg_revealed_board
    call mostrar_tablero_final
    print_msg display_board
    leer_char
    cmp ax, 'X'
    je reinicio
    cmp ax, 'x'
    je reinicio
    jmp terminar_programa
reinicio:
    call reiniciar_estado_juego
    jmp inicio_juego

    ;Salir del programa
terminar_programa:
    call terminar_programa_proc
main ENDP
    
;PROCEDIMIENTOS

;Procedimiento para pedir datos del display_board
leer_configuracion_tablero PROC
entrada_filas:
    limpiar_pantalla
    print_msg msg_enter_rows
    call leer_dimension
    esperar_tecla
    cmp ax, ERROR_CODE
    je entrada_filas
    mov board_rows,ax

entrada_columnas:
    limpiar_pantalla
    print_msg msg_enter_colums
    call leer_dimension
    esperar_tecla
    mov board_cols,ax
    cmp ax, ERROR_CODE
    je entrada_columnas

    ;Calcular tamaño del display_board
    mov ax, board_rows
    mul board_cols
    mov board_size, ax  

entrada_bombas:
    limpiar_pantalla
    print_msg msg_enter_bombs
    mov ax, board_size
    dec ax
    print_number ax
    print_msg msg_enter_bombs2
    ;Leer numero de total_bombs
    leer_string input_buffer
    string_to_int input_buffer
    cmp ax,0
    jle error_cantidad_bombas
    cmp ax, board_size
    jge error_cantidad_bombas
    mov total_bombs, ax
    ret
error_cantidad_bombas:
    print_msg msg_new_line    
    print_msg msg_invalid_entry
    esperar_tecla
    jmp entrada_bombas
leer_configuracion_tablero ENDP

;Procedimiento para pedir la dimension de un lado del display_board
leer_dimension PROC
    leer_char
    cmp al, '0'
    jle error_dimension_invalida 
    mov ah, '0'
    add ah, 10d
    cmp al, ah
    jge error_dimension_invalida
    xor ah,ah
    sub al, '0' ;devuelve en al el valor
    ret
error_dimension_invalida:
    print_msg msg_new_line
    print_msg msg_invalid_entry
    mov ax, ERROR_CODE
    ret
leer_dimension ENDP

;Procedimiento para crear el display_board de juego aleatoriamente
generar_bombas_aleatorias PROC
    push ax
    push bx
    push cx
    push si
    push di

    lea si, hidden_board

    ; Cargar tamaño del display_board en CX
    mov ax, board_size
    mov cx, ax

    ; Colocar X en las primeras 'total_bombs' posiciones
    mov cx, total_bombs
    xor bx, bx                 

bucle_colocar_bombas:
    mov byte ptr [si + bx], 'X'
    inc bx
    dec cx
    jnz bucle_colocar_bombas

fin_crear_bombas:
    mov bx, ax
    mov byte ptr [si + bx], '$'

    ; Llamar a mezclar_arreglo
    mezclar_arreglo hidden_board, board_size
    print_msg msg_new_line

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
generar_bombas_aleatorias ENDP

;Procedimiento para crear el display_board de la interfaz
dibujar_tablero_inicial PROC
    push cx
    push dx

    ;Calcular cuantos ciclos para las letras 
    mov ax, 2d
    mul board_cols
    dec ax
    mov cx, ax
    lea si, display_board
    mov bx, 0d
    mov BYTE PTR [si+bx],' '
    inc bx
    mov BYTE PTR [si+bx],' '
    inc bx

bucle_columnas_titulo:
    test bx,1 ; Saber si es posicion par o impar
    jz escribir_letra_columna
    jmp escribir_espacio_columna 
escribir_letra_columna:
    mov ax, bx
    push bx
    mov bx, 2d
    div bx
    pop bx
    sub ax, 1
    add ax, 'A'
    mov BYTE PTR [si+bx], al
    jmp fin_dibujo_columnas

escribir_espacio_columna:
    mov BYTE PTR [si+bx], ' '

fin_dibujo_columnas:
    inc bx
    loop bucle_columnas_titulo

    ;Colocar final de la linea
    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx

    ;Repetir el ciclo el numero de filas
    mov cx, board_rows
    mov temp_counter, 1d ;Numero de Fila

bucle_filas_tablero:
    mov ax, temp_counter
    add ax, '0'  
    mov BYTE PTR [si+bx], al
    inc bx
    inc temp_counter
    mov dx, board_cols

bucle_celdas_fila:
    ;Alternar un espacio con un simbolo
    mov BYTE PTR [si+bx], ' '
    inc bx
    mov al, '-'  
    mov BYTE PTR [si+bx], al
    inc bx
    dec dx
    jnz bucle_celdas_fila

    ;Colocar el final de la linea
    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx
    loop bucle_filas_tablero

    ;Colocar $ al final del tablero
    mov BYTE PTR [si+bx], '$'
    pop dx
    pop cx
    ret
dibujar_tablero_inicial ENDP

;Procedimiento para empezar un juego
bucle_principal PROC
    mov revealed_cells, 0

inicio_partida:
    ;Imprimir Interfaz
    limpiar_pantalla
    print_msg msg_title_buscaminas
    print_msg msg_interface_buscaminas1
    print_number total_bombs
    cmp total_bombs, 10
    jge imprimir_banderas
    print_char ' '

imprimir_banderas:
    print_msg msg_interface_buscaminas2
    print_number placed_flags
    cmp placed_flags, 10
    jge imprimir_tablero
    print_char ' '

imprimir_tablero:
    print_msg msg_interface_buscaminas3
    print_msg display_board
    print_msg msg_new_line

    ;Leer tipo movimiento(Letra)
    print_msg msg_enter_move_type
    leer_char
    mov move_type, ax
    print_msg msg_new_line
    cmp move_type,'R'
    je entrada_columna
    cmp move_type,'r'
    je entrada_columna
    cmp move_type,'F'
    je entrada_columna
    cmp move_type,'f'
    je entrada_columna
    cmp move_type,'X'
    je terminar_juego
    cmp move_type,'x'
    je terminar_juego
    jmp continuar_partida

terminar_juego:
    call terminar_programa_proc

    ; Leer columna (letra)
entrada_columna:
    print_msg msg_enter_move_column
    call convertir_columna
    cmp ax, ERROR_CODE
    je continuar_partida
    mov col_index, ax
    print_msg msg_new_line

    ; Leer fila (número)
    print_msg msg_enter_move_row
    call convertir_fila
    cmp ax, ERROR_CODE
    je continuar_partida
    mov row_index, ax
    print_msg msg_new_line

    ;Revisar el tipo de movimiento
    cmp move_type,'F'
    je accion_bandera
    cmp move_type,'f'
    je accion_bandera

    ;REVELAR
accion_revelar:
    call procesar_revelar
    
    ;Comparaciones para saber si se perdio, victoria o seguir jugando
    ;Verificar si se perdio
    cmp al, 'X'
    je derrota
    inc revealed_cells
    ;Verificar si se gano
    mov ax, board_size
    sub ax, total_bombs
    cmp revealed_cells, ax
    je victoria
    jmp continuar_partida
    
    ;FLAG
accion_bandera:
    call procesar_bandera
    esperar_tecla

    ;Siguiente Ronda
continuar_partida:
    jmp inicio_partida

victoria:
    limpiar_pantalla
    print_msg msg_title_buscaminas
    print_msg msg_victory_interface
    ret

derrota:
    limpiar_pantalla
    print_msg msg_title_buscaminas
    print_msg msg_game_over_interface
    ret
bucle_principal ENDP

;Procedimiento para realizar el movimiento revelar
procesar_revelar PROC
    ; Determinar casilla
    call obtener_casilla_oculta     ; al = valor casilla
    esperar_tecla
    ;Revisar si se perdio y salir
    cmp al, 'X'
    jne verificar_celda_repetida
    ret

    ;Si se realiza un movimiento ya hecho no se cuenta
verificar_celda_repetida:
    call calcular_indice_pantalla
    lea si, display_board
    add si, screen_index
    mov al, [si]
    cmp al, '-'
    je calcular_bombas_adyacentes
    cmp al, '?'
    je calcular_bombas_adyacentes
    mov al, '-'
    ret 

    ;Calcular numero de total_bombs adyacentes a la casilla actual
calcular_bombas_adyacentes:
    call contar_bombas_adyacentes
    mov bx,adjacent_bombs
    add bl,'0'
    call actualizar_tablero_visible; Revela en display_board
    ret
procesar_revelar ENDP

;Procedimiento para realizar el movimiento flag
procesar_bandera PROC
    call calcular_indice_pantalla
    lea si, display_board
    add si, screen_index
    mov bl, [si]
    cmp bl, '?' ;Si esta con bandera se quita
    je unflag
    cmp bl, '-' ;Si tiene numero o otra cosa es movimiento invalido
    jne error_flag
    mov BYTE PTR [si], '?' 
    inc placed_flags 
    ret

unflag:
    mov BYTE PTR [si], '-'
    dec placed_flags
    ret

error_flag:
    print_msg msg_invalid_move
    ret
procesar_bandera ENDP

;Procedimiento para convertir a col_index una letra
convertir_columna PROC
    leer_char
    cmp ax,'a'
    jl validar_columna
    cmp ax,'z'
    jg validar_columna
    sub ax,32 ;Convertir a Mayuscula

validar_columna:
    cmp ax, 'A'
    jl error_columna_invalida
    mov bx, board_cols
    dec bx
    add bx, 'A'
    cmp ax, bx
    jg error_columna_invalida
    jmp fin_conversion_columna 
error_columna_invalida:
    call mostrar_error_movimiento
    mov ax, ERROR_CODE
    ret
fin_conversion_columna:
    sub ax, 'A' ;se guarda en ax
fin_letra:
    ret
convertir_columna ENDP

;Procedimiento para convertir a row_index un char
convertir_fila PROC
    leer_char
    cmp ax, '1'
    jl error_fila_invalida
    mov bx, board_rows
    add bx, '0'
    cmp ax, bx
    jg error_fila_invalida
    sub ax, '1'
    ret
error_fila_invalida:
    call mostrar_error_movimiento
    mov ax, ERROR_CODE
    ret
convertir_fila ENDP

;Procedimiento para mensajes de movimiento invalido
mostrar_error_movimiento PROC
    print_msg msg_new_line
    print_msg msg_invalid_move
    esperar_tecla
    ret
mostrar_error_movimiento ENDP

;Procedimiento para determinar que hay en la casilla
obtener_casilla_oculta PROC
    lea si, hidden_board
    call calcular_indice_celda
    mov bx,cell_index
    mov al,[si+bx]
    ret
obtener_casilla_oculta ENDP

;Procedimiento para calcular la posicion actual dentro del array
calcular_indice_celda PROC
    mov ax, board_cols
    mul row_index
    add ax, col_index
    mov cell_index, ax ;Resultado guardado en cell_index
    ret
calcular_indice_celda ENDP

;Procedimiento para calcular la posicion actual dentro del display_board
calcular_indice_pantalla PROC
    mov ax, 2d
    mul board_cols
    add ax, 3d
    mov screen_index, ax
    add screen_index, 2d ;Primer Numero para empezar en la coordenada 0,0

    mul row_index
    add screen_index, ax
    mov ax, 2d
    mul col_index
    add screen_index, ax ;Resultado guardado en screen_index
    ret
calcular_indice_pantalla ENDP

;Procedimiento para calcular el numero de total_bombs cercanas
contar_bombas_adyacentes PROC
    push bx
    push cx
    push dx
    mov adjacent_bombs, 0
    lea si, hidden_board
    mov bx, cell_index
    mov cx, board_cols
    dec cx

fila_superior:
    ;Mirar si el centro esta en la primera fila
    mov ax, board_cols
    cmp cell_index, ax
    jl fila_central

casilla_superior_izquierda:
    sub bx, board_cols
    dec bx
    cmp col_index, 0 ; Si la columna es 0 no tiene izquierda
    je casilla_superior_centro
    call verificar_bomba

casilla_superior_centro:
    inc bx
    call verificar_bomba

casilla_superior_derecha:
    inc bx
    cmp col_index, cx ; Si la columna es 0 no tiene izquierda
    je fila_central
    call verificar_bomba

fila_central:
casilla_central_izquierda:
    mov bx, cell_index
    dec bx
    cmp col_index, 0
    je casilla_central_derecha
    call verificar_bomba

casilla_central_derecha:
    add bx, 2d
    cmp col_index, cx
    je fila_inferior
    call verificar_bomba

fila_inferior:
    ;Mirar si el centro esta en la ultima fila
    mov ax, board_size
    sub ax, board_cols
    cmp cell_index, ax
    jge fin_contar_bombas

casilla_inferior_izquierda:
    add bx, board_cols
    sub bx, 2d
    cmp col_index, 0
    je casilla_inferior_centro
    call verificar_bomba

casilla_inferior_centro:
    inc bx
    call verificar_bomba

casilla_inferior_derecha:
    inc bx
    cmp col_index, cx
    je fin_contar_bombas
    call verificar_bomba

fin_contar_bombas:
    pop dx
    pop cx
    pop bx
    ret
contar_bombas_adyacentes ENDP

;Procedimiento para verificar si la posicion vista es una bomba
verificar_bomba PROC
    ;Verificar si se pasa de los limites
    cmp bx, 0
    jl sin_bomba
    cmp bx, board_size
    jge sin_bomba
    ;Verificar si es una bomba
    mov al, [si+bx]
    cmp al, 'X'
    jne sin_bomba
    inc adjacent_bombs

sin_bomba:
    ret
verificar_bomba ENDP

;Procedimiento para revelar la casilla
actualizar_tablero_visible PROC
    lea si, display_board
    add si, screen_index
    mov BYTE PTR [si], bl
    ret
actualizar_tablero_visible ENDP

;Procedimiento para mostrar todo el display_board revelado
mostrar_tablero_final PROC
    push cx
    push dx
    mov ax, 2d
    mul board_cols
    sub ax, 1d
    mov cx, ax
    lea si, display_board
    mov bx, 0d
    mov BYTE PTR [si+bx],' '
    inc bx
    mov BYTE PTR [si+bx],' '
    inc bx

bucle_columnas_final:
    test bx,1
    jz escribir_letra_final
    jmp escribir_espacio_final 

escribir_letra_final:
    mov ax, bx
    push bx
    mov bx, 2d
    div bx
    pop bx
    sub ax, 1
    add ax, 'A'
    mov BYTE PTR [si+bx], al
    jmp fin_columnas_final

escribir_espacio_final:
    mov BYTE PTR [si+bx], ' '

fin_columnas_final:
    inc bx
    loop bucle_columnas_final

    ;Colocar final de linea
    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx

    ;Repetir por cada fila
    mov cx, board_rows
    mov revealed_cells, 1d
    mov temp_counter, 0d

bucle_filas_final:
    mov ax, revealed_cells
    add ax, '0'  
    mov BYTE PTR [si+bx], al
    inc bx
    inc revealed_cells
    mov dx, board_cols

bucle_celdas_final:
    mov BYTE PTR [si+bx], ' '
    inc bx
    push bx
    push si
    lea si, hidden_board
    mov bx, temp_counter
    mov al, [si+bx]
    inc temp_counter
    pop si
    pop bx
    mov BYTE PTR [si+bx], al
    inc bx
    dec dx
    jnz bucle_celdas_final

    ;Colocar final de linea
    mov BYTE PTR [si+bx], 0Dh
    inc bx
    mov BYTE PTR [si+bx], 0Ah
    inc bx
    loop bucle_filas_final

    ;Colocar $ al final del tablero
    mov BYTE PTR [si+bx], '$'
    pop dx
    pop cx
    ret
mostrar_tablero_final ENDP

;Procedimiento para reiniciar todas las variables del juego
reiniciar_estado_juego PROC
    ;Reinicia contadores y variables
    mov revealed_cells, 0
    mov total_bombs, 0
    mov adjacent_bombs, 0
    mov placed_flags, 0
    mov row_index, 0
    mov col_index, 0
    mov cell_index, 0
    mov screen_index, 0
    mov temp_counter, 0

    ;Limpiar display_board interno (hidden_board)
    push cx
    push si
    lea si, hidden_board
    mov cx, board_size
    mov al, 'O'

bucle_rellenar_interno:
    mov [si], al
    inc si
    loop bucle_rellenar_interno
    pop si
    pop cx

    ;Limpiar display_board visible (display_board)
    push cx
    push si
    lea si, display_board
    mov cx, 211; Tamaño fijo del buffer
    mov al, 0
    
bucle_limpiar_visible:
    mov [si], al
    inc si
    loop bucle_limpiar_visible
    pop si
    pop cx
    ret
reiniciar_estado_juego ENDP

terminar_programa_proc PROC
    mov ah, 4Ch
    int 21h
terminar_programa_proc ENDP

end main
