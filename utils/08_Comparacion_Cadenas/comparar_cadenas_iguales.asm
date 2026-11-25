;==============================================================================
; ARCHIVO      : comparar_cadenas_iguales.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Determina si dos cadenas terminadas en '$' son iguales o
;                diferentes, verificando primero sus longitudes y comparando
;                luego caracter por caracter. Muestra tanto el metodo manual
;                (SI/DI sobre DS) como el metodo con REPE CMPSB (DS:SI vs ES:DI).
; FUNCIONAMIENTO:
;   Metodo 1 (COMPARAR_CADENAS - manual con DS:SI y DS:DI):
;     1) Calcula longitud de cadena 1 (SI) y cadena 2 (DI) con LONGITUD_CADENA.
;     2) Si las longitudes son distintas, devuelve AL = 0 de inmediato.
;     3) Si coinciden, recorre CX caracteres cargando MOV AL, [SI] y haciendo
;        CMP AL, [DI]. Si algun par difiere, devuelve AL = 0; si todos coinciden,
;        devuelve AL = 1.
;   Metodo 2 (COMPARAR_CADENAS_CMPSB - instruccion de cadena 8086):
;     CMPSB compara el byte en DS:[SI] con el byte en ES:[DI] y avanza ambos
;     punteros si DF = 0 (CLD). Como el 8086 usa ES para DI en instrucciones
;     de cadena, se debe inicializar ES = DS (DATOS). Con el prefijo REPE,
;     REPE CMPSB repite mientras CX > 0 y los bytes sean iguales (ZF = 1).
; REGISTROS    :
;   COMPARAR_CADENAS       -> Entrada: SI = cad1 ('$'), DI = cad2 ('$').
;                             Salida : AL = 1 si iguales, AL = 0 si diferentes.
;                             Conserva BX, CX, DX, SI, DI.
;   COMPARAR_CADENAS_CMPSB -> Misma interfaz (requiere ES = DS o lo ajusta).
; VARIABLES    : Cadenas de prueba en DATOS.
; DEPENDENCIAS : Macros de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y LONGITUD_CADENA.
; COMO INTEGRAR: Copiar las macros, LONGITUD_CADENA y COMPARAR_CADENAS (o
;                COMPARAR_CADENAS_CMPSB) en CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      :
;   === DEMO COMPARACION DE CADENAS ===
;   "ASM8086" vs "ASM8086" -> IGUALES (manual) | IGUALES (CMPSB)
;   "ASM8086" vs "ASM8088" -> DIFERENTES (manual) | DIFERENTES (CMPSB)
;   "Hola" vs "Hola mundo" -> DIFERENTES (manual) | DIFERENTES (CMPSB)
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
    CAD_A    DB 'ASM8086$'                  ; cadena A
    CAD_B    DB 'ASM8086$'                  ; igual a A
    CAD_C    DB 'ASM8088$'                  ; misma longitud, difiere al final
    CAD_D    DB 'Hola$'                     ; mas corta
    CAD_E    DB 'Hola mundo$'               ; mas larga (contiene a CAD_D)
    MSG_TIT  DB '=== DEMO COMPARACION DE CADENAS ===$' ; titulo
    MSG_VS   DB ' vs $'                     ; separador
    MSG_SEP  DB ' -> $'                     ; flecha
    MSG_BAR  DB ' | $'                      ; separador de metodos
    MSG_IG1  DB 'IGUALES (manual)$'         ; resultado igual manual
    MSG_DI1  DB 'DIFERENTES (manual)$'      ; resultado distinto manual
    MSG_IG2  DB 'IGUALES (CMPSB)$'          ; resultado igual CMPSB
    MSG_DI2  DB 'DIFERENTES (CMPSB)$'       ; resultado distinto CMPSB
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS
    MOV ES, AX                              ; ES = DATOS (requerido por CMPSB)

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    ; --- Caso 1: iguales ---
    MOV SI, OFFSET CAD_A                    ; SI = "ASM8086"
    MOV DI, OFFSET CAD_B                    ; DI = "ASM8086"
    CALL DEMO_PROBAR_PAR                    ; muestra resultado con ambos metodos

    ; --- Caso 2: misma longitud, diferentes ---
    MOV SI, OFFSET CAD_A                    ; SI = "ASM8086"
    MOV DI, OFFSET CAD_C                    ; DI = "ASM8088"
    CALL DEMO_PROBAR_PAR                    ; muestra resultado con ambos metodos

    ; --- Caso 3: distinta longitud (prefijo) ---
    MOV SI, OFFSET CAD_D                    ; SI = "Hola"
    MOV DI, OFFSET CAD_E                    ; DI = "Hola mundo"
    CALL DEMO_PROBAR_PAR                    ; muestra resultado con ambos metodos

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO AUXILIAR DE DEMO: imprime SI vs DI y prueba ambos comparadores
;------------------------------------------------------------------------------
DEMO_PROBAR_PAR PROC                        ; inicio de rutina auxiliar
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV DX, SI                              ; DX = cadena 1
    MOV AH, 09h                             ; muestra cadena 1
    INT 21h                                 ; DOS imprime
    IMPRIMIR_CADENA MSG_VS                  ; " vs "
    MOV DX, DI                              ; DX = cadena 2
    MOV AH, 09h                             ; muestra cadena 2
    INT 21h                                 ; DOS imprime
    IMPRIMIR_CADENA MSG_SEP                 ; " -> "

    CALL COMPARAR_CADENAS                   ; metodo manual (MOV/CMP)
    CMP AL, 1                               ; son iguales?
    JNE DPP_DIF1                            ; no
    IMPRIMIR_CADENA MSG_IG1                 ; si: imprime iguales
    JMP DPP_M2                              ; pasa al segundo metodo
