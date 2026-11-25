;==============================================================================
; ARCHIVO      : clasificar_numero_completo.asm
; TIPO         : ALGORITMO (+ programa de demostracion interactivo)
; DESCRIPCION  : Lee un numero entero sin signo (0..65535) por teclado y lo
;                clasifica segun seis propiedades: par, impar, primo, perfecto,
;                raiz cuadrada exacta y narcisista.
; FUNCIONAMIENTO: Usa la macro LEER_NUMERO para capturar el valor en AX y lo
;                guarda en NUMERO. Luego invoca uno por uno los seis
;                procedimientos canonicos de clasificacion (todos reciben AX y
;                devuelven BL=1 si cumple o BL=0 si no, conservando AX) y
;                muestra SI o NO para cada propiedad usando IMPRIMIR_SI_NO.
; REGISTROS    : AX = numero a clasificar (conservado por los 6 procedimientos)
;                BL = resultado booleano (1 = SI, 0 = NO), BH = 0.
; VARIABLES    : NUMERO DW 0 para almacenar el valor ingresado.
;                Cadenas de mensajes en DATOS para etiquetas y SI/NO.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, LEER_NUMERO y
;                SALTO_LINEA de utils/01_Macros_Entrada_Salida/macros_entrada_salida.asm.
;                Procedimientos canonicos ES_PAR, ES_IMPAR, ES_PRIMO,
;                ES_PERFECTO, TIENE_RAIZ_EXACTA y ES_NARCISISTA (esta carpeta).
; COMO INTEGRAR: Copiar los procedimientos deseados del bloque reutilizable
;                dentro de CODIGO despues de la salida a DOS, cargar el numero
;                en AX y llamar con CALL a cada clasificador necesario.
; EJEMPLO      : Entrada: 153
;                Salida :
;                  === CLASIFICADOR COMPLETO DE NUMEROS ===
;                  Ingrese un numero (0..65535): 153
;                  Clasificacion de 153:
;                    Par          : NO
;                    Impar        : SI
;                    Primo        : NO
;                    Perfecto     : NO
;                    Raiz exacta  : NO
;                    Narcisista   : SI
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

PILA SEGMENT STACK                          ; segmento de pila
    DW 128 DUP(0)                           ; 128 palabras para PUSH/POP/CALL
PILA ENDS                                   ; fin del segmento de pila

DATOS SEGMENT                               ; segmento de datos
    MSG_TITULO DB '=== CLASIFICADOR COMPLETO DE NUMEROS ===$' ; titulo
    MSG_PEDIR  DB 'Ingrese un numero (0..65535): $'  ; solicitud al usuario
    MSG_ENCAB  DB 'Clasificacion de $'      ; encabezado del resultado
    MSG_DOSP   DB ':$'                      ; dos puntos tras el numero
    MSG_PAR    DB '  Par          : $'      ; etiqueta par
    MSG_IMP    DB '  Impar        : $'      ; etiqueta impar
    MSG_PRI    DB '  Primo        : $'      ; etiqueta primo
    MSG_PER    DB '  Perfecto     : $'      ; etiqueta perfecto
    MSG_RAI    DB '  Raiz exacta  : $'      ; etiqueta raiz exacta
    MSG_NAR    DB '  Narcisista   : $'      ; etiqueta narcisista
    MSG_SI     DB 'SI$'                     ; respuesta afirmativa
    MSG_NO     DB 'NO$'                     ; respuesta negativa
    NUMERO     DW 0                         ; numero leido por teclado
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta al segmento DATOS

    IMPRIMIR_CADENA MSG_TITULO              ; muestra titulo
    SALTO_LINEA                             ; nueva linea

    IMPRIMIR_CADENA MSG_PEDIR               ; solicita el numero
    LEER_NUMERO                             ; AX = numero ingresado
    MOV NUMERO, AX                          ; guarda copia en memoria
    SALTO_LINEA                             ; nueva linea tras Enter

    IMPRIMIR_CADENA MSG_ENCAB               ; muestra "Clasificacion de "
    IMPRIMIR_NUMERO NUMERO                  ; muestra el numero leido
    IMPRIMIR_CADENA MSG_DOSP                ; muestra ":"
    SALTO_LINEA                             ; nueva linea

    MOV AX, NUMERO                          ; AX = numero a evaluar

    IMPRIMIR_CADENA MSG_PAR                 ; etiqueta Par
    CALL ES_PAR                             ; evalua si es par (BL = 1/0)
    CALL IMPRIMIR_SI_NO                     ; imprime SI o NO y salto de linea

    IMPRIMIR_CADENA MSG_IMP                 ; etiqueta Impar
    CALL ES_IMPAR                           ; evalua si es impar (BL = 1/0)
    CALL IMPRIMIR_SI_NO                     ; imprime SI o NO y salto de linea

    IMPRIMIR_CADENA MSG_PRI                 ; etiqueta Primo
    CALL ES_PRIMO                           ; evalua si es primo (BL = 1/0)
    CALL IMPRIMIR_SI_NO                     ; imprime SI o NO y salto de linea

    IMPRIMIR_CADENA MSG_PER                 ; etiqueta Perfecto
    CALL ES_PERFECTO                        ; evalua si es perfecto (BL = 1/0)
    CALL IMPRIMIR_SI_NO                     ; imprime SI o NO y salto de linea

    IMPRIMIR_CADENA MSG_RAI                 ; etiqueta Raiz exacta
    CALL TIENE_RAIZ_EXACTA                  ; evalua raiz exacta (BL = 1/0)
    CALL IMPRIMIR_SI_NO                     ; imprime SI o NO y salto de linea

    IMPRIMIR_CADENA MSG_NAR                 ; etiqueta Narcisista
    CALL ES_NARCISISTA                      ; evalua narcisista (BL = 1/0)
    CALL IMPRIMIR_SI_NO                     ; imprime SI o NO y salto de linea

    MOV AX, 4C00h                           ; AH=4Ch terminar, AL=0 sin error
    INT 21h                                 ; devuelve el control a DOS

