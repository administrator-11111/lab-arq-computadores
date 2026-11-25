;==============================================================================
; ARCHIVO       : comparar_dos_vectores.asm
; TIPO          : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION   : Compara posicion por posicion dos vectores de palabras (DW)
;                 sin signo del mismo tamano, acumulando puntos en PUNTOS_V1
;                 cuando V1[i] > V2[i] y en PUNTOS_V2 cuando V2[i] > V1[i].
;                 Las posiciones iguales no suman a ninguno. Devuelve el
;                 ganador (1, 2 o 0 para empate) en AX.
; FUNCIONAMIENTO: 1) Inicializa PUNTOS_V1 = 0 y PUNTOS_V2 = 0.
;                 2) Recorre ambos vectores en paralelo usando SI (V1) y DI
;                    (V2) durante CX iteraciones:
;                    - Si [SI] == [DI]: no suma puntos (empate en esa posicion).
;                    - Si [SI] > [DI] (JA, sin signo): incrementa PUNTOS_V1.
;                    - Si [SI] < [DI] (JB, sin signo): incrementa PUNTOS_V2.
;                 3) Al terminar el recorrido compara PUNTOS_V1 con PUNTOS_V2
;                    y retorna en AX: 1 (gana V1), 2 (gana V2) o 0 (empate).
;                 La demo ejecuta primero una prueba con dos vectores fijos
;                 (incluyendo posiciones iguales) y luego otra con dos vectores
;                 aleatorios generados con INICIALIZAR_SEMILLA / GENERAR_ALEATORIO.
; REGISTROS     : Entrada  : SI = offset V1 (DW), DI = offset V2 (DW),
;                            CX = cantidad de elementos
;                 Salida   : AX = 1 (gana V1), 2 (gana V2), 0 (empate)
;                            Variables PUNTOS_V1 y PUNTOS_V2 actualizadas
;                 Modifica : AX y banderas (conserva BX, CX, DX, SI, DI)
; VARIABLES     : PUNTOS_V1 DW 0, PUNTOS_V2 DW 0 en DATOS
; DEPENDENCIAS  : Ninguna para COMPARAR_VECTORES. La demo usa macros de E/S de
;                 utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm y
;                 INICIALIZAR_SEMILLA, GENERAR_ALEATORIO, MOSTRAR_VECTOR.
; COMO INTEGRAR : 1. Declarar PUNTOS_V1 DW 0 y PUNTOS_V2 DW 0 en DATOS.
;                 2. Copiar el bloque COMPARAR_VECTORES en CODIGO despues de
;                    la salida a DOS.
;                 3. Cargar SI = OFFSET V1, DI = OFFSET V2, CX = N y llamar a
;                    CALL COMPARAR_VECTORES. Leer AX, PUNTOS_V1 y PUNTOS_V2.
; EJEMPLO       : --- Prueba 1: Vectores fijos ---
;                 Vector 1: 10 25 30 15 40 20
;                 Vector 2: 12 25 18 15 35 50
;                 Puntos V1: 2 | Puntos V2: 2 -> Resultado: EMPATE
;                 --- Prueba 2: Vectores aleatorios ---
;                 (muestra ambos vectores aleatorios, puntos y ganador/empate)
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

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MSG_TITULO DB '=== DEMO: COMPARAR DOS VECTORES ===$' ; titulo general
    MSG_P1     DB '--- Prueba 1: Vectores fijos (con iguales) ---$' ; sub1
    MSG_P2     DB '--- Prueba 2: Vectores aleatorios (1..20) ---$' ; sub2
    MSG_V1     DB 'Vector 1 : $'            ; etiqueta vector 1
    MSG_V2     DB 'Vector 2 : $'            ; etiqueta vector 2
    MSG_PTS1   DB 'Puntos V1: $'            ; etiqueta puntos V1
    MSG_PTS2   DB ' | Puntos V2: $'         ; etiqueta puntos V2
    MSG_G1     DB ' -> Resultado: GANA VECTOR 1$' ; mensaje ganador 1
    MSG_G2     DB ' -> Resultado: GANA VECTOR 2$' ; mensaje ganador 2
    MSG_EMP    DB ' -> Resultado: EMPATE$'  ; mensaje empate
    V1_FIJO    DW 10, 25, 30, 15, 40, 20    ; vector fijo 1 (pos 1 y 3 iguales)
    V2_FIJO    DW 12, 25, 18, 15, 35, 50    ; vector fijo 2 (2 pts vs 2 pts)
    N_FIJO     DW 6                         ; tamano de los vectores fijos
    V1_ALE     DW 6 DUP(0)                  ; vector aleatorio 1
    V2_ALE     DW 6 DUP(0)                  ; vector aleatorio 2
    N_ALE      DW 6                         ; tamano de los vectores aleatorios
    PUNTOS_V1  DW 0                         ; acumulador de puntos de V1
    PUNTOS_V2  DW 0                         ; acumulador de puntos de V2
    SEMILLA    DW 0                         ; semilla del generador aleatorio
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo principal
    SALTO_LINEA                             ; nueva linea

    ;--- Prueba 1: vectores fijos ---
    IMPRIMIR_CADENA MSG_P1                  ; subtitulo prueba 1
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_V1                  ; etiqueta vector 1
    MOV SI, OFFSET V1_FIJO                  ; SI = vector fijo 1
    MOV CX, N_FIJO                          ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra V1_FIJO
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_V2                  ; etiqueta vector 2
    MOV SI, OFFSET V2_FIJO                  ; SI = vector fijo 2
    MOV CX, N_FIJO                          ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra V2_FIJO
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET V1_FIJO                  ; SI = vector 1
    MOV DI, OFFSET V2_FIJO                  ; DI = vector 2
    MOV CX, N_FIJO                          ; CX = cantidad
    CALL COMPARAR_VECTORES                  ; AX = 0 empate, 1 V1, 2 V2
    CALL MOSTRAR_RESULTADO_COMP             ; imprime puntos y ganador

    SALTO_LINEA                             ; linea en blanco de separacion

    ;--- Prueba 2: vectores aleatorios ---
    IMPRIMIR_CADENA MSG_P2                  ; subtitulo prueba 2
    SALTO_LINEA                             ; nueva linea
    CALL INICIALIZAR_SEMILLA                ; inicializa semilla desde reloj

    MOV SI, OFFSET V1_ALE                   ; llena V1_ALE con valores 1..20
    MOV CX, N_ALE                           ; CX = cantidad
