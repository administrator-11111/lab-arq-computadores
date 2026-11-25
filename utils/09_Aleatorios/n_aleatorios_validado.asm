;==============================================================================
; ARCHIVO      : n_aleatorios_validado.asm
; TIPO         : ALGORITMO (+ programa de demostracion)
; DESCRIPCION  : Lee una cantidad N por teclado, valida que 0 <= N <= 30
;                (repitiendo la solicitud si es invalida), genera N numeros
;                aleatorios en [1, 100] dentro de un vector, los muestra y
;                cuenta cuantos son primos y cuantos no primos.
; FUNCIONAMIENTO:
;   1) Pide N con LEER_NUMERO y compara contra 30 (como es sin signo, todo
;      numero valido cumple N <= 30; N = 0 es valido y no genera elementos).
;   2) Si N > 30, muestra un mensaje de error y repite la lectura.
;   3) Si N = 0, informa que no se generaron numeros y termina con contadores 0.
;   4) Si N > 0, llena VECTOR (DW) llamando a GENERAR_ALEATORIO en un ciclo,
;      lo muestra con MOSTRAR_VECTOR y recorre el vector llamando a ES_PRIMO
;      para incrementar CONT_PRIMOS o CONT_NOPRIMOS.
; REGISTROS    :
;   LLENAR_ALEATORIOS -> Entrada: SI = offset del vector, CX = N,
;                        BX = minimo, DX = maximo. Conserva todos los registros.
; VARIABLES    : SEMILLA DW 0, VECTOR DW 30 DUP(0), CANTIDAD DW 0,
;                CONT_PRIMOS DW 0, CONT_NOPRIMOS DW 0.
; DEPENDENCIAS : Macros de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y procedimientos INICIALIZAR_SEMILLA, GENERAR_ALEATORIO,
;                MOSTRAR_VECTOR y ES_PRIMO.
; COMO INTEGRAR: Copiar las macros, declarar SEMILLA y el vector DW en DATOS,
;                y copiar LLENAR_ALEATORIOS junto con los procedimientos
;                canonicos dentro de CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      :
;   Ingrese cantidad N (0 a 30): 35
;   Error: N debe estar entre 0 y 30.
;   Ingrese cantidad N (0 a 30): 6
;   Numeros generados: 17 42 5 88 23 10
;   Primos   : 3
;   No primos: 3
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
    VECTOR        DW 30 DUP(0)              ; almacena hasta 30 aleatorios
    CANTIDAD      DW 0                      ; N ingresado por el usuario
    CONT_PRIMOS   DW 0                      ; cantidad de numeros primos
    CONT_NOPRIMOS DW 0                      ; cantidad de numeros no primos
    MSG_PEDIR     DB 'Ingrese cantidad N (0 a 30): $'          ; solicitud
    MSG_ERR       DB 'Error: N debe estar entre 0 y 30.$'      ; error rango
    MSG_CERO      DB 'N = 0: no se genero ningun numero.$'     ; caso N=0
    MSG_NUMS      DB 'Numeros generados: $'                    ; etiqueta
    MSG_PRI       DB 'Primos   : $'                            ; conteo primos
    MSG_NOPRI     DB 'No primos: $'                            ; conteo no pri
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    CALL INICIALIZAR_SEMILLA                ; semilla inicial desde el reloj

PEDIR_N:                                    ; ciclo de validacion de N
    IMPRIMIR_CADENA MSG_PEDIR               ; solicita N
    LEER_NUMERO                             ; AX = valor ingresado (sin signo)
    SALTO_LINEA                             ; baja de linea tras el Enter
    CMP AX, 30                              ; N <= 30 ? (0 es el minimo)
    JBE N_VALIDO                            ; si: N esta en [0, 30]
    IMPRIMIR_CADENA MSG_ERR                 ; no: avisa del error
    SALTO_LINEA                             ; nueva linea
    JMP PEDIR_N                             ; vuelve a pedir N

N_VALIDO:                                   ; N ya esta validado
    MOV CANTIDAD, AX                        ; guarda N en memoria
    CMP AX, 0                               ; caso especial N = 0?
    JNE GENERAR_Y_CONTAR                    ; si N > 0 continua normal
    IMPRIMIR_CADENA MSG_CERO                ; informa que no se genera nada
    SALTO_LINEA                             ; nueva linea
    JMP MOSTRAR_TOTALES                     ; muestra contadores en 0

GENERAR_Y_CONTAR:                           ; genera N aleatorios y clasifica
    MOV SI, OFFSET VECTOR                   ; SI = direccion del vector
    MOV CX, CANTIDAD                        ; CX = N elementos
    MOV BX, 1                               ; BX = minimo (1)
    MOV DX, 100                             ; DX = maximo (100)
    CALL LLENAR_ALEATORIOS                  ; llena VECTOR con N aleatorios

    IMPRIMIR_CADENA MSG_NUMS                ; etiqueta de los numeros
    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, CANTIDAD                        ; CX = N
    CALL MOSTRAR_VECTOR                     ; imprime los N valores
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET VECTOR                   ; SI = inicio del vector
    MOV CX, CANTIDAD                        ; CX = cantidad a clasificar
CONTAR_CICLO:                               ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_PRIMO                           ; BL = 1 si primo, 0 si no
    CMP BL, 1                               ; es primo?
    JNE CONTAR_NO                           ; no: suma a no primos
    INC CONT_PRIMOS                         ; si: suma a primos
    JMP CONTAR_SIG                          ; salta al siguiente elemento
CONTAR_NO:                                  ; rama para no primos
    INC CONT_NOPRIMOS                       ; incrementa contador de no primos
CONTAR_SIG:                                 ; avance del puntero
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CONTAR_CICLO                       ; repite CX veces

MOSTRAR_TOTALES:                            ; muestra los contadores finales
    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta "Primos   : "
    IMPRIMIR_NUMERO CONT_PRIMOS             ; imprime total de primos
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_NOPRI               ; etiqueta "No primos: "
    IMPRIMIR_NUMERO CONT_NOPRIMOS           ; imprime total de no primos
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LLENAR_ALEATORIOS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_ALEATORIOS
;   Entrada : SI = offset del vector (DW), CX = cantidad N,
;             BX = minimo, DX = maximo (BX <= DX, DX-BX < 65535).
;   Salida  : llena las primeras N posiciones del vector con aleatorios.
;   Requiere: GENERAR_ALEATORIO y SEMILLA inicializada.
;   Modifica: solo el contenido del vector y SEMILLA (conserva registros).
;------------------------------------------------------------------------------
LLENAR_ALEATORIOS PROC                      ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    PUSH SI                                 ; guarda SI
    CMP CX, 0                               ; N = 0?
    JE LLA_FIN                              ; si: no genera nada
LLA_CICLO:                                  ; llena posicion por posicion
    PUSH CX                                 ; guarda el contador del ciclo
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [BX, CX]
    MOV [SI], AX                            ; guarda el valor en el vector
    ADD SI, 2                               ; avanza a la siguiente palabra
    POP CX                                  ; recupera el contador del ciclo
    LOOP LLA_CICLO                          ; repite N veces
LLA_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_ALEATORIOS ENDP                      ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LLENAR_ALEATORIOS ======

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
