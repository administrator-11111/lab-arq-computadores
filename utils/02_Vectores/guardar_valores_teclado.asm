;==============================================================================
; ARCHIVO      : guardar_valores_teclado.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Implementa el procedimiento LEER_VECTOR, que solicita al
;                usuario ingresar CX numeros enteros sin signo (0..65535) por
;                teclado usando la macro LEER_NUMERO y los almacena en un
;                vector de palabras (DW).
; FUNCIONAMIENTO:
;                Recibe en SI el OFFSET del vector y en CX la cantidad de
;                elementos a leer. En cada iteracion muestra el indice [i]:,
;                invoca LEER_NUMERO (resultado en AX), guarda AX en [SI] y
;                avanza SI en 2 bytes (tamano de una palabra DW).
;                Particularidad del 8086: como LEER_NUMERO expande varias
;                instrucciones, un LOOP directo podria quedar fuera del rango
;                de salto corto (+/- 127 bytes). Por eso se usa el patron
;                DEC CX / JZ fin / JMP inicio, que permite saltos largos.
; REGISTROS    : LEER_VECTOR:
;                  Entrada : SI = offset del vector (DW), CX = cantidad
;                  Salida  : vector cargado con los valores ingresados
;                  Modifica: nada (conserva AX, BX, CX, SI)
; VARIABLES    : Un vector DW en DATOS con espacio para al menos CX palabras.
; DEPENDENCIAS : Macros IMPRIMIR_CARACTER, IMPRIMIR_CADENA, IMPRIMIR_NUMERO,
;                IMPRIMIR_ESPACIO, SALTO_LINEA, LEER_NUMERO, FIN_PROGRAMA
;                (de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
;                Procedimiento MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Declarar el vector DW en DATOS.
;                3) Copiar el bloque reutilizable en CODIGO despues de la
;                   salida a DOS y llamarlo con SI = OFFSET VECTOR y CX = N.
; EJEMPLO      : Entrada: 12, 45, 7, 300, 99 (cada uno seguido de Enter)
;                Salida:
;                  === LEER VECTOR DESDE TECLADO ===
;                  Ingrese 5 numeros (Enter tras cada uno):
;                  [0]: 12
;                  [1]: 45
;                  [2]: 7
;                  [3]: 300
;                  [4]: 99
;                  Vector ingresado: 12 45 7 300 99
;==============================================================================

;//// macros

IMPRIMIR_CARACTER MACRO car                 ; inicio de la macro, recibe car
    PUSH AX                                 ; guarda AX porque se usara AH
    PUSH DX                                 ; guarda DX porque se usara DL
    MOV DL, car                             ; DL = caracter que DOS mostrara
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    INT 21h                                 ; DOS muestra el caracter de DL
    POP DX                                  ; recupera DX original
    POP AX                                  ; recupera AX original
ENDM                                        ; fin de la macro

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

IMPRIMIR_ESPACIO MACRO                      ; macro sin parametros
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV DL, ' '                             ; caracter espacio (20h)
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    INT 21h                                 ; muestra el espacio
    POP DX                                  ; restaura DX
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
    TAMANO     EQU 5                        ; cantidad de valores a leer
    VECTOR     DW TAMANO DUP(0)             ; vector de 5 palabras (10 bytes)

    MSG_TIT    DB '=== LEER VECTOR DESDE TECLADO ===$' ; titulo
    MSG_PEDIR  DB 'Ingrese 5 numeros (Enter tras cada uno):$' ; indicacion
    MSG_RES    DB 'Vector ingresado: $'     ; etiqueta del resultado
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_PEDIR               ; indica cuantos valores ingresar
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 5 valores a leer
    CALL LEER_VECTOR                        ; lee los 5 valores por teclado

    IMPRIMIR_CADENA MSG_RES                 ; muestra etiqueta de salida
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 5 elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector cargado
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LEER_VECTOR ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LEER_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : llena el vector con CX numeros leidos por teclado.
;   Requiere: macros IMPRIMIR_CARACTER, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;             SALTO_LINEA y LEER_NUMERO.
;   Modifica: nada (conserva AX, BX, CX, SI).
;------------------------------------------------------------------------------
LEER_VECTOR PROC                            ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (valor leido)
    PUSH BX                                 ; guarda BX (indice para mostrar)
    PUSH CX                                 ; guarda CX (cantidad restante)
    PUSH SI                                 ; guarda SI (puntero al vector)
    CMP CX, 0                               ; vector vacio?
    JNE LV_INICIAR                          ; si CX <> 0 comienza a leer
    JMP LV_FIN                              ; salto largo si CX == 0
LV_INICIAR:                                 ; prepara el indice de etiqueta
    XOR BX, BX                              ; BX = 0 (indice logico actual)
LV_CICLO:                                   ; ciclo de lectura por elemento
    IMPRIMIR_CARACTER '['                   ; muestra '['
    IMPRIMIR_NUMERO BX                      ; muestra el indice logico i
    IMPRIMIR_CARACTER ']'                   ; muestra ']'
    IMPRIMIR_CARACTER ':'                   ; muestra ':'
    IMPRIMIR_ESPACIO                        ; espacio antes de escribir
    LEER_NUMERO                             ; AX = numero ingresado por teclado
    SALTO_LINEA                             ; baja de linea tras el Enter
    MOV [SI], AX                            ; guarda la palabra en VECTOR[i]
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    INC BX                                  ; incrementa el indice logico
    DEC CX                                  ; un elemento menos por leer
    JZ LV_FIN                               ; si CX == 0 termina la lectura
    JMP LV_CICLO                            ; salto largo (evita limite LOOP)
LV_FIN:                                     ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LEER_VECTOR ENDP                            ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LEER_VECTOR ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad (>0)
;   Salida  : muestra los elementos separados por un espacio.
;   Requiere: macros IMPRIMIR_NUMERO e IMPRIMIR_ESPACIO.
;   Modifica: nada (conserva AX, CX, SI).
;------------------------------------------------------------------------------
MOSTRAR_VECTOR PROC                         ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    CMP CX, 0                               ; vector vacio?
    JE MV_FIN                               ; si: no hay nada que mostrar
MV_CICLO:                                   ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    IMPRIMIR_NUMERO AX                      ; lo muestra
    IMPRIMIR_ESPACIO                        ; separador
    ADD SI, 2                               ; siguiente elemento (2 bytes)
    LOOP MV_CICLO                           ; repite CX veces
MV_FIN:                                     ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MOSTRAR_VECTOR ENDP                         ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
