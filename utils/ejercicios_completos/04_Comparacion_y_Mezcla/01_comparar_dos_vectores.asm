;==============================================================================
; EJERCICIO    : Comparar dos vectores posicion por posicion y determinar ganador
; ARCHIVO      : 01_comparar_dos_vectores.asm
; ENUNCIADO    : Dados dos vectores del mismo tamano (8 elementos aleatorios
;                entre 1 y 20), mostrar ambos vectores, comparar posicion por
;                posicion sumando un punto al vector que tenga el valor mayor
;                (los empates en una posicion no suman), mostrar el puntaje de
;                cada vector e indicar cual gano o si hubo EMPATE.
; SOLUCION     : 1) Inicializa la semilla desde el reloj del sistema.
;                2) Llena VEC1 y VEC2 con 8 numeros aleatorios en [1, 20].
;                3) Muestra ambos vectores con MOSTRAR_VECTOR.
;                4) Llama a COMPARAR_VECTORES, que acumula en PUNTOS_V1 y
;                   PUNTOS_V2 y retorna en AX: 1 (gana V1), 2 (gana V2) o 0
;                   (empate).
;                5) Imprime los puntajes y el resultado final.
; REGISTROS    : SI = puntero a VEC1, DI = puntero a VEC2, CX = cantidad,
;                AX = ganador (0/1/2) o elemento V1[i], DX = elemento V2[i].
; VARIABLES    : VEC1 DW 8 DUP(0), VEC2 DW 8 DUP(0), N_ELEM DW 8,
;                PUNTOS_V1 DW 0, PUNTOS_V2 DW 0, SEMILLA DW 0.
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/10_Comparacion_y_Mezcla_Vectores/comparar_dos_vectores.asm
; EJEMPLO DE ENTRADA/SALIDA (run8086.py --time 12:30:45.10):
;                === EJERCICIO: COMPARAR DOS VECTORES ===
;                Vector 1 : 2 8 18 6 15 5 10 19
;                Vector 2 : 1 4 16 10 18 11 16 13
;                Puntos Vector 1: 4
;                Puntos Vector 2: 4
;                Resultado      : EMPATE
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
    MSG_TITULO DB '=== EJERCICIO: COMPARAR DOS VECTORES ===$' ; titulo
    MSG_V1     DB 'Vector 1 : $'            ; etiqueta vector 1
    MSG_V2     DB 'Vector 2 : $'            ; etiqueta vector 2
    MSG_P1     DB 'Puntos Vector 1: $'      ; etiqueta puntos vector 1
    MSG_P2     DB 'Puntos Vector 2: $'      ; etiqueta puntos vector 2
    MSG_RES    DB 'Resultado      : $'      ; etiqueta resultado final
    MSG_G1     DB 'GANA VECTOR 1$'          ; texto ganador 1
    MSG_G2     DB 'GANA VECTOR 2$'          ; texto ganador 2
    MSG_EMP    DB 'EMPATE$'                 ; texto empate
    VEC1       DW 8 DUP(0)                  ; primer vector de 8 palabras
    VEC2       DW 8 DUP(0)                  ; segundo vector de 8 palabras
    N_ELEM     DW 8                         ; tamano comun de ambos vectores
    PUNTOS_V1  DW 0                         ; acumulador de puntos de VEC1
    PUNTOS_V2  DW 0                         ; acumulador de puntos de VEC2
    SEMILLA    DW 0                         ; semilla del generador aleatorio
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    CALL INICIALIZAR_SEMILLA                ; semilla desde el reloj del sistema

    MOV SI, OFFSET VEC1                     ; llena VEC1 con 8 valores 1..20
    MOV CX, N_ELEM                          ; CX = 8
LLENAR_V1:                                  ; ciclo llenado de VEC1
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; valor minimo = 1
    MOV CX, 20                              ; valor maximo = 20
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 20]
    MOV [SI], AX                            ; guarda en VEC1
    ADD SI, 2                               ; siguiente palabra
    POP CX                                  ; recupera contador
    LOOP LLENAR_V1                          ; repite 8 veces

    MOV SI, OFFSET VEC2                     ; llena VEC2 con 8 valores 1..20
    MOV CX, N_ELEM                          ; CX = 8
