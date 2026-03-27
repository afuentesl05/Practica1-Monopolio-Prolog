% ============================================================
% scenarios.pl — Escenarios reproducibles y utilidades de inspección
%
% Contenido:
% - Escenarios del proyecto
% - Impresión formateada del estado
% - Visualización de monopolios, ranking, patrimonio y métricas
% - Ejecución genérica de escenarios basados en tiradas o acciones
% - Validaciones manuales útiles para defensa del proyecto
%
% Este archivo reutiliza la lógica definida en main.pl.ñ
% No añade reglas nuevas del juego.
% ============================================================

:- [main].
:- discontiguous estado_inicial/2.
:- discontiguous tiradas_escenario/2.
:- discontiguous acciones_escenario_explicitas/2.

% ============================================================
% IMPRESIÓN FORMATEADA
% ============================================================

mostrar_estado(estado(Jugadores, _Tablero, Turno)) :-
    writeln('Jugadores:'),
    mostrar_jugadores(Jugadores),
    nl,
    write('Turno: '), writeln(Turno).

mostrar_jugadores([]).
mostrar_jugadores([Jugador | Resto]) :-
    mostrar_jugador(Jugador),
    mostrar_jugadores(Resto).

mostrar_jugador(Jugador) :-
    jugador_campos(Jugador, Nombre, Pos, Din, Props, EstadoTurno),
    write('  - jugador('),
    write(Nombre), write(', '),
    write(Pos), write(', '),
    write(Din), write(', '),
    write(Props),
    (   Jugador = jugador(_, _, _, _)
    ->  writeln(')')
    ;   write(', '),
        write(EstadoTurno),
        writeln(')')
    ).

mostrar_tablero(estado(_Jugadores, Tablero, _Turno)) :-
    writeln('Tablero:'),
    mostrar_tablero_aux(Tablero, 0).

mostrar_tablero_aux([], _).
mostrar_tablero_aux([Casilla | Resto], Indice) :-
    write('  ['), write(Indice), write('] '),
    writeln(Casilla),
    Indice1 is Indice + 1,
    mostrar_tablero_aux(Resto, Indice1).

mostrar_monopolios(estado(Js, Tablero, _Turno)) :-
    writeln('Monopolios detectados:'),
    mostrar_monopolios_jugadores(Js, Tablero).

mostrar_monopolios_jugadores([], _).
mostrar_monopolios_jugadores([Jugador | Resto], Tablero) :-
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno),
    colores_monopolio_jugador(Jugador, Tablero, Colores),
    write('  '), write(Nombre), write(' -> '), writeln(Colores),
    mostrar_monopolios_jugadores(Resto, Tablero).

mostrar_ranking(Estado) :-
    ranking_jugadores(Estado, Ranking),
    writeln('Ranking dinamico:'),
    mostrar_ranking_lista(Ranking, 1).

mostrar_ranking_lista([], _).
mostrar_ranking_lista(
    [ranking(Nombre, Patrimonio, Dinero, ValorProps, NumProps) | Resto],
    Pos
) :-
    write('  '), write(Pos), write('. '),
    write(Nombre),
    write(' -> patrimonio='), write(Patrimonio),
    write(' | dinero='), write(Dinero),
    write(' | valor_props='), write(ValorProps),
    write(' | num_props='), writeln(NumProps),
    Pos1 is Pos + 1,
    mostrar_ranking_lista(Resto, Pos1).

mostrar_patrimonios(estado(Js, Tablero, _Turno)) :-
    writeln('Patrimonios:'),
    mostrar_patrimonios_jugadores(Js, Tablero).

mostrar_patrimonios_jugadores([], _).
mostrar_patrimonios_jugadores([Jugador | Resto], Tablero) :-
    jugador_campos(Jugador, Nombre, _Pos, Din, Props, _EstadoTurno),
    valor_propiedades(Props, Tablero, ValorProps),
    patrimonio_jugador(Jugador, Tablero, Patrimonio),
    write('  '), write(Nombre),
    write(' -> patrimonio='), write(Patrimonio),
    write(' | dinero='), write(Din),
    write(' | valor_props='), writeln(ValorProps),
    mostrar_patrimonios_jugadores(Resto, Tablero).

