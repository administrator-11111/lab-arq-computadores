;==============================================================================
; EJERCICIO    : Analisis estadistico y clasificacion de un vector aleatorio
; ARCHIVO      : 01_analisis_vector.asm
; ENUNCIADO    : Generar un vector de 15 numeros aleatorios en el rango 1..500,
;                mostrar sus elementos y calcular: suma, promedio entero (con
;                residuo), valor minimo, cantidad de numeros pares, cantidad de
;                primos, cantidad con raiz cuadrada exacta y cantidad de
;                numeros narcisistas. Mostrar todos los resultados en pantalla.
; SOLUCION     : 1) Se inicializa la semilla aleatoria con la hora del sistema
;                   (INT 21h / AH=2Ch) mediante INICIALIZAR_SEMILLA.
;                2) Se llena VECTOR (15 palabras DW) en [1, 500] llamando a
;                   LLENAR_VECTOR_ALEATORIO y se imprime con MOSTRAR_VECTOR.
;                3) Se invocan las rutinas de analisis sobre SI = OFFSET VECTOR
;                   y CX = TAMANO: SUMA_VECTOR (32 bits DX:AX), PROMEDIO_VECTOR,
;                   MINIMO_VECTOR, CONTAR_PARES, CONTAR_PRIMOS,
;                   CONTAR_RAIZ_EXACTA y CONTAR_NARCISISTAS.
;                4) Cada resultado se muestra con IMPRIMIR_CADENA e
;                   IMPRIMIR_NUMERO.
; REGISTROS    : SI = puntero (offset) al vector; CX = cantidad de elementos
;                (15); BX/DX = limites [1, 500] al llenar; AX = resultado de
;                cada procedimiento de analisis (DX = residuo en promedio).
; VARIABLES    : SEMILLA (DW), VECTOR (15 DW), TAMANO (EQU 15), mensajes DB.
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/02_Vectores/llenar_vector_aleatorio.asm
;                - utils/04_Analisis_Vectores/suma_promedio.asm
;                - utils/04_Analisis_Vectores/minimo_maximo.asm
;                - utils/04_Analisis_Vectores/contar_pares_impares.asm
;                - utils/04_Analisis_Vectores/contar_clasificados.asm
; EJEMPLO DE ENTRADA/SALIDA (ejecucion con --time 08:05:59.99):
;                === EJERCICIO 1: ANALISIS DE VECTOR ALEATORIO ===
;                Vector (15 elementos en 1..500):
;                315 249 492 185 324 339 320 340 476 325 45 47 237 145 490
;
;                Suma        : 4329
;                Promedio    : 288  (residuo: 9)
;                Minimo      : 45
;                Pares       : 6
;                Primos      : 1
;                Raiz exacta : 1
;                Narcisistas : 0
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

