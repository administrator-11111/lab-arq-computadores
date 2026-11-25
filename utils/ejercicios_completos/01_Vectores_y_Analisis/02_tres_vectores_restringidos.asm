;==============================================================================
; EJERCICIO    : Tres vectores con restricciones (primos, raiz exacta, impares)
; ARCHIVO      : 02_tres_vectores_restringidos.asm
; ENUNCIADO    : Generar tres vectores aleatorios de 10 elementos cada uno en
;                el rango 1..200: el primero debe contener unicamente numeros
;                primos, el segundo unicamente numeros con raiz cuadrada exacta
;                y el tercero unicamente numeros impares. Mostrar los tres
;                vectores resultantes en pantalla.
; SOLUCION     : 1) Se inicializa la semilla aleatoria una sola vez al inicio
;                   con INICIALIZAR_SEMILLA (INT 21h / AH=2Ch).
;                2) Para cada vector se llama a su procedimiento de llenado
;                   restringido (LLENAR_SOLO_PRIMOS, LLENAR_SOLO_RAIZ_EXACTA y
;                   LLENAR_SOLO_IMPARES), que emplean un ciclo WHILE: generan
;                   candidatos en [1, 200] y solo los almacenan cuando el
;                   clasificador correspondiente devuelve BL = 1.
;                3) Se muestran los tres vectores con MOSTRAR_VECTOR.
; REGISTROS    : SI = offset del vector actual; CX = cantidad (10); BX = minimo
;                (1); DX = maximo (200); DI = contador de validos dentro del
;                ciclo WHILE.
; VARIABLES    : SEMILLA (DW), VEC_PRIMOS (10 DW), VEC_RAIZ (10 DW),
;                VEC_IMPARES (10 DW), TAMANO (EQU 10), mensajes DB.
; UTILS RELACIONADOS:
;                - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                - utils/02_Vectores/vectores_restringidos.asm
; EJEMPLO DE ENTRADA/SALIDA (ejecucion con --time 08:05:59.99):
;                === EJERCICIO 2: TRES VECTORES RESTRINGIDOS ===
;                Vector 1 - Solo primos (1..200)     : 47 137 29 199 179 197 17 17 179 59
;                Vector 2 - Solo raiz exacta (1..200): 36 169 144 16 25 4 169 64 169 64
;                Vector 3 - Solo impares (1..200)    : 55 77 49 187 53 137 79 101 77 5
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
    SEMILLA     DW 0                        ; semilla compartida del LCG
    TAMANO      EQU 10                      ; 10 elementos por vector
    VEC_PRIMOS  DW TAMANO DUP(0)            ; vector 1: solo primos
    VEC_RAIZ    DW TAMANO DUP(0)            ; vector 2: solo raiz exacta
    VEC_IMPARES DW TAMANO DUP(0)            ; vector 3: solo impares

    MSG_TIT     DB '=== EJERCICIO 2: TRES VECTORES RESTRINGIDOS ===$' ; titulo
    MSG_PRI     DB 'Vector 1 - Solo primos (1..200)     : $' ; etiqueta 1
    MSG_RAI     DB 'Vector 2 - Solo raiz exacta (1..200): $' ; etiqueta 2
    MSG_IMP     DB 'Vector 3 - Solo impares (1..200)    : $' ; etiqueta 3
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    CALL INICIALIZAR_SEMILLA                ; semilla inicial desde el reloj

    ; 1) Llena el primer vector solo con primos en 1..200
    MOV SI, OFFSET VEC_PRIMOS               ; SI apunta a VEC_PRIMOS
    MOV CX, TAMANO                          ; CX = 10 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 200                             ; maximo = 200
    CALL LLENAR_SOLO_PRIMOS                 ; llena con primos

    ; 2) Llena el segundo vector solo con cuadrados perfectos en 1..200
    MOV SI, OFFSET VEC_RAIZ                 ; SI apunta a VEC_RAIZ
    MOV CX, TAMANO                          ; CX = 10 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 200                             ; maximo = 200
    CALL LLENAR_SOLO_RAIZ_EXACTA            ; llena con raiz exacta

    ; 3) Llena el tercer vector solo con impares en 1..200
    MOV SI, OFFSET VEC_IMPARES              ; SI apunta a VEC_IMPARES
    MOV CX, TAMANO                          ; CX = 10 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 200                             ; maximo = 200
    CALL LLENAR_SOLO_IMPARES                ; llena con impares

    ; Muestra los tres vectores
    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta primos
    MOV SI, OFFSET VEC_PRIMOS               ; SI apunta a VEC_PRIMOS
    MOV CX, TAMANO                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra VEC_PRIMOS
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_RAI                 ; etiqueta raiz exacta
    MOV SI, OFFSET VEC_RAIZ                 ; SI apunta a VEC_RAIZ
    MOV CX, TAMANO                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra VEC_RAIZ
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_IMP                 ; etiqueta impares
    MOV SI, OFFSET VEC_IMPARES              ; SI apunta a VEC_IMPARES
    MOV CX, TAMANO                          ; CX = 10
    CALL MOSTRAR_VECTOR                     ; muestra VEC_IMPARES
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_SOLO_PRIMOS
;   Entrada : SI = offset del vector (DW), CX = cantidad, BX = min, DX = max
;------------------------------------------------------------------------------
LLENAR_SOLO_PRIMOS PROC                     ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero)
    PUSH DI                                 ; guarda DI (validos)
    XOR DI, DI                              ; validos = 0
