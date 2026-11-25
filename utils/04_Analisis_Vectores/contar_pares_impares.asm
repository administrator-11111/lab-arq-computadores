;==============================================================================
; ARCHIVO      : contar_pares_impares.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Implementa CONTAR_PARES y CONTAR_IMPARES para contar cuantos
;                elementos pares o impares hay en un vector de palabras (DW),
;                reutilizando los procedimientos canonicos ES_PAR y ES_IMPAR.
; FUNCIONAMIENTO:
;                Cada procedimiento recorre el vector con SI (avanzando de 2
;                en 2 bytes) y CX elementos. Usa DX como contador acumulado
;                (inicia en 0). Para cada elemento: carga AX = [SI], invoca
;                ES_PAR o ES_IMPAR (que devuelve BL = 1 si cumple, 0 si no) y
;                si BL = 1 incrementa DX. Al finalizar devuelve el total en AX.
;                Nota: el 0 se considera par porque su bit 0 es 0.
; REGISTROS    : CONTAR_PARES / CONTAR_IMPARES:
;                  Entrada : SI = offset del vector (DW), CX = cantidad
;                  Salida  : AX = cantidad de elementos pares / impares
;                  Modifica: AX y banderas (conserva BX, CX, DX, SI)
; VARIABLES    : Un vector DW en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimientos ES_PAR, ES_IMPAR y MOSTRAR_VECTOR
;                (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Copiar ES_PAR, ES_IMPAR y el bloque reutilizable en CODIGO
;                   despues de FIN_PROGRAMA.
;                3) Llamar con SI = OFFSET VECTOR y CX = N; resultado en AX.
; EJEMPLO      : Salida esperada:
;                  === CONTAR PARES E IMPARES EN UN VECTOR ===
;                  Vector : 0 3 8 15 22 41 100 7
;                  Pares  : 4
;                  Impares: 4
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
    VECTOR     DW 0, 3, 8, 15, 22, 41, 100, 7 ; 4 pares (0,8,22,100), 4 impares
    TAMANO     EQU 8                        ; cantidad de elementos

    MSG_TIT    DB '=== CONTAR PARES E IMPARES EN UN VECTOR ===$' ; titulo
    MSG_VEC    DB 'Vector : $'              ; etiqueta vector
    MSG_PAR    DB 'Pares  : $'              ; etiqueta pares
    MSG_IMP    DB 'Impares: $'              ; etiqueta impares
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_VEC                 ; etiqueta vector
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 8 elementos
    CALL MOSTRAR_VECTOR                     ; muestra los elementos
    SALTO_LINEA                             ; nueva linea

    CALL CONTAR_PARES                       ; AX = cantidad de pares (4)
    IMPRIMIR_CADENA MSG_PAR                 ; etiqueta pares
    IMPRIMIR_NUMERO AX                      ; muestra 4
    SALTO_LINEA                             ; nueva linea

    CALL CONTAR_IMPARES                     ; AX = cantidad de impares (4)
    IMPRIMIR_CADENA MSG_IMP                 ; etiqueta impares
    IMPRIMIR_NUMERO AX                      ; muestra 4
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: CONTAR_PARES_IMPARES ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_PARES
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : AX = cantidad de elementos pares en el vector.
;   Requiere: ES_PAR.
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
CONTAR_PARES PROC                           ; inicio del procedimiento
    PUSH BX                                 ; guarda BX (ES_PAR modifica BX)
    PUSH CX                                 ; guarda CX (contador del ciclo)
    PUSH DX                                 ; guarda DX (acumulador)
    PUSH SI                                 ; guarda SI (puntero al vector)
    XOR DX, DX                              ; contador de pares = 0
    CMP CX, 0                               ; vector vacio?
    JE CPAR_FIN                             ; si: devuelve 0
CPAR_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_PAR                             ; BL = 1 si es par, 0 si impar
    CMP BL, 1                               ; es par?
    JNE CPAR_SIG                            ; no: salta el incremento
    INC DX                                  ; si: cuenta un par mas
CPAR_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CPAR_CICLO                         ; repite CX veces
CPAR_FIN:                                   ; salida comun
    MOV AX, DX                              ; devuelve el conteo en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_PARES ENDP                           ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_IMPARES
;   Entrada : SI = offset del vector de palabras (DW), CX = cantidad
;   Salida  : AX = cantidad de elementos impares en el vector.
;   Requiere: ES_IMPAR.
;   Modifica: AX y banderas (conserva BX, CX, DX, SI).
;------------------------------------------------------------------------------
CONTAR_IMPARES PROC                         ; inicio del procedimiento
    PUSH BX                                 ; guarda BX (ES_IMPAR modifica BX)
    PUSH CX                                 ; guarda CX (contador del ciclo)
    PUSH DX                                 ; guarda DX (acumulador)
    PUSH SI                                 ; guarda SI (puntero al vector)
    XOR DX, DX                              ; contador de impares = 0
    CMP CX, 0                               ; vector vacio?
    JE CIMP_FIN                             ; si: devuelve 0
CIMP_CICLO:                                 ; recorre el vector
    MOV AX, [SI]                            ; AX = elemento actual
    CALL ES_IMPAR                           ; BL = 1 si es impar, 0 si par
    CMP BL, 1                               ; es impar?
    JNE CIMP_SIG                            ; no: salta el incremento
    INC DX                                  ; si: cuenta un impar mas
CIMP_SIG:                                   ; avanza al siguiente elemento
    ADD SI, 2                               ; siguiente palabra (2 bytes)
    LOOP CIMP_CICLO                         ; repite CX veces
CIMP_FIN:                                   ; salida comun
    MOV AX, DX                              ; devuelve el conteo en AX
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
CONTAR_IMPARES ENDP                         ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: CONTAR_PARES_IMPARES ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PAR
;   Entrada : AX = numero (sin signo, 0..65535)
;   Salida  : BL = 1 si es par, BL = 0 si es impar  (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero es par si su bit 0 vale 0. TEST AX,1 hace un AND
;             sin guardar el resultado y solo actualiza ZF.
;------------------------------------------------------------------------------
ES_PAR PROC                                 ; inicio del procedimiento
    MOV BX, 0                               ; supone "no es par"
    TEST AX, 1                              ; aisla el bit 0 (ZF=1 si es 0)
    JNZ EPAR_FIN                            ; bit 0 = 1: es impar, termina
    MOV BL, 1                               ; bit 0 = 0: es par
EPAR_FIN:                                   ; salida comun
    RET                                     ; vuelve al llamador
ES_PAR ENDP                                 ; fin del procedimiento

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