FIN_PROGRAMA MACRO                          ; macro sin parametros
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; DOS finaliza el programa
ENDM                                        ; fin de la macro

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    SEMILLA    DW 0                         ; semilla del generador aleatorio
    TAMANO     EQU 15                       ; cantidad de elementos del vector
    VECTOR     DW TAMANO DUP(0)             ; vector de 15 palabras (30 bytes)

    MSG_TIT    DB '=== EJERCICIO 1: ANALISIS DE VECTOR ALEATORIO ===$' ; titulo
    MSG_VEC    DB 'Vector (15 elementos en 1..500):$' ; etiqueta vector
    MSG_SUMA   DB 'Suma        : $'         ; etiqueta suma
    MSG_PROM   DB 'Promedio    : $'         ; etiqueta promedio
    MSG_RES    DB '  (residuo: $'           ; etiqueta residuo
    MSG_CERRAR DB ')$'                      ; cierre de parentesis
    MSG_MIN    DB 'Minimo      : $'         ; etiqueta minimo
    MSG_PAR    DB 'Pares       : $'         ; etiqueta pares
    MSG_PRI    DB 'Primos      : $'         ; etiqueta primos
    MSG_RAI    DB 'Raiz exacta : $'         ; etiqueta raiz exacta
    MSG_NAR    DB 'Narcisistas : $'         ; etiqueta narcisistas
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    ; 1) Genera el vector aleatorio en el rango 1..500
    CALL INICIALIZAR_SEMILLA                ; semilla inicial desde el reloj
    MOV SI, OFFSET VECTOR                   ; SI apunta al vector
    MOV CX, TAMANO                          ; CX = 15 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 500                             ; maximo = 500
    CALL LLENAR_VECTOR_ALEATORIO            ; llena el vector

    ; 2) Muestra el vector generado
    IMPRIMIR_CADENA MSG_VEC                 ; etiqueta
    SALTO_LINEA                             ; nueva linea
    CALL MOSTRAR_VECTOR                     ; muestra los 15 elementos
    SALTO_LINEA                             ; nueva linea
    SALTO_LINEA                             ; linea en blanco

    ; 3) Suma (maximo posible 15 * 500 = 7500, cabe en AX)
    CALL SUMA_VECTOR                        ; DX:AX = suma total
    IMPRIMIR_CADENA MSG_SUMA                ; etiqueta suma
    IMPRIMIR_NUMERO AX                      ; muestra la suma
    SALTO_LINEA                             ; nueva linea

    ; 4) Promedio entero y residuo
    CALL PROMEDIO_VECTOR                    ; AX = cociente, DX = residuo
    IMPRIMIR_CADENA MSG_PROM                ; etiqueta promedio
    IMPRIMIR_NUMERO AX                      ; muestra cociente
    IMPRIMIR_CADENA MSG_RES                 ; texto "  (residuo: "
    IMPRIMIR_NUMERO DX                      ; muestra residuo
    IMPRIMIR_CADENA MSG_CERRAR              ; texto ")"
    SALTO_LINEA                             ; nueva linea

    ; 5) Minimo sin signo
    CALL MINIMO_VECTOR                      ; AX = menor valor del vector
    IMPRIMIR_CADENA MSG_MIN                 ; etiqueta minimo
    IMPRIMIR_NUMERO AX                      ; muestra minimo
    SALTO_LINEA                             ; nueva linea

    ; 6) Cantidad de pares
    CALL CONTAR_PARES                       ; AX = total de pares
    IMPRIMIR_CADENA MSG_PAR                 ; etiqueta pares
    IMPRIMIR_NUMERO AX                      ; muestra cantidad
    SALTO_LINEA                             ; nueva linea

    ; 7) Cantidad de primos
    CALL CONTAR_PRIMOS                      ; AX = total de primos
    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta primos
    IMPRIMIR_NUMERO AX                      ; muestra cantidad
    SALTO_LINEA                             ; nueva linea

    ; 8) Cantidad con raiz exacta
    CALL CONTAR_RAIZ_EXACTA                 ; AX = total con raiz exacta
    IMPRIMIR_CADENA MSG_RAI                 ; etiqueta raiz exacta
    IMPRIMIR_NUMERO AX                      ; muestra cantidad
    SALTO_LINEA                             ; nueva linea

    ; 9) Cantidad de narcisistas
    CALL CONTAR_NARCISISTAS                 ; AX = total de narcisistas
    IMPRIMIR_CADENA MSG_NAR                 ; etiqueta narcisistas
    IMPRIMIR_NUMERO AX                      ; muestra cantidad
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_VECTOR_ALEATORIO
;   Entrada : SI = offset del vector (DW), CX = cantidad, BX = min, DX = max
;   Salida  : llena el vector con CX aleatorios en [BX, DX].
;------------------------------------------------------------------------------
LLENAR_VECTOR_ALEATORIO PROC                ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero)
    CMP CX, 0                               ; vector vacio?
    JE LVA_FIN                              ; si: termina
LVA_CICLO:                                  ; ciclo de llenado
    PUSH CX                                 ; guarda contador del ciclo
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [BX, CX]
    MOV [SI], AX                            ; guarda en el vector
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    POP CX                                  ; recupera contador
    LOOP LVA_CICLO                          ; repite CX veces
LVA_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_VECTOR_ALEATORIO ENDP                ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO SUMA_VECTOR
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : DX:AX = suma de 32 bits sin signo.
;------------------------------------------------------------------------------
SUMA_VECTOR PROC                            ; inicio del procedimiento
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; parte baja = 0
    XOR DX, DX                              ; parte alta = 0
    CMP CX, 0                               ; vector vacio?
    JE SV_FIN                               ; si: devuelve 0
SV_CICLO:                                   ; recorre el vector
    ADD AX, [SI]                            ; suma palabra actual
    ADC DX, 0                               ; propaga el acarreo a DX
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP SV_CICLO                           ; repite CX veces
SV_FIN:                                     ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
SUMA_VECTOR ENDP                            ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO PROMEDIO_VECTOR
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = promedio entero, DX = residuo (0 y 0 si CX = 0).
;------------------------------------------------------------------------------
PROMEDIO_VECTOR PROC                        ; inicio del procedimiento
    CMP CX, 0                               ; vector vacio?
    JE PV_VACIO                             ; si: evita division por cero
    CALL SUMA_VECTOR                        ; DX:AX = suma de 32 bits
    DIV CX                                  ; AX = cociente, DX = residuo
    RET                                     ; vuelve al llamador
