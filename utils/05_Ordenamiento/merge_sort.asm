;==============================================================================
; ARCHIVO       : merge_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento por mezcla (Merge Sort) recursivo en dos
;                 versiones: arreglos de 16 bits (DW, 0..65535) y arreglos de
;                 8 bits (DB, 0..255), sin signo, controlado por SENTIDO
;                 (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: Estrategia "divide y venceras":
;                 1) Si el subarreglo tiene 0 o 1 elemento (izq >= der), ya
;                    esta ordenado (caso base).
;                 2) Calcula medio = (izq + der) / 2 y ordena recursivamente
;                    la mitad izquierda [izq..medio] y la derecha
;                    [medio+1..der], guardando en la pila (PUSH/POP) los
;                    limites de cada llamada.
;                 3) Mezcla ambas mitades ya ordenadas en un vector auxiliar
;                    (MS_AUX para 16 bits o MS_AUX_8 para 8 bits) segun
;                    SENTIDO, y copia el resultado de vuelta al arreglo.
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 1):
;                   Divide  : [5,2] y [8,1] -> [5],[2] y [8],[1]
;                   Mezcla 1: [5]+[2] -> [2,5]  ;  [8]+[1] -> [1,8]
;                   Mezcla 2: [2,5]+[1,8] -> [1,2,5,8]
;
;                 Diferencia 8 bits vs 16 bits en 8086:
;                 - 16 bits (DW): calcula direcciones con SHL reg, 1 (2*idx),
;                   lee/escribe AX/CX, usa MS_AUX DW y avanza ADD reg, 2.
;                 -  8 bits (DB): los indices son directamente desplazamientos
;                   en bytes (sin SHL), lee/escribe AL/CL, usa MS_AUX_8 DB y
;                   avanza INC reg.
; REGISTROS     : Entrada  : SI = offset del vector (DW o DB), CX = cantidad
;                 Salida   : vector ordenado en memoria
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0, MS_BASE DW 0, MS_LIM_I DW 0, MS_LIM_J DW 0,
;                 MS_AUX DW 50 DUP(0) (16b) y/o MS_AUX_8 DB 50 DUP(0) (8b).
; DEPENDENCIAS  : Ninguna para MERGE_SORT / MERGE_SORT_8. La demo usa macros
;                 de E/S y MOSTRAR_VECTOR / MOSTRAR_VECTOR_8.
; COMO INTEGRAR : 1. Declarar SENTIDO, MS_BASE, MS_LIM_I, MS_LIM_J y el vector
;                    auxiliar correspondiente (MS_AUX DW o MS_AUX_8 DB) en
;                    DATOS, mas pila suficiente (DW 256 DUP(0)).
;                 2. Copiar el bloque MERGE_SORT (16b) o MERGE_SORT_8 (8b) en
;                    CODIGO despues de la salida a DOS.
;                 3. Cargar SENTIDO, SI = offset, CX = cantidad y llamar a
;                    CALL MERGE_SORT o CALL MERGE_SORT_8.
; EJEMPLO       : --- 16 bits (DW) ---
;                 Original    : 3800 27 430 3 9 8200 10 27
;                 Ascendente  : 3 9 10 27 27 430 3800 8200
;                 Descendente : 8200 3800 430 27 27 10 9 3
;                 --- 8 bits (DB) ---
;                 Original    : 38 27 143 3 9 252 10 27
;                 Ascendente  : 3 9 10 27 27 38 143 252
;                 Descendente : 252 143 38 27 27 10 9 3
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
    DW 256 DUP(0)                           ; 256 palabras para recursion
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MSG_TITULO DB '=== DEMO: MERGE SORT (16 BITS Y 8 BITS) ===$' ; titulo
    MSG_16     DB '--- Arreglo de 16 bits (DW, 0..65535) ---$' ; subtitulo 16
    MSG_8      DB '--- Arreglo de 8 bits (DB, 0..255) ---$'    ; subtitulo 8
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR_16  DW 3800, 27, 430, 3, 9, 8200, 10, 27 ; arreglo 16 bits (DW)
    N_16       DW 8                         ; cantidad de elementos DW
    VECTOR_8   DB 38, 27, 143, 3, 9, 252, 10, 27 ; arreglo 8 bits (DB)
    N_8        DW 8                         ; cantidad de elementos DB
    SENTIDO    DB 0                         ; 0 = ascendente, 1 = descendente
    MS_AUX     DW 50 DUP(0)                 ; vector auxiliar 16 bits (DW)
    MS_AUX_8   DB 50 DUP(0)                 ; vector auxiliar 8 bits (DB)
    MS_BASE    DW 0                         ; direccion base del vector activo
    MS_LIM_I   DW 0                         ; puntero limite de mitad izq
    MS_LIM_J   DW 0                         ; puntero limite de mitad der
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    ;--- Demostracion 16 bits (DW) ---
    IMPRIMIR_CADENA MSG_16                  ; subtitulo 16 bits
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_ORIG                ; etiqueta original
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo DW
    MOV CX, N_16                            ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra original 16 bits
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente
    CALL MERGE_SORT                         ; ordena DW ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR                     ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL MERGE_SORT                         ; ordena DW descendente
    IMPRIMIR_CADENA MSG_DESC                ; etiqueta descendente
    CALL MOSTRAR_VECTOR                     ; muestra resultado descendente
    SALTO_LINEA                             ; nueva linea

    ;--- Demostracion 8 bits (DB) ---
    IMPRIMIR_CADENA MSG_8                   ; subtitulo 8 bits
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_ORIG                ; etiqueta original
    MOV SI, OFFSET VECTOR_8                 ; SI = arreglo DB
    MOV CX, N_8                             ; CX = cantidad
    CALL MOSTRAR_VECTOR_8                   ; muestra original 8 bits
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente
    CALL MERGE_SORT_8                       ; ordena DB ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL MERGE_SORT_8                       ; ordena DB descendente
    IMPRIMIR_CADENA MSG_DESC                ; etiqueta descendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado descendente
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: MERGE_SORT (16 BITS / DW) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO MERGE_SORT
;   Entrada : SI = offset del vector de 16 bits (DW), CX = cantidad
;             Variables en DATOS: SENTIDO, MS_AUX, MS_BASE, MS_LIM_I, MS_LIM_J
;   Salida  : vector ordenado en memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
MERGE_SORT PROC                             ; inicio del procedimiento 16 bits
    PUSH AX                                 ; guarda AX (indice izq)
    PUSH BX                                 ; guarda BX (indice medio)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (indice der)
    PUSH SI                                 ; guarda SI (offset vector)
    PUSH DI                                 ; guarda DI

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE MS_FIN                              ; si: ya esta ordenado, termina

    MOV MS_BASE, SI                         ; guarda direccion base del vector
    XOR AX, AX                              ; izq = 0
    MOV DX, CX                              ; DX = N
    DEC DX                                  ; der = N - 1
    CALL MS_DIVIDIR                         ; inicia division recursiva

