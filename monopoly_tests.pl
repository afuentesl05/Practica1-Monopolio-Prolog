% ============================================================
% monopoly_tests.pl — Batería de tests para main.pl y scenarios.pl
%
% Ejecutar en SWI-Prolog:
% ?- [monopoly_tests].
% ?- run_tests.
% ============================================================

:- [main].
:- [scenarios].
:- begin_tests(monopoly).

% ------------------------------------------------------------
% Helpers de test
% ------------------------------------------------------------

test_estado_turno_libre_cero(Jugador) :-
    jugador_campos(Jugador, _N, _Pos, _Din, _Props, estado_turno(libre, 0)).

% ------------------------------------------------------------
% Compatibilidad de tiradas
% ------------------------------------------------------------

test(valor_tirada_entero) :-
    valor_tirada(7, V),
    assertion(V == 7).

test(valor_tirada_dados) :-
    valor_tirada(tirada(3,4), V),
    assertion(V == 7).

test(es_doble_real) :-
    es_doble(tirada(2,2)).

test(entero_no_es_doble, [fail]) :-
    es_doble(4).

% ------------------------------------------------------------
% Legacy sin dobles
% ------------------------------------------------------------

test(turno_legacy_entero_sigue_compatibilidad_jugador4) :-
    estado_inicial(E0),
    ejecutar_turno(E0, 6, E1),
    E1 = estado(Js, _Tab, 1),
    get_jugador(ana, Js, JugAna),
    assertion(JugAna == jugador(ana, 6, 1400, [celeste1])).

% ------------------------------------------------------------
% Escenarios clásicos
% ------------------------------------------------------------

test(esc1_compras_iniciales_ok) :-
    estado_inicial(esc1, E0),
    tiradas_escenario(esc1, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),
    EFinal = estado(
        [ jugador(ana, 6, 1340, [celeste1, marron1]),
          jugador(bob, 8, 1340, [celeste2, marron2])
        ],
        _Tablero,
        0
    ),
    Metricas = metricas(IterRev, 4, 4, 0, 0),
    reverse(IterRev, Iters),
    assertion(Iters == [1,1,1,1]).

test(esc2_monopolio_marron_ok) :-
    estado_inicial(esc2, E0),
    jugador_activo_monopolios(E0, Colores),
    assertion(Colores == [marron]).

test(esc3_bancarrota_ok) :-
    estado_inicial(esc3, E0),
    tiradas_escenario(esc3, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),
    EFinal = estado(
        [jugador(bob, 0, 1506, [marron1])],
        _Tablero,
        0
    ),
    Metricas = metricas(IterRev, 1, 0, 1, 1),
    reverse(IterRev, Iters),
    assertion(Iters == [1]).

test(esc4_alquileres_consecutivos_ok) :-
    estado_inicial(esc4, E0),
    tiradas_escenario(esc4, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),
    EFinal = estado(
        [ jugador(ana, 6, 1340, [celeste2, marron2]),
          jugador(bob, 8, 1340, [celeste1, marron1])
        ],
        _Tablero,
        0
    ),
    Metricas = metricas(IterRev, 4, 0, 4, 0),
    reverse(IterRev, Iters),
    assertion(Iters == [1,1,1,1]).

test(esc5_simulacion_completa_ok) :-
    estado_inicial(esc5, E0),
    tiradas_escenario(esc5, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),
    EFinal = estado(
        [ jugador(ana, 12, 1318, [celeste1, marron1]),
          jugador(bob, 16, 1062, [naranja1, celeste3, celeste2, marron2])
        ],
        _Tablero,
        0
    ),
    Metricas = metricas(IterRev, 10, 6, 2, 0),
    reverse(IterRev, Iters),
    assertion(Iters == [1,1,1,1,1,1,1,1,1,1]).

% ------------------------------------------------------------
% Dobles y cárcel
% ------------------------------------------------------------

test(esc6_doble_repite_turno_y_guarda_estado) :-
    estado_inicial(esc6, E0),
    tiradas_escenario(esc6, [T]),
    ejecutar_turno(E0, T, E1),
    E1 = estado(Js, _Tab, 0),
    get_jugador(ana, Js, JugAna),
    jugador_campos(JugAna, ana, 6, 1400, [celeste1], estado_turno(libre, 1)),
    get_jugador(bob, Js, JugBob),
    test_estado_turno_libre_cero(JugBob).

test(esc7_tercer_doble_envia_a_carcel) :-
    estado_inicial(esc7, E0),
    ejecutar_turno(E0, tirada(1,1), E1),
    ejecutar_turno(E1, tirada(2,2), E2),
    ejecutar_turno(E2, tirada(3,3), E3),
    E3 = estado(Js, _Tab, 1),
    get_jugador(ana, Js, JugAna),
    jugador_campos(JugAna, ana, 10, 1400, [celeste1], estado_turno(carcel(3), 0)).

test(esc7_metricas_tercer_doble_cuenta_cero_pasadas) :-
    estado_inicial(esc7, E0),
    tiradas_escenario(esc7, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, _EFinal, Metricas),
    Metricas = metricas(IterRev, 2, 1, 0, 0),
    reverse(IterRev, Iters),
    assertion(Iters == [1,1,0]).

% ------------------------------------------------------------
% Ranking
% ------------------------------------------------------------

test(ranking_esc5_ok) :-
    estado_inicial(esc5, E0),
    tiradas_escenario(esc5, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, _Metricas),
    ranking_jugadores(EFinal, Ranking),
    assertion(Ranking == [
        ranking(bob, 1522, 1062, 460, 4),
        ranking(ana, 1478, 1318, 160, 2)
    ]).

:- end_tests(monopoly).
