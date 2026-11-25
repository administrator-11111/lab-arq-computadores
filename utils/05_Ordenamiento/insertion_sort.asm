;==============================================================================
; ARCHIVO       : insertion_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento por insercion directa (Insertion Sort) en dos
;                 versiones: arreglos de 16 bits (DW, 0..65535) y arreglos de
;                 8 bits (DB, 0..255), sin signo, controlado por la variable
;                 SENTIDO (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: Mantiene una parte izquierda ya ordenada (inicialmente v[0]).
;                 Para cada elemento clave = v[i] (i = 1..N-1), desplaza hacia
;                 la derecha los elementos que deben ir despues de clave segun
;                 SENTIDO, y luego inserta clave en el hueco libre.
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 1):
;                   i=1, clave=2: desplaza 5 -> [2, 5, 8, 1]
;                   i=2, clave=8: 5 <= 8, no desplaza -> [2, 5, 8, 1]
;                   i=3, clave=1: desplaza 8, 5, 2 -> [1, 2, 5, 8]
;
;                 Diferencia 8 bits vs 16 bits en 8086:
;                 - En ambos se copia la base en BX para usar [BX+SI] y [BX+DI]
;                   (porque [SI+DI] no existe en 8086).
;                 - 16 bits (DW): DX = 2*N (SHL DX,1), SI inicia en 2, lee
;                   AX/CX, vecino [BX+DI-2], retrocede SUB DI,2 y avanza ADD SI,2.
;                 -  8 bits (DB): DX = N, SI inicia en 1, lee AL/CL, vecino
;                   [BX+DI-1], retrocede DEC DI y avanza INC SI.
; REGISTROS     : Entrada  : SI = offset del vector (DW o DB), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0  (0 = ascendente, 1 = descendente) en DATOS
; DEPENDENCIAS  : Ninguna para INSERTION_SORT / INSERTION_SORT_8. La demo usa
;                 macros de E/S y MOSTRAR_VECTOR / MOSTRAR_VECTOR_8.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0 en DATOS.
;                 2. Copiar INSERTION_SORT (DW) o INSERTION_SORT_8 (DB) en
;                    CODIGO despues de la salida a DOS.
;                 3. Cargar SENTIDO, SI = offset, CX = cantidad y ejecutar
;                    CALL INSERTION_SORT o CALL INSERTION_SORT_8.
; EJEMPLO       : --- 16 bits (DW) ---
;                 Original    : 3000 12 450 12 7 60000 210 4
;                 Ascendente  : 4 7 12 12 210 450 3000 60000
;                 Descendente : 60000 3000 450 210 12 12 7 4
;                 --- 8 bits (DB) ---
;                 Original    : 130 12 45 12 7 250 21 4
;                 Ascendente  : 4 7 12 12 21 45 130 250
;                 Descendente : 250 130 45 21 12 12 7 4
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
    MSG_TITULO DB '=== DEMO: INSERTION SORT (16 BITS Y 8 BITS) ===$' ; tit
    MSG_16     DB '--- Arreglo de 16 bits (DW, 0..65535) ---$' ; subtitulo 16
    MSG_8      DB '--- Arreglo de 8 bits (DB, 0..255) ---$'    ; subtitulo 8
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR_16  DW 3000, 12, 450, 12, 7, 60000, 210, 4 ; arreglo 16 bits (DW)
    N_16       DW 8                         ; cantidad de elementos DW
    VECTOR_8   DB 130, 12, 45, 12, 7, 250, 21, 4 ; arreglo 8 bits (DB)
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

    ;--- Demostracion 16 bits (DW) ---
    IMPRIMIR_CADENA MSG_16                  ; subtitulo 16 bits
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_ORIG                ; etiqueta original
    MOV SI, OFFSET VECTOR_16                ; SI = arreglo DW
    MOV CX, N_16                            ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra original 16 bits
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente
    CALL INSERTION_SORT                     ; ordena DW ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR                     ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL INSERTION_SORT                     ; ordena DW descendente
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
    CALL INSERTION_SORT_8                   ; ordena DB ascendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado ascendente
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; orden descendente
    CALL INSERTION_SORT_8                   ; ordena DB descendente
    IMPRIMIR_CADENA MSG_DESC                ; etiqueta descendente
    CALL MOSTRAR_VECTOR_8                   ; muestra resultado descendente
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: INSERTION_SORT (16 BITS / DW) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO INSERTION_SORT
;   Entrada : SI = offset del vector de 16 bits (DW), CX = cantidad
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
INSERTION_SORT PROC                         ; inicio del procedimiento 16 bits
    PUSH AX                                 ; guarda AX (clave a insertar)
    PUSH BX                                 ; guarda BX (base del vector)
    PUSH CX                                 ; guarda CX (elemento v[j-1])
    PUSH DX                                 ; guarda DX (limite 2*N en bytes)
    PUSH SI                                 ; guarda SI (desplazamiento i)
    PUSH DI                                 ; guarda DI (desplazamiento j)

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE INS_FIN                             ; si: ya esta ordenado, termina

    MOV BX, SI                              ; BX = direccion base del vector
    MOV DX, CX                              ; DX = N
    SHL DX, 1                               ; DX = 2 * N (tamano en bytes)
    MOV SI, 2                               ; SI = 2 (indice logico i = 1)