MS_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MERGE_SORT ENDP                             ; fin del procedimiento 16 bits

MS_DIVIDIR PROC                             ; recursion 16 bits
    CMP AX, DX                              ; subarreglo de 0 o 1 elemento?
    JAE MS_DIV_FIN                          ; si: caso base, retorna

    MOV BX, AX                              ; BX = izq
    ADD BX, DX                              ; BX = izq + der
    SHR BX, 1                               ; BX = medio = (izq + der) / 2

    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda medio en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV DX, BX                              ; ordena mitad izq [izq..medio]
    CALL MS_DIVIDIR                         ; llamada recursiva izquierda
    POP DX                                  ; recupera der
    POP BX                                  ; recupera medio
    POP AX                                  ; recupera izq

    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda medio en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV AX, BX                              ; AX = medio
    INC AX                                  ; AX = medio + 1
    CALL MS_DIVIDIR                         ; llamada recursiva derecha
    POP DX                                  ; recupera der
    POP BX                                  ; recupera medio
    POP AX                                  ; recupera izq

    CALL MS_MEZCLAR                         ; mezcla [izq..medio] y [med+1..der]

MS_DIV_FIN:                                 ; fin de la llamada recursiva
    RET                                     ; vuelve al nivel anterior
MS_DIVIDIR ENDP                             ; fin de MS_DIVIDIR

