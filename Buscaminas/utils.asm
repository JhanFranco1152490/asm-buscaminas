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


