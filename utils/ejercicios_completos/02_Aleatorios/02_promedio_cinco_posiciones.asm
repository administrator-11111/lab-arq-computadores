;==============================================================================
; EJERCICIO    : Promedio de 5 posiciones aleatorias distintas de un vector
; ARCHIVO      : 02_promedio_cinco_posiciones.asm
; ENUNCIADO    : Generar un vector de 20 numeros aleatorios, seleccionar 5
;                posiciones aleatorias sin repetir (0..19), mostrar los
;                valores elegidos y calcular su promedio (entero y residuo).
; SOLUCION     :
;   1) Se llena VECTOR (20 palabras) con aleatorios en [1, 100].
;   2) Se usa un vector auxiliar USADA DB 20 DUP(0) para registrar que
;      posiciones ya fueron elegidas (0 = libre, 1 = usada).
;   3) Se eligen 5 posiciones distintas en [0, 19]; los valores almacenados
;      en esas posiciones pueden repetirse si asi salieron al azar.
;   4) Se muestran las 5 posiciones y sus valores, se acumulan en SUMA y se
;      divide SUMA entre 5 para obtener PROMEDIO y RESIDUO.
; REGISTROS    : AX (valores y cociente), BX (indice y divisor), CX (contador),
;                DX (residuo), SI/DI (punteros a vectores).
; VARIABLES    : SEMILLA, VECTOR (20 DW), USADA (20 DB), POSICIONES (5 DW),
;                SUMA, PROMEDIO, RESIDUO.
; UTILS RELACIONADOS:
;   - utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;   - utils/09_Aleatorios/generar_aleatorio.asm
;   - utils/09_Aleatorios/seleccion_posiciones_aleatorias.asm
; EJEMPLO DE ENTRADA/SALIDA (run8086.py --time 19:11:22.33):
;   === PROMEDIO DE 5 POSICIONES ALEATORIAS ===
;   Vector completo (20 elementos):
;   18 49 62 70 8 96 31 15 57 71 67 65 20 48 92 89 14 25 73 10
;   Valores elegidos (5 posiciones distintas):
;     Pos 4 -> 8
;     Pos 13 -> 48
;     Pos 3 -> 70
;     Pos 14 -> 92
;     Pos 15 -> 89
;   Suma    : 307
;   Promedio: 61 (residuo 2/5)
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
    VECTOR     DW 20 DUP(0)                 ; vector de 20 aleatorios
    USADA      DB 20 DUP(0)                 ; marcas de posiciones usadas
    POSICIONES DW 5 DUP(0)                  ; 5 posiciones elegidas
    SUMA       DW 0                         ; suma de los 5 valores
    PROMEDIO   DW 0                         ; promedio entero
    RESIDUO    DW 0                         ; residuo de la division por 5
    MSG_TIT    DB '=== PROMEDIO DE 5 POSICIONES ALEATORIAS ===$' ; titulo
    MSG_VEC    DB 'Vector completo (20 elementos):$'             ; etiqueta 1
    MSG_SEL    DB 'Valores elegidos (5 posiciones distintas):$'  ; etiqueta 2
    MSG_POS    DB '  Pos $'                                      ; prefijo
    MSG_FLECHA DB ' -> $'                                        ; separador
    MSG_SUMA   DB 'Suma    : $'                                  ; suma
    MSG_PROM   DB 'Promedio: $'                                  ; promedio
    MSG_RES1   DB ' (residuo $'                                  ; residuo
    MSG_RES2   DB '/5)$'                                         ; cierre
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada
    MOV AX, DATOS                           ; AX = segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    CALL INICIALIZAR_SEMILLA                ; inicializa semilla con la hora

    IMPRIMIR_CADENA MSG_TIT                 ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    ; --- 1) Generar vector de 20 aleatorios en [1, 100] ---
    MOV SI, OFFSET VECTOR                   ; SI = inicio de VECTOR
    MOV CX, 20                              ; CX = 20 elementos
