;==============================================================================
; ARCHIVO      : raiz_cuadrada_entera.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Calcula la raiz cuadrada entera (parte entera, floor(sqrt(n)))
;                de un numero sin signo de 16 bits (0..65535) e indica si la
;                raiz es exacta o no.
; FUNCIONAMIENTO: Prueba candidatos r = 0, 1, 2... calculando r*r con MUL CX
;                (que deja el producto de 32 bits en DX:AX).
;                * Si DX <> 0, r*r supero 65535 (por ej. 256*256 = 65536), por
;                  lo que r ya se paso de cualquier n de 16 bits: la raiz
;                  entera es r - 1 y no es exacta (BL = 0).
;                * Si AX == n, se encontro la raiz exacta: devuelve r y BL = 1.
;                * Si AX > n, r ya se paso: devuelve r - 1 y BL = 0.
;                RELACION CON TIENE_RAIZ_EXACTA (03_Clasificacion_Numeros):
;                TIENE_RAIZ_EXACTA conserva AX y solo informa en BL si n es un
;                cuadrado perfecto (interfaz estandar de clasificadores).
;                RAIZ_CUADRADA_ENTERA usa el mismo principio pero devuelve en
;                AX el valor entero de la raiz (0..255) y en BL si fue exacta.
; REGISTROS    : Entrada  : AX = numero sin signo n (0..65535)
;                Salida   : AX = parte entera de sqrt(n) (0..255)
;                           BL = 1 si es exacta, BL = 0 si no lo es (BH = 0)
;                Modifica : AX, BX y banderas. Conserva CX, DX, SI.
; VARIABLES    : El procedimiento RAIZ_CUADRADA_ENTERA no requiere variables.
; DEPENDENCIAS : Ninguna para el procedimiento RAIZ_CUADRADA_ENTERA.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Copiar el bloque reutilizable RAIZ_CUADRADA_ENTERA dentro
;                   de CODIGO despues de la salida a DOS.
;                2) Cargar n en AX y ejecutar CALL RAIZ_CUADRADA_ENTERA.
;                3) Leer la raiz entera en AX y la exactitud en BL.
; EJEMPLO      : Prueba 0, 1, 2, 4, 8, 9, 15, 16, 100, 1000, 65025, 65535:
;                  sqrt(0) = 0 (exacta)
;                  sqrt(1) = 1 (exacta)
;                  sqrt(2) = 1 (aprox)
;                  ...
;                  sqrt(65025) = 255 (exacta)
;                  sqrt(65535) = 255 (aprox)
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
    MSG_TITULO DB '=== DEMO: RAIZ CUADRADA ENTERA ===$' ; titulo de la demo
    MSG_SQRT   DB 'sqrt($'                  ; prefijo
    MSG_IGUAL  DB ') = $'                   ; separador
    MSG_EXACTA DB ' (exacta)$'              ; texto cuando BL = 1
    MSG_APROX  DB ' (aprox)$'               ; texto cuando BL = 0
    PRUEBAS    DW 0, 1, 2, 4, 8, 9, 15, 16, 100, 1000, 65025, 65535 ; casos
    CANTIDAD   DW 12                        ; cantidad de casos de prueba
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET PRUEBAS                  ; SI apunta al primer valor
    MOV CX, CANTIDAD                        ; CX = cantidad de pruebas
DEMO_CICLO:                                 ; recorre cada numero de prueba
    MOV AX, [SI]                            ; AX = numero n
    IMPRIMIR_CADENA MSG_SQRT                ; muestra "sqrt("
    IMPRIMIR_NUMERO AX                      ; muestra n
    IMPRIMIR_CADENA MSG_IGUAL               ; muestra ") = "

    CALL RAIZ_CUADRADA_ENTERA               ; AX = raiz entera, BL = exacta?
    IMPRIMIR_NUMERO AX                      ; muestra la parte entera de la raiz
    CMP BL, 1                               ; fue raiz exacta?
    JNE DEMO_APROX                          ; no: muestra "(aprox)"
    IMPRIMIR_CADENA MSG_EXACTA              ; si: muestra "(exacta)"
    JMP DEMO_SIG                            ; salta al cierre de iteracion
DEMO_APROX:                                 ; rama no exacta
    IMPRIMIR_CADENA MSG_APROX               ; muestra "(aprox)"
DEMO_SIG:                                   ; fin de la iteracion
    SALTO_LINEA                             ; nueva linea
    ADD SI, 2                               ; siguiente palabra DW
    DEC CX                                  ; decrementa contador (evita LOOP
    JZ DEMO_FIN                             ; fuera de rango de +-127 bytes
    JMP DEMO_CICLO                          ; por las macros expandidas)
DEMO_FIN:                                   ; fin de la demostracion

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: RAIZ_CUADRADA_ENTERA ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO RAIZ_CUADRADA_ENTERA
;   Entrada : AX = numero sin signo n (0..65535)
;   Salida  : AX = parte entera de la raiz cuadrada (0..255)
;             BL = 1 si es exacta (AX*AX == n), BL = 0 si no (BH = 0)
;   Modifica: AX, BX y banderas. Conserva CX, DX, SI.
;------------------------------------------------------------------------------
RAIZ_CUADRADA_ENTERA PROC                   ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (candidato r)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (copia de n)
    MOV SI, AX                              ; SI = n original
    MOV BX, 0                               ; supone raiz no exacta (BH=0,BL=0)
    XOR CX, CX                              ; r = 0 (primer candidato)
RCE_CICLO:                                  ; prueba r = 0, 1, 2...
    MOV AX, CX                              ; AX = r
    MUL CX                                  ; DX:AX = r * r
    CMP DX, 0                               ; r*r supero 65535 (16 bits)?
    JNE RCE_PASO                            ; si: r ya es demasiado grande
    CMP AX, SI                              ; compara r*r con n
    JE RCE_EXACTA                           ; r*r == n: raiz exacta
    JA RCE_PASO                             ; r*r > n: la parte entera es r-1
    INC CX                                  ; prueba el siguiente entero
    JMP RCE_CICLO                           ; continua la busqueda
RCE_EXACTA:                                 ; se encontro r con r*r == n
    MOV AX, CX                              ; AX = r
    MOV BL, 1                               ; indica raiz exacta
    JMP RCE_FIN                             ; salta a restaurar registros
RCE_PASO:                                   ; r*r > n, retrocede uno
    DEC CX                                  ; r - 1 es el mayor con (r-1)^2 <= n
    MOV AX, CX                              ; AX = parte entera de la raiz
RCE_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
RAIZ_CUADRADA_ENTERA ENDP                   ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: RAIZ_CUADRADA_ENTERA ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
