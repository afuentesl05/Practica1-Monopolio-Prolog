:- ensure_loaded('../scenarios.pl').
:- use_module(library(http/json)).
:- use_module(library(lists)).

% ============================================================
% BOOL / NULL JSON
% ============================================================

json_bool(si, true).
json_bool(no, false).
json_bool(true, true).
json_bool(false, false).

json_null(null).

% ============================================================
% SERIALIZACION CANONICA
% ============================================================

estado_turno_ui_dict(
    estado_turno(libre, Dobles),
    _{
        modo: "libre",
        turnos_carcel: 0,
        dobles_seguidos: Dobles
     }
).

estado_turno_ui_dict(
    estado_turno(carcel(Turnos), Dobles),
    _{
        modo: "carcel",
        turnos_carcel: Turnos,
        dobles_seguidos: Dobles
     }
).

propiedad_ui_dict(
    PropRaw,
    _{
        id: PropId,
        hipotecada: HipBool,
        casas: Casas
     }
) :-
    prop_campos(PropRaw, PropId, Hipotecada, Casas),
    json_bool(Hipotecada, HipBool).

jugador_ui_dict(
    Jugador,
    _{
        nombre: Nombre,
        posicion: Pos,
        dinero: Din,
        propiedades: PropsDict,
        estado_turno: EstadoTurnoDict
     }
) :-
    jugador_campos(Jugador, Nombre, Pos, Din, Props, EstadoTurno),
    maplist(propiedad_ui_dict, Props, PropsDict),
    estado_turno_ui_dict(EstadoTurno, EstadoTurnoDict).

jugadores_ui_dicts([], []).
jugadores_ui_dicts([J | R], [D | RD]) :-
    jugador_ui_dict(J, D),
    jugadores_ui_dicts(R, RD).

casilla_ui_dict(
    salida,
    _{
        tipo: "salida",
        nombre: "salida"
     }
).

casilla_ui_dict(
    carta,
    _{
        tipo: "carta",
        nombre: "carta"
     }
).

casilla_ui_dict(
    impuesto(Monto),
    _{
        tipo: "impuesto",
        nombre: "impuesto",
        monto: Monto
     }
).

casilla_ui_dict(
    especial(Tipo),
    _{
        tipo: "especial",
        nombre: Tipo
     }
).

casilla_ui_dict(
    propiedad(Id, Precio, Color),
    _{
        tipo: "propiedad",
        nombre: Id,
        precio: Precio,
        color: Color
     }
).

tablero_ui_dicts([], []).
tablero_ui_dicts([C | R], [D | RD]) :-
    casilla_ui_dict(C, D),
    tablero_ui_dicts(R, RD).

estado_ui_dict(
    estado(Js, Tablero, Turno),
    _{
        jugadores: JsDict,
        turno: Turno,
        ranking: RankingDict
     }
) :-
    jugadores_ui_dicts(Js, JsDict),
    ranking_ui_dicts(estado(Js, Tablero, Turno), RankingDict).

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

% ============================================================
% TIRADAS / ACCIONES
% ============================================================

tirada_ui_dict(
    Tirada,
    _{
        modo: "legacy",
        total: Tirada,
        doble: false
     }
) :-
    integer(Tirada),
    !.

tirada_ui_dict(
    tirada(D1, D2),
    _{
        modo: "real",
        d1: D1,
        d2: D2,
        total: Total,
        doble: DobleBool
     }
) :-
    Total is D1 + D2,
    (   es_doble(tirada(D1, D2))
    ->  DobleBool = true
    ;   DobleBool = false
    ).

accion_ui_dict(
    tirar(Tirada),
    _{
        tipo: "tirar",
        tirada: TiradaDict
     }
) :-
    tirada_ui_dict(Tirada, TiradaDict).

accion_ui_dict(
    hipotecar(Nombre, PropId),
    _{
        tipo: "hipotecar",
        jugador: Nombre,
        propiedad: PropId
     }
).

accion_ui_dict(
    deshipotecar(Nombre, PropId),
    _{
        tipo: "deshipotecar",
        jugador: Nombre,
        propiedad: PropId
     }
).

accion_ui_dict(
    construir_casa(Nombre, PropId),
    _{
        tipo: "construir_casa",
        jugador: Nombre,
        propiedad: PropId
     }
).

accion_ui_dict(
    intentar_construir_casa(Nombre, PropId),
    _{
        tipo: "intentar_construir_casa",
        jugador: Nombre,
        propiedad: PropId
     }
).

actor_accion(tirar(_), EstadoIn, Nombre) :-
    jugador_activo(EstadoIn, Jugador),
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno).

actor_accion(hipotecar(Nombre, _), _EstadoIn, Nombre).
actor_accion(deshipotecar(Nombre, _), _EstadoIn, Nombre).
actor_accion(construir_casa(Nombre, _), _EstadoIn, Nombre).
actor_accion(intentar_construir_casa(Nombre, _), _EstadoIn, Nombre).

