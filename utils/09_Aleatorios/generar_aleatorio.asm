;==============================================================================
; ARCHIVO      : generar_aleatorio.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Generador canonico de numeros pseudoaleatorios en 8086
;                (INICIALIZAR_SEMILLA y GENERAR_ALEATORIO) para obtener
;                valores uniformes en cualquier intervalo [BX, CX].
; FUNCIONAMIENTO:
;   1) INICIALIZAR_SEMILLA consulta la hora del sistema mediante DOS
;      (INT 21h, AH=2Ch), que devuelve CH=hora, CL=minutos, DH=segundos y
;      DL=centesimas. Mezcla CX y DX con XOR y guarda el resultado en SEMILLA
;      para que cada ejecucion produzca una secuencia diferente.
;   2) GENERAR_ALEATORIO aplica un Generador Congruencial Lineal (LCG):
;        SEMILLA = (SEMILLA * 25173 + 13849) mod 65536
;      En 16 bits, el "mod 65536" ocurre automaticamente al quedarse con AX
;      (se descarta la parte alta DX de MUL y el acarreo de ADD).
;   3) XCHG AH, AL intercambia el byte alto y el byte bajo antes del modulo:
;      en un LCG modulo 2^16, los bits menos significativos tienen periodo
;      muy corto (el bit 0 alterna 0,1,0,1), mientras que los bits altos
;      son mucho mas aleatorios.
;   4) Para ajustar al intervalo [min, max]:
;        cantidad = max - min + 1
;        resultado = (valor mod cantidad) + min
;      Se usa DIV CX con DX=0; el residuo en DX esta en [0, cantidad-1].
;   LIMITES: requiere BX <= CX y (CX - BX) < 65535. Si BX=0 y CX=65535,
;      INC CX desbordaria a 0 y DIV CX provocaria error de division por cero.
; REGISTROS    :
;   INICIALIZAR_SEMILLA -> Entrada: ninguna. Salida: SEMILLA actualizada.
;                          Conserva todos los registros.
;   GENERAR_ALEATORIO   -> Entrada: BX = minimo, CX = maximo.
;                          Salida: AX = aleatorio en [BX, CX].
;                          Modifica: AX, SEMILLA y banderas. Conserva BX,CX,DX.
; VARIABLES    : SEMILLA DW 0 en el segmento DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA de
;                utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm.
; COMO INTEGRAR: Copiar las macros arriba de PILA, declarar SEMILLA DW 0 en
;                DATOS, copiar el bloque reutilizable dentro de CODIGO despues
;                de FIN_PROGRAMA. Llamar una sola vez a INICIALIZAR_SEMILLA al
;                inicio y luego cargar BX/CX antes de cada CALL GENERAR_ALEATORIO.
;                Atencion: si usas CX como contador de un ciclo LOOP, guarda
;                CX con PUSH CX antes de cargar el maximo y restaura con POP CX.
; EJEMPLO      :
;   === DEMO GENERADOR ALEATORIO (LCG) ===
;   Un numero entre 1 y 100: 47
;   5 lanzamientos de dado (1..6): 4 1 6 3 2
;   5 numeros en [10, 20]: 15 11 19 12 18
;   8 numeros en [0, 99] con ciclo: 83 14 57 92 6 39 71 28
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
    SEMILLA    DW 0                         ; estado interno del generador LCG
    CANTIDAD_N DW 8                         ; cantidad para la demo con ciclo
    MSG_TIT    DB '=== DEMO GENERADOR ALEATORIO (LCG) ===$' ; titulo
    MSG_UNO    DB 'Un numero entre 1 y 100: $'              ; etiqueta demo 1
    MSG_DADO   DB '5 lanzamientos de dado (1..6): $'        ; etiqueta demo 2
    MSG_RANGO  DB '5 numeros en [10, 20]: $'                ; etiqueta demo 3
    MSG_CICLO  DB '8 numeros en [0, 99] con ciclo: $'       ; etiqueta demo 4
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento de datos

    CALL INICIALIZAR_SEMILLA                ; inicializa SEMILLA con la hora DOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo de la demo
    SALTO_LINEA                             ; baja a la siguiente linea

    ; --- Demo 1: generar un solo numero en [1, 100] ---
    IMPRIMIR_CADENA MSG_UNO                 ; muestra etiqueta de demo 1
    MOV BX, 1                               ; BX = limite inferior (1)
    MOV CX, 100                             ; CX = limite superior (100)
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 100]
    IMPRIMIR_NUMERO AX                      ; muestra el numero generado
    SALTO_LINEA                             ; nueva linea

    ; --- Demo 2: simular 5 lanzamientos de dado [1, 6] ---
    IMPRIMIR_CADENA MSG_DADO                ; muestra etiqueta de demo 2
    MOV CX, 5                               ; CX = 5 lanzamientos
DEMO_DADO:                                  ; ciclo para el dado
    PUSH CX                                 ; guarda el contador del ciclo
    MOV BX, 1                               ; BX = minimo del dado (1)
    MOV CX, 6                               ; CX = maximo del dado (6)
    CALL GENERAR_ALEATORIO                  ; AX = cara del dado (1..6)
    IMPRIMIR_NUMERO AX                      ; muestra el resultado
    IMPRIMIR_ESPACIO                        ; separa con un espacio
    POP CX                                  ; recupera el contador del ciclo
    LOOP DEMO_DADO                          ; decrementa CX y repite si CX<>0
    SALTO_LINEA                             ; nueva linea

    ; --- Demo 3: 5 numeros en el intervalo [10, 20] ---
    IMPRIMIR_CADENA MSG_RANGO               ; muestra etiqueta de demo 3
    MOV CX, 5                               ; CX = 5 numeros a generar
DEMO_RANGO:                                 ; ciclo para intervalo [10, 20]
    PUSH CX                                 ; guarda el contador del ciclo
    MOV BX, 10                              ; BX = minimo (10)
    MOV CX, 20                              ; CX = maximo (20)
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [10, 20]
    IMPRIMIR_NUMERO AX                      ; muestra el numero
    IMPRIMIR_ESPACIO                        ; separador
    POP CX                                  ; recupera el contador del ciclo
    LOOP DEMO_RANGO                         ; repite 5 veces
    SALTO_LINEA                             ; nueva linea

    ; --- Demo 4: N numeros en [0, 99] usando una variable ---
    IMPRIMIR_CADENA MSG_CICLO               ; muestra etiqueta de demo 4
    MOV CX, CANTIDAD_N                      ; CX = N (8 numeros)
DEMO_CICLO:                                 ; ciclo para N numeros
    PUSH CX                                 ; guarda CX antes de cargar maximo
    MOV BX, 0                               ; BX = minimo (0)
    MOV CX, 99                              ; CX = maximo (99)
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [0, 99]
    IMPRIMIR_NUMERO AX                      ; muestra el numero generado
    IMPRIMIR_ESPACIO                        ; separador
    POP CX                                  ; restaura contador del ciclo
    LOOP DEMO_CICLO                         ; repite N veces
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: GENERADOR_ALEATORIO ======

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

;====== FIN BLOQUE REUTILIZABLE: GENERADOR_ALEATORIO ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
