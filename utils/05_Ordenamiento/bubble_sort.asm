;==============================================================================
; ARCHIVO       : bubble_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento por metodo de burbuja (Bubble Sort) para
;                 vectores de palabras (DW) sin signo (0..65535). Incluye
;                 bandera de "hubo intercambio" para terminar antes si el
;                 vector ya quedo ordenado, y variable SENTIDO (0 asc, 1 desc).
; FUNCIONAMIENTO: En cada pasada recorre los elementos adyacentes v[j] y
;                 v[j+1]. Si estan fuera de orden segun SENTIDO, los
;                 intercambia y activa la bandera BL = 1. Al final de la
;                 pasada el elemento extremo (mayor en ascendente, menor en
;                 descendente) queda en su posicion definitiva, por lo que la
;                 siguiente pasada recorre un elemento menos. Si una pasada
;                 completa no realiza ningun intercambio (BL = 0), el vector
;                 ya esta ordenado y el algoritmo termina de inmediato.
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 1):
;                   Pasada 1 (3 comp): [2,5,8,1] -> [2,5,8,1] -> [2,5,1,8] (8 fijo)
;                   Pasada 2 (2 comp): [2,5,1,8] -> [2,1,5,8] (5 fijo)
;                   Pasada 3 (1 comp): [1,2,5,8] (hubo intercambio -> fin)
;                 Si el vector entra ya ordenado (1, 2, 5, 8):
;                   Pasada 1 (3 comp): sin intercambios -> BL=0 -> termina.
;
;                 Particularidad 8086: cada elemento DW ocupa 2 bytes, por eso
;                 el adyacente de [DI] es [DI+2] y el puntero avanza con
;                 ADD DI, 2. Se usan saltos sin signo (JBE / JAE).
; REGISTROS     : Entrada  : SI = offset del vector (DW), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0  (0 = ascendente, 1 = descendente) en DATOS
; DEPENDENCIAS  : Ninguna para BUBBLE_SORT. La demo usa macros de E/S de
;                 utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                 y MOSTRAR_VECTOR de procedimientos canonicos.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0 en DATOS.
;                 2. Copiar el bloque BUBBLE_SORT dentro de CODIGO (despues
;                    de la salida a DOS).
;                 3. Cargar MOV SENTIDO, 0 (o 1), MOV SI, OFFSET VECTOR,
;                    MOV CX, N y ejecutar CALL BUBBLE_SORT.
; EJEMPLO       : Vector original     : 42 15 88 15 3 99 27 8
;                 Ordenado ascendente : 3 8 15 15 27 42 88 99
;                 Ordenado descendente: 99 88 42 27 15 15 8 3
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
    MSG_TITULO DB '=== DEMO: BUBBLE SORT (BURBUJA) ===$' ; titulo de la demo
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR     DW 42, 15, 88, 15, 3, 99, 27, 8 ; vector de prueba con repetido
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
    CALL BUBBLE_SORT                        ; ordena ascendentemente

    IMPRIMIR_CADENA MSG_ASC                 ; muestra etiqueta ascendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado asc
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; elige orden descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL BUBBLE_SORT                        ; ordena descendentemente

    IMPRIMIR_CADENA MSG_DESC                ; muestra etiqueta descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado desc
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: BUBBLE_SORT ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO BUBBLE_SORT
;   Entrada : SI = offset del vector (DW), CX = cantidad de elementos
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
BUBBLE_SORT PROC                            ; inicio del procedimiento
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
    MOV AX, [DI]                            ; AX = v[j]
    MOV DX, [DI+2]                          ; DX = v[j+1]
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
BUBBLE_SORT ENDP                            ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: BUBBLE_SORT ======

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
