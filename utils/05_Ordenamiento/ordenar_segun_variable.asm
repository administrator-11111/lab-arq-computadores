;==============================================================================
; ARCHIVO       : ordenar_segun_variable.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Rutinas de referencia ORDENAR_SEGUN_SENTIDO (16 bits / DW) y
;                 ORDENAR_SEGUN_SENTIDO_8 (8 bits / DB) que ordenan un arreglo
;                 sin signo en orden ascendente o descendente segun la variable
;                 SENTIDO en DATOS (0 = ascendente, 1 = descendente), usando
;                 Bubble Sort con bandera de parada anticipada como base.
; FUNCIONAMIENTO: En lugar de duplicar el algoritmo para ascendente y
;                 descendente, cada rutina consulta SENTIDO DB en cada
;                 comparacion de elementos adyacentes:
;                   - Si SENTIDO = 0: intercambia cuando v[j] > v[j+1].
;                   - Si SENTIDO = 1: intercambia cuando v[j] < v[j+1].
;                 La demo muestra un vector de 16 bits (DW) y otro de 8 bits
;                 (DB), pide elegir el sentido por teclado (0 o 1), guarda la
;                 eleccion en SENTIDO y ordena ambos arreglos.
; REGISTROS     : Entrada  : SI = offset del vector (DW o DB), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0  (0 = ascendente, 1 = descendente) en DATOS
; DEPENDENCIAS  : Ninguna para las rutinas. La demo usa macros de E/S y
;                 MOSTRAR_VECTOR / MOSTRAR_VECTOR_8.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0 en DATOS.
;                 2. Copiar ORDENAR_SEGUN_SENTIDO (DW) o
;                    ORDENAR_SEGUN_SENTIDO_8 (DB) en CODIGO despues de la
;                    salida a DOS.
;                 3. Asignar 0 o 1 a SENTIDO, cargar SI = offset, CX = cantidad
;                    y llamar al procedimiento correspondiente.
; EJEMPLO       : Vector 16b original: 3400 12 890 5 470 12 6300 1
;                 Vector  8b original: 34 12 189 5 47 12 243 1
;                 Elija sentido (0 = ascendente, 1 = descendente): 1
;                 Vector 16b ordenado (desc): 6300 3400 890 470 12 12 5 1
;                 Vector  8b ordenado (desc): 243 189 47 34 12 12 5 1
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

LEER_CARACTER MACRO                         ; macro sin parametros
    MOV AH, 01h                             ; servicio 01h: leer tecla + eco
    INT 21h                                 ; DOS espera la tecla, AL = ASCII
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MSG_TITULO DB '=== DEMO: ORDENAR SEGUN VARIABLE (16B Y 8B) ===$' ; tit
    MSG_O16    DB 'Vector 16b original       : $' ; etiqueta original 16 bits
    MSG_O8     DB 'Vector  8b original       : $' ; etiqueta original 8 bits
    MSG_PEDIR  DB 'Elija sentido (0 = ascendente, 1 = descendente): $' ; menu
    MSG_A16    DB 'Vector 16b ordenado (asc) : $' ; etiqueta 16b asc
    MSG_D16    DB 'Vector 16b ordenado (desc): $' ; etiqueta 16b desc
    MSG_A8     DB 'Vector  8b ordenado (asc) : $' ; etiqueta 8b asc
    MSG_D8     DB 'Vector  8b ordenado (desc): $' ; etiqueta 8b desc
    VECTOR_16  DW 3400, 12, 890, 5, 470, 12, 6300, 1 ; arreglo 16 bits (DW)
    N_16       DW 8                         ; cantidad de elementos DW
    VECTOR_8   DB 34, 12, 189, 5, 47, 12, 243, 1 ; arreglo 8 bits (DB)
    N_8        DW 8                         ; cantidad de elementos DB
    SENTIDO    DB 0                         ; 0 = ascendente, 1 = descendente
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_O16                 ; muestra original 16 bits
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo DW
    MOV CX, N_16                            ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; imprime vector 16 bits
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_O8                  ; muestra original 8 bits
    MOV SI, OFFSET VECTOR_8                 ; SI = arreglo DB
    MOV CX, N_8                             ; CX = cantidad
    CALL MOSTRAR_VECTOR_8                   ; imprime vector 8 bits
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PEDIR               ; solicita el sentido al usuario
PEDIR_OPCION:                               ; valida que la tecla sea '0' o '1'
    LEER_CARACTER                           ; AL = tecla presionada
    CMP AL, '0'                             ; eligio '0' (ascendente)?
    JE OPCION_VALIDA                        ; si: acepta la opcion
    CMP AL, '1'                             ; eligio '1' (descendente)?
    JNE PEDIR_OPCION                        ; no: vuelve a pedir tecla

