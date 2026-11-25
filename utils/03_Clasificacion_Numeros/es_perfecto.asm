;==============================================================================
; ARCHIVO      : es_perfecto.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Determina si un numero entero de 16 bits sin signo es perfecto.
; FUNCIONAMIENTO: Un numero es perfecto si es igual a la suma de sus divisores
;                propios (todos sus divisores menores que el mismo). Ejemplos:
;                6 = 1+2+3, 28 = 1+2+4+7+14, 496 y 8128 (unicos 4 perfectos
;                en el rango de 16 bits). Se prueban d = 1..n/2 (calculado con
;                SHR AX, 1). Si la suma parcial genera acarreo (CF=1 tras ADD)
;                significa que supero 65535 y por tanto supera a n, asi que se
;                descarta de inmediato. 0 y 1 no son perfectos.
; REGISTROS    : Entrada  : AX = numero sin signo (0..65535)
;                Salida   : BL = 1 si es perfecto, BL = 0 si no (BH = 0)
;                Modifica : BX y banderas. Conserva AX, CX, DX, SI, DI.
; VARIABLES    : El procedimiento ES_PERFECTO no requiere variables en DATOS.
; DEPENDENCIAS : Ninguna para el procedimiento ES_PERFECTO.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable ES_PERFECTO dentro de CODIGO
;                   despues de la salida a DOS (MOV AX, 4C00h / INT 21h).
;                2) Cargar el numero en AX y ejecutar CALL ES_PERFECTO.
;                3) Consultar BL (1 = perfecto, 0 = no perfecto).
; EJEMPLO      : Prueba 0, 1, 2, 6, 12, 28, 100, 496, 8128, 65535:
;                  0 -> NO ES PERFECTO
;                  1 -> NO ES PERFECTO
;                  2 -> NO ES PERFECTO
;                  6 -> ES PERFECTO
;                  12 -> NO ES PERFECTO
;                  28 -> ES PERFECTO
;                  100 -> NO ES PERFECTO
;                  496 -> ES PERFECTO
;                  8128 -> ES PERFECTO
;                  65535 -> NO ES PERFECTO
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
    MSG_TITULO DB '=== DEMO: ES_PERFECTO (0..65535) ===$' ; titulo de la demo
    MSG_SI     DB ' -> ES PERFECTO$'        ; texto cuando BL = 1
    MSG_NO     DB ' -> NO ES PERFECTO$'     ; texto cuando BL = 0
    PRUEBAS    DW 0, 1, 2, 6, 12, 28, 100, 496, 8128, 65535 ; casos de prueba
    CANTIDAD   DW 10                        ; cantidad de valores en PRUEBAS
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo de la demo
    SALTO_LINEA                             ; baja a la siguiente linea

    MOV SI, OFFSET PRUEBAS                  ; SI apunta al primer valor
    MOV CX, CANTIDAD                        ; CX = cantidad de pruebas
DEMO_CICLO:                                 ; recorre cada numero de prueba
    MOV AX, [SI]                            ; AX = numero actual (16 bits)
    IMPRIMIR_NUMERO AX                      ; muestra el numero evaluado
    CALL ES_PERFECTO                        ; BL = 1 si AX es perfecto
    CMP BL, 1                               ; se cumplio la condicion?
    JNE DEMO_NO                             ; no: muestra mensaje negativo
    IMPRIMIR_CADENA MSG_SI                  ; si: muestra " -> ES PERFECTO"
    JMP DEMO_SIG                            ; salta a la siguiente iteracion
DEMO_NO:                                    ; rama cuando BL = 0
    IMPRIMIR_CADENA MSG_NO                  ; muestra " -> NO ES PERFECTO"
DEMO_SIG:                                   ; fin de la iteracion actual
    SALTO_LINEA                             ; nueva linea para el proximo caso
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP DEMO_CICLO                         ; decrementa CX y repite si CX<>0

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: ES_PERFECTO ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PERFECTO
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es perfecto, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero es perfecto si es igual a la suma de sus divisores
;             propios (los menores que el). Ej: 6 = 1+2+3, 28 = 1+2+4+7+14.
;             Se prueban d = 1 .. n/2 (ningun divisor propio supera n/2).
;             Si la suma desborda 16 bits (CF=1) el numero no es perfecto.
;             0 y 1 no son perfectos.
;------------------------------------------------------------------------------
ES_PERFECTO PROC                            ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    PUSH DI                                 ; guarda DI (suma de divisores)
    MOV BX, 0                               ; supone "no es perfecto"
    CMP AX, 2                               ; n < 2 ?
    JB EPER_FIN                             ; 0 y 1 no son perfectos
    MOV SI, AX                              ; SI = n
    XOR DI, DI                              ; suma = 0
    MOV CX, 1                               ; primer divisor d = 1
EPER_CICLO:                                 ; recorre los candidatos
    MOV AX, SI                              ; AX = n
    SHR AX, 1                               ; AX = n / 2 (desplazar = /2)
    CMP CX, AX                              ; d > n/2 ?
    JA EPER_COMPARAR                        ; si: termino la busqueda
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; d divide a n?
    JNE EPER_SIGUIENTE                      ; no: prueba el siguiente
    ADD DI, CX                              ; suma += d
    JC EPER_FIN                             ; desborde: no puede ser perfecto
EPER_SIGUIENTE:                             ; avanza al siguiente divisor
    INC CX                                  ; d = d + 1
    JMP EPER_CICLO                          ; repite
EPER_COMPARAR:                              ; termino de sumar
    CMP DI, SI                              ; suma == n ?
    JNE EPER_FIN                            ; distinto: no es perfecto
    MOV BL, 1                               ; igual: es perfecto
EPER_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_PERFECTO ENDP                            ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: ES_PERFECTO ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
