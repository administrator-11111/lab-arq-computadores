;==============================================================================
; ARCHIVO      : comparar_cadenas_numericas.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Compara dos cadenas que representan numeros enteros sin signo
;                ("123" vs "45", "00045" vs "45", etc.) de forma NUMERICA y
;                determina si el primero es mayor, menor o igual que el segundo.
; FUNCIONAMIENTO:
;   Por que NO sirve comparar como texto normal?
;     Como texto (orden ASCII), "45" > "123" porque el primer caracter '4'
;     (34h) es mayor que '1' (31h). Numericamenente, 123 > 45.
;   Algoritmo correcto (funciona incluso para numeros que superan 65535!):
;     1) Saltar todos los ceros a la izquierda ('0') en ambas cadenas.
;     2) Calcular la longitud restante de cada cadena (si una quedo en 0,
;        su valor es cero).
;     3) Si longitud1 > longitud2 -> numero 1 es MAYOR (AL = 1).
;        Si longitud1 < longitud2 -> numero 1 es MENOR (AL = 2).
;     4) Si tienen la misma longitud, comparar digito a digito de izquierda a
;        derecha (como los codigos ASCII '0'..'9' estan ordenados, el primer
;        digito mayor decide el numero mayor). Si todos coinciden -> IGUAL (0).
; REGISTROS    :
;   COMPARAR_NUMERICAS -> Entrada: SI = cadena num1 ('$'), DI = cadena num2 ('$').
;                         Salida : AL = 0 si iguales,
;                                  AL = 1 si num1 > num2,
;                                  AL = 2 si num1 < num2 (AH = 0).
;                         Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
; VARIABLES    : Cadenas numericas de ejemplo en DATOS.
; DEPENDENCIAS : Macros de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y LONGITUD_CADENA.
; COMO INTEGRAR: Copiar las macros, LONGITUD_CADENA y COMPARAR_NUMERICAS en
;                CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      :
;   === DEMO COMPARACION DE CADENAS NUMERICAS ===
;   123 vs 45 -> MAYOR (123 > 45)
;   00045 vs 45 -> IGUALES
;   999 vs 1000 -> MENOR (999 < 1000)
;   125 vs 123 -> MAYOR
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
    N1A      DB '123$'                      ; 123 (como texto < "45", num > 45)
    N1B      DB '45$'                       ; 45
    N2A      DB '00045$'                    ; ceros a la izquierda
    N2B      DB '45$'                       ; igual numericamente a 00045
    N3A      DB '999$'                      ; 3 cifras
    N3B      DB '1000$'                     ; 4 cifras
    N4A      DB '125$'                      ; misma longitud, mayor
    N4B      DB '123$'                      ; misma longitud, menor
    N5A      DB '000$'                      ; solo ceros
    N5B      DB '0$'                        ; cero
    MSG_TIT  DB '=== DEMO COMPARACION DE CADENAS NUMERICAS ===$' ; titulo
    MSG_VS   DB ' vs $'                     ; separador
    MSG_MAY  DB ' -> PRIMERO ES MAYOR$'     ; resultado 1
    MSG_MEN  DB ' -> PRIMERO ES MENOR$'     ; resultado 2
    MSG_IG   DB ' -> SON IGUALES$'          ; resultado 0
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET N1A                      ; 123 vs 45
    MOV DI, OFFSET N1B                      ; puntero 2
    CALL DEMO_NUM                           ; prueba

    MOV SI, OFFSET N2A                      ; 00045 vs 45
    MOV DI, OFFSET N2B                      ; puntero 2
    CALL DEMO_NUM                           ; prueba

    MOV SI, OFFSET N3A                      ; 999 vs 1000
    MOV DI, OFFSET N3B                      ; puntero 2
    CALL DEMO_NUM                           ; prueba

    MOV SI, OFFSET N4A                      ; 125 vs 123
    MOV DI, OFFSET N4B                      ; puntero 2
    CALL DEMO_NUM                           ; prueba

    MOV SI, OFFSET N5A                      ; 000 vs 0
    MOV DI, OFFSET N5B                      ; puntero 2
    CALL DEMO_NUM                           ; prueba

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO AUXILIAR DE DEMO: muestra SI vs DI y resultado numerico
;------------------------------------------------------------------------------
DEMO_NUM PROC                               ; inicio auxiliar
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV DX, SI                              ; muestra cadena 1
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; imprime
    IMPRIMIR_CADENA MSG_VS                  ; " vs "
    MOV DX, DI                              ; muestra cadena 2
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; imprime
    CALL COMPARAR_NUMERICAS                 ; AL = 0 igual, 1 mayor, 2 menor
    CMP AL, 1                               ; primero mayor?
    JE DN_MAY                               ; si
    CMP AL, 2                               ; primero menor?
    JE DN_MEN                               ; si
    IMPRIMIR_CADENA MSG_IG                  ; son iguales
    JMP DN_FIN                              ; sale
