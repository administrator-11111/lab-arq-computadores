# Biblioteca `utils/` — Algoritmos, Macros y Procedimientos para EMU8086

Colección reutilizable de código en ensamblador **8086** compatible con **EMU8086**. Cada archivo `.asm` incluye:

- Un **bloque reutilizable** delimitado (`INICIO BLOQUE REUTILIZABLE` / `FIN BLOQUE REUTILIZABLE`) listo para copiar en cualquier ejercicio.
- Explicación de funcionamiento, registros, variables y particularidades del 8086.
- Un **programa de demostración** completo con formato explícito de segmentos (`PILA`, `DATOS`, `CODIGO`) que puede abrirse y ejecutarse directamente en EMU8086.
- Comentarios en español en todas las líneas de código.

---

## Consulta rápida (¿qué necesito hacer?)

| Si necesitas... | Carpeta / Archivo |
|---|---|
| Mostrar o leer caracteres, cadenas, números o limpiar pantalla | [`01_Macros_Entrada_Salida/macros_entrada_salida.asm`](01_Macros_Entrada_Salida/macros_entrada_salida.asm) |
| Consultar `CMP`, banderas y saltos condicionales (`JE`, `JA`, `JG`, `JC`...) | [`saltos_condicionales_8086.md`](saltos_condicionales_8086.md) |
| Declarar, inicializar, recorrer, leer o modificar un vector | [`02_Vectores/`](02_Vectores/) |
| Saber si un número es par, impar, primo, perfecto, cuadrado perfecto o narcisista | [`03_Clasificacion_Numeros/`](03_Clasificacion_Numeros/) |
| Calcular suma, promedio, mínimo, máximo o conteos sobre un vector | [`04_Analisis_Vectores/`](04_Analisis_Vectores/) |
| Ordenar un vector (Bubble, Insertion, Selection, Merge, Quick) o elegir asc/desc por variable | [`05_Ordenamiento/`](05_Ordenamiento/) |
| Extraer/contar/sumar dígitos, raíz entera, divisores, potencia, factorial o año bisiesto | [`06_Algoritmos_Matematicos/`](06_Algoritmos_Matematicos/) |
| Validar un rango por teclado, leer dígitos `0..9` o contar frecuencias | [`07_Procesamiento_Teclado/`](07_Procesamiento_Teclado/) |
| Calcular longitud o comparar cadenas (iguales, posición distinta, numéricas, palabras) | [`08_Comparacion_Cadenas/`](08_Comparacion_Cadenas/) |
| Generar números aleatorios, validar `0..30`, aplicar restricciones o elegir posiciones sin repetir | [`09_Aleatorios/`](09_Aleatorios/) |
| Comparar dos vectores posición a posición o mezclar dos vectores ordenados | [`10_Comparacion_y_Mezcla_Vectores/`](10_Comparacion_y_Mezcla_Vectores/) |

---

## Convenciones comunes de la biblioteca

- **Vectores**: definidos como palabras de 16 bits (`DW`) sin signo (`0..65535`). El elemento `i` está en el desplazamiento `2 * i`.
- **Clasificadores (`03_Clasificacion_Numeros`)**: entrada `AX` = número; salida `BL = 1` (cumple) o `BL = 0` (no cumple), `BH = 0`; conservan los demás registros.
- **Aleatorios (`09_Aleatorios`)**: requieren `SEMILLA DW 0` en `DATOS`; llamar una vez a `INICIALIZAR_SEMILLA` y luego a `GENERAR_ALEATORIO` con `BX` = mínimo, `CX` = máximo → resultado en `AX`.
- **Vectores y ordenamientos**: convención habitual `SI` = offset del vector, `CX` = cantidad de elementos.
- **Cómo integrar una rutina en tu ejercicio**: copia las macros requeridas antes de `PILA`, las variables necesarias en `DATOS`, y los procedimientos (`PROC`/`ENDP`) dentro de `CODIGO`, después de la salida a DOS (`MOV AX, 4C00h / INT 21h`).

---

## Índice completo por carpeta

### Referencia teórica

