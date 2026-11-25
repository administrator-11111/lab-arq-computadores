;==============================================================================
; ARCHIVO      : analisis_un_recorrido.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Realiza el analisis completo de un vector de palabras (DW) en
;                UN UNICO RECORRIDO: calcula suma (32 bits), minimo, maximo y
;                los 6 conteos (pares, impares, primos, perfectos, raiz exacta
;                y narcisistas) simultaneamente, y al final calcula promedio y
;                residuo.
; FUNCIONAMIENTO:
;                1) Inicializa en cero todas las variables de resultado en
;                   DATOS. Si CX = 0 termina sin dividir.
;                2) Toma el primer elemento [SI] como MINIMO y MAXIMO inicial.
;                3) Recorre el vector una sola vez (SI avanza de 2 en 2 bytes):
;                   - Acumula suma en 32 bits (SUMA_LO con ADD y SUMA_HI con
;                     ADC).
;                   - Actualiza MINIMO (si AX < MINIMO) y MAXIMO (si AX > MAX).
;                   - Clasifica AX con ES_PAR, ES_IMPAR, ES_PRIMO, ES_PERFECTO,
;                     TIENE_RAIZ_EXACTA y ES_NARCISISTA e incrementa la
;                     variable correspondiente si BL = 1.
;                4) Al salir del ciclo, carga DX:AX = SUMA_HI:SUMA_LO y divide
;                   por la cantidad original para obtener PROMEDIO y RESIDUO.
;                Nota 8086: como el cuerpo del ciclo tiene varias llamadas, se
;                usa DEC CX / JZ / JMP en vez de LOOP para no exceder el rango
;                de salto corto (+/- 127 bytes).
; REGISTROS    : ANALIZAR_VECTOR:
;                  Entrada : SI = offset del vector (DW), CX = cantidad
;                  Salida  : resultados guardados en variables de DATOS
;                  Modifica: variables de resultado (conserva AX,BX,CX,DX,SI)
; VARIABLES    : En DATOS: SUMA_LO, SUMA_HI, PROMEDIO, RESIDUO, MINIMO, MAXIMO,
;                CANT_PARES, CANT_IMPARES, CANT_PRIMOS, CANT_PERFECTOS,
;                CANT_RAIZ, CANT_NARCISISTAS (todas DW).
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimientos ES_PAR, ES_IMPAR, ES_PRIMO, ES_PERFECTO,
;                TIENE_RAIZ_EXACTA, ES_NARCISISTA, MOSTRAR_VECTOR
;                (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Copiar las variables de resultados en DATOS.
;                3) Copiar ANALIZAR_VECTOR y los 6 clasificadores en CODIGO
;                   despues de FIN_PROGRAMA.
;                4) Llamar con SI = OFFSET VECTOR y CX = N.
; EJEMPLO      : Salida esperada:
;                  === ANALISIS COMPLETO EN UN SOLO RECORRIDO ===
;                  Vector     : 2 6 9 13 28 153 16 496 371 25
;                  Suma       : 1119
;                  Promedio   : 111  (residuo: 9)
;                  Minimo     : 2
;                  Maximo     : 496
;                  Pares      : 5
;                  Impares    : 5
;                  Primos     : 2
;                  Perfectos  : 3
;                  Raiz exacta: 3
;                  Narcisistas: 5
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
    ; Suma = 2+6+9+13+28+153+16+496+371+25 = 1119
    ; Promedio = 111, residuo = 9; Min = 2, Max = 496
    ; Pares: 2,6,28,16,496 (5); Impares: 9,13,153,371,25 (5)
    ; Primos: 2,13 (2); Perfectos: 6,28,496 (3)
    ; Raiz exacta: 9,16,25 (3); Narcisistas: 2,6,9,153,371 (5)
    VECTOR     DW 2, 6, 9, 13, 28, 153, 16, 496, 371, 25 ; 10 elementos
    TAMANO     EQU 10                       ; cantidad de elementos

    ; Variables de resultados (requeridas por ANALIZAR_VECTOR)
    SUMA_LO          DW 0                   ; parte baja de la suma (bits 0..15)
    SUMA_HI          DW 0                   ; parte alta de la suma (bits 16..31)
    PROMEDIO         DW 0                   ; cociente de la division entera
    RESIDUO          DW 0                   ; residuo de la division entera
    MINIMO           DW 0                   ; menor elemento (sin signo)
    MAXIMO           DW 0                   ; mayor elemento (sin signo)
    CANT_PARES       DW 0                   ; total de numeros pares
    CANT_IMPARES     DW 0                   ; total de numeros impares
    CANT_PRIMOS      DW 0                   ; total de numeros primos
    CANT_PERFECTOS   DW 0                   ; total de numeros perfectos
    CANT_RAIZ        DW 0                   ; total con raiz cuadrada exacta
    CANT_NARCISISTAS DW 0                   ; total de numeros narcisistas

    MSG_TIT    DB '=== ANALISIS COMPLETO EN UN SOLO RECORRIDO ===$' ; titulo
    MSG_VEC    DB 'Vector     : $'          ; etiqueta vector
    MSG_SUMA   DB 'Suma       : $'          ; etiqueta suma
    MSG_PROM   DB 'Promedio   : $'          ; etiqueta promedio
    MSG_RES    DB '  (residuo: $'           ; etiqueta residuo
    MSG_CERRAR DB ')$'                      ; cierre parentesis
    MSG_MIN    DB 'Minimo     : $'          ; etiqueta minimo
    MSG_MAX    DB 'Maximo     : $'          ; etiqueta maximo
    MSG_PAR    DB 'Pares      : $'          ; etiqueta pares
    MSG_IMP    DB 'Impares    : $'          ; etiqueta impares
    MSG_PRI    DB 'Primos     : $'          ; etiqueta primos
    MSG_PER    DB 'Perfectos  : $'          ; etiqueta perfectos
    MSG_RAI    DB 'Raiz exacta: $'          ; etiqueta raiz exacta
    MSG_NAR    DB 'Narcisistas: $'          ; etiqueta narcisistas
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_VEC                 ; etiqueta vector
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 10 elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector
    SALTO_LINEA                             ; nueva linea

    ; Calcula todas las estadisticas en una sola pasada
    CALL ANALIZAR_VECTOR                    ; llena las variables de DATOS

    IMPRIMIR_CADENA MSG_SUMA                ; muestra la suma (cabe en 16 bits)
    IMPRIMIR_NUMERO SUMA_LO                 ; imprime SUMA_LO
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PROM                ; muestra el promedio y residuo
    IMPRIMIR_NUMERO PROMEDIO                ; cociente
    IMPRIMIR_CADENA MSG_RES                 ; texto "  (residuo: "
    IMPRIMIR_NUMERO RESIDUO                 ; residuo
    IMPRIMIR_CADENA MSG_CERRAR              ; texto ")"
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_MIN                 ; muestra el minimo
    IMPRIMIR_NUMERO MINIMO                  ; valor minimo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_MAX                 ; muestra el maximo
    IMPRIMIR_NUMERO MAXIMO                  ; valor maximo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PAR                 ; muestra cantidad de pares
    IMPRIMIR_NUMERO CANT_PARES              ; total pares
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_IMP                 ; muestra cantidad de impares
    IMPRIMIR_NUMERO CANT_IMPARES            ; total impares
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PRI                 ; muestra cantidad de primos
    IMPRIMIR_NUMERO CANT_PRIMOS             ; total primos
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PER                 ; muestra cantidad de perfectos
    IMPRIMIR_NUMERO CANT_PERFECTOS          ; total perfectos
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_RAI                 ; muestra cantidad con raiz exacta
    IMPRIMIR_NUMERO CANT_RAIZ               ; total raiz exacta
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_NAR                 ; muestra cantidad de narcisistas
    IMPRIMIR_NUMERO CANT_NARCISISTAS        ; total narcisistas
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: ANALIZAR_VECTOR ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO ANALIZAR_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : actualiza SUMA_LO, SUMA_HI, PROMEDIO, RESIDUO, MINIMO, MAXIMO,
;             CANT_PARES, CANT_IMPARES, CANT_PRIMOS, CANT_PERFECTOS,
;             CANT_RAIZ y CANT_NARCISISTAS en DATOS.
;   Requiere: variables de salida en DATOS y los 6 clasificadores canonicos.
;   Modifica: solo las variables de salida (conserva AX, BX, CX, DX, SI).
;------------------------------------------------------------------------------
ANALIZAR_VECTOR PROC                        ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX
    PUSH SI                                 ; guarda SI (puntero)

    ; Reinicia todas las variables de resultado en 0
    MOV SUMA_LO, 0                          ; parte baja suma = 0
    MOV SUMA_HI, 0                          ; parte alta suma = 0
    MOV PROMEDIO, 0                         ; promedio = 0
    MOV RESIDUO, 0                          ; residuo = 0
    MOV MINIMO, 0                           ; minimo = 0
    MOV MAXIMO, 0                           ; maximo = 0
    MOV CANT_PARES, 0                       ; pares = 0
    MOV CANT_IMPARES, 0                     ; impares = 0
    MOV CANT_PRIMOS, 0                      ; primos = 0
    MOV CANT_PERFECTOS, 0                   ; perfectos = 0
    MOV CANT_RAIZ, 0                        ; raiz exacta = 0
    MOV CANT_NARCISISTAS, 0                 ; narcisistas = 0

    CMP CX, 0                               ; vector vacio?
    JNE ANV_INICIAR                         ; no: comienza el recorrido
    JMP ANV_FIN                             ; si: salto largo al final

