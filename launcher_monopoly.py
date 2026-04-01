import json
import os
import random
import shutil
import subprocess
import time
import re
from dataclasses import dataclass, field
from typing import List, Optional, Dict, Tuple

from analisis_lotes import (
    PlantillaJugadorLotes,
    construir_estado_aleatorio_desde_plantillas,
    inicializar_acumulador_resultados,
    actualizar_acumulador_con_partida,
    construir_resumen_lotes,
)


# ============================================================
# CONFIGURACION
# ============================================================

ARCHIVO_BRIDGE_PROLOG = "prolog/bridges/python_bridge_trace.pl"
DINERO_INICIAL_POR_DEFECTO = 1500
NUM_JUGADORES_POR_DEFECTO = 2
NUM_TIRADAS_POR_DEFECTO = 10
ANCHO_MIN_CELDA = 8
ANCHO_MAX_CELDA = 14


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

def limpiar_pantalla():
    os.system("cls" if os.name == "nt" else "clear")


def pausa(msg: str = "\nPulsa Enter para continuar..."):
    input(msg)


def leer_entero(msg: str, minimo=None, maximo=None, default=None) -> int:
    while True:
        raw = input(msg).strip()
        if raw == "" and default is not None:
            return default
        try:
            valor = int(raw)
            if minimo is not None and valor < minimo:
                print(f"Debe ser >= {minimo}")
                continue
            if maximo is not None and valor > maximo:
                print(f"Debe ser <= {maximo}")
                continue
            return valor
        except ValueError:
            print("Introduce un entero valido.")


def leer_entero_o_vacio(msg: str, minimo=None, maximo=None) -> Optional[int]:
    while True:
        raw = input(msg).strip()
        if raw == "":
            return None
        try:
            valor = int(raw)
            if minimo is not None and valor < minimo:
                print(f"Debe ser >= {minimo}")
                continue
            if maximo is not None and valor > maximo:
                print(f"Debe ser <= {maximo}")
                continue
            return valor
        except ValueError:
            print("Introduce un entero valido o pulsa Enter para aleatorio.")


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


# ============================================================
# RENDER ASCII
# ============================================================

ABREVIATURA_COLOR = {
    "marron": "MR",
    "celeste": "CE",
    "rosa": "RS",
    "naranja": "NJ",
    "rojo": "RJ",
    "amarillo": "AM",
    "verde": "VD",
    "azul": "AZ",
}

ABREVIATURA_TIPO = {
    "salida": "GO",
    "carta": "CA",
    "impuesto": "TX",
    "especial": "ES",
    "propiedad": "PR",
}


def nombre_corto(nombre: str, max_len: int = 8) -> str:
    return nombre[:max_len].upper()


def token_jugador(nombre: str) -> str:
    nombre = nombre.strip().lower()
    m = re.fullmatch(r"jugador(\d+)", nombre)
    if m:
        return f"J{m.group(1)}"
    return nombre[:2].upper()


def jugadores_en_posicion(pos: int, jugadores: List[Jugador]) -> List[str]:
    return [token_jugador(j.nombre) for j in jugadores if j.posicion == pos]


def formato_casilla(
    idx: int,
    casilla: Casilla,
    jugadores: List[Jugador],
    propietarios: Dict[str, str],
    ancho: int = 14
) -> List[str]:
    if casilla.tipo == "propiedad":
        cab = f"{idx:02d} {nombre_corto(casilla.nombre, 8)}"
        color = ABREVIATURA_COLOR.get(casilla.color, "--")
        precio = f"${casilla.precio}"
        dueno = propietarios.get(casilla.nombre, "-")
        dueno_txt = f"Own:{token_jugador(dueno) if dueno != '-' else '-'}"
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
        cab = f"{idx:02d} {nombre_corto(casilla.nombre, 8)}"
        color = "--"
        precio = ""
        dueno_txt = ""

    tokens = jugadores_en_posicion(idx, jugadores)
    tokens_txt = "J:" + (",".join(tokens) if tokens else "-")

    lineas = [
        cab[:ancho].ljust(ancho),
        f"T:{ABREVIATURA_TIPO.get(casilla.tipo, '??')}".ljust(ancho),
        f"C:{color}".ljust(ancho),
        precio[:ancho].ljust(ancho),
        (dueno_txt if dueno_txt else tokens_txt)[:ancho].ljust(ancho),
    ]

    if casilla.tipo == "propiedad":
        lineas[4] = f"{dueno_txt} {tokens_txt}".strip()[:ancho].ljust(ancho)

    return lineas


