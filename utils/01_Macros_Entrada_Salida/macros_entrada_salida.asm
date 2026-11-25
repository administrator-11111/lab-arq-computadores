;==============================================================================
; ARCHIVO     : macros_entrada_salida.asm
; TIPO        : MACROS (biblioteca reutilizable) + programa de demostracion
; DESCRIPCION : Coleccion de macros de entrada/salida por consola usando las
;               interrupciones de DOS (INT 21h) y del BIOS de video (INT 10h).
;               Es la VERSION DE REFERENCIA de las macros de E/S: los demas
;               archivos de la biblioteca copian desde aqui las que necesitan.
;
; MACROS DISPONIBLES
;   IMPRIMIR_CARACTER car   -> muestra un caracter (INT 21h, AH=02h)
;   IMPRIMIR_CADENA cad     -> muestra una cadena terminada en '$' (AH=09h)
;   IMPRIMIR_NUMERO val     -> muestra un numero de 16 bits sin signo (0..65535)
;   SALTO_LINEA             -> muestra retorno de carro + avance de linea
;   TABULACION              -> muestra un caracter de tabulacion (ASCII 9)
;   IMPRIMIR_ESPACIO        -> muestra un espacio en blanco
;   LEER_CARACTER           -> lee una tecla con eco, queda en AL
;   LEER_DIGITO             -> lee una tecla '0'..'9' y deja su VALOR en AX
;   LEER_NUMERO             -> lee un numero de varias cifras, queda en AX
;   ASCII_A_NUMERO reg8     -> convierte '0'..'9' en 0..9 (resta 30h)
;   NUMERO_A_ASCII reg8     -> convierte 0..9 en '0'..'9' (suma 30h)
;   LIMPIAR_PANTALLA        -> borra la pantalla (modo texto 80x25)
;   FIN_PROGRAMA            -> devuelve el control a DOS (AH=4Ch)
;
; IDEAS CLAVE DEL 8086
;   * INT 21h es el "menu" de servicios de DOS: el numero de servicio se pone
;     en AH antes de ejecutar la interrupcion.
;   * AH=09h necesita que DS apunte al segmento de datos y DX al OFFSET de la
;     cadena; por eso al inicio del programa se hace MOV AX,DATOS / MOV DS,AX.
;   * Para mostrar un numero hay que separarlo en cifras (dividiendo por 10)
;     y convertir cada cifra a ASCII sumando 30h ('0').
;   * Las macros guardan (PUSH) y restauran (POP) los registros que usan para
;     no "romper" los valores del programa que las invoca. Las que devuelven
;     un resultado en AX/AL, obviamente, si modifican ese registro.
;   * Las etiquetas internas se declaran con LOCAL para que la macro pueda
;     usarse muchas veces sin generar etiquetas duplicadas.
;
; COMO INTEGRARLAS EN UN PROGRAMA
;   1. Copiar las macros necesarias al inicio del archivo (antes de PILA).
;   2. Inicializar DS en INICIO (MOV AX,DATOS / MOV DS,AX).
;   3. Invocarlas por su nombre, por ejemplo:  IMPRIMIR_CADENA MSG_HOLA
;
; DEPENDENCIAS: ninguna (solo DOS / BIOS).
; NOTA: los textos estan sin tildes porque la consola de DOS/EMU8086 no
;       muestra correctamente los caracteres acentuados.
;==============================================================================

;//// macros

