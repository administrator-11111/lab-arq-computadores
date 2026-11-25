;==============================================================================
; ARCHIVO      : llenar_vector_aleatorio.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Implementa LLENAR_VECTOR_ALEATORIO para cargar un vector de
;                palabras (DW) con numeros pseudoaleatorios en el rango
;                [BX, DX] usando GENERAR_ALEATORIO.
; FUNCIONAMIENTO:
;                Recibe SI = offset del vector, CX = cantidad, BX = minimo y
;                DX = maximo. Como GENERAR_ALEATORIO usa CX para recibir el
;                valor maximo y el ciclo LOOP tambien usa CX como contador,
;                en cada iteracion se guarda CX con PUSH CX, se copia DX en
;                CX, se llama a GENERAR_ALEATORIO (resultado en AX), se guarda
;                AX en [SI], se avanza SI en 2 bytes y se recupera CX con
;                POP CX antes de ejecutar LOOP.
; REGISTROS    : LLENAR_VECTOR_ALEATORIO:
;                  Entrada : SI = offset del vector (DW), CX = cantidad,
;                            BX = minimo, DX = maximo (BX <= DX)
;                  Salida  : vector cargado con numeros en [BX, DX]
;                  Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI)
; VARIABLES    : Requiere SEMILLA DW 0 en DATOS (inicializada una sola vez
;                con CALL INICIALIZAR_SEMILLA antes de llenar vectores).
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimientos INICIALIZAR_SEMILLA, GENERAR_ALEATORIO y
;                MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Declarar SEMILLA DW 0 y el vector DW en DATOS.
;                3) Copiar INICIALIZAR_SEMILLA, GENERAR_ALEATORIO y
;                   LLENAR_VECTOR_ALEATORIO en CODIGO despues de FIN_PROGRAMA.
;                4) Llamar CALL INICIALIZAR_SEMILLA una vez al inicio y luego
;                   CALL LLENAR_VECTOR_ALEATORIO con SI, CX, BX, DX.
; EJEMPLO      : Salida (varia segun la hora del sistema):
;                  === LLENAR VECTOR ALEATORIO ===
;                  Vector aleatorio (10 elementos en 1..100):
;                  37 82 14 95 61 8 44 73 29 50
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
    TAMANO     EQU 10                       ; cantidad de elementos
    VECTOR     DW TAMANO DUP(0)             ; vector de 10 palabras (20 bytes)

    MSG_TIT    DB '=== LLENAR VECTOR ALEATORIO ===$' ; titulo
    MSG_VEC    DB 'Vector aleatorio (10 elementos en 1..100):$' ; etiqueta
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    CALL INICIALIZAR_SEMILLA                ; semilla inicial desde el reloj

    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 10 elementos
    MOV BX, 1                               ; BX = valor minimo (1)
    MOV DX, 100                             ; DX = valor maximo (100)
    CALL LLENAR_VECTOR_ALEATORIO            ; carga el vector con aleatorios

    IMPRIMIR_CADENA MSG_VEC                 ; muestra la etiqueta
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 10 elementos
    CALL MOSTRAR_VECTOR                     ; muestra los 10 numeros
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: LLENAR_VECTOR_ALEATORIO ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LLENAR_VECTOR_ALEATORIO
;   Entrada : SI = offset del vector (DW), CX = cantidad,
;             BX = valor minimo, DX = valor maximo (BX <= DX)
;   Salida  : llena el vector con CX numeros pseudoaleatorios en [BX, DX].
;   Requiere: GENERAR_ALEATORIO y variable SEMILLA DW en DATOS.
;   Modifica: SEMILLA y banderas (conserva AX, BX, CX, DX, SI).
;------------------------------------------------------------------------------
LLENAR_VECTOR_ALEATORIO PROC                ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (minimo)
    PUSH CX                                 ; guarda CX (cantidad)
    PUSH DX                                 ; guarda DX (maximo)
    PUSH SI                                 ; guarda SI (puntero al vector)
    CMP CX, 0                               ; vector vacio?
    JE LVA_FIN                              ; si: no genera nada
LVA_CICLO:                                  ; ciclo de llenado
    PUSH CX                                 ; guarda contador del ciclo
    MOV CX, DX                              ; CX = maximo para GENERAR_ALEATORIO
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [BX, CX]
    MOV [SI], AX                            ; guarda la palabra en el vector
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    POP CX                                  ; recupera contador del ciclo
    LOOP LVA_CICLO                          ; CX-1 y repite si CX <> 0
LVA_FIN:                                    ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
LLENAR_VECTOR_ALEATORIO ENDP                ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: LLENAR_VECTOR_ALEATORIO ======

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
