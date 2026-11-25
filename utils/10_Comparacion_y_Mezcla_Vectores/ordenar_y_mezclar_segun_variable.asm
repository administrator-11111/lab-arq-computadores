;==============================================================================
; ARCHIVO       : ordenar_y_mezclar_segun_variable.asm
; TIPO          : ALGORITMO (+ programa de demostracion)
; DESCRIPCION   : Integra el ordenamiento controlado por la variable SENTIDO
;                 (ORDENAR_SEGUN_SENTIDO) con la mezcla directa de dos vectores
;                 ordenados (MEZCLAR_VECTORES). Parte de dos vectores
;                 desordenados, los ordena ascendentemente, los mezcla en un
;                 tercer vector y aplica el sentido final indicado por
;                 SENTIDO_FINAL (0 = ascendente, 1 = descendente).
;                 NOTA: la version de referencia del ordenamiento por variable
;                 esta en utils/05_Ordenamiento/ordenar_segun_variable.asm.
; FUNCIONAMIENTO: 1) Muestra VEC1 y VEC2 en su estado original (desordenados).
;                 2) Fija SENTIDO = 0 y llama a ORDENAR_SEGUN_SENTIDO sobre
;                    VEC1 y VEC2 para dejarlos en orden ascendente (requisito
;                    de MEZCLAR_VECTORES).
;                 3) Llama a MEZCLAR_VECTORES para construir VEC3 ordenado
;                    ascendentemente en una sola pasada O(N1 + N2).
;                 4) Copia SENTIDO_FINAL a SENTIDO y llama a
;                    ORDENAR_SEGUN_SENTIDO sobre VEC3 para presentar el
;                    resultado en el sentido deseado (ascendente o descendente).
; REGISTROS     : ORDENAR_SEGUN_SENTIDO: SI = offset, CX = cantidad (conserva
;                 todos). MEZCLAR_VECTORES: SI=V1, CX=N1, DI=V2, DX=N2, BX=V3,
;                 devuelve AX = N1 + N2.
; VARIABLES     : SENTIDO DB 0, SENTIDO_FINAL DB 1 (cambiar a 0 para ascendente
;                 o 1 para descendente) en DATOS.
; DEPENDENCIAS  : ORDENAR_SEGUN_SENTIDO copiado desde
;                 utils/05_Ordenamiento/ordenar_segun_variable.asm;
;                 MEZCLAR_VECTORES copiado desde
;                 utils/10_Comparacion_y_Mezcla_Vectores/mezclar_vectores_ordenados.asm;
;                 macros de E/S y MOSTRAR_VECTOR.
; COMO INTEGRAR : 1. Declarar SENTIDO DB 0 en DATOS junto con los vectores.
;                 2. Copiar ORDENAR_SEGUN_SENTIDO y MEZCLAR_VECTORES en CODIGO
;                    despues de la salida a DOS.
;                 3. Ordenar ambos vectores con SENTIDO=0, mezclar en V3 y, si
;                    se desea orden descendente, fijar SENTIDO=1 y ordenar V3.
; EJEMPLO       : V1 original : 45 12 80 5 22
;                 V2 original : 30 5 60 18
;                 V1 asc      : 5 12 22 45 80
;                 V2 asc      : 5 18 30 60
;                 Mezcla asc  : 5 5 12 18 22 30 45 60 80
;                 Final (SENTIDO_FINAL=1, desc): 80 60 45 30 22 18 12 5 5
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
    MSG_TITULO    DB '=== DEMO: ORDENAR Y MEZCLAR SEGUN VARIABLE ===$' ; tit
    MSG_V1_ORIG   DB 'V1 original : $'      ; etiqueta V1 desordenado
    MSG_V2_ORIG   DB 'V2 original : $'      ; etiqueta V2 desordenado
    MSG_V1_ASC    DB 'V1 asc      : $'      ; etiqueta V1 ascendente
    MSG_V2_ASC    DB 'V2 asc      : $'      ; etiqueta V2 ascendente
    MSG_MEZ_ASC   DB 'Mezcla asc  : $'      ; etiqueta mezcla ascendente
    MSG_FINAL_ASC DB 'Final (asc) : $'      ; etiqueta final ascendente
    MSG_FINAL_DES DB 'Final (desc): $'      ; etiqueta final descendente
    VEC1          DW 45, 12, 80, 5, 22      ; primer vector desordenado
    N1            DW 5                      ; tamano de VEC1
    VEC2          DW 30, 5, 60, 18          ; segundo vector desordenado
    N2            DW 4                      ; tamano de VEC2
    VEC3          DW 20 DUP(0)              ; vector resultante de la mezcla
    N3            DW 0                      ; tamano de VEC3
    SENTIDO       DB 0                      ; variable usada por el ordenador
    SENTIDO_FINAL DB 1                      ; cambiar a 0 (asc) o 1 (desc)
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V1_ORIG             ; muestra V1 original
    MOV SI, OFFSET VEC1                     ; SI = VEC1
    MOV CX, N1                              ; CX = N1
    CALL MOSTRAR_VECTOR                     ; imprime VEC1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V2_ORIG             ; muestra V2 original
    MOV SI, OFFSET VEC2                     ; SI = VEC2
    MOV CX, N2                              ; CX = N2
    CALL MOSTRAR_VECTOR                     ; imprime VEC2
    SALTO_LINEA                             ; nueva linea

    MOV SENTIDO, 0                          ; orden ascendente para mezclar
    MOV SI, OFFSET VEC1                     ; SI = VEC1
    MOV CX, N1                              ; CX = N1
    CALL ORDENAR_SEGUN_SENTIDO              ; ordena VEC1 ascendentemente

    MOV SI, OFFSET VEC2                     ; SI = VEC2
    MOV CX, N2                              ; CX = N2
    CALL ORDENAR_SEGUN_SENTIDO              ; ordena VEC2 ascendentemente

    IMPRIMIR_CADENA MSG_V1_ASC              ; muestra V1 ya ordenado asc
    MOV SI, OFFSET VEC1                     ; SI = VEC1
    MOV CX, N1                              ; CX = N1
    CALL MOSTRAR_VECTOR                     ; imprime VEC1
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_V2_ASC              ; muestra V2 ya ordenado asc
    MOV SI, OFFSET VEC2                     ; SI = VEC2
    MOV CX, N2                              ; CX = N2
    CALL MOSTRAR_VECTOR                     ; imprime VEC2
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VEC1                     ; SI = VEC1 ascendente
    MOV CX, N1                              ; CX = N1
    MOV DI, OFFSET VEC2                     ; DI = VEC2 ascendente
    MOV DX, N2                              ; DX = N2
    MOV BX, OFFSET VEC3                     ; BX = destino VEC3
    CALL MEZCLAR_VECTORES                   ; mezcla en orden ascendente
    MOV N3, AX                              ; guarda cantidad total

    IMPRIMIR_CADENA MSG_MEZ_ASC             ; muestra la mezcla ascendente
    MOV SI, OFFSET VEC3                     ; SI = VEC3
    MOV CX, N3                              ; CX = N3
    CALL MOSTRAR_VECTOR                     ; imprime VEC3 ascendente
    SALTO_LINEA                             ; nueva linea

    MOV AL, SENTIDO_FINAL                   ; toma el sentido final deseado
    MOV SENTIDO, AL                         ; configura SENTIDO
    MOV SI, OFFSET VEC3                     ; SI = VEC3
    MOV CX, N3                              ; CX = N3
    CALL ORDENAR_SEGUN_SENTIDO              ; ordena VEC3 segun SENTIDO

    CMP SENTIDO, 0                          ; sentido final ascendente?
    JNE ET_FINAL_DESC                       ; no: etiqueta descendente
    IMPRIMIR_CADENA MSG_FINAL_ASC           ; etiqueta final ascendente
    JMP MOSTRAR_FINAL                       ; salta a imprimir VEC3
