;==============================================================================
; ARCHIVO      : seleccion_posiciones_aleatorias.asm
; TIPO         : ALGORITMO (+ programa de demostracion)
; DESCRIPCION  : Llena un vector de 20 aleatorios, selecciona 5 POSICIONES
;                aleatorias distintas (0..19) mediante un arreglo auxiliar de
;                marcas USADA, muestra las posiciones y valores elegidos y
;                calcula el promedio de los 5 (parte entera + residuo).
; FUNCIONAMIENTO:
;   1) Diferencia clave entre POSICION y VALOR:
;      Se exige que no se repitan las POSICIONES (indices 0..19), NO los
;      valores almacenados. Si VECTOR[3] = 25 y VECTOR[14] = 25, elegir las
;      posiciones 3 y 14 es valido aunque ambos valores sean 25.
;   2) Se usa un vector de marcas USADA DB 20 DUP(0), donde USADA[p] = 0
;      indica "posicion libre" y USADA[p] = 1 indica "ya elegida".
;   3) Para cada una de las 5 selecciones se genera p en [0, 19]. Si
;      USADA[p] == 1 se descarta y se genera otra posicion. Cuando se halla
;      una libre, se marca USADA[p] = 1 y se guarda p en POSICIONES.
;   4) Para leer VECTOR[p], como VECTOR es de palabras (DW = 2 bytes), se
;      calcula el desplazamiento en bytes: BX = p * 2 (SHL BX, 1).
;   5) Se acumulan los 5 valores en SUMA y se divide por 5 (DIV) para obtener
;      PROMEDIO (cociente en AX) y RESIDUO (resto en DX).
; REGISTROS    :
;   SELECCIONAR_POSICIONES -> Entrada: DI = offset de POSICIONES (DW),
;                             CX = cantidad de posiciones a elegir (<= 20).
;                             Usa USADA en DATOS. Conserva AX, BX, CX, DX, DI.
; VARIABLES    : SEMILLA DW 0, VECTOR DW 20 DUP(0), USADA DB 20 DUP(0),
;                POSICIONES DW 5 DUP(0), SUMA DW 0, PROMEDIO DW 0, RESIDUO DW 0.
; DEPENDENCIAS : Macros de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y procedimientos INICIALIZAR_SEMILLA, GENERAR_ALEATORIO,
;                MOSTRAR_VECTOR.
; COMO INTEGRAR: Copiar las macros, declarar SEMILLA, USADA DB 20 DUP(0) y
;                POSICIONES en DATOS, y copiar SELECCIONAR_POSICIONES junto con
;                el generador canonico dentro de CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      :
;   Vector de 20 aleatorios (1..50):
;   12 37 5 44 19 28 3 41 16 25 9 33 50 7 22 48 11 30 6 14
;   5 posiciones aleatorias distintas y sus valores:
;     Posicion 14 -> Valor 22
;     Posicion 2 -> Valor 5
;     Posicion 19 -> Valor 14
;     Posicion 7 -> Valor 41
;     Posicion 0 -> Valor 12
;   Suma    : 94
;   Promedio: 18 (residuo 4/5)
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
    SEMILLA    DW 0                         ; semilla del generador LCG
    VECTOR     DW 20 DUP(0)                 ; vector de 20 numeros aleatorios
    USADA      DB 20 DUP(0)                 ; marcas: 0=libre, 1=ya elegida
    POSICIONES DW 5 DUP(0)                  ; las 5 posiciones seleccionadas
    SUMA       DW 0                         ; suma de los 5 valores elegidos
    PROMEDIO   DW 0                         ; cociente entero de SUMA / 5
    RESIDUO    DW 0                         ; residuo de SUMA / 5
    MSG_VEC    DB 'Vector de 20 aleatorios (1..50):$'               ; titulo
    MSG_SEL    DB '5 posiciones aleatorias distintas y sus valores:$'; titulo 2
    MSG_POS    DB '  Posicion $'                                    ; prefijo
    MSG_VAL    DB ' -> Valor $'                                     ; separador
    MSG_SUMA   DB 'Suma    : $'                                     ; suma
    MSG_PROM   DB 'Promedio: $'                                     ; promedio
    MSG_RES1   DB ' (residuo $'                                     ; residuo
    MSG_RES2   DB '/5)$'                                            ; cierre
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    CALL INICIALIZAR_SEMILLA                ; semilla inicial desde la hora

    ; --- 1) Llenar el vector de 20 elementos en [1, 50] ---
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio de VECTOR
    MOV CX, 20                              ; CX = 20 elementos
LLENAR_VEC:                                 ; ciclo de llenado
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; minimo = 1
    MOV CX, 50                              ; maximo = 50 (permite repetidos)
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 50]
    MOV [SI], AX                            ; guarda el valor en VECTOR
    ADD SI, 2                               ; avanza a la siguiente palabra
    POP CX                                  ; recupera contador del ciclo
    LOOP LLENAR_VEC                         ; repite 20 veces

    IMPRIMIR_CADENA MSG_VEC                 ; muestra cabecera del vector
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VECTOR                   ; SI = inicio de VECTOR
    MOV CX, 20                              ; CX = 20 elementos
    CALL MOSTRAR_VECTOR                     ; imprime los 20 valores
    SALTO_LINEA                             ; nueva linea

    ; --- 2) Seleccionar 5 posiciones distintas en [0, 19] ---
    MOV DI, OFFSET POSICIONES               ; DI = destino de las posiciones
    MOV CX, 5                               ; CX = 5 posiciones distintas
    CALL SELECCIONAR_POSICIONES             ; llena POSICIONES sin repetir

    ; --- 3) Mostrar posiciones, valores y acumular la suma ---
    IMPRIMIR_CADENA MSG_SEL                 ; muestra cabecera de seleccion
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET POSICIONES               ; SI recorre POSICIONES
    MOV CX, 5                               ; CX = 5 elementos elegidos
    MOV SUMA, 0                             ; inicializa acumulador en 0