def posiciones_anillo_monopoly() -> Dict[Tuple[int, int], int]:
    mapping = {}

    col = 0
    filas = list(range(10, -1, -1))
    for pos, fila in enumerate(filas):
        mapping[(fila, col)] = pos

    fila = 0
    columnas = list(range(1, 11))
    for i, col in enumerate(columnas, start=11):
        mapping[(fila, col)] = i

    col = 10
    filas = list(range(1, 11))
    for i, fila in enumerate(filas, start=21):
        mapping[(fila, col)] = i

    fila = 10
    columnas = list(range(9, 0, -1))
    for i, col in enumerate(columnas, start=31):
        mapping[(fila, col)] = i

    return mapping


def render_tablero_ascii(estado: Estado, ancho_celda: int = 14) -> str:
    tablero = estado.tablero
    jugadores = estado.jugadores

    propietarios = {}
    for jugador in jugadores:
        for prop in jugador.propiedades:
            propietarios[prop] = jugador.nombre

    mapping = posiciones_anillo_monopoly()
    grid = [[None for _ in range(11)] for _ in range(11)]
    for (fila, col), pos in mapping.items():
        grid[fila][col] = pos

    def celda_vacia() -> List[str]:
        return [" " * ancho_celda for _ in range(5)]

    def celda_de_pos(pos: int) -> List[str]:
        return formato_casilla(pos, tablero[pos], jugadores, propietarios, ancho=ancho_celda)

    lineas_finales = []
    borde = "+" + "+".join(["-" * ancho_celda for _ in range(11)]) + "+"

    for fila in range(11):
        fila_celdas = []
        for col in range(11):
            pos = grid[fila][col]
            if pos is None:
                if fila == 5 and col == 5:
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

        lineas_finales.append(borde)
        for i in range(5):
            lineas_finales.append("|" + "|".join(celda[i] for celda in fila_celdas) + "|")

    lineas_finales.append(borde)
    return "\n".join(lineas_finales)


def ancho_celda_terminal(valor_por_defecto: int = ANCHO_MAX_CELDA) -> int:
    columnas = shutil.get_terminal_size(fallback=(180, 40)).columns
    ancho_max_tablero = max(100, columnas - 2)
    ancho = (ancho_max_tablero - 12) // 11
    return max(ANCHO_MIN_CELDA, min(valor_por_defecto, ancho))


def render_resumen_jugadores(estado: Estado) -> str:
    lineas = ["JUGADORES", "-" * 90]
    for i, jugador in enumerate(estado.jugadores):
        activo = " <== TURNO" if i == estado.turno else ""
        props = ", ".join(jugador.propiedades) if jugador.propiedades else "-"
        lineas.append(
            f"{jugador.nombre:<10} | Pos: {jugador.posicion:>2} | "
            f"Dinero: {jugador.dinero:>5} | Props: {props}{activo}"
        )
    return "\n".join(lineas)


def render_estado(estado: Estado) -> str:
    ancho = ancho_celda_terminal()
    return render_tablero_ascii(estado, ancho_celda=ancho) + "\n\n" + render_resumen_jugadores(estado)


# ============================================================
# RENDER DE BLOQUES DE INFORMACION
# ============================================================

def render_ranking(ranking: List[dict], titulo: str = "RANKING") -> str:
    lineas = [titulo, "-" * 90]

    if not ranking:
        lineas.append("No hay datos de ranking.")
        return "\n".join(lineas)

    for i, item in enumerate(ranking, start=1):
        lineas.append(
            f"{i:>2}. "
            f"{item['nombre']:<10} | "
            f"Patrimonio: {item['patrimonio']:>5} | "
            f"Dinero: {item['dinero']:>5} | "
            f"Valor props: {item['valor_propiedades']:>5} | "
            f"Num props: {item['num_propiedades']:>2}"
        )
    return "\n".join(lineas)