OPCION_VALIDA:                              ; guarda la eleccion en SENTIDO
    SUB AL, '0'                             ; convierte '0'/'1' a 0/1
    MOV SENTIDO, AL                         ; configura la variable SENTIDO
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VECTOR_16                ; ordena vector 16 bits
    MOV CX, N_16                            ; CX = cantidad
    CALL ORDENAR_SEGUN_SENTIDO              ; ordena DW segun SENTIDO

    MOV SI, OFFSET VECTOR_8                 ; ordena vector 8 bits
    MOV CX, N_8                             ; CX = cantidad
    CALL ORDENAR_SEGUN_SENTIDO_8            ; ordena DB segun SENTIDO

    CMP SENTIDO, 0                          ; se ordeno ascendentemente?
    JNE MOSTRAR_DESC                        ; no: mostrar etiquetas desc
    IMPRIMIR_CADENA MSG_A16                 ; etiqueta 16b asc
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo DW
    MOV CX, N_16                            ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra DW ordenado
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_A8                  ; etiqueta 8b asc
    MOV SI, OFFSET VECTOR_8                 ; SI = arreglo DB
    MOV CX, N_8                             ; CX = cantidad
    CALL MOSTRAR_VECTOR_8                   ; muestra DB ordenado
    JMP FIN_DEMO                            ; salta al final

MOSTRAR_DESC:                               ; muestra resultados descendentes
    IMPRIMIR_CADENA MSG_D16                 ; etiqueta 16b desc
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo DW
    MOV CX, N_16                            ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra DW ordenado
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_D8                  ; etiqueta 8b desc
    MOV SI, OFFSET VECTOR_8                 ; SI = arreglo DB
    MOV CX, N_8                             ; CX = cantidad
    CALL MOSTRAR_VECTOR_8                   ; muestra DB ordenado

FIN_DEMO:                                   ; cierre comun
    SALTO_LINEA                             ; nueva linea
    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: ORDENAR_SEGUN_SENTIDO (16 BITS / DW) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ORDENAR_SEGUN_SENTIDO
;   Entrada : SI = offset del vector de 16 bits (DW), CX = cantidad
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
ORDENAR_SEGUN_SENTIDO PROC                  ; inicio del procedimiento 16 bits
    PUSH AX                                 ; guarda AX (elemento actual)
    PUSH BX                                 ; guarda BX (BL = bandera swap)
    PUSH CX                                 ; guarda CX (contadores)
    PUSH DX                                 ; guarda DX (elemento siguiente)
    PUSH SI                                 ; guarda SI (inicio del vector)
    PUSH DI                                 ; guarda DI (puntero interno)

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE OSS_FIN                             ; si: ya esta ordenado, termina
    DEC CX                                  ; CX = N - 1 pasadas maximas

OSS_PASADA:                                 ; inicio de una pasada completa
    XOR BL, BL                              ; BL = 0 (aun no hubo intercambio)
    MOV DI, SI                              ; DI apunta al primer elemento
    PUSH CX                                 ; guarda contador de pasadas

OSS_COMPARAR:                               ; recorre pares adyacentes
    MOV AX, [DI]                            ; AX = v[j] (16 bits)
    MOV DX, [DI+2]                          ; DX = v[j+1] (2 bytes adelante)
    CMP SENTIDO, 0                          ; orden ascendente?
    JNE OSS_DESC                            ; no: verificar orden descendente
    CMP AX, DX                              ; ascendente: v[j] <= v[j+1]?
    JBE OSS_SIGUIENTE                       ; si: ya estan en orden
    JMP OSS_INTERCAMBIAR                    ; no: intercambiar ambos

OSS_DESC:                                   ; comparacion para orden descendente
    CMP AX, DX                              ; descendente: v[j] >= v[j+1]?
    JAE OSS_SIGUIENTE                       ; si: ya estan en orden

OSS_INTERCAMBIAR:                           ; intercambia v[j] y v[j+1]
    MOV [DI], DX                            ; guarda el segundo en v[j]
    MOV [DI+2], AX                          ; guarda el primero en v[j+1]
    MOV BL, 1                               ; marca que hubo al menos un swap

OSS_SIGUIENTE:                              ; avanza al siguiente par
    ADD DI, 2                               ; siguiente palabra (2 bytes)
    LOOP OSS_COMPARAR                       ; repite CX veces en esta pasada

    POP CX                                  ; recupera contador de pasadas
    CMP BL, 0                               ; hubo algun intercambio?
    JE OSS_FIN                              ; no: el vector ya esta ordenado
    LOOP OSS_PASADA                         ; siguiente pasada

