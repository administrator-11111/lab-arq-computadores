;==============================================================================
; ARCHIVO      : factorial.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Calcula el factorial n! de un entero sin signo en 16 bits con
;                deteccion de desborde.
; FUNCIONAMIENTO: * 0! = 1 y 1! = 1 por definicion.
;                * Para n >= 2 multiplica sucesivamente AX = 1 * 2 * 3 * ... * n
;                  usando MUL CX (que deja el producto de 32 bits en DX:AX).
;                * Tras cada MUL se verifica CMP DX, 0: si DX <> 0 el factorial
;                  supero 65535 (desborde de 16 bits) y devuelve BL = 1, AX = 0.
;                * LIMITE DE 16 BITS: el maximo factorial representable en un
;                  registro de 16 bits sin signo (0..65535) es 8! = 40320.
;                  A partir de 9! = 362880 se produce desborde.
; REGISTROS    : Entrada  : AX = n (entero sin signo)
;                Salida   : AX = n! (o 0 si hubo desborde)
;                           BL = 1 si hubo desborde de 16 bits, 0 si no (BH=0)
;                Modifica : AX, BX y banderas. Conserva CX, DX, SI.
; VARIABLES    : El procedimiento FACTORIAL no requiere variables en DATOS.
; DEPENDENCIAS : Ninguna para el procedimiento FACTORIAL.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable FACTORIAL dentro de CODIGO
;                   despues de la salida a DOS.
;                2) Cargar n en AX y ejecutar CALL FACTORIAL.
;                3) Verificar BL (0 = valido en AX, 1 = desborde).
; EJEMPLO      : Prueba n = 0..9:
;                  0! = 1
;                  1! = 1
;                  2! = 2
;                  3! = 6
;                  4! = 24
;                  5! = 120
;                  6! = 720
;                  7! = 5040
;                  8! = 40320
;                  9! = DESBORDE (> 65535)
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
    MSG_TITULO DB '=== DEMO: FACTORIAL (0..9 en 16 bits) ===$' ; titulo
    MSG_IGUAL  DB '! = $'                   ; separador factorial
    MSG_DESB   DB 'DESBORDE (> 65535)$'     ; mensaje de desborde
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV CX, 0                               ; empieza en n = 0
DEMO_CICLO:                                 ; recorre n = 0 hasta 9
    MOV AX, CX                              ; AX = n actual
    IMPRIMIR_NUMERO AX                      ; muestra n
    IMPRIMIR_CADENA MSG_IGUAL               ; muestra "! = "

    CALL FACTORIAL                          ; AX = n!, BL = desborde?
    CMP BL, 1                               ; hubo desborde de 16 bits?
    JE DEMO_DESB                            ; si: informa desborde
    IMPRIMIR_NUMERO AX                      ; no: muestra n!
    JMP DEMO_SIG                            ; continua con el siguiente n
DEMO_DESB:                                  ; rama de desborde (9! en adelante)
    IMPRIMIR_CADENA MSG_DESB                ; muestra aviso de desborde
DEMO_SIG:                                   ; cierre de la iteracion
    SALTO_LINEA                             ; nueva linea
    INC CX                                  ; siguiente n
    CMP CX, 9                               ; llego hasta 9?
    JBE DEMO_CICLO                          ; mientras CX <= 9 repite

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: FACTORIAL ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO FACTORIAL
;   Entrada : AX = n (entero sin signo)
;   Salida  : AX = n! (0 si hubo desborde)
;             BL = 1 si desbordo 16 bits (n >= 9), BL = 0 si valido (BH = 0)
;   Modifica: AX, BX y banderas. Conserva CX, DX, SI.
;   Limite  : 8! = 40320 cabe en 16 bits; 9! = 362880 > 65535 (desborda).
;------------------------------------------------------------------------------
FACTORIAL PROC                              ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (multiplicador)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (limite n)
    MOV BX, 0                               ; supone sin desborde (BH=0, BL=0)
    MOV SI, AX                              ; SI = n
    MOV AX, 1                               ; resultado = 1 (cubre 0! y 1!)
    CMP SI, 1                               ; n <= 1?
    JBE FAC_FIN                             ; si: 0! = 1 y 1! = 1
    MOV CX, 2                               ; primer factor del producto
FAC_CICLO:                                  ; multiplica AX por 2, 3, ..., n
    MUL CX                                  ; DX:AX = AX * CX
    CMP DX, 0                               ; el producto supero 16 bits?
    JNE FAC_DESBORDE                        ; si: desborde (> 65535)
    CMP CX, SI                              ; ya multiplico por n?
    JE FAC_FIN                              ; si: termina con resultado en AX
    INC CX                                  ; siguiente factor
    JMP FAC_CICLO                           ; repite
FAC_DESBORDE:                               ; ocurrio desborde
    MOV AX, 0                               ; limpia resultado invalido
    MOV BL, 1                               ; activa indicador de desborde
FAC_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
FACTORIAL ENDP                              ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: FACTORIAL ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
