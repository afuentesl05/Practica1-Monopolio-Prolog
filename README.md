# Monopoly en Prolog

Proyecto de la practica de **Conocimiento y Razonamiento Automatizado**. La idea del trabajo es modelar una version simplificada de Monopoly en **SWI-Prolog** y luego apoyarnos en **Python** para visualizar partidas, escenarios y simulaciones.

No hemos intentado hacer el Monopoly comercial completo, sino una base razonable para trabajar estados, reglas, transiciones, metricas y analisis de partidas.

## Autores

- Alvaro Fuentes Lozano
- Lucia Cantero Anchuelo
- Rodrigo Rey Henche

## Que hace el proyecto

El nucleo del proyecto esta en Prolog. Ahi se define:

- el estado del juego,
- el tablero,
- el movimiento por turnos,
- la compra de propiedades,
- los alquileres,
- los monopolios,
- la bancarrota,
- la carcel y los dobles,
- las hipotecas,
- la construccion de casas,
- las metricas,
- y el ranking dinamico por patrimonio.

A partir de ese motor hemos montado tres formas de usar el proyecto:

1. una app de terminal para ver la partida paso a paso en ASCII;
2. una interfaz grafica para visualizar escenarios y partidas aleatorias;
3. una interfaz separada para lanzar muchas simulaciones y sacar metricas agregadas.

## Estructura del proyecto

```text
Practica1-Monopolio-Prolog/
|-- prolog/
|   |-- main.pl
|   |-- scenarios.pl
|   |-- bridges/
|   |   |-- bridge_trace_ui.pl
|   |   |-- bridge_batch_ui.pl
|   |   `-- python_bridge_trace.pl
|   `-- tests/
|       `-- monopoly_tests.pl
|-- ui_monopoly/
|   |-- app.py
|   |-- main_window.py
|   |-- board_widget.py
|   `-- bridge_client.py
|-- ui_batch/
|   |-- app.py
|   |-- main_window.py
|   `-- bridge_client.py
|-- docs/
|   |-- enunciado/
|   `-- notas/
|-- launcher_monopoly.py
|-- launcher_batch.py
|-- README.md
`-- LICENSE
```

## Para que sirve cada parte

### `prolog/main.pl`
Es el motor principal del juego. Aqui esta la logica importante del proyecto.

### `prolog/scenarios.pl`
Contiene escenarios preparados para probar comportamientos concretos: compras, alquileres, carcel, hipotecas, casas, patrimonio, etc.

### `prolog/bridges/`
Son los puentes entre Prolog y Python.

- `bridge_trace_ui.pl`: usado por la interfaz grafica principal.
- `bridge_batch_ui.pl`: usado por la app de simulaciones por lotes.
- `python_bridge_trace.pl`: usado por la app de terminal ASCII.

### `ui_monopoly/`
Es la app visual principal. Sirve para cargar escenarios o generar partidas aleatorias y verlas paso a paso.

### `ui_batch/`
Es la app de analisis. Sirve para ejecutar muchas simulaciones y ver metricas globales.

### `launcher_monopoly.py`
Arranca la aplicacion de terminal.

### `launcher_batch.py`
Arranca la app de simulaciones por lotes.

## Requisitos

Para ejecutar el proyecto hace falta tener:

- `swipl` en el `PATH`
- `python` en el `PATH`
- `PySide6` instalado para las interfaces graficas

## Como ejecutar el proyecto

### 1. Ejecutar los tests de Prolog

```powershell
swipl -q -s prolog/tests/monopoly_tests.pl -g run_tests,halt
```

### 2. Cargar Prolog a mano

```powershell
swipl
```

Y ya dentro:

```prolog
['prolog/scenarios.pl'].
listar_escenarios.
ejecutar_escenario_metricas(esc5, EstadoFinal, Metricas).
```

### 3. Ejecutar la app de terminal ASCII

```powershell
python launcher_monopoly.py
```

Esta app permite:

- ver escenarios precargados,
- ejecutarlos paso a paso,
- crear escenarios personalizados,
- y lanzar partidas aleatorias sencillas.

### 4. Ejecutar la interfaz grafica principal

Puedes abrirla de cualquiera de estas dos formas:

```powershell
python -m ui_monopoly.app
```

O si prefieres desde Python importado:

```powershell
python -c "from ui_monopoly.app import main; main()"
```

Esta interfaz sirve para:

- cargar escenarios del catalogo,
- generar partidas aleatorias,
- avanzar paso a paso,
- usar autoplay,
- ver el tablero,
- ver el ranking dinamico,
- y seguir visualmente la evolucion de la partida.

### 5. Ejecutar la app de simulaciones por lotes

```powershell
python launcher_batch.py
```

Esta app sirve para:

- ejecutar un banco de `N` simulaciones aleatorias,
- ver cuantas partidas terminan y cuantas no,
- comparar compras, alquileres y bancarrotas,
- y revisar el resultado individual de cada simulacion.

## Como funciona en general

La arquitectura del proyecto es bastante simple:

- **Prolog** resuelve la logica del juego.
- **Python** no decide reglas del juego: solo lanza consultas, recibe resultados y los representa.
- Los **bridges** convierten estados de Prolog a JSON para que las apps Python puedan consumirlos.

Esto nos ha venido bien porque separa bastante bien la parte logica de la parte visual.

## Escenarios y validacion

Una parte importante del proyecto son los escenarios reproducibles de `prolog/scenarios.pl`.

Nos sirven para:

- comprobar que cada regla funciona,
- preparar casos de defensa,
- comparar comportamiento antes y despues de cambios,
- y visualizar situaciones concretas como carcel, hipoteca o construccion de casas.

Ademas de eso, el proyecto tiene tests en `prolog/tests/monopoly_tests.pl`.

## Notas

- La app de terminal y las interfaces graficas usan el mismo motor de Prolog.
- La app por lotes no sustituye a la visual: sirve para otra cosa, que es sacar metricas de muchas partidas.
- La carpeta `docs/` guarda el enunciado y notas auxiliares del proyecto.

## Licencia

El repositorio incluye un archivo `LICENSE` con la licencia del proyecto.
