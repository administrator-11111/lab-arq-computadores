;==============================================================================
; ARCHIVO       : insertion_sort.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Ordenamiento por insercion directa (Insertion Sort) para
;                 vectores de palabras (DW) sin signo (0..65535), controlado
;                 por la variable SENTIDO (0 = ascendente, 1 = descendente).
; FUNCIONAMIENTO: Mantiene una parte izquierda ya ordenada (inicialmente solo
;                 v[0]). Para cada elemento clave = v[i] (i = 1..N-1), busca
;                 hacia la izquierda desplazando una posicion a la derecha los
;                 elementos que deben ir despues de clave segun SENTIDO. Al
;                 encontrar el hueco correcto, inserta clave alli.
;
;                 Traza de ejemplo (ascendente, vector: 5, 2, 8, 1):
;                   i=1, clave=2: desplaza 5 -> [2, 5, 8, 1]
;                   i=2, clave=8: 5 <= 8, no desplaza -> [2, 5, 8, 1]
;                   i=3, clave=1: desplaza 8, 5, 2 -> [1, 2, 5, 8]
;
;                 Particularidad 8086: los modos de direccionamiento base+indice
;                 validos son [BX+SI] y [BX+DI] (NO existe [SI+DI]). Por eso se
;                 copia la base del vector en BX, se usa SI como desplazamiento
;                 en bytes de i (2, 4, ..., 2*(N-1)) y DI como desplazamiento
;                 de j hacia atras, verificando DI = 0 antes de leer [BX+DI-2]
;                 para evitar subdesbordamiento sin signo.
; REGISTROS     : Entrada  : SI = offset del vector (DW), CX = cantidad
;                 Salida   : vector ordenado en memoria (in-place)
;                 Modifica : ninguno (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES     : SENTIDO DB 0  (0 = ascendente, 1 = descendente) en DATOS
; DEPENDENCIAS  : Ninguna para INSERTION_SORT. La demo usa macros de E/S de
;                 utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                 y MOSTRAR_VECTOR de procedimientos canonicos.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0 en DATOS.
;                 2. Copiar el bloque INSERTION_SORT dentro de CODIGO (despues
;                    de la salida a DOS).
;                 3. Cargar SENTIDO, SI = offset, CX = cantidad y llamar a
;                    CALL INSERTION_SORT.
; EJEMPLO       : Vector original     : 30 12 45 12 7 60 21 4
;                 Ordenado ascendente : 4 7 12 12 21 30 45 60
;                 Ordenado descendente: 60 45 30 21 12 12 7 4
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
    MSG_TITULO DB '=== DEMO: INSERTION SORT (INSERCION) ===$' ; titulo
    MSG_ORIG   DB 'Vector original     : $' ; etiqueta para vector inicial
    MSG_ASC    DB 'Ordenado ascendente : $' ; etiqueta para orden ascendente
    MSG_DESC   DB 'Ordenado descendente: $' ; etiqueta para orden descendente
    VECTOR     DW 30, 12, 45, 12, 7, 60, 21, 4 ; vector de prueba con repetido
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
    CALL INSERTION_SORT                     ; ordena ascendentemente

    IMPRIMIR_CADENA MSG_ASC                 ; muestra etiqueta ascendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado asc
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 1                          ; elige orden descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL INSERTION_SORT                     ; ordena descendentemente

    IMPRIMIR_CADENA MSG_DESC                ; muestra etiqueta descendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado desc
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: INSERTION_SORT ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO INSERTION_SORT
;   Entrada : SI = offset del vector (DW), CX = cantidad de elementos
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
INSERTION_SORT PROC                         ; inicio del procedimiento
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
    MOV AX, [BX+SI]                         ; AX = clave = v[i]
    MOV DI, SI                              ; DI = j (en bytes, inicia en i)

INS_INTERNO:                                ; busca donde insertar la clave
    CMP DI, 0                               ; llego al inicio del vector (j=0)?
    JE INS_INSERTAR                         ; si: insertar en la posicion 0
    MOV CX, [BX+DI-2]                       ; CX = v[j-1]
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
INSERTION_SORT ENDP                         ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: INSERTION_SORT ======

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
