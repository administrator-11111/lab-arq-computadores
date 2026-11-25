# Saltos condicionales del 8086 — guía rápida

Documento de consulta para los laboratorios con EMU8086. Explica `CMP`, las banderas del registro **FLAGS** y todos los saltos condicionales principales, con ejemplos listos para copiar.

---

## 1. ¿Cómo decide el 8086 si salta?

El 8086 no tiene instrucciones del tipo "si A > B entonces...". La decisión se hace en **dos pasos**:

1. Una instrucción **aritmética o lógica** (`CMP`, `SUB`, `ADD`, `TEST`, `AND`, `DEC`...) actualiza las **banderas** del registro FLAGS.
2. Un **salto condicional** (`Jxx`) consulta esas banderas y salta a una etiqueta si se cumple la condición. Si no se cumple, continúa con la instrucción siguiente.

```asm
    CMP AX, BX          ; paso 1: compara AX con BX (actualiza FLAGS)
    JA  AX_MAYOR        ; paso 2: salta si AX > BX (sin signo)
    ; ... aqui llega si AX <= BX
```

### 1.1. La instrucción `CMP`

`CMP destino, fuente` **resta** `destino - fuente`, **descarta el resultado** y solo actualiza las banderas. Es igual a `SUB` pero sin modificar el destino.

| Forma válida | Ejemplo |
|---|---|
| registro, registro | `CMP AX, BX` |
| registro, memoria | `CMP AX, SUMA` |
| memoria, registro | `CMP VECTOR[SI], AX` |
| registro, inmediato | `CMP AL, '0'` |
| memoria, inmediato | `CMP WORD PTR [SI], 100` |

> ⚠️ **No existe** `CMP memoria, memoria`: primero copie un operando a un registro.
> Con memoria e inmediato hay que indicar el tamaño: `CMP BYTE PTR [SI], 5` o `CMP WORD PTR [SI], 5`.

### 1.2. Relación entre `CMP` y los saltos

Después de `CMP A, B` el procesador "sabe" el resultado de `A - B`:

| Resultado de `A - B` | Banderas que quedan | Significado |
|---|---|---|
| 0 | ZF = 1 | A = B |
| se necesitó "pedir prestado" | CF = 1 | A < B (sin signo) |
| no hubo préstamo y no es 0 | CF = 0 y ZF = 0 | A > B (sin signo) |
| resultado negativo correcto | SF ≠ OF | A < B (con signo) |

Los saltos condicionales simplemente leen esas banderas. Por eso el salto **debe ir inmediatamente después** del `CMP` (o con instrucciones intermedias que no modifiquen banderas, como `MOV`, `PUSH`, `POP`, `JMP`, `LEA`).

> ⚠️ `INC`, `DEC`, `ADD`, `SUB`, `MUL`, `DIV`, `AND`, `OR`, `XOR`, `TEST`, `SHL`... **sí modifican banderas**. Si las pone entre `CMP` y `Jxx`, el salto evaluará el resultado de la última instrucción, no del `CMP`.

---

## 2. Las banderas que usan los saltos

| Bandera | Nombre | Se activa (=1) cuando... | Ejemplo |
|---|---|---|---|
| **CF** | Carry (acarreo) | una suma sin signo pasa de 65535 (o 255), o una resta necesita préstamo (A < B sin signo) | `MOV AL,200` / `ADD AL,100` → CF=1 |
| **ZF** | Zero (cero) | el resultado es 0 | `CMP AX,AX` → ZF=1 |
| **SF** | Sign (signo) | el bit más significativo del resultado es 1 (resultado "negativo" en complemento a 2) | `MOV AL,5` / `SUB AL,6` → AL=FFh, SF=1 |
| **OF** | Overflow (desborde con signo) | el resultado con signo no cabe: positivo+positivo=negativo o negativo+negativo=positivo | `MOV AL,127` / `ADD AL,1` → OF=1 |
| **PF** | Parity (paridad) | el **byte bajo** del resultado tiene una cantidad **par** de bits en 1 | `MOV AL,3` / `OR AL,0` → 00000011b, PF=1 |

