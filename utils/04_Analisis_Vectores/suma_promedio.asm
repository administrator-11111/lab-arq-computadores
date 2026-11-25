;==============================================================================
; ARCHIVO      : suma_promedio.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Implementa SUMA_VECTOR (acumulacion segura en 32 bits DX:AX
;                usando ADD y ADC) y PROMEDIO_VECTOR (division entera con
;                residuo y proteccion contra vector vacio CX = 0).
; FUNCIONAMIENTO:
;                1) SUMA_VECTOR recorre el vector de palabras (DW) avanzando
;                   SI de 2 en 2 bytes. Acumula cada palabra en AX con
;                   ADD AX, [SI] y propaga el acarreo (CF) a DX con ADC DX, 0.
;                   Asi el resultado es un entero sin signo de 32 bits en
;                   DX:AX (hasta 4.294.967.295), evitando el desborde de 16
;                   bits (65535) cuando se suman muchos elementos o valores
;                   grandes.
;                2) PROMEDIO_VECTOR comprueba primero si CX = 0 (vector vacio)
;                   para evitar una division por cero. Luego llama a
;                   SUMA_VECTOR, que deja la suma de 32 bits exactamente en
;                   DX:AX, y ejecuta DIV CX:
;                     AX = cociente (promedio entero)
;                     DX = residuo  (suma mod CX)
;                   Nota matematica: como cada elemento es <= 65535, el
;                   promedio de CX elementos nunca supera 65535, por lo que
;                   el cociente siempre cabe en AX (16 bits) sin error de DIV.
; REGISTROS    : SUMA_VECTOR:
;                  Entrada : SI = offset del vector (DW), CX = cantidad
;                  Salida  : DX:AX = suma sin signo de 32 bits (DX alto, AX bajo)
;                  Modifica: AX, DX y banderas (conserva BX, CX, SI)
;                PROMEDIO_VECTOR:
;                  Entrada : SI = offset del vector (DW), CX = cantidad
;                  Salida  : AX = promedio entero, DX = residuo (0 y 0 si CX=0)
;                  Modifica: AX, DX y banderas (conserva BX, CX, SI)
; VARIABLES    : Un vector DW en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimiento MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Copiar el bloque reutilizable en CODIGO despues de
;                   FIN_PROGRAMA y llamarlo con SI = OFFSET VECTOR, CX = N.
; EJEMPLO      : Salida esperada:
;                  === SUMA (32 BITS) Y PROMEDIO DE VECTOR ===
;                  Vector 1: 10 20 35 42
;                    Suma (16b): 107  |  Promedio: 26  Residuo: 3
;                  Vector 2 (suma > 65535): 30000 40000 50000
;                    Suma DX (x65536): 1  AX: 54464  |  Promedio: 40000  Residuo: 0
;                  Vector vacio (CX=0):
;                    Promedio: 0  Residuo: 0
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
    VEC1       DW 10, 20, 35, 42            ; suma=107, prom=26, residuo=3
    TAM1       EQU 4                        ; cantidad de elementos de VEC1

    VEC2       DW 30000, 40000, 50000       ; suma=120000 (DX=1, AX=54464)
    TAM2       EQU 3                        ; cantidad de elementos de VEC2

    MSG_TIT    DB '=== SUMA (32 BITS) Y PROMEDIO DE VECTOR ===$' ; titulo
    MSG_V1     DB 'Vector 1: $'             ; etiqueta vector 1
    MSG_V2     DB 'Vector 2 (suma > 65535): $' ; etiqueta vector 2
    MSG_VAC    DB 'Vector vacio (CX=0):$'   ; etiqueta vector vacio
    MSG_SUMA   DB '  Suma: $'               ; etiqueta suma
    MSG_DX     DB '  Suma DX (x65536): $'   ; parte alta de suma 32 bits
    MSG_AX     DB '  AX: $'                 ; parte baja de suma 32 bits
    MSG_PROM   DB '  |  Promedio: $'        ; etiqueta promedio
    MSG_PROM2  DB '  Promedio: $'           ; etiqueta promedio (vacio)
    MSG_RES    DB '  Residuo: $'            ; etiqueta residuo
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    ; --- Caso 1: vector normal (suma cabe en 16 bits, con residuo) ---
    IMPRIMIR_CADENA MSG_V1                  ; etiqueta
    MOV SI, OFFSET VEC1                     ; SI apunta a VEC1
    MOV CX, TAM1                            ; CX = 4 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 10 20 35 42
    SALTO_LINEA                             ; nueva linea

    CALL SUMA_VECTOR                        ; DX:AX = 107 (DX=0, AX=107)
    IMPRIMIR_CADENA MSG_SUMA                ; etiqueta suma
    IMPRIMIR_NUMERO AX                      ; muestra 107
    CALL PROMEDIO_VECTOR                    ; AX = 26, DX = 3
    IMPRIMIR_CADENA MSG_PROM                ; etiqueta promedio
    IMPRIMIR_NUMERO AX                      ; muestra 26
    IMPRIMIR_CADENA MSG_RES                 ; etiqueta residuo
    IMPRIMIR_NUMERO DX                      ; muestra 3
    SALTO_LINEA                             ; nueva linea

    ; --- Caso 2: suma mayor a 65535 (demuestra ADC en 32 bits) ---
    IMPRIMIR_CADENA MSG_V2                  ; etiqueta
    MOV SI, OFFSET VEC2                     ; SI apunta a VEC2
    MOV CX, TAM2                            ; CX = 3 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 30000 40000 50000
    SALTO_LINEA                             ; nueva linea

    CALL SUMA_VECTOR                        ; DX = 1, AX = 54464 (120000)
    IMPRIMIR_CADENA MSG_DX                  ; etiqueta parte alta
    IMPRIMIR_NUMERO DX                      ; muestra 1
    IMPRIMIR_CADENA MSG_AX                  ; etiqueta parte baja
    IMPRIMIR_NUMERO AX                      ; muestra 54464
    CALL PROMEDIO_VECTOR                    ; AX = 40000, DX = 0
    IMPRIMIR_CADENA MSG_PROM                ; etiqueta promedio
    IMPRIMIR_NUMERO AX                      ; muestra 40000
    IMPRIMIR_CADENA MSG_RES                 ; etiqueta residuo
    IMPRIMIR_NUMERO DX                      ; muestra 0
    SALTO_LINEA                             ; nueva linea

    ; --- Caso 3: vector vacio (CX = 0, sin division por cero) ---
    IMPRIMIR_CADENA MSG_VAC                 ; etiqueta
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VEC1                     ; offset cualquiera
    MOV CX, 0                               ; CX = 0 elementos
    CALL PROMEDIO_VECTOR                    ; devuelve AX = 0, DX = 0
    IMPRIMIR_CADENA MSG_PROM2               ; etiqueta promedio
    IMPRIMIR_NUMERO AX                      ; muestra 0
    IMPRIMIR_CADENA MSG_RES                 ; etiqueta residuo
    IMPRIMIR_NUMERO DX                      ; muestra 0
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: SUMA_PROMEDIO ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO SUMA_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : DX:AX = suma sin signo de 32 bits (DX = parte alta, AX = baja)
;   Modifica: AX, DX y banderas (conserva BX, CX, SI).
;   Metodo  : ADD AX, [SI] suma la palabra actual y deja CF=1 si hay acarreo.
;             ADC DX, 0 suma 0 + CF a DX, manteniendo la suma exacta en 32 bits.
;------------------------------------------------------------------------------
SUMA_VECTOR PROC                            ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (contador)
    PUSH SI                                 ; guarda SI (puntero al vector)
    XOR AX, AX                              ; parte baja de la suma = 0
    XOR DX, DX                              ; parte alta de la suma = 0
    CMP CX, 0                               ; vector vacio?
    JE SV_FIN                               ; si: devuelve DX:AX = 0