LSP_WHILE:                                  ; WHILE validos < cantidad
    CMP DI, CX                              ; se completaron todos?
    JAE LSP_FIN                             ; si: termina
    PUSH CX                                 ; guarda cantidad
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = candidato
    POP CX                                  ; recupera cantidad
    PUSH BX                                 ; guarda minimo (ES_PRIMO usa BX)
    CALL ES_PRIMO                           ; BL = 1 si es primo
    CMP BL, 1                               ; cumple?
    POP BX                                  ; restaura minimo (no altera flags)
    JNE LSP_WHILE                           ; no: descarta y repite
    MOV [SI], AX                            ; guarda primo
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    INC DI                                  ; cuenta un valido mas
    JMP LSP_WHILE                           ; vuelve al WHILE
LSP_FIN:                                    ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_SOLO_PRIMOS ENDP                     ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_SOLO_RAIZ_EXACTA
;   Entrada : SI = offset del vector (DW), CX = cantidad, BX = min, DX = max
;------------------------------------------------------------------------------
LLENAR_SOLO_RAIZ_EXACTA PROC                ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero)
    PUSH DI                                 ; guarda DI (validos)
    XOR DI, DI                              ; validos = 0
LSR_WHILE:                                  ; WHILE validos < cantidad
    CMP DI, CX                              ; se completaron todos?
    JAE LSR_FIN                             ; si: termina
    PUSH CX                                 ; guarda cantidad
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = candidato
    POP CX                                  ; recupera cantidad
    PUSH BX                                 ; guarda minimo
    CALL TIENE_RAIZ_EXACTA                  ; BL = 1 si tiene raiz exacta
    CMP BL, 1                               ; cumple?
    POP BX                                  ; restaura minimo (no altera flags)
    JNE LSR_WHILE                           ; no: descarta y repite
    MOV [SI], AX                            ; guarda cuadrado perfecto
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    INC DI                                  ; cuenta un valido mas
    JMP LSR_WHILE                           ; vuelve al WHILE
LSR_FIN:                                    ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_SOLO_RAIZ_EXACTA ENDP                ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_SOLO_IMPARES
;   Entrada : SI = offset del vector (DW), CX = cantidad, BX = min, DX = max
;------------------------------------------------------------------------------
LLENAR_SOLO_IMPARES PROC                    ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero)
    PUSH DI                                 ; guarda DI (validos)
    XOR DI, DI                              ; validos = 0
LSI_WHILE:                                  ; WHILE validos < cantidad
    CMP DI, CX                              ; se completaron todos?
    JAE LSI_FIN                             ; si: termina
    PUSH CX                                 ; guarda cantidad
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = candidato
    POP CX                                  ; recupera cantidad
    PUSH BX                                 ; guarda minimo
    CALL ES_IMPAR                           ; BL = 1 si es impar
    CMP BL, 1                               ; cumple?
    POP BX                                  ; restaura minimo (no altera flags)
    JNE LSI_WHILE                           ; no: descarta y repite
    MOV [SI], AX                            ; guarda impar
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    INC DI                                  ; cuenta un valido mas
    JMP LSI_WHILE                           ; vuelve al WHILE
LSI_FIN:                                    ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_SOLO_IMPARES ENDP                    ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_IMPAR
;   Entrada : AX = numero.  Salida: BL = 1 si es impar, 0 si es par (BH=0)
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
;   Entrada : AX = numero (0..65535).  Salida: BL = 1 si primo, 0 si no (BH=0)
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
;   Entrada : AX = numero (0..65535).  Salida: BL = 1 si cuadrado perfecto
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
