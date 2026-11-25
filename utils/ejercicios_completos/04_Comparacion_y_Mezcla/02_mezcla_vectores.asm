;==============================================================================
; EJERCICIO    : Mezclar dos vectores ordenados ascendentes en un tercer vector
; ARCHIVO      : 02_mezcla_vectores.asm
; ENUNCIADO    : Dados dos vectores ya ordenados ascendentemente (de tamanos
;                distintos), mezclarlos en un tercer vector manteniendo el
;                orden ascendente mediante comparaciones directas (sin volver
;                a ordenar todo), y mostrar los tres vectores por pantalla.
; SOLUCION     : 1) Define VEC1 (5 elementos) y VEC2 (6 elementos) en orden
;                   ascendente en DATOS, y reserva VEC3 de 15 palabras.
;                2) Muestra VEC1 y VEC2 con MOSTRAR_VECTOR.
;                3) Llama a MEZCLAR_VECTORES con SI=VEC1, CX=N1, DI=VEC2,
;                   DX=N2, BX=VEC3. La rutina recorre ambos con tres punteros
;                   y copia los elementos sobrantes en O(N1 + N2).
;                4) Guarda en N3 el total devuelto en AX y muestra VEC3.
; REGISTROS    : SI = indice i (VEC1), DI = indice j (VEC2), BX = indice k
;                (VEC3), CX = restantes de VEC1, DX = restantes de VEC2,
;                AX = elemento actual / total N1 + N2 al retornar.
; VARIABLES    : VEC1 DW 5 elem, N1 DW 5, VEC2 DW 6 elem, N2 DW 6,
;                VEC3 DW 15 DUP(0), N3 DW 0.
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/10_Comparacion_y_Mezcla_Vectores/mezclar_vectores_ordenados.asm
; EJEMPLO DE ENTRADA/SALIDA:
;                === EJERCICIO: MEZCLA DE DOS VECTORES ORDENADOS ===
;                Vector 1 (5 elem) : 4 15 22 48 90
;                Vector 2 (6 elem) : 2 15 19 35 60 105
;                Vector 3 (11 elem): 2 4 15 15 19 22 35 48 60 90 105
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
    MSG_TITULO DB '=== EJERCICIO: MEZCLA DE DOS VECTORES ORDENADOS ===$' ; tit
    MSG_V1     DB 'Vector 1 (5 elem) : $'   ; etiqueta vector 1
    MSG_V2     DB 'Vector 2 (6 elem) : $'   ; etiqueta vector 2
    MSG_V3     DB 'Vector 3 (11 elem): $'   ; etiqueta vector resultante
    VEC1       DW 4, 15, 22, 48, 90         ; primer vector ordenado ascendente
    N1         DW 5                         ; cantidad de elementos de VEC1
    VEC2       DW 2, 15, 19, 35, 60, 105    ; segundo vector ordenado ascendente
    N2         DW 6                         ; cantidad de elementos de VEC2
    VEC3       DW 15 DUP(0)                 ; vector destino (capacidad >= 11)
    N3         DW 0                         ; tamano resultante de VEC3
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V1                  ; muestra VEC1
    MOV SI, OFFSET VEC1                     ; SI = VEC1
    MOV CX, N1                              ; CX = N1
    CALL MOSTRAR_VECTOR                     ; imprime VEC1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V2                  ; muestra VEC2
    MOV SI, OFFSET VEC2                     ; SI = VEC2
    MOV CX, N2                              ; CX = N2
    CALL MOSTRAR_VECTOR                     ; imprime VEC2
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VEC1                     ; SI = indice i (VEC1)
    MOV CX, N1                              ; CX = restantes de VEC1
    MOV DI, OFFSET VEC2                     ; DI = indice j (VEC2)
    MOV DX, N2                              ; DX = restantes de VEC2
    MOV BX, OFFSET VEC3                     ; BX = indice k (VEC3 destino)
    CALL MEZCLAR_VECTORES                   ; mezcla directa, AX = N1 + N2
    MOV N3, AX                              ; guarda cantidad total en N3

    IMPRIMIR_CADENA MSG_V3                  ; muestra VEC3 mezclado
    MOV SI, OFFSET VEC3                     ; SI = VEC3
    MOV CX, N3                              ; CX = N3 (11)
    CALL MOSTRAR_VECTOR                     ; imprime VEC3
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;------------------------------------------------------------------------------
; PROCEDIMIENTO MEZCLAR_VECTORES
;   Copia de utils/10_Comparacion_y_Mezcla_Vectores/mezclar_vectores_ordenados.asm
;------------------------------------------------------------------------------
MEZCLAR_VECTORES PROC                       ; inicio del procedimiento
    PUSH BX                                 ; guarda puntero k original
    PUSH CX                                 ; guarda N1 original
    PUSH DX                                 ; guarda N2 original
    PUSH SI                                 ; guarda puntero i original
    PUSH DI                                 ; guarda puntero j original

    MOV AX, CX                              ; AX = N1
    ADD AX, DX                              ; AX = N1 + N2 (valor de retorno)
    PUSH AX                                 ; guarda el total para el final

