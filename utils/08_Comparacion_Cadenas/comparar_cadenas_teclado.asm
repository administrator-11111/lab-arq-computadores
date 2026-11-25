;==============================================================================
; ARCHIVO      : comparar_cadenas_teclado.asm
; TIPO         : ALGORITMO (+ programa de demostracion)
; DESCRIPCION  : Lee dos cadenas por teclado mediante INT 21h AH=0Ah, coloca
;                el terminador '$' al final de cada una y las compara para
;                determinar si son iguales o diferentes.
; FUNCIONAMIENTO:
;   1) LEER_CADENA_TECLADO recibe DX = direccion de un buffer de AH=0Ah con
;      estructura [max][leidos][texto...]. Invoca INT 21h AH=0Ah, toma la
;      cantidad leida en [BX+1] y escribe '$' en [BX+2+leidos] reemplazando
;      el retorno de carro 0Dh.
;   2) Con ambas cadenas ya terminadas en '$', llama a COMPARAR_CADENAS
;      pasando SI = texto 1 y DI = texto 2.
; REGISTROS    :
;   LEER_CADENA_TECLADO -> Entrada: DX = offset del inicio del buffer AH=0Ah.
;                          Salida : AX = cantidad de caracteres leidos.
;                          Conserva BX, CX, DX, SI, DI.
;   COMPARAR_CADENAS    -> Entrada: SI = cad1 ('$'), DI = cad2 ('$').
;                          Salida : AL = 1 si iguales, 0 si diferentes.
; VARIABLES    : Dos buffers de teclado (BUF1_MAX..BUF1_TXT, BUF2_MAX..BUF2_TXT).
; DEPENDENCIAS : Macros de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y LONGITUD_CADENA / COMPARAR_CADENAS.
; COMO INTEGRAR: Declarar un buffer [max][0][max+1 DUP('$')] en DATOS y copiar
;                LEER_CADENA_TECLADO junto con COMPARAR_CADENAS en CODIGO.
; EJEMPLO      :
;   === COMPARAR DOS CADENAS POR TECLADO ===
;   Ingrese cadena 1: hola 8086
;   Ingrese cadena 2: hola 8086
;   Resultado: las cadenas son IGUALES.
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
    ; Buffer 1 para INT 21h AH=0Ah (hasta 40 caracteres + 0Dh)
    BUF1_MAX DB 41                          ; capacidad maxima (incluye 0Dh)
    BUF1_LEN DB 0                           ; longitud real leida por DOS
    BUF1_TXT DB 42 DUP('$')                 ; texto leido + terminador '$'
    ; Buffer 2 para INT 21h AH=0Ah (hasta 40 caracteres + 0Dh)
    BUF2_MAX DB 41                          ; capacidad maxima (incluye 0Dh)
    BUF2_LEN DB 0                           ; longitud real leida por DOS
    BUF2_TXT DB 42 DUP('$')                 ; texto leido + terminador '$'

    MSG_TIT  DB '=== COMPARAR DOS CADENAS POR TECLADO ===$' ; titulo
    MSG_P1   DB 'Ingrese cadena 1: $'       ; solicitud 1
    MSG_P2   DB 'Ingrese cadena 2: $'       ; solicitud 2
    MSG_IG   DB 'Resultado: las cadenas son IGUALES.$'      ; resultado igual
    MSG_DIF  DB 'Resultado: las cadenas son DIFERENTES.$'   ; resultado dif.
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P1                  ; pide cadena 1
    LEA DX, BUF1_MAX                        ; DX = inicio buffer 1
    CALL LEER_CADENA_TECLADO                ; lee y termina en '$'
    SALTO_LINEA                             ; baja de linea

    IMPRIMIR_CADENA MSG_P2                  ; pide cadena 2
    LEA DX, BUF2_MAX                        ; DX = inicio buffer 2
    CALL LEER_CADENA_TECLADO                ; lee y termina en '$'
    SALTO_LINEA                             ; baja de linea

    MOV SI, OFFSET BUF1_TXT                 ; SI = texto de cadena 1
    MOV DI, OFFSET BUF2_TXT                 ; DI = texto de cadena 2
    CALL COMPARAR_CADENAS                   ; AL = 1 si iguales, 0 si no
    CMP AL, 1                               ; fueron iguales?
    JNE SON_DIF                             ; no
    IMPRIMIR_CADENA MSG_IG                  ; si: informa iguales
    JMP FIN_DEMO                            ; salta al fin
