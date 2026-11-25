;==============================================================================
; EJERCICIO    : Comparar dos palabras (orden alfabetico, sin mayusculas)
; ARCHIVO      : 04_comparar_palabras.asm
; ENUNCIADO    : Leer dos palabras por teclado, compararlas caracter por
;                caracter ignorando mayusculas y minusculas, e informar si son
;                iguales o cual va primero en orden alfabetico.
; SOLUCION     :
;   1) Lee dos palabras con INT 21h AH=0Ah (LEER_CADENA_TECLADO).
;   2) Recorre ambas palabras en COMPARAR_PALABRAS convirtiendo cada letra
;      minuscula 'a'..'z' a mayuscula (restando 20h) mediante A_MAYUSCULA.
;   3) Al encontrar la primera diferencia (o el final '$' de una palabra),
;      determina si son iguales (0), si la primera va antes (1) o si la
;      segunda va antes (2), y muestra el orden alfabetico.
; REGISTROS    : SI/DI (palabras), AX (resultado 0/1/2), BX (caracteres
;                normalizados), DX (buffers y mensajes).
; VARIABLES    : BUF1_MAX..BUF1_TXT, BUF2_MAX..BUF2_TXT en DATOS.
; UTILS RELACIONADOS:
;   - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;   - utils/08_Comparacion_Cadenas/comparar_cadenas_teclado.asm
;   - utils/08_Comparacion_Cadenas/comparar_palabras.asm
; EJEMPLO DE ENTRADA/SALIDA:
;   === COMPARAR PALABRAS (ORDEN ALFABETICO) ===
;   Ingrese palabra 1: zorro
;   Ingrese palabra 2: Abeja
;   Orden alfabetico: "Abeja" va antes que "zorro".
;==============================================================================

;//// macros

IMPRIMIR_CADENA MACRO cad                   ; inicio de la macro, recibe cad
    PUSH AX                                 ; guarda AX porque se usara AH
    PUSH DX                                 ; guarda DX porque se usara DX
    LEA DX, cad                             ; DX = direccion (offset) de cad
    MOV AH, 09h                             ; servicio 09h: escribir cadena$
    INT 21h                                 ; DOS muestra hasta encontrar '$'
    POP DX                                  ; recupera DX original
    POP AX                                  ; recupera AX original
ENDM                                        ; fin de la macro

SALTO_LINEA MACRO                           ; macro sin parametros
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    MOV DL, 13                              ; 13 = retorno de carro (CR)
    INT 21h                                 ; cursor a la columna 0
    MOV DL, 10                              ; 10 = avance de linea (LF)
    INT 21h                                 ; cursor a la linea siguiente
    POP DX                                  ; restaura DX
    POP AX                                  ; restaura AX
ENDM                                        ; fin de la macro

FIN_PROGRAMA MACRO                          ; macro sin parametros
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; DOS finaliza el programa
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    BUF1_MAX DB 41                          ; capacidad maxima palabra 1
    BUF1_LEN DB 0                           ; longitud leida 1
    BUF1_TXT DB 42 DUP('$')                 ; palabra 1 terminada en '$'
    BUF2_MAX DB 41                          ; capacidad maxima palabra 2
    BUF2_LEN DB 0                           ; longitud leida 2
    BUF2_TXT DB 42 DUP('$')                 ; palabra 2 terminada en '$'

    MSG_TIT  DB '=== COMPARAR PALABRAS (ORDEN ALFABETICO) ===$' ; titulo
    MSG_P1   DB 'Ingrese palabra 1: $'      ; solicitud 1
    MSG_P2   DB 'Ingrese palabra 2: $'      ; solicitud 2
    MSG_IG   DB 'Resultado: las palabras son IGUALES (sin distinguir mayusculas).$' ; ig
    MSG_ORD1 DB 'Orden alfabetico: "$'      ; prefijo orden
    MSG_ORD2 DB '" va antes que "$'         ; medio orden
    MSG_ORD3 DB '".$'                       ; cierre orden
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P1                  ; pide palabra 1
    LEA DX, BUF1_MAX                        ; buffer 1
    CALL LEER_CADENA_TECLADO                ; lee palabra 1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P2                  ; pide palabra 2
    LEA DX, BUF2_MAX                        ; buffer 2
    CALL LEER_CADENA_TECLADO                ; lee palabra 2
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET BUF1_TXT                 ; SI = palabra 1
    MOV DI, OFFSET BUF2_TXT                 ; DI = palabra 2
    CALL COMPARAR_PALABRAS                  ; AL = 0 igual, 1 p1<p2, 2 p2<p1
    CMP AL, 1                               ; palabra 1 va primero?
    JE UNO_ANTES                            ; si
    CMP AL, 2                               ; palabra 2 va primero?
    JE DOS_ANTES                            ; si
    IMPRIMIR_CADENA MSG_IG                  ; iguales
    JMP FIN_EJ                              ; sale

