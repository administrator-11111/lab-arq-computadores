;==============================================================================
; ARCHIVO      : leer_n_validado.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Lee una cantidad N por teclado y valida que pertenezca al
;                rango cerrado [MINIMO, MAXIMO] (variables en DATOS),
;                repitiendo la lectura hasta recibir un valor valido.
; FUNCIONAMIENTO:
;   1) Muestra un mensaje de solicitud y lee un numero sin signo con la macro
;      LEER_NUMERO (resultado en AX).
;   2) Compara AX con MINIMO usando JB (menor sin signo) y con MAXIMO usando
;      JA (mayor sin signo).
;   3) Si esta fuera del rango, muestra un mensaje de error indicando los
;      limites [MINIMO, MAXIMO] y repite el ciclo.
;   4) Cuando MINIMO <= AX <= MAXIMO, retorna con AX = valor validado.
;   NOTA 8086: Como IMPRIMIR_NUMERO y LEER_NUMERO expanden varias instrucciones,
;      los saltos condicionales pueden superar +-127 bytes; por eso se usan
;      saltos cortos hacia etiquetas cercanas o saltos invertidos + JMP.
; REGISTROS    :
;   LEER_EN_RANGO -> Entrada: variables MINIMO y MAXIMO en DATOS,
;                             DX = offset del mensaje de solicitud (terminado '$').
;                    Salida : AX = numero validado en [MINIMO, MAXIMO].
;                    Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
; VARIABLES    : MINIMO DW, MAXIMO DW, MSG_ERR_RANGO1/2/3 en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, SALTO_LINEA,
;                LEER_NUMERO, FIN_PROGRAMA de
;                utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm.
; COMO INTEGRAR: Copiar las macros, declarar MINIMO, MAXIMO y los mensajes de
;                error en DATOS, y copiar LEER_EN_RANGO en CODIGO despues de
;                FIN_PROGRAMA. Antes de llamarlo, cargar MINIMO, MAXIMO y
;                LEA DX, TU_MENSAJE.
; EJEMPLO      :
;   === DEMO LECTURA VALIDADA EN RANGO ===
;   Ingrese N (1 a 10): 0
;   Error: ingrese un valor entre 1 y 10.
;   Ingrese N (1 a 10): 15
;   Error: ingrese un valor entre 1 y 10.
;   Ingrese N (1 a 10): 7
;   Valor aceptado: 7
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

LEER_NUMERO MACRO                           ; macro sin parametros
    LOCAL LN_LEER, LN_FIN                   ; etiquetas unicas por cada uso
    PUSH BX                                 ; guarda BX (acumulador)
    PUSH CX                                 ; guarda CX (cifra)
    PUSH DX                                 ; guarda DX (MUL lo modifica)
    XOR BX, BX                              ; acumulado = 0
LN_LEER:                                    ; ciclo de lectura de teclas
    MOV AH, 01h                             ; servicio 01h: leer tecla + eco
    INT 21h                                 ; AL = tecla presionada
    CMP AL, 13                              ; es Enter (retorno de carro)?
    JE LN_FIN                               ; si: termina la lectura
    CMP AL, '0'                             ; menor que el ASCII '0'?
    JB LN_LEER                              ; no es digito: lo ignora
    CMP AL, '9'                             ; mayor que el ASCII '9'?
    JA LN_LEER                              ; no es digito: lo ignora
    SUB AL, '0'                             ; convierte ASCII a valor 0..9
    MOV CL, AL                              ; CL = cifra leida
    MOV CH, 0                               ; CX = cifra en 16 bits
    MOV AX, BX                              ; AX = acumulado actual
    MOV DX, 10                              ; DX = multiplicador 10
    MUL DX                                  ; DX:AX = acumulado * 10
    ADD AX, CX                              ; suma la nueva cifra
    MOV BX, AX                              ; guarda el nuevo acumulado
    JMP LN_LEER                             ; lee la siguiente tecla
LN_FIN:                                     ; se presiono Enter
    MOV AX, BX                              ; AX = numero leido (resultado)
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
ENDM                                        ; fin de la macro

