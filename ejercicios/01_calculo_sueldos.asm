; EJERCICIO 01 Calculo de sueldos con bonificaciones
; Una empresa cuenta con cinco trabajadores, cuyos sueldos base son 500, 600, 
; 700, 800 y 900. Cada trabajador recibe una bonificacion de 100 y un descuento 
; de 50. Desarrolle un programa en ensamblador 8086 que recorra los sueldos 
; mediante un ciclo, calcule el sueldo final de cada trabajador, almacene los 
; cinco resultados en un arreglo y obtenga el total general a pagar.

PILA SEGMENT STACK
    DW 64 DUP(0)
PILA ENDS

DATOS SEGMENT
    SUELDOS_BASE   DW 500, 600, 700, 800, 900 ; Arreglo con sueldos iniciales (16 bits)
    BONIFICACION   DW 100                     ; Bono fijo por trabajador
    DESCUENTO      DW 50                      ; Descuento fijo por trabajador
    SUELDOS_FINAL  DW 5 DUP(0)                ; Arreglo para almacenar los 5 resultados
    TOTAL_PAGAR    DW 0                       ; Variable para el total general a pagar
DATOS ENDS

CODIGO SEGMENT
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA

INICIO:
    ; Inicializacion del segmento de datos
    MOV AX, DATOS
    MOV DS, AX

    ; Inicializacion de registros para el ciclo
    MOV CX, 5                  ; Contador del ciclo (5 trabajadores)
    MOV SI, 0                  ; Indice para recorrer los arreglos de tipo DW (avanza de 2 en 2)
    MOV BX, 0                  ; Acumulador para el total general a pagar

CICLO_SUELDOS:
    MOV AX, SUELDOS_BASE[SI]   ; Cargar sueldo base del trabajador actual
    ADD AX, BONIFICACION       ; Sumar la bonificacion de 100
    SUB AX, DESCUENTO          ; Restar el descuento de 50
    
    MOV SUELDOS_FINAL[SI], AX  ; Almacenar sueldo final en el arreglo de resultados
    ADD BX, AX                 ; Sumar al acumulado general
    
    ADD SI, 2                  ; Avanzar al siguiente elemento (2 bytes por ser DW)
    LOOP CICLO_SUELDOS         ; Decrementar CX y repetir si CX > 0

    MOV TOTAL_PAGAR, BX        ; Guardar el total general en memoria (Resultado: 3750)

    ; Finalizar el programa y retornar al sistema
    MOV AH, 4CH
    INT 21H

CODIGO ENDS
END INICIO