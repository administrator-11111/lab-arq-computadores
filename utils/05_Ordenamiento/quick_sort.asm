;==============================================================================
; ARCHIVO       : quick_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento rapido (Quick Sort) recursivo con particion de
;                 Lomuto para vectores de palabras (DW) sin signo (0..65535),
;                 controlado por SENTIDO (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: 1) Elige como pivote el ultimo elemento del subarreglo:
;                    pivote = v[der].
;                 2) Particion de Lomuto usando dos punteros:
;                    - SI (posicion de escritura i): comienza en v[izq] (no en
;                      izq-1, evitando asi indices negativos sin signo).
;                    - DI (explorador j): recorre desde v[izq] hasta v[der-1].
;                    Cada vez que v[j] debe ir antes del pivote (<= en asc,
;                    >= en desc), intercambia [SI] con [DI] y avanza SI.
;                 3) Al final coloca el pivote en [SI] intercambiando [SI] con
;                    v[der]. El indice logico p de [SI] es la posicion final
;                    del pivote.
;                 4) Ordena recursivamente [izq..p-1] (solo si p > izq, lo que
;                    evita subdesbordar 0-1 = 65535) y [p+1..der] (solo si
;                    p < der).
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 3):
;                   izq=0, der=3, pivote=3:
;                     j=0 (5>3): nada        | j=1 (2<=3): swap v[0],v[1] -> [2,5,8,3], i=1
;                     j=2 (8>3): nada        | fin: swap v[1],v[3] -> [2,3,8,5], p=1
;                   Izq [0..0]: 1 elem, fin. | Der [2..3] ([8,5]): pivote=5 -> [5,8].
;                   Resultado: [2, 3, 5, 8].
;
;                 Cuidado en 8086: todos los indices son sin signo (0..65535).
;                 Nunca se calcula p-1 cuando p <= izq, evitando desbordamiento
;                 y recursion infinita en subarreglos vacios.
; REGISTROS     : Entrada  : SI = offset del vector (DW), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0, QS_BASE DW 0, QS_PTR_DER DW 0 en DATOS
; DEPENDENCIAS  : Ninguna para QUICK_SORT. La demo usa macros de E/S de
;                 utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                 y MOSTRAR_VECTOR de procedimientos canonicos.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0, QS_BASE DW 0, QS_PTR_DER DW 0 en
;                    DATOS (y pila suficiente, ej. DW 256 DUP(0)).
;                 2. Copiar el bloque QUICK_SORT (incluye QS_ORDENAR y
;                    QS_PARTICION) en CODIGO despues de la salida a DOS.
;                 3. Cargar SENTIDO, SI = offset, CX = cantidad y ejecutar
;                    CALL QUICK_SORT.
; EJEMPLO       : Vector original     : 50 18 75 18 6 91 33 12
;                 Ordenado ascendente : 6 12 18 18 33 50 75 91
;                 Ordenado descendente: 91 75 50 33 18 18 12 6
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
    MSG_TITULO DB '=== DEMO: QUICK SORT (RAPIDO) ===$' ; titulo de la demo
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR     DW 50, 18, 75, 18, 6, 91, 33, 12 ; vector de prueba con repetido
    N_ELEM     DW 8                         ; cantidad de elementos del vector
    SENTIDO    DB 0                         ; 0 = ascendente, 1 = descendente
    QS_BASE    DW 0                         ; direccion base del vector activo
    QS_PTR_DER DW 0                         ; puntero al elemento pivote v[der]
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
    CALL QUICK_SORT                         ; ordena ascendentemente

    IMPRIMIR_CADENA MSG_ASC                 ; muestra etiqueta ascendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado asc
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; elige orden descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL QUICK_SORT                         ; ordena descendentemente

    IMPRIMIR_CADENA MSG_DESC                ; muestra etiqueta descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado desc
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: QUICK_SORT ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO QUICK_SORT
;   Entrada : SI = offset del vector (DW), CX = cantidad de elementos
;             Variables en DATOS: SENTIDO, QS_BASE, QS_PTR_DER
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
QUICK_SORT PROC                             ; inicio del procedimiento publico
    PUSH AX                                 ; guarda AX (izq)
    PUSH BX                                 ; guarda BX (indice pivote)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (der)
    PUSH SI                                 ; guarda SI (offset vector)
    PUSH DI                                 ; guarda DI

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE QS_FIN                              ; si: ya esta ordenado, termina

    MOV QS_BASE, SI                         ; guarda direccion base del vector
    XOR AX, AX                              ; izq = 0
    MOV DX, CX                              ; DX = N
    DEC DX                                  ; der = N - 1
    CALL QS_ORDENAR                         ; inicia ordenamiento recursivo

QS_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
QUICK_SORT ENDP                             ; fin del procedimiento publico