- [`saltos_condicionales_8086.md`](saltos_condicionales_8086.md) — Guía rápida de `CMP`, banderas (`CF`, `ZF`, `SF`, `OF`, `PF`), comparaciones con signo vs. sin signo, tabla completa de saltos condicionales y solución al límite de ±127 bytes.

---

### `01_Macros_Entrada_Salida/` (1 archivo)

Macros base de entrada/salida por consola mediante `INT 21h` (DOS) e `INT 10h` (BIOS).

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`macros_entrada_salida.asm`](01_Macros_Entrada_Salida/macros_entrada_salida.asm) | Macros + demo | `IMPRIMIR_CARACTER`, `IMPRIMIR_CADENA`, `IMPRIMIR_NUMERO`, `SALTO_LINEA`, `TABULACION`, `IMPRIMIR_ESPACIO`, `LEER_CARACTER`, `LEER_DIGITO`, `LEER_NUMERO`, `ASCII_A_NUMERO`, `NUMERO_A_ASCII`, `LIMPIAR_PANTALLA`, `FIN_PROGRAMA` | Ninguna | Base de todos los ejercicios interactivos y de visualización |

---

### `02_Vectores/` (7 archivos)

Declaración, acceso por índice (`i * 2`), recorrido, lectura desde teclado y generación aleatoria o restringida de vectores `DW`.

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`declarar_inicializar_vectores.asm`](02_Vectores/declarar_inicializar_vectores.asm) | Procedimientos + demo | Formas de declarar (`DW`, `DUP(0)`, `DUP(?)`), `INICIALIZAR_CEROS`, `INICIALIZAR_SECUENCIA`, `MOSTRAR_VECTOR` | Macros E/S (`01`) | Preparar arreglos antes de procesarlos |
| [`recorrer_acceder_modificar.asm`](02_Vectores/recorrer_acceder_modificar.asm) | Procedimientos + demo | `LEER_POSICION`, `ESCRIBIR_POSICION` usando `SHL BX,1` y `[BX+SI]`, recorrido y modificación con `LOOP` | Macros E/S (`01`), `MOSTRAR_VECTOR` | Consultar o actualizar un índice concreto |
| [`guardar_valores_teclado.asm`](02_Vectores/guardar_valores_teclado.asm) | Procedimiento + demo | `LEER_VECTOR` (`SI`, `CX`) con `LEER_NUMERO` | Macros E/S (`01`), `MOSTRAR_VECTOR` | Cargar datos ingresados por el usuario |
| [`llenar_vector_aleatorio.asm`](02_Vectores/llenar_vector_aleatorio.asm) | Procedimiento + demo | `LLENAR_VECTOR_ALEATORIO` (`SI`, `CX`, `BX`=mín, `DX`=máx) | Macros E/S (`01`), `SEMILLA`, `INICIALIZAR_SEMILLA`, `GENERAR_ALEATORIO`, `MOSTRAR_VECTOR` | Crear vectores de prueba aleatorios |
| [`generar_con_while.asm`](02_Vectores/generar_con_while.asm) | Procedimientos + demo | `LLENAR_SECUENCIA_WHILE` y `LLENAR_ALEATORIO_WHILE` (condición al inicio frente a `LOOP`) | Macros E/S (`01`), aleatorios (`09`), `MOSTRAR_VECTOR` | Ciclos con condición variable |
| [`dos_vectores_aleatorios.asm`](02_Vectores/dos_vectores_aleatorios.asm) | Procedimiento + demo | Genera y muestra dos vectores independientes con una sola inicialización de semilla | Macros E/S (`01`), `LLENAR_VECTOR_ALEATORIO`, `MOSTRAR_VECTOR` | Ejercicios de comparación o mezcla |
| [`vectores_restringidos.asm`](02_Vectores/vectores_restringidos.asm) | Procedimientos + demo | `LLENAR_SOLO_PRIMOS`, `LLENAR_SOLO_RAIZ_EXACTA`, `LLENAR_SOLO_IMPARES` con ciclo `WHILE` | Macros E/S (`01`), aleatorios (`09`), clasificadores (`03`), `MOSTRAR_VECTOR` | Llenar vectores que cumplan filtros matemáticos |

---