LLENAR_V1:                                  ; ciclo llenado V1_ALE
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; limite inferior
    MOV CX, 20                              ; limite superior
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 20]
    MOV [SI], AX                            ; guarda en V1_ALE
    ADD SI, 2                               ; siguiente elemento
    POP CX                                  ; recupera contador
    LOOP LLENAR_V1                          ; repite para todos los elementos

    MOV SI, OFFSET V2_ALE                   ; llena V2_ALE con valores 1..20
    MOV CX, N_ALE                           ; CX = cantidad
LLENAR_V2:                                  ; ciclo llenado V2_ALE
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; limite inferior
    MOV CX, 20                              ; limite superior
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 20]
    MOV [SI], AX                            ; guarda en V2_ALE
    ADD SI, 2                               ; siguiente elemento
    POP CX                                  ; recupera contador
    LOOP LLENAR_V2                          ; repite para todos los elementos

    IMPRIMIR_CADENA MSG_V1                  ; etiqueta vector 1
    MOV SI, OFFSET V1_ALE                   ; SI = V1_ALE
    MOV CX, N_ALE                           ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra V1_ALE
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_V2                  ; etiqueta vector 2
    MOV SI, OFFSET V2_ALE                   ; SI = V2_ALE
    MOV CX, N_ALE                           ; CX = cantidad
    CALL MOSTRAR_VECTOR                     ; muestra V2_ALE
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET V1_ALE                   ; SI = vector 1
    MOV DI, OFFSET V2_ALE                   ; DI = vector 2
    MOV CX, N_ALE                           ; CX = cantidad
    CALL COMPARAR_VECTORES                  ; compara y devuelve ganador en AX
    CALL MOSTRAR_RESULTADO_COMP             ; imprime puntos y ganador

    MOV AX, 4C00h                           ; servicio 4Ch: terminar programa
    INT 21h                                 ; vuelve a DOS con codigo 0

