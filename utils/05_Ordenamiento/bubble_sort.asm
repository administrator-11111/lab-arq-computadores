;==============================================================================
; ARCHIVO       : bubble_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento por metodo de burbuja (Bubble Sort) en dos
;                 versiones: arreglos de 16 bits (DW, 0..65535) y arreglos de
;                 8 bits (DB, 0..255), sin signo. Ambas incluyen bandera de
;                 "hubo intercambio" para terminar antes y variable SENTIDO
;                 (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: En cada pasada recorre los elementos adyacentes v[j] y
;                 v[j+1]. Si estan fuera de orden segun SENTIDO, los
;                 intercambia y activa la bandera BL = 1. Al final de la
;                 pasada el elemento extremo queda en su posicion definitiva.
;                 Si una pasada completa no hace intercambios (BL = 0), el
;                 vector ya esta ordenado y el algoritmo termina antes.
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 1):
;                   Pasada 1 (3 comp): [2,5,8,1] -> [2,5,8,1] -> [2,5,1,8]
;                   Pasada 2 (2 comp): [2,5,1,8] -> [2,1,5,8]
;                   Pasada 3 (1 comp): [1,2,5,8]
;
;                 Diferencia 8 bits vs 16 bits en 8086:
;                 - 16 bits (DW): usa AX/DX, vecino [DI+2], avanza ADD DI, 2.
;                 -  8 bits (DB): usa AL/DL, vecino [DI+1], avanza INC DI.
; REGISTROS     : Entrada  : SI = offset del vector (DW o DB), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0  (0 = ascendente, 1 = descendente) en DATOS
; DEPENDENCIAS  : Ninguna para BUBBLE_SORT / BUBBLE_SORT_8. La demo usa macros
;                 de E/S de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                 y MOSTRAR_VECTOR / MOSTRAR_VECTOR_8.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0 en DATOS.
;                 2. Copiar BUBBLE_SORT (para DW) o BUBBLE_SORT_8 (para DB) en
;                    CODIGO despues de la salida a DOS.
;                 3. Cargar SENTIDO (0 o 1), SI = offset, CX = cantidad y
;                    llamar a CALL BUBBLE_SORT o CALL BUBBLE_SORT_8.
; EJEMPLO       : --- 16 bits (DW) ---
;                 Original    : 1024 15 880 15 3 65000 270 8
;                 Ascendente  : 3 8 15 15 270 880 1024 65000
;                 Descendente : 65000 1024 880 270 15 15 8 3
;                 --- 8 bits (DB) ---
;                 Original    : 200 15 88 15 3 255 27 8
;                 Ascendente  : 3 8 15 15 27 88 200 255
;                 Descendente : 255 200 88 27 15 15 8 3
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

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MSG_TITULO DB '=== DEMO: BUBBLE SORT (16 BITS Y 8 BITS) ===$' ; titulo
    MSG_16     DB '--- Arreglo de 16 bits (DW, 0..65535) ---$' ; subtitulo 16
    MSG_8      DB '--- Arreglo de 8 bits (DB, 0..255) ---$'    ; subtitulo 8
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR_16  DW 1024, 15, 880, 15, 3, 65000, 270, 8 ; arreglo 16 bits (DW)
    N_16       DW 8                         ; cantidad de elementos DW
    VECTOR_8   DB 200, 15, 88, 15, 3, 255, 27, 8 ; arreglo 8 bits (DB)
    N_8        DW 8                         ; cantidad de elementos DB
    SENTIDO    DB 0                         ; 0 = ascendente, 1 = descendente
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo principal
    SALTO_LINEA                             ; nueva linea

    ;--- Demostracion 16 bits (DW) ---
    IMPRIMIR_CADENA MSG_16                  ; subtitulo 16 bits
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_ORIG                ; etiqueta original
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo de 16 bits
    MOV CX, N_16                            ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra original 16 bits
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo de 16 bits
    MOV CX, N_16                            ; CX = cantidad
    CALL BUBBLE_SORT                        ; ordena DW ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR                     ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL BUBBLE_SORT                        ; ordena DW descendente
    IMPRIMIR_CADENA MSG_DESC                ; etiqueta descendente
    CALL MOSTRAR_VECTOR                     ; muestra resultado descendente
    SALTO_LINEA                             ; nueva linea

    ;--- Demostracion 8 bits (DB) ---
    IMPRIMIR_CADENA MSG_8                   ; subtitulo 8 bits
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_ORIG                ; etiqueta original
    MOV SI, OFFSET VECTOR_8                 ; SI = arreglo de 8 bits
    MOV CX, N_8                             ; CX = cantidad
    CALL MOSTRAR_VECTOR_8                   ; muestra original 8 bits
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente
    MOV SI, OFFSET VECTOR_8                 ; SI = arreglo de 8 bits
    MOV CX, N_8                             ; CX = cantidad
    CALL BUBBLE_SORT_8                      ; ordena DB ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL BUBBLE_SORT_8                      ; ordena DB descendente
    IMPRIMIR_CADENA MSG_DESC                ; etiqueta descendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado descendente
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: BUBBLE_SORT (16 BITS / DW) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO BUBBLE_SORT
;   Entrada : SI = offset del vector de 16 bits (DW), CX = cantidad
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
BUBBLE_SORT PROC                            ; inicio del procedimiento 16 bits
    PUSH AX                                 ; guarda AX (elemento actual)
    PUSH BX                                 ; guarda BX (BL = bandera swap)
    PUSH CX                                 ; guarda CX (contadores de pasada)
    PUSH DX                                 ; guarda DX (elemento siguiente)
    PUSH SI                                 ; guarda SI (inicio del vector)
    PUSH DI                                 ; guarda DI (puntero interno)

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE BUB_FIN                             ; si: ya esta ordenado, termina
    DEC CX                                  ; CX = N - 1 pasadas maximas