GEN_VEC:                                    ; ciclo de llenado
    PUSH CX                                 ; guarda contador del ciclo
    MOV BX, 1                               ; minimo = 1
    MOV CX, 100                             ; maximo = 100
    CALL GENERAR_ALEATORIO                  ; AX = aleatorio en [1, 100]
    MOV [SI], AX                            ; guarda en VECTOR
    ADD SI, 2                               ; siguiente palabra
    POP CX                                  ; recupera contador
    LOOP GEN_VEC                            ; repite 20 veces

    IMPRIMIR_CADENA MSG_VEC                 ; muestra etiqueta del vector
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VECTOR                   ; SI = inicio de VECTOR
    MOV CX, 20                              ; CX = 20 elementos
    CALL MOSTRAR_VECTOR                     ; imprime el vector completo
    SALTO_LINEA                             ; nueva linea

    ; --- 2) Elegir 5 posiciones distintas en [0, 19] ---
    MOV DI, OFFSET POSICIONES               ; DI = destino de posiciones
    MOV CX, 5                               ; CX = 5 posiciones
ELEGIR_5:                                   ; ciclo principal de seleccion
    PUSH CX                                 ; guarda contador restante
BUSCAR_LIBRE:                               ; repite si la posicion ya salio
    MOV BX, 0                               ; minimo = 0
    MOV CX, 19                              ; maximo = 19
    CALL GENERAR_ALEATORIO                  ; AX = posicion candidata
    MOV BX, AX                              ; BX = indice en USADA
    CMP USADA[BX], 1                        ; ya fue usada?
    JE BUSCAR_LIBRE                         ; si: genera otra posicion
    MOV USADA[BX], 1                        ; marca como usada
    MOV [DI], AX                            ; guarda posicion elegida
    ADD DI, 2                               ; avanza al siguiente DW
    POP CX                                  ; recupera contador
    LOOP ELEGIR_5                           ; repite 5 veces

    ; --- 3) Mostrar los 5 valores y sumar ---
    IMPRIMIR_CADENA MSG_SEL                 ; etiqueta de valores elegidos
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET POSICIONES               ; SI recorre POSICIONES
    MOV CX, 5                               ; CX = 5 elementos
    MOV SUMA, 0                             ; suma inicial = 0
SUMAR_5:                                    ; recorre las 5 posiciones
    MOV AX, [SI]                            ; AX = posicion elegida
    IMPRIMIR_CADENA MSG_POS                 ; muestra "  Pos "
    IMPRIMIR_NUMERO AX                      ; muestra la posicion
    MOV BX, AX                              ; BX = indice logico
    SHL BX, 1                               ; BX = indice * 2 (bytes)
    MOV AX, VECTOR[BX]                      ; AX = VECTOR[posicion]
    ADD SUMA, AX                            ; acumula el valor en SUMA
    IMPRIMIR_CADENA MSG_FLECHA              ; muestra " -> "
    IMPRIMIR_NUMERO AX                      ; muestra el valor
    SALTO_LINEA                             ; nueva linea
    ADD SI, 2                               ; siguiente posicion
    DEC CX                                  ; decrementa contador (LOOP queda
    JZ FIN_SUMAR_5                          ; fuera de +-127 bytes por macros)
    JMP SUMAR_5                             ; repite hasta completar los 5
FIN_SUMAR_5:                                ; fin del ciclo de suma

    ; --- 4) Calcular promedio (SUMA / 5) ---
    MOV AX, SUMA                            ; AX = suma de los 5 valores
    XOR DX, DX                              ; DX = 0 para DIV 16 bits
    MOV BX, 5                               ; divisor = 5
    DIV BX                                  ; AX = cociente, DX = residuo
    MOV PROMEDIO, AX                        ; guarda promedio entero
    MOV RESIDUO, DX                         ; guarda residuo

    IMPRIMIR_CADENA MSG_SUMA                ; muestra suma
    IMPRIMIR_NUMERO SUMA                    ; valor suma
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_PROM                ; muestra promedio
    IMPRIMIR_NUMERO PROMEDIO                ; cociente entero
    IMPRIMIR_CADENA MSG_RES1                ; muestra " (residuo "
    IMPRIMIR_NUMERO RESIDUO                 ; residuo
    IMPRIMIR_CADENA MSG_RES2                ; muestra "/5)"
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

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