def media_iteraciones(metricas: dict) -> float:
    iteraciones = metricas.get("iter_por_turno", [])
    if not iteraciones:
        return 0.0
    return sum(iteraciones) / len(iteraciones)


def render_metricas(metricas: dict, titulo: str = "METRICAS") -> str:
    lineas = [
        titulo,
        "-" * 90,
        f"Iteraciones por turno : {metricas.get('iter_por_turno', [])}",
        f"Iteraciones totales   : {metricas.get('iter_total', 0)}",
        f"Media iter/turno      : {media_iteraciones(metricas):.2f}",
        f"Compras               : {metricas.get('compras', 0)}",
        f"Alquileres            : {metricas.get('alquileres', 0)}",
        f"Bancarrotas           : {metricas.get('bancarrotas', 0)}",
        f"Monopolios            : {metricas.get('monopolios', 0)}",
    ]
    return "\n".join(lineas)


def texto_motivo_finalizacion(motivo: str) -> str:
    if motivo == "victoria":
        return "Victoria: solo queda un jugador"
    if motivo == "sin_jugadores":
        return "Finalizacion excepcional: no quedan jugadores"
    return "Fin por limite de acciones/tiradas"


def texto_estado_turno(jugador_dict: dict) -> str:
    estado_turno = jugador_dict.get("estado_turno", {})
    libertad = estado_turno.get("libertad", "libre")
    turnos_carcel = estado_turno.get("turnos_carcel", 0)
    dobles = estado_turno.get("dobles_seguidos", 0)

    if libertad == "carcel":
        libertad_txt = f"carcel({turnos_carcel})"
    else:
        libertad_txt = "libre"

    return f"Estado turno: {libertad_txt} | Dobles seguidos: {dobles}"


def texto_propiedad_detalle(prop: dict) -> str:
    hipotecada = "si" if prop.get("hipotecada", False) else "no"
    casas = prop.get("casas", 0)
    return f"{prop.get('id', '?')}[hip={hipotecada}, casas={casas}]"


def render_detalle_jugador(jugador_dict: dict, titulo: str = "DETALLE JUGADOR") -> str:
    lineas = [titulo, "-" * 90]

    if not jugador_dict:
        lineas.append("No hay datos.")
        return "\n".join(lineas)

    if jugador_dict.get("eliminado", False):
        nombre = jugador_dict.get("nombre", "desconocido")
        lineas.append(f"{nombre}: eliminado")
        return "\n".join(lineas)

    nombre = jugador_dict.get("nombre", "-")
    posicion = jugador_dict.get("posicion", "-")
    dinero = jugador_dict.get("dinero", "-")

    lineas.append(f"Nombre      : {nombre}")
    lineas.append(f"Posicion    : {posicion}")
    lineas.append(f"Dinero      : {dinero}")
    lineas.append(texto_estado_turno(jugador_dict))

    props_detalle = jugador_dict.get("propiedades_detalle", [])
    if props_detalle:
        props_txt = ", ".join(texto_propiedad_detalle(p) for p in props_detalle)
    else:
        props_txt = "-"

    lineas.append(f"Propiedades : {props_txt}")
    return "\n".join(lineas)


def render_detalle_jugadores_estado(estado_dict: dict, titulo: str = "DETALLE FINAL DE JUGADORES") -> str:
    lineas = [titulo, "-" * 90]
    jugadores = estado_dict.get("jugadores", [])

    if not jugadores:
        lineas.append("No quedan jugadores en el estado final.")
        return "\n".join(lineas)

    for jugador in jugadores:
        nombre = jugador.get("nombre", "-")
        posicion = jugador.get("posicion", "-")
        dinero = jugador.get("dinero", "-")
        estado_txt = texto_estado_turno(jugador)

        props_detalle = jugador.get("propiedades_detalle", [])
        if props_detalle:
            props_txt = ", ".join(texto_propiedad_detalle(p) for p in props_detalle)
        else:
            props_txt = "-"

        lineas.append(f"{nombre}: pos={posicion} | dinero={dinero}")
        lineas.append(f"  {estado_txt}")
        lineas.append(f"  Propiedades: {props_txt}")
        lineas.append("")

    return "\n".join(lineas).rstrip()