SV_CICLO:                                   ; recorre el vector
    ADD AX, [SI]                            ; suma elemento actual a AX
    ADC DX, 0                               ; suma el acarreo (CF) a DX
    ADD SI, 2                               ; avanza 2 bytes (siguiente DW)
    LOOP SV_CICLO                           ; repite CX veces
SV_FIN:                                     ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
SUMA_VECTOR ENDP                            ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO PROMEDIO_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : AX = promedio entero (cociente), DX = residuo.
;             Si CX = 0 devuelve AX = 0 y DX = 0 (evita division por cero).
;   Requiere: SUMA_VECTOR.
;   Modifica: AX, DX y banderas (conserva BX, CX, SI).
;------------------------------------------------------------------------------
PROMEDIO_VECTOR PROC                        ; inicio del procedimiento
    CMP CX, 0                               ; vector vacio?
    JE PV_VACIO                             ; si: evita dividir por cero
    CALL SUMA_VECTOR                        ; DX:AX = suma exacta de 32 bits
    DIV CX                                  ; AX = DX:AX / CX, DX = residuo
    RET                                     ; vuelve con AX y DX listos
PV_VACIO:                                   ; manejo seguro de CX = 0
    XOR AX, AX                              ; promedio = 0
    XOR DX, DX                              ; residuo = 0
    RET                                     ; vuelve al llamador
PROMEDIO_VECTOR ENDP                        ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: SUMA_PROMEDIO ======

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
