;==============================================================================
; EJERCICIO    : Frecuencia de N digitos leidos por teclado
; ARCHIVO      : 01_frecuencia_digitos.asm
; ENUNCIADO    : Solicitar una cantidad N validada entre 1 y 9, leer N numeros
;                de un digito (0..9) por teclado, guardarlos en un vector,
;                contar cuantas veces aparece cada digito 0..9 y mostrar la
;                frecuencia de cada uno utilizando macros para la E/S.
; SOLUCION     :
;   1) Lee N con LEER_NUMERO y valida 1 <= N <= 9 repitiendo si es invalido.
;   2) Lee N digitos con LEER_DIGITO (rechaza teclas fuera de '0'..'9') y los
;      guarda en VECTOR (DW).
;   3) Muestra el vector ingresado con MOSTRAR_VECTOR.
;   4) Recorre VECTOR indexando FRECUENCIA DW 10 DUP(0) con desplazamiento
;      digito * 2 (SHL BX, 1) para acumular la cantidad de cada digito.
;   5) Muestra la tabla "Digito X: Y veces" para X = 0..9 con macros de E/S.
; REGISTROS    : AX (valores leidos), BX (indice y desplazamiento), CX (ciclos),
;                SI (puntero a VECTOR), DI (puntero a FRECUENCIA).
; VARIABLES    : VECTOR (9 DW), FRECUENCIA (10 DW), CANTIDAD (DW).
; UTILS RELACIONADOS:
;   - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;   - utils/07_Procesamiento_Teclado/leer_n_validado.asm
;   - utils/07_Procesamiento_Teclado/leer_digitos_vector.asm
;   - utils/07_Procesamiento_Teclado/frecuencia_digitos.asm
; EJEMPLO DE ENTRADA/SALIDA:
;   === FRECUENCIA DE DIGITOS (0..9) ===
;   Ingrese cantidad N (1 a 9): 0
;   Error: N debe estar entre 1 y 9.
;   Ingrese cantidad N (1 a 9): 5
;   Digito 1 (0-9): 4
;   Digito 2 (0-9): 2
;   Digito 3 (0-9): 4
;   Digito 4 (0-9): 9
;   Digito 5 (0-9): 2
;   Digitos ingresados: 4 2 4 9 2
;   Frecuencia de cada digito:
;   Digito 0: 0 veces
;   ...
;   Digito 2: 2 veces
;   Digito 4: 2 veces
;   Digito 9: 1 veces
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

LEER_DIGITO MACRO                           ; macro sin parametros
    LOCAL LD_LEER                           ; etiqueta unica por cada uso
LD_LEER:                                    ; punto de reintento
    MOV AH, 01h                             ; servicio 01h: leer tecla + eco
    INT 21h                                 ; AL = codigo ASCII leido
    CMP AL, '0'                             ; compara con el ASCII de 0 (30h)
    JB LD_LEER                              ; menor que '0': no es digito
    CMP AL, '9'                             ; compara con el ASCII de 9 (39h)
    JA LD_LEER                              ; mayor que '9': no es digito
    SUB AL, '0'                             ; ASCII -> valor (ej. '7'-> 7)
    MOV AH, 0                               ; AX = valor completo de 16 bits
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
    VECTOR     DW 9 DUP(0)                  ; guarda hasta 9 digitos (0..9)
    FRECUENCIA DW 10 DUP(0)                 ; contador para cada digito 0..9
    CANTIDAD   DW 0                         ; N validado (1..9)
    MSG_TIT    DB '=== FRECUENCIA DE DIGITOS (0..9) ===$' ; titulo
    MSG_PEDIRN DB 'Ingrese cantidad N (1 a 9): $'         ; solicitud N
    MSG_ERRN   DB 'Error: N debe estar entre 1 y 9.$'     ; error rango
    MSG_DIG1   DB 'Digito $'                              ; prefijo digito
    MSG_DIG2   DB ' (0-9): $'                             ; sufijo digito
    MSG_LISTA  DB 'Digitos ingresados: $'                 ; lista leida
    MSG_TABLA  DB 'Frecuencia de cada digito:$'           ; cabecera tabla
    MSG_FREC1  DB 'Digito $'                              ; fila parte 1
    MSG_FREC2  DB ': $'                                   ; fila parte 2
    MSG_FREC3  DB ' veces$'                               ; fila parte 3
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    ; --- 1) Pedir y validar N en [1, 9] ---
PEDIR_N:                                    ; ciclo de validacion
    IMPRIMIR_CADENA MSG_PEDIRN              ; pide N
    LEER_NUMERO                             ; AX = N
    SALTO_LINEA                             ; nueva linea tras Enter
    CMP AX, 1                               ; N < 1 ?
    JB N_INVALIDO                           ; fuera de rango
    CMP AX, 9                               ; N > 9 ?
    JA N_INVALIDO                           ; fuera de rango
    JMP N_VALIDO                            ; N esta en [1, 9]
