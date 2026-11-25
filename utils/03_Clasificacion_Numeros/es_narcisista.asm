;==============================================================================
; ARCHIVO      : es_narcisista.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Determina si un numero entero de 16 bits sin signo es
;                narcisista (numero de Armstrong).
; FUNCIONAMIENTO: Un numero de k cifras es narcisista si es igual a la suma de
;                cada una de sus cifras elevada a k (ej. 153 = 1^3+5^3+3^3).
;                Paso 1: cuenta las cifras k dividiendo sucesivamente por 10.
;                Paso 2: vuelve a extraer cada cifra y calcula cifra^k mediante
;                multiplicaciones sucesivas con MUL BX, acumulando en DI.
;                Si alguna potencia supera 16 bits (DX <> 0) o la suma genera
;                acarreo (CF=1), equilibra la pila y devuelve BL=0.
;                Paso 3: compara la suma DI con el numero original SI.
;                En 16 bits los narcisistas son: 0..9, 153, 370, 371, 407,
;                1634, 8208, 9474 y 54748.
; REGISTROS    : Entrada  : AX = numero sin signo (0..65535)
;                Salida   : BL = 1 si es narcisista, BL = 0 si no (BH = 0)
;                Modifica : BX y banderas. Conserva AX, CX, DX, SI, DI.
; VARIABLES    : El procedimiento ES_NARCISISTA no requiere variables en DATOS.
; DEPENDENCIAS : Ninguna para el procedimiento ES_NARCISISTA.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable ES_NARCISISTA dentro de
;                   CODIGO despues de la salida a DOS (MOV AX, 4C00h / INT 21h).
;                2) Cargar el numero en AX y ejecutar CALL ES_NARCISISTA.
;                3) Consultar BL (1 = narcisista, 0 = no narcisista).
; EJEMPLO      : Prueba 0, 1, 2, 9, 10, 153, 370, 371, 407, 1000, 1634, 8208,
;                9474, 54748, 65535:
;                  0 -> ES NARCISISTA
;                  ...
;                  153 -> ES NARCISISTA
;                  54748 -> ES NARCISISTA
;                  65535 -> NO ES NARCISISTA
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
    MSG_TITULO DB '=== DEMO: ES_NARCISISTA (0..65535) ===$' ; titulo de demo
    MSG_SI     DB ' -> ES NARCISISTA$'      ; texto cuando BL = 1
    MSG_NO     DB ' -> NO ES NARCISISTA$'   ; texto cuando BL = 0
    PRUEBAS    DW 0, 1, 2, 9, 10, 153, 370, 371, 407, 1000, 1634, 8208, 9474, 54748, 65535 ; pruebas
    CANTIDAD   DW 15                        ; cantidad de valores en PRUEBAS
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
    CALL ES_NARCISISTA                      ; BL = 1 si AX es narcisista
    CMP BL, 1                               ; se cumplio la condicion?
    JNE DEMO_NO                             ; no: muestra mensaje negativo
    IMPRIMIR_CADENA MSG_SI                  ; si: muestra " -> ES NARCISISTA"
    JMP DEMO_SIG                            ; salta a la siguiente iteracion
DEMO_NO:                                    ; rama cuando BL = 0
    IMPRIMIR_CADENA MSG_NO                  ; muestra " -> NO ES NARCISISTA"
DEMO_SIG:                                   ; fin de la iteracion actual
    SALTO_LINEA                             ; nueva linea para el proximo caso
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP DEMO_CICLO                         ; decrementa CX y repite si CX<>0

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: ES_NARCISISTA ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_NARCISISTA
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es narcisista, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero de k cifras es narcisista si es igual a la suma de
;             cada cifra elevada a k. Ej: 153 = 1^3 + 5^3 + 3^3.
;             1) Cuenta las cifras (k) dividiendo por 10.
;             2) Vuelve a separar las cifras y suma cifra^k (potencia por
;                multiplicaciones sucesivas).
;             3) Compara la suma con el numero original.
;             Si una potencia o la suma pasan de 16 bits, no es narcisista.
;             En 16 bits los narcisistas son: 0..9, 153, 370, 371, 407,
;             1634, 8208, 9474 y 54748.
;------------------------------------------------------------------------------
ES_NARCISISTA PROC                          ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (k = cantidad cifras)
    PUSH DX                                 ; guarda DX (cifra / parte alta)
    PUSH SI                                 ; guarda SI (copia de n)
    PUSH DI                                 ; guarda DI (suma de potencias)
    MOV SI, AX                              ; SI = n original
    MOV BX, 10                              ; BX = divisor 10
    XOR CX, CX                              ; k = 0
ENAR_CONTAR:                                ; 1) cuenta las cifras
    XOR DX, DX                              ; DX:AX = numero restante
    DIV BX                                  ; AX = numero / 10
    INC CX                                  ; una cifra mas
    CMP AX, 0                               ; quedan cifras?
    JNE ENAR_CONTAR                         ; si: sigue contando
    XOR DI, DI                              ; suma = 0
    MOV AX, SI                              ; AX = n de nuevo
ENAR_CIFRA:                                 ; 2) procesa cada cifra
    XOR DX, DX                              ; prepara DX:AX
    MOV BX, 10                              ; divisor 10
    DIV BX                                  ; AX = resto del numero, DX=cifra
    PUSH AX                                 ; guarda lo que falta procesar
    PUSH CX                                 ; guarda k (LOOP lo consumira)
    MOV BX, DX                              ; BX = cifra (base)
    MOV AX, 1                               ; potencia = 1
ENAR_POTENCIA:                              ; potencia = cifra^k
    MUL BX                                  ; DX:AX = potencia * cifra
    CMP DX, 0                               ; paso de 16 bits?
    JNE ENAR_DESB_POT                       ; si: no puede ser narcisista
    LOOP ENAR_POTENCIA                      ; repite k veces
    POP CX                                  ; recupera k
    ADD DI, AX                              ; suma += cifra^k
    JC ENAR_DESB_SUMA                       ; la suma desbordo 16 bits
    POP AX                                  ; recupera el numero restante
    CMP AX, 0                               ; quedan cifras?
    JNE ENAR_CIFRA                          ; si: procesa la siguiente
    MOV BX, 0                               ; supone "no es narcisista"
    CMP DI, SI                              ; 3) suma == n ?
    JNE ENAR_FIN                            ; no: termina con BL = 0
    MOV BL, 1                               ; si: es narcisista
    JMP ENAR_FIN                            ; salta a restaurar registros
ENAR_DESB_POT:                              ; desborde dentro de la potencia
    POP CX                                  ; equilibra la pila (k)
ENAR_DESB_SUMA:                             ; desborde en la suma
    POP AX                                  ; equilibra la pila (restante)
    MOV BX, 0                               ; no es narcisista
ENAR_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_NARCISISTA ENDP                          ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: ES_NARCISISTA ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
