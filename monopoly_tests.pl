:- begin_tests(monopoly).

:- [main].
:- [scenarios].

% ============================================================
% HELPERS DE TEST
% ============================================================

jugador_por_nombre(estado(Js, _Tab, _Turno), Nombre, Jugador) :-
    get_jugador(Nombre, Js, Jugador).

jugador_resumen(Estado, Nombre, Pos, Din, Props, Libertad, Dobles) :-
    jugador_por_nombre(Estado, Nombre, Jugador),
    jugador_campos(Jugador, Nombre, Pos, Din, Props, estado_turno(Libertad, Dobles)).

num_jugadores(estado(Js, _Tab, _Turno), N) :-
    length(Js, N).

turno_actual(estado(_Js, _Tab, Turno), Turno).

% ============================================================
% TESTS BÁSICOS DE TIRADAS
% ============================================================

test(valor_tirada_entero) :-
    valor_tirada(7, V),
    assertion(V =:= 7).

test(valor_tirada_dos_dados) :-
    valor_tirada(tirada(3,4), V),
    assertion(V =:= 7).

test(es_doble_true) :-
    es_doble(tirada(2,2)).

test(es_doble_false_entero, [fail]) :-
    es_doble(4).

test(es_doble_false_no_iguales, [fail]) :-
    es_doble(tirada(2,3)).

% ============================================================
% COMPATIBILIDAD LEGACY / ESCENARIOS ANTERIORES
% ============================================================

test(esc1_compras_iniciales) :-
    estado_inicial(esc1, E0),
    tiradas_escenario(esc1, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, _Metricas),

    turno_actual(EFinal, Turno),
    assertion(Turno =:= 0),

    jugador_resumen(EFinal, ana, 6, 1340, PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 8, 1340, PropsBob, libre, 0),

    msort(PropsAna, PropsAnaOrd),
    msort(PropsBob, PropsBobOrd),

    assertion(PropsAnaOrd == [celeste1,marron1]),
    assertion(PropsBobOrd == [celeste2,marron2]).

test(esc3_bancarrota_por_alquiler) :-
    estado_inicial(esc3, E0),
    tiradas_escenario(esc3, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, _Metricas),

    num_jugadores(EFinal, N),
    assertion(N =:= 1),
    turno_actual(EFinal, Turno),
    assertion(Turno =:= 0),

    jugador_resumen(EFinal, bob, 0, 1506, PropsBob, libre, 0),
    assertion(PropsBob == [marron1]).

test(esc4_alquileres_consecutivos) :-
    estado_inicial(esc4, E0),
    tiradas_escenario(esc4, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, _Metricas),

    turno_actual(EFinal, Turno),
    assertion(Turno =:= 0),

    jugador_resumen(EFinal, ana, 6, 1340, PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 8, 1340, PropsBob, libre, 0),

    msort(PropsAna, PropsAnaOrd),
    msort(PropsBob, PropsBobOrd),

    assertion(PropsAnaOrd == [celeste2,marron2]),
    assertion(PropsBobOrd == [celeste1,marron1]).

test(esc5_estado_final_y_metricas) :-
    estado_inicial(esc5, E0),
    tiradas_escenario(esc5, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),

    turno_actual(EFinal, Turno),
    assertion(Turno =:= 0),

    jugador_resumen(EFinal, ana, 12, 1318, PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 16, 1062, PropsBob, libre, 0),

    assertion(PropsAna == [celeste1, marron1]),
    assertion(PropsBob == [naranja1, celeste3, celeste2, marron2]),

    Metricas = metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas),
    reverse(IterRev, IterPorTurno),

    assertion(IterTotal =:= 10),
    assertion(Compras =:= 6),
    assertion(Alquileres =:= 2),
    assertion(Bancarrotas =:= 0),
    assertion(IterPorTurno == [1,1,1,1,1,1,1,1,1,1]).

test(esc5_ranking_final) :-
    estado_inicial(esc5, E0),
    tiradas_escenario(esc5, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, _Metricas),

    ranking_jugadores(EFinal, Ranking),
    assertion(Ranking == [
        ranking(bob, 1522, 1062, 460, 4),
        ranking(ana, 1478, 1318, 160, 2)
    ]).

% ============================================================
% DOBLES
% ============================================================

test(doble_simple_repite_turno) :-
    estado_inicial(E0),
    ejecutar_turno(E0, tirada(1,1), E1),

    turno_actual(E1, Turno),
    assertion(Turno =:= 0),

    jugador_resumen(E1, ana, 2, 1500, PropsAna, libre, DoblesAna),
    jugador_resumen(E1, bob, 0, 1500, PropsBob, libre, 0),

    assertion(PropsAna == []),
    assertion(PropsBob == []),
    assertion(DoblesAna =:= 1).

