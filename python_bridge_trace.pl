:- consult('main.pl').
:- use_module(library(http/json)).

% ============================================================
% ADAPTACIÓN DEL ESTADO QUE LLEGA DESDE PYTHON
% ============================================================

estado_python_a_estado_prolog(
    estado(Js, Tablero, Turno),
    estado(Js, TableroReal, Turno)
) :-
    var(Tablero),
    tablero_base(TableroReal).

estado_python_a_estado_prolog(
    estado(Js, Tablero, Turno),
    estado(Js, Tablero, Turno)
) :-
    nonvar(Tablero).

% ============================================================
% SERIALIZACIÓN DE JUGADORES / ESTADOS / MÉTRICAS
% ============================================================

jugador_dict(
    jugador(Nombre, Posicion, Dinero, Propiedades),
    _{
        nombre: Nombre,
        posicion: Posicion,
        dinero: Dinero,
        propiedades: Propiedades
     }
).

jugadores_dicts([], []).
jugadores_dicts([J | R], [D | RD]) :-
    jugador_dict(J, D),
    jugadores_dicts(R, RD).

estado_dict(
    estado(Js, _Tablero, Turno),
    _{
        jugadores: JsDict,
        turno: Turno
     }
) :-
    jugadores_dicts(Js, JsDict).

metricas_dict(
    metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas),
    _{
        iter_por_turno: IterPorTurno,
        iter_total: IterTotal,
        compras: Compras,
        alquileres: Alquileres,
        bancarrotas: Bancarrotas
     }
) :-
    reverse(IterRev, IterPorTurno).

% ============================================================
% UTILIDADES
% ============================================================

nombre_jugador_activo(estado(Js, _Tab, Turno), Nombre) :-
    nth0(Turno, Js, jugador(Nombre, _, _, _)).

estado_jugador_por_nombre(estado(Js, _Tab, _Turno), Nombre, DictJugador) :-
    member(jugador(Nombre, Pos, Din, Props), Js),
    !,
    DictJugador = _{
        nombre: Nombre,
        posicion: Pos,
        dinero: Din,
        propiedades: Props,
        eliminado: false
    }.
estado_jugador_por_nombre(_Estado, Nombre, _{
    nombre: Nombre,
    eliminado: true
}).

paso_dict(NumTurno, Tirada, NombreJugador, EstadoAntes, EstadoDespues, DictPaso) :-
    estado_dict(EstadoAntes, EstadoAntesDict),
    estado_dict(EstadoDespues, EstadoDespuesDict),
    estado_jugador_por_nombre(EstadoAntes, NombreJugador, JugAntes),
    estado_jugador_por_nombre(EstadoDespues, NombreJugador, JugDespues),
    DictPaso = _{
        turno_num: NumTurno,
        tirada: Tirada,
        jugador_activo: NombreJugador,
        jugador_antes: JugAntes,
        jugador_despues: JugDespues,
        estado_antes: EstadoAntesDict,
        estado_despues: EstadoDespuesDict
    }.

% ============================================================
% SIMULACIÓN CON TRAZA COMPLETA
% ============================================================

simular_con_traza(EstadoInicial, Tiradas, EstadoFinal, Pasos, MetricasFinales) :-
    metricas_init(M0),
    simular_con_traza_aux(EstadoInicial, Tiradas, 1, EstadoFinal, Pasos, M0, MetricasFinales).

simular_con_traza_aux(Estado, [], _NumTurno, Estado, [], M, M).
simular_con_traza_aux(EstadoIn, [T | Ts], NumTurno, EstadoFinal, [Paso | RestoPasos], M0, MOut) :-
    nombre_jugador_activo(EstadoIn, NombreJugador),
    turno_con_reglas_metricas(EstadoIn, T, M0, EstadoNext, M1),
    paso_dict(NumTurno, T, NombreJugador, EstadoIn, EstadoNext, Paso),
    NumTurno1 is NumTurno + 1,
    simular_con_traza_aux(EstadoNext, Ts, NumTurno1, EstadoFinal, RestoPasos, M1, MOut).

% ============================================================
% JSON FINAL PARA PYTHON
% ============================================================

resultado_traza_json(EstadoInicial, Pasos, EstadoFinal, Metricas, JSONAtom) :-
    estado_dict(EstadoInicial, EstadoInicialDict),
    estado_dict(EstadoFinal, EstadoFinalDict),
    metricas_dict(Metricas, MetricasDict),
    Dict = _{
        estado_inicial: EstadoInicialDict,
        pasos: Pasos,
        estado_final: EstadoFinalDict,
        metricas: MetricasDict
    },
    atom_json_dict(JSONAtom, Dict, []).

simular_traza_desde_python(EstadoPython, Tiradas, JSONAtom) :-
    estado_python_a_estado_prolog(EstadoPython, Estado0),
    simular_con_traza(Estado0, Tiradas, EstadoFinal, Pasos, Metricas),
    resultado_traza_json(Estado0, Pasos, EstadoFinal, Metricas, JSONAtom).