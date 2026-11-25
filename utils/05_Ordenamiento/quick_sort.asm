;==============================================================================
; ARCHIVO       : quick_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento rapido (Quick Sort) recursivo con particion de
;                 Lomuto en dos versiones: arreglos de 16 bits (DW, 0..65535)
;                 y arreglos de 8 bits (DB, 0..255), sin signo, controlado por
;                 SENTIDO (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: 1) Elige como pivote el ultimo elemento: pivote = v[der].
;                 2) Particion de Lomuto usando dos punteros:
;                    - SI (posicion de escritura i): comienza en v[izq] (no en
;                      izq-1, evitando indices negativos sin signo).
;                    - DI (explorador j): recorre desde v[izq] hasta v[der-1].
;                    Si v[j] debe ir antes del pivote (<= asc, >= desc),
;                    intercambia [SI] con [DI] y avanza SI.
;                 3) Coloca el pivote en [SI] intercambiando [SI] con v[der].
;                 4) Ordena recursivamente [izq..p-1] (solo si p > izq, lo que
;                    evita subdesbordar 0-1) y [p+1..der] (solo si p < der).
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 3):
;                   pivote=3: j=0(5>3) | j=1(2<=3) swap->[2,5,8,3] i=1 |
;                   j=2(8>3) | fin: swap v[1],v[3]->[2,3,8,5] p=1 -> [2,3,5,8].
;
;                 Diferencia 8 bits vs 16 bits en 8086:
;                 - 16 bits (DW): calcula punteros con SHL reg, 1 (2*idx),
;                   pivote en CX, intercambio con AX/BX, avanza ADD reg, 2 y
;                   recupera indice p con SHR BX, 1.
;                 -  8 bits (DB): punteros directos (sin SHL ni SHR), pivote en
;                   CL, intercambio de bytes con AL/BL, avanza INC reg.
; REGISTROS     : Entrada  : SI = offset del vector (DW o DB), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0, QS_BASE DW 0, QS_PTR_DER DW 0 en DATOS
; DEPENDENCIAS  : Ninguna para QUICK_SORT / QUICK_SORT_8. La demo usa macros
;                 de E/S y MOSTRAR_VECTOR / MOSTRAR_VECTOR_8.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0, QS_BASE DW 0, QS_PTR_DER DW 0 en
;                    DATOS y pila suficiente (DW 256 DUP(0)).
;                 2. Copiar QUICK_SORT (16b) o QUICK_SORT_8 (8b) en CODIGO
;                    despues de la salida a DOS.
;                 3. Cargar SENTIDO, SI = offset, CX = cantidad y llamar a
;                    CALL QUICK_SORT o CALL QUICK_SORT_8.
; EJEMPLO       : --- 16 bits (DW) ---
;                 Original    : 5000 18 750 18 6 9100 330 12
;                 Ascendente  : 6 12 18 18 330 750 5000 9100
;                 Descendente : 9100 5000 750 330 18 18 12 6
;                 --- 8 bits (DB) ---
;                 Original    : 150 18 75 18 6 241 33 12
;                 Ascendente  : 6 12 18 18 33 75 150 241
;                 Descendente : 241 150 75 33 18 18 12 6
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
    MSG_TITULO DB '=== DEMO: QUICK SORT (16 BITS Y 8 BITS) ===$' ; titulo
    MSG_16     DB '--- Arreglo de 16 bits (DW, 0..65535) ---$' ; subtitulo 16
    MSG_8      DB '--- Arreglo de 8 bits (DB, 0..255) ---$'    ; subtitulo 8
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR_16  DW 5000, 18, 750, 18, 6, 9100, 330, 12 ; arreglo 16 bits (DW)
    N_16       DW 8                         ; cantidad de elementos DW
    VECTOR_8   DB 150, 18, 75, 18, 6, 241, 33, 12 ; arreglo 8 bits (DB)
    N_8        DW 8                         ; cantidad de elementos DB
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

    ;--- Demostracion 16 bits (DW) ---
    IMPRIMIR_CADENA MSG_16                  ; subtitulo 16 bits
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_ORIG                ; etiqueta original
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo DW
    MOV CX, N_16                            ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra original 16 bits
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente
    CALL QUICK_SORT                         ; ordena DW ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR                     ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL QUICK_SORT                         ; ordena DW descendente
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
    CALL QUICK_SORT_8                       ; ordena DB ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL QUICK_SORT_8                       ; ordena DB descendente
    IMPRIMIR_CADENA MSG_DESC                ; etiqueta descendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado descendente
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: QUICK_SORT (16 BITS / DW) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO QUICK_SORT
;   Entrada : SI = offset del vector de 16 bits (DW), CX = cantidad
;             Variables en DATOS: SENTIDO, QS_BASE, QS_PTR_DER
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
QUICK_SORT PROC                             ; inicio del procedimiento 16 bits
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
QUICK_SORT ENDP                             ; fin del procedimiento 16 bits

QS_ORDENAR PROC                             ; recursion 16 bits
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

QS_PARTICION PROC                           ; particion de Lomuto (16 bits)
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
    MOV AX, [DI]                            ; AX = v[j] (16 bits)
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
    ADD SI, 2                               ; avanza i (2 bytes)

QS_PART_SIG:                                ; avanza explorador j
    ADD DI, 2                               ; siguiente palabra (2 bytes)
    JMP QS_PART_CICLO                       ; continua el recorrido

QS_COLOCAR_PIVOTE:                          ; ubica el pivote en v[i]
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
;====== FIN BLOQUE REUTILIZABLE: QUICK_SORT (16 BITS / DW) ======