UNO_ANTES:                                  ; palabra 1 < palabra 2
    IMPRIMIR_CADENA MSG_ORD1                ; 'Orden alfabetico: "'
    IMPRIMIR_CADENA BUF1_TXT                ; palabra 1
    IMPRIMIR_CADENA MSG_ORD2                ; '" va antes que "'
    IMPRIMIR_CADENA BUF2_TXT                ; palabra 2
    IMPRIMIR_CADENA MSG_ORD3                ; '".'
    JMP FIN_EJ                              ; sale

DOS_ANTES:                                  ; palabra 2 < palabra 1
    IMPRIMIR_CADENA MSG_ORD1                ; 'Orden alfabetico: "'
    IMPRIMIR_CADENA BUF2_TXT                ; palabra 2
    IMPRIMIR_CADENA MSG_ORD2                ; '" va antes que "'
    IMPRIMIR_CADENA BUF1_TXT                ; palabra 1
    IMPRIMIR_CADENA MSG_ORD3                ; '".'

FIN_EJ:                                     ; cierre
    SALTO_LINEA                             ; nueva linea
    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO LEER_CADENA_TECLADO
;------------------------------------------------------------------------------
LEER_CADENA_TECLADO PROC                    ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH SI                                 ; guarda SI
    MOV AH, 0Ah                             ; servicio 0Ah: lectura con buffer
    INT 21h                                 ; lee hasta Enter
    MOV BX, DX                              ; BX = inicio buffer
    MOV AL, [BX + 1]                        ; AL = longitud
    MOV AH, 0                               ; AX = longitud
    MOV SI, BX                              ; SI = base buffer
    ADD SI, 2                               ; salta cabecera
    ADD SI, AX                              ; apunta a 0Dh
    MOV BYTE PTR [SI], '$'                  ; coloca '$'
    POP SI                                  ; restaura SI
    POP BX                                  ; restaura BX
    RET                                     ; vuelve con AX = longitud
LEER_CADENA_TECLADO ENDP                    ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO A_MAYUSCULA
;------------------------------------------------------------------------------
A_MAYUSCULA PROC                            ; inicio del procedimiento
    CMP AL, 'a'                             ; menor que 'a'?
    JB AM_FIN                               ; no es minuscula
    CMP AL, 'z'                             ; mayor que 'z'?
    JA AM_FIN                               ; no es minuscula
    SUB AL, 20h                             ; convierte a mayuscula
AM_FIN:                                     ; salida
    RET                                     ; vuelve al llamador
A_MAYUSCULA ENDP                            ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_PALABRAS
;------------------------------------------------------------------------------
COMPARAR_PALABRAS PROC                      ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI
CPAL_CICLO:                                 ; compara caracter por caracter
    MOV AL, [SI]                            ; caracter de palabra 1
    MOV BL, [DI]                            ; caracter de palabra 2
    CMP AL, '$'                             ; termino palabra 1?
    JE CPAL_FIN1                            ; si
    CMP BL, '$'                             ; termino palabra 2?
    JE CPAL_DOS_ANTES                       ; si: palabra 2 va antes
    CALL A_MAYUSCULA                        ; normaliza c1
    MOV BH, AL                              ; BH = c1 mayuscula
    MOV AL, BL                              ; AL = c2
    CALL A_MAYUSCULA                        ; normaliza c2
    CMP BH, AL                              ; compara en mayusculas
    JB CPAL_UNO_ANTES                       ; c1 < c2
    JA CPAL_DOS_ANTES                       ; c1 > c2
    INC SI                                  ; avanza palabra 1
    INC DI                                  ; avanza palabra 2
    JMP CPAL_CICLO                          ; siguiente caracter
CPAL_FIN1:                                  ; palabra 1 termino
    CMP BL, '$'                             ; palabra 2 tambien?
    JE CPAL_IGUAL                           ; si: iguales
    JMP CPAL_UNO_ANTES                      ; no: palabra 1 es prefijo
CPAL_IGUAL:                                 ; iguales
    MOV AX, 0                               ; AL = 0
    JMP CPAL_FIN                            ; sale
CPAL_UNO_ANTES:                             ; palabra 1 va antes
    MOV AX, 1                               ; AL = 1
    JMP CPAL_FIN                            ; sale
CPAL_DOS_ANTES:                             ; palabra 2 va antes
    MOV AX, 2                               ; AL = 2
CPAL_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
COMPARAR_PALABRAS ENDP                      ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