Notas:
- **CF** es la bandera de los números **sin signo**; **OF** es la de los números **con signo**.
- `MUL` deja CF=OF=1 si la parte alta del resultado (AH o DX) no es cero → útil para detectar que un producto no cabe en 16 bits.
- `INC` y `DEC` **no modifican CF** (sí ZF, SF, OF, PF).
- **PF** solo mira los 8 bits bajos; **no** indica si el número es par. Para saber si un número es par use `TEST AX, 1` y `JZ`.

---

## 3. Con signo vs. sin signo

El mismo patrón de bits puede leerse de dos formas. `FFFFh` es **65535** sin signo y **-1** con signo (complemento a 2).

```asm
    MOV AX, 0FFFFh      ; 65535 sin signo / -1 con signo
    MOV BX, 1           ; 1 en ambas interpretaciones
    CMP AX, BX          ; misma comparacion, distintas lecturas:
    JA  SIN_SIGNO_MAYOR ; SALTA: 65535 > 1 (sin signo)
    JG  CON_SIGNO_MAYOR ; NO salta: -1 > 1 es falso (con signo)
```

| Comparación | Sin signo (naturales, direcciones, contadores, ASCII) | Con signo (enteros que pueden ser negativos) |
|---|---|---|
| Mayor | `JA` (Above) | `JG` (Greater) |
| Mayor o igual | `JAE` | `JGE` |
| Menor | `JB` (Below) | `JL` (Less) |
| Menor o igual | `JBE` | `JLE` |
| Igual / distinto | `JE` / `JNE` | `JE` / `JNE` (iguales en ambos casos) |

**Regla mnemotécnica:** *Above/Below* = sin signo; *Greater/Less* = con signo.
En esta biblioteca todos los vectores y números son **sin signo**, por eso se usan `JA`, `JB`, `JAE` y `JBE`.

---

## 4. Igualdad, mayor y menor

- **Igualdad** solo depende de ZF: `JE`/`JZ` (ZF=1) y `JNE`/`JNZ` (ZF=0). Es igual con o sin signo.
- **Mayor / menor** depende del tipo de número: CF (+ZF) para sin signo; SF, OF (+ZF) para con signo.
- Muchos saltos tienen **dos nombres** para la misma instrucción máquina; elija el que exprese mejor la intención:
  `JE`=`JZ`, `JNE`=`JNZ`, `JB`=`JC`=`JNAE`, `JAE`=`JNC`=`JNB`, `JA`=`JNBE`, `JBE`=`JNA`, `JG`=`JNLE`, `JGE`=`JNL`, `JL`=`JNGE`, `JLE`=`JNG`, `JP`=`JPE`, `JNP`=`JPO`.

---

## 5. Tabla resumen

| Instrucción | Significado | Condición en FLAGS | Tipo |
|---|---|---|---|
| `JE` / `JZ` | Igual / resultado cero | ZF = 1 | ambos |
| `JNE` / `JNZ` | Diferente / no cero | ZF = 0 | ambos |
| `JC` | Carry activado | CF = 1 | sin signo |
| `JNC` | Carry desactivado | CF = 0 | sin signo |
| `JA` / `JNBE` | Mayor | CF = 0 y ZF = 0 | sin signo |
| `JAE` / `JNB` | Mayor o igual | CF = 0 | sin signo |
| `JB` / `JNAE` | Menor | CF = 1 | sin signo |
| `JBE` / `JNA` | Menor o igual | CF = 1 o ZF = 1 | sin signo |
| `JG` / `JNLE` | Mayor | ZF = 0 y SF = OF | con signo |
| `JGE` / `JNL` | Mayor o igual | SF = OF | con signo |
| `JL` / `JNGE` | Menor | SF ≠ OF | con signo |
| `JLE` / `JNG` | Menor o igual | ZF = 1 o SF ≠ OF | con signo |
| `JO` | Overflow activado | OF = 1 | con signo |
| `JNO` | Overflow desactivado | OF = 0 | con signo |
| `JS` | Signo activado (negativo) | SF = 1 | con signo |
| `JNS` | Signo desactivado (positivo o cero) | SF = 0 | con signo |
| `JP` / `JPE` | Paridad par | PF = 1 | — |
| `JNP` / `JPO` | Paridad impar | PF = 0 | — |
| `JCXZ` | CX vale cero (no usa FLAGS) | CX = 0 | — |
| `JMP` | Salto incondicional | — | — |