N_INVALIDO:                                 ; avisa y repite
    IMPRIMIR_CADENA MSG_ERRN                ; mensaje de error
    SALTO_LINEA                             ; nueva linea
    JMP PEDIR_N                             ; pide nuevamente

N_VALIDO:                                   ; N es valido
    MOV CANTIDAD, AX                        ; guarda N en memoria

    ; --- 2) Leer N digitos (0..9) y guardarlos en VECTOR ---
    MOV SI, OFFSET VECTOR                   ; SI = inicio de VECTOR
    MOV CX, CANTIDAD                        ; CX = N
    MOV BX, 1                               ; indice humano 1..N
LEER_CICLO:                                 ; lee cada digito
    IMPRIMIR_CADENA MSG_DIG1                ; "Digito "
    IMPRIMIR_NUMERO BX                      ; numero de orden
    IMPRIMIR_CADENA MSG_DIG2                ; " (0-9): "
    LEER_DIGITO                             ; AX = valor 0..9
    SALTO_LINEA                             ; nueva linea
    MOV [SI], AX                            ; almacena en VECTOR
    ADD SI, 2                               ; siguiente palabra
    INC BX                                  ; siguiente orden
    LOOP LEER_CICLO                         ; repite N veces

    ; --- 3) Mostrar los digitos ingresados ---
    IMPRIMIR_CADENA MSG_LISTA               ; etiqueta de lista
    MOV SI, OFFSET VECTOR                   ; SI = inicio de VECTOR
    MOV CX, CANTIDAD                        ; CX = N
    CALL MOSTRAR_VECTOR                     ; muestra los N digitos
    SALTO_LINEA                             ; nueva linea

    ; --- 4) Contar frecuencia de cada digito 0..9 ---
    MOV SI, OFFSET VECTOR                   ; SI = vector de digitos
    MOV CX, CANTIDAD                        ; CX = N
    MOV DI, OFFSET FRECUENCIA               ; DI = tabla de frecuencias
CONTAR_CICLO:                               ; recorre VECTOR
    MOV BX, [SI]                            ; BX = digito (0..9)
    SHL BX, 1                               ; desplazamiento = digito * 2
    INC WORD PTR [DI + BX]                  ; incrementa FRECUENCIA[digito]
    ADD SI, 2                               ; siguiente palabra
    LOOP CONTAR_CICLO                       ; repite N veces

    ; --- 5) Mostrar tabla de frecuencias 0..9 ---
    IMPRIMIR_CADENA MSG_TABLA               ; encabezado
    SALTO_LINEA                             ; nueva linea
    MOV DI, OFFSET FRECUENCIA               ; DI = tabla de contadores
    MOV BX, 0                               ; BX = digito actual (0..9)
    MOV CX, 10                              ; 10 digitos posibles
MOSTRAR_TABLA:                              ; imprime cada fila
    IMPRIMIR_CADENA MSG_FREC1               ; "Digito "
    IMPRIMIR_NUMERO BX                      ; X
    IMPRIMIR_CADENA MSG_FREC2               ; ": "
    MOV AX, [DI]                            ; AX = frecuencia de X
    IMPRIMIR_NUMERO AX                      ; Y
    IMPRIMIR_CADENA MSG_FREC3               ; " veces"
    SALTO_LINEA                             ; nueva linea
    ADD DI, 2                               ; siguiente contador
    INC BX                                  ; siguiente digito
    DEC CX                                  ; decrementa contador (LOOP queda
    JZ FIN_MOSTRAR_TABLA                    ; fuera de +-127 bytes por macros)
    JMP MOSTRAR_TABLA                       ; repite hasta los 10 digitos
FIN_MOSTRAR_TABLA:                          ; fin del ciclo de impresion

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_VECTOR (canonico)
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
END INICIO                                  ; fin del programa
