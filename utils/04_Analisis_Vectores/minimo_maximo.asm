;==============================================================================
; ARCHIVO      : minimo_maximo.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Implementa MINIMO_VECTOR y MAXIMO_VECTOR para obtener el menor
;                y el mayor elemento (enteros sin signo de 16 bits, 0..65535)
;                de un vector de palabras (DW).
; FUNCIONAMIENTO:
;                Ambos procedimientos reciben SI = offset del vector y CX =
;                cantidad de elementos. Si CX = 0 devuelven AX = 0.
;                En caso contrario, toman el primer elemento [SI] como mejor
;                candidato inicial en AX, avanzan SI en 2 bytes y decrementan
;                CX. Luego recorren los CX elementos restantes comparando
;                CMP [SI], AX:
;                - En MINIMO_VECTOR: si [SI] >= AX (JAE, sin signo) sigue;
;                  si [SI] < AX actualiza AX = [SI].
;                - En MAXIMO_VECTOR: si [SI] <= AX (JBE, sin signo) sigue;
;                  si [SI] > AX actualiza AX = [SI].
;                IMPORTANTE: se usan JAE/JBE (sin signo) y NO JGE/JLE (con
;                signo), para que valores como 45000 o 60000 no se interpreten
;                erroneamente como negativos.
; REGISTROS    : MINIMO_VECTOR / MAXIMO_VECTOR:
;                  Entrada : SI = offset del vector (DW), CX = cantidad
;                  Salida  : AX = valor minimo / maximo sin signo (0 si CX=0)
;                  Modifica: AX y banderas (conserva BX, CX, DX, SI)
; VARIABLES    : Un vector DW en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimiento MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Copiar el bloque reutilizable en CODIGO despues de
;                   FIN_PROGRAMA y llamarlo con SI = OFFSET VECTOR, CX = N.
; EJEMPLO      : Salida esperada:
;                  === MINIMO Y MAXIMO DE UN VECTOR (SIN SIGNO) ===
;                  Vector: 45000 120 60000 5 32768 19
;                  Minimo: 5
;                  Maximo: 60000
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
    ; Incluye valores > 32767 para demostrar comparacion sin signo (JAE/JBE)
    VECTOR     DW 45000, 120, 60000, 5, 32768, 19 ; 6 palabras de prueba
    TAMANO     EQU 6                        ; cantidad de elementos

    MSG_TIT    DB '=== MINIMO Y MAXIMO DE UN VECTOR (SIN SIGNO) ===$' ; titulo
    MSG_VEC    DB 'Vector: $'               ; etiqueta vector
    MSG_MIN    DB 'Minimo: $'               ; etiqueta minimo
    MSG_MAX    DB 'Maximo: $'               ; etiqueta maximo
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_VEC                 ; etiqueta
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 6 elementos
    CALL MOSTRAR_VECTOR                     ; muestra los elementos
    SALTO_LINEA                             ; nueva linea

    CALL MINIMO_VECTOR                      ; AX = minimo sin signo (5)
    IMPRIMIR_CADENA MSG_MIN                 ; etiqueta minimo
    IMPRIMIR_NUMERO AX                      ; muestra 5
    SALTO_LINEA                             ; nueva linea

    CALL MAXIMO_VECTOR                      ; AX = maximo sin signo (60000)
    IMPRIMIR_CADENA MSG_MAX                 ; etiqueta maximo
    IMPRIMIR_NUMERO AX                      ; muestra 60000
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: MINIMO_MAXIMO ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO MINIMO_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : AX = menor valor sin signo (0 si CX = 0).
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
MINIMO_VECTOR PROC                          ; inicio del procedimiento
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; valor por defecto si CX = 0
    CMP CX, 0                               ; vector vacio?
    JE MINV_FIN                             ; si: devuelve 0
    MOV AX, [SI]                            ; minimo inicial = primer elemento
    ADD SI, 2                               ; apunta al segundo elemento
    DEC CX                                  ; ya se proceso el primero
    JZ MINV_FIN                             ; si habia solo 1 elemento, termina
MINV_CICLO:                                 ; recorre los elementos restantes
    CMP [SI], AX                            ; compara actual con minimo
    JAE MINV_SIG                            ; si actual >= minimo (sin signo)
    MOV AX, [SI]                            ; nuevo minimo encontrado
MINV_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP MINV_CICLO                         ; repite hasta terminar
MINV_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
MINIMO_VECTOR ENDP                          ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO MAXIMO_VECTOR
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : AX = mayor valor sin signo (0 si CX = 0).
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
MAXIMO_VECTOR PROC                          ; inicio del procedimiento
    PUSH CX                                 ; guarda CX
    PUSH SI                                 ; guarda SI
    XOR AX, AX                              ; valor por defecto si CX = 0
    CMP CX, 0                               ; vector vacio?
    JE MAXV_FIN                             ; si: devuelve 0
    MOV AX, [SI]                            ; maximo inicial = primer elemento
    ADD SI, 2                               ; apunta al segundo elemento
    DEC CX                                  ; ya se proceso el primero
    JZ MAXV_FIN                             ; si habia solo 1 elemento, termina
MAXV_CICLO:                                 ; recorre los elementos restantes
    CMP [SI], AX                            ; compara actual con maximo
    JBE MAXV_SIG                            ; si actual <= maximo (sin signo)
    MOV AX, [SI]                            ; nuevo maximo encontrado
MAXV_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP MAXV_CICLO                         ; repite hasta terminar
MAXV_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
MAXIMO_VECTOR ENDP                          ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: MINIMO_MAXIMO ======

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