---

## 6. Detalle de cada salto con ejemplo

### `JE` / `JZ` — Igual / Cero
- **Significa:** salta si los operandos comparados son iguales o si el último resultado fue 0.
- **Cuándo:** comparar con un valor exacto (tecla Enter, fin de cadena, residuo 0, contador terminado).
- **Bandera:** ZF = 1.
```asm
    XOR DX, DX          ; prepara el dividendo DX:AX
    DIV BX              ; DX = residuo de AX / BX
    CMP DX, 0           ; residuo cero?
    JE  ES_DIVISIBLE    ; si: BX divide exactamente a AX
```

### `JNE` / `JNZ` — Diferente / No cero
- **Significa:** salta si son distintos o si el resultado no fue 0.
- **Cuándo:** repetir un ciclo mientras falten elementos, detectar caracteres distintos.
- **Bandera:** ZF = 0.
```asm
CICLO:
    ; ... procesa un elemento
    DEC CX              ; un elemento menos (DEC actualiza ZF)
    JNZ CICLO           ; si CX <> 0 repite (equivale a LOOP)
```

### `JC` — Carry activado
- **Significa:** salta si CF = 1 (hubo acarreo en una suma o préstamo en una resta).
- **Cuándo:** detectar que una suma sin signo pasó de 65535, o tras `CMP A,B` saber que A < B sin signo.
- **Bandera:** CF = 1.
```asm
    ADD SUMA, AX        ; acumula en 16 bits
    JC  DESBORDE        ; el resultado no cabe en 16 bits
```

### `JNC` — Carry desactivado
- **Significa:** salta si CF = 0.
- **Cuándo:** continuar cuando una suma no desbordó; tras `CMP A,B`, A ≥ B sin signo.
- **Bandera:** CF = 0.
```asm
    ADD AX, BX          ; suma sin signo
    JNC SUMA_OK         ; no hubo acarreo: resultado valido
    INC DX              ; hubo acarreo: se suma 1 a la parte alta
SUMA_OK:
```

### `JA` — Mayor (sin signo)
- **Significa:** salta si destino > fuente, interpretando ambos como naturales.
- **Cuándo:** buscar el máximo, validar un límite superior, comparar caracteres ASCII.
- **Banderas:** CF = 0 y ZF = 0.
```asm
    CMP AL, '9'         ; compara la tecla con el ASCII de 9
    JA  NO_ES_DIGITO    ; mayor que '9': no es un digito
```

### `JAE` — Mayor o igual (sin signo)
- **Significa:** salta si destino ≥ fuente (sin signo). Es la misma instrucción que `JNC`.
- **Cuándo:** terminar un ciclo cuando el índice alcanza el tamaño (`i >= N`).
- **Bandera:** CF = 0.
```asm
WHILE_INICIO:
    CMP SI, N           ; i >= N ?
    JAE WHILE_FIN       ; si: termina el ciclo WHILE
    ; ... cuerpo del ciclo
    INC SI              ; i = i + 1
    JMP WHILE_INICIO    ; vuelve a evaluar la condicion
WHILE_FIN:
```

### `JB` — Menor (sin signo)
- **Significa:** salta si destino < fuente (sin signo). Es la misma instrucción que `JC`.
- **Cuándo:** buscar el mínimo, validar un límite inferior.
- **Bandera:** CF = 1.
```asm
    MOV AX, [SI]        ; elemento actual
    CMP AX, MINIMO      ; menor que el minimo actual?
    JB  NUEVO_MINIMO    ; si: actualizar el minimo
```

### `JBE` — Menor o igual (sin signo)
- **Significa:** salta si destino ≤ fuente (sin signo).
- **Cuándo:** ciclos `for i = 1 to N`, validar `N <= 30`.
- **Banderas:** CF = 1 o ZF = 1.
```asm
    CMP AX, 30          ; N <= 30 ?
    JBE N_VALIDO        ; si: esta dentro del rango
```