mostrar_metricas(metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas)) :-
    reverse(IterRev, IterPorTurno),
    writeln('Metricas:'),
    write('  Iteraciones por turno: '), writeln(IterPorTurno),
    write('  Iteraciones totales: '), writeln(IterTotal),
    write('  Compras: '), writeln(Compras),
    write('  Alquileres: '), writeln(Alquileres),
    write('  Bancarrotas/eliminaciones: '), writeln(Bancarrotas).

mostrar_cabecera(Titulo) :-
    writeln('================================'),
    writeln(Titulo),
    writeln('================================').

mostrar_acciones([]).
mostrar_acciones([Accion | Resto]) :-
    write('  - '), writeln(Accion),
    mostrar_acciones(Resto).

% ============================================================
% HELPERS DE INSPECCIÓN
% ============================================================

resumen_jugadores(estado(Js, _, _), Js).
resumen_turno(estado(_, _, Turno), Turno).

resumen_jugador(Estado, Nombre, Pos, Din, Props, Libertad, Dobles) :-
    Estado = estado(Js, _Tab, _Turno),
    get_jugador(Nombre, Js, Jugador),
    jugador_campos(Jugador, Nombre, Pos, Din, Props, estado_turno(Libertad, Dobles)).

% ============================================================
% CATÁLOGO DE ESCENARIOS
% ============================================================

escenario(esc1,  compras_iniciales,              'Compras iniciales y compatibilidad legacy').
escenario(esc2,  monopolio_formado,              'Deteccion de monopolio con propiedades enriquecidas').
escenario(esc3,  bancarrota_alquiler,            'Bancarrota por alquiler').
escenario(esc4,  alquileres_consecutivos,        'Alquileres consecutivos y simetricos').
escenario(esc5,  simulacion_completa,            'Simulacion legacy de 10 turnos').
escenario(esc6,  dobles,                         'Doble simple que repite turno').
escenario(esc7,  dobles_carcel,                  'Tercer doble consecutivo manda a carcel').
escenario(esc8,  carcel_por_casilla,             'Caer en ir_carcel manda a carcel').
escenario(esc9,  carcel_sin_doble,               'Jugador encarcelado que no sale').
escenario(esc10, carcel_sale_por_doble,          'Jugador encarcelado sale por doble y no repite').
escenario(esc11, carcel_pago_salida,             'Tercer intento fallido paga 50 y sale').
escenario(esc12, hipoteca_basica,                'Hipotecar una propiedad').
escenario(esc13, deshipoteca_basica,             'Hipotecar y deshipotecar una propiedad').
escenario(esc14, alquiler_bloqueado_hipoteca,    'Una propiedad hipotecada no cobra alquiler').
escenario(esc15, bancarrota_pago_carcel,         'Pago de salida de carcel provoca bancarrota').
escenario(esc16, patrimonio_hipoteca_estable,    'Hipotecar mantiene el patrimonio').
escenario(esc17, patrimonio_deshipoteca_baja,    'Deshipotecar baja patrimonio por el 10 por ciento').

listar_escenarios :-
    mostrar_cabecera('ESCENARIOS DISPONIBLES'), nl,
    forall(escenario(Id, Tema, Descripcion),
           ( write('  - '), write(Id),
             write(' ['), write(Tema), write('] -> '),
             writeln(Descripcion)
           )),
    writeln('================================').

% ============================================================
% ESCENARIOS DEL PROYECTO
% ============================================================

% esc1 — compras iniciales
estado_inicial(esc1,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc1, [1,3,5,5]).

