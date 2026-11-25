;==============================================================================
; EJERCICIO    : Calculo de potencia entera con deteccion de desborde
; ARCHIVO      : 02_potencia.asm
; ENUNCIADO    : Leer una base y un exponente enteros sin signo por teclado,
;                calcular base^exponente en 16 bits y mostrar el resultado.
;                Debe contemplar el caso exponente = 0 (resultado = 1) y
;                mostrar un mensaje de error si el resultado supera 65535.
; SOLUCION     : 1) Se leen BASE y EXPONENTE usando la macro LEER_NUMERO.
;                2) Se cargan AX = BASE y CX = EXPONENTE y se llama a POTENCIA.
;                3) POTENCIA devuelve 1 inmediatamente si CX = 0 (incluye 0^0=1)
;                   o realiza CX multiplicaciones sucesivas con MUL SI.
;                   Si en algun paso DX <> 0 (producto > 65535), activa BL = 1.
;                4) El programa principal muestra la operacion y el resultado,
;                   o un mensaje de error de desborde si BL = 1.
; REGISTROS    : AX = base (entrada) / resultado (salida)
;                CX = exponente
;                BL = indicador de desborde (1 = desborde, 0 = valido), BH = 0
; VARIABLES    : BASE      DW 0 -> base ingresada por el usuario
;                EXPONENTE DW 0 -> exponente ingresado por el usuario
;                RESULTADO DW 0 -> resultado de base^exponente
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/06_Algoritmos_Matematicos/potencia.asm
; EJEMPLO DE ENTRADA/SALIDA:
;                Entrada: base = 2, exponente = 10
;                Salida :
;                  === CALCULO DE POTENCIA (16 BITS) ===
;                  Ingrese la base (0..65535): 2
;                  Ingrese el exponente (0..65535): 10
;                  Resultado: 2 ^ 10 = 1024
;
;                Entrada: base = 2, exponente = 16
;                Salida :
;                  === CALCULO DE POTENCIA (16 BITS) ===
;                  Ingrese la base (0..65535): 2
;                  Ingrese el exponente (0..65535): 16
;                  ERROR: 2 ^ 16 supera el limite de 16 bits (65535).
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

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    BASE      DW 0                          ; base leida por teclado
    EXPONENTE DW 0                          ; exponente leido por teclado
    RESULTADO DW 0                          ; resultado de la potencia
    MSG_TITULO DB '=== CALCULO DE POTENCIA (16 BITS) ===$' ; titulo
    MSG_BASE   DB 'Ingrese la base (0..65535): $'          ; pide base
    MSG_EXP    DB 'Ingrese el exponente (0..65535): $'     ; pide exponente
    MSG_RES    DB 'Resultado: $'                           ; prefijo valido
    MSG_ELEV   DB ' ^ $'                                   ; simbolo potencia
    MSG_IGUAL  DB ' = $'                                   ; signo igual
    MSG_ERR1   DB 'ERROR: $'                               ; prefijo error
    MSG_ERR2   DB ' supera el limite de 16 bits (65535).$' ; sufijo error
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_BASE                ; solicita la base
    LEER_NUMERO                             ; AX = base ingresada
    MOV BASE, AX                            ; guarda base en memoria
    SALTO_LINEA                             ; nueva linea tras Enter

    IMPRIMIR_CADENA MSG_EXP                 ; solicita el exponente
    LEER_NUMERO                             ; AX = exponente ingresado
    MOV EXPONENTE, AX                       ; guarda exponente en memoria
    SALTO_LINEA                             ; nueva linea tras Enter

    MOV AX, BASE                            ; AX = base
    MOV CX, EXPONENTE                       ; CX = exponente
    CALL POTENCIA                           ; AX = base^exp, BL = 1 si desborde
    MOV RESULTADO, AX                       ; guarda el resultado

    CMP BL, 1                               ; hubo desborde de 16 bits?
    JNE EJ_OK                               ; no: salta a mostrar resultado
    JMP EJ_DESBORDE                         ; si: salto largo al mensaje error
EJ_OK:                                      ; muestra resultado valido
    IMPRIMIR_CADENA MSG_RES                 ; muestra "Resultado: "
    IMPRIMIR_NUMERO BASE                    ; muestra la base
    IMPRIMIR_CADENA MSG_ELEV                ; muestra " ^ "
    IMPRIMIR_NUMERO EXPONENTE               ; muestra el exponente
    IMPRIMIR_CADENA MSG_IGUAL               ; muestra " = "
    IMPRIMIR_NUMERO RESULTADO               ; muestra el valor calculado
    SALTO_LINEA                             ; nueva linea
    JMP EJ_FIN                              ; salta al cierre del programa
EJ_DESBORDE:                                ; muestra error de desborde
    IMPRIMIR_CADENA MSG_ERR1                ; muestra "ERROR: "
    IMPRIMIR_NUMERO BASE                    ; muestra la base
    IMPRIMIR_CADENA MSG_ELEV                ; muestra " ^ "
    IMPRIMIR_NUMERO EXPONENTE               ; muestra el exponente
    IMPRIMIR_CADENA MSG_ERR2                ; muestra explicacion del limite
    SALTO_LINEA                             ; nueva linea
EJ_FIN:                                     ; salida a DOS
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO POTENCIA (de utils/06_Algoritmos_Matematicos/potencia.asm)
;   Entrada : AX = base (0..65535), CX = exponente (0..65535)
;   Salida  : AX = base^exponente (0 si hubo desborde)
;             BL = 1 si desbordo 16 bits, BL = 0 si resultado valido (BH = 0)
;   Modifica: AX, BX y banderas. Conserva CX, DX, SI.
;------------------------------------------------------------------------------
POTENCIA PROC                               ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (exponente)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (base)
    MOV BX, 0                               ; supone sin desborde (BH=0, BL=0)
    MOV SI, AX                              ; SI = base
    MOV AX, 1                               ; acumulador = 1 (para exp = 0)
    CMP CX, 0                               ; exponente igual a 0?
    JE POT_FIN                              ; si: base^0 = 1 (incluye 0^0 = 1)
POT_CICLO:                                  ; multiplica CX veces por la base
    MUL SI                                  ; DX:AX = acumulador * base
    CMP DX, 0                               ; la parte alta DX es distinta de 0?
    JNE POT_DESBORDE                        ; si: supero 65535 -> desborde
    LOOP POT_CICLO                          ; CX = CX - 1 y repite si CX <> 0
    JMP POT_FIN                             ; termino sin desborde
POT_DESBORDE:                               ; ocurrio desborde de 16 bits
    MOV AX, 0                               ; limpia resultado invalido
    MOV BL, 1                               ; indica desborde en BL
POT_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
POTENCIA ENDP                               ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