;====== INICIO BLOQUE REUTILIZABLE: COMPARAR_VECTORES ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO COMPARAR_VECTORES
;   Entrada : SI = offset V1 (DW), DI = offset V2 (DW), CX = cantidad
;   Salida  : PUNTOS_V1 = posiciones con V1[i] > V2[i]
;             PUNTOS_V2 = posiciones con V2[i] > V1[i]
;             AX = 1 (gana V1), 2 (gana V2), 0 (empate)
;   Modifica: AX y banderas (conserva BX, CX, DX, SI, DI)
;------------------------------------------------------------------------------
COMPARAR_VECTORES PROC                      ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (contador)
    PUSH DX                                 ; guarda DX (elemento de V2)
    PUSH SI                                 ; guarda SI (puntero V1)
    PUSH DI                                 ; guarda DI (puntero V2)

    MOV PUNTOS_V1, 0                        ; reinicia puntos de V1
    MOV PUNTOS_V2, 0                        ; reinicia puntos de V2
    CMP CX, 0                               ; vectores vacios?
    JE CV_DECIDIR                           ; si: 0 vs 0 es empate

CV_CICLO:                                   ; recorre posicion por posicion
    MOV AX, [SI]                            ; AX = V1[i]
    MOV DX, [DI]                            ; DX = V2[i]
    CMP AX, DX                              ; compara V1[i] con V2[i]
    JE CV_SIGUIENTE                         ; iguales: no suman a ninguno
    JA CV_PUNTO_V1                          ; V1[i] > V2[i] (sin signo)
    INC PUNTOS_V2                           ; V2[i] > V1[i]: punto para V2
    JMP CV_SIGUIENTE                        ; pasa a la siguiente posicion

CV_PUNTO_V1:                                ; suma punto al primer vector
    INC PUNTOS_V1                           ; PUNTOS_V1 = PUNTOS_V1 + 1

CV_SIGUIENTE:                               ; avanza ambos punteros
    ADD SI, 2                               ; siguiente palabra en V1
    ADD DI, 2                               ; siguiente palabra en V2
    LOOP CV_CICLO                           ; repite CX veces

CV_DECIDIR:                                 ; determina ganador o empate
    MOV AX, PUNTOS_V1                       ; AX = puntaje de V1
    CMP AX, PUNTOS_V2                       ; compara PUNTOS_V1 con PUNTOS_V2
    JE CV_EMPATE                            ; iguales -> empate
    JA CV_GANA_V1                           ; PUNTOS_V1 > PUNTOS_V2
    MOV AX, 2                               ; gana vector 2
    JMP CV_FIN                              ; sale del procedimiento

CV_GANA_V1:                                 ; gano el primer vector
    MOV AX, 1                               ; codigo 1 = gana V1
    JMP CV_FIN                              ; sale del procedimiento

CV_EMPATE:                                  ; ambos empataron
    MOV AX, 0                               ; codigo 0 = empate

CV_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador con AX
COMPARAR_VECTORES ENDP                      ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: COMPARAR_VECTORES ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_RESULTADO_COMP (auxiliar de la demo)
;   Entrada : AX = 0 (empate), 1 (gana V1), 2 (gana V2)
;------------------------------------------------------------------------------
MOSTRAR_RESULTADO_COMP PROC                 ; imprime puntos y ganador
    IMPRIMIR_CADENA MSG_PTS1                ; muestra "Puntos V1: "
    IMPRIMIR_NUMERO PUNTOS_V1               ; muestra puntos de V1
    IMPRIMIR_CADENA MSG_PTS2                ; muestra " | Puntos V2: "
    IMPRIMIR_NUMERO PUNTOS_V2               ; muestra puntos de V2
    CMP AX, 1                               ; gano V1?
    JE MRC_G1                               ; si: muestra mensaje V1
    CMP AX, 2                               ; gano V2?
    JE MRC_G2                               ; si: muestra mensaje V2
    IMPRIMIR_CADENA MSG_EMP                 ; muestra mensaje de empate
    JMP MRC_FIN                             ; salta al salto de linea
MRC_G1:                                     ; caso ganador 1
    IMPRIMIR_CADENA MSG_G1                  ; muestra ganador 1
    JMP MRC_FIN                             ; salta al salto de linea
MRC_G2:                                     ; caso ganador 2
    IMPRIMIR_CADENA MSG_G2                  ; muestra ganador 2
MRC_FIN:                                    ; cierre comun
    SALTO_LINEA                             ; nueva linea
    RET                                     ; vuelve al llamador
MOSTRAR_RESULTADO_COMP ENDP                 ; fin del auxiliar

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