ANV_INICIAR:                                ; prepara valores iniciales
    PUSH CX                                 ; guarda N original para promedio
    MOV AX, [SI]                            ; primer elemento del vector
    MOV MINIMO, AX                          ; minimo inicial = VECTOR[0]
    MOV MAXIMO, AX                          ; maximo inicial = VECTOR[0]

ANV_CICLO:                                  ; unico recorrido del vector
    MOV AX, [SI]                            ; AX = elemento actual

    ; 1) Acumula suma en 32 bits (SUMA_HI:SUMA_LO)
    ADD SUMA_LO, AX                         ; suma a la parte baja
    ADC SUMA_HI, 0                          ; propaga el acarreo a parte alta

    ; 2) Actualiza minimo (sin signo)
    CMP AX, MINIMO                          ; AX < MINIMO ?
    JAE ANV_CHK_MAX                         ; no: comprueba maximo
    MOV MINIMO, AX                          ; si: nuevo minimo

ANV_CHK_MAX:                                ; 3) actualiza maximo (sin signo)
    CMP AX, MAXIMO                          ; AX > MAXIMO ?
    JBE ANV_CHK_PAR                         ; no: pasa a clasificaciones
    MOV MAXIMO, AX                          ; si: nuevo maximo

ANV_CHK_PAR:                                ; 4) verifica paridad (par)
    CALL ES_PAR                             ; BL = 1 si par
    CMP BL, 1                               ; es par?
    JNE ANV_CHK_IMP                         ; no: revisa impar
    INC CANT_PARES                          ; cuenta un par