;------------------------------------------------------------------------------
; MACRO IMPRIMIR_CARACTER car
;   Que hace  : muestra en pantalla UN caracter.
;   Parametro : car = caracter inmediato ('A', 13, 9...), registro de 8 bits
;               o variable de tipo byte (DB).
;   Usa       : AH (servicio 02h) y DL (caracter a mostrar).
;   Modifica  : ningun registro (AX y DX se guardan y restauran).
;   Ejemplo   : IMPRIMIR_CARACTER 'A'        IMPRIMIR_CARACTER BL
;------------------------------------------------------------------------------
IMPRIMIR_CARACTER MACRO car                 ; inicio de la macro, recibe car
    PUSH AX                                 ; guarda AX porque se usara AH
    PUSH DX                                 ; guarda DX porque se usara DL
    MOV DL, car                             ; DL = caracter que DOS mostrara
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    INT 21h                                 ; DOS muestra el caracter de DL
    POP DX                                  ; recupera DX original
    POP AX                                  ; recupera AX original
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO IMPRIMIR_CADENA cad
;   Que hace  : muestra una cadena almacenada en DATOS que termina en '$'.
;   Parametro : cad = nombre de la variable (ej. MSG DB 'Hola$').
;   Usa       : AH (servicio 09h) y DX (offset de la cadena). Requiere DS ok.
;   Modifica  : ningun registro (AX y DX se guardan y restauran).
;   Ejemplo   : IMPRIMIR_CADENA MSG_TITULO
;------------------------------------------------------------------------------
IMPRIMIR_CADENA MACRO cad                   ; inicio de la macro, recibe cad
    PUSH AX                                 ; guarda AX porque se usara AH
    PUSH DX                                 ; guarda DX porque se usara DX
    LEA DX, cad                             ; DX = direccion (offset) de cad
    MOV AH, 09h                             ; servicio 09h: escribir cadena$
    INT 21h                                 ; DOS muestra hasta encontrar '$'
    POP DX                                  ; recupera DX original
    POP AX                                  ; recupera AX original
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO IMPRIMIR_NUMERO val
;   Que hace  : muestra un numero entero SIN signo de 16 bits (0 a 65535).
;   Parametro : val = registro de 16 bits, variable DW o valor inmediato.
;               (Para una variable DB primero copiarla a AX: MOV AL,var /
;               MOV AH,0 / IMPRIMIR_NUMERO AX).
;   Metodo    : divide sucesivamente por 10. Cada residuo es una cifra (de
;               derecha a izquierda), por eso se apilan con PUSH y luego se
;               sacan con POP para mostrarlas en el orden correcto.
;   Usa       : AX, BX, CX, DX internamente.
;   Modifica  : ningun registro (todos se guardan y restauran).
;   Ejemplo   : IMPRIMIR_NUMERO SUMA        IMPRIMIR_NUMERO AX
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; MACRO SALTO_LINEA
;   Que hace  : baja el cursor al inicio de la linea siguiente.
;   Metodo    : muestra CR (13, vuelve a la columna 0) y LF (10, baja una
;               linea). DOS necesita ambos caracteres.
;   Modifica  : ningun registro.
;   Ejemplo   : SALTO_LINEA
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; MACRO TABULACION
;   Que hace  : muestra el caracter de tabulacion (ASCII 9) para alinear
;               columnas. Si tu consola lo muestra como simbolo, usa varias
;               veces IMPRIMIR_ESPACIO.
;   Modifica  : ningun registro.
;   Ejemplo   : TABULACION
;------------------------------------------------------------------------------
TABULACION MACRO                            ; macro sin parametros
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV DL, 9                               ; 9 = tabulacion horizontal
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    INT 21h                                 ; muestra la tabulacion
    POP DX                                  ; restaura DX
    POP AX                                  ; restaura AX
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO IMPRIMIR_ESPACIO
;   Que hace  : muestra un espacio en blanco (separador de valores).
;   Modifica  : ningun registro.
;   Ejemplo   : IMPRIMIR_ESPACIO
;------------------------------------------------------------------------------
IMPRIMIR_ESPACIO MACRO                      ; macro sin parametros
    PUSH AX                                 ; guarda AX
    PUSH DX                                 ; guarda DX
    MOV DL, ' '                             ; caracter espacio (20h)
    MOV AH, 02h                             ; servicio 02h: escribir caracter
    INT 21h                                 ; muestra el espacio
    POP DX                                  ; restaura DX
    POP AX                                  ; restaura AX
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO LEER_CARACTER
;   Que hace  : espera una tecla y la muestra (eco) en pantalla.
;   Salida    : AL = codigo ASCII de la tecla (Enter = 13).
;   Modifica  : AX (AH queda con 01h, AL con la tecla).
;   Ejemplo   : LEER_CARACTER  /  MOV OPCION, AL
;------------------------------------------------------------------------------
LEER_CARACTER MACRO                         ; macro sin parametros
    MOV AH, 01h                             ; servicio 01h: leer tecla + eco
    INT 21h                                 ; DOS espera la tecla, AL = ASCII
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO LEER_DIGITO
;   Que hace  : lee teclas hasta que se presione un digito '0'..'9'
;               (las demas teclas se ignoran) y entrega su VALOR numerico.
;   Salida    : AX = valor 0..9 (AH = 0, AL = digito).
;   Modifica  : AX.
;   Ejemplo   : LEER_DIGITO  /  MOV VECTOR[SI], AX
;------------------------------------------------------------------------------
LEER_DIGITO MACRO                           ; macro sin parametros
    LOCAL LD_LEER                           ; etiqueta unica por cada uso
