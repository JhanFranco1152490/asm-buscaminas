; .model small
; .stack 100h
; .code


; print_pixel macro x, y, color
;     print_line x, y, 1, color
; endm

; ; Macro: print_line
; ; Draws a horizontal line of pixels on the screen.
; ; Parameters:
; ;   x     - Starting X coordinate
; ;   y     - Y coordinate
; ;   len   - Length of the line (number of pixels)
; ;   color - Color attribute for the pixels
; print_line macro x, y, len, color
;     LOCAL row_loop, end_m
;     mov bx, len
;     cmp bx, 0
;     jle end_m

;     add bx, x
;     cmp bx, 320
;     jnle end_m
;     mov bx, 320
;     sub bx, x
;     continue_m:
;     mov cx, x
;     mov dx, y
;     mov al, color
;     mov ah, 0Ch
;     row_loop:
;         int 10h
;         inc cx
;         cmp cx, bx 
;         jle row_loop
;     end_m:
; endm


; print_rectangle macro x, y, wid, height, color
;     LOCAL rect_loop, end_rect
;     mov si, height
;     cmp si, 0
;     jle end_rect

;     rect_loop:
;         print_line x, y, wid, color
;         inc y
;         dec si
;         jnz rect_loop
;     end_rect:
; endm
; mov ax, 13h       ; modo gráfico VGA 320x200 256 colores
; int 10h

; mov ax, 0A000h
; mov es, ax

; mov cx, 320*10     ; 10 filas de puntos
; mov di, 0
; mov al, 12         ; color (rojo claro)

; dibujar:
;     stosb
;     loop dibujar

; ; Esperar una tecla para salir
; mov ah, 00h
; int 16h

; ; Regresar a modo texto
; mov ah, 00h
; mov al, 03h
; int 10h

; mov ah, 4Ch
; int 21h
; end