test(tercer_doble_manda_a_carcel) :-
    estado_inicial(E0),
    ejecutar_turno(E0, tirada(1,1), E1),
    ejecutar_turno(E1, tirada(2,2), E2),
    ejecutar_turno(E2, tirada(3,3), E3),

    turno_actual(E3, Turno),
    assertion(Turno =:= 1),

    jugador_resumen(E3, ana, 10, 1500, PropsAna, carcel(3), 0),
    jugador_resumen(E3, bob, 0, 1500, PropsBob, libre, 0),

    assertion(PropsAna == []),
    assertion(PropsBob == []).

test(tercer_doble_metricas_turno_cero_iteraciones) :-
    metricas_init(M0),
    estado_inicial(E0),
    turno_con_reglas_metricas(E0, tirada(1,1), M0, E1, M1),
    turno_con_reglas_metricas(E1, tirada(2,2), M1, E2, M2),
    turno_con_reglas_metricas(E2, tirada(3,3), M2, _E3, M3),

    M3 = metricas(IterRev, _IterTotal, _Compras, _Alquileres, _Bancarrotas),
    reverse(IterRev, IterPorTurno),
    assertion(IterPorTurno == [1,1,0]).

% ============================================================
% CÁRCEL POR CASILLA
% ============================================================

test(caer_en_ir_carcel_envia_a_carcel) :-
    estado_inicial(estado(Js, Tab, 0)),
    set_jugador(ana, Js, jugador(ana, 30, 1500, []), Js2),
    E0 = estado(Js2, Tab, 0),

    ejecutar_turno(E0, 0, EFinal),

    turno_actual(EFinal, Turno),
    assertion(Turno =:= 1),

    jugador_resumen(EFinal, ana, 10, 1500, PropsAna, carcel(3), 0),
    jugador_resumen(EFinal, bob, 0, 1500, PropsBob, libre, 0),

    assertion(PropsAna == []),
    assertion(PropsBob == []).

% ============================================================
% TURNOS EN CÁRCEL
% ============================================================

test(encarcelado_no_doble_no_sale) :-
    tablero_base(Tab),
    E0 = estado(
            [ jugador(ana, 10, 1500, [], estado_turno(carcel(3),0)),
              jugador(bob, 0, 1500, [])
            ],
            Tab,
            0
         ),

    ejecutar_turno(E0, tirada(2,3), EFinal),

    turno_actual(EFinal, Turno),
    assertion(Turno =:= 1),

    jugador_resumen(EFinal, ana, 10, 1500, PropsAna, carcel(2), 0),
    jugador_resumen(EFinal, bob, 0, 1500, PropsBob, libre, 0),

    assertion(PropsAna == []),
    assertion(PropsBob == []).

test(encarcelado_sale_por_doble_y_no_repite_turno) :-
    tablero_base(Tab),
    E0 = estado(
            [ jugador(ana, 10, 1500, [], estado_turno(carcel(3),0)),
              jugador(bob, 0, 1500, [])
            ],
            Tab,
            0
         ),

    ejecutar_turno(E0, tirada(1,1), EFinal),

    turno_actual(EFinal, Turno),
    assertion(Turno =:= 1),

    jugador_resumen(EFinal, ana, 12, 1500, PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1500, PropsBob, libre, 0),

    assertion(PropsAna == []),
    assertion(PropsBob == []).

test(encarcelado_tercer_intento_fallido_paga_y_sale) :-
    tablero_base(Tab),
    E0 = estado(
            [ jugador(ana, 10, 1500, [], estado_turno(carcel(1),0)),
              jugador(bob, 0, 1500, [])
            ],
            Tab,
            0
         ),

    ejecutar_turno(E0, tirada(2,3), EFinal),

    turno_actual(EFinal, Turno),
    assertion(Turno =:= 1),

    jugador_resumen(EFinal, ana, 15, 1450, PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1500, PropsBob, libre, 0),

    assertion(PropsAna == []),
    assertion(PropsBob == []).

test(encarcelado_pago_salida_activa_bancarrota) :-
    tablero_base(Tab),
    E0 = estado(
            [ jugador(ana, 10, 40, [], estado_turno(carcel(1),0)),
              jugador(bob, 0, 1500, [])
            ],
            Tab,
            0
         ),

    ejecutar_turno(E0, tirada(2,3), EFinal),

    num_jugadores(EFinal, N),
    assertion(N =:= 1),
    turno_actual(EFinal, Turno),
    assertion(Turno =:= 0),

    jugador_resumen(EFinal, bob, 0, 1500, PropsBob, libre, 0),
    assertion(PropsBob == []).

test(encarcelado_no_doble_metricas_turno_cero_iteraciones) :-
    tablero_base(Tab),
    E0 = estado(
            [ jugador(ana, 10, 1500, [], estado_turno(carcel(3),0)),
              jugador(bob, 0, 1500, [])
            ],
            Tab,
            0
         ),
    metricas_init(M0),

    turno_con_reglas_metricas(E0, tirada(2,3), M0, _EFinal, M1),
    M1 = metricas(IterRev, _IterTotal, _Compras, _Alquileres, _Bancarrotas),
    reverse(IterRev, IterPorTurno),

    assertion(IterPorTurno == [0]).

:- end_tests(monopoly).