DPP_DIF1:                                   ; rama diferentes (manual)
    IMPRIMIR_CADENA MSG_DI1                 ; imprime diferentes
DPP_M2:                                     ; prueba con REPE CMPSB
    IMPRIMIR_CADENA MSG_BAR                 ; " | "
    CALL COMPARAR_CADENAS_CMPSB             ; metodo con REPE CMPSB
    CMP AL, 1                               ; son iguales?
    JNE DPP_DIF2                            ; no
    IMPRIMIR_CADENA MSG_IG2                 ; si
    JMP DPP_FIN                             ; termina
DPP_DIF2:                                   ; rama diferentes (CMPSB)
    IMPRIMIR_CADENA MSG_DI2                 ; imprime diferentes
DPP_FIN:                                    ; fin de la linea
    SALTO_LINEA                             ; nueva linea
    POP DX                                  ; restaura DX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
DEMO_PROBAR_PAR ENDP                        ; fin de rutina auxiliar

;====== INICIO BLOQUE REUTILIZABLE: COMPARAR_CADENAS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LONGITUD_CADENA
;   Entrada : SI = offset de cadena terminada en '$'.
;   Salida  : AX = longitud (sin contar '$'). Conserva SI y demas registros.
;------------------------------------------------------------------------------
LONGITUD_CADENA PROC                        ; inicio del procedimiento
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; contador = 0
LC_CICLO:                                   ; ciclo de conteo
    CMP BYTE PTR [SI], '$'                  ; es el terminador '$'?
    JE LC_FIN                               ; si: termina
    INC AX                                  ; suma 1
    INC SI                                  ; siguiente caracter
    JMP LC_CICLO                            ; repite
LC_FIN:                                     ; salida
    POP SI                                  ; restaura SI
    RET                                     ; vuelve con AX = longitud
