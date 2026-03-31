import json
import os
import random
import shutil
import subprocess
import time
import re
from dataclasses import dataclass, field
from typing import List, Optional, Dict, Tuple


# ============================================================
# CONFIGURACION
# ============================================================

PROLOG_BRIDGE_FILE = "prolog/bridges/python_bridge_trace.pl"
DEFAULT_START_MONEY = 1500
DEFAULT_NUM_PLAYERS = 2
DEFAULT_NUM_ROLLS = 10
BOARD_SIZE = 40
MIN_CELL_WIDTH = 8
MAX_CELL_WIDTH = 14


# ============================================================
# MODELO
# ============================================================

@dataclass
class Casilla:
    tipo: str
    nombre: str
    precio: Optional[int] = None
    color: Optional[str] = None
    monto: Optional[int] = None


@dataclass
class Jugador:
    nombre: str
    posicion: int
    dinero: int
    propiedades: List[str] = field(default_factory=list)


@dataclass
class Estado:
    jugadores: List[Jugador]
    tablero: List[Casilla]
    turno: int


@dataclass
class Escenario:
    nombre: str
    descripcion: str
    estado: Estado
    tiradas: List[int]


# ============================================================
# TABLERO BASE
# ============================================================

def tablero_base() -> List[Casilla]:
    return [
        Casilla("salida", "SALIDA"),
        Casilla("propiedad", "marron1", 60, "marron"),
        Casilla("carta", "CARTA"),
        Casilla("propiedad", "marron2", 60, "marron"),
        Casilla("impuesto", "IMPUESTO", monto=200),
        Casilla("especial", "estacion1"),
        Casilla("propiedad", "celeste1", 100, "celeste"),
        Casilla("carta", "CARTA"),
        Casilla("propiedad", "celeste2", 100, "celeste"),
        Casilla("propiedad", "celeste3", 120, "celeste"),

        Casilla("especial", "carcel_visita"),
        Casilla("propiedad", "rosa1", 140, "rosa"),
        Casilla("especial", "servicio1"),
        Casilla("propiedad", "rosa2", 140, "rosa"),
        Casilla("propiedad", "rosa3", 160, "rosa"),
        Casilla("especial", "estacion2"),
        Casilla("propiedad", "naranja1", 180, "naranja"),
        Casilla("carta", "CARTA"),
        Casilla("propiedad", "naranja2", 180, "naranja"),
        Casilla("propiedad", "naranja3", 200, "naranja"),

        Casilla("especial", "parking"),
        Casilla("propiedad", "rojo1", 220, "rojo"),
        Casilla("carta", "CARTA"),
        Casilla("propiedad", "rojo2", 220, "rojo"),
        Casilla("propiedad", "rojo3", 240, "rojo"),
        Casilla("especial", "estacion3"),
        Casilla("propiedad", "amarillo1", 260, "amarillo"),
        Casilla("propiedad", "amarillo2", 260, "amarillo"),
        Casilla("especial", "servicio2"),
        Casilla("propiedad", "amarillo3", 280, "amarillo"),

        Casilla("especial", "ir_carcel"),
        Casilla("propiedad", "verde1", 300, "verde"),
        Casilla("propiedad", "verde2", 300, "verde"),
        Casilla("carta", "CARTA"),
        Casilla("propiedad", "verde3", 320, "verde"),
        Casilla("especial", "estacion4"),
        Casilla("carta", "CARTA"),
        Casilla("propiedad", "azul1", 350, "azul"),
        Casilla("impuesto", "IMPUESTO", monto=100),
        Casilla("propiedad", "azul2", 400, "azul"),
    ]


# ============================================================
# UTILIDADES DE TERMINAL
# ============================================================

def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")


# ============================================================
# RENDER ASCII
# ============================================================

COLOR_ABBR = {
    "marron": "MR",
    "celeste": "CE",
    "rosa": "RS",
    "naranja": "NJ",
    "rojo": "RJ",
    "amarillo": "AM",
    "verde": "VD",
    "azul": "AZ",
}

TIPO_ABBR = {
    "salida": "GO",
    "carta": "CA",
    "impuesto": "TX",
    "especial": "ES",
    "propiedad": "PR",
}