MS_MEZCLAR PROC                             ; mezcla 16 bits usando MS_AUX
    PUSH AX                                 ; guarda izq
    PUSH BX                                 ; guarda medio
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda der
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI

    PUSH AX                                 ; conserva izq para copia final
    PUSH DX                                 ; conserva der para copia final

    MOV SI, AX                              ; SI = izq
    SHL SI, 1                               ; SI = 2 * izq (bytes)
    ADD SI, MS_BASE                         ; SI apunta a v[izq]

    MOV CX, BX                              ; CX = medio
    SHL CX, 1                               ; CX = 2 * medio
    ADD CX, MS_BASE                         ; CX apunta a v[medio]
    MOV MS_LIM_I, CX                        ; guarda limite de la mitad izq

    MOV DI, CX                              ; DI = direccion de v[medio]
    ADD DI, 2                               ; DI apunta a v[medio+1]

    MOV CX, DX                              ; CX = der
    SHL CX, 1                               ; CX = 2 * der
    ADD CX, MS_BASE                         ; CX apunta a v[der]
    MOV MS_LIM_J, CX                        ; guarda limite de la mitad der

    MOV BX, OFFSET MS_AUX                   ; BX apunta al inicio de MS_AUX

MS_MEZ_CICLO:                               ; compara cabezas de ambas mitades
    CMP SI, MS_LIM_I                        ; se acabo la mitad izquierda?
    JA MS_COPIAR_DER                        ; si: copiar lo que queda de der
    CMP DI, MS_LIM_J                        ; se acabo la mitad derecha?
    JA MS_COPIAR_IZQ                        ; si: copiar lo que queda de izq

    MOV AX, [SI]                            ; AX = elemento actual mitad izq
    MOV CX, [DI]                            ; CX = elemento actual mitad der
    CMP SENTIDO, 0                          ; orden ascendente?
    JNE MS_MEZ_DESC                         ; no: comparar para descendente
    CMP AX, CX                              ; ascendente: izq <= der?
    JBE MS_TOMAR_IZQ                        ; si: tomar de mitad izquierda
    JMP MS_TOMAR_DER                        ; no: tomar de mitad derecha

MS_MEZ_DESC:                                ; comparacion para descendente
    CMP AX, CX                              ; descendente: izq >= der?
    JAE MS_TOMAR_IZQ                        ; si: tomar de mitad izquierda

MS_TOMAR_DER:                               ; copia elemento de mitad derecha
    MOV [BX], CX                            ; guarda en MS_AUX
    ADD DI, 2                               ; avanza puntero mitad derecha
    ADD BX, 2                               ; avanza puntero de MS_AUX
    JMP MS_MEZ_CICLO                        ; continua mezclando

MS_TOMAR_IZQ:                               ; copia elemento de mitad izquierda
    MOV [BX], AX                            ; guarda en MS_AUX
    ADD SI, 2                               ; avanza puntero mitad izquierda
    ADD BX, 2                               ; avanza puntero de MS_AUX
    JMP MS_MEZ_CICLO                        ; continua mezclando

MS_COPIAR_IZQ:                              ; copia sobrantes de mitad izquierda
    CMP SI, MS_LIM_I                        ; quedan elementos en izq?
    JA MS_COPIAR_VUELTA                     ; no: pasar a copiar de vuelta
    MOV AX, [SI]                            ; lee elemento sobrante
    MOV [BX], AX                            ; escribe en MS_AUX
    ADD SI, 2                               ; siguiente en mitad izquierda
    ADD BX, 2                               ; siguiente en MS_AUX
    JMP MS_COPIAR_IZQ                       ; repite hasta vaciar izq

MS_COPIAR_DER:                              ; copia sobrantes de mitad derecha
    CMP DI, MS_LIM_J                        ; quedan elementos en der?
    JA MS_COPIAR_VUELTA                     ; no: pasar a copiar de vuelta
    MOV AX, [DI]                            ; lee elemento sobrante
    MOV [BX], AX                            ; escribe en MS_AUX
    ADD DI, 2                               ; siguiente en mitad derecha
    ADD BX, 2                               ; siguiente en MS_AUX
    JMP MS_COPIAR_DER                       ; repite hasta vaciar der

MS_COPIAR_VUELTA:                           ; copia MS_AUX -> v[izq..der]
    POP DX                                  ; recupera der
    POP AX                                  ; recupera izq
    MOV CX, DX                              ; CX = der
    SUB CX, AX                              ; CX = der - izq
    INC CX                                  ; CX = cantidad = der - izq + 1
    MOV DI, AX                              ; DI = izq
    SHL DI, 1                               ; DI = 2 * izq
    ADD DI, MS_BASE                         ; DI apunta a v[izq]
    MOV SI, OFFSET MS_AUX                   ; SI apunta al inicio de MS_AUX