ANV_CHK_IMP:                                ; 5) verifica paridad (impar)
    CALL ES_IMPAR                           ; BL = 1 si impar
    CMP BL, 1                               ; es impar?
    JNE ANV_CHK_PRI                         ; no: revisa primo
    INC CANT_IMPARES                        ; cuenta un impar

ANV_CHK_PRI:                                ; 6) verifica si es primo
    CALL ES_PRIMO                           ; BL = 1 si primo
    CMP BL, 1                               ; es primo?
    JNE ANV_CHK_PER                         ; no: revisa perfecto
    INC CANT_PRIMOS                         ; cuenta un primo

ANV_CHK_PER:                                ; 7) verifica si es perfecto
    CALL ES_PERFECTO                        ; BL = 1 si perfecto
    CMP BL, 1                               ; es perfecto?
    JNE ANV_CHK_RAI                         ; no: revisa raiz exacta
    INC CANT_PERFECTOS                      ; cuenta un perfecto

ANV_CHK_RAI:                                ; 8) verifica raiz exacta
    CALL TIENE_RAIZ_EXACTA                  ; BL = 1 si tiene raiz exacta
    CMP BL, 1                               ; tiene raiz exacta?
    JNE ANV_CHK_NAR                         ; no: revisa narcisista
    INC CANT_RAIZ                           ; cuenta uno con raiz exacta

ANV_CHK_NAR:                                ; 9) verifica si es narcisista
    CALL ES_NARCISISTA                      ; BL = 1 si narcisista
    CMP BL, 1                               ; es narcisista?
    JNE ANV_SIG                             ; no: siguiente elemento
    INC CANT_NARCISISTAS                    ; cuenta un narcisista

ANV_SIG:                                    ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    DEC CX                                  ; un elemento menos
    JZ ANV_PROMEDIO                         ; si CX = 0 termina el recorrido
    JMP ANV_CICLO                           ; salto largo al inicio del ciclo

ANV_PROMEDIO:                               ; calcula promedio = suma / N
    POP CX                                  ; recupera N original
    MOV AX, SUMA_LO                         ; parte baja del dividendo
    MOV DX, SUMA_HI                         ; parte alta del dividendo
    DIV CX                                  ; AX = cociente, DX = residuo
    MOV PROMEDIO, AX                        ; guarda el promedio entero
    MOV RESIDUO, DX                         ; guarda el residuo