ET_FINAL_DESC:                              ; caso descendente
    IMPRIMIR_CADENA MSG_FINAL_DES           ; etiqueta final descendente

MOSTRAR_FINAL:                              ; muestra el vector final
    MOV SI, OFFSET VEC3                     ; SI = VEC3
    MOV CX, N3                              ; CX = N3
    CALL MOSTRAR_VECTOR                     ; imprime resultado final
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: ORDENAR_SEGUN_SENTIDO ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ORDENAR_SEGUN_SENTIDO
;   Copia de utils/05_Ordenamiento/ordenar_segun_variable.asm
;   Entrada : SI = offset del vector (DW), CX = cantidad de elementos
;             Variable global SENTIDO DB (0 = ascendente, 1 = descendente)
;   Salida  : vector ordenado en el mismo espacio de memoria
;   Modifica: nada (conserva AX, BX, CX, DX, SI, DI)
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
;====== FIN BLOQUE REUTILIZABLE: ORDENAR_SEGUN_SENTIDO ======

;====== INICIO BLOQUE REUTILIZABLE: MEZCLAR_VECTORES ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO MEZCLAR_VECTORES
;   Copia de utils/10_Comparacion_y_Mezcla_Vectores/mezclar_vectores_ordenados.asm
;   Entrada : SI = offset V1 (ascendente), CX = N1
;             DI = offset V2 (ascendente), DX = N2
;             BX = offset V3 (destino, capacidad >= N1 + N2)
;   Salida  : AX = N1 + N2 (total de elementos escritos en V3)
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
    CMP CX, 0                               ; se agoto V1?
    JE MZ_SOBRANTE_V2                       ; si: copiar lo que queda de V2
    CMP DX, 0                               ; se agoto V2?
    JE MZ_SOBRANTE_V1                       ; si: copiar lo que queda de V1

    MOV AX, [SI]                            ; AX = V1[i]
    CMP AX, [DI]                            ; compara V1[i] con V2[j]
    JBE MZ_TOMAR_V1                         ; V1[i] <= V2[j]: tomar de V1

    MOV AX, [DI]                            ; toma V2[j] (es menor)
    MOV [BX], AX                            ; V3[k] = V2[j]
    ADD DI, 2                               ; avanza indice j
    DEC DX                                  ; un elemento menos en V2
    ADD BX, 2                               ; avanza indice k
    JMP MZ_COMPARAR                         ; continua comparando

MZ_TOMAR_V1:                                ; copia elemento desde V1
    MOV [BX], AX                            ; V3[k] = V1[i]
    ADD SI, 2                               ; avanza indice i
    DEC CX                                  ; un elemento menos en V1
    ADD BX, 2                               ; avanza indice k
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
