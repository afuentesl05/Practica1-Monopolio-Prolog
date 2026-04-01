import random
from dataclasses import dataclass, field
from typing import List, Optional, Dict


DINERO_ALEATORIO_MIN = 500
DINERO_ALEATORIO_MAX = 2500
POSICION_ALEATORIA_MIN = 0
POSICION_ALEATORIA_MAX = 39


@dataclass
class PlantillaJugadorLotes:
    nombre: str
    dinero_fijo: Optional[int] = None
    posicion_fija: Optional[int] = None
    propiedades_fijas: List[str] = field(default_factory=list)


def generar_dinero_aleatorio() -> int:
    return random.randint(DINERO_ALEATORIO_MIN, DINERO_ALEATORIO_MAX)


def generar_posicion_aleatoria() -> int:
    return random.randint(POSICION_ALEATORIA_MIN, POSICION_ALEATORIA_MAX)


def construir_jugador_desde_plantilla(plantilla, clase_jugador):
    dinero = plantilla.dinero_fijo
    if dinero is None:
        dinero = generar_dinero_aleatorio()

    posicion = plantilla.posicion_fija
    if posicion is None:
        posicion = generar_posicion_aleatoria()

    return clase_jugador(
        nombre=plantilla.nombre,
        posicion=posicion,
        dinero=dinero,
        propiedades=list(plantilla.propiedades_fijas)
    )


def construir_estado_aleatorio_desde_plantillas(plantillas, clase_estado, clase_jugador, tablero):
    jugadores = [
        construir_jugador_desde_plantilla(plantilla, clase_jugador)
        for plantilla in plantillas
    ]
    return clase_estado(jugadores=jugadores, tablero=tablero, turno=0)


def inicializar_acumulador_resultados(nombres_jugadores: List[str]) -> Dict:
    return {
        "partidas": 0,
        "partidas_con_ganador_unico": 0,
        "partidas_sin_ganador_unico": 0,
        "turnos_totales": 0,
        "compras_totales": 0,
        "alquileres_totales": 0,
        "bancarrotas_totales": 0,
        "monopolios_totales": 0,
        "iteraciones_totales": 0,
        "finalizadas_por_victoria": 0,
        "finalizadas_por_limite_tiradas": 0,
        "finalizadas_por_sin_jugadores": 0,
        "victorias_primera_posicion": {nombre: 0 for nombre in nombres_jugadores},
        "patrimonio_final_acumulado": {nombre: 0 for nombre in nombres_jugadores},
        "dinero_final_acumulado": {nombre: 0 for nombre in nombres_jugadores},
        "num_props_final_acumulado": {nombre: 0 for nombre in nombres_jugadores},
        "apariciones_en_ranking_final": {nombre: 0 for nombre in nombres_jugadores},
    }


def actualizar_acumulador_con_partida(acumulador: Dict, data_partida: dict):
    acumulador["partidas"] += 1

    pasos = data_partida.get("pasos", [])
    estado_final = data_partida.get("estado_final", {})
    metricas = data_partida.get("metricas", {})
    ranking_final = data_partida.get("ranking_final", [])
    motivo_finalizacion = data_partida.get("motivo_finalizacion", "limite_tiradas")

    acumulador["turnos_totales"] += len(pasos)
    acumulador["compras_totales"] += metricas.get("compras", 0)
    acumulador["alquileres_totales"] += metricas.get("alquileres", 0)
    acumulador["bancarrotas_totales"] += metricas.get("bancarrotas", 0)
    acumulador["monopolios_totales"] += metricas.get("monopolios", 0)
    acumulador["iteraciones_totales"] += metricas.get("iter_total", 0)

    jugadores_restantes = estado_final.get("jugadores", [])
    if len(jugadores_restantes) == 1:
        acumulador["partidas_con_ganador_unico"] += 1
    else:
        acumulador["partidas_sin_ganador_unico"] += 1

    if motivo_finalizacion == "victoria":
        acumulador["finalizadas_por_victoria"] += 1
    elif motivo_finalizacion == "sin_jugadores":
        acumulador["finalizadas_por_sin_jugadores"] += 1
    else:
        acumulador["finalizadas_por_limite_tiradas"] += 1

    if ranking_final:
        nombre_primero = ranking_final[0]["nombre"]
        if nombre_primero in acumulador["victorias_primera_posicion"]:
            acumulador["victorias_primera_posicion"][nombre_primero] += 1

    for item in ranking_final:
        nombre = item["nombre"]
        if nombre in acumulador["patrimonio_final_acumulado"]:
            acumulador["patrimonio_final_acumulado"][nombre] += item.get("patrimonio", 0)
            acumulador["dinero_final_acumulado"][nombre] += item.get("dinero", 0)
            acumulador["num_props_final_acumulado"][nombre] += item.get("num_propiedades", 0)
            acumulador["apariciones_en_ranking_final"][nombre] += 1