% esc2 — monopolio formado con propiedades enriquecidas
estado_inicial(esc2,
    estado(
        [ jugador(ana, 0, 1380, [titulo(marron2, no, 0), titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc2, [1]).

% esc3 — bancarrota por alquiler
estado_inicial(esc3,
    estado(
        [ jugador(ana, 0, 5, []),
          jugador(bob, 0, 1500, [marron1])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc3, [1]).

% esc4 — alquileres consecutivos y simetricos
estado_inicial(esc4,
    estado(
        [ jugador(ana, 0, 1340, [titulo(celeste2, no, 0), marron2]),
          jugador(bob, 0, 1340, [titulo(celeste1, no, 0), marron1])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc4, [1,3,5,5]).

% esc5 — simulacion completa legacy de 10 turnos
estado_inicial(esc5,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc5, [1,3,5,5,2,1,1,3,3,4]).

% esc6 — doble simple
estado_inicial(esc6,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc6, [tirada(3,3)]).

% esc7 — tercer doble a carcel
estado_inicial(esc7,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc7, [tirada(1,1), tirada(2,2), tirada(3,3)]).

% esc8 — caer en ir_carcel desde el movimiento
estado_inicial(esc8,
    estado(
        [ jugador(ana, 27, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc8, [3]).

% esc9 — jugador encarcelado que no sale por no sacar doble
estado_inicial(esc9,
    estado(
        [ jugador(ana, 10, 1500, [], estado_turno(carcel(3), 0)),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc9, [tirada(2,3)]).

% esc10 — jugador encarcelado sale por doble y no repite
estado_inicial(esc10,
    estado(
        [ jugador(ana, 10, 1500, [], estado_turno(carcel(3), 0)),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc10, [tirada(1,1)]).

% esc11 — tercer intento fallido paga 50 y sale
estado_inicial(esc11,
    estado(
        [ jugador(ana, 10, 1500, [], estado_turno(carcel(1), 0)),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc11, [tirada(2,3)]).

% esc12 — hipoteca básica
estado_inicial(esc12,
    estado(
        [ jugador(ana, 1, 1440, [titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc12, [hipotecar(ana, marron1)]).

% esc13 — hipoteca y deshipoteca
estado_inicial(esc13,
    estado(
        [ jugador(ana, 1, 1440, [titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc13, [hipotecar(ana, marron1), deshipotecar(ana, marron1)]).

% esc14 — una propiedad hipotecada no cobra alquiler
estado_inicial(esc14,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [titulo(marron1, si, 0)])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc14, [1]).

% esc15 — bancarrota al pagar salida de carcel
estado_inicial(esc15,
    estado(
        [ jugador(ana, 10, 40, [], estado_turno(carcel(1), 0)),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc15, [tirada(2,3)]).

% esc16 — patrimonio estable al hipotecar
estado_inicial(esc16,
    estado(
        [ jugador(ana, 1, 1440, [titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc16, [hipotecar(ana, marron1)]).

% esc17 — patrimonio baja al deshipotecar por el coste extra
estado_inicial(esc17,
    estado(
        [ jugador(ana, 1, 1440, [titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc17, [hipotecar(ana, marron1), deshipotecar(ana, marron1)]).

% ============================================================
% ACCIONES DE ESCENARIO
% ============================================================

envolver_tirada(T, tirar(T)).

acciones_escenario(IdEscenario, Acciones) :-
    acciones_escenario_explicitas(IdEscenario, Acciones), !.
acciones_escenario(IdEscenario, Acciones) :-
    tiradas_escenario(IdEscenario, Tiradas),
    maplist(envolver_tirada, Tiradas, Acciones).

accion_turno(tirar(Tirada)).

% ============================================================
% EJECUCIÓN GENÉRICA DE ACCIONES
% ============================================================

ejecutar_acciones_metricas(Estado, [], Estado, M, M) :- !.
ejecutar_acciones_metricas(EstadoIn, [Accion | Resto], EstadoOut, M0, MOut) :-
    ejecutar_accion_metricas(Accion, EstadoIn, EstadoNext, M0, M1),
    ejecutar_acciones_metricas(EstadoNext, Resto, EstadoOut, M1, MOut).

ejecutar_accion_metricas(tirar(Tirada), EstadoIn, EstadoOut, M0, MOut) :-
    turno_con_reglas_metricas(EstadoIn, Tirada, M0, EstadoOut, MOut).
ejecutar_accion_metricas(hipotecar(Nombre, PropId), EstadoIn, EstadoOut, M, M) :-
    hipotecar_propiedad(EstadoIn, Nombre, PropId, EstadoOut).
ejecutar_accion_metricas(deshipotecar(Nombre, PropId), EstadoIn, EstadoOut, M, M) :-
    deshipotecar_propiedad(EstadoIn, Nombre, PropId, EstadoOut).

% ============================================================
% EJECUCIÓN GENERAL DE ESCENARIOS
% ============================================================

resolver_escenario(IdEscenario, EstadoFinal) :-
    resolver_escenario_metricas(IdEscenario, EstadoFinal, _Metricas).

resolver_escenario_metricas(IdEscenario, EstadoFinal, Metricas) :-
    estado_inicial(IdEscenario, EstadoInicial),
    acciones_escenario(IdEscenario, Acciones),
    metricas_init(M0),
    ejecutar_acciones_metricas(EstadoInicial, Acciones, EstadoFinal, M0, Metricas).

ejecutar_escenario(IdEscenario, EstadoFinal) :-
    ejecutar_escenario_metricas(IdEscenario, EstadoFinal, _Metricas).

ejecutar_escenario_metricas(IdEscenario, EstadoFinal, Metricas) :-
    estado_inicial(IdEscenario, EstadoInicial),
    acciones_escenario(IdEscenario, Acciones),
    resolver_escenario_metricas(IdEscenario, EstadoFinal, Metricas),

    atomic_list_concat(['ESCENARIO: ', IdEscenario], Titulo),
    mostrar_cabecera(Titulo), nl,

    writeln('ESTADO INICIAL'),
    writeln('--------------------------------'),
    mostrar_estado(EstadoInicial), nl,

    writeln('MONOPOLIOS INICIALES'),
    writeln('--------------------------------'),
    mostrar_monopolios(EstadoInicial), nl,

    writeln('PATRIMONIOS INICIALES'),
    writeln('--------------------------------'),
    mostrar_patrimonios(EstadoInicial), nl,

    writeln('ACCIONES DEL ESCENARIO'),
    writeln('--------------------------------'),
    mostrar_acciones(Acciones), nl,

    writeln('ESTADO FINAL'),
    writeln('--------------------------------'),
    mostrar_estado(EstadoFinal), nl,

    writeln('MONOPOLIOS FINALES'),
    writeln('--------------------------------'),
    mostrar_monopolios(EstadoFinal), nl,

    writeln('PATRIMONIOS FINALES'),
    writeln('--------------------------------'),
    mostrar_patrimonios(EstadoFinal), nl,

    writeln('RANKING FINAL'),
    writeln('--------------------------------'),
    mostrar_ranking(EstadoFinal), nl,

    writeln('METRICAS'),
    writeln('--------------------------------'),
    mostrar_metricas(Metricas), nl,

    writeln('================================').


ejecutar_todos_escenarios :-
    forall(escenario(Id, _Tema, _Descripcion),
           ( ejecutar_escenario(Id, _), nl )).

% ============================================================
% VALIDACIONES MANUALES RÁPIDAS
% ============================================================

validar_mover_basico :-
    estado_inicial(E0),
    mostrar_cabecera('VALIDACION: mover/4 basico'), nl,

    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,

    mover(E0, 7, E1, Paso),

    writeln('Tras mover con tirada 7:'),
    mostrar_estado(E1),
    write('Paso por salida: '), writeln(Paso),
    writeln('================================').

validar_turno_base :-
    estado_inicial(E0),
    mostrar_cabecera('VALIDACION: turno_base/3'), nl,

    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,

    turno_base(E0, 7, E1),

    writeln('Tras turno_base con tirada 7:'),
    mostrar_estado(E1),
    writeln('================================').

validar_modulo_y_salida :-
    estado_inicial(estado(Js, Tab, 0)),
    set_jugador(ana, Js, jugador(ana, 39, 1500, []), Js2),
    E0 = estado(Js2, Tab, 0),

    mostrar_cabecera('VALIDACION: modulo 40 + bonus salida'), nl,

    writeln('Estado inicial modificado:'),
    mostrar_estado(E0), nl,

    mover(E0, 2, E1, Paso),

    writeln('Tras mover con tirada 2:'),
    mostrar_estado(E1),
    write('Paso por salida: '), writeln(Paso),
    writeln('================================').

validar_doble_simple :-
    ejecutar_escenario(esc6, _).

validar_tercer_doble_carcel :-
    ejecutar_escenario(esc7, _).

validar_carcel_por_casilla :-
    ejecutar_escenario(esc8, _).

validar_carcel_sin_doble :-
    ejecutar_escenario(esc9, _).

validar_carcel_sale_por_doble :-
    ejecutar_escenario(esc10, _).

validar_carcel_pago_salida :-
    ejecutar_escenario(esc11, _).

validar_hipoteca_basica :-
    ejecutar_escenario(esc12, _).

validar_deshipoteca_basica :-
    ejecutar_escenario(esc13, _).

validar_alquiler_bloqueado_hipoteca :-
    ejecutar_escenario(esc14, EstadoFinal),
    mostrar_cabecera('RESUMEN: alquiler bloqueado por hipoteca'), nl,
    resumen_jugador(EstadoFinal, ana, _PosA, DinA, _PropsA, _LibA, _DobA),
    resumen_jugador(EstadoFinal, bob, _PosB, DinB, _PropsB, _LibB, _DobB),
    write('Dinero final de Ana (esperado 1500): '), writeln(DinA),
    write('Dinero final de Bob (esperado 1500): '), writeln(DinB),
    writeln('================================').

validar_bancarrota_pago_carcel :-
    ejecutar_escenario(esc15, _).

validar_patrimonio_hipoteca_estable :-
    estado_inicial(esc16, E0),
    resolver_escenario(esc16, E1),
    E0 = estado(Js0, Tab, _),
    E1 = estado(Js1, _, _),
    get_jugador(ana, Js0, J0),
    get_jugador(ana, Js1, J1),
    patrimonio_jugador(J0, Tab, P0),
    patrimonio_jugador(J1, Tab, P1),
    Dif is P1 - P0,
    mostrar_cabecera('VALIDACION: patrimonio estable al hipotecar'), nl,
    write('Patrimonio antes: '), writeln(P0),
    write('Patrimonio despues: '), writeln(P1),
    write('Diferencia observada: '), writeln(Dif),
    writeln('Esperado: 0'),
    writeln('================================').

validar_patrimonio_deshipoteca_baja :-
    estado_inicial(esc17, E0),
    resolver_escenario(esc17, E1),
    E0 = estado(Js0, Tab, _),
    E1 = estado(Js1, _, _),
    get_jugador(ana, Js0, J0),
    get_jugador(ana, Js1, J1),
    patrimonio_jugador(J0, Tab, P0),
    patrimonio_jugador(J1, Tab, P1),
    Dif is P0 - P1,
    mostrar_cabecera('VALIDACION: patrimonio baja al deshipotecar'), nl,
    write('Patrimonio antes: '), writeln(P0),
    write('Patrimonio despues: '), writeln(P1),
    write('Diferencia observada: '), writeln(Dif),
    writeln('Esperado: 3'),
    writeln('================================').

% Alias útiles para defensa en vivo

defensa_base :-
    ejecutar_escenario(esc1, _),
    ejecutar_escenario(esc4, _),
    ejecutar_escenario(esc5, _).

defensa_dobles_y_carcel :-
    ejecutar_escenario(esc6, _),
    ejecutar_escenario(esc7, _),
    ejecutar_escenario(esc8, _),
    ejecutar_escenario(esc10, _),
    ejecutar_escenario(esc11, _).

defensa_hipotecas :-
    ejecutar_escenario(esc12, _),
    ejecutar_escenario(esc13, _),
    ejecutar_escenario(esc14, _),
    validar_patrimonio_hipoteca_estable,
    validar_patrimonio_deshipoteca_baja.

