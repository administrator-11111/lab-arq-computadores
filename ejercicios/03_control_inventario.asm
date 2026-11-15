; EJERCICIO 03 Sistema de control de inventario
; Una tienda inicia con 200 productos y registra movimientos durante cinco dias. 
; Entradas: 20, 15, 30, 10 y 25 unidades. Salidas: 10, 20, 15, 25 y 10 unidades. 
; Programe el procesamiento de cada dia mediante un ciclo, actualice y almacene 
; el inventario disponible y calcule el valor monetario del inventario final, 
; considerando un precio unitario de 150. Evite realizar salidas que excedan 
; el stock disponible.

PILA SEGMENT STACK
    DW 64 DUP(0)
PILA ENDS

DATOS SEGMENT
    STOCK_ACTUAL     DW 200                ; Inventario inicial disponible
    ENTRADAS         DW 20, 15, 30, 10, 25 ; Entradas de los 5 dias
    SALIDAS          DW 10, 20, 15, 25, 10 ; Salidas de los 5 dias
    HISTORIAL_DIARIO DW 5 DUP(0)           ; Almacena el inventario disponible al cierre de cada dia
    PRECIO_UNITARIO  DW 150                ; Precio por unidad
    VALOR_MONETARIO  DW 0                  ; Valor monetario del inventario final
DATOS ENDS

CODIGO SEGMENT
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA

INICIO:
    ; Inicializacion del segmento de datos
    MOV AX, DATOS
    MOV DS, AX

    ; Inicializacion de registros para el ciclo
    MOV CX, 5                  ; 5 dias de movimientos
    MOV SI, 0                  ; Indice para recorrer arreglos DW (de 2 en 2)

CICLO_DIAS:
    ; Procesar entrada del dia
    MOV AX, STOCK_ACTUAL       ; Cargar stock disponible
    ADD AX, ENTRADAS[SI]       ; Sumar las unidades que entran en el dia
    
    ; Validar que la salida no exceda el stock disponible
    MOV BX, SALIDAS[SI]        ; Cargar las unidades de salida del dia
    CMP AX, BX                 ; Comparar stock disponible (AX) con la salida (BX)
    JB OMITIR_SALIDA           ; Si Stock < Salida (Jump if Below), omitir la salida
    
    SUB AX, BX                 ; Si hay stock suficiente, descontar la salida

OMITIR_SALIDA:
    ; Actualizar y almacenar el inventario disponible
    MOV STOCK_ACTUAL, AX       ; Actualizar el inventario general (Final: 220)
    MOV HISTORIAL_DIARIO[SI], AX ; Guardar registro del dia en el arreglo
    
    ADD SI, 2                  ; Avanzar al siguiente dia
    LOOP CICLO_DIAS            ; Repetir para los 5 dias

    ; Calcular el valor monetario del inventario final
    MOV AX, STOCK_ACTUAL       ; Cargar inventario final (220)
    MOV BX, PRECIO_UNITARIO    ; Cargar precio unitario (150)
    MUL BX                     ; Multiplicar AX * BX (220 * 150 = 33000 en AX)
    MOV VALOR_MONETARIO, AX    ; Guardar valor monetario final

    ; Finalizar el programa
    MOV AH, 4CH
    INT 21H

CODIGO ENDS
END INICIO