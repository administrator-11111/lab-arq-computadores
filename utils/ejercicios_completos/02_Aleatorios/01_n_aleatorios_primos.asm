;==============================================================================
; EJERCICIO    : N numeros aleatorios y conteo de primos / no primos
; ARCHIVO      : 01_n_aleatorios_primos.asm
; ENUNCIADO    : Solicitar al usuario una cantidad N validada entre 0 y 30,
;                generar N numeros aleatorios en [1, 100], mostrarlos en
;                pantalla, contar cuantos son primos y cuantos no primos, y
;                mostrar ambos resultados.
; SOLUCION     :
;   1) Inicializa la semilla aleatoria con la hora del sistema (INT 21h/2Ch).
;   2) Lee N con LEER_NUMERO en un ciclo hasta que N <= 30 (N = 0 es valido).
;   3) Si N > 0, genera N aleatorios en [1, 100] y los guarda en VECTOR (DW).
;   4) Muestra los N numeros usando MOSTRAR_VECTOR.
;   5) Recorre VECTOR evaluando cada numero con ES_PRIMO para incrementar
;      CONT_PRIMOS o CONT_NOPRIMOS, y finalmente imprime ambos totales.
; REGISTROS    : AX (numero/resultados), BX (minimo y resultado de ES_PRIMO),
;                CX (contador LOOP y maximo), SI (puntero al vector).
; VARIABLES    : SEMILLA, VECTOR (30 DW), CANTIDAD, CONT_PRIMOS, CONT_NOPRIMOS.
; UTILS RELACIONADOS:
;   - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;   - utils/09_Aleatorios/generar_aleatorio.asm
;   - utils/09_Aleatorios/n_aleatorios_validado.asm
; EJEMPLO DE ENTRADA/SALIDA (run8086.py --time 08:05:59.99):
;   === N ALEATORIOS: PRIMOS Y NO PRIMOS ===
;   Ingrese cantidad N (0 a 30): 40
;   Valor invalido. Debe estar entre 0 y 30.
;   Ingrese cantidad N (0 a 30): 6
;   Numeros generados: 15 49 92 85 24 39
;   Cantidad de primos   : 0
;   Cantidad de no primos: 6
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

IMPRIMIR_ESPACIO MACRO                      ; macro sin parametros
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV DL, ' '                             ; caracter espacio (20h)
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    INT 21h                                 ; muestra el espacio
    POP DX                                  ; restaura DX
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

FIN_PROGRAMA MACRO                          ; macro sin parametros
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; DOS finaliza el programa
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    SEMILLA       DW 0                      ; semilla del generador LCG
    VECTOR        DW 30 DUP(0)              ; guarda hasta 30 aleatorios
    CANTIDAD      DW 0                      ; N ingresado por teclado
    CONT_PRIMOS   DW 0                      ; total de primos encontrados
    CONT_NOPRIMOS DW 0                      ; total de no primos encontrados
    MSG_TIT       DB '=== N ALEATORIOS: PRIMOS Y NO PRIMOS ===$'  ; titulo
    MSG_PEDIR     DB 'Ingrese cantidad N (0 a 30): $'             ; pedido
    MSG_ERR       DB 'Valor invalido. Debe estar entre 0 y 30.$'  ; error
    MSG_VACIO     DB 'No se generaron numeros (N = 0).$'          ; caso N=0
    MSG_NUMS      DB 'Numeros generados: $'                       ; lista
    MSG_PRI       DB 'Cantidad de primos   : $'                   ; primos
    MSG_NOPRI     DB 'Cantidad de no primos: $'                   ; no primos
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = direccion de DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    CALL INICIALIZAR_SEMILLA                ; toma semilla de la hora DOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

LEER_N:                                     ; ciclo hasta recibir N valido
    IMPRIMIR_CADENA MSG_PEDIR               ; solicita N
    LEER_NUMERO                             ; AX = N sin signo
    SALTO_LINEA                             ; baja de linea tras Enter
    CMP AX, 30                              ; N <= 30 ?
    JBE N_OK                                ; si: valido (incluye N = 0)
    IMPRIMIR_CADENA MSG_ERR                 ; no: muestra error
    SALTO_LINEA                             ; nueva linea
    JMP LEER_N                              ; repite solicitud

N_OK:                                       ; N es valido (0..30)
    MOV CANTIDAD, AX                        ; guarda N en memoria
    CMP AX, 0                               ; N = 0?
    JNE GENERAR_NUMS                        ; si N > 0, genera los numeros
    IMPRIMIR_CADENA MSG_VACIO               ; informa que N es 0
    SALTO_LINEA                             ; nueva linea
    JMP MOSTRAR_RES                         ; salta a mostrar totales (0 y 0)

