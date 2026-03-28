:- consult('scenarios.pl').
:- use_module(library(http/json)).
:- use_module(library(random)).

json_bool(true, true).
json_bool(false, false).

json_null(null).

metricas_ui_dict(
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

ranking_item_ui_dict(
    ranking(Nombre, Patrimonio, Dinero, ValorProps, NumProps),
    _{
        nombre: Nombre,
        patrimonio: Patrimonio,
        dinero: Dinero,
        valor_propiedades: ValorProps,
        num_propiedades: NumProps
     }
).

ranking_ui_dicts(Estado, RankingDicts) :-
    ranking_jugadores(Estado, Ranking),
    maplist(ranking_item_ui_dict, Ranking, RankingDicts).

crear_jugadores_base(I, N, _Dinero, []) :-
    I > N,
    !.
crear_jugadores_base(I, N, Dinero, [jugador(Nombre, 0, Dinero, []) | Resto]) :-
    atom_concat(jugador, I, Nombre),
    I1 is I + 1,
    crear_jugadores_base(I1, N, Dinero, Resto).

estado_base_batch(NumJugadores, DineroInicial,
    estado(Js, Tablero, 0)) :-
    integer(NumJugadores),
    NumJugadores >= 2,
    integer(DineroInicial),
    DineroInicial >= 0,
    tablero_base(Tablero),
    crear_jugadores_base(1, NumJugadores, DineroInicial, Js).

jugadores_restantes(estado(Js, _Tablero, _Turno), N) :-
    length(Js, N).

partida_terminada(Estado) :-
    jugadores_restantes(Estado, N),
    N =< 1.

tirada_aleatoria(real, tirada(D1, D2)) :-
    random_between(1, 6, D1),
    random_between(1, 6, D2).
tirada_aleatoria(legacy, T) :-
    random_between(2, 12, T).

simular_partida_lote(Estado, _Modo, _TurnosRestantes, Estado, 0, true, M, M) :-
    partida_terminada(Estado),
    !.
simular_partida_lote(Estado, _Modo, 0, Estado, 0, false, M, M) :-
    !.
simular_partida_lote(EstadoIn, Modo, TurnosRestantes, EstadoFinal, TurnosJugados, Finalizada, M0, MOut) :-
    TurnosRestantes > 0,
    tirada_aleatoria(Modo, Tirada),
    turno_con_reglas_metricas(EstadoIn, Tirada, M0, EstadoNext, M1),
    Restantes1 is TurnosRestantes - 1,
    simular_partida_lote(EstadoNext, Modo, Restantes1, EstadoFinal, TurnosRec, Finalizada, M1, MOut),
    TurnosJugados is TurnosRec + 1.

resultado_simulacion_ui_dict(Id, TurnosLimite, EstadoFinal, TurnosJugados, Finalizada, Metricas, Dict) :-
    jugadores_restantes(EstadoFinal, NumRestantes),
    ranking_jugadores(EstadoFinal, Ranking),
    ranking_ui_dicts(EstadoFinal, RankingDicts),
    metricas_ui_dict(Metricas, MetricasDict),
    json_bool(Finalizada, FinalizadaBool),
    (   Ranking = [ranking(Lider, PatrimonioLider, DineroLider, ValorPropsLider, NumPropsLider) | _]
    ->  LiderOut = Lider,
        PatrimonioOut = PatrimonioLider,
        DineroOut = DineroLider,
        ValorPropsOut = ValorPropsLider,
        NumPropsOut = NumPropsLider
    ;   LiderOut = null,
        PatrimonioOut = null,
        DineroOut = null,
        ValorPropsOut = null,
        NumPropsOut = null
    ),
    (   Finalizada = true,
        Ranking = [ranking(Ganador, _, _, _, _) | _]
    ->  GanadorOut = Ganador
    ;   GanadorOut = null
    ),
    Dict = _{
        id: Id,
        turnos_limite: TurnosLimite,
        turnos_jugados: TurnosJugados,
        finalizada: FinalizadaBool,
        jugadores_restantes: NumRestantes,
        ganador: GanadorOut,
        lider: LiderOut,
        patrimonio_lider: PatrimonioOut,
        dinero_lider: DineroOut,
        valor_propiedades_lider: ValorPropsOut,
        num_propiedades_lider: NumPropsOut,
        ranking_final: RankingDicts,
        metricas: MetricasDict
    }.

simulacion_aleatoria_ui(Id, NumJugadores, DineroInicial, TurnosLimite, Modo, Dict) :-
    estado_base_batch(NumJugadores, DineroInicial, EstadoInicial),
    metricas_init(M0),
    simular_partida_lote(EstadoInicial, Modo, TurnosLimite, EstadoFinal, TurnosJugados, Finalizada, M0, Metricas),
    resultado_simulacion_ui_dict(Id, TurnosLimite, EstadoFinal, TurnosJugados, Finalizada, Metricas, Dict).

simulaciones_aleatorias_ui(NumSimulaciones, NumJugadores, DineroInicial, TurnosLimite, Modo, JSONAtom) :-
    integer(NumSimulaciones),
    NumSimulaciones >= 1,
    findall(
        Dict,
        (
            between(1, NumSimulaciones, Id),
            simulacion_aleatoria_ui(Id, NumJugadores, DineroInicial, TurnosLimite, Modo, Dict)
        ),
        Resultados
    ),
    DictOut = _{
        configuracion: _{
            simulaciones: NumSimulaciones,
            jugadores: NumJugadores,
            dinero_inicial: DineroInicial,
            turnos_limite: TurnosLimite,
            modo: Modo
        },
        simulaciones: Resultados
    },
    atom_json_dict(JSONAtom, DictOut, []).