OSS_FIN:                                    ; salida comun del procedimiento
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ORDENAR_SEGUN_SENTIDO ENDP                  ; fin del procedimiento 16 bits
;====== FIN BLOQUE REUTILIZABLE: ORDENAR_SEGUN_SENTIDO (16 BITS / DW) ======

;====== INICIO BLOQUE REUTILIZABLE: ORDENAR_SEGUN_SENTIDO_8 (8 BITS / DB) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ORDENAR_SEGUN_SENTIDO_8
;   Entrada : SI = offset del vector de 8 bits (DB), CX = cantidad
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
ORDENAR_SEGUN_SENTIDO_8 PROC                ; inicio del procedimiento 8 bits
    PUSH AX                                 ; guarda AX (AL = byte actual)
    PUSH BX                                 ; guarda BX (BL = bandera swap)
    PUSH CX                                 ; guarda CX (contadores)
    PUSH DX                                 ; guarda DX (DL = byte siguiente)
    PUSH SI                                 ; guarda SI (inicio del vector)
    PUSH DI                                 ; guarda DI (puntero interno)

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE OSS8_FIN                            ; si: ya esta ordenado, termina
    DEC CX                                  ; CX = N - 1 pasadas maximas

OSS8_PASADA:                                ; inicio de una pasada completa
    XOR BL, BL                              ; BL = 0 (aun no hubo intercambio)
    MOV DI, SI                              ; DI apunta al primer byte
    PUSH CX                                 ; guarda contador de pasadas

OSS8_COMPARAR:                              ; recorre pares de bytes adyacentes
    MOV AL, [DI]                            ; AL = v[j] (8 bits)
    MOV DL, [DI+1]                          ; DL = v[j+1] (1 byte adelante)
    CMP SENTIDO, 0                          ; orden ascendente?
    JNE OSS8_DESC                           ; no: verificar orden descendente
    CMP AL, DL                              ; ascendente: v[j] <= v[j+1]?
    JBE OSS8_SIGUIENTE                      ; si: ya estan en orden
    JMP OSS8_INTERCAMBIAR                   ; no: intercambiar ambos bytes

OSS8_DESC:                                  ; comparacion para orden descendente
    CMP AL, DL                              ; descendente: v[j] >= v[j+1]?
    JAE OSS8_SIGUIENTE                      ; si: ya estan en orden

OSS8_INTERCAMBIAR:                          ; intercambia v[j] y v[j+1]
    MOV [DI], DL                            ; guarda el segundo byte en v[j]
    MOV [DI+1], AL                          ; guarda el primero en v[j+1]
    MOV BL, 1                               ; marca que hubo al menos un swap

OSS8_SIGUIENTE:                             ; avanza al siguiente par
    INC DI                                  ; siguiente byte (1 byte)
    LOOP OSS8_COMPARAR                      ; repite CX veces en esta pasada

    POP CX                                  ; recupera contador de pasadas
    CMP BL, 0                               ; hubo algun intercambio?
    JE OSS8_FIN                             ; no: el vector ya esta ordenado
    LOOP OSS8_PASADA                        ; siguiente pasada

OSS8_FIN:                                   ; salida comun del procedimiento
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ORDENAR_SEGUN_SENTIDO_8 ENDP                ; fin del procedimiento 8 bits
;====== FIN BLOQUE REUTILIZABLE: ORDENAR_SEGUN_SENTIDO_8 (8 BITS / DB) ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_VECTOR (16 bits / DW)
;------------------------------------------------------------------------------
MOSTRAR_VECTOR PROC                         ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    CMP CX, 0                               ; vector vacio?
    JE MV_FIN                               ; si: no hay nada que mostrar
MV_CICLO:                                   ; recorre el vector DW
    MOV AX, [SI]                            ; AX = elemento actual (16 bits)
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

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_VECTOR_8 (8 bits / DB)
;------------------------------------------------------------------------------
MOSTRAR_VECTOR_8 PROC                       ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    CMP CX, 0                               ; vector vacio?
    JE MV8_FIN                              ; si: no hay nada que mostrar
MV8_CICLO:                                  ; recorre el vector DB
    MOV AL, [SI]                            ; AL = elemento actual (8 bits)
    MOV AH, 0                               ; extiende sin signo a 16 bits
    IMPRIMIR_NUMERO AX                      ; lo muestra
    IMPRIMIR_ESPACIO                        ; separador
    INC SI                                  ; siguiente elemento (1 byte)
    LOOP MV8_CICLO                          ; repite CX veces
MV8_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MOSTRAR_VECTOR_8 ENDP                       ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
