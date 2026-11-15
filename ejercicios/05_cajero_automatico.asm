; EJERCICIO 05 Simulador de cajero automatico
; Un banco comienza con saldo de 5.000 y procesa, en orden, seis movimientos: 
; deposito de 1.000, giro de 500, deposito de 2.000, giro de 800, giro de 300 
; y deposito de 500. Cada deposito recibe una bonificacion del 10%; cada giro 
; tiene un cargo fijo de 20. Recorra las operaciones mediante un ciclo, distinga 
; depositos y giros con condiciones, rechace giros sin saldo suficiente y 
; calcule el saldo final, el total retirado y el promedio entero de los giros 
; exitosos.

PILA SEGMENT STACK
    DW 64 DUP(0)
PILA ENDS

DATOS SEGMENT
    SALDO            DW 5000                       ; Saldo inicial del banco
    ; Codificacion de tipos: 1 = Deposito, 2 = Giro
    TIPO_MOV         DB 1, 2, 1, 2, 2, 1           ; Orden de las 6 operaciones
    MONTOS           DW 1000, 500, 2000, 800, 300, 500 ; Montos de cada movimiento
    CARGO_GIRO       DW 20                         ; Cargo fijo por cada giro
    DIEZ_PORCIENTO   DW 10                         ; Divisor para obtener el 10% de bonificacion
    
    TOTAL_RETIRADO   DW 0                          ; Suma de los montos retirados en giros exitosos
    GIROS_EXITOSOS   DW 0                          ; Contador de giros realizados con exito
    PROMEDIO_GIROS   DW 0                          ; Promedio entero de los giros exitosos
DATOS ENDS

CODIGO SEGMENT
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA

INICIO:
    ; Inicializacion del segmento de datos
    MOV AX, DATOS
    MOV DS, AX

    ; Inicializacion de registros para el ciclo
    MOV CX, 6                  ; 6 movimientos en total
    MOV SI, 0                  ; Indice para arreglo MONTOS (DW -> avanza de 2 en 2)
    MOV DI, 0                  ; Indice para arreglo TIPO_MOV (DB -> avanza de 1 en 1)

CICLO_MOVIMIENTOS:
    MOV AL, TIPO_MOV[DI]       ; Cargar el tipo de movimiento (1 o 2)
    CMP AL, 1                  ; Verificar si es un deposito (1)
    JE PROCESAR_DEPOSITO       ; Si es 1, saltar a la rutina de deposito


PROCESAR_GIRO:
    MOV AX, MONTOS[SI]         ; Cargar el monto que se desea girar
    MOV BX, AX                 ; Guardar copia del monto neto en BX
    ADD AX, CARGO_GIRO         ; Sumar el cargo fijo de 20 para obtener el costo total
    
    CMP SALDO, AX              ; Comparar el SALDO actual con el costo total del giro (Monto + 20)
    JB FIN_ITERACION           ; Si SALDO < Costo total, rechazar el giro y pasar al siguiente
    
    SUB SALDO, AX              ; Descontar del saldo el monto más el cargo fijo
    ADD TOTAL_RETIRADO, BX     ; Acumular el monto retirado (sin el cargo de 20)
    INC GIROS_EXITOSOS         ; Incrementar el contador de giros exitosos
    JMP FIN_ITERACION          ; Terminar movimiento actual

PROCESAR_DEPOSITO:
    MOV AX, MONTOS[SI]         ; Cargar el monto del deposito
    MOV BX, AX                 ; Guardar copia del monto base en BX
    MOV DX, 0                  ; Limpiar DX para division de 16 bits (DX:AX / Divisor)
    DIV DIEZ_PORCIENTO         ; Dividir monto entre 10 para obtener el 10% de bono en AX
    
    ADD BX, AX                 ; Sumar al monto base (BX) su 10% de bonificacion (AX)
    ADD SALDO, BX              ; Sumar el deposito total al saldo de la cuenta

FIN_ITERACION:
    ADD SI, 2                  ; Avanzar al siguiente monto (2 bytes)
    INC DI                     ; Avanzar al siguiente tipo de movimiento (1 byte)
    LOOP CICLO_MOVIMIENTOS     ; Repetir hasta completar los 6 movimientos

    ; Calculo del promedio de giros exitosos
    CMP GIROS_EXITOSOS, 0      ; Verificar que exista al menos un giro exitoso (praa evitar division por 0)
    JE TERMINAR
    
    MOV AX, TOTAL_RETIRADO     ; Cargar total retirado (1600)
    MOV DX, 0                  ; Limpiar DX para la division
    DIV GIROS_EXITOSOS         ; Dividir TOTAL_RETIRADO entre GIROS_EXITOSOS (1600 / 3 = 533)
    MOV PROMEDIO_GIROS, AX     ; Almacenar el promedio entero (Cociente en AX)

TERMINAR:
    ; Finalizar el programa
    MOV AH, 4CH
    INT 21H

CODIGO ENDS
END INICIO