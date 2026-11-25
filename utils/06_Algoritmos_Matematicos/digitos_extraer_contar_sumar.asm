;==============================================================================
; ARCHIVO      : digitos_extraer_contar_sumar.asm
; TIPO         : PROCEDIMIENTOS (+ programa de demostracion)
; DESCRIPCION  : Tres procedimientos para trabajar con las cifras decimales de
;                un numero entero de 16 bits sin signo (0..65535):
;                - EXTRAER_DIGITOS: guarda las cifras en un vector de palabras
;                  (DW) en orden de izquierda a derecha y devuelve la cantidad.
;                - CONTAR_DIGITOS : devuelve cuantas cifras decimales tiene AX.
;                - SUMAR_DIGITOS  : devuelve la suma de las cifras de AX.
; FUNCIONAMIENTO: En 8086, dividir sucesivamente por 10 (XOR DX,DX + DIV BX)
;                entrega las cifras como residuos en DX desde la menos
;                significativa (unidades) hasta la mas significativa.
;                * CONTAR_DIGITOS cuenta cuantas divisiones se necesitan hasta
;                  que el cociente AX llegue a 0 (para AX=0 realiza una
;                  iteracion y devuelve 1).
;                * SUMAR_DIGITOS acumula cada residuo DX en un registro. Como
;                  el mayor numero de 16 bits es 65535, la suma maxima es
;                  5+9+9+9+9 = 41 (para 59999), imposible que desborde 16 bits.
;                * EXTRAER_DIGITOS apila cada residuo con PUSH DX y luego los
;                  desapila con POP DX guardandolos en el vector [DI], asi
;                  quedan ordenados de izquierda a derecha (maximo 5 cifras).
; REGISTROS    : EXTRAER_DIGITOS:
;                  Entrada  : AX = numero (0..65535), DI = offset vector DW
;                             (con espacio para al menos 5 palabras)
;                  Salida   : CX = cantidad de cifras guardadas (1..5)
;                  Modifica : CX y banderas. Conserva AX, BX, DX, SI, DI.
;                CONTAR_DIGITOS:
;                  Entrada  : AX = numero (0..65535)
;                  Salida   : CX = cantidad de cifras (1..5)
;                  Modifica : CX y banderas. Conserva AX, BX, DX.
;                SUMAR_DIGITOS:
;                  Entrada  : AX = numero (0..65535)
;                  Salida   : AX = suma de las cifras (0..41)
;                  Modifica : AX y banderas. Conserva BX, CX, DX.
; VARIABLES    : Los procedimientos no requieren variables globales fijas;
;                EXTRAER_DIGITOS escribe en el vector apuntado por DI.
; DEPENDENCIAS : Ninguna para los tres procedimientos de digitos.
;                La demo usa IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO
;                y SALTO_LINEA de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm
;                y MOSTRAR_VECTOR (procedimiento canonico).
; COMO INTEGRAR: 1) Copiar los bloques reutilizables deseados dentro de CODIGO
;                   despues de la salida a DOS.
;                2) Para EXTRAER_DIGITOS, declarar un vector de 5 palabras en
;                   DATOS (ej. DIGITOS DW 5 DUP(0)), cargar AX y DI, y llamar.
; EJEMPLO      : Prueba 0, 7, 1234, 59999, 65535:
;                  Numero: 0 | Cantidad: 1 | Suma: 0 | Digitos: 0
;                  Numero: 7 | Cantidad: 1 | Suma: 7 | Digitos: 7
;                  Numero: 1234 | Cantidad: 4 | Suma: 10 | Digitos: 1 2 3 4
;                  Numero: 59999 | Cantidad: 5 | Suma: 41 | Digitos: 5 9 9 9 9
;                  Numero: 65535 | Cantidad: 5 | Suma: 24 | Digitos: 6 5 5 3 5
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
    MSG_TITULO DB '=== DEMO: DIGITOS (EXTRAER, CONTAR, SUMAR) ===$' ; titulo
    MSG_NUM    DB 'Numero: $'               ; etiqueta del numero
    MSG_CANT   DB ' | Cantidad: $'          ; etiqueta de cantidad de cifras
    MSG_SUMA   DB ' | Suma: $'              ; etiqueta de suma de cifras
    MSG_DIG    DB ' | Digitos: $'           ; etiqueta del vector de digitos
    PRUEBAS    DW 0, 7, 1234, 59999, 65535  ; casos de prueba (0..65535)
    CANT_PRU   DW 5                         ; cantidad de pruebas
    DIGITOS    DW 5 DUP(0)                  ; buffer para hasta 5 cifras DW
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo de la demo
    SALTO_LINEA                             ; nueva linea

    MOV SI, OFFSET PRUEBAS                  ; SI apunta al primer numero
    MOV CX, CANT_PRU                        ; CX = cantidad de pruebas