;====== INICIO BLOQUE REUTILIZABLE: QUICK_SORT_8 (8 BITS / DB) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO QUICK_SORT_8
;   Entrada : SI = offset del vector de 8 bits (DB), CX = cantidad
;             Variables en DATOS: SENTIDO, QS_BASE, QS_PTR_DER
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
QUICK_SORT_8 PROC                           ; inicio del procedimiento 8 bits
    PUSH AX                                 ; guarda AX (izq)
    PUSH BX                                 ; guarda BX (indice pivote)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (der)
    PUSH SI                                 ; guarda SI (offset vector)
    PUSH DI                                 ; guarda DI

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE QS8_FIN                             ; si: ya esta ordenado, termina

    MOV QS_BASE, SI                         ; guarda direccion base del vector
    XOR AX, AX                              ; izq = 0
    MOV DX, CX                              ; DX = N
    DEC DX                                  ; der = N - 1
    CALL QS8_ORDENAR                        ; inicia ordenamiento recursivo

QS8_FIN:                                    ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
QUICK_SORT_8 ENDP                           ; fin del procedimiento 8 bits

QS8_ORDENAR PROC                            ; recursion 8 bits
    CMP AX, DX                              ; izq >= der (0 o 1 elemento)?
    JAE QS8_ORD_FIN                         ; si: caso base, retorna

    CALL QS8_PARTICION                      ; particiona; BX = indice final p

    CMP BX, AX                              ; p > izq? (evita p-1 si p=0)
    JBE QS8_LADO_DER                        ; no: subarreglo izquierdo vacio
    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda p en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV DX, BX                              ; DX = p
    DEC DX                                  ; DX = p - 1 (seguro sin signo)
    CALL QS8_ORDENAR                        ; ordena subarreglo [izq..p-1]
    POP DX                                  ; recupera der
    POP BX                                  ; recupera p
    POP AX                                  ; recupera izq

QS8_LADO_DER:                               ; procesa subarreglo derecho
    CMP BX, DX                              ; p < der?
    JAE QS8_ORD_FIN                         ; no: subarreglo derecho vacio
    PUSH AX                                 ; guarda izq en la pila
    PUSH BX                                 ; guarda p en la pila
    PUSH DX                                 ; guarda der en la pila
    MOV AX, BX                              ; AX = p
    INC AX                                  ; AX = p + 1
    CALL QS8_ORDENAR                        ; ordena subarreglo [p+1..der]
    POP DX                                  ; recupera der
    POP BX                                  ; recupera p
    POP AX                                  ; recupera izq

QS8_ORD_FIN:                                ; fin de la llamada recursiva
    RET                                     ; vuelve al nivel anterior
QS8_ORDENAR ENDP                            ; fin de QS8_ORDENAR

QS8_PARTICION PROC                          ; particion de Lomuto (8 bits)
    PUSH AX                                 ; guarda izq original
    PUSH CX                                 ; guarda CX (CL = valor pivote)
    PUSH DX                                 ; guarda der original
    PUSH SI                                 ; guarda SI (puntero escritura i)
    PUSH DI                                 ; guarda DI (puntero explorador j)

    MOV DI, DX                              ; DI = der (1 byte por elemento)
    ADD DI, QS_BASE                         ; DI apunta a v[der]
    MOV QS_PTR_DER, DI                      ; guarda puntero al pivote
    MOV CL, [DI]                            ; CL = valor del pivote v[der]

    MOV SI, AX                              ; SI = izq
    ADD SI, QS_BASE                         ; SI apunta a v[izq] (indice i)
    MOV DI, SI                              ; DI apunta a v[izq] (indice j)

QS8_PART_CICLO:                             ; recorre j desde izq hasta der-1
    CMP DI, QS_PTR_DER                      ; llego al pivote (j == der)?
    JAE QS8_COLOCAR_PIVOTE                  ; si: termina la exploracion
    MOV AL, [DI]                            ; AL = v[j] (8 bits)
    CMP SENTIDO, 0                          ; orden ascendente?
    JNE QS8_PART_DESC                       ; no: comparar para descendente
    CMP AL, CL                              ; ascendente: v[j] <= pivote?
    JA QS8_PART_SIG                         ; no: dejar a la derecha
    JMP QS8_PART_SWAP                       ; si: mover a la zona izquierda

QS8_PART_DESC:                              ; comparacion para descendente
    CMP AL, CL                              ; descendente: v[j] >= pivote?
    JB QS8_PART_SIG                         ; no: dejar a la derecha

QS8_PART_SWAP:                              ; intercambia los bytes v[i], v[j]
    MOV BL, [SI]                            ; BL = v[i]
    MOV [SI], AL                            ; v[i] = v[j]
    MOV [DI], BL                            ; v[j] = v[i] anterior
    INC SI                                  ; avanza i (1 byte)

QS8_PART_SIG:                               ; avanza explorador j
    INC DI                                  ; siguiente byte (1 byte)
    JMP QS8_PART_CICLO                      ; continua el recorrido

QS8_COLOCAR_PIVOTE:                         ; ubica el pivote en v[i]
    MOV DI, QS_PTR_DER                      ; DI apunta a v[der]
    MOV AL, [SI]                            ; AL = v[i]
    MOV BL, [DI]                            ; BL = pivote v[der]
    MOV [SI], BL                            ; v[i] = pivote
    MOV [DI], AL                            ; v[der] = v[i] anterior

    MOV BX, SI                              ; BX = direccion final del pivote
    SUB BX, QS_BASE                         ; BX = indice logico p (sin SHR)

    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura der
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura izq
    RET                                     ; vuelve con p en BX
QS8_PARTICION ENDP                          ; fin de QS8_PARTICION
;====== FIN BLOQUE REUTILIZABLE: QUICK_SORT_8 (8 BITS / DB) ======

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