### `03_Clasificacion_Numeros/` (7 archivos)

Procedimientos independientes para clasificar un entero sin signo de 16 bits (`AX` → `BL = 1/0`).

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`es_par.asm`](03_Clasificacion_Numeros/es_par.asm) | Procedimiento + demo | `ES_PAR` mediante `TEST AX, 1` | Ninguna (demo: macros `01`) | Conteo o filtrado de pares |
| [`es_impar.asm`](03_Clasificacion_Numeros/es_impar.asm) | Procedimiento + demo | `ES_IMPAR` mediante `TEST AX, 1` | Ninguna (demo: macros `01`) | Conteo o filtrado de impares |
| [`es_primo.asm`](03_Clasificacion_Numeros/es_primo.asm) | Procedimiento + demo | `ES_PRIMO` probando divisores `2..sqrt(n)` con control de desborde `DX` | Ninguna (demo: macros `01`) | Primos en vectores y aleatorios |
| [`es_perfecto.asm`](03_Clasificacion_Numeros/es_perfecto.asm) | Procedimiento + demo | `ES_PERFECTO` sumando divisores propios `1..n/2` con control de acarreo | Ninguna (demo: macros `01`) | Análisis estadístico de vectores |
| [`tiene_raiz_exacta.asm`](03_Clasificacion_Numeros/tiene_raiz_exacta.asm) | Procedimiento + demo | `TIENE_RAIZ_EXACTA` probando `r*r <= n` | Ninguna (demo: macros `01`) | Cuadrados perfectos |
| [`es_narcisista.asm`](03_Clasificacion_Numeros/es_narcisista.asm) | Procedimiento + demo | `ES_NARCISISTA` (Armstrong) contando cifras `k` y sumando `cifra^k` | Ninguna (demo: macros `01`) | Análisis de propiedades numéricas |
| [`clasificar_numero_completo.asm`](03_Clasificacion_Numeros/clasificar_numero_completo.asm) | Algoritmo + demo | Lee un número por teclado y evalúa las 6 clasificaciones a la vez | Macros E/S (`01`) + los 6 procedimientos de esta carpeta | Verificación rápida de un número |

---

### `04_Analisis_Vectores/` (5 archivos)

Estadísticas y conteos sobre vectores `DW` (`SI` = offset, `CX` = cantidad).

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`suma_promedio.asm`](04_Analisis_Vectores/suma_promedio.asm) | Procedimientos + demo | `SUMA_VECTOR` en 32 bits (`DX:AX` con `ADD`/`ADC`) y `PROMEDIO_VECTOR` (cociente `AX` y residuo `DX`, protege `CX=0`) | Macros E/S (`01`), `MOSTRAR_VECTOR` | Sumatoria y media aritmética |
| [`minimo_maximo.asm`](04_Analisis_Vectores/minimo_maximo.asm) | Procedimientos + demo | `MINIMO_VECTOR` y `MAXIMO_VECTOR` sin signo (`JAE`/`JBE`) | Macros E/S (`01`), `MOSTRAR_VECTOR` | Extremos de un conjunto de datos |
| [`contar_pares_impares.asm`](04_Analisis_Vectores/contar_pares_impares.asm) | Procedimientos + demo | `CONTAR_PARES` y `CONTAR_IMPARES` | `ES_PAR`, `ES_IMPAR` (`03`), macros `01` | Conteos básicos sobre arreglos |
| [`contar_clasificados.asm`](04_Analisis_Vectores/contar_clasificados.asm) | Procedimientos + demo | `CONTAR_PRIMOS`, `CONTAR_PERFECTOS`, `CONTAR_RAIZ_EXACTA`, `CONTAR_NARCISISTAS` | Clasificadores (`03`), macros `01` | Conteos con propiedades matemáticas |
| [`analisis_un_recorrido.asm`](04_Analisis_Vectores/analisis_un_recorrido.asm) | Procedimiento + demo | `ANALIZAR_VECTOR`: calcula suma, promedio, mínimo, máximo y los 6 conteos en una sola pasada | Variables de salida en `DATOS`, los 6 clasificadores (`03`), macros `01` | Laboratorios de análisis integral de vectores |

---

