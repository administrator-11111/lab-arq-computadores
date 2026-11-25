;==============================================================================
; ARCHIVO      : frecuencia_digitos.asm
; TIPO         : ALGORITMO (+ programa de demostracion)
; DESCRIPCION  : Cuenta cuantas veces aparece cada digito 0..9 en un vector
;                usando un arreglo de contadores FRECUENCIA DW 10 DUP(0)
;                indexado directamente por el digito, y muestra la tabla
;                "Digito X: Y veces" usando macros de E/S.
; FUNCIONAMIENTO:
;   1) Cada posicion d (0..9) de FRECUENCIA guarda la cantidad de apariciones
;      del digito d. Como FRECUENCIA es de palabras (DW = 2 bytes), el
;      desplazamiento en bytes del contador para el digito d es:
;        desplazamiento = d * 2   (calculado con SHL BX, 1)
;   2) CONTAR_FRECUENCIAS limpia primero las 10 palabras de FRECUENCIA a 0,
;      luego recorre el vector de entrada; si el valor d cumple d <= 9,
;      calcula BX = d * 2 e incrementa la palabra en [DI + BX].
;   3) MOSTRAR_FRECUENCIAS recorre d = 0..9 y usa las macros IMPRIMIR_CADENA,
;      IMPRIMIR_NUMERO y SALTO_LINEA para imprimir "Digito X: Y veces".
; REGISTROS    :
;   CONTAR_FRECUENCIAS  -> Entrada: SI = vector de digitos (DW), CX = cantidad,
;                                   DI = vector FRECUENCIA (10 DW).
;                          Conserva todos los registros.
;   MOSTRAR_FRECUENCIAS -> Entrada: DI = vector FRECUENCIA (10 DW).
;                          Conserva todos los registros.
; VARIABLES    : DATOS_EJEMPLO DW, FRECUENCIA DW 10 DUP(0), mensajes en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA de
;                utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y MOSTRAR_VECTOR.
; COMO INTEGRAR: Copiar las macros, declarar FRECUENCIA DW 10 DUP(0) y los
;                mensajes MSG_FREC1/2/3 en DATOS, y copiar el bloque
;                reutilizable dentro de CODIGO despues de FIN_PROGRAMA.
; EJEMPLO      :
;   === DEMO FRECUENCIA DE DIGITOS (0..9) ===
;   Digitos analizados: 3 7 3 0 9 3 7 1 0 5
;   Tabla de frecuencias:
;   Digito 0: 2 veces
;   Digito 1: 1 veces
;   ...
;   Digito 3: 3 veces
;   ...
;   Digito 9: 1 veces
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
    DIGITOS    DW 3, 7, 3, 0, 9, 3, 7, 1, 0, 5 ; vector de ejemplo (10 digitos)
    CANTIDAD   DW 10                           ; cantidad de digitos
    FRECUENCIA DW 10 DUP(0)                    ; contadores para digitos 0..9
    MSG_TIT    DB '=== DEMO FRECUENCIA DE DIGITOS (0..9) ===$' ; titulo
    MSG_VEC    DB 'Digitos analizados: $'                      ; etiqueta vec
    MSG_TABLA  DB 'Tabla de frecuencias:$'                     ; etiqueta tabla
    MSG_FREC1  DB 'Digito $'                                   ; prefijo fila
    MSG_FREC2  DB ': $'                                        ; separador
    MSG_FREC3  DB ' veces$'                                    ; sufijo fila
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo con macro
    SALTO_LINEA                             ; baja de linea con macro

    IMPRIMIR_CADENA MSG_VEC                 ; muestra etiqueta del vector
    MOV SI, OFFSET DIGITOS                  ; SI = vector de digitos
    MOV CX, CANTIDAD                        ; CX = 10 elementos
    CALL MOSTRAR_VECTOR                     ; imprime los digitos
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET DIGITOS                  ; SI = vector de entrada
    MOV CX, CANTIDAD                        ; CX = cantidad de elementos
    MOV DI, OFFSET FRECUENCIA               ; DI = tabla de 10 contadores
    CALL CONTAR_FRECUENCIAS                 ; calcula frecuencias 0..9

    IMPRIMIR_CADENA MSG_TABLA               ; encabezado de la tabla
    SALTO_LINEA                             ; nueva linea
    MOV DI, OFFSET FRECUENCIA               ; DI = tabla de frecuencias
    CALL MOSTRAR_FRECUENCIAS                ; imprime "Digito X: Y veces"

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: FRECUENCIA_DIGITOS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_FRECUENCIAS
;   Entrada : SI = offset del vector de digitos (DW), CX = cantidad,
;             DI = offset del vector FRECUENCIA (10 palabras DW).
;   Salida  : FRECUENCIA[d] contiene cuantas veces aparece el digito d (0..9).
;   Modifica: solo el vector apuntado por DI (conserva AX, BX, CX, SI, DI).
;------------------------------------------------------------------------------
CONTAR_FRECUENCIAS PROC                     ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    PUSH DI                                 ; guarda DI

    ; Paso 1: poner en cero las 10 palabras de FRECUENCIA
    PUSH CX                                 ; guarda cantidad de entrada
    PUSH DI                                 ; guarda base de FRECUENCIA
    MOV CX, 10                              ; 10 contadores (digitos 0..9)