### `JG` — Mayor (con signo)
- **Significa:** salta si destino > fuente considerando números negativos.
- **Cuándo:** temperaturas, saldos, diferencias que pueden ser negativas.
- **Banderas:** ZF = 0 y SF = OF.
```asm
    MOV AX, -5          ; AX = FFFBh (complemento a 2)
    CMP AX, -10         ; -5 > -10 ?
    JG  ES_MAYOR        ; SALTA (con JA no saltaria: FFFBh < FFF6h es falso... ver nota)
```
> Nota: aquí `JA` también saltaría por casualidad (FFFBh > FFF6h); pruebe `CMP AX, 3`: `JG` no salta (-5 < 3) pero `JA` sí (65531 > 3). Por eso hay que elegir el salto según el tipo de dato.

### `JGE` — Mayor o igual (con signo)
- **Significa:** salta si destino ≥ fuente con signo.
- **Cuándo:** verificar que un valor con signo no sea negativo (`CMP AX,0` / `JGE`).
- **Banderas:** SF = OF.
```asm
    CMP AX, 0           ; AX >= 0 ?
    JGE NO_NEGATIVO     ; si: es cero o positivo
```

### `JL` — Menor (con signo)
- **Significa:** salta si destino < fuente con signo.
- **Cuándo:** detectar números negativos, mínimos con signo.
- **Banderas:** SF ≠ OF.
```asm
    CMP AX, 0           ; AX < 0 ?
    JL  ES_NEGATIVO     ; si: tratarlo como negativo
```

### `JLE` — Menor o igual (con signo)
- **Significa:** salta si destino ≤ fuente con signo.
- **Cuándo:** límites superiores de valores con signo.
- **Banderas:** ZF = 1 o SF ≠ OF.
```asm
    CMP AX, 100         ; AX <= 100 (con signo)?
    JLE DENTRO_LIMITE   ; si: valor aceptado
```

### `JO` — Overflow activado
- **Significa:** salta si la última operación con signo produjo un resultado que no cabe.
- **Cuándo:** sumas/restas de enteros con signo (rango -32768..32767).
- **Bandera:** OF = 1.
```asm
    MOV AX, 32767       ; maximo positivo con signo de 16 bits
    ADD AX, 1           ; 32768 no cabe: AX = 8000h = -32768
    JO  ERROR_DESBORDE  ; OF = 1: SALTA
```

### `JNO` — Overflow desactivado
- **Significa:** salta si no hubo desborde con signo.
- **Bandera:** OF = 0.
```asm
    ADD AX, BX          ; suma con signo
    JNO RESULTADO_OK    ; el resultado es valido
```

### `JS` — Signo activado
- **Significa:** salta si el bit más alto del resultado es 1 (resultado negativo en complemento a 2).
- **Cuándo:** saber si una resta dio negativo sin hacer `CMP` adicional.
- **Bandera:** SF = 1.
```asm
    MOV AX, A           ; AX = A
    SUB AX, B           ; AX = A - B
    JS  A_MENOR         ; resultado negativo: A < B (con signo)
```

### `JNS` — Signo desactivado
- **Significa:** salta si el resultado es positivo o cero (bit alto = 0).
- **Bandera:** SF = 0.
```asm
    TEST AX, AX         ; actualiza SF segun el bit 15 de AX
    JNS POSITIVO        ; bit 15 = 0: AX >= 0 (con signo)
```

### `JP` / `JPE` — Paridad par
- **Significa:** salta si el byte bajo del resultado tiene una cantidad par de bits en 1.
- **Cuándo:** comprobación de errores en comunicaciones (bit de paridad). **No sirve para saber si un número es par.**
- **Bandera:** PF = 1.
```asm
    MOV AL, 00000011b   ; dos bits en 1
    OR  AL, AL          ; actualiza PF sin cambiar AL
    JP  PARIDAD_PAR     ; SALTA: cantidad de unos par
```

