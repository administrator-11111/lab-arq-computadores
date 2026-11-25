;==============================================================================
; ARCHIVO      : declarar_inicializar_vectores.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Muestra las formas de declarar vectores de palabras (DW) en
;                EMU8086 (lista explicita, DUP(0), DUP(?), constante EQU) y
;                procedimientos reutilizables para inicializar un vector con
;                ceros o con una secuencia 1..N (o desde un valor inicial).
; FUNCIONAMIENTO:
;                En el 8086 un vector de numeros de 16 bits (0..65535) se
;                declara con DW (Define Word). Cada elemento ocupa 2 bytes en
;                memoria, por lo que el elemento con indice logico i (0, 1, 2...)
;                se encuentra en el desplazamiento 2*i bytes desde el inicio:
;                  elemento 0 -> desplazamiento 0  (VECTOR + 0)
;                  elemento 1 -> desplazamiento 2  (VECTOR + 2)
;                  elemento 2 -> desplazamiento 4  (VECTOR + 4)
;                Para recorrerlo se carga el OFFSET del vector en SI, se
;                accede con [SI] (direccionamiento indirecto por registro) o
;                VECTOR[SI] (indexado) y se avanza con ADD SI, 2.
; REGISTROS    : INICIALIZAR_CEROS:
;                  Entrada : SI = offset del vector, CX = cantidad de elementos
;                  Salida  : vector lleno con ceros
;                  Modifica: ninguno (conserva AX, CX, SI)
;                INICIALIZAR_SECUENCIA:
;                  Entrada : SI = offset del vector, CX = cantidad,
;                            AX = valor inicial (ej. 1 para 1..N)
;                  Salida  : vector lleno con AX, AX+1, AX+2, ...
;                  Modifica: ninguno (conserva AX, CX, SI)
; VARIABLES    : Un vector declarado con DW en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimiento MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros necesarias arriba de PILA.
;                2) Declarar el vector con DW en DATOS.
;                3) Copiar el bloque reutilizable dentro de CODIGO (despues
;                   de FIN_PROGRAMA) y llamarlo con SI, CX (y AX si aplica).
; EJEMPLO      : Salida esperada:
;                  === DECLARAR E INICIALIZAR VECTORES ===
;                  Vector lista (DW 10,20,...): 10 20 30 40 50 60
;                  Vector DUP(0) inicial      : 0 0 0 0 0 0
;                  Vector DUP(?) inicializado 1..6: 1 2 3 4 5 6
;                  Vector lista puesto a ceros: 0 0 0 0 0 0
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
    TAM_VEC    EQU 6                        ; constante de tamano (no ocupa RAM)

    ; Forma 1: lista explicita de valores (cada uno ocupa 2 bytes = 12 bytes)
    VEC_LISTA  DW 10, 20, 30, 40, 50, 60    ; 6 palabras con valores iniciales

    ; Forma 2: DUP(0) repite el valor 0 la cantidad indicada (TAM_VEC veces)
    VEC_CEROS  DW TAM_VEC DUP(0)            ; 6 palabras inicializadas en 0

    ; Forma 3: DUP(?) reserva espacio sin valor inicial definido
    VEC_SEQ    DW TAM_VEC DUP(?)            ; 6 palabras reservadas (sin valor)

    MSG_TIT    DB '=== DECLARAR E INICIALIZAR VECTORES ===$' ; titulo
    MSG_LISTA  DB 'Vector lista (DW 10,20,...): $'          ; etiqueta 1
    MSG_CEROS  DB 'Vector DUP(0) inicial      : $'          ; etiqueta 2
    MSG_SEQ    DB 'Vector DUP(?) inicializado 1..6: $'      ; etiqueta 3
    MSG_BORRA  DB 'Vector lista puesto a ceros: $'          ; etiqueta 4
    MSG_IDX    DB 'Ejemplo VECTOR[SI] (indice 2, SI=4): $'  ; etiqueta 5
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    ; 1) Muestra el vector declarado con lista explicita
    IMPRIMIR_CADENA MSG_LISTA               ; etiqueta descriptiva
    MOV SI, OFFSET VEC_LISTA                ; SI apunta al primer elemento
    MOV CX, TAM_VEC                         ; CX = cantidad de elementos
    CALL MOSTRAR_VECTOR                     ; muestra los 6 elementos
    SALTO_LINEA                             ; nueva linea

    ; Ejemplo de direccionamiento indexado VECTOR[SI]:
    ; el indice logico 2 corresponde al desplazamiento 2 * 2 = 4 bytes
    IMPRIMIR_CADENA MSG_IDX                 ; etiqueta descriptiva
    MOV SI, 4                               ; desplazamiento en bytes (2 * 2)
    MOV AX, VEC_LISTA[SI]                   ; lee el tercer elemento (30)
    IMPRIMIR_NUMERO AX                      ; muestra 30
    SALTO_LINEA                             ; nueva linea

    ; 2) Muestra el vector declarado con DUP(0)
    IMPRIMIR_CADENA MSG_CEROS               ; etiqueta descriptiva
    MOV SI, OFFSET VEC_CEROS                ; SI apunta a VEC_CEROS
    MOV CX, TAM_VEC                         ; CX = 6 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 0 0 0 0 0 0
    SALTO_LINEA                             ; nueva linea

    ; 3) Inicializa el vector DUP(?) con la secuencia 1..6
    MOV SI, OFFSET VEC_SEQ                  ; SI apunta a VEC_SEQ
    MOV CX, TAM_VEC                         ; CX = 6 elementos
    MOV AX, 1                               ; valor inicial de la secuencia
    CALL INICIALIZAR_SECUENCIA              ; llena con 1, 2, 3, 4, 5, 6

    IMPRIMIR_CADENA MSG_SEQ                 ; etiqueta descriptiva
    MOV SI, OFFSET VEC_SEQ                  ; SI apunta a VEC_SEQ
    MOV CX, TAM_VEC                         ; CX = 6 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 1 2 3 4 5 6
    SALTO_LINEA                             ; nueva linea

    ; 4) Reinicia VEC_LISTA poniendo todos sus elementos en cero
    MOV SI, OFFSET VEC_LISTA                ; SI apunta a VEC_LISTA
    MOV CX, TAM_VEC                         ; CX = 6 elementos
    CALL INICIALIZAR_CEROS                  ; escribe 0 en todas las palabras

    IMPRIMIR_CADENA MSG_BORRA               ; etiqueta descriptiva
    MOV SI, OFFSET VEC_LISTA                ; SI apunta a VEC_LISTA
    MOV CX, TAM_VEC                         ; CX = 6 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 0 0 0 0 0 0
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: INICIALIZAR_VECTORES ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO INICIALIZAR_CEROS
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : todos los elementos del vector quedan en 0.
;   Modifica: nada (conserva AX, CX, SI).
;------------------------------------------------------------------------------
INICIALIZAR_CEROS PROC                      ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (contador)
    PUSH SI                                 ; guarda SI (puntero)
    CMP CX, 0                               ; vector vacio?
    JE ICER_FIN                             ; si: no escribe nada
    XOR AX, AX                              ; AX = 0 (valor a escribir)
ICER_CICLO:                                 ; ciclo de inicializacion
    MOV [SI], AX                            ; escribe 0 en la palabra actual
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP ICER_CICLO                         ; decrementa CX y repite si <> 0
ICER_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
INICIALIZAR_CEROS ENDP                      ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO INICIALIZAR_SECUENCIA
;   Entrada : SI = offset del vector (DW), CX = cantidad, AX = valor inicial
;   Salida  : llena el vector con AX, AX+1, AX+2, ...
;   Modifica: nada (conserva AX, CX, SI).
;------------------------------------------------------------------------------
INICIALIZAR_SECUENCIA PROC                  ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (valor actual)
    PUSH CX                                 ; guarda CX (contador)
    PUSH SI                                 ; guarda SI (puntero)
    CMP CX, 0                               ; vector vacio?
    JE ISEQ_FIN                             ; si: no escribe nada
ISEQ_CICLO:                                 ; ciclo de llenado secuencial
    MOV [SI], AX                            ; guarda el valor actual en [SI]
    INC AX                                  ; siguiente numero de la secuencia
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP ISEQ_CICLO                         ; decrementa CX y repite si <> 0
ISEQ_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
INICIALIZAR_SECUENCIA ENDP                  ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: INICIALIZAR_VECTORES ======

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
