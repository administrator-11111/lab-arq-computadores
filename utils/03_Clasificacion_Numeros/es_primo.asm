;==============================================================================
; ARCHIVO      : es_primo.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Determina si un numero entero de 16 bits sin signo es primo.
; FUNCIONAMIENTO: 0 y 1 no son primos por definicion. Para n >= 2 se prueban
;                divisores d = 2, 3, 4... mientras d*d <= n. Si algun residuo
;                n mod d es 0, n es compuesto. En 8086, MUL CX deja d*d en
;                DX:AX; si DX <> 0 el producto supero 65535 y por lo tanto ya
;                supera a cualquier n de 16 bits. Antes de DIV CX siempre se
;                limpia DX con XOR DX, DX porque DIV divide el par DX:AX.
; REGISTROS    : Entrada  : AX = numero sin signo (0..65535)
;                Salida   : BL = 1 si es primo, BL = 0 si no lo es (BH = 0)
;                Modifica : BX y banderas. Conserva AX, CX, DX, SI.
; VARIABLES    : El procedimiento ES_PRIMO no requiere variables en DATOS.
; DEPENDENCIAS : Ninguna para el procedimiento ES_PRIMO.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable ES_PRIMO dentro de CODIGO
;                   despues de la salida a DOS (MOV AX, 4C00h / INT 21h).
;                2) Cargar el numero en AX y ejecutar CALL ES_PRIMO.
;                3) Consultar BL (1 = primo, 0 = no primo).
; EJEMPLO      : Prueba 0, 1, 2, 3, 4, 17, 25, 97, 100, 997, 65521, 65535:
;                  0 -> NO ES PRIMO
;                  1 -> NO ES PRIMO
;                  2 -> ES PRIMO
;                  3 -> ES PRIMO
;                  4 -> NO ES PRIMO
;                  17 -> ES PRIMO
;                  25 -> NO ES PRIMO
;                  97 -> ES PRIMO
;                  100 -> NO ES PRIMO
;                  997 -> ES PRIMO
;                  65521 -> ES PRIMO
;                  65535 -> NO ES PRIMO
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
    MSG_TITULO DB '=== DEMO: ES_PRIMO (0..65535) ===$' ; titulo de la demo
    MSG_SI     DB ' -> ES PRIMO$'           ; texto cuando BL = 1
    MSG_NO     DB ' -> NO ES PRIMO$'        ; texto cuando BL = 0
    PRUEBAS    DW 0, 1, 2, 3, 4, 17, 25, 97, 100, 997, 65521, 65535 ; pruebas
    CANTIDAD   DW 12                        ; cantidad de valores en PRUEBAS
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
    CALL ES_PRIMO                           ; BL = 1 si AX es primo, 0 si no
    CMP BL, 1                               ; se cumplio la condicion?
    JNE DEMO_NO                             ; no: muestra mensaje negativo
    IMPRIMIR_CADENA MSG_SI                  ; si: muestra " -> ES PRIMO"
    JMP DEMO_SIG                            ; salta a la siguiente iteracion
DEMO_NO:                                    ; rama cuando BL = 0
    IMPRIMIR_CADENA MSG_NO                  ; muestra " -> NO ES PRIMO"
DEMO_SIG:                                   ; fin de la iteracion actual
    SALTO_LINEA                             ; nueva linea para el proximo caso
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP DEMO_CICLO                         ; decrementa CX y repite si CX<>0

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: ES_PRIMO ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PRIMO
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es primo, BL = 0 si no lo es (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI.
;   Metodo  : 0 y 1 no son primos. Para n >= 2 se prueban divisores d = 2,
;             3, 4... mientras d*d <= n. Si algun residuo es 0, no es primo.
;             Basta llegar a la raiz porque si n = a*b, uno de los dos
;             factores es <= raiz(n). MUL deja d*d en DX:AX; si DX <> 0 el
;             producto supera 65535 y por lo tanto supera a n.
;------------------------------------------------------------------------------
ES_PRIMO PROC                               ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (se usa en MUL/DIV)
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    MOV BX, 0                               ; supone "no es primo"
    CMP AX, 2                               ; n < 2 ?
    JB EPRI_FIN                             ; 0 y 1 no son primos
    MOV SI, AX                              ; SI = n (AX se reutilizara)
    MOV CX, 2                               ; primer divisor a probar
EPRI_CICLO:                                 ; prueba cada divisor
    MOV AX, CX                              ; AX = d
    MUL CX                                  ; DX:AX = d * d
    CMP DX, 0                               ; el producto paso de 16 bits?
    JNE EPRI_SI                             ; si: d*d > n, no hay divisores
    CMP AX, SI                              ; compara d*d con n
    JA EPRI_SI                              ; d*d > n: ya se probo todo
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0, dividendo DX:AX = n
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; division exacta?
    JE EPRI_FIN                             ; si: tiene divisor, no es primo
    INC CX                                  ; siguiente divisor
    JMP EPRI_CICLO                          ; repite la prueba
EPRI_SI:                                    ; no se encontro divisor
    MOV BL, 1                               ; es primo
EPRI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_PRIMO ENDP                               ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: ES_PRIMO ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
