; EJERCICIO 04 Promedios y aprobacion de estudiantes
; Una institucion necesita calcular el promedio entero de seis estudiantes, 
; cada uno con tres notas: (70,80,90), (40,50,60), (90,90,90), (30,40,50), 
; (60,70,80) y (50,55,60). Utilice ciclos y division para calcular y almacenar 
; los promedios. Mediante comparaciones y saltos condicionales, contabilice 
; aprobados (promedio igual o superior a 60) y reprobados.

PILA SEGMENT STACK
    DW 64 DUP(0)
PILA ENDS

DATOS SEGMENT
    ; Notas de los 6 estudiantes (3 notas consecutivas por estudiante)
    NOTAS       DB 70, 80, 90,  40, 50, 60,  90, 90, 90,  30, 40, 50,  60, 70, 80,  50, 55, 60
    PROMEDIOS   DB 6 DUP(0)    ; Arreglo para almacenar el promedio entero de cada estudiante
    APROBADOS   DB 0           ; Contador de estudiantes con promedio >= 60
    REPROBADOS  DB 0           ; Contador de estudiantes con promedio < 60
    CANT_NOTAS  DB 3           ; Divisor para el calculo de promedio
DATOS ENDS

CODIGO SEGMENT
    ASSUME CS:CODIGO, DS:DATOS, SS:PILA

INICIO:
    ; Inicializacion del segmento de datos
    MOV AX, DATOS
    MOV DS, AX

    ; Inicializacion de punteros y contadores
    MOV CX, 6                  ; Contador del ciclo externo (6 estudiantes)
    MOV SI, 0                  ; Indice para recorrer el arreglo NOTAS
    MOV DI, 0                  ; Indice para recorrer el arreglo PROMEDIOS

CICLO_ESTUDIANTES:
    PUSH CX                    ; Guardar contador de estudiantes en la pila
    MOV CX, 3                  ; Contador del ciclo interno (3 notas por estudiante)
    MOV AX, 0                  ; Limpiar AX para acumular la suma de las 3 notas

CICLO_NOTAS:
    MOV BL, NOTAS[SI]          ; Cargar nota actual
    MOV BH, 0                  ; Limpiar BH para sumar en 16 bits sin error de desborde
    ADD AX, BX                 ; Acumular nota en AX
    INC SI                     ; Avanzar a la siguiente nota
    LOOP CICLO_NOTAS           ; Repetir para las 3 notas del estudiante

    ; Calcular el promedio entero
    DIV CANT_NOTAS             ; Dividir AX entre 3 (AL = Cociente/Promedio, AH = Resto)
    MOV PROMEDIOS[DI], AL      ; Guardar promedio entero en el arreglo

    ; Evaluar aprobacion o reprobacion
    CMP AL, 60                 ; Comparar promedio con la nota minima de aprobacion (60)
    JAE ES_APROBADO            ; Si AL >= 60 (Jump if Above or Equal), salta a ES_APROBADO
    
    INC REPROBADOS             ; Si es menor a 60, incrementar reprobados
    JMP CONTINUAR              ; Saltar al final de la iteracion

ES_APROBADO:
    INC APROBADOS              ; Incrementar contador de aprobados

CONTINUAR:
    INC DI                     ; Avanzar al siguiente espacio en el arreglo PROMEDIOS
    POP CX                     ; Recuperar contador de estudiantes desde la pila
    LOOP CICLO_ESTUDIANTES     ; Procesar siguiente estudiante

    ; Finalizar el programa
    MOV AH, 4CH
    INT 21H

CODIGO ENDS
END INICIO