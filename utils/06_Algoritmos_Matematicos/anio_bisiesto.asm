;==============================================================================
; ARCHIVO      : anio_bisiesto.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Determina si un anio (calendario gregoriano) es bisiesto y
;                almacena el resultado en las variables VarEsBisiesto y
;                VarNoEsBisiesto, ademas de devolverlo en BL.
; FUNCIONAMIENTO: Reglas del calendario gregoriano:
;                1) Si es divisible por 400 -> ES bisiesto (ej. 2000, 2400).
;                2) Si no, si es divisible por 100 -> NO es bisiesto (ej. 1900,
;                   2100).
;                3) Si no, si es divisible por 4 -> ES bisiesto (ej. 2024).
;                4) En otro caso -> NO es bisiesto (ej. 2023).
;                Equivale a: (divisible por 4 y NO por 100) o (divisible por 400).
;                DIVISION DE 16 BITS EN 8086:
;                La instruccion DIV con operando de 16 bits (ej. DIV CX) divide
;                el numero de 32 bits formado por DX:AX entre CX, dejando el
;                cociente en AX y el residuo en DX. Por eso SIEMPRE hay que
;                poner DX = 0 con XOR DX, DX antes de DIV (si DX tuviera basura
;                el resultado seria erroneo o causaria desborde de division).
;                Para saber si el anio es divisible por CX basta revisar
;                CMP DX, 0 (residuo igual a cero).
; REGISTROS    : Entrada  : AX = anio (entero sin signo, 0..65535)
;                Salida   : BL = 1 si es bisiesto, BL = 0 si no (BH = 0)
;                           VarEsBisiesto = 1 y VarNoEsBisiesto = 0 si bisiesto
;                           VarEsBisiesto = 0 y VarNoEsBisiesto = 1 si no
;                Modifica : BX, VarEsBisiesto, VarNoEsBisiesto y banderas.
;                           Conserva AX, CX, DX.
; VARIABLES    : Requiere en el segmento DATOS:
;                  VarEsBisiesto   DB 0
;                  VarNoEsBisiesto DB 0
; DEPENDENCIAS : Ninguna para el procedimiento ES_BISIESTO (solo las 2 vars).
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO y SALTO_LINEA
;                (copiadas de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm).
; COMO INTEGRAR: 1) Declarar VarEsBisiesto DB 0 y VarNoEsBisiesto DB 0 en DATOS.
;                2) Copiar el bloque reutilizable ES_BISIESTO en CODIGO despues
;                   de la salida a DOS.
;                3) Cargar el anio en AX y ejecutar CALL ES_BISIESTO.
; EJEMPLO      : Prueba 1900, 2000, 2023, 2024, 2100, 2400:
;                  1900 -> NO ES BISIESTO (VarEs=0, VarNo=1)
;                  2000 -> ES BISIESTO    (VarEs=1, VarNo=0)
;                  2023 -> NO ES BISIESTO (VarEs=0, VarNo=1)
;                  2024 -> ES BISIESTO    (VarEs=1, VarNo=0)
;                  2100 -> NO ES BISIESTO (VarEs=0, VarNo=1)
;                  2400 -> ES BISIESTO    (VarEs=1, VarNo=0)
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
    VarEsBisiesto   DB 0                    ; queda en 1 si el anio es bisiesto
    VarNoEsBisiesto DB 0                    ; queda en 1 si NO es bisiesto
    MSG_TITULO DB '=== DEMO: ANIO BISIESTO (4 / 100 / 400) ===$' ; titulo
    MSG_SI     DB ' -> ES BISIESTO    (VarEs=$'  ; texto bisiesto
    MSG_NO     DB ' -> NO ES BISIESTO (VarEs=$'  ; texto no bisiesto
    MSG_VNO    DB ', VarNo=$'               ; separador de segunda variable
    MSG_CIERRE DB ')$'                      ; cierre de parentesis
    PRUEBAS    DW 1900, 2000, 2023, 2024, 2100, 2400 ; anios de prueba
    CANTIDAD   DW 6                         ; cantidad de anios a probar
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET PRUEBAS                  ; SI apunta al primer anio
    MOV CX, CANTIDAD                        ; CX = cantidad de pruebas
DEMO_CICLO:                                 ; recorre cada anio de prueba
    MOV AX, [SI]                            ; AX = anio actual
    IMPRIMIR_NUMERO AX                      ; muestra el anio
    CALL ES_BISIESTO                        ; evalua y actualiza variables + BL
    CMP BL, 1                               ; es bisiesto?
    JNE DEMO_NO                             ; no: muestra mensaje negativo
    IMPRIMIR_CADENA MSG_SI                  ; si: muestra mensaje positivo
    JMP DEMO_VARS                           ; muestra valores de las variables