### `JNP` / `JPO` — Paridad impar
- **Significa:** salta si el byte bajo tiene una cantidad impar de bits en 1.
- **Bandera:** PF = 0.
```asm
    MOV AL, 00000111b   ; tres bits en 1
    OR  AL, AL          ; actualiza PF
    JNP PARIDAD_IMPAR   ; SALTA: cantidad de unos impar
```

---

## 7. Ejemplos de comparaciones de números

### 7.1. ¿Es par o impar? (no usar PF)
```asm
    TEST AX, 1          ; AND con 1 sin guardar: aisla el bit 0
    JZ   ES_PAR         ; bit 0 = 0 -> par
    JMP  ES_IMPAR       ; bit 0 = 1 -> impar
```

### 7.2. ¿Está en un rango [1, 9]?
```asm
    CMP AX, 1           ; AX < 1 ?
    JB  FUERA_RANGO     ; si: invalido
    CMP AX, 9           ; AX > 9 ?
    JA  FUERA_RANGO     ; si: invalido
    ; aqui 1 <= AX <= 9
```

### 7.3. Tres resultados posibles (mayor, menor, igual)
```asm
    MOV AX, A           ; AX = primer valor
    CMP AX, B           ; compara A con B
    JA  A_ES_MAYOR      ; A > B
    JB  A_ES_MENOR      ; A < B
    ; si no salto en ninguno, A = B
```
(`JA` no modifica banderas, por eso el `JB` siguiente sigue evaluando el mismo `CMP`.)

### 7.4. Máximo de un vector (sin signo)
```asm
    MOV SI, OFFSET VECTOR   ; SI apunta al primer elemento
    MOV CX, N               ; cantidad de elementos
    MOV AX, [SI]            ; maximo provisional = primer elemento
MAX_CICLO:
    CMP [SI], AX            ; elemento > maximo?
    JBE MAX_SIGUE           ; no: lo ignora
    MOV AX, [SI]            ; si: nuevo maximo
MAX_SIGUE:
    ADD SI, 2               ; siguiente palabra (2 bytes)
    LOOP MAX_CICLO          ; repite N veces
```

### 7.5. Validar una tecla de dígito
```asm
    MOV AH, 01h         ; leer tecla con eco
    INT 21h             ; AL = codigo ASCII
    CMP AL, '0'         ; menor que '0'?
    JB  TECLA_INVALIDA  ; no es digito
    CMP AL, '9'         ; mayor que '9'?
    JA  TECLA_INVALIDA  ; no es digito
    SUB AL, '0'         ; AL = valor 0..9
```

---

## 8. Limitación importante: alcance de los saltos condicionales

En el 8086 **todos los saltos condicionales son cortos**: solo pueden saltar entre **-128 y +127 bytes** desde la instrucción siguiente. Si la etiqueta está más lejos (por ejemplo, porque hay macros grandes en medio), el ensamblador muestra un error de salto fuera de rango. La solución clásica es **invertir la condición** y usar un `JMP` (que no tiene ese límite):

```asm
    ; En lugar de:  JE ETIQUETA_LEJANA   (fuera de rango)
    JNE CONTINUAR           ; condicion invertida: salto corto
    JMP ETIQUETA_LEJANA     ; JMP puede llegar a cualquier punto del segmento
CONTINUAR:
```

`LOOP` y `JCXZ` tienen la misma limitación de ±127 bytes.

---

## 9. Ciclos frecuentes armados con saltos

| Estructura | Plantilla |
|---|---|
| `FOR` con `LOOP` | `MOV CX, N` / `CICLO:` ... `LOOP CICLO` (CX debe ser > 0; si CX = 0, `LOOP` repite 65536 veces → proteger con `JCXZ FIN`) |
| `WHILE` (condición al inicio) | `W_INI: CMP i, N` / `JAE W_FIN` / ... / `JMP W_INI` / `W_FIN:` |
| `DO-WHILE` (condición al final) | `D_INI:` ... `CMP AX, 0` / `JNE D_INI` |
| `IF-ELSE` | `CMP A, B` / `JNE ELSE_` / (bloque then) / `JMP FIN_IF` / `ELSE_:` (bloque else) / `FIN_IF:` |
