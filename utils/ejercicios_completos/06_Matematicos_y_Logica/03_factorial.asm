;==============================================================================
; EJERCICIO    : Calculo del factorial con validacion de rango de 16 bits
; ARCHIVO      : 03_factorial.asm
; ENUNCIADO    : Leer un numero entero sin signo n por teclado, validar que
;                este en el rango 0..8 (explicando el limite de 16 bits),
;                calcular n! (contemplando 0! = 1 y 1! = 1) y mostrar el
;                resultado en pantalla.
; SOLUCION     : 1) Se lee n por teclado mediante LEER_NUMERO y se guarda en N.
;                2) Se valida que N <= 8, porque en 16 bits sin signo el maximo
;                   valor representable es 65535: 8! = 40320 cabe en AX, pero
;                   9! = 362880 lo supera y produce desborde.
;                3) Si N > 8 se muestra un mensaje de error explicando el limite.
;                4) Si 0 <= N <= 8 se llama a FACTORIAL (que trata 0! = 1 y
;                   1! = 1 y multiplica 2..n) y se imprime "n! = resultado".
; REGISTROS    : AX = n (entrada) / n! (salida)
;                BL = indicador de desborde (0 = valido, 1 = desborde), BH = 0
; VARIABLES    : NUM_N     DW 0 -> numero n ingresado por teclado
;                RESULTADO DW 0 -> resultado de n!
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/06_Algoritmos_Matematicos/factorial.asm
; EJEMPLO DE ENTRADA/SALIDA:
;                Entrada: 8
;                Salida :
;                  === CALCULO DE FACTORIAL (0..8 en 16 bits) ===
;                  Nota: 8! = 40320 es el maximo que cabe en 16 bits (65535).
;                  Ingrese n (0..8): 8
;                  Resultado: 8! = 40320
;
;                Entrada: 9
;                Salida :
;                  === CALCULO DE FACTORIAL (0..8 en 16 bits) ===
;                  Nota: 8! = 40320 es el maximo que cabe en 16 bits (65535).
;                  Ingrese n (0..8): 9
;                  ERROR: n debe estar entre 0 y 8 (9! = 362880 supera 65535).
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

LEER_NUMERO MACRO                           ; macro sin parametros
    LOCAL LN_LEER, LN_FIN                   ; etiquetas unicas por cada uso
    PUSH BX                                 ; guarda BX (acumulador)
    PUSH CX                                 ; guarda CX (cifra)
    PUSH DX                                 ; guarda DX (MUL lo modifica)
    XOR BX, BX                              ; acumulado = 0
LN_LEER:                                    ; ciclo de lectura de teclas
    MOV AH, 01h                             ; servicio 01h: leer tecla + eco
    INT 21h                                 ; AL = tecla presionada
    CMP AL, 13                              ; es Enter (retorno de carro)?
    JE LN_FIN                               ; si: termina la lectura
    CMP AL, '0'                             ; menor que el ASCII '0'?
    JB LN_LEER                              ; no es digito: lo ignora
    CMP AL, '9'                             ; mayor que el ASCII '9'?
    JA LN_LEER                              ; no es digito: lo ignora
    SUB AL, '0'                             ; convierte ASCII a valor 0..9
    MOV CL, AL                              ; CL = cifra leida
    MOV CH, 0                               ; CX = cifra en 16 bits
    MOV AX, BX                              ; AX = acumulado actual
    MOV DX, 10                              ; DX = multiplicador 10
    MUL DX                                  ; DX:AX = acumulado * 10
    ADD AX, CX                              ; suma la nueva cifra
    MOV BX, AX                              ; guarda el nuevo acumulado
    JMP LN_LEER                             ; lee la siguiente tecla
LN_FIN:                                     ; se presiono Enter
    MOV AX, BX                              ; AX = numero leido (resultado)
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    NUM_N     DW 0                          ; numero n leido por teclado
    RESULTADO DW 0                          ; resultado de n!
    MSG_TITULO DB '=== CALCULO DE FACTORIAL (0..8 en 16 bits) ===$' ; titulo
    MSG_NOTA   DB 'Nota: 8! = 40320 es el maximo que cabe en 16 bits (65535).$' ; limite
    MSG_PEDIR  DB 'Ingrese n (0..8): $'     ; solicitud de entrada
    MSG_RES    DB 'Resultado: $'            ; prefijo de resultado
    MSG_IGUAL  DB '! = $'                   ; separador factorial
    MSG_ERROR  DB 'ERROR: n debe estar entre 0 y 8 (9! = 362880 supera 65535).$' ; error
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_NOTA                ; explica limite de 16 bits
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PEDIR               ; solicita n
    LEER_NUMERO                             ; AX = n leido
    MOV NUM_N, AX                           ; guarda n en memoria
    SALTO_LINEA                             ; nueva linea tras Enter

    CMP AX, 8                               ; valida rango 0..8 (sin signo)
    JBE EJ_VALIDO                           ; si n <= 8 es valido
    JMP EJ_ERROR                            ; si n > 8 salta al mensaje error
EJ_VALIDO:                                  ; calcula y muestra n!
    CALL FACTORIAL                          ; AX = n!, BL = 0 (garantizado)
    MOV RESULTADO, AX                       ; guarda el resultado
    IMPRIMIR_CADENA MSG_RES                 ; muestra "Resultado: "
    IMPRIMIR_NUMERO NUM_N                   ; muestra n
    IMPRIMIR_CADENA MSG_IGUAL               ; muestra "! = "
    IMPRIMIR_NUMERO RESULTADO               ; muestra n!
    SALTO_LINEA                             ; nueva linea
    JMP EJ_FIN                              ; salta al cierre
EJ_ERROR:                                   ; fuera de rango (> 8)
    IMPRIMIR_CADENA MSG_ERROR               ; muestra error del limite 16 bits
    SALTO_LINEA                             ; nueva linea
EJ_FIN:                                     ; salida a DOS
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO FACTORIAL (de utils/06_Algoritmos_Matematicos/factorial.asm)
;   Entrada : AX = n (entero sin signo)
;   Salida  : AX = n! (0 si hubo desborde)
;             BL = 1 si desbordo 16 bits (n >= 9), BL = 0 si valido (BH = 0)
;   Modifica: AX, BX y banderas. Conserva CX, DX, SI.
;------------------------------------------------------------------------------
FACTORIAL PROC                              ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (multiplicador)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (limite n)
    MOV BX, 0                               ; supone sin desborde (BH=0, BL=0)
    MOV SI, AX                              ; SI = n
    MOV AX, 1                               ; resultado = 1 (cubre 0! y 1!)
    CMP SI, 1                               ; n <= 1?
    JBE FAC_FIN                             ; si: 0! = 1 y 1! = 1
    MOV CX, 2                               ; primer factor del producto
FAC_CICLO:                                  ; multiplica AX por 2, 3, ..., n
    MUL CX                                  ; DX:AX = AX * CX
    CMP DX, 0                               ; el producto supero 16 bits?
    JNE FAC_DESBORDE                        ; si: desborde (> 65535)
    CMP CX, SI                              ; ya multiplico por n?
    JE FAC_FIN                              ; si: termina con resultado en AX
    INC CX                                  ; siguiente factor
    JMP FAC_CICLO                           ; repite
FAC_DESBORDE:                               ; ocurrio desborde
    MOV AX, 0                               ; limpia resultado invalido
    MOV BL, 1                               ; activa indicador de desborde
FAC_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
FACTORIAL ENDP                              ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
