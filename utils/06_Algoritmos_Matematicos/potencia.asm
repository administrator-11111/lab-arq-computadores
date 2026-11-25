;==============================================================================
; ARCHIVO      : potencia.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Calcula la potencia entera base^exponente en 16 bits sin signo
;                con deteccion de desborde.
; FUNCIONAMIENTO: * Si el exponente CX es 0, devuelve inmediatamente 1 (BL = 0).
;                  Por convencion algebraica/combinatoria se define 0^0 = 1,
;                  ya que el producto vacio (cero multiplicaciones) es el
;                  elemento neutro multiplicativo (1).
;                * Si CX > 0, comienza con AX = 1 y repite CX veces MUL SI
;                  (donde SI guarda la base). En 8086, MUL de 16 bits deja el
;                  producto de 32 bits en DX:AX; si DX <> 0 tras cualquier
;                  multiplicacion, el resultado supero 65535 (desborde de 16
;                  bits), por lo que detiene el ciclo y devuelve BL = 1, AX = 0.
; REGISTROS    : Entrada  : AX = base (0..65535), CX = exponente (0..65535)
;                Salida   : AX = base^exponente (o 0 si hubo desborde)
;                           BL = 1 si hubo desborde de 16 bits, 0 si no (BH=0)
;                Modifica : AX, BX y banderas. Conserva CX, DX, SI.
; VARIABLES    : El procedimiento POTENCIA no requiere variables en DATOS.
; DEPENDENCIAS : Ninguna para el procedimiento POTENCIA.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable POTENCIA dentro de CODIGO
;                   despues de la salida a DOS.
;                2) Cargar base en AX, exponente en CX y ejecutar CALL POTENCIA.
;                3) Revisar BL antes de usar AX (BL = 1 indica desborde).
; EJEMPLO      : Prueba 2^0, 2^10, 3^4, 10^4, 0^0, 2^16:
;                  2 ^ 0 = 1
;                  2 ^ 10 = 1024
;                  3 ^ 4 = 81
;                  10 ^ 4 = 10000
;                  0 ^ 0 = 1
;                  2 ^ 16 = DESBORDE (> 65535)
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
    MSG_TITULO DB '=== DEMO: POTENCIA (16 BITS SIN SIGNO) ===$' ; titulo
    MSG_ELEV   DB ' ^ $'                    ; simbolo de potencia
    MSG_IGUAL  DB ' = $'                    ; signo igual
    MSG_DESB   DB 'DESBORDE (> 65535)$'     ; mensaje de desborde
    BASES      DW 2, 2, 3, 10, 0, 2         ; bases de prueba
    EXPONENTES DW 0, 10, 4, 4, 0, 16        ; exponentes de prueba
    CANTIDAD   DW 6                         ; cantidad de casos
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET BASES                    ; SI apunta al vector de bases
    MOV DI, OFFSET EXPONENTES               ; DI apunta al vector de exponentes
    MOV CX, CANTIDAD                        ; CX = cantidad de casos
DEMO_CICLO:                                 ; recorre cada par base^exponente
    PUSH CX                                 ; guarda contador del ciclo
    MOV AX, [SI]                            ; AX = base actual
    MOV CX, [DI]                            ; CX = exponente actual

    IMPRIMIR_NUMERO AX                      ; muestra la base
    IMPRIMIR_CADENA MSG_ELEV                ; muestra " ^ "
    IMPRIMIR_NUMERO CX                      ; muestra el exponente
    IMPRIMIR_CADENA MSG_IGUAL               ; muestra " = "

    CALL POTENCIA                           ; AX = base^exp, BL = desborde?
    CMP BL, 1                               ; hubo desborde de 16 bits?
    JE DEMO_DESB                            ; si: informa desborde
    IMPRIMIR_NUMERO AX                      ; no: muestra el resultado
    JMP DEMO_SIG                            ; salta al final de iteracion
DEMO_DESB:                                  ; rama de desborde
    IMPRIMIR_CADENA MSG_DESB                ; muestra "DESBORDE (> 65535)"
DEMO_SIG:                                   ; cierre de la iteracion
    SALTO_LINEA                             ; nueva linea
    ADD SI, 2                               ; siguiente base (DW)
    ADD DI, 2                               ; siguiente exponente (DW)
    POP CX                                  ; recupera contador de casos
    DEC CX                                  ; decrementa contador (evita LOOP
    JZ DEMO_FIN                             ; fuera de rango de +-127 bytes
    JMP DEMO_CICLO                          ; por las macros expandidas)
DEMO_FIN:                                   ; fin de la demostracion

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: POTENCIA ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO POTENCIA
;   Entrada : AX = base (0..65535), CX = exponente (0..65535)
;   Salida  : AX = base^exponente (0 si hubo desborde)
;             BL = 1 si desbordo 16 bits, BL = 0 si resultado valido (BH = 0)
;   Modifica: AX, BX y banderas. Conserva CX, DX, SI.
;   Nota    : Define 0^0 = 1 (producto vacio = elemento neutro multiplicativo).
;------------------------------------------------------------------------------
POTENCIA PROC                               ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (exponente)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (base)
    MOV BX, 0                               ; supone sin desborde (BH=0, BL=0)
    MOV SI, AX                              ; SI = base
    MOV AX, 1                               ; acumulador = 1 (para exp = 0)
    CMP CX, 0                               ; exponente igual a 0?
    JE POT_FIN                              ; si: base^0 = 1 (incluye 0^0 = 1)
POT_CICLO:                                  ; multiplica CX veces por la base
    MUL SI                                  ; DX:AX = acumulador * base
    CMP DX, 0                               ; la parte alta DX es distinta de 0?
    JNE POT_DESBORDE                        ; si: supero 65535 -> desborde
    LOOP POT_CICLO                          ; CX = CX - 1 y repite si CX <> 0
    JMP POT_FIN                             ; termino sin desborde
POT_DESBORDE:                               ; ocurrio desborde de 16 bits
    MOV AX, 0                               ; limpia resultado invalido
    MOV BL, 1                               ; indica desborde en BL
POT_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
POTENCIA ENDP                               ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: POTENCIA ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