CF_LIMPIAR:                                 ; ciclo de limpieza
    MOV WORD PTR [DI], 0                    ; contador = 0
    ADD DI, 2                               ; siguiente palabra
    LOOP CF_LIMPIAR                         ; repite 10 veces
    POP DI                                  ; restaura base de FRECUENCIA
    POP CX                                  ; restaura cantidad de entrada

    ; Paso 2: recorrer el vector de digitos e incrementar FRECUENCIA[digito]
    CMP CX, 0                               ; vector vacio?
    JE CF_FIN                               ; si: termina
CF_CONTAR:                                  ; ciclo de conteo
    MOV BX, [SI]                            ; BX = digito actual
    CMP BX, 9                               ; esta en el rango valido 0..9?
    JA CF_SIG                               ; fuera de rango: lo ignora
    SHL BX, 1                               ; desplazamiento = digito * 2
    INC WORD PTR [DI + BX]                  ; FRECUENCIA[digito]++
CF_SIG:                                     ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra del vector
    LOOP CF_CONTAR                          ; repite CX veces
CF_FIN:                                     ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
CONTAR_FRECUENCIAS ENDP                     ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_FRECUENCIAS
;   Entrada : DI = offset del vector FRECUENCIA (10 palabras DW).
;   Salida  : imprime "Digito X: Y veces" para X = 0..9.
;   Requiere: macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, SALTO_LINEA y
;             mensajes MSG_FREC1, MSG_FREC2, MSG_FREC3 en DATOS.
;   Modifica: nada (conserva AX, BX, CX, DI).
;------------------------------------------------------------------------------
MOSTRAR_FRECUENCIAS PROC                    ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX
    PUSH CX                                 ; guarda CX
    PUSH DI                                 ; guarda DI
    MOV BX, 0                               ; BX = digito actual (0..9)
    MOV CX, 10                              ; 10 filas a imprimir
MF_CICLO:                                   ; ciclo de impresion
    IMPRIMIR_CADENA MSG_FREC1               ; "Digito "
    IMPRIMIR_NUMERO BX                      ; X (0..9)
    IMPRIMIR_CADENA MSG_FREC2               ; ": "
    MOV AX, [DI]                            ; AX = frecuencia del digito X
    IMPRIMIR_NUMERO AX                      ; Y
    IMPRIMIR_CADENA MSG_FREC3               ; " veces"
    SALTO_LINEA                             ; nueva linea
    ADD DI, 2                               ; siguiente contador (2 bytes)
    INC BX                                  ; siguiente digito
    DEC CX                                  ; decrementa contador (LOOP no
    JZ MF_FIN                               ; alcanza por macros en el cuerpo)
    JMP MF_CICLO                            ; repite hasta los 10 digitos
MF_FIN:                                     ; fin del ciclo de impresion
    POP DI                                  ; restaura DI
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MOSTRAR_FRECUENCIAS ENDP                    ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: FRECUENCIA_DIGITOS ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_VECTOR (canonico)
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
END INICIO                                  ; fin del programa