def media(total: float, n: int) -> float:
    if n == 0:
        return 0.0
    return total / n


def construir_resumen_lotes(acumulador: Dict, config: Dict) -> str:
    partidas = acumulador["partidas"]
    nombres = list(acumulador["victorias_primera_posicion"].keys())

    lineas = []
    lineas.append("=" * 100)
    lineas.append("ANALISIS POR LOTES")
    lineas.append("=" * 100)
    lineas.append(f"Numero de partidas              : {partidas}")
    lineas.append(f"Numero de jugadores             : {config['num_jugadores']}")
    lineas.append(f"Turnos simulados por partida    : {config['num_tiradas_por_partida']}")
    lineas.append(f"Dinero aleatorio por defecto    : {DINERO_ALEATORIO_MIN}..{DINERO_ALEATORIO_MAX}")
    lineas.append(f"Posicion aleatoria por defecto  : {POSICION_ALEATORIA_MIN}..{POSICION_ALEATORIA_MAX}")
    lineas.append("")

    lineas.append("RESULTADOS GENERALES")
    lineas.append("-" * 100)
    lineas.append(f"Partidas con ganador unico      : {acumulador['partidas_con_ganador_unico']}")
    lineas.append(f"Partidas sin ganador unico      : {acumulador['partidas_sin_ganador_unico']}")
    lineas.append(f"Finalizadas por victoria        : {acumulador['finalizadas_por_victoria']}")
    lineas.append(f"Finalizadas por limite          : {acumulador['finalizadas_por_limite_tiradas']}")
    lineas.append(f"Finalizadas sin jugadores       : {acumulador['finalizadas_por_sin_jugadores']}")
    lineas.append(f"Media de pasos                  : {media(acumulador['turnos_totales'], partidas):.2f}")
    lineas.append(f"Media de compras                : {media(acumulador['compras_totales'], partidas):.2f}")
    lineas.append(f"Media de alquileres             : {media(acumulador['alquileres_totales'], partidas):.2f}")
    lineas.append(f"Media de bancarrotas            : {media(acumulador['bancarrotas_totales'], partidas):.2f}")
    lineas.append(f"Media de monopolios             : {media(acumulador['monopolios_totales'], partidas):.2f}")
    lineas.append(f"Media de iteraciones totales    : {media(acumulador['iteraciones_totales'], partidas):.2f}")
    lineas.append("")

    lineas.append("PRIMER PUESTO FINAL")
    lineas.append("-" * 100)
    for nombre in nombres:
        lineas.append(f"{nombre:<15} : {acumulador['victorias_primera_posicion'][nombre]}")
    lineas.append("")

    lineas.append("MEDIAS FINALES POR JUGADOR")
    lineas.append("-" * 100)
    for nombre in nombres:
        apariciones = acumulador["apariciones_en_ranking_final"][nombre]
        lineas.append(
            f"{nombre:<15} | "
            f"Patrimonio medio: {media(acumulador['patrimonio_final_acumulado'][nombre], apariciones):>8.2f} | "
            f"Dinero medio: {media(acumulador['dinero_final_acumulado'][nombre], apariciones):>8.2f} | "
            f"Props medias: {media(acumulador['num_props_final_acumulado'][nombre], apariciones):>6.2f}"
        )

    return "\n".join(lineas)