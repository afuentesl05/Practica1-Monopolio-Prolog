:- ensure_loaded('../main.pl').
:- ensure_loaded('../scenarios.pl').
:- use_module(library(http/json)).

% ============================================================
% ADAPTACION DEL ESTADO QUE LLEGA DESDE PYTHON
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
% SERIALIZACION DE PROPIEDADES
% ============================================================

propiedad_dict(PropRaw,
    _{
        id: PropId,
        hipotecada: HipotecadaBool,
        casas: Casas
    }
) :-
    prop_campos(PropRaw, PropId, Hipotecada, Casas),
    ( Hipotecada == si -> HipotecadaBool = true ; HipotecadaBool = false ).

propiedades_dicts([], []).
propiedades_dicts([P | Ps], [D | Ds]) :-
    propiedad_dict(P, D),
    propiedades_dicts(Ps, Ds).

% ============================================================
% SERIALIZACION DE JUGADORES / ESTADOS / METRICAS / RANKING
% ============================================================

estado_turno_dict(estado_turno(libre, Dobles),
    _{
        libertad: libre,
        turnos_carcel: 0,
        dobles_seguidos: Dobles
    }
).

estado_turno_dict(estado_turno(carcel(Turnos), Dobles),
    _{
        libertad: carcel,
        turnos_carcel: Turnos,
        dobles_seguidos: Dobles
    }
).

jugador_dict(
    Jugador,
    _{
        nombre: Nombre,
        posicion: Posicion,
        dinero: Dinero,
        propiedades: PropIds,
        propiedades_detalle: PropsDetalle,
        estado_turno: EstadoTurnoDict,
        en_carcel: EnCarcel
     }
) :-
    jugador_campos(Jugador, Nombre, Posicion, Dinero, Propiedades, EstadoTurno),
    props_ids(Propiedades, PropIds),
    propiedades_dicts(Propiedades, PropsDetalle),
    estado_turno_dict(EstadoTurno, EstadoTurnoDict),
    ( EstadoTurno = estado_turno(carcel(_), _) -> EnCarcel = true ; EnCarcel = false ).

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
    metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas, Monopolios),
    _{
        iter_por_turno: IterPorTurno,
        iter_total: IterTotal,
        compras: Compras,
        alquileres: Alquileres,
        bancarrotas: Bancarrotas,
        monopolios: Monopolios
     }
) :-
    reverse(IterRev, IterPorTurno).

ranking_item_dict(
    ranking(Nombre, Patrimonio, Dinero, ValorProps, NumProps),
    _{
        nombre: Nombre,
        patrimonio: Patrimonio,
        dinero: Dinero,
        valor_propiedades: ValorProps,
        num_propiedades: NumProps
     }
).

ranking_dicts([], []).
ranking_dicts([R | Rs], [D | Ds]) :-
    ranking_item_dict(R, D),
    ranking_dicts(Rs, Ds).

ranking_estado_dict(Estado, RankingDict) :-
    ranking_jugadores(Estado, Ranking),
    ranking_dicts(Ranking, RankingDict).

% ============================================================
% UTILIDADES
% ============================================================

nombre_jugador_activo(estado(Js, _Tab, Turno), Nombre) :-
    nth0(Turno, Js, Jugador),
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno).

estado_jugador_por_nombre(estado(Js, _Tab, _Turno), Nombre, DictJugador) :-
    member(Jugador, Js),
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno),
    !,
    jugador_dict(Jugador, DictJugador).
estado_jugador_por_nombre(_Estado, Nombre, _{
    nombre: Nombre,
    eliminado: true
}).

motivo_finalizacion_estado(EstadoFinal, Motivo) :-
    (   fin_partida(EstadoFinal, MotivoFin)
    ->  Motivo = MotivoFin
    ;   Motivo = limite_tiradas
    ).

accion_tipo(tirar(_), tirar).
accion_tipo(hipotecar(_, _), hipotecar).
accion_tipo(deshipotecar(_, _), deshipotecar).
accion_tipo(construir_casa(_, _), construir_casa).
accion_tipo(intentar_construir_casa(_, _), intentar_construir_casa).

accion_texto(tirar(Tirada), Texto) :-
    tirada_texto(Tirada, Texto).
accion_texto(hipotecar(Nombre, PropId), Texto) :-
    format(atom(Texto), 'Hipotecar ~w sobre ~w', [Nombre, PropId]).
accion_texto(deshipotecar(Nombre, PropId), Texto) :-
    format(atom(Texto), 'Deshipotecar ~w sobre ~w', [Nombre, PropId]).
accion_texto(construir_casa(Nombre, PropId), Texto) :-
    format(atom(Texto), 'Construir casa: ~w en ~w', [Nombre, PropId]).
accion_texto(intentar_construir_casa(Nombre, PropId), Texto) :-
    format(atom(Texto), 'Intentar construir casa: ~w en ~w', [Nombre, PropId]).

tirada_texto(Tirada, Texto) :-
    integer(Tirada),
    !,
    format(atom(Texto), 'Tirada ~d', [Tirada]).
tirada_texto(tirada(D1, D2), Texto) :-
    Total is D1 + D2,
    format(atom(Texto), 'Tirada ~d+~d=~d', [D1, D2, Total]).

actor_accion(EstadoIn, tirar(_), NombreActor) :-
    nombre_jugador_activo(EstadoIn, NombreActor).
actor_accion(_EstadoIn, hipotecar(Nombre, _), Nombre).
actor_accion(_EstadoIn, deshipotecar(Nombre, _), Nombre).
actor_accion(_EstadoIn, construir_casa(Nombre, _), Nombre).
actor_accion(_EstadoIn, intentar_construir_casa(Nombre, _), Nombre).

