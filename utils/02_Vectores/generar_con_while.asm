;==============================================================================
; ARCHIVO      : generar_con_while.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Muestra como implementar ciclos tipo WHILE en 8086 (evaluando
;                la condicion AL INICIO con CMP/Jcc y volviendo con JMP) en
;                contraste con LOOP (que decrementa CX al final). Incluye dos
;                procedimientos: LLENAR_SECUENCIA_WHILE y LLENAR_ALEATORIO_WHILE.
; FUNCIONAMIENTO:
;                Un ciclo WHILE evalua la condicion ANTES de entrar al cuerpo:
;                  ETIQUETA_WHILE:
;                      CMP indice, limite   ; evalua i < N
;                      JAE ETIQUETA_FIN     ; si i >= N sale sin ejecutar
;                      ... cuerpo ...       ; accede a [SI], avanza ADD SI, 2
;                      INC indice           ; i = i + 1
;                      JMP ETIQUETA_WHILE   ; regresa a evaluar la condicion
;                  ETIQUETA_FIN:
;                Diferencia frente a LOOP:
;                1) Si N = 0, WHILE ejecuta 0 veces automaticamente; LOOP sin
;                   comprobacion previa decrementaria 0 a 65535 y repetiria
;                   65536 veces.
;                2) WHILE permite condiciones arbitrarias (ej. esperar a que
;                   un aleatorio cumpla una propiedad) y no depende de CX.
; REGISTROS    : LLENAR_SECUENCIA_WHILE:
;                  Entrada : SI = offset del vector (DW), CX = cantidad N
;                  Salida  : llena con multiplos de 5 (5, 10, 15, ...)
;                  Modifica: nada (conserva AX, BX, CX, DX, SI)
;                LLENAR_ALEATORIO_WHILE:
;                  Entrada : SI = offset del vector (DW), CX = cantidad N,
;                            BX = minimo, DX = maximo
;                  Salida  : llena con N aleatorios en [BX, DX] usando WHILE
;                  Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI, DI)
; VARIABLES    : SEMILLA DW 0 en DATOS (para LLENAR_ALEATORIO_WHILE).
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimientos INICIALIZAR_SEMILLA, GENERAR_ALEATORIO y
;                MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Declarar SEMILLA DW 0 y vectores DW en DATOS.
;                3) Copiar el bloque reutilizable y los procedimientos de
;                   aleatorios en CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      : Salida esperada (la segunda linea varia segun la hora):
;                  === GENERAR VALORES CON CICLO WHILE ===
;                  Secuencia (multiplos de 5, WHILE i < 8):
;                  5 10 15 20 25 30 35 40
;                  Aleatorios (1..50, WHILE i < 8):
;                  23 7 49 12 31 44 18 5
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
    TAMANO     EQU 8                        ; cantidad de elementos
    VEC_SEQ    DW TAMANO DUP(0)             ; vector para la secuencia
    VEC_ALE    DW TAMANO DUP(0)             ; vector para los aleatorios

    MSG_TIT    DB '=== GENERAR VALORES CON CICLO WHILE ===$' ; titulo
    MSG_SEQ    DB 'Secuencia (multiplos de 5, WHILE i < 8):$' ; etiqueta 1
    MSG_ALE    DB 'Aleatorios (1..50, WHILE i < 8):$' ; etiqueta 2
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    ; 1) Llena VEC_SEQ con multiplos de 5 usando WHILE (i < 8)
    MOV SI, OFFSET VEC_SEQ                  ; SI apunta a VEC_SEQ
    MOV CX, TAMANO                          ; CX = limite N = 8
    CALL LLENAR_SECUENCIA_WHILE             ; ejecuta el ciclo WHILE

    IMPRIMIR_CADENA MSG_SEQ                 ; etiqueta
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VEC_SEQ                  ; SI apunta a VEC_SEQ
    MOV CX, TAMANO                          ; CX = 8
    CALL MOSTRAR_VECTOR                     ; muestra 5 10 15 20 25 30 35 40
    SALTO_LINEA                             ; nueva linea

    ; 2) Llena VEC_ALE con aleatorios en 1..50 usando WHILE (i < 8)
    CALL INICIALIZAR_SEMILLA                ; inicializa la semilla
    MOV SI, OFFSET VEC_ALE                  ; SI apunta a VEC_ALE
    MOV CX, TAMANO                          ; CX = limite N = 8
    MOV BX, 1                               ; minimo = 1
    MOV DX, 50                              ; maximo = 50
    CALL LLENAR_ALEATORIO_WHILE             ; ejecuta el ciclo WHILE

    IMPRIMIR_CADENA MSG_ALE                 ; etiqueta
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VEC_ALE                  ; SI apunta a VEC_ALE
    MOV CX, TAMANO                          ; CX = 8
    CALL MOSTRAR_VECTOR                     ; muestra los 8 aleatorios
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LLENAR_CON_WHILE ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_SECUENCIA_WHILE
;   Entrada : SI = offset del vector (DW), CX = cantidad N
;   Salida  : llena el vector con 5, 10, 15, ... mientras indice < N.
;   Modifica: nada (conserva AX, BX, CX, SI).
;------------------------------------------------------------------------------
LLENAR_SECUENCIA_WHILE PROC                 ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (valor actual)
    PUSH BX                                 ; guarda BX (indice logico i)
    PUSH CX                                 ; guarda CX (limite N)
    PUSH SI                                 ; guarda SI (puntero al vector)
    XOR BX, BX                              ; i = 0
    MOV AX, 5                               ; primer valor de la secuencia
LSW_WHILE:                                  ; inicio del WHILE (evalua primero)
    CMP BX, CX                              ; condicion: i < N ?
    JAE LSW_FIN                             ; si i >= N sale del ciclo
    MOV [SI], AX                            ; guarda el valor en VECTOR[i]
    ADD AX, 5                               ; siguiente multiplo de 5
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    INC BX                                  ; i = i + 1
    JMP LSW_WHILE                           ; vuelve a evaluar la condicion
LSW_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_SECUENCIA_WHILE ENDP                 ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_ALEATORIO_WHILE
;   Entrada : SI = offset del vector (DW), CX = cantidad N,
;             BX = minimo, DX = maximo
;   Salida  : llena el vector con N aleatorios en [BX, DX] usando WHILE.
;   Requiere: GENERAR_ALEATORIO y variable SEMILLA DW en DATOS.
;   Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI, DI).
;------------------------------------------------------------------------------
LLENAR_ALEATORIO_WHILE PROC                 ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (aleatorio)
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (limite N)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero al vector)
    PUSH DI                                 ; guarda DI (indice logico i)
    XOR DI, DI                              ; i = 0
LAW_WHILE:                                  ; inicio del WHILE (evalua primero)
    CMP DI, CX                              ; condicion: i < N ?
    JAE LAW_FIN                             ; si i >= N sale del ciclo
    PUSH CX                                 ; guarda N porque GENERAR usa CX
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [BX, DX]
    POP CX                                  ; recupera N
    MOV [SI], AX                            ; guarda la palabra en VECTOR[i]
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    INC DI                                  ; i = i + 1
    JMP LAW_WHILE                           ; vuelve a evaluar la condicion
LAW_FIN:                                    ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_ALEATORIO_WHILE ENDP                 ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LLENAR_CON_WHILE ======

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