SON_DIF:                                    ; rama diferentes
    IMPRIMIR_CADENA MSG_DIF                 ; informa diferentes
FIN_DEMO:                                   ; cierre
    SALTO_LINEA                             ; nueva linea
    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LEER_CADENA_TECLADO ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LEER_CADENA_TECLADO
;   Entrada : DX = offset del buffer AH=0Ah ([max][len][texto...]).
;   Salida  : AX = cantidad de caracteres leidos; coloca '$' al final del texto.
;   Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
LEER_CADENA_TECLADO PROC                    ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH SI                                 ; guarda SI
    MOV AH, 0Ah                             ; servicio 0Ah: lectura con buffer
    INT 21h                                 ; DOS lee la linea hasta Enter
    MOV BX, DX                              ; BX = base del buffer
    MOV AL, [BX + 1]                        ; AL = cantidad real leida
    MOV AH, 0                               ; AX = longitud en 16 bits
    MOV SI, BX                              ; SI = base del buffer
    ADD SI, 2                               ; SI apunta al inicio del texto
    ADD SI, AX                              ; SI apunta al 0Dh final
    MOV BYTE PTR [SI], '$'                  ; reemplaza 0Dh por '$'
    POP SI                                  ; restaura SI
    POP BX                                  ; restaura BX
    RET                                     ; vuelve con AX = longitud
LEER_CADENA_TECLADO ENDP                    ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LEER_CADENA_TECLADO ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LONGITUD_CADENA
;------------------------------------------------------------------------------
LONGITUD_CADENA PROC                        ; inicio del procedimiento
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; contador = 0
LC_CICLO:                                   ; recorre hasta '$'
    CMP BYTE PTR [SI], '$'                  ; fin de cadena?
    JE LC_FIN                               ; si
    INC AX                                  ; suma 1
    INC SI                                  ; siguiente byte
    JMP LC_CICLO                            ; repite
LC_FIN:                                     ; salida
    POP SI                                  ; restaura SI
    RET                                     ; vuelve con AX = longitud
LONGITUD_CADENA ENDP                        ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_CADENAS
;------------------------------------------------------------------------------
COMPARAR_CADENAS PROC                       ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI
    CALL LONGITUD_CADENA                    ; AX = longitud 1
    MOV BX, AX                              ; BX = longitud 1
    PUSH SI                                 ; guarda SI
    MOV SI, DI                              ; mide cadena 2
    CALL LONGITUD_CADENA                    ; AX = longitud 2
    POP SI                                  ; recupera SI
    CMP BX, AX                              ; longitudes iguales?
    JNE CC_DIF                              ; no: diferentes
    MOV CX, BX                              ; CX = cantidad a comparar
    CMP CX, 0                               ; vacias?
    JE CC_IGUAL                             ; si: iguales
CC_CICLO:                                   ; compara byte a byte
    MOV AL, [SI]                            ; byte de cadena 1
    CMP AL, [DI]                            ; compara con byte de cadena 2
    JNE CC_DIF                              ; distinto: diferentes
    INC SI                                  ; avanza SI
    INC DI                                  ; avanza DI
    LOOP CC_CICLO                           ; repite CX veces
CC_IGUAL:                                   ; iguales
    MOV AX, 1                               ; AL = 1
    JMP CC_FIN                              ; sale
CC_DIF:                                     ; diferentes
    MOV AX, 0                               ; AL = 0
CC_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
COMPARAR_CADENAS ENDP                       ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