FIN_PROGRAMA MACRO                          ; macro sin parametros
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; DOS finaliza el programa
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MINIMO       DW 0                       ; limite inferior permitido
    MAXIMO       DW 0                       ; limite superior permitido
    VALOR_N      DW 0                       ; ultimo valor validado
    MSG_TIT      DB '=== DEMO LECTURA VALIDADA EN RANGO ===$'  ; titulo
    MSG_PEDIR1   DB 'Ingrese N (1 a 10): $'                    ; pedido 1
    MSG_PEDIR2   DB 'Ingrese cantidad (0 a 30): $'             ; pedido 2
    MSG_OK       DB 'Valor aceptado: $'                        ; confirmacion
    MSG_ERR1     DB 'Error: ingrese un valor entre $'          ; error parte 1
    MSG_ERR2     DB ' y $'                                     ; error parte 2
    MSG_ERR3     DB '.$'                                       ; error parte 3
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    ; --- Prueba 1: validar en [1, 10] ---
    MOV MINIMO, 1                           ; fija limite inferior en 1
    MOV MAXIMO, 10                          ; fija limite superior en 10
    LEA DX, MSG_PEDIR1                      ; DX = mensaje de solicitud 1
    CALL LEER_EN_RANGO                      ; AX = N validado en [1, 10]
    MOV VALOR_N, AX                         ; guarda el resultado
    IMPRIMIR_CADENA MSG_OK                  ; muestra confirmacion
    IMPRIMIR_NUMERO VALOR_N                 ; muestra el valor aceptado
    SALTO_LINEA                             ; nueva linea

    ; --- Prueba 2: validar en [0, 30] ---
    MOV MINIMO, 0                           ; fija limite inferior en 0
    MOV MAXIMO, 30                          ; fija limite superior en 30
    LEA DX, MSG_PEDIR2                      ; DX = mensaje de solicitud 2
    CALL LEER_EN_RANGO                      ; AX = N validado en [0, 30]
    MOV VALOR_N, AX                         ; guarda el resultado
    IMPRIMIR_CADENA MSG_OK                  ; muestra confirmacion
    IMPRIMIR_NUMERO VALOR_N                 ; muestra el valor aceptado
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LEER_EN_RANGO ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LEER_EN_RANGO
;   Entrada : MINIMO (DW), MAXIMO (DW) en DATOS; DX = offset del mensaje '$'.
;   Salida  : AX = numero entero sin signo tal que MINIMO <= AX <= MAXIMO.
;   Requiere: macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, SALTO_LINEA, LEER_NUMERO
;             y mensajes MSG_ERR1, MSG_ERR2, MSG_ERR3 en DATOS.
;   Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
LEER_EN_RANGO PROC                          ; inicio del procedimiento
    PUSH DX                                 ; guarda offset del mensaje
LER_PEDIR:                                  ; ciclo de solicitud y validacion
    POP DX                                  ; recupera offset del mensaje
    PUSH DX                                 ; lo mantiene en pila para reintentos
    MOV AH, 09h                             ; servicio 09h: mostrar cadena$
    INT 21h                                 ; muestra el mensaje de solicitud
    LEER_NUMERO                             ; AX = numero ingresado por teclado
    SALTO_LINEA                             ; nueva linea tras presionar Enter
    CMP AX, MINIMO                          ; compara con el minimo
    JB LER_ERROR                            ; AX < MINIMO: fuera de rango
    CMP AX, MAXIMO                          ; compara con el maximo
    JA LER_ERROR                            ; AX > MAXIMO: fuera de rango
    JMP LER_FIN                             ; valido: sale del ciclo
LER_ERROR:                                  ; muestra mensaje de rango valido
    IMPRIMIR_CADENA MSG_ERR1                ; "Error: ingrese un valor entre "
    IMPRIMIR_NUMERO MINIMO                  ; imprime el limite inferior
    IMPRIMIR_CADENA MSG_ERR2                ; " y "
    IMPRIMIR_NUMERO MAXIMO                  ; imprime el limite superior
    IMPRIMIR_CADENA MSG_ERR3                ; "."
    SALTO_LINEA                             ; nueva linea
    JMP LER_PEDIR                           ; vuelve a pedir el numero
LER_FIN:                                    ; salida con valor valido en AX
    POP DX                                  ; restaura DX original
    RET                                     ; vuelve al llamador
LEER_EN_RANGO ENDP                          ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LEER_EN_RANGO ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
