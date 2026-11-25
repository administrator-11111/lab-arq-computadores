;==============================================================================
; ARCHIVO      : vectores_restringidos.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Procedimientos que llenan un vector de palabras (DW) con
;                numeros aleatorios que cumplen una restriccion especifica:
;                LLENAR_SOLO_PRIMOS, LLENAR_SOLO_RAIZ_EXACTA y
;                LLENAR_SOLO_IMPARES.
; FUNCIONAMIENTO:
;                Cada procedimiento usa un ciclo WHILE: mantiene un contador
;                DI de elementos validos guardados (empieza en 0). Mientras
;                DI < CX (cantidad pedida), genera un aleatorio en [BX, DX] y
;                lo valida con ES_PRIMO, TIENE_RAIZ_EXACTA o ES_IMPAR.
;                Solo si BL = 1 guarda AX en [SI], avanza SI en 2 bytes e
;                incrementa DI. Si no cumple, descarta el candidato y repite.
;                Detalle 8086: los clasificadores modifican BX (devuelven el
;                resultado en BL), por lo que se guarda BX con PUSH BX antes
;                de llamarlos y se recupera con POP BX despues de CMP BL, 1
;                (POP no altera las banderas de comparacion).
;                IMPORTANTE: el rango [BX, DX] debe contener al menos un valor
;                que cumpla la restriccion; de lo contrario el WHILE no acaba.
; REGISTROS    : LLENAR_SOLO_PRIMOS / LLENAR_SOLO_RAIZ_EXACTA /
;                LLENAR_SOLO_IMPARES:
;                  Entrada : SI = offset del vector (DW), CX = cantidad,
;                            BX = minimo, DX = maximo
;                  Salida  : vector lleno con CX elementos que cumplen la regla
;                  Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES    : SEMILLA DW 0 y los vectores DW en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimientos ES_PRIMO, TIENE_RAIZ_EXACTA, ES_IMPAR,
;                INICIALIZAR_SEMILLA, GENERAR_ALEATORIO, MOSTRAR_VECTOR
;                (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar macros arriba de PILA.
;                2) Declarar SEMILLA DW 0 y vectores DW en DATOS.
;                3) Copiar el bloque reutilizable y los procedimientos de
;                   clasificacion/aleatorios en CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      : Salida (varia segun la hora del sistema):
;                  === VECTORES CON RESTRICCION (WHILE) ===
;                  Solo primos (1..200)     : 109 19 67 173 2 151 43 89
;                  Solo raiz exacta (1..200): 64 144 9 16 121 4 196 49
;                  Solo impares (1..200)    : 135 27 91 183 7 119 55 161
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
    TAMANO     EQU 8                        ; 8 elementos por vector (16 bytes)
    VEC_PRIMOS DW TAMANO DUP(0)             ; vector solo con numeros primos
    VEC_RAIZ   DW TAMANO DUP(0)             ; vector solo con raiz exacta
    VEC_IMPAR  DW TAMANO DUP(0)             ; vector solo con impares

    MSG_TIT    DB '=== VECTORES CON RESTRICCION (WHILE) ===$' ; titulo
    MSG_PRI    DB 'Solo primos (1..200)     : $' ; etiqueta 1
    MSG_RAI    DB 'Solo raiz exacta (1..200): $' ; etiqueta 2
    MSG_IMP    DB 'Solo impares (1..200)    : $' ; etiqueta 3
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    CALL INICIALIZAR_SEMILLA                ; inicializa la semilla una vez

    ; 1) Vector solo de primos en 1..200
    MOV SI, OFFSET VEC_PRIMOS               ; SI apunta a VEC_PRIMOS
    MOV CX, TAMANO                          ; CX = 8 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 200                             ; maximo = 200
    CALL LLENAR_SOLO_PRIMOS                 ; llena solo con primos

    ; 2) Vector solo con raiz exacta en 1..200
    MOV SI, OFFSET VEC_RAIZ                 ; SI apunta a VEC_RAIZ
    MOV CX, TAMANO                          ; CX = 8 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 200                             ; maximo = 200
    CALL LLENAR_SOLO_RAIZ_EXACTA            ; llena solo con cuadrados perfectos

    ; 3) Vector solo de impares en 1..200
    MOV SI, OFFSET VEC_IMPAR                ; SI apunta a VEC_IMPAR
    MOV CX, TAMANO                          ; CX = 8 elementos
    MOV BX, 1                               ; minimo = 1
    MOV DX, 200                             ; maximo = 200
    CALL LLENAR_SOLO_IMPARES                ; llena solo con impares

    ; Muestra los tres vectores
    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta primos
    MOV SI, OFFSET VEC_PRIMOS               ; SI apunta a VEC_PRIMOS
    MOV CX, TAMANO                          ; CX = 8
    CALL MOSTRAR_VECTOR                     ; muestra primos
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_RAI                 ; etiqueta raiz exacta
    MOV SI, OFFSET VEC_RAIZ                 ; SI apunta a VEC_RAIZ
    MOV CX, TAMANO                          ; CX = 8
    CALL MOSTRAR_VECTOR                     ; muestra cuadrados perfectos
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_IMP                 ; etiqueta impares
    MOV SI, OFFSET VEC_IMPAR                ; SI apunta a VEC_IMPAR
    MOV CX, TAMANO                          ; CX = 8
    CALL MOSTRAR_VECTOR                     ; muestra impares
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: VECTORES_RESTRINGIDOS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_SOLO_PRIMOS
;   Entrada : SI = offset del vector (DW), CX = cantidad, BX = min, DX = max
;   Salida  : llena el vector con CX primos aleatorios en [BX, DX].
;   Requiere: GENERAR_ALEATORIO, ES_PRIMO y variable SEMILLA DW en DATOS.
;   Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI, DI).
;------------------------------------------------------------------------------
LLENAR_SOLO_PRIMOS PROC                     ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad pedida)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero al vector)
    PUSH DI                                 ; guarda DI (elementos validos)
    XOR DI, DI                              ; validos = 0
