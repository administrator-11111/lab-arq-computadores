;==============================================================================
; ARCHIVO      : aleatorios_restringidos.asm
; TIPO         : ALGORITMO (+ programa de demostracion)
; DESCRIPCION  : Genera N numeros aleatorios que cumplen una restriccion:
;                solo primos, solo con raiz cuadrada exacta y solo impares.
; FUNCIONAMIENTO:
;   Tecnica 1 (generar y descartar / rechazo):
;     Se genera un candidato en [BX, CX] y se verifica la condicion con un
;     procedimiento clasificador (ES_PRIMO, TIENE_RAIZ_EXACTA o ES_IMPAR).
;     Si BL = 0 se descarta y se repite hasta obtener BL = 1.
;     Sirve para cualquier propiedad, siempre que exista al menos un numero
;     valido en [BX, CX] (si no existe ninguno, el ciclo seria infinito).
;   Tecnica 2 (construccion directa para impares: 2*k + 1):
;     En lugar de descartar la mitad de los intentos, para generar un impar
;     en [1, 99] basta generar k en [0, 49] y calcular 2*k + 1 (SHL AX, 1
;     seguido de INC AX). Nunca descarta y siempre da un impar en [1, 99].
; REGISTROS    :
;   ALEATORIO_PRIMO        -> Entrada: BX=min, CX=max. Salida: AX=primo.
;   ALEATORIO_RAIZ_EXACTA  -> Entrada: BX=min, CX=max. Salida: AX=cuadrado.
;   ALEATORIO_IMPAR_RECHAZO-> Entrada: BX=min, CX=max. Salida: AX=impar.
;   ALEATORIO_IMPAR_DIRECTO-> Entrada: BX=k_min, CX=k_max. Salida: AX=2*k+1.
;   Todos conservan BX, CX y DX.
; VARIABLES    : SEMILLA DW 0 en DATOS.
; DEPENDENCIAS : Macros de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y procedimientos INICIALIZAR_SEMILLA, GENERAR_ALEATORIO,
;                ES_PRIMO, TIENE_RAIZ_EXACTA, ES_IMPAR.
; COMO INTEGRAR: Copiar las macros, declarar SEMILLA DW 0 en DATOS, y copiar
;                el bloque reutilizable junto con los procedimientos canonicos
;                que utilices dentro de CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      :
;   === ALEATORIOS CON RESTRICCION (N = 6) ===
;   Solo primos [1..100] (rechazo)       : 17 5 73 29 11 43
;   Solo raiz exacta [1..100] (rechazo)  : 64 9 36 100 16 4
;   Solo impares [1..99] (rechazo)       : 81 35 19 67 93 7
;   Solo impares [1..99] (directo 2*k+1) : 55 21 89 13 47 75
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
    SEMILLA    DW 0                         ; semilla del generador LCG
    CANTIDAD_N DW 6                         ; cantidad a generar por categoria
    MSG_TIT    DB '=== ALEATORIOS CON RESTRICCION (N = 6) ===$' ; titulo
    MSG_PRI    DB 'Solo primos [1..100] (rechazo)       : $'  ; etiqueta 1
    MSG_RAI    DB 'Solo raiz exacta [1..100] (rechazo)  : $'  ; etiqueta 2
    MSG_IMP1   DB 'Solo impares [1..99] (rechazo)       : $'  ; etiqueta 3
    MSG_IMP2   DB 'Solo impares [1..99] (directo 2*k+1) : $'  ; etiqueta 4
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    CALL INICIALIZAR_SEMILLA                ; inicializa SEMILLA con la hora

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    ; --- 1) Solo primos en [1, 100] por rechazo ---
    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta primos
    MOV CX, CANTIDAD_N                      ; CX = N
DEMO_PRI:                                   ; ciclo de N primos
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; minimo = 1
    MOV CX, 100                             ; maximo = 100
    CALL ALEATORIO_PRIMO                    ; AX = primo aleatorio en [1, 100]
    IMPRIMIR_NUMERO AX                      ; muestra el primo
    IMPRIMIR_ESPACIO                        ; separador
    POP CX                                  ; recupera contador
    LOOP DEMO_PRI                           ; repite N veces
    SALTO_LINEA                             ; nueva linea

    ; --- 2) Solo cuadrados perfectos en [1, 100] por rechazo ---
    IMPRIMIR_CADENA MSG_RAI                 ; etiqueta raiz exacta
    MOV CX, CANTIDAD_N                      ; CX = N
DEMO_RAI:                                   ; ciclo de N cuadrados perfectos
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; minimo = 1
    MOV CX, 100                             ; maximo = 100
    CALL ALEATORIO_RAIZ_EXACTA              ; AX = cuadrado perfecto en [1,100]
    IMPRIMIR_NUMERO AX                      ; muestra el numero
    IMPRIMIR_ESPACIO                        ; separador
    POP CX                                  ; recupera contador
    LOOP DEMO_RAI                           ; repite N veces
    SALTO_LINEA                             ; nueva linea

    ; --- 3) Solo impares en [1, 99] por rechazo ---
    IMPRIMIR_CADENA MSG_IMP1                ; etiqueta impares por rechazo
    MOV CX, CANTIDAD_N                      ; CX = N