def render_resumen_partida_final(
    estado_inicial: Estado,
    estado_final: Estado,
    pasos: List[dict],
    metricas: dict,
    motivo_finalizacion: str,
    escenario_info: Optional[dict] = None
) -> str:
    turnos_totales = len(pasos)
    jugadores_iniciales = len(estado_inicial.jugadores)
    jugadores_restantes = len(estado_final.jugadores)

    motivo_txt = texto_motivo_finalizacion(motivo_finalizacion)

    if estado_final.jugadores:
        ganador = estado_final.jugadores[0].nombre
    else:
        ganador = "Ninguno"

    lineas = [
        "RESUMEN DE LA PARTIDA",
        "-" * 90,
    ]

    if escenario_info:
        lineas.append(f"Escenario              : {escenario_info.get('id', '-')}")
        lineas.append(f"Tema                   : {escenario_info.get('tema', '-')}")
        lineas.append(f"Descripcion            : {escenario_info.get('descripcion', '-')}")

    lineas.extend([
        f"Motivo de finalizacion : {motivo_txt}",
        f"Pasos ejecutados       : {turnos_totales}",
        f"Jugadores iniciales    : {jugadores_iniciales}",
        f"Jugadores restantes    : {jugadores_restantes}",
        f"Ganador actual         : {ganador}",
        f"Compras totales        : {metricas.get('compras', 0)}",
        f"Alquileres totales     : {metricas.get('alquileres', 0)}",
        f"Bancarrotas totales    : {metricas.get('bancarrotas', 0)}",
        f"Monopolios totales     : {metricas.get('monopolios', 0)}",
    ])
    return "\n".join(lineas)


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

    for jugador in estado.jugadores:
        if not (0 <= jugador.posicion < 40):
            errores.append(f"{jugador.nombre}: posicion fuera de rango (0..39).")
        if jugador.dinero < 0:
            errores.append(f"{jugador.nombre}: dinero inicial negativo.")
        for prop in jugador.propiedades:
            if prop not in props_validas:
                errores.append(f"{jugador.nombre}: propiedad desconocida '{prop}'.")
            if prop in props_vistas:
                errores.append(f"Propiedad duplicada en varios jugadores: '{prop}'.")
            props_vistas.add(prop)

    for tirada in tiradas:
        if tirada < 0:
            errores.append(f"Tirada invalida: {tirada}. Debe ser >= 0.")

    if len(tiradas) == 0:
        errores.append("La lista de tiradas no puede estar vacia.")

    return errores


# ============================================================
# SERIALIZACION HACIA PROLOG
# ============================================================

def atomo_prolog(texto: str) -> str:
    return texto.lower().replace(" ", "_")


def jugador_a_prolog(jugador: Jugador) -> str:
    props = "[" + ",".join(atomo_prolog(p) for p in jugador.propiedades) + "]"
    return f"jugador({atomo_prolog(jugador.nombre)},{jugador.posicion},{jugador.dinero},{props})"


def estado_a_prolog(estado: Estado) -> str:
    jugadores = "[" + ",".join(jugador_a_prolog(j) for j in estado.jugadores) + "]"
    return f"estado({jugadores},Tablero,{estado.turno})"


def tiradas_a_prolog(tiradas: List[int]) -> str:
    return "[" + ",".join(str(x) for x in tiradas) + "]"


# ============================================================
# PARSEO JSON -> PYTHON
# ============================================================

def estado_desde_dict(d: dict) -> Estado:
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

