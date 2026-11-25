;==============================================================================
; ARCHIVO      : divisores_y_suma_divisores.asm
; TIPO         : PROCEDIMIENTOS (+ programa de demostracion)
; DESCRIPCION  : Conjunto de procedimientos relacionados con divisores de un
;                numero de 16 bits sin signo:
;                - MOSTRAR_DIVISORES    : imprime todos los divisores de AX.
;                - CONTAR_DIVISORES     : cuenta cuantos divisores tiene AX.
;                - SUMA_DIVISORES_PROPIOS: suma los divisores menores que AX,
;                  con deteccion de desborde de 16 bits mediante la bandera CF.
;                NOTA: La version canonica de ES_PRIMO y ES_PERFECTO se
;                encuentra en utils/03_Clasificacion_Numeros/es_primo.asm y
;                utils/03_Clasificacion_Numeros/es_perfecto.asm. Esta demo
;                muestra como dichas propiedades se relacionan directamente con
;                la cantidad de divisores (= 2 -> primo) y con la suma de
;                divisores propios (= n -> perfecto).
; FUNCIONAMIENTO: Para comprobar si d divide a n se hace XOR DX, DX (limpia la
;                parte alta del dividendo DX:AX), luego DIV CX y se evalua si
;                el residuo DX es 0.
;                * MOSTRAR_DIVISORES y CONTAR_DIVISORES prueban d = 1..n (para
;                  n = 0 retornan sin dividir porque 0 tiene infinitos divisores).
;                * SUMA_DIVISORES_PROPIOS prueba d = 1..n/2 (calculado con
;                  SHR AX, 1), porque ningun divisor propio supera n/2. Tras
;                  ADD DI, CX revisa JC (CF = 1) para detectar desborde > 65535.
; REGISTROS    : MOSTRAR_DIVISORES:
;                  Entrada  : AX = n (1..65535)
;                  Salida   : imprime los divisores separados por espacio
;                  Modifica : banderas. Conserva AX, BX, CX, DX, SI.
;                CONTAR_DIVISORES:
;                  Entrada  : AX = n (0..65535)
;                  Salida   : CX = cantidad de divisores (0 si n = 0)
;                  Modifica : CX y banderas. Conserva AX, BX, DX, SI.
;                SUMA_DIVISORES_PROPIOS:
;                  Entrada  : AX = n (0..65535)
;                  Salida   : AX = suma de divisores propios (0 si desborde)
;                             BL = 1 si hubo desborde de 16 bits, 0 si no (BH=0)
;                  Modifica : AX, BX y banderas. Conserva CX, DX, SI, DI.
; VARIABLES    : Los procedimientos no requieren variables en DATOS.
; DEPENDENCIAS : MOSTRAR_DIVISORES requiere IMPRIMIR_NUMERO e IMPRIMIR_ESPACIO
;                de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm.
;                CONTAR_DIVISORES y SUMA_DIVISORES_PROPIOS no tienen dependencias.
; COMO INTEGRAR: Copiar las macros necesarias arriba de PILA y el bloque
;                reutilizable DIVISORES dentro de CODIGO despues de la salida
;                a DOS. Cargar n en AX y llamar con CALL al procedimiento.
; EJEMPLO      : Prueba 1, 2, 6, 12, 17, 28, 36, 496:
;                  n=6 | Divisores: 1 2 3 6 | Cant: 4 | Suma propios: 6 [PERFECTO]
;                  n=17 | Divisores: 1 17 | Cant: 2 [PRIMO] | Suma propios: 1
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
    MSG_TITULO DB '=== DEMO: DIVISORES Y SUMA DE DIVISORES PROPIOS ===$' ; titulo
    MSG_N      DB 'n = $'                   ; etiqueta del numero
    MSG_DIVS   DB ' | Divisores: $'         ; etiqueta de lista de divisores
    MSG_CANT   DB ' | Cant: $'              ; etiqueta de cantidad
    MSG_SUMA   DB ' | Suma propios: $'      ; etiqueta de suma de propios
    MSG_PRIMO  DB ' [PRIMO]$'               ; aviso cuando cantidad == 2
    MSG_PERF   DB ' [PERFECTO]$'            ; aviso cuando suma == n
    MSG_DESB   DB ' (DESBORDE 16b)$'        ; aviso cuando CF = 1
    PRUEBAS    DW 1, 2, 6, 12, 17, 28, 36, 496 ; casos de prueba
    CANT_PRU   DW 8                         ; cantidad de pruebas
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET PRUEBAS                  ; SI apunta al primer numero
    MOV CX, CANT_PRU                        ; CX = cantidad de pruebas