### `05_Ordenamiento/` (6 archivos)

Los cinco algoritmos clásicos de ordenamiento sobre vectores `DW` sin signo, todos con selección de sentido mediante `SENTIDO DB` (`0` = ascendente, `1` = descendente).

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`bubble_sort.asm`](05_Ordenamiento/bubble_sort.asm) | Algoritmo + demo | `BUBBLE_SORT` con bandera de parada anticipada | Variable `SENTIDO DB` (demo: macros `01`, `MOSTRAR_VECTOR`) | Ordenamiento sencillo y educativo |
| [`insertion_sort.asm`](05_Ordenamiento/insertion_sort.asm) | Algoritmo + demo | `INSERTION_SORT` usando base `BX` y desplazamientos `SI`/`DI` | Variable `SENTIDO DB` (demo: macros `01`, `MOSTRAR_VECTOR`) | Vectores pequeños o casi ordenados |
| [`selection_sort.asm`](05_Ordenamiento/selection_sort.asm) | Algoritmo + demo | `SELECTION_SORT` con mínimo/máximo y a lo sumo `N-1` intercambios | Variable `SENTIDO DB` (demo: macros `01`, `MOSTRAR_VECTOR`) | Minimizar intercambios en memoria |
| [`merge_sort.asm`](05_Ordenamiento/merge_sort.asm) | Algoritmo + demo | `MERGE_SORT` recursivo (`MS_DIVIDIR`, `MS_MEZCLAR`) con pila 256 palabras y vector auxiliar `MS_AUX` | `SENTIDO DB`, `MS_AUX`, `MS_BASE`, `MS_LIM_I`, `MS_LIM_J` | Ordenamiento divide y vencerás estable |
| [`quick_sort.asm`](05_Ordenamiento/quick_sort.asm) | Algoritmo + demo | `QUICK_SORT` recursivo con partición de Lomuto y guardas sin signo (`QS_ORDENAR`, `QS_PARTICION`) | `SENTIDO DB`, `QS_BASE`, `QS_PTR_DER`, pila 256 palabras | Ordenamiento in-place rápido |
| [`ordenar_segun_variable.asm`](05_Ordenamiento/ordenar_segun_variable.asm) | Algoritmo + demo | `ORDENAR_SEGUN_SENTIDO` (versión de referencia controlada por `SENTIDO DB`) con demo interactiva | `SENTIDO DB`, macros `01`, `MOSTRAR_VECTOR` | Ejercicios que piden ascendente/descendente según variable |

---

### `06_Algoritmos_Matematicos/` (6 archivos)

Operaciones aritméticas, descomposición en cifras, divisores y lógica matemática respetando el rango de 16 bits.

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`digitos_extraer_contar_sumar.asm`](06_Algoritmos_Matematicos/digitos_extraer_contar_sumar.asm) | Procedimientos + demo | `EXTRAER_DIGITOS` (izq→der en vector), `CONTAR_DIGITOS`, `SUMAR_DIGITOS` | Ninguna (demo: macros `01`, `MOSTRAR_VECTOR`) | Manipulación de cifras decimales |
| [`raiz_cuadrada_entera.asm`](06_Algoritmos_Matematicos/raiz_cuadrada_entera.asm) | Procedimiento + demo | `RAIZ_CUADRADA_ENTERA` (`AX` = parte entera, `BL` = 1 si exacta) | Ninguna (demo: macros `01`) | Cálculo de raíz entera y exactitud |
| [`divisores_y_suma_divisores.asm`](06_Algoritmos_Matematicos/divisores_y_suma_divisores.asm) | Procedimientos + demo | `MOSTRAR_DIVISORES`, `CONTAR_DIVISORES`, `SUMA_DIVISORES_PROPIOS` (relación con primo/perfecto) | `MOSTRAR_DIVISORES` usa `IMPRIMIR_NUMERO`/`IMPRIMIR_ESPACIO` (`01`) | Problemas de divisibilidad |
| [`anio_bisiesto.asm`](06_Algoritmos_Matematicos/anio_bisiesto.asm) | Procedimiento + demo | `ES_BISIESTO` (reglas 4/100/400) guardando en `VarEsBisiesto` y `VarNoEsBisiesto` | Variables `VarEsBisiesto DB`, `VarNoEsBisiesto DB` | Lógica condicional y divisiones |
| [`potencia.asm`](06_Algoritmos_Matematicos/potencia.asm) | Procedimiento + demo | `POTENCIA` (`base^exp` por multiplicaciones sucesivas, exp 0 → 1, aviso de desborde > 65535) | Ninguna (demo: macros `01`) | Potenciación entera en 16 bits |
| [`factorial.asm`](06_Algoritmos_Matematicos/factorial.asm) | Procedimiento + demo | `FACTORIAL` (`0!=1`, `1!=1`, límite `8!=40320`, aviso de desborde para `n >= 9`) | Ninguna (demo: macros `01`) | Combinatoria y ciclos multiplicativos |