INS_EXTERNO:                                ; recorre i = 1 .. N-1
    CMP SI, DX                              ; llego al final del vector?
    JAE INS_FIN                             ; si: todos los elementos insertados
    MOV AX, [BX+SI]                         ; AX = clave = v[i] (16 bits)
    MOV DI, SI                              ; DI = j (en bytes, inicia en i)

INS_INTERNO:                                ; busca donde insertar la clave
    CMP DI, 0                               ; llego al inicio del vector (j=0)?
    JE INS_INSERTAR                         ; si: insertar en la posicion 0
    MOV CX, [BX+DI-2]                       ; CX = v[j-1] (16 bits)
    CMP SENTIDO, 0                          ; se pidio orden ascendente?
    JNE INS_DESC                            ; no: verificar orden descendente
    CMP CX, AX                              ; ascendente: v[j-1] <= clave?
    JBE INS_INSERTAR                        ; si: encontramos la posicion
    JMP INS_DESPLAZAR                       ; no: mover v[j-1] a la derecha

INS_DESC:                                   ; comparacion para orden descendente
    CMP CX, AX                              ; descendente: v[j-1] >= clave?
    JAE INS_INSERTAR                        ; si: encontramos la posicion

INS_DESPLAZAR:                              ; corre el elemento hacia la derecha
    MOV [BX+DI], CX                         ; v[j] = v[j-1]
    SUB DI, 2                               ; j = j - 1 (retrocede 2 bytes)
    JMP INS_INTERNO                         ; sigue comparando a la izquierda

INS_INSERTAR:                               ; coloca la clave en su lugar
    MOV [BX+DI], AX                         ; v[j] = clave
    ADD SI, 2                               ; i = i + 1 (avanza 2 bytes)
    JMP INS_EXTERNO                         ; procesa el siguiente elemento

INS_FIN:                                    ; salida comun del procedimiento
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
INSERTION_SORT ENDP                         ; fin del procedimiento 16 bits
;====== FIN BLOQUE REUTILIZABLE: INSERTION_SORT (16 BITS / DW) ======

;====== INICIO BLOQUE REUTILIZABLE: INSERTION_SORT_8 (8 BITS / DB) ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO INSERTION_SORT_8
;   Entrada : SI = offset del vector de 8 bits (DB), CX = cantidad
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
INSERTION_SORT_8 PROC                       ; inicio del procedimiento 8 bits
    PUSH AX                                 ; guarda AX (AL = clave)
    PUSH BX                                 ; guarda BX (base del vector)
    PUSH CX                                 ; guarda CX (CL = v[j-1])
    PUSH DX                                 ; guarda DX (limite N bytes)
    PUSH SI                                 ; guarda SI (indice i)
    PUSH DI                                 ; guarda DI (indice j)

    CMP CX, 1                               ; tiene 0 o 1 elemento?
    JBE INS8_FIN                            ; si: ya esta ordenado, termina

    MOV BX, SI                              ; BX = direccion base del vector
    MOV DX, CX                              ; DX = N (1 byte por elemento)
    MOV SI, 1                               ; SI = 1 (segundo elemento)

INS8_EXTERNO:                               ; recorre i = 1 .. N-1
    CMP SI, DX                              ; llego al final del vector?
    JAE INS8_FIN                            ; si: todos los bytes insertados
    MOV AL, [BX+SI]                         ; AL = clave = v[i] (8 bits)
    MOV DI, SI                              ; DI = j (inicia en i)

INS8_INTERNO:                               ; busca donde insertar la clave
    CMP DI, 0                               ; llego al inicio (j = 0)?
    JE INS8_INSERTAR                        ; si: insertar en la posicion 0
    MOV CL, [BX+DI-1]                       ; CL = v[j-1] (1 byte atras)
    CMP SENTIDO, 0                          ; se pidio orden ascendente?
    JNE INS8_DESC                           ; no: verificar orden descendente
    CMP CL, AL                              ; ascendente: v[j-1] <= clave?
    JBE INS8_INSERTAR                       ; si: encontramos la posicion
    JMP INS8_DESPLAZAR                      ; no: mover v[j-1] a la derecha

INS8_DESC:                                  ; comparacion para orden descendente
    CMP CL, AL                              ; descendente: v[j-1] >= clave?
    JAE INS8_INSERTAR                       ; si: encontramos la posicion

INS8_DESPLAZAR:                             ; corre el byte hacia la derecha
    MOV [BX+DI], CL                         ; v[j] = v[j-1]
    DEC DI                                  ; j = j - 1 (retrocede 1 byte)
    JMP INS8_INTERNO                        ; sigue comparando a la izquierda

INS8_INSERTAR:                              ; coloca la clave en su lugar
    MOV [BX+DI], AL                         ; v[j] = clave
    INC SI                                  ; i = i + 1 (avanza 1 byte)
    JMP INS8_EXTERNO                        ; procesa el siguiente byte

INS8_FIN:                                   ; salida comun del procedimiento
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
INSERTION_SORT_8 ENDP                       ; fin del procedimiento 8 bits
;====== FIN BLOQUE REUTILIZABLE: INSERTION_SORT_8 (8 BITS / DB) ======

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