DEMO_CICLO:                                 ; recorre cada prueba
    PUSH CX                                 ; guarda contador del ciclo
    MOV AX, [SI]                            ; AX = numero n actual

    IMPRIMIR_CADENA MSG_N                   ; muestra "n = "
    IMPRIMIR_NUMERO AX                      ; muestra n
    IMPRIMIR_CADENA MSG_DIVS                ; muestra " | Divisores: "
    CALL MOSTRAR_DIVISORES                  ; imprime todos los divisores de n

    CALL CONTAR_DIVISORES                   ; CX = cantidad de divisores
    IMPRIMIR_CADENA MSG_CANT                ; muestra " | Cant: "
    IMPRIMIR_NUMERO CX                      ; muestra la cantidad
    CMP CX, 2                               ; exactamente 2 divisores?
    JNE DEMO_NO_PRIMO                       ; no: no es primo
    IMPRIMIR_CADENA MSG_PRIMO               ; si: un numero con 2 div es primo
DEMO_NO_PRIMO:                              ; continua con suma de propios
    PUSH AX                                 ; guarda n para comparar luego
    CALL SUMA_DIVISORES_PROPIOS             ; AX = suma, BL = 1 si desborde
    IMPRIMIR_CADENA MSG_SUMA                ; muestra " | Suma propios: "
    CMP BL, 1                               ; hubo desborde de 16 bits?
    JE DEMO_DESB                            ; si: informa desborde
    IMPRIMIR_NUMERO AX                      ; muestra la suma calculada
    POP DX                                  ; DX = n original
    CMP DX, 2                               ; n < 2 no puede ser perfecto
    JB DEMO_SIG                             ; si: salta comparacion
    CMP AX, DX                              ; suma de propios == n?
    JNE DEMO_SIG                            ; no: no es perfecto
    IMPRIMIR_CADENA MSG_PERF                ; si: es numero perfecto
    JMP DEMO_SIG                            ; fin del caso actual
DEMO_DESB:                                  ; rama cuando hubo desborde
    POP DX                                  ; equilibra la pila (n original)
    IMPRIMIR_CADENA MSG_DESB                ; muestra aviso de desborde
DEMO_SIG:                                   ; cierre de la iteracion
    SALTO_LINEA                             ; nueva linea
    ADD SI, 2                               ; siguiente palabra DW
    POP CX                                  ; recupera contador de pruebas
    DEC CX                                  ; decrementa contador (evita LOOP
    JNZ DEMO_CICLO_SALTO                    ; lejos por macros expandidas)
    JMP DEMO_FIN                            ; termino todas las pruebas
DEMO_CICLO_SALTO:                           ; puente de salto largo (8086)
    JMP DEMO_CICLO                          ; vuelve al inicio del ciclo
DEMO_FIN:                                   ; fin de la demostracion
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: DIVISORES ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO MOSTRAR_DIVISORES
;   Entrada : AX = numero sin signo n (1..65535; si n=0 no muestra nada)
;   Salida  : muestra todos los divisores de n separados por espacio.
;   Requiere: macros IMPRIMIR_NUMERO e IMPRIMIR_ESPACIO.
;   Modifica: banderas. Conserva AX, BX, CX, DX, SI.
;------------------------------------------------------------------------------
MOSTRAR_DIVISORES PROC                      ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    CMP AX, 0                               ; n == 0?
    JE MDIV_FIN                             ; 0 tiene infinitos divisores
    MOV SI, AX                              ; SI = n
    MOV CX, 1                               ; d = 1 (primer divisor)