DN_MAY:                                     ; rama mayor
    IMPRIMIR_CADENA MSG_MAY                 ; imprime mayor
    JMP DN_FIN                              ; sale
DN_MEN:                                     ; rama menor
    IMPRIMIR_CADENA MSG_MEN                 ; imprime menor
DN_FIN:                                     ; fin
    SALTO_LINEA                             ; nueva linea
    POP DX                                  ; restaura DX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
DEMO_NUM ENDP                               ; fin auxiliar

;====== INICIO BLOQUE REUTILIZABLE: COMPARAR_NUMERICAS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LONGITUD_CADENA
;------------------------------------------------------------------------------
LONGITUD_CADENA PROC                        ; inicio del procedimiento
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; contador = 0
LC_CICLO:                                   ; recorre hasta '$'
    CMP BYTE PTR [SI], '$'                  ; llego al final?
    JE LC_FIN                               ; si
    INC AX                                  ; suma 1
    INC SI                                  ; siguiente byte
    JMP LC_CICLO                            ; repite
LC_FIN:                                     ; salida
    POP SI                                  ; restaura SI
    RET                                     ; vuelve con AX = longitud
LONGITUD_CADENA ENDP                        ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_NUMERICAS
;   Entrada : SI = cadena numerica 1 ('$'), DI = cadena numerica 2 ('$').
;   Salida  : AL = 0 si iguales, AL = 1 si num1 > num2, AL = 2 si num1 < num2.
;             (AH = 0). Conserva BX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
COMPARAR_NUMERICAS PROC                     ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI

    ; 1) Saltar ceros a la izquierda en cadena 1
CN_CEROS1:                                  ; avanza mientras haya '0'
    CMP BYTE PTR [SI], '0'                  ; es cero inicial?
    JNE CN_CEROS2                           ; no: pasa a cadena 2
    INC SI                                  ; salta el '0'
    JMP CN_CEROS1                           ; sigue revisando

    ; 2) Saltar ceros a la izquierda en cadena 2
CN_CEROS2:                                  ; avanza mientras haya '0'
    CMP BYTE PTR [DI], '0'                  ; es cero inicial?
    JNE CN_MEDIR                            ; no: pasa a medir longitudes
    INC DI                                  ; salta el '0'
    JMP CN_CEROS2                           ; sigue revisando

    ; 3) Comparar longitudes significativas (sin ceros iniciales)
CN_MEDIR:                                   ; mide ambas partes significativas
    CALL LONGITUD_CADENA                    ; AX = longitud significativa 1
    MOV BX, AX                              ; BX = longitud 1
    PUSH SI                                 ; guarda SI
    MOV SI, DI                              ; SI = cadena 2 sin ceros
    CALL LONGITUD_CADENA                    ; AX = longitud significativa 2
    POP SI                                  ; recupera SI
    CMP BX, AX                              ; compara longitudes
    JA CN_MAYOR                             ; mas cifras -> numero 1 es mayor
    JB CN_MENOR                             ; menos cifras -> numero 1 es menor

    ; 4) Misma longitud: si es 0, ambos eran cero (iguales)
    MOV CX, BX                              ; CX = cantidad de digitos
    CMP CX, 0                               ; ambos son 0?
    JE CN_IGUAL                             ; si: iguales

    ; 5) Comparar digito a digito de izquierda a derecha
CN_DIGITO:                                  ; recorre CX digitos
    MOV AL, [SI]                            ; digito actual de num1
    CMP AL, [DI]                            ; compara con digito de num2
    JA CN_MAYOR                             ; digito1 > digito2 -> num1 mayor
    JB CN_MENOR                             ; digito1 < digito2 -> num1 menor
    INC SI                                  ; siguiente digito de num1
    INC DI                                  ; siguiente digito de num2
    LOOP CN_DIGITO                          ; repite mientras coincidan
CN_IGUAL:                                   ; todos los digitos coincidieron
    MOV AX, 0                               ; AL = 0 (iguales)
    JMP CN_FIN                              ; sale
CN_MAYOR:                                   ; num1 > num2
    MOV AX, 1                               ; AL = 1
    JMP CN_FIN                              ; sale
CN_MENOR:                                   ; num1 < num2
    MOV AX, 2                               ; AL = 2
CN_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
COMPARAR_NUMERICAS ENDP                     ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: COMPARAR_NUMERICAS ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
