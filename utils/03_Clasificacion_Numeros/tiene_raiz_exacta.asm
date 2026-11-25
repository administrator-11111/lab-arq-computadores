;==============================================================================
; ARCHIVO      : tiene_raiz_exacta.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Determina si un numero entero de 16 bits sin signo es un
;                cuadrado perfecto (tiene raiz cuadrada entera exacta).
; FUNCIONAMIENTO: Prueba candidatos r = 0, 1, 2... calculando r*r con MUL CX.
;                Si DX <> 0 el cuadrado paso de 16 bits (> 65535) y se detiene
;                porque ningun r mayor podra igualar a n. Si AX == n existe
;                raiz exacta (BL=1); si AX > n no existe (BL=0).
;                El mayor cuadrado perfecto de 16 bits es 255*255 = 65025.
;                Ver tambien utils/06_Algoritmos_Matematicos/raiz_cuadrada_entera.asm
;                si ademas se necesita el valor de la raiz entera.
; REGISTROS    : Entrada  : AX = numero sin signo (0..65535)
;                Salida   : BL = 1 si tiene raiz exacta, BL = 0 si no (BH = 0)
;                Modifica : BX y banderas. Conserva AX, CX, DX, SI.
; VARIABLES    : El procedimiento TIENE_RAIZ_EXACTA no requiere variables.
; DEPENDENCIAS : Ninguna para el procedimiento TIENE_RAIZ_EXACTA.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable TIENE_RAIZ_EXACTA dentro de
;                   CODIGO despues de la salida a DOS (MOV AX, 4C00h / INT 21h).
;                2) Cargar el numero en AX y ejecutar CALL TIENE_RAIZ_EXACTA.
;                3) Consultar BL (1 = tiene raiz exacta, 0 = no tiene).
; EJEMPLO      : Prueba 0, 1, 2, 4, 9, 15, 16, 100, 1000, 65025, 65535:
;                  0 -> TIENE RAIZ EXACTA
;                  1 -> TIENE RAIZ EXACTA
;                  2 -> NO TIENE RAIZ EXACTA
;                  4 -> TIENE RAIZ EXACTA
;                  9 -> TIENE RAIZ EXACTA
;                  15 -> NO TIENE RAIZ EXACTA
;                  16 -> TIENE RAIZ EXACTA
;                  100 -> TIENE RAIZ EXACTA
;                  1000 -> NO TIENE RAIZ EXACTA
;                  65025 -> TIENE RAIZ EXACTA
;                  65535 -> NO TIENE RAIZ EXACTA
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
    MSG_TITULO DB '=== DEMO: TIENE_RAIZ_EXACTA (0..65535) ===$' ; titulo
    MSG_SI     DB ' -> TIENE RAIZ EXACTA$'  ; texto cuando BL = 1
    MSG_NO     DB ' -> NO TIENE RAIZ EXACTA$' ; texto cuando BL = 0
    PRUEBAS    DW 0, 1, 2, 4, 9, 15, 16, 100, 1000, 65025, 65535 ; pruebas
    CANTIDAD   DW 11                        ; cantidad de valores en PRUEBAS
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
    CALL TIENE_RAIZ_EXACTA                  ; BL = 1 si AX es cuadrado perfecto
    CMP BL, 1                               ; se cumplio la condicion?
    JNE DEMO_NO                             ; no: muestra mensaje negativo
    IMPRIMIR_CADENA MSG_SI                  ; si: muestra " -> TIENE RAIZ..."
    JMP DEMO_SIG                            ; salta a la siguiente iteracion
DEMO_NO:                                    ; rama cuando BL = 0
    IMPRIMIR_CADENA MSG_NO                  ; muestra " -> NO TIENE RAIZ..."
DEMO_SIG:                                   ; fin de la iteracion actual
    SALTO_LINEA                             ; nueva linea para el proximo caso
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP DEMO_CICLO                         ; decrementa CX y repite si CX<>0

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: TIENE_RAIZ_EXACTA ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO TIENE_RAIZ_EXACTA
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si existe r entero con r*r = n, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI.
;   Metodo  : prueba r = 0, 1, 2... calculando r*r. Si r*r = n hay raiz
;             exacta; si r*r > n (o pasa de 16 bits) ya no puede haberla.
;             Nota: 0 y 1 cuentan como cuadrados perfectos (0*0, 1*1).
;------------------------------------------------------------------------------
TIENE_RAIZ_EXACTA PROC                      ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (candidato r)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (copia de n)
    MOV BX, 0                               ; supone "no tiene raiz exacta"
    MOV SI, AX                              ; SI = n
    MOV CX, 0                               ; r = 0
ERAI_CICLO:                                 ; prueba cada candidato
    MOV AX, CX                              ; AX = r
    MUL CX                                  ; DX:AX = r * r
    CMP DX, 0                               ; r*r supero 65535?
    JNE ERAI_FIN                            ; si: es mayor que n, no hay raiz
    CMP AX, SI                              ; compara r*r con n
    JE ERAI_SI                              ; iguales: raiz exacta = r
    JA ERAI_FIN                             ; r*r > n: no hay raiz exacta
    INC CX                                  ; siguiente candidato
    JMP ERAI_CICLO                          ; repite
ERAI_SI:                                    ; se encontro r
    MOV BL, 1                               ; tiene raiz exacta
ERAI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
TIENE_RAIZ_EXACTA ENDP                      ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: TIENE_RAIZ_EXACTA ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