---

### `07_Procesamiento_Teclado/` (3 archivos)

Lectura validada por rango, captura de dígitos individuales y conteo de frecuencias.

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`leer_n_validado.asm`](07_Procesamiento_Teclado/leer_n_validado.asm) | Procedimiento + demo | `LEER_EN_RANGO` repite la lectura hasta que `MINIMO <= N <= MAXIMO` | Macros E/S (`01`), variables `MINIMO`, `MAXIMO` | Validar tamaños o menús por teclado |
| [`leer_digitos_vector.asm`](07_Procesamiento_Teclado/leer_digitos_vector.asm) | Procedimiento + demo | `LEER_DIGITOS_VECTOR` lee `N` dígitos `0..9` rechazando otras teclas | Macros E/S (`01`), `MOSTRAR_VECTOR` | Capturar secuencias de un dígito |
| [`frecuencia_digitos.asm`](07_Procesamiento_Teclado/frecuencia_digitos.asm) | Algoritmo + demo | `CONTAR_FRECUENCIAS` (indexación `digito * 2` sobre `FRECUENCIA DW 10 DUP(0)`) y `MOSTRAR_FRECUENCIAS` | Macros E/S (`01`), `MOSTRAR_VECTOR` | Histogramas y conteo de ocurrencias |

---

### `08_Comparacion_Cadenas/` (6 archivos)

Operaciones sobre cadenas terminadas en `'$'` y buffers de teclado `INT 21h AH=0Ah`.

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`longitud_cadena.asm`](08_Comparacion_Cadenas/longitud_cadena.asm) | Procedimiento + demo | `LONGITUD_CADENA` para cadenas `'$'` y uso del buffer `AH=0Ah` (`[max][leidos][texto][0Dh]`) | Macros E/S (`01`) | Medir cadenas antes de compararlas |
| [`comparar_cadenas_iguales.asm`](08_Comparacion_Cadenas/comparar_cadenas_iguales.asm) | Procedimientos + demo | `COMPARAR_CADENAS` (manual con `SI`/`DI`) y `COMPARAR_CADENAS_CMPSB` (`ES=DS`, `CLD`, `REPE CMPSB`) | `LONGITUD_CADENA`, macros E/S (`01`) | Verificar igualdad exacta |
| [`comparar_caracter_por_caracter.asm`](08_Comparacion_Cadenas/comparar_caracter_por_caracter.asm) | Procedimiento + demo | `COMPARAR_POSICION`: cantidad de coincidencias iniciales y primera posición donde difieren | Macros E/S (`01`) | Detectar diferencias exactas entre textos |
| [`comparar_cadenas_teclado.asm`](08_Comparacion_Cadenas/comparar_cadenas_teclado.asm) | Algoritmo + demo | `LEER_CADENA_TECLADO` (`AH=0Ah` + conversión de `0Dh` a `'$'`) y comparación de dos entradas | `LONGITUD_CADENA`, `COMPARAR_CADENAS`, macros `01` | Validación de claves o textos ingresados |
| [`comparar_cadenas_numericas.asm`](08_Comparacion_Cadenas/comparar_cadenas_numericas.asm) | Procedimiento + demo | `COMPARAR_NUMERICAS`: omite ceros a la izquierda, compara longitud y luego dígito a dígito | `LONGITUD_CADENA`, macros E/S (`01`) | Comparar números grandes como texto |
| [`comparar_palabras.asm`](08_Comparacion_Cadenas/comparar_palabras.asm) | Procedimientos + demo | `A_MAYUSCULA` y `COMPARAR_PALABRAS`: igualdad sin distinguir mayúsculas y orden alfabético | Macros E/S (`01`) | Ordenamiento o búsqueda de palabras |