MDIV_CICLO:                                 ; prueba d = 1..n
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; d divide a n?
    JNE MDIV_SIG                            ; no: prueba siguiente
    IMPRIMIR_NUMERO CX                      ; si: muestra el divisor d
    IMPRIMIR_ESPACIO                        ; separador
MDIV_SIG:                                   ; avanza al siguiente candidato
    CMP CX, SI                              ; ya llego a d == n?
    JE MDIV_FIN                             ; si: evita desborde si n=65535
    INC CX                                  ; d = d + 1
    JMP MDIV_CICLO                          ; repite
MDIV_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
MOSTRAR_DIVISORES ENDP                      ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_DIVISORES
;   Entrada : AX = numero sin signo n (0..65535)
;   Salida  : CX = cantidad de divisores de n (0 si n = 0)
;   Modifica: CX y banderas. Conserva AX, BX, DX, SI.
;------------------------------------------------------------------------------
CONTAR_DIVISORES PROC                       ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    XOR CX, CX                              ; contador de divisores = 0
    CMP AX, 0                               ; n == 0?
    JE CDIV_FIN                             ; si: devuelve 0
    MOV SI, AX                              ; SI = n
    MOV BX, 1                               ; d = 1
CDIV_CICLO:                                 ; prueba d = 1..n
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    DIV BX                                  ; DX = n mod d
    CMP DX, 0                               ; d divide a n?
    JNE CDIV_SIG                            ; no: siguiente
    INC CX                                  ; si: cuenta un divisor mas
CDIV_SIG:                                   ; avanza al siguiente candidato
    CMP BX, SI                              ; ya llego a d == n?
    JE CDIV_FIN                             ; si: termina (seguro para 65535)
    INC BX                                  ; d = d + 1
    JMP CDIV_CICLO                          ; repite
CDIV_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
CONTAR_DIVISORES ENDP                       ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO SUMA_DIVISORES_PROPIOS
;   Entrada : AX = numero sin signo n (0..65535)
;   Salida  : AX = suma de divisores propios (menores que n), o 0 si desborde
;             BL = 1 si hubo desborde de 16 bits (CF=1), BL = 0 si no (BH = 0)
;   Modifica: AX, BX y banderas. Conserva CX, DX, SI, DI.
;------------------------------------------------------------------------------
SUMA_DIVISORES_PROPIOS PROC                 ; inicio del procedimiento
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    PUSH DI                                 ; guarda DI (acumulador de suma)
    MOV BX, 0                               ; supone sin desborde (BH=0, BL=0)
    XOR DI, DI                              ; suma = 0
    CMP AX, 2                               ; n < 2?
    JB SDIV_OK                              ; 0 y 1 no tienen divisores propios
    MOV SI, AX                              ; SI = n
    MOV CX, 1                               ; d = 1
SDIV_CICLO:                                 ; prueba d = 1..n/2
    MOV AX, SI                              ; AX = n
    SHR AX, 1                               ; AX = n / 2 (limite de propios)
    CMP CX, AX                              ; d > n/2?
    JA SDIV_OK                              ; si: termino la busqueda
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; d divide a n?
    JNE SDIV_SIG                            ; no: siguiente divisor
    ADD DI, CX                              ; suma += d
    JC SDIV_DESBORDE                        ; CF=1: la suma supero 65535
SDIV_SIG:                                   ; avanza al siguiente candidato
    INC CX                                  ; d = d + 1
    JMP SDIV_CICLO                          ; repite
SDIV_DESBORDE:                              ; ocurrio desborde de 16 bits
    MOV AX, 0                               ; devuelve 0 por desborde
    MOV BL, 1                               ; activa bandera de desborde
    JMP SDIV_FIN                            ; salta a restaurar registros
SDIV_OK:                                    ; termino sin desborde
    MOV AX, DI                              ; AX = suma de divisores propios
SDIV_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    RET                                     ; vuelve al llamador
SUMA_DIVISORES_PROPIOS ENDP                 ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: DIVISORES ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