ANV_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ANALIZAR_VECTOR ENDP                        ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: ANALIZAR_VECTOR ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PAR
;   Entrada : AX = numero (sin signo, 0..65535)
;   Salida  : BL = 1 si es par, BL = 0 si es impar  (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero es par si su bit 0 vale 0. TEST AX,1 hace un AND
;             sin guardar el resultado y solo actualiza ZF.
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
; PROCEDIMIENTO ES_IMPAR
;   Entrada : AX = numero.  Salida: BL = 1 si es impar, 0 si es par (BH=0)
;   Modifica: BX y banderas.
;------------------------------------------------------------------------------
ES_IMPAR PROC                               ; inicio del procedimiento
    MOV BX, 0                               ; supone "no es impar"
    TEST AX, 1                              ; aisla el bit 0
    JZ EIMP_FIN                             ; bit 0 = 0: es par, termina
    MOV BL, 1                               ; bit 0 = 1: es impar
EIMP_FIN:                                   ; salida comun
    RET                                     ; vuelve al llamador
ES_IMPAR ENDP                               ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PRIMO
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es primo, BL = 0 si no lo es (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI.
;   Metodo  : 0 y 1 no son primos. Para n >= 2 se prueban divisores d = 2,
;             3, 4... mientras d*d <= n. Si algun residuo es 0, no es primo.
;             Basta llegar a la raiz porque si n = a*b, uno de los dos
;             factores es <= raiz(n). MUL deja d*d en DX:AX; si DX <> 0 el
;             producto supera 65535 y por lo tanto supera a n.
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
;   Metodo  : prueba r = 0, 1, 2... calculando r*r. Si r*r = n hay raiz
;             exacta; si r*r > n (o pasa de 16 bits) ya no puede haberla.
;             Nota: 0 y 1 cuentan como cuadrados perfectos (0*0, 1*1).
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
; PROCEDIMIENTO ES_PERFECTO
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es perfecto, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero es perfecto si es igual a la suma de sus divisores
;             propios (los menores que el). Ej: 6 = 1+2+3, 28 = 1+2+4+7+14.
;             Se prueban d = 1 .. n/2 (ningun divisor propio supera n/2).
;             Si la suma desborda 16 bits (CF=1) el numero no es perfecto.
;             0 y 1 no son perfectos.
;------------------------------------------------------------------------------
ES_PERFECTO PROC                            ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    PUSH DI                                 ; guarda DI (suma de divisores)
    MOV BX, 0                               ; supone "no es perfecto"
    CMP AX, 2                               ; n < 2 ?
    JB EPER_FIN                             ; 0 y 1 no son perfectos
    MOV SI, AX                              ; SI = n
    XOR DI, DI                              ; suma = 0
    MOV CX, 1                               ; primer divisor d = 1
EPER_CICLO:                                 ; recorre los candidatos
    MOV AX, SI                              ; AX = n
    SHR AX, 1                               ; AX = n / 2 (desplazar = /2)
    CMP CX, AX                              ; d > n/2 ?
    JA EPER_COMPARAR                        ; si: termino la busqueda
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; d divide a n?
    JNE EPER_SIGUIENTE                      ; no: prueba el siguiente
    ADD DI, CX                              ; suma += d
    JC EPER_FIN                             ; desborde: no puede ser perfecto
EPER_SIGUIENTE:                             ; avanza al siguiente divisor
    INC CX                                  ; d = d + 1
    JMP EPER_CICLO                          ; repite
EPER_COMPARAR:                              ; termino de sumar
    CMP DI, SI                              ; suma == n ?
    JNE EPER_FIN                            ; distinto: no es perfecto
    MOV BL, 1                               ; igual: es perfecto
EPER_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_PERFECTO ENDP                            ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_NARCISISTA
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es narcisista, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero de k cifras es narcisista si es igual a la suma de
;             cada cifra elevada a k. Ej: 153 = 1^3 + 5^3 + 3^3.
;             1) Cuenta las cifras (k) dividiendo por 10.
;             2) Vuelve a separar las cifras y suma cifra^k (potencia por
;                multiplicaciones sucesivas).
;             3) Compara la suma con el numero original.
;             Si una potencia o la suma pasan de 16 bits, no es narcisista.
;             En 16 bits los narcisistas son: 0..9, 153, 370, 371, 407,
;             1634, 8208, 9474 y 54748.
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
; PROCEDIMIENTO MOSTRAR_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad (>0)
;   Salida  : muestra los elementos separados por un espacio.
;   Requiere: macros IMPRIMIR_NUMERO e IMPRIMIR_ESPACIO.
;   Modifica: nada (conserva AX, CX, SI).
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