def short_name(nombre: str, max_len: int = 8) -> str:
    return nombre[:max_len].upper()


def jugador_token(nombre: str) -> str:
    nombre = nombre.strip().lower()
    m = re.fullmatch(r"jugador(\d+)", nombre)
    if m:
        return f"J{m.group(1)}"
    return nombre[:2].upper()


def jugadores_en_posicion(pos: int, jugadores: List[Jugador]) -> List[str]:
    return [jugador_token(j.nombre) for j in jugadores if j.posicion == pos]


def formato_casilla(idx: int, casilla: Casilla, jugadores: List[Jugador], propietarios: Dict[str, str], ancho: int = 14) -> List[str]:
    if casilla.tipo == "propiedad":
        cab = f"{idx:02d} {short_name(casilla.nombre, 8)}"
        color = COLOR_ABBR.get(casilla.color, "--")
        precio = f"${casilla.precio}"
        dueno = propietarios.get(casilla.nombre, "-")
        dueno_txt = f"Own:{jugador_token(dueno) if dueno != '-' else '-'}"
    elif casilla.tipo == "impuesto":
        cab = f"{idx:02d} TAX"
        color = "--"
        precio = f"${casilla.monto}"
        dueno_txt = ""
    elif casilla.tipo == "carta":
        cab = f"{idx:02d} CARTA"
        color = "--"
        precio = ""
        dueno_txt = ""
    elif casilla.tipo == "salida":
        cab = f"{idx:02d} SALIDA"
        color = "--"
        precio = "+200"
        dueno_txt = ""
    else:
        cab = f"{idx:02d} {short_name(casilla.nombre, 8)}"
        color = "--"
        precio = ""
        dueno_txt = ""

    toks = jugadores_en_posicion(idx, jugadores)
    toks_txt = "J:" + (",".join(toks) if toks else "-")

    lineas = [
        cab[:ancho].ljust(ancho),
        f"T:{TIPO_ABBR.get(casilla.tipo, '??')}".ljust(ancho),
        f"C:{color}".ljust(ancho),
        precio[:ancho].ljust(ancho),
        (dueno_txt if dueno_txt else toks_txt)[:ancho].ljust(ancho),
    ]

    if casilla.tipo == "propiedad":
        lineas[4] = f"{dueno_txt} {toks_txt}".strip()[:ancho].ljust(ancho)

    return lineas


def posiciones_monopoly_ring() -> Dict[Tuple[int, int], int]:
    """
    Orientacion rotada:
    - esquina inferior izquierda = 0 (SALIDA)
    """
    mapping = {}

    # 0..10: columna izquierda, de abajo a arriba
    col = 0
    rows = list(range(10, -1, -1))
    for pos, row in enumerate(rows):
        mapping[(row, col)] = pos

    # 11..20: fila superior, de izquierda a derecha
    row = 0
    cols = list(range(1, 11))
    for i, col in enumerate(cols, start=11):
        mapping[(row, col)] = i

    # 21..30: columna derecha, de arriba a abajo
    col = 10
    rows = list(range(1, 11))
    for i, row in enumerate(rows, start=21):
        mapping[(row, col)] = i

    # 31..39: fila inferior, de derecha a izquierda
    row = 10
    cols = list(range(9, 0, -1))
    for i, col in enumerate(cols, start=31):
        mapping[(row, col)] = i

    return mapping