GENERAR_NUMS:                               ; genera N aleatorios en [1, 100]
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, CANTIDAD                        ; CX = N
CICLO_GEN:                                  ; ciclo de generacion
    PUSH CX                                 ; guarda el contador
    MOV BX, 1                               ; minimo = 1
    MOV CX, 100                             ; maximo = 100
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 100]
    MOV [SI], AX                            ; almacena en VECTOR
    ADD SI, 2                               ; siguiente palabra
    POP CX                                  ; recupera el contador
    LOOP CICLO_GEN                          ; repite N veces

    IMPRIMIR_CADENA MSG_NUMS                ; muestra etiqueta de la lista
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, CANTIDAD                        ; CX = N
    CALL MOSTRAR_VECTOR                     ; imprime los N valores
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, CANTIDAD                        ; CX = N
CICLO_CLAS:                                 ; clasifica cada numero
    MOV AX, [SI]                            ; AX = numero actual
    CALL ES_PRIMO                           ; BL = 1 si primo, 0 si no
    CMP BL, 1                               ; es primo?
    JNE ES_NOPRIMO                          ; no: suma en no primos
    INC CONT_PRIMOS                         ; si: suma en primos
    JMP SIG_CLAS                            ; pasa al siguiente
ES_NOPRIMO:                                 ; rama no primo
    INC CONT_NOPRIMOS                       ; incrementa no primos
SIG_CLAS:                                   ; avanza puntero
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CICLO_CLAS                         ; repite N veces

MOSTRAR_RES:                                ; muestra resumen final
    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta primos
    IMPRIMIR_NUMERO CONT_PRIMOS             ; valor primos
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_NOPRI               ; etiqueta no primos
    IMPRIMIR_NUMERO CONT_NOPRIMOS           ; valor no primos
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO INICIALIZAR_SEMILLA (canonico)
;------------------------------------------------------------------------------
INICIALIZAR_SEMILLA PROC                    ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    MOV AH, 2Ch                             ; servicio 2Ch: obtener hora
    INT 21h                                 ; CX = hora:min, DX = seg:cent
    XOR DX, CX                              ; mezcla los bits de ambos
    MOV SEMILLA, DX                         ; guarda la semilla inicial
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
INICIALIZAR_SEMILLA ENDP                    ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO GENERAR_ALEATORIO (canonico)
;------------------------------------------------------------------------------
GENERAR_ALEATORIO PROC                      ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (maximo)
    PUSH DX                                 ; guarda DX (MUL/DIV lo usan)
    MOV AX, SEMILLA                         ; AX = semilla actual
    MOV DX, 25173                           ; DX = multiplicador del LCG
    MUL DX                                  ; DX:AX = semilla * 25173
    ADD AX, 13849                           ; suma el incremento (mod 65536)
    MOV SEMILLA, AX                         ; guarda la nueva semilla
    XCHG AH, AL                             ; usa los bits altos como bajos
    SUB CX, BX                              ; CX = max - min
    INC CX                                  ; CX = cantidad de valores
    XOR DX, DX                              ; DX:AX = valor pseudoaleatorio
    DIV CX                                  ; DX = valor mod cantidad
    MOV AX, DX                              ; AX = desplazamiento 0..rango-1
    ADD AX, BX                              ; AX = min + desplazamiento
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
GENERAR_ALEATORIO ENDP                      ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_VECTOR (canonico)
;------------------------------------------------------------------------------
MOSTRAR_VECTOR PROC                         ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    CMP CX, 0                               ; vector vacio?
    JE MV_FIN                               ; si: no hay nada que mostrar
MV_CICLO:                                   ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    IMPRIMIR_NUMERO AX                      ; lo muestra
    IMPRIMIR_ESPACIO                        ; separador
    ADD SI, 2                               ; siguiente elemento (2 bytes)
    LOOP MV_CICLO                           ; repite CX veces
MV_FIN:                                     ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MOSTRAR_VECTOR ENDP                         ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PRIMO (canonico)
;------------------------------------------------------------------------------
ES_PRIMO PROC                               ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (se usa en MUL/DIV)
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    MOV BX, 0                               ; supone "no es primo"
    CMP AX, 2                               ; n < 2 ?
    JB EPRI_FIN                             ; 0 y 1 no son primos
    MOV SI, AX                              ; SI = n (AX se reutilizara)
    MOV CX, 2                               ; primer divisor a probar
EPRI_CICLO:                                 ; prueba cada divisor
    MOV AX, CX                              ; AX = d
    MUL CX                                  ; DX:AX = d * d
    CMP DX, 0                               ; el producto paso de 16 bits?
    JNE EPRI_SI                             ; si: d*d > n, no hay divisores
    CMP AX, SI                              ; compara d*d con n
    JA EPRI_SI                              ; d*d > n: ya se probo todo
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0, dividendo DX:AX = n
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; division exacta?
    JE EPRI_FIN                             ; si: tiene divisor, no es primo
    INC CX                                  ; siguiente divisor
    JMP EPRI_CICLO                          ; repite la prueba
EPRI_SI:                                    ; no se encontro divisor
    MOV BL, 1                               ; es primo
EPRI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_PRIMO ENDP                               ; fin del procedimiento

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
