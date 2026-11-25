;==============================================================================
; EJERCICIO    : Comparar cadenas en memoria (iguales o diferentes)
; ARCHIVO      : 01_comparar_cadenas_memoria.asm
; ENUNCIADO    : Comparar pares de cadenas almacenadas en el segmento de datos
;                e indicar si son iguales o diferentes, considerando primero
;                sus longitudes antes de comparar caracter por caracter.
; SOLUCION     :
;   1) Para cada par de cadenas (SI y DI), calcula ambas longitudes con
;      LONGITUD_CADENA y las muestra.
;   2) Si las longitudes son distintas, concluye directamente que son
;      diferentes.
;   3) Si coinciden, compara byte a byte (DS:[SI] vs DS:[DI]) hasta verificar
;      si todos los caracteres son iguales o si alguno difiere.
; REGISTROS    : SI (cadena 1), DI (cadena 2), AX (longitud / resultado),
;                BX (longitud 1), CX (contador de caracteres).
; VARIABLES    : Cadenas de prueba CAD1..CAD6 en DATOS.
; UTILS RELACIONADOS:
;   - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;   - utils/08_Comparacion_Cadenas/longitud_cadena.asm
;   - utils/08_Comparacion_Cadenas/comparar_cadenas_iguales.asm
; EJEMPLO DE ENTRADA/SALIDA:
;   === COMPARAR CADENAS EN MEMORIA ===
;   Par 1: "emu8086" (len 7) vs "emu8086" (len 7) -> IGUALES
;   Par 2: "arquitectura" (len 12) vs "arquitecto" (len 10) -> DIFERENTES
;   Par 3: "registro" (len 8) vs "registros" (len 9) -> DIFERENTES
;   Par 4: "CPU" (len 3) vs "GPU" (len 3) -> DIFERENTES
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

IMPRIMIR_NUMERO MACRO val                   ; inicio de la macro, recibe val
    LOCAL IN_DIVIDIR, IN_MOSTRAR            ; etiquetas unicas por cada uso
    PUSH AX                                 ; guarda AX (dividendo/servicio)
    PUSH BX                                 ; guarda BX (divisor 10)
    PUSH CX                                 ; guarda CX (contador de cifras)
    PUSH DX                                 ; guarda DX (residuo/caracter)
    MOV AX, val                             ; AX = numero a mostrar
    MOV BX, 10                              ; BX = 10, base decimal
    XOR CX, CX                              ; CX = 0 cifras apiladas
IN_DIVIDIR:                                 ; ciclo que separa las cifras
    XOR DX, DX                              ; DX = 0, el dividendo es DX:AX
    DIV BX                                  ; AX = cociente, DX = cifra (0-9)
    PUSH DX                                 ; apila la cifra para invertirla
    INC CX                                  ; cuenta una cifra mas
    CMP AX, 0                               ; queda cociente por dividir?
    JNE IN_DIVIDIR                          ; si AX<>0 sigue separando