def render_tablero_ascii(estado: Estado, ancho_celda: int = 14) -> str:
    tablero = estado.tablero
    jugadores = estado.jugadores

    propietarios = {}
    for j in jugadores:
        for p in j.propiedades:
            propietarios[p] = j.nombre

    mapping = posiciones_monopoly_ring()
    grid = [[None for _ in range(11)] for _ in range(11)]
    for (r, c), pos in mapping.items():
        grid[r][c] = pos

    def celda_vacia() -> List[str]:
        return [" " * ancho_celda for _ in range(5)]

    def celda_de_pos(pos: int) -> List[str]:
        return formato_casilla(pos, tablero[pos], jugadores, propietarios, ancho=ancho_celda)

    lineas_finales = []
    border = "+" + "+".join(["-" * ancho_celda for _ in range(11)]) + "+"

    for r in range(11):
        fila_celdas = []
        for c in range(11):
            pos = grid[r][c]
            if pos is None:
                if r == 5 and c == 5:
                    centro = [
                        " MONOPOLY     ".ljust(ancho_celda),
                        " PROLOG+PY    ".ljust(ancho_celda),
                        f" Turno:{estado.turno}     ".ljust(ancho_celda),
                        "             ".ljust(ancho_celda),
                        "             ".ljust(ancho_celda),
                    ]
                    fila_celdas.append(centro)
                else:
                    fila_celdas.append(celda_vacia())
            else:
                fila_celdas.append(celda_de_pos(pos))

        lineas_finales.append(border)
        for i in range(5):
            lineas_finales.append("|" + "|".join(celda[i] for celda in fila_celdas) + "|")

    lineas_finales.append(border)
    return "\n".join(lineas_finales)


def ancho_celda_terminal(default: int = MAX_CELL_WIDTH) -> int:
    columnas = shutil.get_terminal_size(fallback=(180, 40)).columns
    max_ancho_tablero = max(100, columnas - 2)
    ancho = (max_ancho_tablero - 12) // 11
    return max(MIN_CELL_WIDTH, min(default, ancho))


def render_resumen_jugadores(estado: Estado) -> str:
    lineas = ["JUGADORES", "-" * 90]
    for i, j in enumerate(estado.jugadores):
        activo = " <== TURNO" if i == estado.turno else ""
        props = ", ".join(j.propiedades) if j.propiedades else "-"
        lineas.append(
            f"{j.nombre:<10} | Pos: {j.posicion:>2} | Dinero: {j.dinero:>5} | Props: {props}{activo}"
        )
    return "\n".join(lineas)


def render_estado(estado: Estado) -> str:
    ancho = ancho_celda_terminal()
    return render_tablero_ascii(estado, ancho_celda=ancho) + "\n\n" + render_resumen_jugadores(estado)


# ============================================================
# ESCENARIOS PRECARGADOS
# ============================================================

def estado_base_normal(num_jugadores: int = 2, dinero_inicial: int = DEFAULT_START_MONEY) -> Estado:
    jugadores = [
        Jugador(f"jugador{i+1}", 0, dinero_inicial, [])
        for i in range(num_jugadores)
    ]
    return Estado(jugadores, tablero_base(), 0)


def escenarios_precargados() -> List[Escenario]:
    tablero = tablero_base()

    return [
        Escenario(
            "esc1",
            "Compras iniciales",
            Estado(
                [Jugador("jugador1", 0, 1500, []),
                 Jugador("jugador2", 0, 1500, [])],
                tablero,
                0
            ),
            [1, 3, 5, 5]
        ),
        Escenario(
            "esc2",
            "Monopolio marron formado",
            Estado(
                [Jugador("jugador1", 0, 1380, ["marron2", "marron1"]),
                 Jugador("jugador2", 0, 1500, [])],
                tablero,
                0
            ),
            [1]
        ),
        Escenario(
            "esc3",
            "Bancarrota por alquiler",
            Estado(
                [Jugador("jugador1", 0, 5, []),
                 Jugador("jugador2", 0, 1500, ["marron1"])],
                tablero,
                0
            ),
            [1]
        ),
        Escenario(
            "esc4",
            "Alquileres consecutivos",
            Estado(
                [Jugador("jugador1", 0, 1340, ["celeste2", "marron2"]),
                 Jugador("jugador2", 0, 1340, ["celeste1", "marron1"])],
                tablero,
                0
            ),
            [1, 3, 5, 5]
        ),
        Escenario(
            "esc5",
            "10 turnos completos",
            Estado(
                [Jugador("jugador1", 0, 1500, []),
                 Jugador("jugador2", 0, 1500, [])],
                tablero,
                0
            ),
            [1, 3, 5, 5, 2, 1, 1, 3, 3, 4]
        ),
    ]


# ============================================================
# VALIDACION BASICA DEL ESCENARIO
# ============================================================

