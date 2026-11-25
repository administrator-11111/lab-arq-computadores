;==============================================================================
; EJERCICIO    : Determinar si un anio es bisiesto
; ARCHIVO      : 01_anio_bisiesto.asm
; ENUNCIADO    : Dado un anio asignado previamente en el registro AX, determinar
;                si es bisiesto segun las reglas del calendario gregoriano
;                (divisible por 4 y no por 100, salvo que tambien sea divisible
;                por 400). Guardar el resultado en las variables VarEsBisiesto
;                y VarNoEsBisiesto (una en 1 y la otra en 0) y mostrar en
;                pantalla el anio junto con el resultado.
; SOLUCION     : 1) Se carga el anio deseado en AX (ej. MOV AX, 2024; se puede
;                   modificar ese valor para probar otros anios como 1900, 2000
;                   o 2023) y se guarda una copia en ANIO.
;                2) Se invoca ES_BISIESTO, que verifica divisibilidad usando
;                   XOR DX, DX + DIV con divisores 400, 100 y 4, comprobando si
;                   el residuo en DX es 0.
;                3) ES_BISIESTO actualiza VarEsBisiesto y VarNoEsBisiesto (y BL).
;                4) El programa principal muestra el anio, el mensaje de
;                   resultado y el valor final de ambas variables.
; REGISTROS    : AX = anio a evaluar (conservado por ES_BISIESTO)
;                BL = resultado (1 = bisiesto, 0 = no bisiesto), BH = 0
;                CX, DX, SI = usados internamente por ES_BISIESTO (conservados)
; VARIABLES    : ANIO            DW 0 -> copia del anio cargado en AX
;                VarEsBisiesto   DB 0 -> 1 si es bisiesto, 0 si no
;                VarNoEsBisiesto DB 0 -> 1 si NO es bisiesto, 0 si si
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/06_Algoritmos_Matematicos/anio_bisiesto.asm
; EJEMPLO DE ENTRADA/SALIDA:
;                (Con MOV AX, 2024 en INICIO)
;                  === VERIFICADOR DE ANIO BISIESTO ===
;                  Anio evaluado: 2024
;                  Resultado    : ES BISIESTO
;                  VarEsBisiesto = 1 | VarNoEsBisiesto = 0
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
    ANIO            DW 0                    ; copia del anio asignado a AX
    VarEsBisiesto   DB 0                    ; queda en 1 si es bisiesto
    VarNoEsBisiesto DB 0                    ; queda en 1 si NO es bisiesto
    MSG_TITULO DB '=== VERIFICADOR DE ANIO BISIESTO ===$' ; titulo
    MSG_ANIO   DB 'Anio evaluado: $'        ; etiqueta del anio
    MSG_RES    DB 'Resultado    : $'        ; etiqueta del resultado
    MSG_SI     DB 'ES BISIESTO$'            ; mensaje afirmativo
    MSG_NO     DB 'NO ES BISIESTO$'         ; mensaje negativo
    MSG_VES    DB 'VarEsBisiesto = $'       ; etiqueta variable bisiesto
    MSG_VNO    DB ' | VarNoEsBisiesto = $'  ; etiqueta variable no bisiesto
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    ; --- Asignacion previa del anio en AX (cambiar este valor para probar) ---
    MOV AX, 2024                            ; anio de prueba (ej. 1900, 2000, 2023, 2024)
    MOV ANIO, AX                            ; guarda copia del anio en memoria

    CALL ES_BISIESTO                        ; evalua AX -> actualiza variables y BL

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_ANIO                ; muestra "Anio evaluado: "
    IMPRIMIR_NUMERO ANIO                    ; muestra el anio evaluado
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_RES                 ; muestra "Resultado    : "
    CMP VarEsBisiesto, 1                    ; revisa la variable resultado
    JNE EJ_NO_BIS                           ; si es 0, no es bisiesto
    IMPRIMIR_CADENA MSG_SI                  ; muestra "ES BISIESTO"
    JMP EJ_MOSTRAR_VARS                     ; salta a mostrar las variables
EJ_NO_BIS:                                  ; rama no bisiesto
    IMPRIMIR_CADENA MSG_NO                  ; muestra "NO ES BISIESTO"
EJ_MOSTRAR_VARS:                            ; muestra ambas variables DB
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_VES                 ; muestra "VarEsBisiesto = "
    MOV AL, VarEsBisiesto                   ; carga byte en AL
    MOV AH, 0                               ; extiende a 16 bits
    IMPRIMIR_NUMERO AX                      ; muestra 0 o 1
    IMPRIMIR_CADENA MSG_VNO                 ; muestra " | VarNoEsBisiesto = "
    MOV AL, VarNoEsBisiesto                 ; carga byte en AL
    MOV AH, 0                               ; extiende a 16 bits
    IMPRIMIR_NUMERO AX                      ; muestra 0 o 1
    SALTO_LINEA                             ; nueva linea

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_BISIESTO (de utils/06_Algoritmos_Matematicos/anio_bisiesto.asm)
;   Entrada : AX = anio (sin signo, 0..65535)
;   Salida  : BL = 1 si es bisiesto, BL = 0 si no (BH = 0)
;             VarEsBisiesto = 1, VarNoEsBisiesto = 0  (si es bisiesto)
;             VarEsBisiesto = 0, VarNoEsBisiesto = 1  (si NO es bisiesto)
;   Modifica: BX, VarEsBisiesto, VarNoEsBisiesto y banderas. Conserva AX,CX,DX.
;------------------------------------------------------------------------------
ES_BISIESTO PROC                            ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (anio original)
    PUSH CX                                 ; guarda CX (divisor 16 bits)
    PUSH DX                                 ; guarda DX (residuo de DIV)
    PUSH SI                                 ; guarda SI (copia del anio)

    MOV SI, AX                              ; SI = copia del anio
    MOV BX, 0                               ; BH = 0, supone BL = 0

    MOV AX, SI                              ; AX = anio
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    MOV CX, 400                             ; divisor 400
    DIV CX                                  ; DX = anio mod 400
    CMP DX, 0                               ; divisible por 400?
    JE BISI_SI                              ; si: es bisiesto

    MOV AX, SI                              ; AX = anio
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    MOV CX, 100                             ; divisor 100
    DIV CX                                  ; DX = anio mod 100
    CMP DX, 0                               ; divisible por 100?
    JE BISI_NO                              ; si: no es bisiesto

    MOV AX, SI                              ; AX = anio
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    MOV CX, 4                               ; divisor 4
    DIV CX                                  ; DX = anio mod 4
    CMP DX, 0                               ; divisible por 4?
    JE BISI_SI                              ; si: es bisiesto

BISI_NO:                                    ; rama no bisiesto
    MOV VarEsBisiesto, 0                    ; VarEsBisiesto = 0
    MOV VarNoEsBisiesto, 1                  ; VarNoEsBisiesto = 1
    MOV BL, 0                               ; BL = 0
    JMP BISI_FIN                            ; va al cierre

BISI_SI:                                    ; rama bisiesto
    MOV VarEsBisiesto, 1                    ; VarEsBisiesto = 1
    MOV VarNoEsBisiesto, 0                  ; VarNoEsBisiesto = 0
    MOV BL, 1                               ; BL = 1

BISI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_BISIESTO ENDP                            ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
