;==============================================================================
; ARCHIVO      : contar_clasificados.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Implementa CONTAR_PRIMOS, CONTAR_PERFECTOS, CONTAR_RAIZ_EXACTA
;                y CONTAR_NARCISISTAS para contar cuantos elementos de un
;                vector de palabras (DW) cumplen cada propiedad matematica,
;                usando los procedimientos canonicos de clasificacion.
; FUNCIONAMIENTO:
;                Cada procedimiento sigue el mismo patron: recibe SI = offset
;                del vector y CX = cantidad. Usa DX como contador (inicia en 0).
;                Para cada elemento carga AX = [SI], llama al clasificador
;                correspondiente (que conserva AX, CX, DX, SI y devuelve BL=1
;                si cumple o BL=0 si no) e incrementa DX cuando BL=1. Al
;                terminar, devuelve el total en AX.
; REGISTROS    : CONTAR_PRIMOS / CONTAR_PERFECTOS / CONTAR_RAIZ_EXACTA /
;                CONTAR_NARCISISTAS:
;                  Entrada : SI = offset del vector (DW), CX = cantidad
;                  Salida  : AX = cantidad de elementos que cumplen la propiedad
;                  Modifica: AX y banderas (conserva BX, CX, DX, SI)
; VARIABLES    : Un vector DW en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimientos ES_PRIMO, ES_PERFECTO, TIENE_RAIZ_EXACTA,
;                ES_NARCISISTA y MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Copiar los procedimientos de conteo y los clasificadores
;                   que necesite en CODIGO despues de FIN_PROGRAMA.
;                3) Llamar con SI = OFFSET VECTOR y CX = N; resultado en AX.
; EJEMPLO      : Salida esperada:
;                  === CONTAR CLASIFICADOS EN UN VECTOR ===
;                  Vector     : 0 1 2 4 6 9 13 28 153 370 496 16
;                  Primos     : 2
;                  Perfectos  : 3
;                  Raiz exacta: 5
;                  Narcisistas: 8
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
    ; Primos: 2, 13 (2)
    ; Perfectos: 6, 28, 496 (3)
    ; Raiz exacta: 0, 1, 4, 9, 16 (5)
    ; Narcisistas: 0, 1, 2, 4, 6, 9, 153, 370 (8)
    VECTOR     DW 0, 1, 2, 4, 6, 9, 13, 28, 153, 370, 496, 16 ; 12 elementos
    TAMANO     EQU 12                       ; cantidad de elementos

    MSG_TIT    DB '=== CONTAR CLASIFICADOS EN UN VECTOR ===$' ; titulo
    MSG_VEC    DB 'Vector     : $'          ; etiqueta vector
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
    MOV CX, TAMANO                          ; CX = 12 elementos
    CALL MOSTRAR_VECTOR                     ; muestra el vector
    SALTO_LINEA                             ; nueva linea

    CALL CONTAR_PRIMOS                      ; AX = cantidad de primos (2)
    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta primos
    IMPRIMIR_NUMERO AX                      ; muestra 2
    SALTO_LINEA                             ; nueva linea

    CALL CONTAR_PERFECTOS                   ; AX = cantidad de perfectos (3)
    IMPRIMIR_CADENA MSG_PER                 ; etiqueta perfectos
    IMPRIMIR_NUMERO AX                      ; muestra 3
    SALTO_LINEA                             ; nueva linea

    CALL CONTAR_RAIZ_EXACTA                 ; AX = cantidad con raiz exacta (5)
    IMPRIMIR_CADENA MSG_RAI                 ; etiqueta raiz exacta
    IMPRIMIR_NUMERO AX                      ; muestra 5
    SALTO_LINEA                             ; nueva linea

    CALL CONTAR_NARCISISTAS                 ; AX = cantidad de narcisistas (8)
    IMPRIMIR_CADENA MSG_NAR                 ; etiqueta narcisistas
    IMPRIMIR_NUMERO AX                      ; muestra 8
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: CONTAR_CLASIFICADOS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_PRIMOS
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = cantidad de numeros primos en el vector.
;   Requiere: ES_PRIMO.
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
CONTAR_PRIMOS PROC                          ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX (acumulador)
    PUSH SI                                 ; guarda SI (puntero)
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CPRI_FIN                             ; si: devuelve 0
CPRI_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_PRIMO                           ; BL = 1 si es primo
    CMP BL, 1                               ; cumple?
    JNE CPRI_SIG                            ; no: salta
    INC DX                                  ; si: cuenta un primo mas
CPRI_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CPRI_CICLO                         ; repite CX veces
CPRI_FIN:                                   ; salida comun
    MOV AX, DX                              ; resultado en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_PRIMOS ENDP                          ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_PERFECTOS
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = cantidad de numeros perfectos en el vector.
;   Requiere: ES_PERFECTO.
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
CONTAR_PERFECTOS PROC                       ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX (acumulador)
    PUSH SI                                 ; guarda SI (puntero)
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CPER_FIN                             ; si: devuelve 0
CPER_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_PERFECTO                        ; BL = 1 si es perfecto
    CMP BL, 1                               ; cumple?
    JNE CPER_SIG                            ; no: salta
    INC DX                                  ; si: cuenta un perfecto mas
CPER_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CPER_CICLO                         ; repite CX veces
CPER_FIN:                                   ; salida comun
    MOV AX, DX                              ; resultado en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_PERFECTOS ENDP                       ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_RAIZ_EXACTA
;   Entrada : SI = offset del vector (DW), CX = cantidad
;   Salida  : AX = cantidad de cuadrados perfectos en el vector.
;   Requiere: TIENE_RAIZ_EXACTA.
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
CONTAR_RAIZ_EXACTA PROC                     ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX (acumulador)
    PUSH SI                                 ; guarda SI (puntero)
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CRAI_FIN                             ; si: devuelve 0
CRAI_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL TIENE_RAIZ_EXACTA                  ; BL = 1 si tiene raiz exacta
    CMP BL, 1                               ; cumple?
    JNE CRAI_SIG                            ; no: salta
    INC DX                                  ; si: cuenta uno mas
CRAI_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CRAI_CICLO                         ; repite CX veces
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
;   Salida  : AX = cantidad de numeros narcisistas en el vector.
;   Requiere: ES_NARCISISTA.
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
CONTAR_NARCISISTAS PROC                     ; inicio del procedimiento
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DX                                 ; guarda DX (acumulador)
    PUSH SI                                 ; guarda SI (puntero)
    XOR DX, DX                              ; contador = 0
    CMP CX, 0                               ; vector vacio?
    JE CNAR_FIN                             ; si: devuelve 0
CNAR_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_NARCISISTA                      ; BL = 1 si es narcisista
    CMP BL, 1                               ; cumple?
    JNE CNAR_SIG                            ; no: salta
    INC DX                                  ; si: cuenta un narcisista mas
CNAR_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CNAR_CICLO                         ; repite CX veces
CNAR_FIN:                                   ; salida comun
    MOV AX, DX                              ; resultado en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_NARCISISTAS ENDP                     ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: CONTAR_CLASIFICADOS ======

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