LONGITUD_CADENA ENDP                        ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_CADENAS (comparacion manual con DS:SI y DS:DI)
;   Entrada : SI = offset cadena 1 ('$'), DI = offset cadena 2 ('$').
;   Salida  : AL = 1 si son iguales, AL = 0 si son diferentes (AH = 0).
;   Modifica: AX y banderas. Conserva BX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
COMPARAR_CADENAS PROC                       ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI

    ; 1) Comparar longitudes primero
    CALL LONGITUD_CADENA                    ; AX = longitud de cadena 1
    MOV BX, AX                              ; BX = longitud 1
    PUSH SI                                 ; guarda SI
    MOV SI, DI                              ; SI = cadena 2 para medirla
    CALL LONGITUD_CADENA                    ; AX = longitud de cadena 2
    POP SI                                  ; recupera SI = cadena 1
    CMP BX, AX                              ; tienen la misma longitud?
    JNE CC_DIF                              ; no: ya son diferentes

    ; 2) Si ambas estan vacias (longitud 0), son iguales
    MOV CX, BX                              ; CX = cantidad de bytes a comparar
    CMP CX, 0                               ; longitud 0?
    JE CC_IGUAL                             ; si: dos cadenas vacias son iguales

    ; 3) Comparar caracter por caracter manualmente
CC_CICLO:                                   ; recorre CX caracteres
    MOV AL, [SI]                            ; AL = caracter actual de cadena 1
    CMP AL, [DI]                            ; compara con caracter de cadena 2
    JNE CC_DIF                              ; difieren: no son iguales
    INC SI                                  ; avanza puntero cadena 1
    INC DI                                  ; avanza puntero cadena 2
    LOOP CC_CICLO                           ; decrementa CX y repite si CX<>0
CC_IGUAL:                                   ; todos los bytes coincidieron
    MOV AX, 1                               ; AL = 1 (iguales)
    JMP CC_FIN                              ; salta al final
CC_DIF:                                     ; longitudes o algun byte distinto
    MOV AX, 0                               ; AL = 0 (diferentes)
CC_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
COMPARAR_CADENAS ENDP                       ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_CADENAS_CMPSB (usando CLD y REPE CMPSB con ES = DS)
;   Entrada : SI = offset cadena 1 ('$'), DI = offset cadena 2 ('$').
;   Salida  : AL = 1 si son iguales, AL = 0 si son diferentes (AH = 0).
;   Nota    : CMPSB compara DS:[SI] con ES:[DI]. Este procedimiento copia DS
;             en ES (guardando ES) para funcionar aunque ES no este cargado.
;------------------------------------------------------------------------------
COMPARAR_CADENAS_CMPSB PROC                 ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI
    PUSH ES                                 ; guarda ES

    MOV AX, DS                              ; AX = segmento de datos actual
    MOV ES, AX                              ; ES = DS para que ES:[DI] sea valido

    CALL LONGITUD_CADENA                    ; AX = longitud cadena 1
    MOV BX, AX                              ; BX = longitud 1
    PUSH SI                                 ; guarda SI
    MOV SI, DI                              ; mide cadena 2
    CALL LONGITUD_CADENA                    ; AX = longitud cadena 2
    POP SI                                  ; recupera SI
    CMP BX, AX                              ; longitudes iguales?
    JNE CCC_DIF                             ; no: diferentes

    MOV CX, BX                              ; CX = cantidad de bytes
    CMP CX, 0                               ; ambas vacias?
    JE CCC_IGUAL                            ; si: iguales

    CLD                                     ; DF = 0: SI y DI avanzan (+1)
    REPE CMPSB                              ; compara DS:[SI] con ES:[DI]
    JNE CCC_DIF                             ; si ZF=0, hubo un byte distinto
CCC_IGUAL:                                  ; todos coincidieron
    MOV AX, 1                               ; AL = 1 (iguales)
    JMP CCC_FIN                             ; sale
CCC_DIF:                                    ; difieren
    MOV AX, 0                               ; AL = 0 (diferentes)
CCC_FIN:                                    ; salida comun
    POP ES                                  ; restaura ES
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
COMPARAR_CADENAS_CMPSB ENDP                 ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: COMPARAR_CADENAS ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