def propiedades_validas_tablero() -> set:
    return {
        "marron1", "marron2",
        "celeste1", "celeste2", "celeste3",
        "rosa1", "rosa2", "rosa3",
        "naranja1", "naranja2", "naranja3",
        "rojo1", "rojo2", "rojo3",
        "amarillo1", "amarillo2", "amarillo3",
        "verde1", "verde2", "verde3",
        "azul1", "azul2",
    }


def validar_escenario(estado: Estado, tiradas: List[int]) -> List[str]:
    errores = []

    if len(estado.jugadores) < 2:
        errores.append("Debe haber al menos 2 jugadores.")

    if not (0 <= estado.turno < len(estado.jugadores)):
        errores.append("El indice de turno es invalido.")

    props_validas = propiedades_validas_tablero()
    props_vistas = set()

    for j in estado.jugadores:
        if not (0 <= j.posicion < 40):
            errores.append(f"{j.nombre}: posicion fuera de rango (0..39).")
        if j.dinero < 0:
            errores.append(f"{j.nombre}: dinero inicial negativo.")
        for p in j.propiedades:
            if p not in props_validas:
                errores.append(f"{j.nombre}: propiedad desconocida '{p}'.")
            if p in props_vistas:
                errores.append(f"Propiedad duplicada en varios jugadores: '{p}'.")
            props_vistas.add(p)

    for t in tiradas:
        if t < 0:
            errores.append(f"Tirada invalida: {t}. Debe ser >= 0.")

    if len(tiradas) == 0:
        errores.append("La lista de tiradas no puede estar vacia.")

    return errores


# ============================================================
# SERIALIZACION HACIA PROLOG
# ============================================================

def prolog_atom(name: str) -> str:
    return name.lower().replace(" ", "_")


def jugador_to_prolog(j: Jugador) -> str:
    props = "[" + ",".join(prolog_atom(p) for p in j.propiedades) + "]"
    return f"jugador({prolog_atom(j.nombre)},{j.posicion},{j.dinero},{props})"


def estado_to_prolog(e: Estado) -> str:
    js = "[" + ",".join(jugador_to_prolog(j) for j in e.jugadores) + "]"
    return f"estado({js},Tablero,{e.turno})"


def tiradas_to_prolog(tiradas: List[int]) -> str:
    return "[" + ",".join(str(x) for x in tiradas) + "]"


# ============================================================
# PARSEO JSON -> PYTHON
# ============================================================

def estado_from_dict(d: dict) -> Estado:
    jugadores = [
        Jugador(
            nombre=j["nombre"],
            posicion=j["posicion"],
            dinero=j["dinero"],
            propiedades=j["propiedades"]
        )
        for j in d["jugadores"]
    ]
    return Estado(jugadores, tablero_base(), d["turno"])


# ============================================================
# LLAMADA A PROLOG
# ============================================================

def ejecutar_traza_en_prolog(estado: Estado, tiradas: List[int]):
    if not os.path.exists(PROLOG_BRIDGE_FILE):
        return None, f"No se encuentra {PROLOG_BRIDGE_FILE}"

    estado_term = estado_to_prolog(estado)
    tiradas_term = tiradas_to_prolog(tiradas)

    goal = (
        f"consult('{PROLOG_BRIDGE_FILE}'), "
        f"simular_traza_desde_python({estado_term}, {tiradas_term}, JSON), "
        f"write(JSON), nl, halt."
    )

    try:
        result = subprocess.run(
            ["swipl", "-q", "-g", goal],
            capture_output=True,
            text=True,
            check=False
        )
    except FileNotFoundError:
        return None, "No se encontro 'swipl'. Instala SWI-Prolog y anadelo al PATH."

    if result.returncode != 0:
        return None, (
            "Error al ejecutar Prolog.\n"
            f"STDOUT:\n{result.stdout}\n"
            f"STDERR:\n{result.stderr}"
        )

    salida = result.stdout.strip()
    if not salida:
        return None, "Prolog no devolvio ninguna salida."

    try:
        data = json.loads(salida)
        return data, ""
    except json.JSONDecodeError:
        return None, f"La salida de Prolog no es JSON valido:\n{salida}"