def _ejecutar_goal_prolog(goal: str):
    if not os.path.exists(ARCHIVO_BRIDGE_PROLOG):
        return None, f"No se encuentra {ARCHIVO_BRIDGE_PROLOG}"

    try:
        resultado = subprocess.run(
            ["swipl", "-q", "-g", goal],
            capture_output=True,
            text=True,
            check=False
        )
    except FileNotFoundError:
        return None, "No se encontro 'swipl'. Instala SWI-Prolog y anadelo al PATH."

    if resultado.returncode != 0:
        return None, (
            "Error al ejecutar Prolog.\n"
            f"STDOUT:\n{resultado.stdout}\n"
            f"STDERR:\n{resultado.stderr}"
        )

    salida = resultado.stdout.strip()
    if not salida:
        return None, "Prolog no devolvio ninguna salida."

    try:
        data = json.loads(salida)
        return data, ""
    except json.JSONDecodeError:
        return None, f"La salida de Prolog no es JSON valido:\n{salida}"


def ejecutar_traza_en_prolog(estado: Estado, tiradas: List[int]):
    estado_term = estado_a_prolog(estado)
    tiradas_term = tiradas_a_prolog(tiradas)

    goal = (
        f"consult('{ARCHIVO_BRIDGE_PROLOG}'), "
        f"simular_traza_desde_python({estado_term}, {tiradas_term}, JSON), "
        f"write(JSON), nl, halt."
    )
    return _ejecutar_goal_prolog(goal)


def listar_escenarios_prolog():
    goal = (
        f"consult('{ARCHIVO_BRIDGE_PROLOG}'), "
        f"listar_escenarios_desde_python(JSON), "
        f"write(JSON), nl, halt."
    )
    return _ejecutar_goal_prolog(goal)


def ejecutar_escenario_prolog(id_escenario: str):
    id_term = atomo_prolog(id_escenario)
    goal = (
        f"consult('{ARCHIVO_BRIDGE_PROLOG}'), "
        f"ejecutar_escenario_desde_python({id_term}, JSON), "
        f"write(JSON), nl, halt."
    )
    return _ejecutar_goal_prolog(goal)


# ============================================================
# CONSTRUCCION DE ESCENARIOS PERSONALIZADOS Y LOTES
# ============================================================

def construir_escenario_personalizado():
    print("\n=== ESCENARIO PERSONALIZADO ===\n")

    num_jugadores = leer_entero(
        f"Numero de jugadores [{NUM_JUGADORES_POR_DEFECTO}]: ",
        minimo=2,
        default=NUM_JUGADORES_POR_DEFECTO
    )

    jugadores = []
    for i in range(num_jugadores):
        print(f"\nJugador {i+1}")
        nombre = f"jugador{i+1}"
        dinero = leer_entero(f"  Dinero [{DINERO_INICIAL_POR_DEFECTO}]: ", minimo=0, default=DINERO_INICIAL_POR_DEFECTO)
        posicion = leer_entero("  Posicion [0]: ", minimo=0, maximo=39, default=0)
        props = leer_propiedades("  Propiedades iniciales (coma separadas, vacio = ninguna): ")
        jugadores.append(Jugador(nombre, posicion, dinero, props))

    turno = leer_entero("Turno actual [0]: ", minimo=0, maximo=num_jugadores - 1, default=0)

    modo_tiradas = input("Tiradas aleatorias? [s/n, defecto s]: ").strip().lower()
    if modo_tiradas in ("", "s", "si"):
        n = leer_entero(
            f"Numero de tiradas [{NUM_TIRADAS_POR_DEFECTO}]: ",
            minimo=1,
            default=NUM_TIRADAS_POR_DEFECTO
        )
        tiradas = generar_tiradas_aleatorias(n)
    else:
        tiradas = leer_lista_enteros("Introduce tiradas separadas por comas: ")

    estado = Estado(jugadores, tablero_base(), turno)
    return estado, tiradas


