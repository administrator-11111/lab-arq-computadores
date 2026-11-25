;==============================================================================
; EJERCICIO    : Comparar dos cadenas leidas por teclado con detalle
; ARCHIVO      : 02_comparar_cadenas_teclado.asm
; ENUNCIADO    : Leer dos cadenas por teclado, mostrar la longitud de cada una,
;                indicar si son iguales o diferentes y, en caso de diferir,
;                informar cuantos caracteres coinciden y la primera posicion
;                donde difieren.
; SOLUCION     :
;   1) Lee ambas cadenas usando INT 21h AH=0Ah con LEER_CADENA_TECLADO, que
;      coloca '$' al final de cada texto y devuelve la longitud en AX.
;   2) Imprime la longitud de cada cadena.
;   3) Llama a COMPARAR_POSICION (SI = cadena 1, DI = cadena 2), que devuelve
;      BL = 1 si son iguales o BL = 0 si difieren, y AX = cantidad de
;      caracteres coincidentes (indice base 0 de la primera diferencia).
;   4) Muestra el resultado y, si difieren, la primera posicion (base 1 y 0).
; REGISTROS    : SI/DI (punteros a cadenas), AX (longitudes y coincidencias),
;                BX (resultado BL=1/0 y posicion base 1), DX (buffers).
; VARIABLES    : BUF1_MAX..BUF1_TXT, BUF2_MAX..BUF2_TXT, LEN1, LEN2.
; UTILS RELACIONADOS:
;   - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;   - utils/08_Comparacion_Cadenas/longitud_cadena.asm
;   - utils/08_Comparacion_Cadenas/comparar_cadenas_teclado.asm
;   - utils/08_Comparacion_Cadenas/comparar_caracter_por_caracter.asm
; EJEMPLO DE ENTRADA/SALIDA:
;   === COMPARAR DOS CADENAS POR TECLADO ===
;   Ingrese cadena 1: computador
;   Ingrese cadena 2: computacion
;   Longitud cadena 1: 10
;   Longitud cadena 2: 11
;   Resultado: DIFERENTES
;   Caracteres coincidentes al inicio: 7
;   Primera posicion distinta: 8 (indice 7)
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
    BUF1_MAX DB 51                          ; capacidad maxima buffer 1
    BUF1_LEN DB 0                           ; longitud leida 1
    BUF1_TXT DB 52 DUP('$')                 ; texto 1 terminado en '$'
    BUF2_MAX DB 51                          ; capacidad maxima buffer 2
    BUF2_LEN DB 0                           ; longitud leida 2
    BUF2_TXT DB 52 DUP('$')                 ; texto 2 terminado en '$'
    LEN1     DW 0                           ; longitud 1 (16 bits)
    LEN2     DW 0                           ; longitud 2 (16 bits)

    MSG_TIT  DB '=== COMPARAR DOS CADENAS POR TECLADO ===$' ; titulo
    MSG_P1   DB 'Ingrese cadena 1: $'       ; pedido 1
    MSG_P2   DB 'Ingrese cadena 2: $'       ; pedido 2
    MSG_L1   DB 'Longitud cadena 1: $'      ; etiqueta longitud 1
    MSG_L2   DB 'Longitud cadena 2: $'      ; etiqueta longitud 2
    MSG_IG   DB 'Resultado: IGUALES$'       ; resultado igual
    MSG_DIF  DB 'Resultado: DIFERENTES$'    ; resultado diferente
    MSG_COI  DB 'Caracteres coincidentes al inicio: $' ; coincidencias
    MSG_POS1 DB 'Primera posicion distinta: $'         ; posicion base 1
    MSG_POS2 DB ' (indice $'                ; indice base 0
    MSG_CIE  DB ')$'                        ; cierre
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P1                  ; pide cadena 1
    LEA DX, BUF1_MAX                        ; buffer 1
    CALL LEER_CADENA_TECLADO                ; lee y retorna longitud en AX
    MOV LEN1, AX                            ; guarda longitud 1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P2                  ; pide cadena 2
    LEA DX, BUF2_MAX                        ; buffer 2
    CALL LEER_CADENA_TECLADO                ; lee y retorna longitud en AX
    MOV LEN2, AX                            ; guarda longitud 2
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_L1                  ; muestra longitud 1
    IMPRIMIR_NUMERO LEN1                    ; valor
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_L2                  ; muestra longitud 2
    IMPRIMIR_NUMERO LEN2                    ; valor
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET BUF1_TXT                 ; SI = texto 1
    MOV DI, OFFSET BUF2_TXT                 ; DI = texto 2
    CALL COMPARAR_POSICION                  ; BL = 1/0, AX = coincidencias
    CMP BL, 1                               ; iguales?
    JNE SON_DIF                             ; no: muestra detalle de diferencia
    IMPRIMIR_CADENA MSG_IG                  ; "Resultado: IGUALES"
    SALTO_LINEA                             ; nueva linea
    JMP FIN_EJ                              ; termina

SON_DIF:                                    ; rama diferentes
    IMPRIMIR_CADENA MSG_DIF                 ; "Resultado: DIFERENTES"
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_COI                 ; "Caracteres coincidentes..."
    IMPRIMIR_NUMERO AX                      ; muestra coincidencias
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_POS1                ; "Primera posicion distinta: "
    MOV BX, AX                              ; BX = indice base 0
    INC BX                                  ; BX = posicion base 1
    IMPRIMIR_NUMERO BX                      ; muestra posicion base 1
    IMPRIMIR_CADENA MSG_POS2                ; " (indice "
    IMPRIMIR_NUMERO AX                      ; muestra indice base 0
    IMPRIMIR_CADENA MSG_CIE                 ; ")"
    SALTO_LINEA                             ; nueva linea

FIN_EJ:                                     ; salida
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
    MOV AL, [BX + 1]                        ; AL = longitud real
    MOV AH, 0                               ; AX = longitud
    MOV SI, BX                              ; SI = base buffer
    ADD SI, 2                               ; salta [max][len]
    ADD SI, AX                              ; apunta al 0Dh final
    MOV BYTE PTR [SI], '$'                  ; coloca '$'
    POP SI                                  ; restaura SI
    POP BX                                  ; restaura BX
    RET                                     ; vuelve con AX = longitud
LEER_CADENA_TECLADO ENDP                    ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_POSICION
;------------------------------------------------------------------------------
COMPARAR_POSICION PROC                      ; inicio del procedimiento
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI
    XOR CX, CX                              ; coincidencias = 0
CP_CICLO:                                   ; recorre byte a byte
    MOV AL, [SI]                            ; caracter de cad1
    MOV AH, [DI]                            ; caracter de cad2
    CMP AL, AH                              ; iguales?
    JNE CP_DIF                              ; no: difieren en indice CX
    CMP AL, '$'                             ; ambos en fin '$'?
    JE CP_IGUAL                             ; si: iguales
    INC CX                                  ; suma coincidencia
    INC SI                                  ; avanza cad1
    INC DI                                  ; avanza cad2
    JMP CP_CICLO                            ; repite
CP_IGUAL:                                   ; iguales
    MOV BX, 1                               ; BL = 1
    JMP CP_FIN                              ; sale
CP_DIF:                                     ; diferentes
    MOV BX, 0                               ; BL = 0
CP_FIN:                                     ; salida comun
    MOV AX, CX                              ; AX = coincidencias / indice dif.
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
COMPARAR_POSICION ENDP                      ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
