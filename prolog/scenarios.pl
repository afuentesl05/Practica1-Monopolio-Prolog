% ============================================================
% scenarios.pl - Catalogo de escenarios del proyecto
%
% Contenido:
% - Catalogo de escenarios
% - Estados iniciales por escenario
% - Tiradas o acciones explicitas por escenario
% - Ejecucion generica de acciones reutilizando main.pl
%
% Este archivo reutiliza la logica definida en main.pl.
% No anade reglas nuevas del juego.
% ============================================================

:- ensure_loaded('main.pl').
:- discontiguous estado_inicial/2.
:- discontiguous tiradas_escenario/2.
:- discontiguous acciones_escenario_explicitas/2.
:- discontiguous ejecutar_accion_metricas/5.

% ============================================================
% CATALOGO DE ESCENARIOS
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
escenario(esc15, bancarrota_pago_carcel,         'Pago de salida de carcel provoca bancarrota').

escenario(esc12, hipoteca_basica,                'Hipotecar una propiedad').
escenario(esc13, deshipoteca_basica,             'Hipotecar y deshipotecar una propiedad').
escenario(esc14, alquiler_bloqueado_hipoteca,    'Una propiedad hipotecada no cobra alquiler').
escenario(esc16, patrimonio_hipoteca_estable,    'Hipotecar mantiene el patrimonio').
escenario(esc17, patrimonio_deshipoteca_baja,    'Deshipotecar baja patrimonio por el coste extra').

escenario(esc18, construccion_casa_basica,       'Construccion basica de una casa con monopolio').
escenario(esc19, alquiler_con_una_casa,          'Alquiler aumentado por una casa').
escenario(esc20, alquiler_con_dos_casas,         'Alquiler aumentado por dos casas').
escenario(esc21, patrimonio_casa_estable,        'Construir una casa mantiene el patrimonio total').
escenario(esc22, construccion_sin_monopolio_bloqueada, 'No se puede construir sin monopolio').
escenario(esc23, construccion_sobre_hipotecada_bloqueada, 'No se puede construir sobre propiedad hipotecada').
escenario(esc24, construccion_sin_dinero_bloqueada, 'No se puede construir sin dinero suficiente').
escenario(esc25, construccion_maximo_casas_bloqueada, 'No se puede construir por encima de 4 casas').

% ============================================================
% ESCENARIOS DEL PROYECTO
% ============================================================

% esc1 - compras iniciales
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

% esc2 - monopolio creado durante la partida
% Ana ya posee marron1 y en este turno cae en marron2, la compra
% y completa el monopolio marron.
estado_inicial(esc2,
    estado(
        [ jugador(ana, 0, 1440, [titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc2, [3]).

% esc3 - bancarrota por alquiler
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

% esc4 - alquileres consecutivos y simetricos
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

% esc5 - simulacion completa legacy de 10 turnos
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

% esc6 - doble simple
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

% esc7 - tercer doble a carcel
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

% esc8 - caer en ir_carcel desde el movimiento
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

% esc9 - jugador encarcelado que no sale por no sacar doble
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

% esc10 - jugador encarcelado sale por doble y no repite
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

% esc11 - tercer intento fallido paga 50 y sale
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

% esc12 - hipoteca basica
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

% esc13 - hipoteca y deshipoteca
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

% esc14 - una propiedad hipotecada no cobra alquiler
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

% esc15 - bancarrota al pagar salida de carcel
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

% esc16 - patrimonio estable al hipotecar
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

% esc17 - patrimonio baja al deshipotecar por el coste extra
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

% esc18 - construccion basica de una casa
estado_inicial(esc18,
    estado(
        [ jugador(ana, 0, 1380, [titulo(marron2, no, 0), titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc18, [construir_casa(ana, marron1)]).

% esc19 - alquiler con una casa
estado_inicial(esc19,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1330, [titulo(marron2, no, 0), titulo(marron1, no, 1)])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc19, [1]).

% esc20 - alquiler con dos casas
estado_inicial(esc20,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1280, [titulo(marron2, no, 0), titulo(marron1, no, 2)])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc20, [1]).

% esc21 - patrimonio estable al construir una casa
estado_inicial(esc21,
    estado(
        [ jugador(ana, 0, 1380, [titulo(marron2, no, 0), titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc21, [construir_casa(ana, marron1)]).

% esc22 - intento de construccion sin monopolio
estado_inicial(esc22,
    estado(
        [ jugador(ana, 0, 1440, [titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc22, [intentar_construir_casa(ana, marron1)]).

% esc23 - intento de construccion sobre propiedad hipotecada
estado_inicial(esc23,
    estado(
        [ jugador(ana, 0, 1410, [titulo(marron2, no, 0), titulo(marron1, si, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc23, [intentar_construir_casa(ana, marron1)]).

% esc24 - intento de construccion sin dinero suficiente
estado_inicial(esc24,
    estado(
        [ jugador(ana, 0, 40, [titulo(marron2, no, 0), titulo(marron1, no, 0)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc24, [intentar_construir_casa(ana, marron1)]).

% esc25 - intento de construccion con maximo de casas alcanzado
estado_inicial(esc25,
    estado(
        [ jugador(ana, 0, 1330, [titulo(marron2, no, 0), titulo(marron1, no, 4)]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

acciones_escenario_explicitas(esc25, [intentar_construir_casa(ana, marron1)]).

% ============================================================
% TRADUCCION DE TIRADAS A ACCIONES
% ============================================================

envolver_tirada(T, tirar(T)).

acciones_escenario(IdEscenario, Acciones) :-
    acciones_escenario_explicitas(IdEscenario, Acciones),
    !.
acciones_escenario(IdEscenario, Acciones) :-
    tiradas_escenario(IdEscenario, Tiradas),
    maplist(envolver_tirada, Tiradas, Acciones).

% ============================================================
% EJECUCION GENERICA DE ACCIONES
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

ejecutar_accion_metricas(construir_casa(Nombre, PropId), EstadoIn, EstadoOut, M, M) :-
    construir_casa(EstadoIn, Nombre, PropId, EstadoOut).

ejecutar_accion_metricas(intentar_construir_casa(Nombre, PropId), EstadoIn, EstadoOut, M, M) :-
    (   construir_casa(EstadoIn, Nombre, PropId, EstadoTmp)
    ->  EstadoOut = EstadoTmp
    ;   EstadoOut = EstadoIn
    ).

% ============================================================
% RESOLUCION GENERICA DE ESCENARIOS
% ============================================================

resolver_escenario(IdEscenario, EstadoFinal) :-
    resolver_escenario_metricas(IdEscenario, EstadoFinal, _Metricas).

resolver_escenario_metricas(IdEscenario, EstadoFinal, Metricas) :-
    estado_inicial(IdEscenario, EstadoInicial),
    acciones_escenario(IdEscenario, Acciones),
    metricas_init(M0),
    ejecutar_acciones_metricas(EstadoInicial, Acciones, EstadoFinal, M0, Metricas).