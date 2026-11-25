;==============================================================================
; ARCHIVO      : comparar_caracter_por_caracter.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Compara dos cadenas terminadas en '$' caracter por caracter
;                e informa si son iguales, cuantos caracteres coinciden desde
;                el inicio y cual es la primera posicion donde difieren.
; FUNCIONAMIENTO:
;   1) Recorre simultaneamente DS:[SI] y DS:[DI] llevando un contador CX = 0
;      de caracteres coincidentes.
;   2) En cada paso lee AL = [SI] y AH = [DI]:
;      - Si ambos son '$', ambas cadenas terminaron igual -> iguales (BL = 1).
;      - Si AL == AH (y no son '$'), incrementa CX, SI y DI, y continua.
;      - Si AL != AH (incluye el caso en que una termino en '$' antes que la
;        otra), se encontro la primera diferencia en la posicion CX (base 0)
;        o CX + 1 (base 1), y devuelve BL = 0.
; REGISTROS    :
;   COMPARAR_POSICION -> Entrada: SI = cadena 1 ('$'), DI = cadena 2 ('$').
;                        Salida : BL = 1 si iguales, BL = 0 si diferentes (BH=0)
;                                 AX = cantidad de caracteres coincidentes
;                                      (tambien es el indice base 0 de la
;                                      primera diferencia si BL = 0).
;                        Modifica: AX, BX y banderas. Conserva CX, DX, SI, DI.
; VARIABLES    : Cadenas de prueba en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, SALTO_LINEA,
;                FIN_PROGRAMA de
;                utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm.
; COMO INTEGRAR: Copiar las macros y COMPARAR_POSICION dentro de CODIGO
;                despues de FIN_PROGRAMA. Cargar SI y DI y hacer CALL.
; EJEMPLO      :
;   === DEMO COMPARACION CARACTER POR CARACTER ===
;   "computador" vs "computacion"
;     Resultado : DIFERENTES
;     Coinciden : 7 caracteres
;     1a dif.   : posicion 8 (indice 7)
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
    C1A      DB 'computador$'               ; ejemplo 1A
    C1B      DB 'computacion$'              ; ejemplo 1B (difiere en indice 7)
    C2A      DB 'ensamblador$'              ; ejemplo 2A
    C2B      DB 'ensamblador$'              ; ejemplo 2B (iguales)
    C3A      DB 'casa$'                     ; ejemplo 3A (prefijo)
    C3B      DB 'casas$'                    ; ejemplo 3B (difiere en indice 4)
    MSG_TIT  DB '=== DEMO COMPARACION CARACTER POR CARACTER ===$' ; titulo
    MSG_VS   DB ' vs $'                     ; separador
    MSG_IG   DB '  Resultado : IGUALES (coinciden todos: $' ; iguales
    MSG_DIF  DB '  Resultado : DIFERENTES$' ; diferentes
    MSG_COI  DB '  Coinciden : $'           ; coincidencias
    MSG_CAR  DB ' caracteres$'              ; sufijo
    MSG_POS1 DB '  1a dif.   : posicion $'  ; posicion base 1
    MSG_POS2 DB ' (indice $'                ; indice base 0
    MSG_CIE  DB ')$'                        ; cierre parentesis
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET C1A                      ; par 1: computador vs computacion
    MOV DI, OFFSET C1B                      ; puntero 2
    CALL MOSTRAR_COMPARACION                ; ejecuta y muestra detalle

    MOV SI, OFFSET C2A                      ; par 2: ensamblador vs ensamblador
    MOV DI, OFFSET C2B                      ; puntero 2
    CALL MOSTRAR_COMPARACION                ; ejecuta y muestra detalle

    MOV SI, OFFSET C3A                      ; par 3: casa vs casas
    MOV DI, OFFSET C3B                      ; puntero 2
    CALL MOSTRAR_COMPARACION                ; ejecuta y muestra detalle

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO AUXILIAR DE DEMO: imprime resultado detallado
;------------------------------------------------------------------------------
MOSTRAR_COMPARACION PROC                    ; inicio auxiliar
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX
    PUSH DX                                 ; guarda DX

    MOV DX, SI                              ; imprime cadena 1
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; muestra
    IMPRIMIR_CADENA MSG_VS                  ; " vs "
    MOV DX, DI                              ; imprime cadena 2
    MOV AH, 09h                             ; DOS AH=09h
    INT 21h                                 ; muestra
    SALTO_LINEA                             ; nueva linea

    CALL COMPARAR_POSICION                  ; BL=1/0, AX=coincidencias
    CMP BL, 1                               ; son iguales?
    JNE MC_DIF                              ; no: muestra posicion distinta
    IMPRIMIR_CADENA MSG_IG                  ; "  Resultado : IGUALES..."
    IMPRIMIR_NUMERO AX                      ; total caracteres coincidentes
    IMPRIMIR_CADENA MSG_CIE                 ; ")"
    SALTO_LINEA                             ; nueva linea
    JMP MC_FIN                              ; termina