MOSTRAR_SEL:                                ; recorre las 5 posiciones
    MOV AX, [SI]                            ; AX = posicion elegida (0..19)
    IMPRIMIR_CADENA MSG_POS                 ; imprime "  Posicion "
    IMPRIMIR_NUMERO AX                      ; imprime el indice de posicion
    MOV BX, AX                              ; BX = indice logico p
    SHL BX, 1                               ; BX = p * 2 (desplaz. en bytes)
    MOV AX, VECTOR[BX]                      ; AX = VECTOR[p]
    ADD SUMA, AX                            ; acumula en SUMA
    IMPRIMIR_CADENA MSG_VAL                 ; imprime " -> Valor "
    IMPRIMIR_NUMERO AX                      ; imprime el valor de esa posicion
    SALTO_LINEA                             ; nueva linea
    ADD SI, 2                               ; siguiente posicion (2 bytes)
    DEC CX                                  ; decrementa contador (LOOP no
    JZ FIN_MOSTRAR_SEL                      ; alcanza por macros en el cuerpo)
    JMP MOSTRAR_SEL                         ; repite hasta completar los 5
FIN_MOSTRAR_SEL:                            ; fin del ciclo de muestra

    ; --- 4) Calcular promedio entero y residuo (SUMA / 5) ---
    MOV AX, SUMA                            ; AX = suma total
    XOR DX, DX                              ; DX = 0 para DIV de 16 bits
    MOV BX, 5                               ; BX = divisor (5 elementos)
    DIV BX                                  ; AX = cociente, DX = residuo
    MOV PROMEDIO, AX                        ; guarda parte entera
    MOV RESIDUO, DX                         ; guarda residuo (0..4)

    IMPRIMIR_CADENA MSG_SUMA                ; muestra "Suma    : "
    IMPRIMIR_NUMERO SUMA                    ; imprime la suma
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_PROM                ; muestra "Promedio: "
    IMPRIMIR_NUMERO PROMEDIO                ; imprime el cociente entero
    IMPRIMIR_CADENA MSG_RES1                ; muestra " (residuo "
    IMPRIMIR_NUMERO RESIDUO                 ; imprime el residuo
    IMPRIMIR_CADENA MSG_RES2                ; muestra "/5)"
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: SELECCIONAR_POSICIONES ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO SELECCIONAR_POSICIONES
;   Entrada : DI = offset de vector destino (DW), CX = cantidad a elegir (<=20).
;   Requiere: USADA DB 20 DUP(0) en DATOS, GENERAR_ALEATORIO y SEMILLA lista.
;   Salida  : llena [DI] con CX posiciones distintas en [0, 19].
;   Modifica: USADA, el vector destino y SEMILLA. Conserva AX, BX, CX, DX, DI.
;------------------------------------------------------------------------------
SELECCIONAR_POSICIONES PROC                 ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI

    ; Limpia el vector de marcas USADA (20 bytes a 0) para permitir reutilizar
    MOV SI, OFFSET USADA                    ; SI = inicio de USADA
    PUSH CX                                 ; guarda cantidad pedida
    MOV CX, 20                              ; 20 marcas a limpiar
SP_LIMPIAR:                                 ; ciclo de limpieza
    MOV BYTE PTR [SI], 0                    ; marca posicion como libre (0)
    INC SI                                  ; siguiente byte
    LOOP SP_LIMPIAR                         ; repite 20 veces
    POP CX                                  ; recupera cantidad a elegir

    CMP CX, 0                               ; pidieron 0 posiciones?
    JE SP_FIN                               ; si: termina de inmediato
SP_ELEGIR:                                  ; ciclo para elegir cada posicion
    PUSH CX                                 ; guarda el contador restante
SP_PROBAR:                                  ; genera hasta hallar una libre
    MOV BX, 0                               ; minimo = posicion 0
    MOV CX, 19                              ; maximo = posicion 19
    CALL GENERAR_ALEATORIO                  ; AX = posicion candidata (0..19)
    MOV BX, AX                              ; BX = indice en USADA (bytes)
    CMP USADA[BX], 1                        ; ya fue elegida esa posicion?
    JE SP_PROBAR                            ; si: descarta y genera otra
    MOV USADA[BX], 1                        ; no: la marca como usada (1)
    MOV [DI], AX                            ; guarda la posicion elegida
    ADD DI, 2                               ; avanza al siguiente DW destino
    POP CX                                  ; recupera contador restante
    LOOP SP_ELEGIR                          ; repite hasta completar CX
SP_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
SELECCIONAR_POSICIONES ENDP                 ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: SELECCIONAR_POSICIONES ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO INICIALIZAR_SEMILLA (canonico)
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
; PROCEDIMIENTO GENERAR_ALEATORIO (canonico)
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
; PROCEDIMIENTO MOSTRAR_VECTOR (canonico)
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
END INICIO                                  ; fin del programa
