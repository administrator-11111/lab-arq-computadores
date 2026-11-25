;==============================================================================
; ARCHIVO       : selection_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento por seleccion (Selection Sort) para vectores de
;                 palabras (DW) sin signo (0..65535), controlado por la
;                 variable SENTIDO (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: Para cada posicion i (0..N-2) recorre el resto del vector
;                 buscando la direccion del elemento "mejor" (el minimo si
;                 SENTIDO=0 o el maximo si SENTIDO=1). Al terminar la busqueda,
;                 si el mejor elemento no estaba ya en i, lo intercambia con
;                 v[i]. Asi realiza como maximo N-1 intercambios en total.
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 1):
;                   i=0: minimo en [5,2,8,1] es 1 (pos 3) -> swap -> [1, 2, 8, 5]
;                   i=1: minimo en [2,8,5]   es 2 (pos 1) -> sin swap
;                   i=2: minimo en [8,5]     es 5 (pos 3) -> swap -> [1, 2, 5, 8]
;
;                 Particularidad 8086: se usan punteros directos en memoria:
;                 SI apunta a v[i], BX guarda el puntero al mejor candidato y
;                 DI recorre v[i+1..N-1] avanzando de 2 en 2 bytes.
; REGISTROS     : Entrada  : SI = offset del vector (DW), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0  (0 = ascendente, 1 = descendente) en DATOS
; DEPENDENCIAS  : Ninguna para SELECTION_SORT. La demo usa macros de E/S de
;                 utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                 y MOSTRAR_VECTOR de procedimientos canonicos.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0 en DATOS.
;                 2. Copiar el bloque SELECTION_SORT dentro de CODIGO (despues
;                    de la salida a DOS).
;                 3. Cargar SENTIDO, SI = offset, CX = cantidad y llamar a
;                    CALL SELECTION_SORT.
; EJEMPLO       : Vector original     : 64 25 12 22 11 25 90 5
;                 Ordenado ascendente : 5 11 12 22 25 25 64 90
;                 Ordenado descendente: 90 64 25 25 22 12 11 5
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
    MSG_TITULO DB '=== DEMO: SELECTION SORT (SELECCION) ===$' ; titulo
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR     DW 64, 25, 12, 22, 11, 25, 90, 5 ; vector de prueba con repetido
    N_ELEM     DW 8                         ; cantidad de elementos del vector
    SENTIDO    DB 0                         ; 0 = ascendente, 1 = descendente
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
    CALL SELECTION_SORT                     ; ordena ascendentemente

    IMPRIMIR_CADENA MSG_ASC                 ; muestra etiqueta ascendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado asc
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; elige orden descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL SELECTION_SORT                     ; ordena descendentemente

    IMPRIMIR_CADENA MSG_DESC                ; muestra etiqueta descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado desc
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: SELECTION_SORT ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO SELECTION_SORT
;   Entrada : SI = offset del vector (DW), CX = cantidad de elementos
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
SELECTION_SORT PROC                         ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (candidato v[j])
    PUSH BX                                 ; guarda BX (puntero al mejor)
    PUSH CX                                 ; guarda CX (contadores)
    PUSH DX                                 ; guarda DX (valor del mejor)
    PUSH SI                                 ; guarda SI (puntero a v[i])
    PUSH DI                                 ; guarda DI (puntero a v[j])

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE SEL_FIN                             ; si: ya esta ordenado, termina
    DEC CX                                  ; N - 1 posiciones por fijar

SEL_EXTERNO:                                ; fija el elemento en [SI]
    MOV BX, SI                              ; supone que el mejor es v[i]
    MOV DI, SI                              ; DI inicia en v[i]
    ADD DI, 2                               ; DI apunta a v[i+1]
    PUSH CX                                 ; guarda contador externo (y j)

SEL_BUSCAR:                                 ; busca el mejor en v[i+1..N-1]
    MOV AX, [DI]                            ; AX = candidato v[j]
    MOV DX, [BX]                            ; DX = mejor actual
    CMP SENTIDO, 0                          ; orden ascendente?
    JNE SEL_DESC                            ; no: buscar el mayor
    CMP AX, DX                              ; ascendente: v[j] >= mejor?
    JAE SEL_SIGUIENTE                       ; si: no mejora al minimo
    JMP SEL_ACTUALIZAR                      ; no: v[j] es el nuevo minimo

SEL_DESC:                                   ; comparacion para descendente
    CMP AX, DX                              ; descendente: v[j] <= mejor?
    JBE SEL_SIGUIENTE                       ; si: no mejora al maximo

SEL_ACTUALIZAR:                             ; guarda puntero al nuevo mejor
    MOV BX, DI                              ; BX = direccion del nuevo mejor

SEL_SIGUIENTE:                              ; avanza al siguiente candidato
    ADD DI, 2                               ; siguiente palabra (2 bytes)
    LOOP SEL_BUSCAR                         ; repite CX veces

    POP CX                                  ; recupera contador externo
    CMP BX, SI                              ; el mejor ya estaba en v[i]?
    JE SEL_AVANZAR                          ; si: no hace falta intercambiar
    MOV AX, [SI]                            ; AX = v[i]
    MOV DX, [BX]                            ; DX = v[mejor]
    MOV [SI], DX                            ; v[i] = v[mejor]
    MOV [BX], AX                            ; v[mejor] = v[i] anterior

SEL_AVANZAR:                                ; avanza a la siguiente posicion
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP SEL_EXTERNO                        ; repite para el resto del vector

SEL_FIN:                                    ; salida comun del procedimiento
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
SELECTION_SORT ENDP                         ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: SELECTION_SORT ======

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
