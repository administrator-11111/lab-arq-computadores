;==============================================================================
; ARCHIVO       : merge_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento por mezcla (Merge Sort) recursivo para vectores
;                 de palabras (DW) sin signo (0..65535), controlado por la
;                 variable SENTIDO (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: Estrategia "divide y venceras":
;                 1) Si el subarreglo tiene 0 o 1 elemento (izq >= der), ya
;                    esta ordenado (caso base).
;                 2) Calcula medio = (izq + der) / 2 y ordena recursivamente
;                    la mitad izquierda [izq..medio] y la derecha
;                    [medio+1..der], guardando en la pila (PUSH/POP) los
;                    limites de cada llamada recursiva.
;                 3) Mezcla ambas mitades ya ordenadas en un vector auxiliar
;                    MS_AUX del mismo tamano maximo, comparando elemento a
;                    elemento segun SENTIDO, y copia el resultado de vuelta al
;                    vector original.
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 1):
;                   Divide  : [5,2] y [8,1] -> [5],[2] y [8],[1]
;                   Mezcla 1: [5] + [2] -> [2,5]  ;  [8] + [1] -> [1,8]
;                   Mezcla 2: [2,5] + [1,8] -> [1,2,5,8]
;
;                 Uso de pila y memoria en 8086:
;                 - Cada nivel recursivo apila 4 palabras (dir. retorno + AX +
;                   BX + DX). Con 256 palabras en PILA se soportan vectores
;                   muy grandes (profundidad log2(N) es muy pequena).
;                 - Requiere MS_AUX en DATOS con capacidad >= N elementos DW.
; REGISTROS     : Entrada  : SI = offset del vector (DW), CX = cantidad
;                 Salida   : vector ordenado en memoria
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0, MS_AUX DW 50 DUP(0), MS_BASE DW 0,
;                 MS_LIM_I DW 0, MS_LIM_J DW 0 en DATOS
; DEPENDENCIAS  : Ninguna para MERGE_SORT. La demo usa macros de E/S de
;                 utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                 y MOSTRAR_VECTOR de procedimientos canonicos.
; COMO INTEGRAR : 1. Declarar SENTIDO, MS_AUX (tamano >= N), MS_BASE, MS_LIM_I
;                    y MS_LIM_J en DATOS.
;                 2. Copiar el bloque MERGE_SORT (incluye MS_DIVIDIR y
;                    MS_MEZCLAR) en CODIGO despues de la salida a DOS.
;                 3. Cargar SENTIDO, SI = offset, CX = cantidad y ejecutar
;                    CALL MERGE_SORT.
; EJEMPLO       : Vector original     : 38 27 43 3 9 82 10 27
;                 Ordenado ascendente : 3 9 10 27 27 38 43 82
;                 Ordenado descendente: 82 43 38 27 27 10 9 3
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
    MSG_TITULO DB '=== DEMO: MERGE SORT (MEZCLA) ===$' ; titulo de la demo
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR     DW 38, 27, 43, 3, 9, 82, 10, 27 ; vector de prueba con repetido
    N_ELEM     DW 8                         ; cantidad de elementos del vector
    SENTIDO    DB 0                         ; 0 = ascendente, 1 = descendente
    MS_AUX     DW 50 DUP(0)                 ; vector auxiliar para la mezcla
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

    IMPRIMIR_CADENA MSG_ORIG                ; muestra etiqueta de original
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector original
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; elige orden ascendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MERGE_SORT                         ; ordena ascendentemente

    IMPRIMIR_CADENA MSG_ASC                 ; muestra etiqueta ascendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado asc
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; elige orden descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MERGE_SORT                         ; ordena descendentemente

    IMPRIMIR_CADENA MSG_DESC                ; muestra etiqueta descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado desc
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: MERGE_SORT ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO MERGE_SORT
;   Entrada : SI = offset del vector (DW), CX = cantidad de elementos
;             Variables en DATOS: SENTIDO, MS_AUX, MS_BASE, MS_LIM_I, MS_LIM_J
;   Salida  : vector ordenado en memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
MERGE_SORT PROC                             ; inicio del procedimiento publico
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
MERGE_SORT ENDP                             ; fin del procedimiento publico

;------------------------------------------------------------------------------
; PROCEDIMIENTO MS_DIVIDIR (interno, recursivo)
;   Entrada : AX = izq, DX = der (indices logicos 0..N-1)
;------------------------------------------------------------------------------
MS_DIVIDIR PROC                             ; inicio de la recursion
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

;------------------------------------------------------------------------------
; PROCEDIMIENTO MS_MEZCLAR (interno)
;   Entrada : AX = izq, BX = medio, DX = der
;   Mezcla las dos mitades ordenadas en MS_AUX y las copia al vector original.
;------------------------------------------------------------------------------
MS_MEZCLAR PROC                             ; inicio de la mezcla
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
;====== FIN BLOQUE REUTILIZABLE: MERGE_SORT ======

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