DEMO_NO:                                    ; rama no bisiesto
    IMPRIMIR_CADENA MSG_NO                  ; muestra mensaje negativo
DEMO_VARS:                                  ; imprime ambas variables DB
    MOV AL, VarEsBisiesto                   ; carga byte VarEsBisiesto en AL
    MOV AH, 0                               ; extiende a 16 bits para imprimir
    IMPRIMIR_NUMERO AX                      ; muestra 0 o 1
    IMPRIMIR_CADENA MSG_VNO                 ; muestra ", VarNo="
    MOV AL, VarNoEsBisiesto                 ; carga byte VarNoEsBisiesto en AL
    MOV AH, 0                               ; extiende a 16 bits
    IMPRIMIR_NUMERO AX                      ; muestra 0 o 1
    IMPRIMIR_CADENA MSG_CIERRE              ; muestra ")"
    SALTO_LINEA                             ; nueva linea
    ADD SI, 2                               ; siguiente palabra DW
    DEC CX                                  ; decrementa contador (evita LOOP
    JZ DEMO_FIN                             ; fuera de rango de +-127 bytes
    JMP DEMO_CICLO                          ; por las macros expandidas)
DEMO_FIN:                                   ; fin de la demostracion

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: ES_BISIESTO ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_BISIESTO
;   Entrada : AX = anio (sin signo, 0..65535)
;   Salida  : BL = 1 si es bisiesto, BL = 0 si no (BH = 0)
;             VarEsBisiesto = 1, VarNoEsBisiesto = 0  (si es bisiesto)
;             VarEsBisiesto = 0, VarNoEsBisiesto = 1  (si NO es bisiesto)
;   Requiere: VarEsBisiesto DB 0 y VarNoEsBisiesto DB 0 en DATOS.
;   Modifica: BX, VarEsBisiesto, VarNoEsBisiesto y banderas. Conserva AX,CX,DX.
;------------------------------------------------------------------------------
ES_BISIESTO PROC                            ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (anio original)
    PUSH CX                                 ; guarda CX (divisor 16 bits)
    PUSH DX                                 ; guarda DX (residuo de DIV)
    PUSH SI                                 ; guarda SI (copia del anio)

    MOV SI, AX                              ; SI = copia del anio (DIV pisa AX)
    MOV BX, 0                               ; BH = 0, supone BL = 0

    ; Paso 1: divisible por 400? (si si, es bisiesto sin excepcion)
    MOV AX, SI                              ; AX = anio (parte baja dividendo)
    XOR DX, DX                              ; DX = 0 (dividendo DX:AX = anio)
    MOV CX, 400                             ; divisor de 16 bits = 400
    DIV CX                                  ; AX = anio/400, DX = anio mod 400
    CMP DX, 0                               ; residuo igual a 0?
    JE BISI_SI                              ; si: divisible por 400 -> bisiesto

    ; Paso 2: divisible por 100? (como no lo fue por 400, NO es bisiesto)
    MOV AX, SI                              ; restaura AX = anio
    XOR DX, DX                              ; limpia DX antes del nuevo DIV
    MOV CX, 100                             ; divisor de 16 bits = 100
    DIV CX                                  ; AX = anio/100, DX = anio mod 100
    CMP DX, 0                               ; residuo igual a 0?
    JE BISI_NO                              ; si: multiplo de 100 -> no bisiesto

    ; Paso 3: divisible por 4? (como no es multiplo de 100, SI es bisiesto)
    MOV AX, SI                              ; restaura AX = anio
    XOR DX, DX                              ; limpia DX antes del nuevo DIV
    MOV CX, 4                               ; divisor de 16 bits = 4
    DIV CX                                  ; AX = anio/4, DX = anio mod 4
    CMP DX, 0                               ; residuo igual a 0?
    JE BISI_SI                              ; si: divisible por 4 -> bisiesto

BISI_NO:                                    ; el anio NO es bisiesto
    MOV VarEsBisiesto, 0                    ; marca variable bisiesto = 0
    MOV VarNoEsBisiesto, 1                  ; marca variable no bisiesto = 1
    MOV BL, 0                               ; devuelve BL = 0
    JMP BISI_FIN                            ; salta a restaurar registros

BISI_SI:                                    ; el anio SI es bisiesto
    MOV VarEsBisiesto, 1                    ; marca variable bisiesto = 1
    MOV VarNoEsBisiesto, 0                  ; marca variable no bisiesto = 0
    MOV BL, 1                               ; devuelve BL = 1

BISI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX original
    RET                                     ; vuelve al llamador
ES_BISIESTO ENDP                            ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: ES_BISIESTO ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
