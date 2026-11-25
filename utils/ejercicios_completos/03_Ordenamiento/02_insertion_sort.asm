;==============================================================================
; EJERCICIO    : Ordenar un vector aleatorio con Insertion Sort (Insercion)
; ARCHIVO      : 02_insertion_sort.asm
; ENUNCIADO    : Generar un vector de 10 numeros aleatorios entre 1 y 99,
;                mostrar el vector original, ordenarlo de forma ascendente
;                mediante insercion directa (Insertion Sort) y mostrar el
;                vector ordenado.
; SOLUCION     : 1) Inicializa la semilla con la hora del sistema mediante
;                   INICIALIZAR_SEMILLA.
;                2) Llena VECTOR (10 palabras DW) con numeros aleatorios en
;                   [1, 99] usando GENERAR_ALEATORIO.
;                3) Muestra el vector original con MOSTRAR_VECTOR.
;                4) Fija SENTIDO = 0 (ascendente) y llama a INSERTION_SORT.
;                5) Muestra el vector ordenado.
; REGISTROS    : SI = puntero / desplazamiento i, BX = base del vector,
;                DI = desplazamiento j, AX = clave, CX = v[j-1], DX = 2*N.
; VARIABLES    : VECTOR DW 10 DUP(0), N_ELEM DW 10, SEMILLA DW 0, SENTIDO DB 0.
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/05_Ordenamiento/insertion_sort.asm
; EJEMPLO DE ENTRADA/SALIDA (run8086.py --time 12:30:45.10):
;                === EJERCICIO: INSERTION SORT (10 ALEATORIOS 1..99) ===
;                Vector original : 92 93 77 8 16 98 71 11 35 12
;                Vector ordenado : 8 11 12 16 35 71 77 92 93 98
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
    MSG_TITULO DB '=== EJERCICIO: INSERTION SORT (10 ALEATORIOS 1..99) ===$' ; t
    MSG_ORIG   DB 'Vector original : $'     ; etiqueta vector original
    MSG_ORD    DB 'Vector ordenado : $'     ; etiqueta vector ordenado
    VECTOR     DW 10 DUP(0)                 ; vector de 10 palabras
    N_ELEM     DW 10                        ; cantidad de elementos
    SEMILLA    DW 0                         ; semilla del generador aleatorio
    SENTIDO    DB 0                         ; 0 = ascendente, 1 = descendente
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
    CALL MOSTRAR_VECTOR                     ; muestra el vector sin ordenar
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = 10
    CALL INSERTION_SORT                     ; ordena con Insertion Sort

    IMPRIMIR_CADENA MSG_ORD                 ; muestra etiqueta ordenado
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;------------------------------------------------------------------------------
; PROCEDIMIENTO INSERTION_SORT (copia de utils/05_Ordenamiento/insertion_sort.asm)
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
    CMP SENTIDO, 0                          ; orden ascendente?
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