BUB_PASADA:                                 ; inicio de una pasada completa
    XOR BL, BL                              ; BL = 0 (aun no hubo intercambio)
    MOV DI, SI                              ; DI apunta al primer elemento
    PUSH CX                                 ; guarda pasadas restantes (y comp)

BUB_COMPARAR:                               ; recorre pares adyacentes
    MOV AX, [DI]                            ; AX = v[j] (16 bits)
    MOV DX, [DI+2]                          ; DX = v[j+1] (2 bytes adelante)
    CMP SENTIDO, 0                          ; se pidio orden ascendente?
    JNE BUB_DESC                            ; no: verificar orden descendente
    CMP AX, DX                              ; ascendente: v[j] <= v[j+1]?
    JBE BUB_SIGUIENTE                       ; si: ya estan en orden
    JMP BUB_INTERCAMBIAR                    ; no: intercambiar ambos

BUB_DESC:                                   ; comparacion para orden descendente
    CMP AX, DX                              ; descendente: v[j] >= v[j+1]?
    JAE BUB_SIGUIENTE                       ; si: ya estan en orden

BUB_INTERCAMBIAR:                           ; intercambia v[j] y v[j+1]
    MOV [DI], DX                            ; guarda el segundo en v[j]
    MOV [DI+2], AX                          ; guarda el primero en v[j+1]
    MOV BL, 1                               ; marca que hubo al menos un swap

BUB_SIGUIENTE:                              ; avanza al siguiente par
    ADD DI, 2                               ; siguiente palabra (2 bytes)
    LOOP BUB_COMPARAR                       ; repite CX veces en esta pasada

    POP CX                                  ; recupera contador de pasadas
    CMP BL, 0                               ; hubo algun intercambio?
    JE BUB_FIN                              ; no: el vector ya esta ordenado
    LOOP BUB_PASADA                         ; siguiente pasada (1 comp menos)

BUB_FIN:                                    ; salida comun del procedimiento
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
BUBBLE_SORT ENDP                            ; fin del procedimiento 16 bits
;====== FIN BLOQUE REUTILIZABLE: BUBBLE_SORT (16 BITS / DW) ======

;====== INICIO BLOQUE REUTILIZABLE: BUBBLE_SORT_8 (8 BITS / DB) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO BUBBLE_SORT_8
;   Entrada : SI = offset del vector de 8 bits (DB), CX = cantidad
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
BUBBLE_SORT_8 PROC                          ; inicio del procedimiento 8 bits
    PUSH AX                                 ; guarda AX (AL = elemento actual)
    PUSH BX                                 ; guarda BX (BL = bandera swap)
    PUSH CX                                 ; guarda CX (contadores de pasada)
    PUSH DX                                 ; guarda DX (DL = elemento sig.)
    PUSH SI                                 ; guarda SI (inicio del vector)
    PUSH DI                                 ; guarda DI (puntero interno)

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE BUB8_FIN                            ; si: ya esta ordenado, termina
    DEC CX                                  ; CX = N - 1 pasadas maximas

BUB8_PASADA:                                ; inicio de una pasada completa
    XOR BL, BL                              ; BL = 0 (aun no hubo intercambio)
    MOV DI, SI                              ; DI apunta al primer byte
    PUSH CX                                 ; guarda pasadas restantes

BUB8_COMPARAR:                              ; recorre pares de bytes adyacentes
    MOV AL, [DI]                            ; AL = v[j] (8 bits)
    MOV DL, [DI+1]                          ; DL = v[j+1] (1 byte adelante)
    CMP SENTIDO, 0                          ; se pidio orden ascendente?
    JNE BUB8_DESC                           ; no: verificar orden descendente
    CMP AL, DL                              ; ascendente: v[j] <= v[j+1]?
    JBE BUB8_SIGUIENTE                      ; si: ya estan en orden
    JMP BUB8_INTERCAMBIAR                   ; no: intercambiar ambos bytes

BUB8_DESC:                                  ; comparacion para orden descendente
    CMP AL, DL                              ; descendente: v[j] >= v[j+1]?
    JAE BUB8_SIGUIENTE                      ; si: ya estan en orden

BUB8_INTERCAMBIAR:                          ; intercambia los dos bytes
    MOV [DI], DL                            ; guarda el segundo byte en v[j]
    MOV [DI+1], AL                          ; guarda el primer byte en v[j+1]
    MOV BL, 1                               ; marca que hubo al menos un swap

BUB8_SIGUIENTE:                             ; avanza al siguiente par
    INC DI                                  ; siguiente byte (1 byte)
    LOOP BUB8_COMPARAR                      ; repite CX veces en esta pasada

    POP CX                                  ; recupera contador de pasadas
    CMP BL, 0                               ; hubo algun intercambio?
    JE BUB8_FIN                             ; no: el vector ya esta ordenado
    LOOP BUB8_PASADA                        ; siguiente pasada

BUB8_FIN:                                   ; salida comun del procedimiento
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
BUBBLE_SORT_8 ENDP                          ; fin del procedimiento 8 bits
;====== FIN BLOQUE REUTILIZABLE: BUBBLE_SORT_8 (8 BITS / DB) ======

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
