;==============================================================================
; EJERCICIO    : Comparar dos cadenas numericas leidas por teclado
; ARCHIVO      : 03_comparar_cadenas_numericas.asm
; ENUNCIADO    : Leer dos cadenas numericas por teclado (enteros sin signo de
;                cualquier cantidad de cifras hasta 40) e indicar cual numero
;                es mayor o si son iguales.
; SOLUCION     :
;   1) Lee ambas cadenas con INT 21h AH=0Ah (LEER_CADENA_TECLADO).
;   2) Llama a COMPARAR_NUMERICAS, que:
;      a) Salta los ceros a la izquierda ('0') de ambas cadenas.
;      b) Compara las longitudes significativas: la de mayor longitud es mayor.
;      c) Si tienen la misma longitud, compara digito a digito de izquierda a
;         derecha.
;   3) Muestra el veredicto: primer numero mayor, segundo mayor o iguales.
; REGISTROS    : SI/DI (cadenas), AX (resultado 0/1/2), BX/CX (longitudes),
;                DX (buffers y mensajes).
; VARIABLES    : BUF1_MAX..BUF1_TXT, BUF2_MAX..BUF2_TXT en DATOS.
; UTILS RELACIONADOS:
;   - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;   - utils/08_Comparacion_Cadenas/comparar_cadenas_teclado.asm
;   - utils/08_Comparacion_Cadenas/comparar_cadenas_numericas.asm
; EJEMPLO DE ENTRADA/SALIDA:
;   === COMPARAR DOS CADENAS NUMERICAS ===
;   Ingrese primer numero : 123
;   Ingrese segundo numero: 45
;   Resultado: el primer numero (123) es MAYOR que (45).
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
    BUF1_MAX DB 41                          ; hasta 40 digitos + 0Dh
    BUF1_LEN DB 0                           ; longitud leida 1
    BUF1_TXT DB 42 DUP('$')                 ; texto numerico 1
    BUF2_MAX DB 41                          ; hasta 40 digitos + 0Dh
    BUF2_LEN DB 0                           ; longitud leida 2
    BUF2_TXT DB 42 DUP('$')                 ; texto numerico 2

    MSG_TIT  DB '=== COMPARAR DOS CADENAS NUMERICAS ===$' ; titulo
    MSG_P1   DB 'Ingrese primer numero : $' ; solicitud 1
    MSG_P2   DB 'Ingrese segundo numero: $' ; solicitud 2
    MSG_R1   DB 'Resultado: el primer numero ($'  ; resultado 1
    MSG_R2   DB 'Resultado: el segundo numero ($' ; resultado 2
    MSG_MAY  DB ') es MAYOR que ($'         ; comparador mayor
    MSG_CIE  DB ').$'                       ; cierre
    MSG_IG   DB 'Resultado: ambos numeros son IGUALES.$' ; iguales
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P1                  ; pide primer numero
    LEA DX, BUF1_MAX                        ; buffer 1
    CALL LEER_CADENA_TECLADO                ; lee cadena 1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P2                  ; pide segundo numero
    LEA DX, BUF2_MAX                        ; buffer 2
    CALL LEER_CADENA_TECLADO                ; lee cadena 2
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET BUF1_TXT                 ; SI = numero 1
    MOV DI, OFFSET BUF2_TXT                 ; DI = numero 2
    CALL COMPARAR_NUMERICAS                 ; AL = 0 igual, 1 mayor, 2 menor
    CMP AL, 1                               ; primero > segundo?
    JE PRIMERO_MAYOR                        ; si
    CMP AL, 2                               ; primero < segundo?
    JE SEGUNDO_MAYOR                        ; si
    IMPRIMIR_CADENA MSG_IG                  ; iguales
    JMP FIN_EJ                              ; sale

PRIMERO_MAYOR:                              ; num1 > num2
    IMPRIMIR_CADENA MSG_R1                  ; "Resultado: el primer numero ("
    IMPRIMIR_CADENA BUF1_TXT                ; imprime num1
    IMPRIMIR_CADENA MSG_MAY                 ; ") es MAYOR que ("
    IMPRIMIR_CADENA BUF2_TXT                ; imprime num2
    IMPRIMIR_CADENA MSG_CIE                 ; ")."
    JMP FIN_EJ                              ; sale

SEGUNDO_MAYOR:                              ; num2 > num1
    IMPRIMIR_CADENA MSG_R2                  ; "Resultado: el segundo numero ("
    IMPRIMIR_CADENA BUF2_TXT                ; imprime num2
    IMPRIMIR_CADENA MSG_MAY                 ; ") es MAYOR que ("
    IMPRIMIR_CADENA BUF1_TXT                ; imprime num1
    IMPRIMIR_CADENA MSG_CIE                 ; ")."

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
    MOV BX, DX                              ; BX = base buffer
    MOV AL, [BX + 1]                        ; AL = longitud
    MOV AH, 0                               ; AX = longitud
    MOV SI, BX                              ; SI = base buffer
    ADD SI, 2                               ; salta cabecera
    ADD SI, AX                              ; apunta a 0Dh
    MOV BYTE PTR [SI], '$'                  ; reemplaza por '$'
    POP SI                                  ; restaura SI
    POP BX                                  ; restaura BX
    RET                                     ; vuelve con AX = longitud
LEER_CADENA_TECLADO ENDP                    ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO LONGITUD_CADENA
;------------------------------------------------------------------------------
LONGITUD_CADENA PROC                        ; inicio del procedimiento
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; contador = 0
LC_CICLO:                                   ; recorre hasta '$'
    CMP BYTE PTR [SI], '$'                  ; es '$'?
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
;------------------------------------------------------------------------------
COMPARAR_NUMERICAS PROC                     ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI
CN_CEROS1:                                  ; salta '0' iniciales en num1
    CMP BYTE PTR [SI], '0'                  ; es cero inicial?
    JNE CN_CEROS2                           ; no
    INC SI                                  ; salta
    JMP CN_CEROS1                           ; repite
CN_CEROS2:                                  ; salta '0' iniciales en num2
    CMP BYTE PTR [DI], '0'                  ; es cero inicial?
    JNE CN_MEDIR                            ; no
    INC DI                                  ; salta
    JMP CN_CEROS2                           ; repite
CN_MEDIR:                                   ; mide longitudes significativas
    CALL LONGITUD_CADENA                    ; AX = longitud 1
    MOV BX, AX                              ; BX = longitud 1
    PUSH SI                                 ; guarda SI
    MOV SI, DI                              ; mide num2
    CALL LONGITUD_CADENA                    ; AX = longitud 2
    POP SI                                  ; recupera SI
    CMP BX, AX                              ; compara longitudes
    JA CN_MAYOR                             ; num1 tiene mas cifras
    JB CN_MENOR                             ; num2 tiene mas cifras
    MOV CX, BX                              ; misma longitud
    CMP CX, 0                               ; ambos eran cero?
    JE CN_IGUAL                             ; si: iguales
CN_DIGITO:                                  ; compara digito a digito
    MOV AL, [SI]                            ; digito de num1
    CMP AL, [DI]                            ; compara con digito de num2
    JA CN_MAYOR                             ; num1 > num2
    JB CN_MENOR                             ; num1 < num2
    INC SI                                  ; siguiente digito
    INC DI                                  ; siguiente digito
    LOOP CN_DIGITO                          ; repite CX veces
CN_IGUAL:                                   ; iguales
    MOV AX, 0                               ; AL = 0
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

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