def construir_configuracion_lotes():
    print("\n=== ANALISIS POR LOTES ===\n")

    num_partidas = leer_entero("Numero de partidas [100]: ", minimo=1, default=100)
    num_jugadores = leer_entero(
        f"Numero de jugadores [{NUM_JUGADORES_POR_DEFECTO}]: ",
        minimo=2,
        default=NUM_JUGADORES_POR_DEFECTO
    )
    num_tiradas = leer_entero(
        f"Numero de turnos simulados por partida [{NUM_TIRADAS_POR_DEFECTO}]: ",
        minimo=1,
        default=NUM_TIRADAS_POR_DEFECTO
    )

    plantillas = []
    for i in range(num_jugadores):
        print(f"\nJugador {i+1}")
        nombre = f"jugador{i+1}"
        dinero_fijo = leer_entero_o_vacio(
            "  Dinero fijo para todas las partidas [Enter = aleatorio]: ",
            minimo=0
        )
        posicion_fija = leer_entero_o_vacio(
            "  Posicion fija para todas las partidas [Enter = aleatoria]: ",
            minimo=0,
            maximo=39
        )
        propiedades_fijas = leer_propiedades(
            "  Propiedades iniciales fijas (coma separadas, vacio = ninguna): "
        )
        plantillas.append(
            PlantillaJugadorLotes(
                nombre=nombre,
                dinero_fijo=dinero_fijo,
                posicion_fija=posicion_fija,
                propiedades_fijas=propiedades_fijas
            )
        )

    return {
        "num_partidas": num_partidas,
        "num_jugadores": num_jugadores,
        "num_tiradas_por_partida": num_tiradas,
        "plantillas": plantillas,
    }


# ============================================================
# MOSTRADO DE PANTALLAS
# ============================================================

def mostrar_bloque_estado(
    titulo: str,
    estado: Estado,
    lineas_info: Optional[List[str]] = None,
    bloques: Optional[List[str]] = None
):
    limpiar_pantalla()
    print("=" * 100)
    print(titulo)
    print("=" * 100)
    print(render_estado(estado))
    print()

    if lineas_info:
        print("INFORMACION")
        print("-" * 90)
        for linea in lineas_info:
            print(linea)
        print()

    if bloques:
        for bloque in bloques:
            if bloque:
                print(bloque)
                print()


def mostrar_pantalla_final(
    data: dict
):
    estado_inicial = estado_desde_dict(data["estado_inicial"])
    estado_final = estado_desde_dict(data["estado_final"])
    pasos = data["pasos"]
    metricas = data["metricas"]
    ranking_final = data.get("ranking_final", [])
    motivo_finalizacion = data.get("motivo_finalizacion", "limite_tiradas")
    escenario_info = data.get("escenario")
    estado_final_raw = data["estado_final"]

    limpiar_pantalla()
    print("=" * 100)
    print("PARTIDA FINALIZADA")
    print("=" * 100)
    print(render_estado(estado_final))
    print()
    print(
        render_resumen_partida_final(
            estado_inicial,
            estado_final,
            pasos,
            metricas,
            motivo_finalizacion,
            escenario_info
        )
    )
    print()
    print(render_metricas(metricas, "METRICAS FINALES"))
    print()
    print(render_ranking(ranking_final, "RANKING FINAL"))
    print()
    print(render_detalle_jugadores_estado(estado_final_raw, "DETALLE FINAL DE JUGADORES"))
    print()


# ============================================================
# REPRODUCCION PASO A PASO
# ============================================================

