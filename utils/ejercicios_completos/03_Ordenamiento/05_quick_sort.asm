;==============================================================================
; EJERCICIO    : Ordenar un vector aleatorio con Quick Sort (Rapido)
; ARCHIVO      : 05_quick_sort.asm
; ENUNCIADO    : Generar un vector de 10 numeros aleatorios entre 1 y 99,
;                mostrar el vector original, ordenarlo de forma ascendente
;                mediante Quick Sort recursivo (particion de Lomuto) y mostrar
;                el vector ordenado.
; SOLUCION     : 1) Inicializa la semilla con la hora del sistema mediante
;                   INICIALIZAR_SEMILLA.
;                2) Llena VECTOR (10 palabras DW) con valores aleatorios en
;                   [1, 99] usando GENERAR_ALEATORIO.
;                3) Muestra el vector original con MOSTRAR_VECTOR.
;                4) Fija SENTIDO = 0 (ascendente) y llama a QUICK_SORT.
;                5) Muestra el vector ordenado.
; REGISTROS    : AX = izq, DX = der, BX = indice del pivote p, SI = puntero i,
;                DI = explorador j, CX = valor pivote / contador.
; VARIABLES    : VECTOR DW 10 DUP(0), N_ELEM DW 10, SEMILLA DW 0, SENTIDO DB 0,
;                QS_BASE DW 0, QS_PTR_DER DW 0.
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/05_Ordenamiento/quick_sort.asm
; EJEMPLO DE ENTRADA/SALIDA (run8086.py --time 12:30:45.10):
;                === EJERCICIO: QUICK SORT (10 ALEATORIOS 1..99) ===
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
    DW 256 DUP(0)                           ; 256 palabras para recursion
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MSG_TITULO DB '=== EJERCICIO: QUICK SORT (10 ALEATORIOS 1..99) ===$' ; tit
    MSG_ORIG   DB 'Vector original : $'     ; etiqueta vector original
    MSG_ORD    DB 'Vector ordenado : $'     ; etiqueta vector ordenado
    VECTOR     DW 10 DUP(0)                 ; vector de 10 palabras
    N_ELEM     DW 10                        ; cantidad de elementos
    SEMILLA    DW 0                         ; semilla del generador aleatorio
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
    CALL QUICK_SORT                         ; ordena con Quick Sort

    IMPRIMIR_CADENA MSG_ORD                 ; muestra etiqueta ordenado
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, N_ELEM                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra el vector ordenado
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;------------------------------------------------------------------------------
; PROCEDIMIENTO QUICK_SORT (copia de utils/05_Ordenamiento/quick_sort.asm)
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

QS_ORDENAR PROC                             ; recursion de Quick Sort
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

QS_PARTICION PROC                           ; particion de Lomuto
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