MS_VUELTA_CICLO:                            ; copia palabra por palabra
    MOV AX, [SI]                            ; lee desde MS_AUX
    MOV [DI], AX                            ; escribe en el vector original
    ADD SI, 2                               ; siguiente palabra en MS_AUX
    ADD DI, 2                               ; siguiente palabra en vector
    LOOP MS_VUELTA_CICLO                    ; repite CX veces

    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve a MS_DIVIDIR
MS_MEZCLAR ENDP                             ; fin de MS_MEZCLAR
;====== FIN BLOQUE REUTILIZABLE: MERGE_SORT (16 BITS / DW) ======

;====== INICIO BLOQUE REUTILIZABLE: MERGE_SORT_8 (8 BITS / DB) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO MERGE_SORT_8
;   Entrada : SI = offset del vector de 8 bits (DB), CX = cantidad
;             Variables en DATOS: SENTIDO, MS_AUX_8, MS_BASE, MS_LIM_I, MS_LIM_J
;   Salida  : vector ordenado en memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
MERGE_SORT_8 PROC                           ; inicio del procedimiento 8 bits
    PUSH AX                                 ; guarda AX (indice izq)
    PUSH BX                                 ; guarda BX (indice medio)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (indice der)
    PUSH SI                                 ; guarda SI (offset vector)
    PUSH DI                                 ; guarda DI

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE MS8_FIN                             ; si: ya esta ordenado, termina

    MOV MS_BASE, SI                         ; guarda direccion base del vector
    XOR AX, AX                              ; izq = 0
    MOV DX, CX                              ; DX = N
    DEC DX                                  ; der = N - 1
    CALL MS8_DIVIDIR                        ; inicia division recursiva

MS8_FIN:                                    ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MERGE_SORT_8 ENDP                           ; fin del procedimiento 8 bits

MS8_DIVIDIR PROC                            ; recursion 8 bits
    CMP AX, DX                              ; subarreglo de 0 o 1 elemento?
    JAE MS8_DIV_FIN                         ; si: caso base, retorna

    MOV BX, AX                              ; BX = izq
    ADD BX, DX                              ; BX = izq + der
    SHR BX, 1                               ; BX = medio = (izq + der) / 2

    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda medio en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV DX, BX                              ; ordena mitad izq [izq..medio]
    CALL MS8_DIVIDIR                        ; llamada recursiva izquierda
    POP DX                                  ; recupera der
    POP BX                                  ; recupera medio
    POP AX                                  ; recupera izq

    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda medio en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV AX, BX                              ; AX = medio
    INC AX                                  ; AX = medio + 1
    CALL MS8_DIVIDIR                        ; llamada recursiva derecha
    POP DX                                  ; recupera der
    POP BX                                  ; recupera medio
    POP AX                                  ; recupera izq

    CALL MS8_MEZCLAR                        ; mezcla ambas mitades en MS_AUX_8

MS8_DIV_FIN:                                ; fin de la llamada recursiva
    RET                                     ; vuelve al nivel anterior
MS8_DIVIDIR ENDP                            ; fin de MS8_DIVIDIR

MS8_MEZCLAR PROC                            ; mezcla 8 bits usando MS_AUX_8
    PUSH AX                                 ; guarda izq
    PUSH BX                                 ; guarda medio
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda der
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI

    PUSH AX                                 ; conserva izq para copia final
    PUSH DX                                 ; conserva der para copia final

    MOV SI, AX                              ; SI = izq (1 byte por elemento)
    ADD SI, MS_BASE                         ; SI apunta a v[izq]

    MOV CX, BX                              ; CX = medio
    ADD CX, MS_BASE                         ; CX apunta a v[medio]
    MOV MS_LIM_I, CX                        ; guarda limite de mitad izq

    MOV DI, CX                              ; DI = direccion de v[medio]
    INC DI                                  ; DI apunta a v[medio+1] (1 byte)

    MOV CX, DX                              ; CX = der
    ADD CX, MS_BASE                         ; CX apunta a v[der]
    MOV MS_LIM_J, CX                        ; guarda limite de mitad der

    MOV BX, OFFSET MS_AUX_8                 ; BX apunta al inicio de MS_AUX_8