IN_MOSTRAR:                                 ; ciclo que muestra las cifras
    POP DX                                  ; saca la cifra mas significativa
    ADD DL, '0'                             ; convierte valor 0-9 a ASCII
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    INT 21h                                 ; muestra la cifra
    LOOP IN_MOSTRAR                         ; CX-1 y repite si CX<>0
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
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
    CAD1A    DB 'emu8086$'                  ; par 1A
    CAD1B    DB 'emu8086$'                  ; par 1B (iguales)
    CAD2A    DB 'arquitectura$'             ; par 2A
    CAD2B    DB 'arquitecto$'               ; par 2B (distinta longitud)
    CAD3A    DB 'registro$'                 ; par 3A
    CAD3B    DB 'registros$'                ; par 3B (prefijo, distinta long)
    CAD4A    DB 'CPU$'                      ; par 4A
    CAD4B    DB 'GPU$'                      ; par 4B (misma long, difieren)
    MSG_TIT  DB '=== COMPARAR CADENAS EN MEMORIA ===$' ; titulo
    MSG_PAR  DB 'Par $'                     ; prefijo numero de par
    MSG_P2   DB ': "$'                      ; abre comilla
    MSG_LEN  DB '" (len $'                  ; longitud
    MSG_VS   DB ') vs "$'                   ; separador
    MSG_RES  DB ') -> $'                    ; flecha resultado
    MSG_IG   DB 'IGUALES$'                  ; iguales
    MSG_DIF  DB 'DIFERENTES$'               ; diferentes
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV BX, 1                               ; numero de par = 1
    MOV SI, OFFSET CAD1A                    ; par 1
    MOV DI, OFFSET CAD1B                    ; segunda cadena
    CALL PROBAR_PAR                         ; evalua y muestra

    MOV BX, 2                               ; numero de par = 2
    MOV SI, OFFSET CAD2A                    ; par 2
    MOV DI, OFFSET CAD2B                    ; segunda cadena
    CALL PROBAR_PAR                         ; evalua y muestra

    MOV BX, 3                               ; numero de par = 3
    MOV SI, OFFSET CAD3A                    ; par 3
    MOV DI, OFFSET CAD3B                    ; segunda cadena
    CALL PROBAR_PAR                         ; evalua y muestra

    MOV BX, 4                               ; numero de par = 4
    MOV SI, OFFSET CAD4A                    ; par 4
    MOV DI, OFFSET CAD4B                    ; segunda cadena
    CALL PROBAR_PAR                         ; evalua y muestra

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO PROBAR_PAR: muestra el par, sus longitudes y si son iguales
;------------------------------------------------------------------------------
PROBAR_PAR PROC                             ; inicio auxiliar
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX

    IMPRIMIR_CADENA MSG_PAR                 ; "Par "
    IMPRIMIR_NUMERO BX                      ; numero de par
    IMPRIMIR_CADENA MSG_P2                  ; ': "'
    MOV DX, SI                              ; imprime cadena 1
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; muestra
    IMPRIMIR_CADENA MSG_LEN                 ; '" (len '
    CALL LONGITUD_CADENA                    ; AX = longitud 1
    IMPRIMIR_NUMERO AX                      ; muestra longitud 1
    IMPRIMIR_CADENA MSG_VS                  ; ') vs "'
    MOV DX, DI                              ; imprime cadena 2
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; muestra
    IMPRIMIR_CADENA MSG_LEN                 ; '" (len '
    PUSH SI                                 ; guarda SI
    MOV SI, DI                              ; mide cadena 2
    CALL LONGITUD_CADENA                    ; AX = longitud 2
    POP SI                                  ; recupera SI
    IMPRIMIR_NUMERO AX                      ; muestra longitud 2
    IMPRIMIR_CADENA MSG_RES                 ; ') -> '

    CALL COMPARAR_CADENAS                   ; AL = 1 si iguales, 0 si no
    CMP AL, 1                               ; iguales?
    JNE PP_DIF                              ; no
    IMPRIMIR_CADENA MSG_IG                  ; "IGUALES"
    JMP PP_FIN                              ; sale
PP_DIF:                                     ; diferentes
    IMPRIMIR_CADENA MSG_DIF                 ; "DIFERENTES"
PP_FIN:                                     ; cierre
    SALTO_LINEA                             ; nueva linea
    POP DX                                  ; restaura DX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
PROBAR_PAR ENDP                             ; fin auxiliar

;------------------------------------------------------------------------------
; PROCEDIMIENTO LONGITUD_CADENA
;------------------------------------------------------------------------------
LONGITUD_CADENA PROC                        ; inicio del procedimiento
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; contador = 0
LC_CICLO:                                   ; recorre hasta '$'
    CMP BYTE PTR [SI], '$'                  ; es '$'?
    JE LC_FIN                               ; si: termina
    INC AX                                  ; suma 1
    INC SI                                  ; siguiente caracter
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
    JNE CC_DIF                              ; distintas: diferentes
    MOV CX, BX                              ; CX = cantidad a comparar
    CMP CX, 0                               ; vacias?
    JE CC_IGUAL                             ; si: iguales
CC_CICLO:                                   ; compara byte a byte
    MOV AL, [SI]                            ; byte de cad1
    CMP AL, [DI]                            ; compara con byte de cad2
    JNE CC_DIF                              ; distinto: diferentes
    INC SI                                  ; avanza cad1
    INC DI                                  ; avanza cad2
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