;------------------------------------------------------------------------------
; PROCEDIMIENTO IMPRIMIR_SI_NO (auxiliar de la demostracion)
;   Entrada : BL = 1 para mostrar "SI", cualquier otro valor muestra "NO".
;   Modifica: nada (conserva AX y demas registros).
;------------------------------------------------------------------------------
IMPRIMIR_SI_NO PROC                         ; inicio del auxiliar
    CMP BL, 1                               ; resultado afirmativo?
    JNE ISN_NO                              ; no: imprime NO
    IMPRIMIR_CADENA MSG_SI                  ; si: imprime SI
    JMP ISN_FIN                             ; va al salto de linea
ISN_NO:                                     ; rama negativa
    IMPRIMIR_CADENA MSG_NO                  ; imprime NO
ISN_FIN:                                    ; salida comun
    SALTO_LINEA                             ; baja a la linea siguiente
    RET                                     ; vuelve al llamador
IMPRIMIR_SI_NO ENDP                         ; fin del auxiliar

;====== INICIO BLOQUE REUTILIZABLE: CLASIFICADORES ======
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
; PROCEDIMIENTO ES_PRIMO
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es primo, BL = 0 si no lo es (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI.
;   Metodo  : 0 y 1 no son primos. Para n >= 2 se prueban divisores d = 2,
;             3, 4... mientras d*d <= n. Si algun residuo es 0, no es primo.
;             Basta llegar a la raiz porque si n = a*b, uno de los dos
;             factores es <= raiz(n). MUL deja d*d en DX:AX; si DX <> 0 el
;             producto supera 65535 y por lo tanto supera a n.
;------------------------------------------------------------------------------
ES_PRIMO PROC                               ; inicio del procedimiento
    PUSH AX                                 ; guarda AX (se usa en MUL/DIV)
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    MOV BX, 0                               ; supone "no es primo"
    CMP AX, 2                               ; n < 2 ?
    JB EPRI_FIN                             ; 0 y 1 no son primos
    MOV SI, AX                              ; SI = n (AX se reutilizara)
    MOV CX, 2                               ; primer divisor a probar
EPRI_CICLO:                                 ; prueba cada divisor
    MOV AX, CX                              ; AX = d
    MUL CX                                  ; DX:AX = d * d
    CMP DX, 0                               ; el producto paso de 16 bits?
    JNE EPRI_SI                             ; si: d*d > n, no hay divisores
    CMP AX, SI                              ; compara d*d con n
    JA EPRI_SI                              ; d*d > n: ya se probo todo
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0, dividendo DX:AX = n
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; division exacta?
    JE EPRI_FIN                             ; si: tiene divisor, no es primo
    INC CX                                  ; siguiente divisor
    JMP EPRI_CICLO                          ; repite la prueba
EPRI_SI:                                    ; no se encontro divisor
    MOV BL, 1                               ; es primo
EPRI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_PRIMO ENDP                               ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO TIENE_RAIZ_EXACTA
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si existe r entero con r*r = n, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI.
;   Metodo  : prueba r = 0, 1, 2... calculando r*r. Si r*r = n hay raiz
;             exacta; si r*r > n (o pasa de 16 bits) ya no puede haberla.
;             Nota: 0 y 1 cuentan como cuadrados perfectos (0*0, 1*1).
;------------------------------------------------------------------------------
TIENE_RAIZ_EXACTA PROC                      ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (candidato r)
    PUSH DX                                 ; guarda DX (parte alta de MUL)
    PUSH SI                                 ; guarda SI (copia de n)
    MOV BX, 0                               ; supone "no tiene raiz exacta"
    MOV SI, AX                              ; SI = n
    MOV CX, 0                               ; r = 0
ERAI_CICLO:                                 ; prueba cada candidato
    MOV AX, CX                              ; AX = r
    MUL CX                                  ; DX:AX = r * r
    CMP DX, 0                               ; r*r supero 65535?
    JNE ERAI_FIN                            ; si: es mayor que n, no hay raiz
    CMP AX, SI                              ; compara r*r con n
    JE ERAI_SI                              ; iguales: raiz exacta = r
    JA ERAI_FIN                             ; r*r > n: no hay raiz exacta
    INC CX                                  ; siguiente candidato
    JMP ERAI_CICLO                          ; repite
ERAI_SI:                                    ; se encontro r
    MOV BL, 1                               ; tiene raiz exacta
ERAI_FIN:                                   ; salida comun
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
TIENE_RAIZ_EXACTA ENDP                      ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_PERFECTO
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es perfecto, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero es perfecto si es igual a la suma de sus divisores
;             propios (los menores que el). Ej: 6 = 1+2+3, 28 = 1+2+4+7+14.
;             Se prueban d = 1 .. n/2 (ningun divisor propio supera n/2).
;             Si la suma desborda 16 bits (CF=1) el numero no es perfecto.
;             0 y 1 no son perfectos.
;------------------------------------------------------------------------------
ES_PERFECTO PROC                            ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (divisor d)
    PUSH DX                                 ; guarda DX (residuo)
    PUSH SI                                 ; guarda SI (copia de n)
    PUSH DI                                 ; guarda DI (suma de divisores)
    MOV BX, 0                               ; supone "no es perfecto"
    CMP AX, 2                               ; n < 2 ?
    JB EPER_FIN                             ; 0 y 1 no son perfectos
    MOV SI, AX                              ; SI = n
    XOR DI, DI                              ; suma = 0
    MOV CX, 1                               ; primer divisor d = 1
EPER_CICLO:                                 ; recorre los candidatos
    MOV AX, SI                              ; AX = n
    SHR AX, 1                               ; AX = n / 2 (desplazar = /2)
    CMP CX, AX                              ; d > n/2 ?
    JA EPER_COMPARAR                        ; si: termino la busqueda
    MOV AX, SI                              ; AX = n (dividendo)
    XOR DX, DX                              ; DX = 0
    DIV CX                                  ; DX = n mod d
    CMP DX, 0                               ; d divide a n?
    JNE EPER_SIGUIENTE                      ; no: prueba el siguiente
    ADD DI, CX                              ; suma += d
    JC EPER_FIN                             ; desborde: no puede ser perfecto
EPER_SIGUIENTE:                             ; avanza al siguiente divisor
    INC CX                                  ; d = d + 1
    JMP EPER_CICLO                          ; repite
EPER_COMPARAR:                              ; termino de sumar
    CMP DI, SI                              ; suma == n ?
    JNE EPER_FIN                            ; distinto: no es perfecto
    MOV BL, 1                               ; igual: es perfecto
EPER_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_PERFECTO ENDP                            ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ES_NARCISISTA
;   Entrada : AX = numero (0..65535)
;   Salida  : BL = 1 si es narcisista, BL = 0 si no (BH = 0)
;   Modifica: BX y banderas. Conserva AX, CX, DX, SI, DI.
;   Metodo  : un numero de k cifras es narcisista si es igual a la suma de
;             cada cifra elevada a k. Ej: 153 = 1^3 + 5^3 + 3^3.
;             1) Cuenta las cifras (k) dividiendo por 10.
;             2) Vuelve a separar las cifras y suma cifra^k (potencia por
;                multiplicaciones sucesivas).
;             3) Compara la suma con el numero original.
;             Si una potencia o la suma pasan de 16 bits, no es narcisista.
;             En 16 bits los narcisistas son: 0..9, 153, 370, 371, 407,
;             1634, 8208, 9474 y 54748.
;------------------------------------------------------------------------------
ES_NARCISISTA PROC                          ; inicio del procedimiento
    PUSH AX                                 ; guarda AX
    PUSH CX                                 ; guarda CX (k = cantidad cifras)
    PUSH DX                                 ; guarda DX (cifra / parte alta)
    PUSH SI                                 ; guarda SI (copia de n)
    PUSH DI                                 ; guarda DI (suma de potencias)
    MOV SI, AX                              ; SI = n original
    MOV BX, 10                              ; BX = divisor 10
    XOR CX, CX                              ; k = 0