MS8_MEZ_CICLO:                              ; compara cabezas de ambas mitades
    CMP SI, MS_LIM_I                        ; se acabo la mitad izquierda?
    JA MS8_COPIAR_DER                       ; si: copiar lo que queda de der
    CMP DI, MS_LIM_J                        ; se acabo la mitad derecha?
    JA MS8_COPIAR_IZQ                       ; si: copiar lo que queda de izq

    MOV AL, [SI]                            ; AL = byte actual mitad izq
    MOV CL, [DI]                            ; CL = byte actual mitad der
    CMP SENTIDO, 0                          ; orden ascendente?
    JNE MS8_MEZ_DESC                        ; no: comparar para descendente
    CMP AL, CL                              ; ascendente: izq <= der?
    JBE MS8_TOMAR_IZQ                       ; si: tomar de mitad izquierda
    JMP MS8_TOMAR_DER                       ; no: tomar de mitad derecha

MS8_MEZ_DESC:                               ; comparacion para descendente
    CMP AL, CL                              ; descendente: izq >= der?
    JAE MS8_TOMAR_IZQ                       ; si: tomar de mitad izquierda

MS8_TOMAR_DER:                              ; copia byte de mitad derecha
    MOV [BX], CL                            ; guarda en MS_AUX_8
    INC DI                                  ; avanza puntero mitad derecha
    INC BX                                  ; avanza puntero de MS_AUX_8
    JMP MS8_MEZ_CICLO                       ; continua mezclando

MS8_TOMAR_IZQ:                              ; copia byte de mitad izquierda
    MOV [BX], AL                            ; guarda en MS_AUX_8
    INC SI                                  ; avanza puntero mitad izquierda
    INC BX                                  ; avanza puntero de MS_AUX_8
    JMP MS8_MEZ_CICLO                       ; continua mezclando

MS8_COPIAR_IZQ:                             ; copia sobrantes de mitad izq
    CMP SI, MS_LIM_I                        ; quedan bytes en izq?
    JA MS8_COPIAR_VUELTA                    ; no: pasar a copiar de vuelta
    MOV AL, [SI]                            ; lee byte sobrante
    MOV [BX], AL                            ; escribe en MS_AUX_8
    INC SI                                  ; siguiente en mitad izquierda
    INC BX                                  ; siguiente en MS_AUX_8
    JMP MS8_COPIAR_IZQ                      ; repite hasta vaciar izq

MS8_COPIAR_DER:                             ; copia sobrantes de mitad der
    CMP DI, MS_LIM_J                        ; quedan bytes en der?
    JA MS8_COPIAR_VUELTA                    ; no: pasar a copiar de vuelta
    MOV AL, [DI]                            ; lee byte sobrante
    MOV [BX], AL                            ; escribe en MS_AUX_8
    INC DI                                  ; siguiente en mitad derecha
    INC BX                                  ; siguiente en MS_AUX_8
    JMP MS8_COPIAR_DER                      ; repite hasta vaciar der

MS8_COPIAR_VUELTA:                          ; copia MS_AUX_8 -> v[izq..der]
    POP DX                                  ; recupera der
    POP AX                                  ; recupera izq
    MOV CX, DX                              ; CX = der
    SUB CX, AX                              ; CX = der - izq
    INC CX                                  ; CX = cantidad = der - izq + 1
    MOV DI, AX                              ; DI = izq (sin SHL, 1 byte)
    ADD DI, MS_BASE                         ; DI apunta a v[izq]
    MOV SI, OFFSET MS_AUX_8                 ; SI apunta al inicio de MS_AUX_8

MS8_VUELTA_CICLO:                           ; copia byte por byte
    MOV AL, [SI]                            ; lee desde MS_AUX_8
    MOV [DI], AL                            ; escribe en el vector original
    INC SI                                  ; siguiente byte en MS_AUX_8
    INC DI                                  ; siguiente byte en vector
    LOOP MS8_VUELTA_CICLO                   ; repite CX veces

    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve a MS8_DIVIDIR
MS8_MEZCLAR ENDP                            ; fin de MS8_MEZCLAR
;====== FIN BLOQUE REUTILIZABLE: MERGE_SORT_8 (8 BITS / DB) ======

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