;------------------------------------------------------------------------------
; PROCEDIMIENTO QS_ORDENAR (interno, recursivo)
;   Entrada : AX = izq, DX = der (indices logicos sin signo)
;------------------------------------------------------------------------------
QS_ORDENAR PROC                             ; inicio de la recursion
    CMP AX, DX                              ; izq >= der (0 o 1 elemento)?
    JAE QS_ORD_FIN                          ; si: caso base, retorna

    CALL QS_PARTICION                       ; particiona; BX = indice final p

    CMP BX, AX                              ; p > izq? (evita p-1 si p=0)
    JBE QS_LADO_DER                         ; no: subarreglo izquierdo vacio
    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda p en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV DX, BX                              ; DX = p
    DEC DX                                  ; DX = p - 1 (seguro sin signo)
    CALL QS_ORDENAR                         ; ordena subarreglo [izq..p-1]
    POP DX                                  ; recupera der
    POP BX                                  ; recupera p
    POP AX                                  ; recupera izq

QS_LADO_DER:                                ; procesa subarreglo derecho
    CMP BX, DX                              ; p < der?
    JAE QS_ORD_FIN                          ; no: subarreglo derecho vacio
    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda p en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV AX, BX                              ; AX = p
    INC AX                                  ; AX = p + 1
    CALL QS_ORDENAR                         ; ordena subarreglo [p+1..der]
    POP DX                                  ; recupera der
    POP BX                                  ; recupera p
    POP AX                                  ; recupera izq

QS_ORD_FIN:                                 ; fin de la llamada recursiva
    RET                                     ; vuelve al nivel anterior
QS_ORDENAR ENDP                             ; fin de QS_ORDENAR

;------------------------------------------------------------------------------
; PROCEDIMIENTO QS_PARTICION (interno, esquema de Lomuto)
;   Entrada : AX = izq, DX = der
;   Salida  : BX = indice logico final del pivote (conserva AX y DX)
;------------------------------------------------------------------------------
QS_PARTICION PROC                           ; inicio de la particion
    PUSH AX                                 ; guarda izq original
    PUSH CX                                 ; guarda CX (valor pivote)
    PUSH DX                                 ; guarda der original
    PUSH SI                                 ; guarda SI (puntero escritura i)
    PUSH DI                                 ; guarda DI (puntero explorador j)

    MOV DI, DX                              ; DI = der
    SHL DI, 1                               ; DI = 2 * der
    ADD DI, QS_BASE                         ; DI apunta a v[der]
    MOV QS_PTR_DER, DI                      ; guarda puntero al pivote
    MOV CX, [DI]                            ; CX = valor del pivote v[der]

    MOV SI, AX                              ; SI = izq
    SHL SI, 1                               ; SI = 2 * izq
    ADD SI, QS_BASE                         ; SI apunta a v[izq] (indice i)
    MOV DI, SI                              ; DI apunta a v[izq] (indice j)

QS_PART_CICLO:                              ; recorre j desde izq hasta der-1
    CMP DI, QS_PTR_DER                      ; llego al pivote (j == der)?
    JAE QS_COLOCAR_PIVOTE                   ; si: termina la exploracion
    MOV AX, [DI]                            ; AX = v[j]
    CMP SENTIDO, 0                          ; orden ascendente?
    JNE QS_PART_DESC                        ; no: comparar para descendente
    CMP AX, CX                              ; ascendente: v[j] <= pivote?
    JA QS_PART_SIG                          ; no: dejar a la derecha
    JMP QS_PART_SWAP                        ; si: mover a la zona izquierda

QS_PART_DESC:                               ; comparacion para descendente
    CMP AX, CX                              ; descendente: v[j] >= pivote?
    JB QS_PART_SIG                          ; no: dejar a la derecha

QS_PART_SWAP:                               ; intercambia v[i] con v[j]
    MOV BX, [SI]                            ; BX = v[i]
    MOV [SI], AX                            ; v[i] = v[j]
    MOV [DI], BX                            ; v[j] = v[i] anterior
    ADD SI, 2                               ; avanza i (zona izquierda crece)

QS_PART_SIG:                                ; avanza explorador j
    ADD DI, 2                               ; siguiente palabra (2 bytes)
    JMP QS_PART_CICLO                       ; continua el recorrido

QS_COLOCAR_PIVOTE:                          ; ubica el pivote en su lugar v[i]
    MOV DI, QS_PTR_DER                      ; DI apunta a v[der]
    MOV AX, [SI]                            ; AX = v[i]
    MOV BX, [DI]                            ; BX = pivote v[der]
    MOV [SI], BX                            ; v[i] = pivote
    MOV [DI], AX                            ; v[der] = v[i] anterior

    MOV BX, SI                              ; BX = direccion final del pivote
    SUB BX, QS_BASE                         ; BX = desplazamiento en bytes
    SHR BX, 1                               ; BX = indice logico p

    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura der
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura izq
    RET                                     ; vuelve con p en BX
QS_PARTICION ENDP                           ; fin de QS_PARTICION
;====== FIN BLOQUE REUTILIZABLE: QUICK_SORT ======

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