DEMO_IMP1:                                  ; ciclo de N impares (rechazo)
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; minimo = 1
    MOV CX, 99                              ; maximo = 99
    CALL ALEATORIO_IMPAR_RECHAZO            ; AX = impar en [1, 99]
    IMPRIMIR_NUMERO AX                      ; muestra el impar
    IMPRIMIR_ESPACIO                        ; separador
    POP CX                                  ; recupera contador
    LOOP DEMO_IMP1                          ; repite N veces
    SALTO_LINEA                             ; nueva linea

    ; --- 4) Solo impares en [1, 99] por formula directa 2*k + 1 ---
    IMPRIMIR_CADENA MSG_IMP2                ; etiqueta impares directo
    MOV CX, CANTIDAD_N                      ; CX = N
DEMO_IMP2:                                  ; ciclo de N impares (directo)
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 0                               ; k_min = 0 -> 2*0+1 = 1
    MOV CX, 49                              ; k_max = 49 -> 2*49+1 = 99
    CALL ALEATORIO_IMPAR_DIRECTO            ; AX = 2*k + 1 (siempre impar)
    IMPRIMIR_NUMERO AX                      ; muestra el impar
    IMPRIMIR_ESPACIO                        ; separador
    POP CX                                  ; recupera contador
    LOOP DEMO_IMP2                          ; repite N veces
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: ALEATORIOS_RESTRINGIDOS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO ALEATORIO_PRIMO
;   Entrada : BX = minimo, CX = maximo (debe existir al menos un primo).
;   Salida  : AX = numero primo aleatorio en [BX, CX]. Conserva BX, CX, DX.
;------------------------------------------------------------------------------
ALEATORIO_PRIMO PROC                        ; inicio del procedimiento
    PUSH BX                                 ; guarda BX (ES_PRIMO modifica BX)
APRI_INTENTO:                               ; genera y prueba hasta cumplir
    POP BX                                  ; restaura BX = minimo
    PUSH BX                                 ; vuelve a guardarlo en pila
    CALL GENERAR_ALEATORIO                  ; AX = candidato en [BX, CX]
    CALL ES_PRIMO                           ; BL = 1 si AX es primo
    CMP BL, 1                               ; cumplio la restriccion?
    JNE APRI_INTENTO                        ; no: descarta y genera otro
    POP BX                                  ; restaura BX original
    RET                                     ; vuelve con AX = primo
ALEATORIO_PRIMO ENDP                        ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ALEATORIO_RAIZ_EXACTA
;   Entrada : BX = minimo, CX = maximo (debe existir al menos un cuadrado).
;   Salida  : AX = cuadrado perfecto aleatorio en [BX, CX]. Conserva BX,CX,DX.
;------------------------------------------------------------------------------
ALEATORIO_RAIZ_EXACTA PROC                  ; inicio del procedimiento
    PUSH BX                                 ; guarda BX (clasificador usa BX)
ARAI_INTENTO:                               ; genera y prueba hasta cumplir
    POP BX                                  ; restaura BX = minimo
    PUSH BX                                 ; lo mantiene respaldado
    CALL GENERAR_ALEATORIO                  ; AX = candidato en [BX, CX]
    CALL TIENE_RAIZ_EXACTA                  ; BL = 1 si AX tiene raiz exacta
    CMP BL, 1                               ; cumplio la restriccion?
    JNE ARAI_INTENTO                        ; no: descarta y reintenta
    POP BX                                  ; restaura BX original
    RET                                     ; vuelve con AX = cuadrado
ALEATORIO_RAIZ_EXACTA ENDP                  ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ALEATORIO_IMPAR_RECHAZO
;   Entrada : BX = minimo, CX = maximo (debe existir al menos un impar).
;   Salida  : AX = numero impar aleatorio en [BX, CX]. Conserva BX, CX, DX.
;------------------------------------------------------------------------------
ALEATORIO_IMPAR_RECHAZO PROC                ; inicio del procedimiento
    PUSH BX                                 ; guarda BX (ES_IMPAR usa BX)
AIMP_INTENTO:                               ; genera y prueba hasta cumplir
    POP BX                                  ; restaura BX = minimo
    PUSH BX                                 ; lo mantiene respaldado
    CALL GENERAR_ALEATORIO                  ; AX = candidato en [BX, CX]
    CALL ES_IMPAR                           ; BL = 1 si AX es impar
    CMP BL, 1                               ; es impar?
    JNE AIMP_INTENTO                        ; no: descarta y genera otro
    POP BX                                  ; restaura BX original
    RET                                     ; vuelve con AX = impar
ALEATORIO_IMPAR_RECHAZO ENDP                ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ALEATORIO_IMPAR_DIRECTO
;   Entrada : BX = k_min, CX = k_max (con 2*k_max + 1 <= 65535).
;   Salida  : AX = 2*k + 1 (impar directo, sin descartes). Conserva BX,CX,DX.
;------------------------------------------------------------------------------
ALEATORIO_IMPAR_DIRECTO PROC                ; inicio del procedimiento
    CALL GENERAR_ALEATORIO                  ; AX = k en [BX, CX]
    SHL AX, 1                               ; AX = 2 * k (siempre par)
    INC AX                                  ; AX = 2 * k + 1 (siempre impar)
    RET                                     ; vuelve con AX = impar
ALEATORIO_IMPAR_DIRECTO ENDP                ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: ALEATORIOS_RESTRINGIDOS ======

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
; PROCEDIMIENTO ES_IMPAR (canonico)
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

;------------------------------------------------------------------------------
; PROCEDIMIENTO TIENE_RAIZ_EXACTA (canonico)
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

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del programa