MC_DIF:                                     ; rama diferentes
    IMPRIMIR_CADENA MSG_DIF                 ; "  Resultado : DIFERENTES"
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_COI                 ; "  Coinciden : "
    IMPRIMIR_NUMERO AX                      ; cantidad de coincidencias
    IMPRIMIR_CADENA MSG_CAR                 ; " caracteres"
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_POS1                ; "  1a dif.   : posicion "
    MOV BX, AX                              ; BX = indice base 0
    INC BX                                  ; BX = posicion base 1
    IMPRIMIR_NUMERO BX                      ; posicion humana (1..)
    IMPRIMIR_CADENA MSG_POS2                ; " (indice "
    IMPRIMIR_NUMERO AX                      ; indice base 0 (0..)
    IMPRIMIR_CADENA MSG_CIE                 ; ")"
    SALTO_LINEA                             ; nueva linea
MC_FIN:                                     ; salida
    POP DX                                  ; restaura DX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MOSTRAR_COMPARACION ENDP                    ; fin auxiliar

;====== INICIO BLOQUE REUTILIZABLE: COMPARAR_POSICION ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_POSICION
;   Entrada : SI = offset cadena 1 ('$'), DI = offset cadena 2 ('$').
;   Salida  : BL = 1 si iguales, BL = 0 si diferentes (BH = 0).
;             AX = cantidad de caracteres que coinciden al inicio (y tambien
;                  indice base 0 de la primera diferencia cuando BL = 0).
;   Modifica: AX, BX y banderas. Conserva CX, DX, SI, DI.
;------------------------------------------------------------------------------
COMPARAR_POSICION PROC                      ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (contador)
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI
    XOR CX, CX                              ; CX = 0 caracteres coincidentes
CP_CICLO:                                   ; compara byte a byte
    MOV AL, [SI]                            ; AL = caracter actual de cad1
    MOV AH, [DI]                            ; AH = caracter actual de cad2
    CMP AL, AH                              ; son iguales?
    JNE CP_DIF                              ; no: primera diferencia en CX
    CMP AL, '$'                             ; ambos llegaron al fin '$'?
    JE CP_IGUAL                             ; si: cadenas identicas
    INC CX                                  ; un caracter coincidente mas
    INC SI                                  ; avanza cad1
    INC DI                                  ; avanza cad2
    JMP CP_CICLO                            ; siguiente caracter
CP_IGUAL:                                   ; terminaron a la vez sin diferir
    MOV BX, 1                               ; BL = 1 (iguales), BH = 0
    JMP CP_FIN                              ; salta al final
CP_DIF:                                     ; difieren en posicion CX
    MOV BX, 0                               ; BL = 0 (diferentes), BH = 0
CP_FIN:                                     ; salida comun
    MOV AX, CX                              ; AX = coincidencias / indice dif.
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
COMPARAR_POSICION ENDP                      ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: COMPARAR_POSICION ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
