; EJERCICIO 02 Tabla de multiplicar acumulativa
; Desarrolle un programa en ensamblador 8086 que genere la tabla de multiplicar 
; del numero 7, desde 1 hasta 10. Debe utilizar un ciclo, efectuar las 
; multiplicaciones, almacenar cada producto en un arreglo y calcular la suma 
; acumulada de todos los resultados.

PILA SEGMENT STACK
    DW 64 DUP(0)
PILA ENDS

DATOS SEGMENT
    NUMERO          DB 7          ; Numero base para la tabla de multiplicar
    TABLA_PRODUCTOS DB 10 DUP(0)  ; Arreglo para guardar los 10 productos (7, 14, ..., 70)
    SUMA_ACUMULADA  DW 0          ; Suma total de los productos (requiere 16 bits: 385)
DATOS ENDS

CODIGO SEGMENT
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA

INICIO:
    ; Inicializacion del segmento de datos
    MOV AX, DATOS
    MOV DS, AX

    ; Inicializacion de registros
    MOV CX, 10                 ; Contador del ciclo (10 multiplicaciones)
    MOV SI, 0                  ; Indice para el arreglo TABLA_PRODUCTOS
    MOV BL, 1                  ; Multiplicador actual (inicia en 1, llega hasta 10)
    MOV DX, 0                  ; Registro acumulador para la suma total

CICLO_TABLA:
    MOV AL, NUMERO             ; Cargar el numero 7 en AL
    MUL BL                     ; Multiplicar AL * BL (el resultado queda en AX)
    
    MOV TABLA_PRODUCTOS[SI], AL; Guardar el producto en el arreglo (cabe en 1 byte)
    ADD DX, AX                 ; Sumar el producto de 16 bits al acumulador general
    
    INC BL                     ; Incrementar multiplicador (1, 2, 3...)
    INC SI                     ; Avanzar a la siguiente posicion del arreglo (1 byte)
    LOOP CICLO_TABLA           ; Decrementar CX y repetir si CX > 0

    MOV SUMA_ACUMULADA, DX     ; Guardar la suma acumulada en memoria (Resultado: 385)

    ; Finalizar el programa
    MOV AH, 4CH
    INT 21H

CODIGO ENDS
END INICIO