% ============================================================
% EJECUCION ROBUSTA DE ACCIONES
% ============================================================

ejecutar_accion_ui_metricas(Accion, EstadoIn, EstadoOut, Resultado, M0, MOut) :-
    (   ejecutar_accion_metricas(Accion, EstadoIn, EstadoTmp, M0, M1)
    ->  EstadoOut = EstadoTmp,
        Resultado = ok,
        MOut = M1
    ;   EstadoOut = EstadoIn,
        Resultado = fallo,
        MOut = M0
    ).

% ============================================================
% SNAPSHOT DE UN JUGADOR EN UN ESTADO
% ============================================================

jugador_snapshot(estado(Js, _Tab, _Turno), Nombre,
                 existe(Pos, Din, PropIds, Modo, TurnosCarcel, Dobles)) :-
    get_jugador(Nombre, Js, Jugador),
    !,
    jugador_campos(Jugador, _N, Pos, Din, Props, estado_turno(Libertad, Dobles)),
    props_ids(Props, PropIds),
    (   Libertad = libre
    ->  Modo = libre,
        TurnosCarcel = 0
    ;   Libertad = carcel(TurnosCarcel),
        Modo = carcel
    ).

jugador_snapshot(_Estado, _Nombre, no_existe).

jugador_ui_o_eliminado(Estado, Nombre, Dict) :-
    Estado = estado(Js, _Tab, _Turno),
    (   get_jugador(Nombre, Js, Jugador)
    ->  jugador_ui_dict(Jugador, Dict0),
        put_dict(_{eliminado: false}, Dict0, Dict)
    ;   Dict = _{
            nombre: Nombre,
            eliminado: true
        }
    ).

delta_nullable(null, _B, null) :- !.
delta_nullable(_A, null, null) :- !.
delta_nullable(A, B, D) :-
    number(A),
    number(B),
    D is B - A.

snapshot_a_campos(
    no_existe,
    null, null, [],
    _{
        modo: "eliminado",
        turnos_carcel: 0,
        dobles_seguidos: 0
     },
    true
) :- !.

snapshot_a_campos(
    existe(Pos, Din, PropIds, Modo, TurnosCarcel, Dobles),
    Pos, Din, PropIds,
    _{
        modo: Modo,
        turnos_carcel: TurnosCarcel,
        dobles_seguidos: Dobles
     },
    false
).

resumen_paso_ui_dict(EstadoIn, EstadoOut, NombreActor, Resultado, Dict) :-
    jugador_snapshot(EstadoIn, NombreActor, SnapIn),
    jugador_snapshot(EstadoOut, NombreActor, SnapOut),

    snapshot_a_campos(SnapIn, PosIn, DinIn, PropsIn, EstadoTurnoIn, EliminadoIn),
    snapshot_a_campos(SnapOut, PosOut, DinOut, PropsOut, EstadoTurnoOut, EliminadoOut),

    subtract(PropsOut, PropsIn, PropsNuevas),
    delta_nullable(DinIn, DinOut, DeltaDinero),

    Dict = _{
        resultado: Resultado,
        actor: NombreActor,
        eliminado_antes: EliminadoIn,
        eliminado_despues: EliminadoOut,
        posicion_inicial: PosIn,
        posicion_final: PosOut,
        dinero_inicial: DinIn,
        dinero_final: DinOut,
        delta_dinero: DeltaDinero,
        propiedades_iniciales: PropsIn,
        propiedades_finales: PropsOut,
        propiedades_nuevas: PropsNuevas,
        estado_turno_inicial: EstadoTurnoIn,
        estado_turno_final: EstadoTurnoOut
    }.

% ============================================================
% DELTA DE METRICAS
% ============================================================

metricas_totales(
    metricas(_IterRev, IterTotal, Compras, Alquileres, Bancarrotas),
    IterTotal, Compras, Alquileres, Bancarrotas
).

metricas_delta_ui_dict(M0, M1,
    _{
        iter_total_delta: DIter,
        compras_delta: DCompras,
        alquileres_delta: DAlquileres,
        bancarrotas_delta: DBancarrotas
     }
) :-
    metricas_totales(M0, I0, C0, A0, B0),
    metricas_totales(M1, I1, C1, A1, B1),
    DIter is I1 - I0,
    DCompras is C1 - C0,
    DAlquileres is A1 - A0,
    DBancarrotas is B1 - B0.

% ============================================================
% PASOS DE TRAZA
% ============================================================