def reproducir_traza(data: dict):
    estado_inicial = estado_desde_dict(data["estado_inicial"])
    pasos = data["pasos"]
    escenario_info = data.get("escenario")

    print("\nModo de reproduccion:")
    print("1. Manual (Enter en cada paso)")
    print("2. Automatico")
    modo = input("Elige modo [1/2]: ").strip()

    manual = modo != "2"
    delay = 1.0
    if not manual:
        try:
            delay = float(input("Segundos entre pasos [1.0]: ").strip() or "1.0")
        except ValueError:
            delay = 1.0

    lineas_iniciales = ["La simulacion completa se ha ejecutado en Prolog."]
    if escenario_info:
        lineas_iniciales.append(f"Escenario   : {escenario_info.get('id', '-')}")
        lineas_iniciales.append(f"Tema        : {escenario_info.get('tema', '-')}")
        lineas_iniciales.append(f"Descripcion : {escenario_info.get('descripcion', '-')}")

    mostrar_bloque_estado(
        "ESTADO INICIAL",
        estado_inicial,
        lineas_info=lineas_iniciales,
        bloques=[]
    )
    pausa("Pulsa Enter para comenzar...")

    for paso in pasos:
        estado_despues = estado_desde_dict(paso["estado_despues"])
        paso_num = paso["paso_num"]
        accion_tipo = paso.get("accion_tipo", "-")
        accion_texto = paso.get("accion_texto", "-")
        actor = paso.get("actor", "-")
        actor_despues = paso.get("actor_despues", {})
        ranking_despues = paso.get("ranking_despues", [])
        metricas_acumuladas = paso.get("metricas_acumuladas", {})

        lineas_info = [
            f"Paso            : {paso_num}",
            f"Tipo de accion  : {accion_tipo}",
            f"Accion          : {accion_texto}",
            f"Actor           : {actor}",
        ]

        bloques = [
            render_detalle_jugador(actor_despues, "DETALLE DEL ACTOR DESPUES DEL PASO"),
            render_ranking(ranking_despues, "RANKING TRAS EL PASO"),
            render_metricas(metricas_acumuladas, "METRICAS ACUMULADAS"),
        ]

        mostrar_bloque_estado(
            f"PASO {paso_num}",
            estado_despues,
            lineas_info=lineas_info,
            bloques=bloques
        )

        if manual:
            pausa("Pulsa Enter para continuar...")
        else:
            time.sleep(delay)

    mostrar_pantalla_final(data)
    pausa("Pulsa Enter para volver al menu...")


# ============================================================
# EJECUCION DE SIMULACIONES
# ============================================================

def ejecutar_simulacion(estado: Estado, tiradas: List[int]):
    errores = validar_escenario(estado, tiradas)
    if errores:
        limpiar_pantalla()
        print("ESCENARIO INVALIDO")
        print("-" * 80)
        for error in errores:
            print(f"- {error}")
        pausa("\nPulsa Enter para volver al menu...")
        return

    data, error = ejecutar_traza_en_prolog(estado, tiradas)
    if error:
        limpiar_pantalla()
        print("ERROR")
        print("-" * 80)
        print(error)
        pausa("\nPulsa Enter para volver al menu...")
        return

    reproducir_traza(data)


def ejecutar_analisis_lotes():
    config = construir_configuracion_lotes()
    plantillas = config["plantillas"]
    nombres = [p.nombre for p in plantillas]

    acumulador = inicializar_acumulador_resultados(nombres)

    limpiar_pantalla()
    print("=" * 100)
    print("EJECUTANDO ANALISIS POR LOTES")
    print("=" * 100)
    print(f"Partidas a ejecutar: {config['num_partidas']}")
    print()

    for i in range(config["num_partidas"]):
        estado = construir_estado_aleatorio_desde_plantillas(
            plantillas=plantillas,
            clase_estado=Estado,
            clase_jugador=Jugador,
            tablero=tablero_base()
        )
        tiradas = generar_tiradas_aleatorias(config["num_tiradas_por_partida"])

        errores = validar_escenario(estado, tiradas)
        if errores:
            limpiar_pantalla()
            print("ERROR EN ANALISIS POR LOTES")
            print("-" * 80)
            print("La configuracion ha generado un estado invalido.")
            for error in errores:
                print(f"- {error}")
            pausa("\nPulsa Enter para volver al menu...")
            return

        data, error = ejecutar_traza_en_prolog(estado, tiradas)
        if error:
            limpiar_pantalla()
            print("ERROR EN ANALISIS POR LOTES")
            print("-" * 80)
            print(f"Partida {i + 1} de {config['num_partidas']}")
            print(error)
            pausa("\nPulsa Enter para volver al menu...")
            return

        actualizar_acumulador_con_partida(acumulador, data)

        if (i + 1) % 10 == 0 or (i + 1) == config["num_partidas"]:
            print(f"Partidas finalizadas: {i + 1}/{config['num_partidas']}")

    resumen = construir_resumen_lotes(acumulador, config)

    limpiar_pantalla()
    print(resumen)
    pausa("\nPulsa Enter para volver al menu...")