PV_VACIO:                                   ; caso vector vacio
    XOR AX, AX                              ; promedio = 0
    XOR DX, DX                              ; residuo = 0
    RET                                     ; vuelve al llamador
PROMEDIO_VECTOR ENDP                        ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO MINIMO_VECTOR
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = menor valor sin signo (0 si CX = 0).
;------------------------------------------------------------------------------
MINIMO_VECTOR PROC                          ; inicio del procedimiento
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; valor por defecto
    CMP CX, 0                               ; vector vacio?
    JE MINV_FIN                             ; si: devuelve 0
    MOV AX, [SI]                            ; minimo inicial = VECTOR[0]
    ADD SI, 2                               ; apunta al segundo elemento
    DEC CX                                  ; un elemento ya procesado
    JZ MINV_FIN                             ; si solo habia 1, termina
MINV_CICLO:                                 ; recorre el resto
    CMP [SI], AX                            ; compara actual con minimo
    JAE MINV_SIG                            ; si actual >= minimo (sin signo)
    MOV AX, [SI]                            ; nuevo minimo
MINV_SIG:                                   ; avanza al siguiente
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP MINV_CICLO                         ; repite
MINV_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
MINIMO_VECTOR ENDP                          ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_PARES
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = cantidad de elementos pares.
;------------------------------------------------------------------------------
CONTAR_PARES PROC                           ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    PUSH SI                                 ; guarda SI
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CPAR_FIN                             ; si: devuelve 0
CPAR_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_PAR                             ; BL = 1 si es par
    CMP BL, 1                               ; cumple?
    JNE CPAR_SIG                            ; no: salta
    INC DX                                  ; cuenta un par
CPAR_SIG:                                   ; avanza
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CPAR_CICLO                         ; repite
CPAR_FIN:                                   ; salida comun
    MOV AX, DX                              ; resultado en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_PARES ENDP                           ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_PRIMOS
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = cantidad de numeros primos.
;------------------------------------------------------------------------------
CONTAR_PRIMOS PROC                          ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    PUSH SI                                 ; guarda SI
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CPRI_FIN                             ; si: devuelve 0
CPRI_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_PRIMO                           ; BL = 1 si es primo
    CMP BL, 1                               ; cumple?
    JNE CPRI_SIG                            ; no: salta
    INC DX                                  ; cuenta un primo
CPRI_SIG:                                   ; avanza
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CPRI_CICLO                         ; repite
CPRI_FIN:                                   ; salida comun
    MOV AX, DX                              ; resultado en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_PRIMOS ENDP                          ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_RAIZ_EXACTA
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = cantidad de elementos con raiz cuadrada exacta.
;------------------------------------------------------------------------------
CONTAR_RAIZ_EXACTA PROC                     ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    PUSH SI                                 ; guarda SI
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CRAI_FIN                             ; si: devuelve 0
CRAI_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL TIENE_RAIZ_EXACTA                  ; BL = 1 si tiene raiz exacta
    CMP BL, 1                               ; cumple?
    JNE CRAI_SIG                            ; no: salta
    INC DX                                  ; cuenta uno mas
CRAI_SIG:                                   ; avanza
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CRAI_CICLO                         ; repite
CRAI_FIN:                                   ; salida comun
    MOV AX, DX                              ; resultado en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_RAIZ_EXACTA ENDP                     ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_NARCISISTAS
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = cantidad de numeros narcisistas.
;------------------------------------------------------------------------------
CONTAR_NARCISISTAS PROC                     ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX
    PUSH SI                                 ; guarda SI
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CNAR_FIN                             ; si: devuelve 0
CNAR_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_NARCISISTA                      ; BL = 1 si es narcisista
    CMP BL, 1                               ; cumple?
    JNE CNAR_SIG                            ; no: salta
    INC DX                                  ; cuenta un narcisista
CNAR_SIG:                                   ; avanza
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CNAR_CICLO                         ; repite
CNAR_FIN:                                   ; salida comun
    MOV AX, DX                              ; resultado en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_NARCISISTAS ENDP                     ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PAR
