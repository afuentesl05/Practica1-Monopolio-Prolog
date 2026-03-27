# Monopoly en Prolog

Practica experimental de laboratorio (`PECL1`) de la asignatura **Conocimiento y Razonamiento Automatizado**, centrada en el modelado simbolico y la simulacion de una version simplificada de Monopoly mediante **SWI-Prolog**, con utilidades auxiliares en **Python** para trazado y visualizacion.

## Autoria

- Alvaro Fuentes Lozano
- Lucia Cantero Anchuelo
- Rodrigo Rey Henche

## Descripcion del proyecto

El proyecto implementa un motor logico de Monopoly en Prolog a partir de una representacion declarativa del estado del juego. Sobre ese nucleo se construyen:

- reglas de evolucion del estado por turnos,
- escenarios reproducibles para validacion,
- metricas de ejecucion,
- una interfaz de terminal en Python,
- y una interfaz grafica en PySide6 apoyada en un puente Prolog-JSON.

El objetivo principal es aplicar tecnicas de representacion del conocimiento y razonamiento automatizado sobre un dominio conocido, modelando estados, transiciones, restricciones y consecuencias de las reglas del juego.

## Funcionalidades implementadas

- Representacion formal del estado global del juego.
- Tablero de 40 casillas.
- Gestion de jugadores, turnos, dinero y propiedades.
- Compra automatica de propiedades cuando procede.
- Cobro de alquileres.
- Deteccion de monopolios por color.
- Gestion de bancarrota y eliminacion de jugadores.
- Soporte de tiradas legacy y tiradas reales de dos dados.
- Reglas de dobles y carcel.
- Hipotecas y cancelacion de hipotecas.
- Construccion de casas con validacion de restricciones.
- Calculo de patrimonio y ranking de jugadores.
- Metricas de simulacion por turno.
- Catalogo de escenarios reproducibles para pruebas y defensa.

## Estructura del repositorio

```text
Practica1-Monopolio-Prolog/
|-- main.pl                  # Nucleo logico del juego
|-- scenarios.pl             # Escenarios reproducibles y utilidades de inspeccion
|-- monopoly_tests.pl        # Bateria de tests en Prolog
|-- bridge_trace_ui.pl       # Serializacion a JSON para la interfaz grafica
|-- python_bridge_trace.pl   # Puente Prolog para la app de terminal
|-- launcher_monopoly.py     # Aplicacion de terminal en Python
|-- ui_monopoly/             # Interfaz grafica en PySide6
|   |-- app.py
|   |-- main_window.py
|   |-- board_widget.py
|   `-- bridge_client.py
|-- docs/
|   `-- enunciado/
|       `-- Practica 1_2025-26.pdf
`-- README.md
```

## Tecnologias utilizadas

- SWI-Prolog
- Python 3
- PySide6

## Requisitos

Para ejecutar el proyecto desde la raiz del repositorio se necesita:

- `swipl` disponible en el `PATH`
- `python` disponible en el `PATH`
- el paquete `PySide6` instalado para la interfaz grafica

Entorno verificado en este repositorio:

- SWI-Prolog `10.0.0`
- Python `3.14.3`
- PySide6 `6.11.0`

## Como ejecutar el proyecto

### 1. Ejecutar los tests

```powershell
swipl -q -s monopoly_tests.pl -g run_tests,halt
```

La bateria actual contiene **33 tests** y ha pasado correctamente en este entorno.

### 2. Listar escenarios disponibles

```powershell
swipl -q -g "consult('bridge_trace_ui.pl'), listar_escenarios_ui(JSON), write(JSON), halt."
```

El repositorio incluye **25 escenarios** que cubren compras, alquileres, monopolios, carcel, hipotecas y construccion de casas.

### 3. Ejecutar utilidades y validaciones en Prolog

Ejemplo de carga interactiva:

```powershell
swipl
```

Y dentro de Prolog:

```prolog
['scenarios.pl'].
listar_escenarios.
ejecutar_escenario_metricas(esc5, EstadoFinal, Metricas).
```

### 4. Ejecutar la aplicacion de terminal

```powershell
python launcher_monopoly.py
```

Esta aplicacion permite:

- consultar escenarios precargados,
- ejecutar simulaciones paso a paso,
- crear escenarios personalizados,
- y lanzar partidas rapidas aleatorias.

### 5. Ejecutar la interfaz grafica

```powershell
python -m ui_monopoly.app
```

La interfaz grafica muestra el tablero, el estado de los jugadores, el resumen de cada paso y las metricas de la simulacion a partir de trazas generadas por Prolog.

## Alcance academico

Esta practica esta orientada a trabajar conceptos propios de la asignatura, entre ellos:

- representacion declarativa de estados,
- diseno de reglas de transicion,
- razonamiento sobre consecuencias,
- validacion mediante escenarios,
- y separacion entre motor logico y capa de visualizacion.

No pretende reproducir el juego comercial completo, sino ofrecer una base consistente y extensible para experimentar con razonamiento simbolico en Prolog.

## Validacion

El proyecto se apoya en dos mecanismos principales de validacion:

- **tests automaticos** en `monopoly_tests.pl`,
- **escenarios reproducibles** en `scenarios.pl`, utiles tanto para comprobacion funcional como para defensa de la practica.

Los escenarios cubren, entre otros casos:

- compras iniciales,
- bancarrota por alquiler,
- dobles y envio a carcel,
- salida de carcel,
- hipotecas y deshipotecas,
- construccion de casas,
- restricciones de construccion,
- patrimonio y ranking.

## Licencia

El repositorio incluye un archivo `LICENSE` con la licencia del proyecto.
