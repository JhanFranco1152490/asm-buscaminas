.model small
.stack 100h
.code

mov ax, 13h       ; modo gráfico VGA 320x200 256 colores
int 10h

mov ax, 0A000h
mov es, ax

mov cx, 320*10     ; 10 filas de puntos
mov di, 0
mov al, 12         ; color (rojo claro)

dibujar:
    stosb
    loop dibujar

; Esperar una tecla para salir
mov ah, 00h
int 16h

; Regresar a modo texto
mov ah, 00h
mov al, 03h
int 10h

mov ah, 4Ch
int 21h
end