;==============================================================================
; ARCHIVO      : comparar_palabras.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Compara dos palabras terminadas en '$' ignorando mayusculas y
;                minusculas, y determina su orden alfabetico (cual va primero).
; FUNCIONAMIENTO:
;   1) En ASCII, 'A'..'Z' ocupan 41h..5Ah y 'a'..'z' ocupan 61h..7Ah. La
;      diferencia es exactamente 20h (32). Por eso, para normalizar una letra
;      minuscula a mayuscula basta comprobar 'a' <= AL <= 'z' y hacer SUB AL, 20h.
;   2) COMPARAR_PALABRAS recorre ambas palabras simultaneamente (SI y DI):
;      - Si ambos caracteres son '$', las palabras son iguales (AL = 0).
;      - Si cad1 llego a '$' antes que cad2, cad1 es prefijo y va ANTES (AL = 1).
;      - Si cad2 llego a '$' antes que cad1, cad2 va ANTES (AL = 2).
;      - Si ninguno es '$', normaliza ambos a mayuscula y los compara:
;        si c1 < c2 -> cad1 va antes (AL = 1);
;        si c1 > c2 -> cad2 va antes (AL = 2);
;        si c1 == c2 -> avanza SI y DI al siguiente caracter.
; REGISTROS    :
;   A_MAYUSCULA       -> Entrada: AL = caracter. Salida: AL en mayuscula si era
;                        'a'..'z', sin cambios en otro caso.
;   COMPARAR_PALABRAS -> Entrada: SI = palabra 1 ('$'), DI = palabra 2 ('$').
;                        Salida : AL = 0 si iguales (sin distinguir mayusculas),
;                                 AL = 1 si palabra 1 va primero (cad1 < cad2),
;                                 AL = 2 si palabra 2 va primero (cad1 > cad2).
;                        Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
; VARIABLES    : Palabras de ejemplo en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, SALTO_LINEA, FIN_PROGRAMA de
;                utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm.
; COMO INTEGRAR: Copiar las macros y el bloque reutilizable en CODIGO despues
;                de FIN_PROGRAMA. Cargar SI y DI con las palabras y llamar.
; EJEMPLO      :
;   === DEMO COMPARACION DE PALABRAS (ORDEN ALFABETICO) ===
;   Hola vs hola -> IGUALES (ignorando mayusculas)
;   Arbol vs barco -> Primero va: Arbol
;   zorro vs Abeja -> Primero va: Abeja
;   casa vs CasaGrande -> Primero va: casa
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
    P1A      DB 'Hola$'                     ; ejemplo 1A
    P1B      DB 'hola$'                     ; ejemplo 1B (iguales sin mayus.)
    P2A      DB 'Arbol$'                    ; ejemplo 2A
    P2B      DB 'barco$'                    ; ejemplo 2B (Arbol < barco)
    P3A      DB 'zorro$'                    ; ejemplo 3A
    P3B      DB 'Abeja$'                    ; ejemplo 3B (Abeja < zorro)
    P4A      DB 'casa$'                     ; ejemplo 4A (prefijo)
    P4B      DB 'CasaGrande$'               ; ejemplo 4B (casa < CasaGrande)
    MSG_TIT  DB '=== DEMO COMPARACION DE PALABRAS (ORDEN ALFABETICO) ===$' ; tit
    MSG_VS   DB ' vs $'                     ; separador
    MSG_IG   DB ' -> IGUALES (ignorando mayusculas)$' ; iguales
    MSG_PRI  DB ' -> Primero va: $'         ; orden alfabetico
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET P1A                      ; Hola vs hola
    MOV DI, OFFSET P1B                      ; puntero 2
    CALL DEMO_PAL                           ; prueba

    MOV SI, OFFSET P2A                      ; Arbol vs barco
    MOV DI, OFFSET P2B                      ; puntero 2
    CALL DEMO_PAL                           ; prueba

    MOV SI, OFFSET P3A                      ; zorro vs Abeja
    MOV DI, OFFSET P3B                      ; puntero 2
    CALL DEMO_PAL                           ; prueba

    MOV SI, OFFSET P4A                      ; casa vs CasaGrande
    MOV DI, OFFSET P4B                      ; puntero 2
    CALL DEMO_PAL                           ; prueba

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO AUXILIAR DE DEMO: imprime SI vs DI y cual va primero
;------------------------------------------------------------------------------
DEMO_PAL PROC                               ; inicio auxiliar
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV DX, SI                              ; imprime palabra 1
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; muestra
    IMPRIMIR_CADENA MSG_VS                  ; " vs "
    MOV DX, DI                              ; imprime palabra 2
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; muestra
    CALL COMPARAR_PALABRAS                  ; AL = 0 igual, 1 cad1<, 2 cad2<
    CMP AL, 0                               ; iguales?
    JE DP_IG                                ; si
    IMPRIMIR_CADENA MSG_PRI                 ; " -> Primero va: "
    CMP AL, 1                               ; palabra 1 va primero?
    JE DP_UNO                               ; si
    MOV DX, DI                              ; no: palabra 2 va primero
    JMP DP_IMP                              ; imprime la ganadora