paso_ui_dict(NumPaso, Accion, EstadoAntes, EstadoDespues, Resultado, M0, M1, DictPaso) :-
    actor_accion(Accion, EstadoAntes, NombreActor),
    accion_ui_dict(Accion, AccionDict),
    estado_ui_dict(EstadoAntes, EstadoAntesDict),
    estado_ui_dict(EstadoDespues, EstadoDespuesDict),
    jugador_ui_o_eliminado(EstadoAntes, NombreActor, JugAntesDict),
    jugador_ui_o_eliminado(EstadoDespues, NombreActor, JugDespuesDict),
    resumen_paso_ui_dict(EstadoAntes, EstadoDespues, NombreActor, Resultado, ResumenDict),
    metricas_delta_ui_dict(M0, M1, MetricasDeltaDict),

    DictPaso = _{
        num_paso: NumPaso,
        accion: AccionDict,
        jugador_antes: JugAntesDict,
        jugador_despues: JugDespuesDict,
        resumen: ResumenDict,
        metricas_delta: MetricasDeltaDict,
        estado_antes: EstadoAntesDict,
        estado_despues: EstadoDespuesDict
    }.

simular_acciones_con_traza(EstadoInicial, Acciones, EstadoFinal, Pasos, MetricasFinales) :-
    metricas_init(M0),
    simular_acciones_con_traza_aux(EstadoInicial, Acciones, 1, EstadoFinal, Pasos, M0, MetricasFinales).

simular_acciones_con_traza_aux(Estado, [], _NumPaso, Estado, [], M, M).
simular_acciones_con_traza_aux(EstadoIn, [Accion | Resto], NumPaso,
                               EstadoFinal, [Paso | Pasos], M0, MOut) :-
    ejecutar_accion_ui_metricas(Accion, EstadoIn, EstadoNext, Resultado, M0, M1),
    paso_ui_dict(NumPaso, Accion, EstadoIn, EstadoNext, Resultado, M0, M1, Paso),
    NumPaso1 is NumPaso + 1,
    simular_acciones_con_traza_aux(EstadoNext, Resto, NumPaso1, EstadoFinal, Pasos, M1, MOut).

% ============================================================
% ESTADOS BASE PARA UI
% ============================================================

crear_jugadores_base(I, N, _Dinero, []) :-
    I > N,
    !.
crear_jugadores_base(I, N, Dinero, [jugador(Nombre, 0, Dinero, []) | Resto]) :-
    atom_concat(jugador, I, Nombre),
    I1 is I + 1,
    crear_jugadores_base(I1, N, Dinero, Resto).

estado_base_ui(NumJugadores, DineroInicial,
    estado(Js, Tablero, 0)) :-
    integer(NumJugadores),
    NumJugadores >= 2,
    integer(DineroInicial),
    DineroInicial >= 0,
    tablero_base(Tablero),
    crear_jugadores_base(1, NumJugadores, DineroInicial, Js).

tiradas_a_acciones([], []).
tiradas_a_acciones([T | Ts], [tirar(T) | As]) :-
    tiradas_a_acciones(Ts, As).

% ============================================================
% JSON FINAL
% ============================================================

resultado_traza_ui_json(EstadoInicial, Pasos, EstadoFinal, Metricas, JSONAtom) :-
    EstadoInicial = estado(_Js0, Tablero, _Turno0),
    tablero_ui_dicts(Tablero, TableroDict),
    estado_ui_dict(EstadoInicial, EstadoInicialDict),
    estado_ui_dict(EstadoFinal, EstadoFinalDict),
    metricas_ui_dict(Metricas, MetricasDict),
    length(Pasos, NumPasos),

    Dict = _{
        tablero: TableroDict,
        estado_inicial: EstadoInicialDict,
        pasos: Pasos,
        estado_final: EstadoFinalDict,
        metricas_finales: MetricasDict,
        num_pasos: NumPasos
    },

    atom_json_dict(JSONAtom, Dict, []).

% ============================================================
% API PUBLICA DEL BRIDGE
% ============================================================

listar_escenarios_ui(JSONAtom) :-
    findall(
        _{
            id: Id,
            tema: Tema,
            descripcion: Descripcion
         },
        escenario(Id, Tema, Descripcion),
        Escenarios
    ),
    atom_json_dict(JSONAtom, _{escenarios: Escenarios}, []).

traza_escenario_ui(IdEscenario, JSONAtom) :-
    estado_inicial(IdEscenario, EstadoInicial),
    acciones_escenario(IdEscenario, Acciones),
    simular_acciones_con_traza(EstadoInicial, Acciones, EstadoFinal, Pasos, Metricas),
    resultado_traza_ui_json(EstadoInicial, Pasos, EstadoFinal, Metricas, JSONAtom).

traza_tiradas_base_ui(NumJugadores, DineroInicial, Tiradas, JSONAtom) :-
    estado_base_ui(NumJugadores, DineroInicial, EstadoInicial),
    tiradas_a_acciones(Tiradas, Acciones),
    simular_acciones_con_traza(EstadoInicial, Acciones, EstadoFinal, Pasos, Metricas),
    resultado_traza_ui_json(EstadoInicial, Pasos, EstadoFinal, Metricas, JSONAtom).