LD_LEER:                                    ; punto de reintento
    MOV AH, 01h                             ; servicio 01h: leer tecla + eco
    INT 21h                                 ; AL = codigo ASCII leido
    CMP AL, '0'                             ; compara con el ASCII de 0 (30h)
    JB LD_LEER                              ; menor que '0': no es digito
    CMP AL, '9'                             ; compara con el ASCII de 9 (39h)
    JA LD_LEER                              ; mayor que '9': no es digito
    SUB AL, '0'                             ; ASCII -> valor (ej. '7'-> 7)
    MOV AH, 0                               ; AX = valor completo de 16 bits
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO LEER_NUMERO
;   Que hace  : lee un numero decimal de varias cifras terminado con Enter.
;               Ignora las teclas que no son digitos.
;   Metodo    : acumulado = acumulado * 10 + cifra   (por cada tecla).
;   Salida    : AX = numero leido (0..65535; si se excede, se pierde el
;               acarreo porque el 8086 trabaja con 16 bits).
;   Usa       : AX, BX (acumulado), CX (cifra), DX (parte alta de MUL).
;   Modifica  : solo AX (BX, CX y DX se restauran).
;   Ejemplo   : LEER_NUMERO  /  MOV N, AX
;------------------------------------------------------------------------------
LEER_NUMERO MACRO                           ; macro sin parametros
    LOCAL LN_LEER, LN_FIN                   ; etiquetas unicas por cada uso
    PUSH BX                                 ; guarda BX (acumulador)
    PUSH CX                                 ; guarda CX (cifra)
    PUSH DX                                 ; guarda DX (MUL lo modifica)
    XOR BX, BX                              ; acumulado = 0
LN_LEER:                                    ; ciclo de lectura de teclas
    MOV AH, 01h                             ; servicio 01h: leer tecla + eco
    INT 21h                                 ; AL = tecla presionada
    CMP AL, 13                              ; es Enter (retorno de carro)?
    JE LN_FIN                               ; si: termina la lectura
    CMP AL, '0'                             ; menor que el ASCII '0'?
    JB LN_LEER                              ; no es digito: lo ignora
    CMP AL, '9'                             ; mayor que el ASCII '9'?
    JA LN_LEER                              ; no es digito: lo ignora
    SUB AL, '0'                             ; convierte ASCII a valor 0..9
    MOV CL, AL                              ; CL = cifra leida
    MOV CH, 0                               ; CX = cifra en 16 bits
    MOV AX, BX                              ; AX = acumulado actual
    MOV DX, 10                              ; DX = multiplicador 10
    MUL DX                                  ; DX:AX = acumulado * 10
    ADD AX, CX                              ; suma la nueva cifra
    MOV BX, AX                              ; guarda el nuevo acumulado
    JMP LN_LEER                             ; lee la siguiente tecla
LN_FIN:                                     ; se presiono Enter
    MOV AX, BX                              ; AX = numero leido (resultado)
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP BX                                  ; restaura BX
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO ASCII_A_NUMERO reg8
;   Que hace  : convierte el caracter '0'..'9' guardado en un registro de 8
;               bits en su valor 0..9. ('5' = 35h, 35h - 30h = 5).
;   Parametro : reg8 = AL, BL, CL, DL, etc.
;   Modifica  : solo el registro recibido (y las banderas).
;   Ejemplo   : LEER_CARACTER  /  ASCII_A_NUMERO AL
;------------------------------------------------------------------------------
ASCII_A_NUMERO MACRO reg8                   ; inicio de la macro, recibe reg8
    SUB reg8, 30h                           ; resta el ASCII de '0'
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO NUMERO_A_ASCII reg8
;   Que hace  : convierte un valor 0..9 en su caracter '0'..'9' (suma 30h).
;   Parametro : reg8 = registro de 8 bits con un valor entre 0 y 9.
;   Modifica  : solo el registro recibido (y las banderas).
;   Ejemplo   : MOV DL,7  /  NUMERO_A_ASCII DL  /  IMPRIMIR_CARACTER DL
;------------------------------------------------------------------------------
NUMERO_A_ASCII MACRO reg8                   ; inicio de la macro, recibe reg8
    ADD reg8, 30h                           ; suma el ASCII de '0'
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO LIMPIAR_PANTALLA
;   Que hace  : borra la pantalla reestableciendo el modo de video texto
;               80x25 a color (modo 03h) con el BIOS (INT 10h, AH=00h).
;   Modifica  : ningun registro.
;   Ejemplo   : LIMPIAR_PANTALLA
;------------------------------------------------------------------------------
LIMPIAR_PANTALLA MACRO                      ; macro sin parametros
    PUSH AX                                 ; guarda AX
    MOV AH, 00h                             ; servicio 00h: fijar modo video
    MOV AL, 03h                             ; modo 03h: texto 80x25 color
    INT 10h                                 ; el BIOS reinicia y limpia
    POP AX                                  ; restaura AX