# ============================================================
# MENU DE ESCENARIOS PROLOG
# ============================================================

def ver_escenarios_precargados():
    data, error = listar_escenarios_prolog()
    if error:
        limpiar_pantalla()
        print("ERROR")
        print("-" * 80)
        print(error)
        pausa("\nPulsa Enter para volver al menu...")
        return

    escenarios = data.get("escenarios", [])

    limpiar_pantalla()
    print("ESCENARIOS PRECARGADOS (DESDE PROLOG)")
    print("-" * 90)
    for i, escenario in enumerate(escenarios, start=1):
        print(f"{i:>2}. {escenario.get('id', '-'):<6} | {escenario.get('tema', '-')}")
        print(f"    {escenario.get('descripcion', '-')}")
    pausa("\nPulsa Enter para volver al menu...")


def ejecutar_escenario_precargado():
    data, error = listar_escenarios_prolog()
    if error:
        limpiar_pantalla()
        print("ERROR")
        print("-" * 80)
        print(error)
        pausa("\nPulsa Enter para volver al menu...")
        return

    escenarios = data.get("escenarios", [])
    if not escenarios:
        limpiar_pantalla()
        print("No hay escenarios disponibles.")
        pausa("\nPulsa Enter para volver al menu...")
        return

    limpiar_pantalla()
    print("SELECCION DE ESCENARIO")
    print("-" * 90)
    for i, escenario in enumerate(escenarios, start=1):
        print(f"{i:>2}. {escenario.get('id', '-'):<6} | {escenario.get('tema', '-')}")
        print(f"    {escenario.get('descripcion', '-')}")

    idx = leer_entero("Numero: ", minimo=1, maximo=len(escenarios))
    id_escenario = escenarios[idx - 1]["id"]

    data_esc, error_esc = ejecutar_escenario_prolog(id_escenario)
    if error_esc:
        limpiar_pantalla()
        print("ERROR")
        print("-" * 80)
        print(error_esc)
        pausa("\nPulsa Enter para volver al menu...")
        return

    reproducir_traza(data_esc)


# ============================================================
# MENU
# ============================================================

def imprimir_menu():
    limpiar_pantalla()
    print("=" * 72)
    print(" MONOPOLY - APP TERMINAL PYTHON + MOTOR LOGICO EN PROLOG")
    print("=" * 72)
    print("1. Ver escenarios precargados")
    print("2. Ejecutar escenario precargado")
    print("3. Crear escenario personalizado")
    print("4. Partida rapida aleatoria")
    print("5. Analisis por lotes")
    print("6. Salir")


def ejecutar_menu():
    while True:
        imprimir_menu()
        opcion = input("\nElige una opcion: ").strip()

        if opcion == "1":
            ver_escenarios_precargados()

        elif opcion == "2":
            ejecutar_escenario_precargado()

        elif opcion == "3":
            estado, tiradas = construir_escenario_personalizado()
            ejecutar_simulacion(estado, tiradas)

        elif opcion == "4":
            estado = Estado(
                jugadores=[
                    Jugador(f"jugador{i+1}", 0, DINERO_INICIAL_POR_DEFECTO, [])
                    for i in range(NUM_JUGADORES_POR_DEFECTO)
                ],
                tablero=tablero_base(),
                turno=0
            )
            tiradas = generar_tiradas_aleatorias(NUM_TIRADAS_POR_DEFECTO)
            ejecutar_simulacion(estado, tiradas)

        elif opcion == "5":
            ejecutar_analisis_lotes()

        elif opcion == "6":
            limpiar_pantalla()
            print("Saliendo.")
            break

        else:
            pausa("Opcion no valida. Pulsa Enter para continuar...")


if __name__ == "__main__":
    ejecutar_menu()