DEMO_CICLO:                                 ; recorre cada numero de prueba
    PUSH CX                                 ; guarda contador del ciclo
    MOV AX, [SI]                            ; AX = numero actual

    IMPRIMIR_CADENA MSG_NUM                 ; muestra "Numero: "
    IMPRIMIR_NUMERO AX                      ; muestra el valor evaluado

    CALL CONTAR_DIGITOS                     ; CX = cantidad de cifras de AX
    IMPRIMIR_CADENA MSG_CANT                ; muestra " | Cantidad: "
    IMPRIMIR_NUMERO CX                      ; muestra la cantidad

    PUSH AX                                 ; guarda AX (SUMAR_DIGITOS lo pisa)
    CALL SUMAR_DIGITOS                      ; AX = suma de las cifras
    IMPRIMIR_CADENA MSG_SUMA                ; muestra " | Suma: "
    IMPRIMIR_NUMERO AX                      ; muestra la suma
    POP AX                                  ; recupera el numero original

    MOV DI, OFFSET DIGITOS                  ; DI apunta al vector destino
    CALL EXTRAER_DIGITOS                    ; llena DIGITOS, CX = cantidad
    IMPRIMIR_CADENA MSG_DIG                 ; muestra " | Digitos: "
    PUSH SI                                 ; guarda puntero de PRUEBAS
    MOV SI, OFFSET DIGITOS                  ; SI apunta al vector de digitos
    CALL MOSTRAR_VECTOR                     ; muestra las CX cifras extraidas
    POP SI                                  ; recupera puntero de PRUEBAS

    SALTO_LINEA                             ; baja a la linea siguiente
    ADD SI, 2                               ; avanza al siguiente DW
    POP CX                                  ; recupera contador de pruebas
    DEC CX                                  ; decrementa contador (evita LOOP
    JZ DEMO_FIN                             ; fuera de rango de +-127 bytes
    JMP DEMO_CICLO                          ; por las macros expandidas)
DEMO_FIN:                                   ; fin de la demostracion

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;====== INICIO BLOQUE REUTILIZABLE: DIGITOS ======
;------------------------------------------------------------------------------
; PROCEDIMIENTO EXTRAER_DIGITOS
;   Entrada : AX = numero (0..65535), DI = offset del vector destino (DW, >=5)
;   Salida  : CX = cantidad de cifras almacenadas (1..5), orden izq -> der
;   Modifica: CX y banderas. Conserva AX, BX, DX, SI, DI.
;------------------------------------------------------------------------------
EXTRAER_DIGITOS PROC                        ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (se divide por 10)
    PUSH BX                                 ; guarda BX (divisor / contador)
    PUSH DX                                 ; guarda DX (residuo = cifra)
    PUSH DI                                 ; guarda DI (puntero destino)
    MOV BX, 10                              ; BX = base decimal 10
    XOR CX, CX                              ; CX = 0 cifras apiladas
EXD_APILAR:                                 ; separa cifras de der a izq
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    DIV BX                                  ; AX = cociente, DX = cifra (0..9)
    PUSH DX                                 ; apila la cifra para invertir orden
    INC CX                                  ; incrementa el contador de cifras
    CMP AX, 0                               ; quedan mas cifras por separar?
    JNE EXD_APILAR                          ; si: continua dividiendo
    MOV BX, CX                              ; BX = copia de cantidad para el loop
EXD_GUARDAR:                                ; desapila en orden izq -> der
    POP DX                                  ; recupera cifra mas significativa
    MOV [DI], DX                            ; guarda cifra como palabra (DW)
    ADD DI, 2                               ; avanza a la siguiente palabra
    DEC BX                                  ; una cifra menos por guardar
    JNZ EXD_GUARDAR                         ; repite hasta vaciar las cifras
    POP DI                                  ; restaura DI original
    POP DX                                  ; restaura DX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador (CX = cantidad)
EXTRAER_DIGITOS ENDP                        ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO CONTAR_DIGITOS
;   Entrada : AX = numero (0..65535)
;   Salida  : CX = cantidad de cifras decimales (1..5; para 0 devuelve 1)
;   Modifica: CX y banderas. Conserva AX, BX, DX.
;------------------------------------------------------------------------------
CONTAR_DIGITOS PROC                         ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH BX                                 ; guarda BX
    PUSH DX                                 ; guarda DX
    MOV BX, 10                              ; BX = divisor 10
    XOR CX, CX                              ; CX = 0 cifras contadas
CND_CICLO:                                  ; divide hasta que AX sea 0
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    DIV BX                                  ; AX = AX / 10
    INC CX                                  ; cuenta una cifra
    CMP AX, 0                               ; quedan cifras?
    JNE CND_CICLO                           ; si: sigue dividiendo
    POP DX                                  ; restaura DX
    POP BX                                  ; restaura BX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
CONTAR_DIGITOS ENDP                         ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO SUMAR_DIGITOS
;   Entrada : AX = numero (0..65535)
;   Salida  : AX = suma de sus cifras decimales (0..41)
;   Modifica: AX y banderas. Conserva BX, CX, DX.
;------------------------------------------------------------------------------
SUMAR_DIGITOS PROC                          ; inicio del procedimiento
    PUSH BX                                 ; guarda BX (divisor 10)
    PUSH CX                                 ; guarda CX (acumulador de suma)
    PUSH DX                                 ; guarda DX (residuo = cifra)
    MOV BX, 10                              ; BX = divisor 10
    XOR CX, CX                              ; CX = suma acumulada = 0
SMD_CICLO:                                  ; extrae y suma cada cifra
    XOR DX, DX                              ; DX = 0 para dividir DX:AX
    DIV BX                                  ; AX = cociente, DX = cifra (0..9)
    ADD CX, DX                              ; suma += cifra
    CMP AX, 0                               ; quedan cifras?
    JNE SMD_CICLO                           ; si: sigue sumando
    MOV AX, CX                              ; AX = resultado final de la suma
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
    RET                                     ; vuelve al llamador
SUMAR_DIGITOS ENDP                          ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: DIGITOS ======

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
