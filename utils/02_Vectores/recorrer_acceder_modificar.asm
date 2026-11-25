;==============================================================================
; ARCHIVO      : recorrer_acceder_modificar.asm
; TIPO         : PROCEDIMIENTO (+ programa de demostracion)
; DESCRIPCION  : Muestra como recorrer un vector de palabras (DW) con SI y
;                LOOP, como calcular el desplazamiento en bytes a partir de un
;                indice logico i (i * 2 usando SHL BX, 1) y provee los
;                procedimientos LEER_POSICION y ESCRIBIR_POSICION usando el
;                modo de direccionamiento base + indice [BX+SI].
; FUNCIONAMIENTO:
;                En 8086 el modo base + indice solo permite combinar un
;                registro base (BX o BP) con un registro indice (SI o DI):
;                [BX+SI] es valido, mientras que [SI+DI] no existe en 8086.
;                Si SI contiene el OFFSET del vector y BX contiene el indice
;                logico i (0, 1, 2...), primero se convierte i a bytes con
;                SHL BX, 1 (equivale a multiplicar por 2, tamano de una DW)
;                y luego se accede directamente a [BX+SI].
; REGISTROS    : LEER_POSICION:
;                  Entrada : SI = offset del vector, BX = indice logico i
;                  Salida  : AX = valor almacenado en VECTOR[i]
;                  Modifica: AX y banderas (conserva BX, SI)
;                ESCRIBIR_POSICION:
;                  Entrada : SI = offset del vector, BX = indice logico i,
;                            AX = nuevo valor a guardar
;                  Salida  : VECTOR[i] = AX
;                  Modifica: banderas (conserva AX, BX, SI)
; VARIABLES    : Un vector de palabras (DW) en DATOS.
; DEPENDENCIAS : Macros IMPRIMIR_CADENA, IMPRIMIR_NUMERO, IMPRIMIR_ESPACIO,
;                SALTO_LINEA, FIN_PROGRAMA (de utils/01_Macros_Entrada_Salida/
;                macros_entrada_salida.asm).
;                Procedimiento MOSTRAR_VECTOR (de canon_procs.asm).
; COMO INTEGRAR: 1) Copiar las macros arriba de PILA.
;                2) Copiar el bloque reutilizable en CODIGO despues de la
;                   salida a DOS.
;                3) Llamar con SI = OFFSET VECTOR, BX = indice (y AX al
;                   escribir). Verificar que BX < tamano del vector.
; EJEMPLO      : Salida esperada:
;                  === RECORRER, ACCEDER Y MODIFICAR ===
;                  Vector inicial       : 15 25 35 45 55
;                  Elemento en indice 2 : 35
;                  Modificando indice 2 a 999...
;                  Nuevo valor indice 2 : 999
;                  Vector tras modificar: 15 25 999 45 55
;                  Duplicando todos los elementos con SI y LOOP...
;                  Vector duplicado     : 30 50 1998 90 110
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
    TAMANO     EQU 5                        ; cantidad de elementos del vector
    VECTOR     DW 15, 25, 35, 45, 55        ; vector de 5 palabras (10 bytes)

    MSG_TIT    DB '=== RECORRER, ACCEDER Y MODIFICAR ===$' ; titulo
    MSG_INI    DB 'Vector inicial       : $' ; etiqueta 1
    MSG_LEER   DB 'Elemento en indice 2 : $' ; etiqueta 2
    MSG_MOD    DB 'Modificando indice 2 a 999...$' ; aviso
    MSG_NUEVO  DB 'Nuevo valor indice 2 : $' ; etiqueta 3
    MSG_DESP   DB 'Vector tras modificar: $' ; etiqueta 4
    MSG_DUP    DB 'Duplicando todos los elementos con SI y LOOP...$' ; aviso
    MSG_FINAL  DB 'Vector duplicado     : $' ; etiqueta 5
DATOS ENDS                                  ; fin del segmento de datos