ENDM                                        ; fin de la macro

;------------------------------------------------------------------------------
; MACRO FIN_PROGRAMA
;   Que hace  : termina el programa y vuelve a DOS con codigo 0.
;   Ejemplo   : FIN_PROGRAMA   (ultima instruccion ejecutada)
;------------------------------------------------------------------------------
FIN_PROGRAMA MACRO                          ; macro sin parametros
    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; DOS finaliza el programa
ENDM                                        ; fin de la macro

;==============================================================================
; PROGRAMA DE DEMOSTRACION
; Ejemplo de ejecucion:
;   === DEMO DE MACROS DE E/S ===
;   Caracter: A
;   Numero  : 12345
;   Columnas: 10<TAB>20<TAB>30
;   Ingrese un numero y Enter: 250
;   El doble es: 500
;   Ingrese un digito (0-9): 7
;   Digito convertido a ASCII y mostrado: 7
;==============================================================================

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MSG_TITULO DB '=== DEMO DE MACROS DE E/S ===$'      ; titulo
    MSG_CAR    DB 'Caracter: $'             ; texto previo al caracter
    MSG_NUM    DB 'Numero  : $'             ; texto previo al numero
    MSG_COL    DB 'Columnas: $'             ; texto previo a las columnas
    MSG_PEDIR  DB 'Ingrese un numero y Enter: $'        ; pide un numero
    MSG_DOBLE  DB 'El doble es: $'          ; texto del resultado
    MSG_DIG    DB 'Ingrese un digito (0-9): $'          ; pide un digito
    MSG_ASCII  DB 'Digito convertido a ASCII y mostrado: $'  ; resultado
    NUMERO     DW 12345                     ; numero de prueba de 16 bits
    LEIDO      DW 0                         ; guarda el numero ingresado
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del seg. DATOS
    MOV DS, AX                              ; DS apunta a DATOS (no hay MOV
                                            ; directo de inmediato a DS)
    LIMPIAR_PANTALLA                        ; borra la pantalla
    IMPRIMIR_CADENA MSG_TITULO              ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_CAR                 ; muestra "Caracter: "
    IMPRIMIR_CARACTER 'A'                   ; muestra la letra A
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_NUM                 ; muestra "Numero  : "
    IMPRIMIR_NUMERO NUMERO                  ; muestra 12345 desde memoria
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_COL                 ; muestra "Columnas: "
    IMPRIMIR_NUMERO 10                      ; muestra un valor inmediato
    TABULACION                              ; separa con tabulacion
    IMPRIMIR_NUMERO 20                      ; segundo valor
    TABULACION                              ; separa con tabulacion
    IMPRIMIR_NUMERO 30                      ; tercer valor
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PEDIR               ; pide un numero de varias cifras
    LEER_NUMERO                             ; AX = numero ingresado
    MOV LEIDO, AX                           ; lo guarda en memoria
    SALTO_LINEA                             ; nueva linea tras el Enter
    IMPRIMIR_CADENA MSG_DOBLE               ; muestra "El doble es: "
    MOV AX, LEIDO                           ; AX = numero ingresado
    ADD AX, AX                              ; AX = AX * 2 (suma consigo mismo)
    IMPRIMIR_NUMERO AX                      ; muestra el doble
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_DIG                 ; pide un digito
    LEER_DIGITO                             ; AX = valor 0..9
    MOV BL, AL                              ; BL = valor numerico del digito
    SALTO_LINEA                             ; nueva linea
    IMPRIMIR_CADENA MSG_ASCII               ; texto del resultado
    NUMERO_A_ASCII BL                       ; BL = caracter '0'..'9'
    IMPRIMIR_CARACTER BL                    ; muestra el caracter
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS
CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