# ============================================================
# ENTRADA DE DATOS
# ============================================================

def leer_entero(msg: str, minimo=None, maximo=None, default=None) -> int:
    while True:
        raw = input(msg).strip()
        if raw == "" and default is not None:
            return default
        try:
            v = int(raw)
            if minimo is not None and v < minimo:
                print(f"Debe ser >= {minimo}")
                continue
            if maximo is not None and v > maximo:
                print(f"Debe ser <= {maximo}")
                continue
            return v
        except ValueError:
            print("Introduce un entero valido.")


def leer_lista_enteros(msg: str) -> List[int]:
    while True:
        raw = input(msg).strip()
        if raw == "":
            return []
        try:
            return [int(x.strip()) for x in raw.split(",") if x.strip()]
        except ValueError:
            print("Formato invalido. Ejemplo: 1,3,5,5")


def leer_propiedades(msg: str) -> List[str]:
    raw = input(msg).strip()
    if raw == "":
        return []
    return [x.strip().lower() for x in raw.split(",") if x.strip()]


def generar_tiradas_aleatorias(n: int, minimo: int = 1, maximo: int = 6) -> List[int]:
    return [random.randint(minimo, maximo) for _ in range(n)]


def construir_escenario_personalizado():
    print("\n=== ESCENARIO PERSONALIZADO ===\n")

    num_jugadores = leer_entero(
        f"Numero de jugadores [{DEFAULT_NUM_PLAYERS}]: ",
        minimo=2,
        default=DEFAULT_NUM_PLAYERS
    )

    dinero_default = leer_entero(
        f"Dinero inicial por defecto [{DEFAULT_START_MONEY}]: ",
        minimo=0,
        default=DEFAULT_START_MONEY
    )

    jugadores = []
    for i in range(num_jugadores):
        print(f"\nJugador {i+1}")
        nombre = f"jugador{i+1}"
        dinero = leer_entero(f"  Dinero [{dinero_default}]: ", minimo=0, default=dinero_default)
        posicion = leer_entero("  Posicion [0]: ", minimo=0, maximo=39, default=0)
        props = leer_propiedades("  Propiedades iniciales (coma separadas, vacio = ninguna): ")
        jugadores.append(Jugador(nombre, posicion, dinero, props))

    turno = leer_entero("Turno actual [0]: ", minimo=0, maximo=num_jugadores - 1, default=0)

    modo_tiradas = input("Tiradas aleatorias? [s/n, defecto s]: ").strip().lower()
    if modo_tiradas in ("", "s", "si", "si"):
        n = leer_entero(f"Numero de tiradas [{DEFAULT_NUM_ROLLS}]: ", minimo=1, default=DEFAULT_NUM_ROLLS)
        tiradas = generar_tiradas_aleatorias(n)
    else:
        tiradas = leer_lista_enteros("Introduce tiradas separadas por comas: ")

    estado = Estado(jugadores, tablero_base(), turno)
    return estado, tiradas


# ============================================================
# REPRODUCCION PASO A PASO
# ============================================================

def mostrar_bloque_estado(titulo: str, estado: Estado, extra: Optional[List[str]] = None):
    clear_screen()
    print("=" * 100)
    print(titulo)
    print("=" * 100)
    if extra:
        for linea in extra:
            print(linea)
        print()
    print(render_estado(estado))
    print()


