# Programas Completos (`ejercicios_completos/`) para EMU8086

Colección de **21 programas completos, independientes y ejecutables** en ensamblador **8086**, organizados por temática. Todos utilizan el formato explícito de segmentos requerido en el laboratorio (`PILA`, `DATOS`, `CODIGO`, `ASSUME CS:CODIGO, DS:DATOS, SS:PILA`, `INICIO:` y `END INICIO`), incluyen comentarios en español en cada línea y no dependen de archivos externos ni directivas `INCLUDE`.

---

## Cómo abrir y ejecutar un programa en EMU8086

1. Abre **EMU8086**.
2. Selecciona **File → Open** (o *Open Existing*) y elige cualquier archivo `.asm` de las subcarpetas de `ejercicios_completos/`.
3. Haz clic en **Emulate** (o presiona `F5`). EMU8086 ensamblará el archivo y abrirá la ventana del emulador junto con la consola de salida.
4. Presiona **Run** para ejecutar el programa completo, o **Single Step** (`F8`) para avanzar instrucción por instrucción inspeccionando los registros (`AX`, `BX`, `CX`, `DX`, `SI`, `DI`), las banderas (`FLAGS`) y las variables en **View → Vars**.
5. Si el programa solicita entrada por teclado, haz clic sobre la ventana negra de la consola del emulador, escribe los datos y presiona `Enter` cuando corresponda.

> **Nota sobre caracteres:** las cadenas de texto en consola se escriben sin tildes ni `ñ` para que se muestren limpiamente en la tabla ASCII estándar de DOS/EMU8086.

---

## Índice de programas completos

### `01_Vectores_y_Analisis/` (3 programas)

| Ejercicio | Archivo | Descripción breve | `utils/` relacionados |
|---|---|---|---|
| Análisis de un vector | [`01_analisis_vector.asm`](01_Vectores_y_Analisis/01_analisis_vector.asm) | Genera un vector aleatorio de 15 elementos (`1..500`), lo muestra y calcula suma, promedio (con residuo), mínimo y cantidad de pares, primos, raíz cuadrada exacta y narcisistas. | `01_Macros_Entrada_Salida/macros_entrada_salida.asm`, `02_Vectores/llenar_vector_aleatorio.asm`, `04_Analisis_Vectores/` |
| Tres vectores restringidos | [`02_tres_vectores_restringidos.asm`](01_Vectores_y_Analisis/02_tres_vectores_restringidos.asm) | Genera y muestra tres vectores de 10 elementos (`1..200`): uno solo con primos, uno solo con raíz cuadrada exacta y uno solo con impares. | `01_Macros_Entrada_Salida/macros_entrada_salida.asm`, `02_Vectores/vectores_restringidos.asm`, `03_Clasificacion_Numeros/` |
| Dos vectores aleatorios | [`03_dos_vectores_aleatorios.asm`](01_Vectores_y_Analisis/03_dos_vectores_aleatorios.asm) | Genera dos vectores independientes de 10 números aleatorios (`1..100`) y muestra sus elementos. | `01_Macros_Entrada_Salida/macros_entrada_salida.asm`, `02_Vectores/dos_vectores_aleatorios.asm`, `09_Aleatorios/generar_aleatorio.asm` |

---

### `02_Aleatorios/` (2 programas)

| Ejercicio | Archivo | Descripción breve | `utils/` relacionados |
|---|---|---|---|
| N números aleatorios y primos | [`01_n_aleatorios_primos.asm`](02_Aleatorios/01_n_aleatorios_primos.asm) | Solicita `N`, valida que esté entre `0` y `30`, genera `N` números aleatorios (`1..100`), los muestra y cuenta cuántos son primos y cuántos no son primos. | `01_Macros_Entrada_Salida/macros_entrada_salida.asm`, `09_Aleatorios/n_aleatorios_validado.asm`, `03_Clasificacion_Numeros/es_primo.asm` |
| Promedio de cinco posiciones aleatorias | [`02_promedio_cinco_posiciones.asm`](02_Aleatorios/02_promedio_cinco_posiciones.asm) | Crea un vector de 20 aleatorios, elige 5 posiciones distintas sin repetir índices (permitiendo valores iguales en posiciones distintas), muestra los 5 valores y calcula su promedio. | `01_Macros_Entrada_Salida/macros_entrada_salida.asm`, `09_Aleatorios/seleccion_posiciones_aleatorias.asm` |

---

### `03_Ordenamiento/` (6 programas)

Todos generan un vector aleatorio de 10 elementos (`1..99`) y muestran el vector original y el vector ordenado.

| Ejercicio | Archivo | Descripción breve | `utils/` relacionados |
|---|---|---|---|
| Bubble Sort | [`01_bubble_sort.asm`](03_Ordenamiento/01_bubble_sort.asm) | Ordena ascendentemente con burbuja y parada anticipada. | `05_Ordenamiento/bubble_sort.asm`, `09_Aleatorios/generar_aleatorio.asm` |
| Insertion Sort | [`02_insertion_sort.asm`](03_Ordenamiento/02_insertion_sort.asm) | Ordena ascendentemente por inserción directa. | `05_Ordenamiento/insertion_sort.asm`, `09_Aleatorios/generar_aleatorio.asm` |
| Selection Sort | [`03_selection_sort.asm`](03_Ordenamiento/03_selection_sort.asm) | Ordena ascendentemente por selección del mínimo. | `05_Ordenamiento/selection_sort.asm`, `09_Aleatorios/generar_aleatorio.asm` |
| Merge Sort | [`04_merge_sort.asm`](03_Ordenamiento/04_merge_sort.asm) | Ordena ascendentemente mediante Merge Sort recursivo con vector auxiliar. | `05_Ordenamiento/merge_sort.asm`, `09_Aleatorios/generar_aleatorio.asm` |
| Quick Sort | [`05_quick_sort.asm`](03_Ordenamiento/05_quick_sort.asm) | Ordena ascendentemente mediante Quick Sort recursivo (partición de Lomuto). | `05_Ordenamiento/quick_sort.asm`, `09_Aleatorios/generar_aleatorio.asm` |
| Ordenamiento asc/desc según variable | [`06_ordenar_asc_desc_variable.asm`](03_Ordenamiento/06_ordenar_asc_desc_variable.asm) | Controla el sentido del ordenamiento mediante `SENTIDO DB` en `DATOS` (`0` ascendente, `1` descendente) y muestra el resultado. | `05_Ordenamiento/ordenar_segun_variable.asm`, `09_Aleatorios/generar_aleatorio.asm` |