ENAR_CONTAR:                                ; 1) cuenta las cifras
    XOR DX, DX                              ; DX:AX = numero restante
    DIV BX                                  ; AX = numero / 10
    INC CX                                  ; una cifra mas
    CMP AX, 0                               ; quedan cifras?
    JNE ENAR_CONTAR                         ; si: sigue contando
    XOR DI, DI                              ; suma = 0
    MOV AX, SI                              ; AX = n de nuevo
ENAR_CIFRA:                                 ; 2) procesa cada cifra
    XOR DX, DX                              ; prepara DX:AX
    MOV BX, 10                              ; divisor 10
    DIV BX                                  ; AX = resto del numero, DX=cifra
    PUSH AX                                 ; guarda lo que falta procesar
    PUSH CX                                 ; guarda k (LOOP lo consumira)
    MOV BX, DX                              ; BX = cifra (base)
    MOV AX, 1                               ; potencia = 1
ENAR_POTENCIA:                              ; potencia = cifra^k
    MUL BX                                  ; DX:AX = potencia * cifra
    CMP DX, 0                               ; paso de 16 bits?
    JNE ENAR_DESB_POT                       ; si: no puede ser narcisista
    LOOP ENAR_POTENCIA                      ; repite k veces
    POP CX                                  ; recupera k
    ADD DI, AX                              ; suma += cifra^k
    JC ENAR_DESB_SUMA                       ; la suma desbordo 16 bits
    POP AX                                  ; recupera el numero restante
    CMP AX, 0                               ; quedan cifras?
    JNE ENAR_CIFRA                          ; si: procesa la siguiente
    MOV BX, 0                               ; supone "no es narcisista"
    CMP DI, SI                              ; 3) suma == n ?
    JNE ENAR_FIN                            ; no: termina con BL = 0
    MOV BL, 1                               ; si: es narcisista
    JMP ENAR_FIN                            ; salta a restaurar registros
ENAR_DESB_POT:                              ; desborde dentro de la potencia
    POP CX                                  ; equilibra la pila (k)
ENAR_DESB_SUMA:                             ; desborde en la suma
    POP AX                                  ; equilibra la pila (restante)
    MOV BX, 0                               ; no es narcisista
ENAR_FIN:                                   ; salida comun
    POP DI                                  ; restaura DI
    POP SI                                  ; restaura SI
    POP DX                                  ; restaura DX
    POP CX                                  ; restaura CX
    POP AX                                  ; restaura AX
    RET                                     ; vuelve al llamador
ES_NARCISISTA ENDP                          ; fin del procedimiento
;====== FIN BLOQUE REUTILIZABLE: CLASIFICADORES ======

CODIGO ENDS                                 ; fin del segmento de codigo
END INICIO                                  ; fin del archivo, entrada INICIO
