;==============================================================================
; ARCHIVO      : es_par.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Determina si un numero entero de 16 bits sin signo es par.
; FUNCIONAMIENTO: En binario, todo numero par termina en bit 0 igual a 0 y todo
;                impar termina en bit 0 igual a 1 (porque todas las demas
;                potencias de 2 son pares). La instruccion TEST AX, 1 realiza
;                un AND bit a bit entre AX y 1 sin modificar AX, actualizando
;                solo las banderas: si ZF=1 el bit 0 era 0 (es par), si ZF=0
;                el bit 0 era 1 (es impar). Es mas rapido que dividir por 2.
; REGISTROS    : Entrada  : AX = numero sin signo (0..65535)
;                Salida   : BL = 1 si es par, BL = 0 si es impar (BH = 0)
;                Modifica : BX y banderas. Conserva AX, CX, DX, SI, DI.
; VARIABLES    : El procedimiento ES_PAR no requiere variables en DATOS.
; DEPENDENCIAS : Ninguna para el procedimiento ES_PAR.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable ES_PAR dentro de CODIGO
;                   despues de la salida a DOS (MOV AX, 4C00h / INT 21h).
;                2) Cargar el numero en AX y ejecutar CALL ES_PAR.
;                3) Consultar BL (1 = par, 0 = impar).
; EJEMPLO      : Prueba 0, 1, 2, 7, 14, 100, 32767, 65534, 65535:
;                  0 -> ES PAR
;                  1 -> NO ES PAR
;                  2 -> ES PAR
;                  7 -> NO ES PAR
;                  14 -> ES PAR
;                  100 -> ES PAR
;                  32767 -> NO ES PAR
;                  65534 -> ES PAR
;                  65535 -> NO ES PAR
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
    MSG_TITULO DB '=== DEMO: ES_PAR (0..65535) ===$'  ; titulo de la demo
    MSG_SI     DB ' -> ES PAR$'             ; texto cuando BL = 1
    MSG_NO     DB ' -> NO ES PAR$'          ; texto cuando BL = 0
    PRUEBAS    DW 0, 1, 2, 7, 14, 100, 32767, 65534, 65535 ; casos de prueba
    CANTIDAD   DW 9                         ; cantidad de valores en PRUEBAS
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
    CALL ES_PAR                             ; BL = 1 si AX es par, 0 si no
    CMP BL, 1                               ; se cumplio la condicion?
    JNE DEMO_NO                             ; no: muestra mensaje negativo
    IMPRIMIR_CADENA MSG_SI                  ; si: muestra " -> ES PAR"
    JMP DEMO_SIG                            ; salta a la siguiente iteracion
DEMO_NO:                                    ; rama cuando BL = 0
    IMPRIMIR_CADENA MSG_NO                  ; muestra " -> NO ES PAR"
DEMO_SIG:                                   ; fin de la iteracion actual
    SALTO_LINEA                             ; nueva linea para el proximo caso
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP DEMO_CICLO                         ; decrementa CX y repite si CX<>0

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: ES_PAR ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PAR
;   Entrada : AX = numero (sin signo, 0..65535)
;   Salida  : BL = 1 si es par, BL = 0 si es impar  (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero es par si su bit 0 vale 0. TEST AX,1 hace un AND
;             sin guardar el resultado y solo actualiza ZF.
;------------------------------------------------------------------------------
ES_PAR PROC                                 ; inicio del procedimiento
    MOV BX, 0                               ; supone "no es par"
    TEST AX, 1                              ; aisla el bit 0 (ZF=1 si es 0)
    JNZ EPAR_FIN                            ; bit 0 = 1: es impar, termina
    MOV BL, 1                               ; bit 0 = 0: es par
EPAR_FIN:                                   ; salida comun
    RET                                     ; vuelve al llamador
ES_PAR ENDP                                 ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: ES_PAR ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
