# Monopoly en Prolog

Proyecto de la practica de **Conocimiento y Razonamiento Automatizado**. El repositorio implementa una version simplificada de Monopoly con un **motor de juego en SWI-Prolog** y una **aplicacion de terminal en Python** para ejecutar simulaciones, reproducir partidas paso a paso y analizar resultados.

## Autores

- Alvaro Fuentes Lozano
- Lucia Cantero Anchuelo
- Rodrigo Rey Henche

## Que hay en el proyecto

El nucleo del juego esta en Prolog. Ahi se modelan:

- el estado del juego y el tablero base,
- el movimiento por turnos,
- compras y alquileres,
- monopolios,
- bancarrota,
- carcel y dobles,
- hipotecas y deshipotecas,
- construccion de casas,
- metricas de simulacion,
- ranking final por patrimonio.

Encima de ese motor, Python aporta una interfaz de terminal que permite:

- ver escenarios precargados definidos en Prolog,
- ejecutar partidas paso a paso con traza,
- crear escenarios personalizados,
- lanzar una partida rapida aleatoria,
- ejecutar analisis por lotes con resumen agregado.

## Estructura real del repositorio

```text
Practica1-Monopolio-Prolog/
|-- prolog/
|   |-- main.pl
|   |-- scenarios.pl
|   |-- bridges/
|   |   `-- python_bridge_trace.pl
|   `-- tests/
|       `-- monopoly_tests.pl
|-- docs/
|   |-- enunciado/
|   `-- notas/
|-- analisis_lotes.py
|-- launcher_monopoly.py
|-- README.md
`-- LICENSE
```

## Componentes principales

### `prolog/main.pl`

Motor principal del juego. Implementa el tablero, el movimiento, las reglas, la gestion de carcel, hipotecas, casas, bancarrota, metricas y ranking.

### `prolog/scenarios.pl`

Catalogo de escenarios reproducibles del proyecto. Incluye casos de compras, monopolios, alquileres, dobles, carcel, hipotecas, patrimonio y construccion de casas.

### `prolog/bridges/python_bridge_trace.pl`

Puente entre Prolog y Python. Convierte el estado y la traza de la simulacion a JSON para que la aplicacion Python pueda mostrar:

- estados inicial y final,
- pasos intermedios,
- detalle del actor de cada accion,
- metricas acumuladas,
- ranking final,
- metadatos del escenario.

### `launcher_monopoly.py`

Aplicacion principal de terminal. Muestra el tablero en ASCII y ofrece un menu interactivo con todas las opciones de simulacion.

### `analisis_lotes.py`

Utilidades de apoyo para generar configuraciones aleatorias y acumular estadisticas en ejecuciones por lotes.

### `prolog/tests/monopoly_tests.pl`

Suite de tests en Prolog para validar reglas y escenarios del motor.

## Requisitos

- `swipl` disponible en el `PATH`
- `python` disponible en el `PATH`

En este entorno se ha comprobado la presencia de:

- SWI-Prolog `10.0.0`
- Python `3.14.3`

## Como ejecutar

### Ejecutar la app de terminal

```powershell
python launcher_monopoly.py
```

El menu actual permite:

1. Ver escenarios precargados
2. Ejecutar escenario precargado
3. Crear escenario personalizado
4. Partida rapida aleatoria
5. Analisis por lotes
6. Salir

### Ejecutar los tests de Prolog

```powershell
swipl -q -s prolog/tests/monopoly_tests.pl -g run_tests,halt
```

### Cargar el motor manualmente en Prolog

```powershell
swipl
```

Y dentro de la consola:

```prolog
['prolog/scenarios.pl'].
resolver_escenario_metricas(esc5, EstadoFinal, Metricas).
ranking_jugadores(EstadoFinal, Ranking).
```

## Escenarios incluidos

El catalogo actual de `prolog/scenarios.pl` contiene 25 escenarios (`esc1` a `esc25`) orientados a comprobar comportamientos concretos, entre ellos:

- compras iniciales,
- monopolios,
- bancarrota por alquiler,
- dobles y tercer doble a carcel,
- salida de carcel por doble o pagando,
- hipotecas y deshipotecas,
- alquiler bloqueado por hipoteca,
- construccion de casas,
- restricciones de construccion,
- estabilidad de patrimonio y ranking.

La aplicacion Python consulta este catalogo directamente desde Prolog, por lo que la lista visible en el menu siempre sale del motor real.

## Como funciona la arquitectura

- **Prolog** decide la logica del juego y ejecuta las simulaciones.
- **Python** construye escenarios de entrada, llama a Prolog y representa la salida.
- El archivo `prolog/bridges/python_bridge_trace.pl` serializa el resultado en JSON para desacoplar la logica de la visualizacion.

## Analisis por lotes

La opcion de analisis por lotes permite ejecutar muchas partidas seguidas con configuraciones parcialmente fijas o aleatorias. El resumen final agrega, entre otros datos:

- numero de partidas,
- victorias en primera posicion,
- medias de pasos, compras, alquileres, bancarrotas y monopolios,
- patrimonio, dinero y propiedades medias por jugador.

## Documentacion adicional

- `docs/enunciado/` contiene el enunciado de la practica.
- `docs/notas/` guarda notas auxiliares y pruebas.

## Licencia

El repositorio incluye un archivo `LICENSE` con la licencia del proyecto.