LLENAR_V2:                                  ; ciclo llenado de VEC2
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; valor minimo = 1
    MOV CX, 20                              ; valor maximo = 20
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 20]
    MOV [SI], AX                            ; guarda en VEC2
    ADD SI, 2                               ; siguiente palabra
    POP CX                                  ; recupera contador
    LOOP LLENAR_V2                          ; repite 8 veces

    IMPRIMIR_CADENA MSG_V1                  ; muestra VEC1
    MOV SI, OFFSET VEC1                     ; SI = VEC1
    MOV CX, N_ELEM                          ; CX = 8
    CALL MOSTRAR_VECTOR                     ; imprime VEC1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V2                  ; muestra VEC2
    MOV SI, OFFSET VEC2                     ; SI = VEC2
    MOV CX, N_ELEM                          ; CX = 8
    CALL MOSTRAR_VECTOR                     ; imprime VEC2
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VEC1                     ; SI = vector 1
    MOV DI, OFFSET VEC2                     ; DI = vector 2
    MOV CX, N_ELEM                          ; CX = cantidad
    CALL COMPARAR_VECTORES                  ; AX = 0 empate, 1 V1, 2 V2

    IMPRIMIR_CADENA MSG_P1                  ; imprime puntos de VEC1
    IMPRIMIR_NUMERO PUNTOS_V1               ; valor de PUNTOS_V1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_P2                  ; imprime puntos de VEC2
    IMPRIMIR_NUMERO PUNTOS_V2               ; valor de PUNTOS_V2
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_RES                 ; imprime texto de resultado
    CMP AX, 1                               ; gano VEC1?
    JE ET_GANA_V1                           ; si: mostrar GANA VECTOR 1
    CMP AX, 2                               ; gano VEC2?
    JE ET_GANA_V2                           ; si: mostrar GANA VECTOR 2
    IMPRIMIR_CADENA MSG_EMP                 ; si no: EMPATE
    JMP FIN_SALIDA                          ; salta al cierre
ET_GANA_V1:                                 ; rama ganador 1
    IMPRIMIR_CADENA MSG_G1                  ; muestra GANA VECTOR 1
    JMP FIN_SALIDA                          ; salta al cierre
ET_GANA_V2:                                 ; rama ganador 2
    IMPRIMIR_CADENA MSG_G2                  ; muestra GANA VECTOR 2

FIN_SALIDA:                                 ; cierre del programa
    SALTO_LINEA                             ; nueva linea
    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_VECTORES
;   Copia de utils/10_Comparacion_y_Mezcla_Vectores/comparar_dos_vectores.asm
;------------------------------------------------------------------------------
COMPARAR_VECTORES PROC                      ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (contador)
    PUSH DX                                 ; guarda DX (elemento de V2)
    PUSH SI                                 ; guarda SI (puntero V1)
    PUSH DI                                 ; guarda DI (puntero V2)

    MOV PUNTOS_V1, 0                        ; reinicia puntos de V1
    MOV PUNTOS_V2, 0                        ; reinicia puntos de V2
    CMP CX, 0                               ; vectores vacios?
    JE CV_DECIDIR                           ; si: 0 vs 0 es empate

CV_CICLO:                                   ; recorre posicion por posicion
    MOV AX, [SI]                            ; AX = V1[i]
    MOV DX, [DI]                            ; DX = V2[i]
    CMP AX, DX                              ; compara V1[i] con V2[i]
    JE CV_SIGUIENTE                         ; iguales: no suman a ninguno
    JA CV_PUNTO_V1                          ; V1[i] > V2[i] (sin signo)
    INC PUNTOS_V2                           ; V2[i] > V1[i]: punto para V2
    JMP CV_SIGUIENTE                        ; pasa a la siguiente posicion

CV_PUNTO_V1:                                ; suma punto al primer vector
    INC PUNTOS_V1                           ; PUNTOS_V1 = PUNTOS_V1 + 1

CV_SIGUIENTE:                               ; avanza ambos punteros
    ADD SI, 2                               ; siguiente palabra en V1
    ADD DI, 2                               ; siguiente palabra en V2
    LOOP CV_CICLO                           ; repite CX veces

CV_DECIDIR:                                 ; determina ganador o empate
    MOV AX, PUNTOS_V1                       ; AX = puntaje de V1
    CMP AX, PUNTOS_V2                       ; compara PUNTOS_V1 con PUNTOS_V2
    JE CV_EMPATE                            ; iguales -> empate
    JA CV_GANA_V1                           ; PUNTOS_V1 > PUNTOS_V2
    MOV AX, 2                               ; gana vector 2
    JMP CV_FIN                              ; sale del procedimiento

CV_GANA_V1:                                 ; gano el primer vector
    MOV AX, 1                               ; codigo 1 = gana V1
    JMP CV_FIN                              ; sale del procedimiento

CV_EMPATE:                                  ; ambos empataron
    MOV AX, 0                               ; codigo 0 = empate

CV_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador con AX
COMPARAR_VECTORES ENDP                      ; fin del procedimiento

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