CODIGO SEGMENT                              ; segmento de codigo
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA     ; asocia segmentos y registros
INICIO:                                     ; punto de entrada del programa
    MOV AX, DATOS                           ; AX = direccion del segmento DATOS
    MOV DS, AX                              ; DS apunta a DATOS

    IMPRIMIR_CADENA MSG_TIT                 ; muestra el titulo
    SALTO_LINEA                             ; nueva linea

    ; 1) Muestra el vector inicial
    IMPRIMIR_CADENA MSG_INI                 ; etiqueta
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 5 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 15 25 35 45 55
    SALTO_LINEA                             ; nueva linea

    ; 2) Lee el elemento en el indice logico 2 (tercer elemento)
    MOV SI, OFFSET VECTOR                   ; SI = direccion base del vector
    MOV BX, 2                               ; BX = indice logico i = 2
    CALL LEER_POSICION                      ; AX = VECTOR[2] (35)
    IMPRIMIR_CADENA MSG_LEER                ; etiqueta
    IMPRIMIR_NUMERO AX                      ; muestra 35
    SALTO_LINEA                             ; nueva linea

    ; 3) Modifica el elemento en el indice logico 2 a 999
    IMPRIMIR_CADENA MSG_MOD                 ; aviso
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VECTOR                   ; SI = direccion base del vector
    MOV BX, 2                               ; BX = indice logico i = 2
    MOV AX, 999                             ; AX = nuevo valor
    CALL ESCRIBIR_POSICION                  ; VECTOR[2] = 999

    ; Verifica leyendo de nuevo la posicion 2
    CALL LEER_POSICION                      ; AX = VECTOR[2] (ahora 999)
    IMPRIMIR_CADENA MSG_NUEVO               ; etiqueta
    IMPRIMIR_NUMERO AX                      ; muestra 999
    SALTO_LINEA                             ; nueva linea

    ; Muestra el vector completo tras la modificacion
    IMPRIMIR_CADENA MSG_DESP                ; etiqueta
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 5 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 15 25 999 45 55
    SALTO_LINEA                             ; nueva linea

    ; 4) Recorrido con SI y LOOP que modifica cada elemento (lo duplica)
    IMPRIMIR_CADENA MSG_DUP                 ; aviso
    SALTO_LINEA                             ; nueva linea
    MOV SI, OFFSET VECTOR                   ; SI = puntero al primer elemento
    MOV CX, TAMANO                          ; CX = contador de iteraciones
DEMO_DUP:                                   ; ciclo que duplica cada palabra
    MOV AX, [SI]                            ; lee la palabra en la direccion SI
    ADD AX, AX                              ; duplica AX (sin desborde aqui)
    MOV [SI], AX                            ; escribe el valor modificado
    ADD SI, 2                               ; avanza 2 bytes al siguiente DW
    LOOP DEMO_DUP                           ; CX = CX - 1; repite si CX <> 0

    IMPRIMIR_CADENA MSG_FINAL               ; etiqueta
    MOV SI, OFFSET VECTOR                   ; SI apunta al inicio del vector
    MOV CX, TAMANO                          ; CX = 5 elementos
    CALL MOSTRAR_VECTOR                     ; muestra 30 50 1998 90 110
    SALTO_LINEA                             ; nueva linea

    FIN_PROGRAMA                            ; termina y vuelve a DOS

;====== INICIO BLOQUE REUTILIZABLE: ACCESO_POR_INDICE ======

;------------------------------------------------------------------------------
; PROCEDIMIENTO LEER_POSICION
;   Entrada : SI = offset del vector de palabras (DW), BX = indice logico i
;   Salida  : AX = valor guardado en VECTOR[i]
;   Modifica: AX y banderas (conserva BX y SI).
;   Nota    : el llamador debe asegurar que 0 <= BX < cantidad de elementos.
;------------------------------------------------------------------------------
LEER_POSICION PROC                          ; inicio del procedimiento
    PUSH BX                                 ; guarda el indice logico original
    SHL BX, 1                               ; BX = i * 2 (desplazamiento bytes)
    MOV AX, [BX+SI]                         ; lee la palabra en (VECTOR + 2*i)
    POP BX                                  ; restaura el indice logico
    RET                                     ; vuelve al llamador
LEER_POSICION ENDP                          ; fin del procedimiento

;------------------------------------------------------------------------------
; PROCEDIMIENTO ESCRIBIR_POSICION
;   Entrada : SI = offset del vector de palabras (DW), BX = indice logico i,
;             AX = valor a almacenar
;   Salida  : escribe AX en VECTOR[i].
;   Modifica: banderas (conserva AX, BX y SI).
;   Nota    : el llamador debe asegurar que 0 <= BX < cantidad de elementos.
;------------------------------------------------------------------------------
ESCRIBIR_POSICION PROC                      ; inicio del procedimiento
    PUSH BX                                 ; guarda el indice logico original
    SHL BX, 1                               ; BX = i * 2 (desplazamiento bytes)
    MOV [BX+SI], AX                         ; guarda AX en (VECTOR + 2*i)
    POP BX                                  ; restaura el indice logico
    RET                                     ; vuelve al llamador
ESCRIBIR_POSICION ENDP                      ; fin del procedimiento

;====== FIN BLOQUE REUTILIZABLE: ACCESO_POR_INDICE ======

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
