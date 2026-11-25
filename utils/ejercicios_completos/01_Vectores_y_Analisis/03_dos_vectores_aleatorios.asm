;==============================================================================
; EJERCICIO    : Generacion y despliegue de dos vectores aleatorios
; ARCHIVO      : 03_dos_vectores_aleatorios.asm
; ENUNCIADO    : Crear dos vectores de 10 numeros enteros aleatorios cada uno
;                (en el rango 1..100) y mostrar en pantalla los elementos de
;                ambos vectores.
; SOLUCION     : 1) Se inicializa la semilla aleatoria una sola vez con la hora
;                   del sistema (INICIALIZAR_SEMILLA) para que ambos vectores
;                   contengan secuencias independientes.
;                2) Se carga VECTOR_1 y luego VECTOR_2 reutilizando el mismo
;                   procedimiento LLENAR_VECTOR_ALEATORIO (solo cambiando SI).
;                3) Se muestran los elementos de VECTOR_1 y VECTOR_2 con
;                   MOSTRAR_VECTOR.
; REGISTROS    : SI = offset del vector; CX = cantidad (10); BX = minimo (1);
;                DX = maximo (100).
; VARIABLES    : SEMILLA (DW), VECTOR_1 (10 DW), VECTOR_2 (10 DW),
;                TAMANO (EQU 10), mensajes DB.
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/02_Vectores/llenar_vector_aleatorio.asm
;                - utils/02_Vectores/dos_vectores_aleatorios.asm
; EJEMPLO DE ENTRADA/SALIDA (ejecucion con --time 08:05:59.99):
;                === EJERCICIO 3: DOS VECTORES ALEATORIOS ===
;                Vector 1 (1..100): 15 49 92 85 24 39 20 40 76 25
;                Vector 2 (1..100): 45 47 37 45 90 80 29 26 84 15
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

FIN_PROGRAMA MACRO                          ; macro sin parametros
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; DOS finaliza el programa
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    SEMILLA    DW 0                         ; semilla compartida por ambos
    TAMANO     EQU 10                       ; 10 elementos por vector
    VECTOR_1   DW TAMANO DUP(0)             ; primer vector (20 bytes)
    VECTOR_2   DW TAMANO DUP(0)             ; segundo vector (20 bytes)

    MSG_TIT    DB '=== EJERCICIO 3: DOS VECTORES ALEATORIOS ===$' ; titulo
    MSG_V1     DB 'Vector 1 (1..100): $'    ; etiqueta vector 1
    MSG_V2     DB 'Vector 2 (1..100): $'    ; etiqueta vector 2
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    ; Inicializa la semilla una sola vez para no repetir secuencia
    CALL INICIALIZAR_SEMILLA                ; semilla inicial desde el reloj

    ; Llena VECTOR_1 con 10 aleatorios en 1..100
    MOV SI, OFFSET VECTOR_1                 ; SI apunta a VECTOR_1
    MOV CX, TAMANO                          ; CX = 10 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 100                             ; maximo = 100
    CALL LLENAR_VECTOR_ALEATORIO            ; genera VECTOR_1

    ; Llena VECTOR_2 con 10 aleatorios en 1..100
    MOV SI, OFFSET VECTOR_2                 ; SI apunta a VECTOR_2
    MOV CX, TAMANO                          ; CX = 10 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 100                             ; maximo = 100
    CALL LLENAR_VECTOR_ALEATORIO            ; genera VECTOR_2

    ; Muestra ambos vectores
    IMPRIMIR_CADENA MSG_V1                  ; etiqueta vector 1
    MOV SI, OFFSET VECTOR_1                 ; SI apunta a VECTOR_1
    MOV CX, TAMANO                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra VECTOR_1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V2                  ; etiqueta vector 2
    MOV SI, OFFSET VECTOR_2                 ; SI apunta a VECTOR_2
    MOV CX, TAMANO                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra VECTOR_2
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_VECTOR_ALEATORIO
;   Entrada : SI = offset del vector (DW), CX = cantidad, BX = min, DX = max
;------------------------------------------------------------------------------
LLENAR_VECTOR_ALEATORIO PROC                ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero)
    CMP CX, 0                               ; vector vacio?
    JE LVA_FIN                              ; si: termina
LVA_CICLO:                                  ; ciclo de llenado
    PUSH CX                                 ; guarda contador del ciclo
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [BX, CX]
    MOV [SI], AX                            ; guarda en el vector
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    POP CX                                  ; recupera contador
    LOOP LVA_CICLO                          ; repite CX veces
LVA_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_VECTOR_ALEATORIO ENDP                ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO INICIALIZAR_SEMILLA
;   Requiere: variable  SEMILLA DW 0  en el segmento DATOS.
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
;   Entrada : BX = valor minimo, CX = valor maximo
;   Salida  : AX = numero pseudoaleatorio en [BX, CX]
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
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad (>0)
;   Salida  : muestra los elementos separados por un espacio.
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
