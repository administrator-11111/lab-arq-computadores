;==============================================================================
; ARCHIVO       : mezclar_vectores_ordenados.asm
; TIPO          : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION   : Mezcla (merge) dos vectores de palabras (DW) sin signo ya
;                 ordenados ascendentemente (pueden tener tamanos distintos)
;                 en un tercer vector destino ordenado ascendentemente,
;                 mediante comparaciones directas sin volver a ordenar todo.
; FUNCIONAMIENTO: Se mantienen tres punteros (equivalentes a los tres indices
;                 i, j, k):
;                   - SI (indice i): recorre V1 mientras queden elementos (CX>0)
;                   - DI (indice j): recorre V2 mientras queden elementos (DX>0)
;                   - BX (indice k): escribe siempre en la siguiente posicion
;                     libre del vector destino V3.
;                 1) Mientras CX > 0 y DX > 0, compara [SI] con [DI]:
;                    - Si [SI] <= [DI]: copia [SI] en [BX], avanza SI en 2,
;                      decrementa CX y avanza BX en 2.
;                    - Si [DI] < [SI]: copia [DI] en [BX], avanza DI en 2,
;                      decrementa DX y avanza BX en 2.
;                 2) Cuando uno de los dos vectores se agota, copia todos los
;                    elementos sobrantes del otro vector directamente en [BX].
;                 Complejidad: O(N1 + N2), una sola pasada por cada vector.
;
;                 Traza de ejemplo (V1: 2, 10, 25 ; V2: 5, 10):
;                   comp 2 vs 5  -> copia 2  (i=1,j=0,k=1)
;                   comp 10 vs 5 -> copia 5  (i=1,j=1,k=2)
;                   comp 10 vs 10-> copia 10 (i=2,j=1,k=3)
;                   comp 25 vs 10-> copia 10 (i=2,j=2,k=4) -> V2 agotado
;                   sobrantes V1 -> copia 25 (i=3,j=2,k=5)
;                   Resultado V3 : 2 5 10 10 25
; REGISTROS     : Entrada  : SI = offset V1 (ordenado asc), CX = N1
;                            DI = offset V2 (ordenado asc), DX = N2
;                            BX = offset V3 (destino, tamano >= N1 + N2)
;                 Salida   : AX = N1 + N2 (cantidad total escrita en V3)
;                 Modifica : AX y banderas (conserva BX, CX, DX, SI, DI)
; VARIABLES     : Ninguna variable global fija (todo por registros).
; DEPENDENCIAS  : Ninguna para MEZCLAR_VECTORES. La demo usa macros de E/S de
;                 utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                 y MOSTRAR_VECTOR de procedimientos canonicos.
; COMO INTEGRAR : 1. Copiar el bloque MEZCLAR_VECTORES en CODIGO despues de la
;                    salida a DOS.
;                 2. Reservar en DATOS un vector destino de al menos N1 + N2
;                    palabras (DW).
;                 3. Cargar SI=OFFSET V1, CX=N1, DI=OFFSET V2, DX=N2,
;                    BX=OFFSET V3 y ejecutar CALL MEZCLAR_VECTORES.
; EJEMPLO       : Vector 1 (5 elem): 3 12 25 40 75
;                 Vector 2 (4 elem): 5 12 30 90
;                 Mezcla   (9 elem): 3 5 12 12 25 30 40 75 90
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
    MSG_TITULO DB '=== DEMO: MEZCLAR DOS VECTORES ORDENADOS ===$' ; titulo
    MSG_V1     DB 'Vector 1 (5 elem): $'    ; etiqueta vector 1
    MSG_V2     DB 'Vector 2 (4 elem): $'    ; etiqueta vector 2
    MSG_V3     DB 'Mezcla   (9 elem): $'    ; etiqueta vector resultante
    VEC1       DW 3, 12, 25, 40, 75         ; primer vector ordenado asc
    N1         DW 5                         ; tamano de VEC1
    VEC2       DW 5, 12, 30, 90             ; segundo vector ordenado asc
    N2         DW 4                         ; tamano de VEC2
    VEC3       DW 20 DUP(0)                 ; vector destino (capacidad >= 9)
    N3         DW 0                         ; tamano resultante de VEC3
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V1                  ; muestra etiqueta VEC1
    MOV SI, OFFSET VEC1                     ; SI = VEC1
    MOV CX, N1                              ; CX = N1
    CALL MOSTRAR_VECTOR                     ; imprime VEC1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V2                  ; muestra etiqueta VEC2
    MOV SI, OFFSET VEC2                     ; SI = VEC2
    MOV CX, N2                              ; CX = N2
    CALL MOSTRAR_VECTOR                     ; imprime VEC2
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VEC1                     ; SI = puntero i (VEC1)
    MOV CX, N1                              ; CX = elementos restantes de VEC1
    MOV DI, OFFSET VEC2                     ; DI = puntero j (VEC2)
    MOV DX, N2                              ; DX = elementos restantes de VEC2
    MOV BX, OFFSET VEC3                     ; BX = puntero k (VEC3 destino)
    CALL MEZCLAR_VECTORES                   ; mezcla en VEC3, AX = N1 + N2
    MOV N3, AX                              ; guarda cantidad total resultante

    IMPRIMIR_CADENA MSG_V3                  ; muestra etiqueta VEC3
    MOV SI, OFFSET VEC3                     ; SI = VEC3
    MOV CX, N3                              ; CX = N3
    CALL MOSTRAR_VECTOR                     ; imprime vector mezclado
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: MEZCLAR_VECTORES ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO MEZCLAR_VECTORES
;   Entrada : SI = offset V1 (ascendente), CX = N1
;             DI = offset V2 (ascendente), DX = N2
;             BX = offset V3 (destino, capacidad >= N1 + N2)
;   Salida  : V3 contiene los N1+N2 elementos en orden ascendente
;             AX = N1 + N2 (total de elementos escritos)
;   Modifica: AX y banderas (conserva BX, CX, DX, SI, DI)
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
    CMP CX, 0                               ; se agoto V1 (i llego al final)?
    JE MZ_SOBRANTE_V2                       ; si: copiar lo que queda de V2
    CMP DX, 0                               ; se agoto V2 (j llego al final)?
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
;====== FIN BLOQUE REUTILIZABLE: MEZCLAR_VECTORES ======

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
