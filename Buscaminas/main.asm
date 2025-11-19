.model small
.stack
include input.asm
include display.asm
include utils.asm
include logic.asm

.data

.code

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
    
end main
