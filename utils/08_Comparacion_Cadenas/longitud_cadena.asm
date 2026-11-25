;==============================================================================
; ARCHIVO      : longitud_cadena.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Calcula la longitud de una cadena terminada en '$' usando SI,
;                y explica el formato del buffer de lectura INT 21h AH=0Ah.
; FUNCIONAMIENTO:
;   1) Cadenas terminadas en '$' (formato usado por DOS AH=09h):
;      Se recorre la cadena desde DS:SI leyendo cada byte con MOV AL, [SI]
;      hasta encontrar '$'. Se cuenta cada caracter distinto de '$'.
;   2) Formato del buffer de teclado de DOS (INT 21h, AH=0Ah):
;        Byte 0 (BUFFER+0): capacidad maxima (incluye el Enter 0Dh).
;        Byte 1 (BUFFER+1): cantidad REAL de caracteres leidos (sin 0Dh).
;        Bytes 2..        : los caracteres tecleados, seguidos de 0Dh.
;      Por eso, cuando una cadena viene de AH=0Ah, su longitud ya esta
;      almacenada en BUFFER+1 sin necesidad de recorrerla.
; REGISTROS    :
;   LONGITUD_CADENA -> Entrada: SI = offset de la cadena terminada en '$'.
;                      Salida : AX = longitud en caracteres (sin contar '$').
;                      Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
; VARIABLES    : Cadenas en DATOS y un buffer de ejemplo para AH=0Ah.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, SALTO_LINEA,
;                FIN_PROGRAMA de
;                utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm.
; COMO INTEGRAR: Copiar las macros arriba de PILA y LONGITUD_CADENA dentro de
;                CODIGO despues de FIN_PROGRAMA. Cargar SI con OFFSET cadena
;                y ejecutar CALL LONGITUD_CADENA (resultado en AX).
; EJEMPLO      :
;   === DEMO LONGITUD DE CADENA ===
;   Cadena 1: "Arquitectura 8086" -> longitud = 17
;   Cadena 2: "" (vacia) -> longitud = 0
;   Ingrese un texto: Hola mundo
;   Longitud desde BUFFER+1 (AH=0Ah): 10
;   Longitud con LONGITUD_CADENA    : 10
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

FIN_PROGRAMA MACRO                          ; macro sin parametros
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; DOS finaliza el programa
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    CAD1       DB 'Arquitectura 8086$'      ; cadena de prueba (17 chars)
    CAD_VACIA  DB '$'                       ; cadena vacia (0 chars)
    ; Buffer de DOS AH=0Ah: [max=41][leidos=0][41 bytes para texto + 0Dh]
    BUF_MAX    DB 41                        ; byte 0: maximo 40 chars + 0Dh
    BUF_LEN    DB 0                         ; byte 1: DOS escribe aqui la long
    BUF_TEXTO  DB 42 DUP('$')               ; bytes 2..: texto + '$' final
    MSG_TIT    DB '=== DEMO LONGITUD DE CADENA ===$'      ; titulo
    MSG_C1     DB 'Cadena 1: "$'                          ; prefijo 1
    MSG_C2     DB 'Cadena 2: "$'                          ; prefijo 2
    MSG_LEN    DB '" -> longitud = $'                     ; sufijo longitud
    MSG_PEDIR  DB 'Ingrese un texto: $'                   ; pedido teclado
    MSG_BUF    DB 'Longitud desde BUFFER+1 (AH=0Ah): $'   ; resultado buffer
    MSG_PROC   DB 'Longitud con LONGITUD_CADENA    : $'   ; resultado proc
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    ; --- Prueba 1: cadena normal en memoria ---
    IMPRIMIR_CADENA MSG_C1                  ; imprime prefijo
    IMPRIMIR_CADENA CAD1                    ; imprime la cadena
    IMPRIMIR_CADENA MSG_LEN                 ; imprime " -> longitud = "
    MOV SI, OFFSET CAD1                     ; SI apunta a CAD1
    CALL LONGITUD_CADENA                    ; AX = longitud de CAD1
    IMPRIMIR_NUMERO AX                      ; muestra 17
    SALTO_LINEA                             ; nueva linea

    ; --- Prueba 2: cadena vacia ---
    IMPRIMIR_CADENA MSG_C2                  ; imprime prefijo
    IMPRIMIR_CADENA CAD_VACIA               ; imprime nada
    IMPRIMIR_CADENA MSG_LEN                 ; imprime " -> longitud = "
    MOV SI, OFFSET CAD_VACIA                ; SI apunta a cadena vacia
    CALL LONGITUD_CADENA                    ; AX = 0
    IMPRIMIR_NUMERO AX                      ; muestra 0
    SALTO_LINEA                             ; nueva linea

    ; --- Prueba 3: lectura con INT 21h AH=0Ah ---
    IMPRIMIR_CADENA MSG_PEDIR               ; solicita texto
    LEA DX, BUF_MAX                         ; DX apunta al byte 0 del buffer
    MOV AH, 0Ah                             ; servicio 0Ah: lectura con buffer
    INT 21h                                 ; DOS lee hasta Enter (0Dh)
    SALTO_LINEA                             ; baja de linea

    ; Colocar '$' justo despues del ultimo caracter leido (reemplaza 0Dh)
    MOV BL, BUF_LEN                         ; BL = cantidad leida por DOS
    MOV BH, 0                               ; BX = longitud en 16 bits
    MOV BUF_TEXTO[BX], '$'                  ; marca el fin con '$'

    IMPRIMIR_CADENA MSG_BUF                 ; muestra longitud desde BUFFER+1
    MOV AL, BUF_LEN                         ; AL = byte 1 del buffer
    MOV AH, 0                               ; AX = longitud sin signo
    IMPRIMIR_NUMERO AX                      ; imprime longitud
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PROC                ; verifica con LONGITUD_CADENA
    MOV SI, OFFSET BUF_TEXTO                ; SI apunta a los caracteres leidos
    CALL LONGITUD_CADENA                    ; AX = longitud contada hasta '$'
    IMPRIMIR_NUMERO AX                      ; debe coincidir con BUF_LEN
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LONGITUD_CADENA ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LONGITUD_CADENA
;   Entrada : SI = offset de cadena terminada en '$' (en segmento DS).
;   Salida  : AX = cantidad de caracteres antes de '$'.
;   Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
LONGITUD_CADENA PROC                        ; inicio del procedimiento
    PUSH SI                                 ; guarda SI original
    XOR AX, AX                              ; contador de caracteres = 0
LC_CICLO:                                   ; recorre byte a byte
    CMP BYTE PTR [SI], '$'                  ; llego al terminador '$'?
    JE LC_FIN                               ; si: termina el conteo
    INC AX                                  ; suma 1 caracter
    INC SI                                  ; avanza al siguiente byte
    JMP LC_CICLO                            ; repite
LC_FIN:                                     ; salida comun
    POP SI                                  ; restaura SI original
    RET                                     ; vuelve con AX = longitud
LONGITUD_CADENA ENDP                        ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LONGITUD_CADENA ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