;   Entrada : AX = numero (sin signo, 0..65535)
;   Salida  : BL = 1 si es par, BL = 0 si es impar  (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
ES_PAR PROC                                 ; inicio del procedimiento
    MOV BX, 0                               ; supone "no es par"
    TEST AX, 1                              ; aisla el bit 0 (ZF=1 si es 0)
    JNZ EPAR_FIN                            ; bit 0 = 1: es impar, termina
    MOV BL, 1                               ; bit 0 = 0: es par
EPAR_FIN:                                   ; salida comun
    RET                                     ; vuelve al llamador
ES_PAR ENDP                                 ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PRIMO
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es primo, BL = 0 si no lo es (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI.
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

;------------------------------------------------------------------------------
; PROCEDIMIENTO TIENE_RAIZ_EXACTA
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si existe r entero con r*r = n, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI.
;------------------------------------------------------------------------------
TIENE_RAIZ_EXACTA PROC                      ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (candidato r)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (copia de n)
    MOV BX, 0                               ; supone "no tiene raiz exacta"
    MOV SI, AX                              ; SI = n
    MOV CX, 0                               ; r = 0
ERAI_CICLO:                                 ; prueba cada candidato
    MOV AX, CX                              ; AX = r
    MUL CX                                  ; DX:AX = r * r
    CMP DX, 0                               ; r*r supero 65535?
    JNE ERAI_FIN                            ; si: es mayor que n, no hay raiz
    CMP AX, SI                              ; compara r*r con n
    JE ERAI_SI                              ; iguales: raiz exacta = r
    JA ERAI_FIN                             ; r*r > n: no hay raiz exacta
    INC CX                                  ; siguiente candidato
    JMP ERAI_CICLO                          ; repite
ERAI_SI:                                    ; se encontro r
    MOV BL, 1                               ; tiene raiz exacta
ERAI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
TIENE_RAIZ_EXACTA ENDP                      ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_NARCISISTA
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es narcisista, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;------------------------------------------------------------------------------
ES_NARCISISTA PROC                          ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (k = cantidad cifras)
    PUSH DX                                 ; guarda DX (cifra / parte alta)
    PUSH SI                                 ; guarda SI (copia de n)
    PUSH DI                                 ; guarda DI (suma de potencias)
    MOV SI, AX                              ; SI = n original
    MOV BX, 10                              ; BX = divisor 10
    XOR CX, CX                              ; k = 0
ENAR_CONTAR:                                ; 1) cuenta las cifras
    XOR DX, DX                              ; DX:AX = numero restante
    DIV BX                                  ; AX = numero / 10
    INC CX                                  ; una cifra mas
    CMP AX, 0                               ; quedan cifras?
    JNE ENAR_CONTAR                         ; si: sigue contando
    XOR DI, DI                              ; suma = 0
    MOV AX, SI                              ; AX = n de nuevo
ENAR_CIFRA:                                 ; 2) procesa cada cifra
    XOR DX, DX                              ; prepara DX:AX
    MOV BX, 10                              ; divisor 10
    DIV BX                                  ; AX = resto del numero, DX=cifra
    PUSH AX                                 ; guarda lo que falta procesar
    PUSH CX                                 ; guarda k (LOOP lo consumira)
    MOV BX, DX                              ; BX = cifra (base)
    MOV AX, 1                               ; potencia = 1
ENAR_POTENCIA:                              ; potencia = cifra^k
    MUL BX                                  ; DX:AX = potencia * cifra
    CMP DX, 0                               ; paso de 16 bits?
    JNE ENAR_DESB_POT                       ; si: no puede ser narcisista
    LOOP ENAR_POTENCIA                      ; repite k veces
    POP CX                                  ; recupera k
    ADD DI, AX                              ; suma += cifra^k
    JC ENAR_DESB_SUMA                       ; la suma desbordo 16 bits
    POP AX                                  ; recupera el numero restante
    CMP AX, 0                               ; quedan cifras?
    JNE ENAR_CIFRA                          ; si: procesa la siguiente
    MOV BX, 0                               ; supone "no es narcisista"
    CMP DI, SI                              ; 3) suma == n ?
    JNE ENAR_FIN                            ; no: termina con BL = 0
    MOV BL, 1                               ; si: es narcisista
    JMP ENAR_FIN                            ; salta a restaurar registros
ENAR_DESB_POT:                              ; desborde dentro de la potencia
    POP CX                                  ; equilibra la pila (k)
ENAR_DESB_SUMA:                             ; desborde en la suma
    POP AX                                  ; equilibra la pila (restante)
    MOV BX, 0                               ; no es narcisista
ENAR_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_NARCISISTA ENDP                          ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO INICIALIZAR_SEMILLA
;   Requiere: variable  SEMILLA DW 0  en el segmento DATOS.
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
; PROCEDIMIENTO GENERAR_ALEATORIO
;   Entrada : BX = valor minimo, CX = valor maximo
;   Salida  : AX = numero pseudoaleatorio en [BX, CX]
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
; PROCEDIMIENTO MOSTRAR_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad (>0)
;   Salida  : muestra los elementos separados por un espacio.
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

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