DP_UNO:                                     ; palabra 1 va primero
    MOV DX, SI                              ; DX = palabra 1
DP_IMP:                                     ; imprime la palabra que va antes
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; muestra
    JMP DP_FIN                              ; sale
DP_IG:                                      ; rama iguales
    IMPRIMIR_CADENA MSG_IG                  ; imprime iguales
DP_FIN:                                     ; fin
    SALTO_LINEA                             ; nueva linea
    POP DX                                  ; restaura DX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
DEMO_PAL ENDP                               ; fin auxiliar

;====== INICIO BLOQUE REUTILIZABLE: COMPARAR_PALABRAS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO A_MAYUSCULA
;   Entrada : AL = codigo ASCII de un caracter.
;   Salida  : AL convertido a mayuscula si estaba en 'a'..'z'.
;   Modifica: solo AL y banderas.
;------------------------------------------------------------------------------
A_MAYUSCULA PROC                            ; inicio del procedimiento
    CMP AL, 'a'                             ; menor que 'a' (61h)?
    JB AM_FIN                               ; no es minuscula
    CMP AL, 'z'                             ; mayor que 'z' (7Ah)?
    JA AM_FIN                               ; no es minuscula
    SUB AL, 20h                             ; 'a'..'z' -> 'A'..'Z'
AM_FIN:                                     ; salida comun
    RET                                     ; vuelve al llamador
A_MAYUSCULA ENDP                            ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_PALABRAS
;   Entrada : SI = offset palabra 1 ('$'), DI = offset palabra 2 ('$').
;   Salida  : AL = 0 si iguales (sin distinguir mayusculas/minusculas),
;             AL = 1 si palabra 1 va primero alfabeticamente (cad1 < cad2),
;             AL = 2 si palabra 2 va primero alfabeticamente (cad1 > cad2).
;             (AH = 0). Conserva BX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
COMPARAR_PALABRAS PROC                      ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI
CPAL_CICLO:                                 ; recorre caracter por caracter
    MOV AL, [SI]                            ; AL = caracter de palabra 1
    MOV BL, [DI]                            ; BL = caracter de palabra 2
    CMP AL, '$'                             ; termino palabra 1?
    JE CPAL_FIN1                            ; si: revisar si termino palabra 2
    CMP BL, '$'                             ; termino palabra 2 (y 1 no)?
    JE CPAL_DOS_ANTES                       ; si: palabra 2 es mas corta -> antes

    CALL A_MAYUSCULA                        ; normaliza AL a mayuscula
    MOV BH, AL                              ; BH = caracter 1 en mayuscula
    MOV AL, BL                              ; AL = caracter 2
    CALL A_MAYUSCULA                        ; normaliza AL a mayuscula
    CMP BH, AL                              ; compara en mayusculas
    JB CPAL_UNO_ANTES                       ; c1 < c2 -> palabra 1 va primero
    JA CPAL_DOS_ANTES                       ; c1 > c2 -> palabra 2 va primero

    INC SI                                  ; avanzan ambos punteros
    INC DI                                  ; siguiente caracter
    JMP CPAL_CICLO                          ; continua comparando

CPAL_FIN1:                                  ; palabra 1 llego a '$'
    CMP BL, '$'                             ; palabra 2 tambien llego a '$'?
    JE CPAL_IGUAL                           ; si: ambas terminaron igual
    JMP CPAL_UNO_ANTES                      ; no: palabra 1 es prefijo -> antes

CPAL_IGUAL:                                 ; son iguales
    MOV AX, 0                               ; AL = 0
    JMP CPAL_FIN                            ; sale
CPAL_UNO_ANTES:                             ; palabra 1 va antes
    MOV AX, 1                               ; AL = 1
    JMP CPAL_FIN                            ; sale
CPAL_DOS_ANTES:                             ; palabra 2 va antes
    MOV AX, 2                               ; AL = 2
CPAL_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
COMPARAR_PALABRAS ENDP                      ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: COMPARAR_PALABRAS ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
