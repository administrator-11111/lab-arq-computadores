;==============================================================================
; EJERCICIO    : Ordenar un vector aleatorio segun la variable SENTIDO
; ARCHIVO      : 06_ordenar_asc_desc_variable.asm
; ENUNCIADO    : Generar un vector de 10 numeros aleatorios entre 1 y 99,
;                mostrar el vector original, ordenarlo en forma ascendente o
;                descendente segun el valor de la variable SENTIDO declarada
;                en el segmento DATOS (0 = ascendente, 1 = descendente) y
;                mostrar el resultado.
; SOLUCION     : 1) En el segmento DATOS se define SENTIDO DB 1 (descendente).
;                   Para cambiar a orden ascendente basta editar esa linea a:
;                   SENTIDO DB 0
;                2) Inicializa la semilla desde el reloj y genera 10 numeros
;                   aleatorios en [1, 99].
;                3) Muestra el vector original.
;                4) Llama a ORDENAR_SEGUN_SENTIDO (que lee la variable SENTIDO
;                   para decidir cada comparacion sin duplicar el algoritmo).
;                5) Muestra el sentido elegido y el vector ordenado.
; REGISTROS    : SI = puntero al vector, CX = cantidad de elementos,
;                BX = bandera swap / minimo aleatorio, AX y DX = valores.
; VARIABLES    : VECTOR DW 10 DUP(0), N_ELEM DW 10, SEMILLA DW 0,
;                SENTIDO DB 1 (cambiar a 0 para ascendente o 1 para descendente).
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/05_Ordenamiento/ordenar_segun_variable.asm
; EJEMPLO DE ENTRADA/SALIDA (run8086.py --time 12:30:45.10):
;                === EJERCICIO: ORDENAR SEGUN VARIABLE SENTIDO ===
;                Vector original                : 92 93 77 8 16 98 71 11 35 12
;                Vector ordenado (descendente)  : 98 93 92 77 71 35 16 12 11 8
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
    MSG_TITULO DB '=== EJERCICIO: ORDENAR SEGUN VARIABLE SENTIDO ===$' ; tit
    MSG_ORIG   DB 'Vector original                : $' ; etiqueta original
    MSG_ASC    DB 'Vector ordenado (ascendente)   : $' ; etiqueta ascendente
    MSG_DESC   DB 'Vector ordenado (descendente)  : $' ; etiqueta descendente
    VECTOR     DW 10 DUP(0)                 ; vector de 10 palabras
    N_ELEM     DW 10                        ; cantidad de elementos
    SEMILLA    DW 0                         ; semilla del generador aleatorio
    ;--------------------------------------------------------------------------
    ; CAMBIAR ESTA VARIABLE PARA ELEGIR EL SENTIDO DE ORDENAMIENTO:
    ;   SENTIDO DB 0  -> orden ascendente  (menor a mayor)
    ;   SENTIDO DB 1  -> orden descendente (mayor a menor)
    ;--------------------------------------------------------------------------
    SENTIDO    DB 1                         ; sentido configurado (1 = desc)
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    CALL INICIALIZAR_SEMILLA                ; semilla desde el reloj del sistema
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, N_ELEM                          ; CX = 10 elementos por generar
LLENAR_CICLO:                               ; genera los 10 numeros aleatorios
    PUSH CX                                 ; guarda el contador del ciclo
    MOV BX, 1                               ; valor minimo = 1
    MOV CX, 99                              ; valor maximo = 99
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 99]
    MOV [SI], AX                            ; guarda el numero en el vector
    ADD SI, 2                               ; avanza al siguiente elemento DW
    POP CX                                  ; recupera contador del ciclo
    LOOP LLENAR_CICLO                       ; repite 10 veces

    IMPRIMIR_CADENA MSG_ORIG                ; muestra etiqueta original
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra el vector original
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = 10
    CALL ORDENAR_SEGUN_SENTIDO              ; ordena segun el valor de SENTIDO

    CMP SENTIDO, 0                          ; se ordeno en sentido ascendente?
    JNE ET_DESC                             ; no: mostrar etiqueta descendente
    IMPRIMIR_CADENA MSG_ASC                 ; etiqueta ascendente
    JMP MOSTRAR_ORD                         ; salta a imprimir el vector
ET_DESC:                                    ; etiqueta para sentido descendente
    IMPRIMIR_CADENA MSG_DESC                ; etiqueta descendente

MOSTRAR_ORD:                                ; muestra el vector ya ordenado
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;------------------------------------------------------------------------------
; PROCEDIMIENTO ORDENAR_SEGUN_SENTIDO
;   Copia de utils/05_Ordenamiento/ordenar_segun_variable.asm
;------------------------------------------------------------------------------
ORDENAR_SEGUN_SENTIDO PROC                  ; inicio del procedimiento
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
    MOV AX, [DI]                            ; AX = v[j]
    MOV DX, [DI+2]                          ; DX = v[j+1]
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
ORDENAR_SEGUN_SENTIDO ENDP                  ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO INICIALIZAR_SEMILLA
;------------------------------------------------------------------------------
INICIALIZAR_SEMILLA PROC                    ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    MOV AH, 2Ch                             ; servicio 2Ch: obtener hora
    INT 21h                                 ; CX = hora:min, DX = seg:cent
    XOR DX, CX                              ; mezcla los bits de ambos
    MOV SEMILLA, DX                         ; guarda la semilla inicial
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
INICIALIZAR_SEMILLA ENDP                    ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO GENERAR_ALEATORIO
;------------------------------------------------------------------------------
GENERAR_ALEATORIO PROC                      ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (maximo)
    PUSH DX                                 ; guarda DX (MUL/DIV lo usan)
    MOV AX, SEMILLA                         ; AX = semilla actual
    MOV DX, 25173                           ; DX = multiplicador del LCG
    MUL DX                                  ; DX:AX = semilla * 25173
    ADD AX, 13849                           ; suma el incremento (mod 65536)
    MOV SEMILLA, AX                         ; guarda la nueva semilla
    XCHG AH, AL                             ; usa los bits altos como bajos
    SUB CX, BX                              ; CX = max - min
    INC CX                                  ; CX = cantidad de valores
    XOR DX, DX                              ; DX:AX = valor pseudoaleatorio
    DIV CX                                  ; DX = valor mod cantidad
    MOV AX, DX                              ; AX = desplazamiento 0..rango-1
    ADD AX, BX                              ; AX = min + desplazamiento
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
GENERAR_ALEATORIO ENDP                      ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_VECTOR
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