paso_dict(
    NumPaso,
    Accion,
    NombreActor,
    EstadoAntes,
    EstadoDespues,
    MetricasAcumuladas,
    DictPaso
) :-
    accion_tipo(Accion, AccionTipo),
    accion_texto(Accion, AccionTexto),
    estado_dict(EstadoAntes, EstadoAntesDict),
    estado_dict(EstadoDespues, EstadoDespuesDict),
    estado_jugador_por_nombre(EstadoAntes, NombreActor, ActorAntes),
    estado_jugador_por_nombre(EstadoDespues, NombreActor, ActorDespues),
    metricas_dict(MetricasAcumuladas, MetricasDict),
    ranking_estado_dict(EstadoDespues, RankingDespuesDict),
    DictPaso = _{
        paso_num: NumPaso,
        accion_tipo: AccionTipo,
        accion_texto: AccionTexto,
        actor: NombreActor,
        actor_antes: ActorAntes,
        actor_despues: ActorDespues,
        estado_antes: EstadoAntesDict,
        estado_despues: EstadoDespuesDict,
        metricas_acumuladas: MetricasDict,
        ranking_despues: RankingDespuesDict
    }.

escenario_meta_dict(IdEscenario, MetaDict) :-
    escenario(IdEscenario, Tema, Descripcion),
    MetaDict = _{
        id: IdEscenario,
        tema: Tema,
        descripcion: Descripcion
    }.

% ============================================================
% TRAZA GENERICA POR ACCIONES
% ============================================================

simular_acciones_con_traza(EstadoInicial, Acciones, EstadoFinal, Pasos, MetricasFinales) :-
    metricas_init(M0),
    simular_acciones_con_traza_aux(EstadoInicial, Acciones, 1, EstadoFinal, Pasos, M0, MetricasFinales).

simular_acciones_con_traza_aux(Estado, _AccionesRestantes, _NumPaso, Estado, [], M, M) :-
    fin_partida(Estado, _Motivo),
    !.
simular_acciones_con_traza_aux(Estado, [], _NumPaso, Estado, [], M, M).
simular_acciones_con_traza_aux(EstadoIn, [Accion | Resto], NumPaso, EstadoFinal, [Paso | RestoPasos], M0, MOut) :-
    actor_accion(EstadoIn, Accion, NombreActor),
    ejecutar_accion_metricas(Accion, EstadoIn, EstadoNext, M0, M1),
    paso_dict(NumPaso, Accion, NombreActor, EstadoIn, EstadoNext, M1, Paso),
    NumPaso1 is NumPaso + 1,
    simular_acciones_con_traza_aux(EstadoNext, Resto, NumPaso1, EstadoFinal, RestoPasos, M1, MOut).

% ============================================================
% TRAZA DESDE LISTA DE TIRADAS
% ============================================================

simular_con_traza(EstadoInicial, Tiradas, EstadoFinal, Pasos, MetricasFinales) :-
    maplist(envolver_tirada, Tiradas, Acciones),
    simular_acciones_con_traza(EstadoInicial, Acciones, EstadoFinal, Pasos, MetricasFinales).

% ============================================================
% JSON FINAL PARA PYTHON
% ============================================================

resultado_traza_json_base(EstadoInicial, Pasos, EstadoFinal, Metricas, Dict) :-
    estado_dict(EstadoInicial, EstadoInicialDict),
    estado_dict(EstadoFinal, EstadoFinalDict),
    metricas_dict(Metricas, MetricasDict),
    ranking_estado_dict(EstadoFinal, RankingFinalDict),
    motivo_finalizacion_estado(EstadoFinal, MotivoFinalizacion),
    Dict = _{
        estado_inicial: EstadoInicialDict,
        pasos: Pasos,
        estado_final: EstadoFinalDict,
        metricas: MetricasDict,
        ranking_final: RankingFinalDict,
        motivo_finalizacion: MotivoFinalizacion
    }.

resultado_traza_json(EstadoInicial, Pasos, EstadoFinal, Metricas, JSONAtom) :-
    resultado_traza_json_base(EstadoInicial, Pasos, EstadoFinal, Metricas, Dict),
    atom_json_dict(JSONAtom, Dict, []).

resultado_traza_json_escenario(IdEscenario, EstadoInicial, Pasos, EstadoFinal, Metricas, JSONAtom) :-
    resultado_traza_json_base(EstadoInicial, Pasos, EstadoFinal, Metricas, DictBase),
    escenario_meta_dict(IdEscenario, EscenarioMeta),
    put_dict(_{escenario: EscenarioMeta}, DictBase, DictFinal),
    atom_json_dict(JSONAtom, DictFinal, []).

simular_traza_desde_python(EstadoPython, Tiradas, JSONAtom) :-
    estado_python_a_estado_prolog(EstadoPython, Estado0),
    simular_con_traza(Estado0, Tiradas, EstadoFinal, Pasos, Metricas),
    resultado_traza_json(Estado0, Pasos, EstadoFinal, Metricas, JSONAtom).

% ============================================================
% ESCENARIOS DESDE PYTHON
% ============================================================

listar_escenarios_desde_python(JSONAtom) :-
    findall(
        _{id: Id, tema: Tema, descripcion: Descripcion},
        escenario(Id, Tema, Descripcion),
        Escenarios
    ),
    atom_json_dict(JSONAtom, _{escenarios: Escenarios}, []).

ejecutar_escenario_desde_python(IdEscenario, JSONAtom) :-
    estado_inicial(IdEscenario, EstadoInicial),
    acciones_escenario(IdEscenario, Acciones),
    simular_acciones_con_traza(EstadoInicial, Acciones, EstadoFinal, Pasos, Metricas),
    resultado_traza_json_escenario(IdEscenario, EstadoInicial, Pasos, EstadoFinal, Metricas, JSONAtom).