---

### `04_Comparacion_y_Mezcla/` (2 programas)

| Ejercicio | Archivo | Descripción breve | `utils/` relacionados |
|---|---|---|---|
| Comparación de dos vectores | [`01_comparar_dos_vectores.asm`](04_Comparacion_y_Mezcla/01_comparar_dos_vectores.asm) | Genera dos vectores de 8 elementos, los compara posición a posición, cuenta victorias de cada uno (empates no suman) e informa el ganador o empate. | `10_Comparacion_y_Mezcla_Vectores/comparar_dos_vectores.asm`, `09_Aleatorios/generar_aleatorio.asm` |
| Mezcla de vectores ordenados | [`02_mezcla_vectores.asm`](04_Comparacion_y_Mezcla/02_mezcla_vectores.asm) | Combina dos vectores previamente ordenados ascendentemente (5 y 6 elementos) en un tercer vector ordenado de 11 elementos sin reordenar todo y muestra los tres. | `10_Comparacion_y_Mezcla_Vectores/mezclar_vectores_ordenados.asm` |

---

### `05_Cadenas/` (4 programas)

| Ejercicio | Archivo | Descripción breve | `utils/` relacionados |
|---|---|---|---|
| Comparar cadenas en memoria | [`01_comparar_cadenas_memoria.asm`](05_Cadenas/01_comparar_cadenas_memoria.asm) | Compara pares de cadenas almacenadas en `DATOS` verificando primero su longitud y luego carácter por carácter. | `08_Comparacion_Cadenas/longitud_cadena.asm`, `08_Comparacion_Cadenas/comparar_cadenas_iguales.asm` |
| Comparar cadenas por teclado | [`02_comparar_cadenas_teclado.asm`](05_Cadenas/02_comparar_cadenas_teclado.asm) | Lee dos cadenas con `INT 21h AH=0Ah`, muestra sus longitudes, indica si son iguales o diferentes y reporta la primera posición distinta. | `08_Comparacion_Cadenas/comparar_cadenas_teclado.asm`, `08_Comparacion_Cadenas/comparar_caracter_por_caracter.asm` |
| Comparar cadenas numéricas | [`03_comparar_cadenas_numericas.asm`](05_Cadenas/03_comparar_cadenas_numericas.asm) | Lee dos cadenas numéricas (hasta 40 cifras), omite ceros a la izquierda y determina qué número es mayor o si son iguales. | `08_Comparacion_Cadenas/comparar_cadenas_numericas.asm` |
| Comparar palabras | [`04_comparar_palabras.asm`](05_Cadenas/04_comparar_palabras.asm) | Lee dos palabras, las compara carácter por carácter ignorando mayúsculas/minúsculas e indica su orden alfabético. | `08_Comparacion_Cadenas/comparar_palabras.asm` |

---

### `06_Matematicos_y_Logica/` (3 programas)

| Ejercicio | Archivo | Descripción breve | `utils/` relacionados |
|---|---|---|---|
| Año bisiesto | [`01_anio_bisiesto.asm`](06_Matematicos_y_Logica/01_anio_bisiesto.asm) | Evalúa el año cargado previamente en `AX` (reglas de divisibilidad por 4, 100 y 400), guarda el resultado en `VarEsBisiesto` y `VarNoEsBisiesto` y lo muestra en pantalla. | `06_Algoritmos_Matematicos/anio_bisiesto.asm` |
| Potencia | [`02_potencia.asm`](06_Matematicos_y_Logica/02_potencia.asm) | Lee base y exponente por teclado, calcula `base^exp` por multiplicaciones sucesivas, contempla exponente `0` (`= 1`) y detecta desborde de 16 bits. | `06_Algoritmos_Matematicos/potencia.asm`, `01_Macros_Entrada_Salida/macros_entrada_salida.asm` |
| Factorial | [`03_factorial.asm`](06_Matematicos_y_Logica/03_factorial.asm) | Lee `n` por teclado, valida el rango representable en 16 bits (`0..8`, donde `8! = 40320`), contempla `0! = 1` y `1! = 1` y muestra el resultado. | `06_Algoritmos_Matematicos/factorial.asm`, `01_Macros_Entrada_Salida/macros_entrada_salida.asm` |

---

### `07_Procesamiento_Teclado/` (1 programa)

| Ejercicio | Archivo | Descripción breve | `utils/` relacionados |
|---|---|---|---|
| Frecuencia de dígitos | [`01_frecuencia_digitos.asm`](07_Procesamiento_Teclado/01_frecuencia_digitos.asm) | Solicita `N` validado entre `1` y `9`, lee `N` dígitos (`0..9`), los guarda en un vector, cuenta cuántas veces aparece cada dígito `0..9` y muestra la tabla de frecuencias usando macros de E/S. | `01_Macros_Entrada_Salida/macros_entrada_salida.asm`, `07_Procesamiento_Teclado/` |