LSP_WHILE:                                  ; WHILE validos < cantidad
    CMP DI, CX                              ; ya se completaron los CX?
    JAE LSP_FIN                             ; si: termina
    PUSH CX                                 ; guarda cantidad pedida
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = candidato en [BX, DX]
    POP CX                                  ; recupera cantidad pedida
    PUSH BX                                 ; guarda minimo (ES_PRIMO usa BX)
    CALL ES_PRIMO                           ; BL = 1 si AX es primo
    CMP BL, 1                               ; cumple la restriccion?
    POP BX                                  ; restaura minimo (no altera flags)
    JNE LSP_WHILE                           ; no es primo: descarta y repite
    MOV [SI], AX                            ; guarda el primo en el vector
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    INC DI                                  ; un elemento valido mas
    JMP LSP_WHILE                           ; vuelve a evaluar el WHILE
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
;   Salida  : llena el vector con CX cuadrados perfectos en [BX, DX].
;   Requiere: GENERAR_ALEATORIO, TIENE_RAIZ_EXACTA y SEMILLA DW en DATOS.
;   Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI, DI).
;------------------------------------------------------------------------------
LLENAR_SOLO_RAIZ_EXACTA PROC                ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad pedida)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero al vector)
    PUSH DI                                 ; guarda DI (elementos validos)
    XOR DI, DI                              ; validos = 0
LSR_WHILE:                                  ; WHILE validos < cantidad
    CMP DI, CX                              ; ya se completaron los CX?
    JAE LSR_FIN                             ; si: termina
    PUSH CX                                 ; guarda cantidad pedida
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = candidato en [BX, DX]
    POP CX                                  ; recupera cantidad pedida
    PUSH BX                                 ; guarda minimo (raiz usa BX)
    CALL TIENE_RAIZ_EXACTA                  ; BL = 1 si AX tiene raiz exacta
    CMP BL, 1                               ; cumple la restriccion?
    POP BX                                  ; restaura minimo (no altera flags)
    JNE LSR_WHILE                           ; no cumple: descarta y repite
    MOV [SI], AX                            ; guarda el valor en el vector
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    INC DI                                  ; un elemento valido mas
    JMP LSR_WHILE                           ; vuelve a evaluar el WHILE
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
;   Salida  : llena el vector con CX numeros impares en [BX, DX].
;   Requiere: GENERAR_ALEATORIO, ES_IMPAR y variable SEMILLA DW en DATOS.
;   Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI, DI).
;------------------------------------------------------------------------------
LLENAR_SOLO_IMPARES PROC                    ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad pedida)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero al vector)
    PUSH DI                                 ; guarda DI (elementos validos)
    XOR DI, DI                              ; validos = 0
LSI_WHILE:                                  ; WHILE validos < cantidad
    CMP DI, CX                              ; ya se completaron los CX?
    JAE LSI_FIN                             ; si: termina
    PUSH CX                                 ; guarda cantidad pedida
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = candidato en [BX, DX]
    POP CX                                  ; recupera cantidad pedida
    PUSH BX                                 ; guarda minimo (ES_IMPAR usa BX)
    CALL ES_IMPAR                           ; BL = 1 si AX es impar
    CMP BL, 1                               ; cumple la restriccion?
    POP BX                                  ; restaura minimo (no altera flags)
    JNE LSI_WHILE                           ; es par: descarta y repite
    MOV [SI], AX                            ; guarda el impar en el vector
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    INC DI                                  ; un elemento valido mas
    JMP LSI_WHILE                           ; vuelve a evaluar el WHILE
LSI_FIN:                                    ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_SOLO_IMPARES ENDP                    ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: VECTORES_RESTRINGIDOS ======

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
; PROCEDIMIENTO INICIALIZAR_SEMILLA
;   Requiere: variable  SEMILLA DW 0  en el segmento DATOS.
;   Que hace: toma la hora del sistema (INT 21h, AH=2Ch) y la usa como
;             semilla para que cada ejecucion genere numeros distintos.
;             CH = hora, CL = minutos, DH = segundos, DL = centesimas.
;   Modifica: solo la variable SEMILLA (conserva AX, CX, DX).
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
;   Entrada : BX = valor minimo, CX = valor maximo  (BX <= CX, y CX-BX < 65535)
;   Salida  : AX = numero pseudoaleatorio en el intervalo [BX, CX]
;   Requiere: variable SEMILLA DW en DATOS (inicializada con
;             INICIALIZAR_SEMILLA o con un valor fijo para pruebas).
;   Modifica: AX, SEMILLA y banderas. Conserva BX, CX, DX.
;   Metodo  : generador congruencial lineal (LCG):
;               SEMILLA = (SEMILLA * 25173 + 13849) mod 65536
;             El "mod 65536" es automatico: solo se conserva AX (16 bits).
;             Se intercambian AH y AL porque los bits altos del LCG son
;             mas aleatorios que los bajos (el bit 0 solo alterna 0,1,0,1).
;             Luego: AX mod (max - min + 1) + min  -> valor en [min, max].
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