MZ_COMPARAR:                                ; mientras queden en V1 y en V2
    CMP CX, 0                               ; se agoto V1?
    JE MZ_SOBRANTE_V2                       ; si: copiar lo que queda de V2
    CMP DX, 0                               ; se agoto V2?
    JE MZ_SOBRANTE_V1                       ; si: copiar lo que queda de V1

    MOV AX, [SI]                            ; AX = V1[i]
    CMP AX, [DI]                            ; compara V1[i] con V2[j]
    JBE MZ_TOMAR_V1                         ; V1[i] <= V2[j]: tomar de V1

    MOV AX, [DI]                            ; toma V2[j] (es menor)
    MOV [BX], AX                            ; V3[k] = V2[j]
    ADD DI, 2                               ; avanza indice j (2 bytes)
    DEC DX                                  ; un elemento menos en V2
    ADD BX, 2                               ; avanza indice k (2 bytes)
    JMP MZ_COMPARAR                         ; continua comparando

MZ_TOMAR_V1:                                ; copia elemento desde V1
    MOV [BX], AX                            ; V3[k] = V1[i]
    ADD SI, 2                               ; avanza indice i (2 bytes)
    DEC CX                                  ; un elemento menos en V1
    ADD BX, 2                               ; avanza indice k (2 bytes)
    JMP MZ_COMPARAR                         ; continua comparando

MZ_SOBRANTE_V1:                             ; copia elementos restantes de V1
    CMP CX, 0                               ; quedan elementos en V1?
    JE MZ_FIN                               ; no: mezcla terminada
    MOV AX, [SI]                            ; lee V1[i]
    MOV [BX], AX                            ; escribe en V3[k]
    ADD SI, 2                               ; avanza indice i
    ADD BX, 2                               ; avanza indice k
    DEC CX                                  ; decrementa restantes de V1
    JMP MZ_SOBRANTE_V1                      ; repite hasta vaciar V1

MZ_SOBRANTE_V2:                             ; copia elementos restantes de V2
    CMP DX, 0                               ; quedan elementos en V2?
    JE MZ_FIN                               ; no: mezcla terminada
    MOV AX, [DI]                            ; lee V2[j]
    MOV [BX], AX                            ; escribe en V3[k]
    ADD DI, 2                               ; avanza indice j
    ADD BX, 2                               ; avanza indice k
    DEC DX                                  ; decrementa restantes de V2
    JMP MZ_SOBRANTE_V2                      ; repite hasta vaciar V2

MZ_FIN:                                     ; salida comun
    POP AX                                  ; recupera AX = N1 + N2
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador con AX
MEZCLAR_VECTORES ENDP                       ; fin del procedimiento

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