---

### `09_Aleatorios/` (4 archivos)

Generador pseudoaleatorio LCG con semilla del reloj del sistema y sus aplicaciones.

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`generar_aleatorio.asm`](09_Aleatorios/generar_aleatorio.asm) | Procedimientos + demo | `INICIALIZAR_SEMILLA` (`INT 21h/2Ch`) y `GENERAR_ALEATORIO` (LCG + `XCHG AH,AL` + módulo `[BX, CX]`) | Variable `SEMILLA DW 0` (demo: macros `01`) | Base de cualquier generación aleatoria |
| [`n_aleatorios_validado.asm`](09_Aleatorios/n_aleatorios_validado.asm) | Algoritmo + demo | Valida `0 <= N <= 30`, llena vector con `LLENAR_ALEATORIOS` y cuenta primos / no primos | Macros E/S (`01`), `GENERAR_ALEATORIO`, `ES_PRIMO` (`03`), `MOSTRAR_VECTOR` | Ejercicios de generación validada y conteo |
| [`aleatorios_restringidos.asm`](09_Aleatorios/aleatorios_restringidos.asm) | Algoritmo + demo | `ALEATORIO_PRIMO`, `ALEATORIO_RAIZ_EXACTA`, `ALEATORIO_IMPAR_RECHAZO` y `ALEATORIO_IMPAR_DIRECTO` (`2*k+1`) | Macros E/S (`01`), `GENERAR_ALEATORIO`, clasificadores (`03`) | Generación con condiciones matemáticas |
| [`seleccion_posiciones_aleatorias.asm`](09_Aleatorios/seleccion_posiciones_aleatorias.asm) | Algoritmo + demo | `SELECCIONAR_POSICIONES`: elige 5 posiciones distintas (`USADA DB 20 DUP(0)`) en un vector de 20, permitiendo valores repetidos, y calcula el promedio | Macros E/S (`01`), `GENERAR_ALEATORIO`, `MOSTRAR_VECTOR` | Muestreo aleatorio sin reposición de índices |

---

### `10_Comparacion_y_Mezcla_Vectores/` (3 archivos)

Operaciones combinadas entre dos vectores.

| Archivo | Tipo | Funcionalidad | Dependencias | Uso típico |
|---|---|---|---|---|
| [`comparar_dos_vectores.asm`](10_Comparacion_y_Mezcla_Vectores/comparar_dos_vectores.asm) | Procedimiento + demo | `COMPARAR_VECTORES`: compara posición por posición, acumula `PUNTOS_V1`/`PUNTOS_V2` (empates no suman) y determina ganador o empate | Variables `PUNTOS_V1`, `PUNTOS_V2`; demo: macros `01`, aleatorios `09` | Competencia o contraste de dos arreglos |
| [`mezclar_vectores_ordenados.asm`](10_Comparacion_y_Mezcla_Vectores/mezclar_vectores_ordenados.asm) | Procedimiento + demo | `MEZCLAR_VECTORES`: combina dos vectores ascendentes en un tercero ordenado en tiempo lineal sin reordenar todo | Macros E/S (`01`), `MOSTRAR_VECTOR` | Fusión (merge) de listas ordenadas |
| [`ordenar_y_mezclar_segun_variable.asm`](10_Comparacion_y_Mezcla_Vectores/ordenar_y_mezclar_segun_variable.asm) | Algoritmo + demo | Ordena dos vectores desordenados, los mezcla con `MEZCLAR_VECTORES` y aplica `SENTIDO_FINAL` (ref. `05_Ordenamiento/ordenar_segun_variable.asm`) | `ORDENAR_SEGUN_SENTIDO` (`05`), `MEZCLAR_VECTORES`, macros `01` | Flujo completo de ordenar y mezclar |
