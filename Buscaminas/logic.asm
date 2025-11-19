.code

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