def reproducir_traza(data: dict):
    estado_inicial = estado_from_dict(data["estado_inicial"])
    pasos = data["pasos"]
    estado_final = estado_from_dict(data["estado_final"])
    metricas = data["metricas"]

    print("\nModo de reproduccion:")
    print("1. Manual (Enter en cada turno)")
    print("2. Automatico")
    modo = input("Elige modo [1/2]: ").strip()

    manual = modo != "2"
    delay = 1.0
    if not manual:
        delay = float(input("Segundos entre turnos [1.0]: ").strip() or "1.0")

    mostrar_bloque_estado(
        "ESTADO INICIAL",
        estado_inicial,
        extra=["La simulacion del juego se ha ejecutado completamente en Prolog."]
    )
    input("Pulsa Enter para comenzar...")

    for paso in pasos:
        estado_despues = estado_from_dict(paso["estado_despues"])
        jugador = paso["jugador_activo"]
        tirada = paso["tirada"]
        turno_num = paso["turno_num"]

        extra = [
            f"Turno ejecutado: {turno_num}",
            f"Jugador activo: {jugador}",
            f"Tirada: {tirada}",
        ]

        j_desp = paso["jugador_despues"]
        if j_desp.get("eliminado", False):
            extra.append("Resultado del jugador activo: eliminado por bancarrota")
        else:
            extra.append(
                f"Jugador tras el turno -> pos={j_desp['posicion']}, dinero={j_desp['dinero']}, props={j_desp['propiedades']}"
            )

        mostrar_bloque_estado(f"TURNO {turno_num}", estado_despues, extra=extra)

        if manual:
            input("Pulsa Enter para continuar...")
        else:
            time.sleep(delay)

    extra_final = [
        f"Iteraciones por turno: {metricas['iter_por_turno']}",
        f"Iteraciones totales: {metricas['iter_total']}",
        f"Compras: {metricas['compras']}",
        f"Alquileres: {metricas['alquileres']}",
        f"Bancarrotas: {metricas['bancarrotas']}",
    ]

    mostrar_bloque_estado("ESTADO FINAL", estado_final, extra=extra_final)
    input("Pulsa Enter para volver al menu...")


# ============================================================
# EJECUCION DE SIMULACION
# ============================================================

def ejecutar_simulacion(estado: Estado, tiradas: List[int]):
    errores = validar_escenario(estado, tiradas)
    if errores:
        clear_screen()
        print("ESCENARIO INVALIDO")
        print("-" * 80)
        for e in errores:
            print(f"- {e}")
        input("\nPulsa Enter para volver al menu...")
        return

    data, error = ejecutar_traza_en_prolog(estado, tiradas)
    if error:
        clear_screen()
        print("ERROR")
        print("-" * 80)
        print(error)
        input("\nPulsa Enter para volver al menu...")
        return

    reproducir_traza(data)


# ============================================================
# MENU
# ============================================================

def imprimir_menu():
    clear_screen()
    print("=" * 72)
    print(" MONOPOLY - APP TERMINAL PYTHON + MOTOR LOGICO EN PROLOG")
    print("=" * 72)
    print("1. Ver escenarios precargados")
    print("2. Ejecutar escenario precargado")
    print("3. Crear escenario personalizado")
    print("4. Partida rapida aleatoria")
    print("5. Salir")


def ejecutar_menu():
    escenarios = escenarios_precargados()

    while True:
        imprimir_menu()
        opcion = input("\nElige una opcion: ").strip()

        if opcion == "1":
            clear_screen()
            print("ESCENARIOS PRECARGADOS")
            print("-" * 72)
            for i, esc in enumerate(escenarios, start=1):
                print(f"{i}. {esc.nombre} -> {esc.descripcion}")
                print(f"   Tiradas: {esc.tiradas}")
            input("\nPulsa Enter para volver al menu...")

        elif opcion == "2":
            clear_screen()
            print("SELECCION DE ESCENARIO")
            print("-" * 72)
            for i, esc in enumerate(escenarios, start=1):
                print(f"{i}. {esc.nombre} -> {esc.descripcion}")

            idx = leer_entero("Numero: ", minimo=1, maximo=len(escenarios))
            esc = escenarios[idx - 1]
            ejecutar_simulacion(esc.estado, esc.tiradas)

        elif opcion == "3":
            estado, tiradas = construir_escenario_personalizado()
            ejecutar_simulacion(estado, tiradas)

        elif opcion == "4":
            estado = estado_base_normal()
            tiradas = generar_tiradas_aleatorias(DEFAULT_NUM_ROLLS)
            ejecutar_simulacion(estado, tiradas)

        elif opcion == "5":
            clear_screen()
            print("Saliendo.")
            break

        else:
            input("Opcion no valida. Pulsa Enter para continuar...")


if __name__ == "__main__":
    ejecutar_menu()
