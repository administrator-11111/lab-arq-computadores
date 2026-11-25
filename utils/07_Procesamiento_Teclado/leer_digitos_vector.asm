;==============================================================================
; ARCHIVO      : leer_digitos_vector.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Lee N numeros de un solo digito (0..9) por teclado usando
;                LEER_DIGITO (rechaza teclas que no sean digitos) y los
;                almacena en un vector de palabras (DW).
; FUNCIONAMIENTO:
;   1) El programa pide N y valida que este en [1, 15].
;   2) Llama a LEER_DIGITOS_VECTOR pasando SI = offset del vector y CX = N.
;   3) Por cada posicion, muestra el numero de elemento (1..N), invoca la
;      macro LEER_DIGITO (que solo acepta teclas '0'..'9' y deja su valor
;      numerico 0..9 en AX), guarda AX en [SI] y avanza SI en 2 bytes.
;   4) Al terminar, muestra el vector cargado con MOSTRAR_VECTOR.
; REGISTROS    :
;   LEER_DIGITOS_VECTOR -> Entrada: SI = offset del vector (DW), CX = cantidad.
;                          Salida : vector lleno con valores 0..9.
;                          Conserva todos los registros.
; VARIABLES    : VECTOR DW 15 DUP(0), CANTIDAD DW 0, mensajes en DATOS.
; DEPENDENCIAS : Macros de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y MOSTRAR_VECTOR.
; COMO INTEGRAR: Copiar las macros, declarar un vector DW en DATOS y copiar
;                LEER_DIGITOS_VECTOR dentro de CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      :
;   === DEMO LECTURA DE N DIGITOS A VECTOR ===
;   Cuantos digitos desea ingresar (1 a 15)? 4
;   Digito 1 (0-9): 5
;   Digito 2 (0-9): 0
;   Digito 3 (0-9): 9
;   Digito 4 (0-9): 3
;   Vector ingresado: 5 0 9 3
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
    VECTOR     DW 15 DUP(0)                 ; almacena hasta 15 digitos (0..9)
    CANTIDAD   DW 0                         ; N ingresado por el usuario
    MSG_TIT    DB '=== DEMO LECTURA DE N DIGITOS A VECTOR ===$' ; titulo
    MSG_PEDIRN DB 'Cuantos digitos desea ingresar (1 a 15)? $'  ; pedido N
    MSG_ERRN   DB 'Error: N debe estar entre 1 y 15.$'          ; error N
    MSG_DIG1   DB 'Digito $'                                    ; prefijo
    MSG_DIG2   DB ' (0-9): $'                                   ; sufijo
    MSG_VEC    DB 'Vector ingresado: $'                         ; salida
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

PEDIR_N:                                    ; valida N en [1, 15]
    IMPRIMIR_CADENA MSG_PEDIRN              ; solicita N
    LEER_NUMERO                             ; AX = N
    SALTO_LINEA                             ; nueva linea
    CMP AX, 1                               ; N < 1 ?
    JB ERR_N                                ; invalido
    CMP AX, 15                              ; N > 15 ?
    JA ERR_N                                ; invalido
    JMP N_VALIDO                            ; N esta en [1, 15]
ERR_N:                                      ; rama de error
    IMPRIMIR_CADENA MSG_ERRN                ; informa el error
    SALTO_LINEA                             ; nueva linea
    JMP PEDIR_N                             ; repite la pregunta

N_VALIDO:                                   ; N es valido
    MOV CANTIDAD, AX                        ; guarda N
    MOV SI, OFFSET VECTOR                   ; SI = inicio de VECTOR
    MOV CX, CANTIDAD                        ; CX = N digitos a leer
    CALL LEER_DIGITOS_VECTOR                ; lee N digitos 0..9

    IMPRIMIR_CADENA MSG_VEC                 ; muestra etiqueta
    MOV SI, OFFSET VECTOR                   ; SI = inicio de VECTOR
    MOV CX, CANTIDAD                        ; CX = N
    CALL MOSTRAR_VECTOR                     ; muestra los digitos cargados
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LEER_DIGITOS_VECTOR ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LEER_DIGITOS_VECTOR
;   Entrada : SI = offset del vector destino (DW), CX = cantidad de digitos.
;   Salida  : llena el vector con CX valores numericos en [0, 9].
;   Requiere: macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, SALTO_LINEA, LEER_DIGITO
;             y mensajes MSG_DIG1, MSG_DIG2 en DATOS.
;   Modifica: solo el contenido del vector (conserva AX, BX, CX, SI).
;------------------------------------------------------------------------------
LEER_DIGITOS_VECTOR PROC                    ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (indice humano 1..N)
    PUSH CX                                 ; guarda CX (contador)
    PUSH SI                                 ; guarda SI (puntero al vector)
    CMP CX, 0                               ; N = 0?
    JE LDV_FIN                              ; si: no lee nada
    MOV BX, 1                               ; numero de digito mostrado (1..N)
LDV_CICLO:                                  ; ciclo para leer cada digito
    IMPRIMIR_CADENA MSG_DIG1                ; imprime "Digito "
    IMPRIMIR_NUMERO BX                      ; imprime el numero de orden
    IMPRIMIR_CADENA MSG_DIG2                ; imprime " (0-9): "
    LEER_DIGITO                             ; AX = valor 0..9 (rechaza otras)
    SALTO_LINEA                             ; baja de linea tras el digito
    MOV [SI], AX                            ; guarda el digito en el vector
    ADD SI, 2                               ; avanza a la siguiente palabra
    INC BX                                  ; incrementa el numero mostrado
    LOOP LDV_CICLO                          ; repite CX veces
LDV_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LEER_DIGITOS_VECTOR ENDP                    ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LEER_DIGITOS_VECTOR ======

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
