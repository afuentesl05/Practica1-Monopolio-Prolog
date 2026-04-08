:- begin_tests(monopoly).

:- ensure_loaded('../main.pl').
:- ensure_loaded('../scenarios.pl').

% ============================================================
% HELPERS DE TEST
% ============================================================

jugador_por_nombre(estado(Js, _Tab, _Turno), Nombre, Jugador) :-
    get_jugador(Nombre, Js, Jugador).

jugador_resumen(Estado, Nombre, Pos, Din, Props, Libertad, Dobles) :-
    jugador_por_nombre(Estado, Nombre, Jugador),
    jugador_campos(Jugador, Nombre, Pos, Din, Props, estado_turno(Libertad, Dobles)).

jugador_props_ids(Estado, Nombre, PropIds) :-
    jugador_por_nombre(Estado, Nombre, Jugador),
    jugador_campos(Jugador, _Nombre, _Pos, _Din, Props, _EstadoTurno),
    props_ids(Props, PropIds).

num_jugadores(estado(Js, _Tab, _Turno), N) :-
    length(Js, N).

turno_actual(estado(_Js, _Tab, Turno), Turno).

metricas_resumen(metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas, _Monopolios),
                 IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas) :-
    reverse(IterRev, IterPorTurno).

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
% ESCENARIOS BASE / COMPATIBILIDAD
% ============================================================

test(esc1_compras_iniciales) :-
    resolver_escenario_metricas(esc1, EFinal, _Metricas),

    turno_actual(EFinal, 0),

    jugador_resumen(EFinal, ana, 6, 1340, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 8, 1340, _PropsBob, libre, 0),

    jugador_props_ids(EFinal, ana, PropsAnaIds),
    jugador_props_ids(EFinal, bob, PropsBobIds),

    assertion(PropsAnaIds == [celeste1, marron1]),
    assertion(PropsBobIds == [celeste2, marron2]).

test(esc2_monopolio_marron_formado) :-
    estado_inicial(esc2, E0),
    E0 = estado(_Js, Tablero, _Turno),
    resolver_escenario_metricas(esc2, EFinal, _Metricas),
    jugador_por_nombre(EFinal, ana, JugAna),
    colores_monopolio_jugador(JugAna, Tablero, Colores),
    assertion(Colores == [marron]).

test(esc3_bancarrota_por_alquiler) :-
    resolver_escenario_metricas(esc3, EFinal, _Metricas),

    num_jugadores(EFinal, 1),
    turno_actual(EFinal, 0),

    jugador_resumen(EFinal, bob, 0, 1506, _PropsBob, libre, 0),
    jugador_props_ids(EFinal, bob, PropsBobIds),
    assertion(PropsBobIds == [marron1]).

test(esc4_alquileres_consecutivos) :-
    resolver_escenario_metricas(esc4, EFinal, _Metricas),

    turno_actual(EFinal, 0),

    jugador_resumen(EFinal, ana, 6, 1340, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 8, 1340, _PropsBob, libre, 0),

    jugador_props_ids(EFinal, ana, PropsAnaIds),
    jugador_props_ids(EFinal, bob, PropsBobIds),

    assertion(PropsAnaIds == [celeste2, marron2]),
    assertion(PropsBobIds == [celeste1, marron1]).

test(esc5_estado_final_y_metricas) :-
    resolver_escenario_metricas(esc5, EFinal, Metricas),

    turno_actual(EFinal, 0),

    jugador_resumen(EFinal, ana, 12, 1318, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 16, 1062, _PropsBob, libre, 0),

    jugador_props_ids(EFinal, ana, PropsAnaIds),
    jugador_props_ids(EFinal, bob, PropsBobIds),

    assertion(PropsAnaIds == [celeste1, marron1]),
    assertion(PropsBobIds == [naranja1, celeste3, celeste2, marron2]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1,1,1,1,1,1,1,1,1,1]),
    assertion(IterTotal =:= 10),
    assertion(Compras =:= 6),
    assertion(Alquileres =:= 2),
    assertion(Bancarrotas =:= 0).

test(esc5_ranking_final) :-
    resolver_escenario_metricas(esc5, EFinal, _Metricas),
    ranking_jugadores(EFinal, Ranking),
    assertion(Ranking == [
        ranking(bob, 1522, 1062, 460, 4),
        ranking(ana, 1478, 1318, 160, 2)
    ]).

% ============================================================
% DOBLES Y CÁRCEL
% ============================================================

test(esc6_doble_simple_repite_turno) :-
    resolver_escenario_metricas(esc6, EFinal, Metricas),

    turno_actual(EFinal, 0),
    jugador_resumen(EFinal, ana, 6, 1400, _PropsAna, libre, 1),
    jugador_resumen(EFinal, bob, 0, 1500, _PropsBob, libre, 0),
    jugador_props_ids(EFinal, ana, PropsAnaIds),
    jugador_props_ids(EFinal, bob, PropsBobIds),

    assertion(PropsAnaIds == [celeste1]),
    assertion(PropsBobIds == []),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1]),
    assertion(IterTotal =:= 1),
    assertion(Compras =:= 1),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc7_tercer_doble_manda_a_carcel) :-
    resolver_escenario_metricas(esc7, EFinal, Metricas),

    turno_actual(EFinal, 1),

    jugador_resumen(EFinal, ana, 10, 1400, _PropsAna, carcel(3), 0),
    jugador_resumen(EFinal, bob, 0, 1500, _PropsBob, libre, 0),

    jugador_props_ids(EFinal, ana, PropsAnaIds),
    jugador_props_ids(EFinal, bob, PropsBobIds),

    assertion(PropsAnaIds == [celeste1]),
    assertion(PropsBobIds == []),

    metricas_resumen(Metricas, IterPorTurno, _IterTotal, _Compras, _Alquileres, _Bancarrotas),
    assertion(IterPorTurno == [1,1,0]).

test(esc8_caer_en_ir_carcel_envia_a_carcel) :-
    resolver_escenario_metricas(esc8, EFinal, Metricas),

    turno_actual(EFinal, 1),

    jugador_resumen(EFinal, ana, 10, 1500, _PropsAna, carcel(3), 0),
    jugador_resumen(EFinal, bob, 0, 1500, _PropsBob, libre, 0),

    jugador_props_ids(EFinal, ana, PropsAnaIds),
    jugador_props_ids(EFinal, bob, PropsBobIds),

    assertion(PropsAnaIds == []),
    assertion(PropsBobIds == []),

    metricas_resumen(Metricas, IterPorTurno, _IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1]),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc9_encarcelado_no_doble_no_sale) :-
    resolver_escenario_metricas(esc9, EFinal, Metricas),

    turno_actual(EFinal, 1),

    jugador_resumen(EFinal, ana, 10, 1500, _PropsAna, carcel(2), 0),
    jugador_resumen(EFinal, bob, 0, 1500, _PropsBob, libre, 0),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [0]),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc10_encarcelado_sale_por_doble_y_no_repite_turno) :-
    resolver_escenario_metricas(esc10, EFinal, Metricas),

    turno_actual(EFinal, 1),

    jugador_resumen(EFinal, ana, 12, 1500, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1500, _PropsBob, libre, 0),

    jugador_props_ids(EFinal, ana, PropsAnaIds),
    assertion(PropsAnaIds == []),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1]),
    assertion(IterTotal =:= 1),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc11_encarcelado_paga_y_sale) :-
    resolver_escenario_metricas(esc11, EFinal, Metricas),

    turno_actual(EFinal, 1),

    jugador_resumen(EFinal, ana, 15, 1450, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1500, _PropsBob, libre, 0),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1]),
    assertion(IterTotal =:= 1),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc15_pago_salida_activa_bancarrota) :-
    resolver_escenario_metricas(esc15, EFinal, Metricas),

    num_jugadores(EFinal, 1),
    turno_actual(EFinal, 0),

    jugador_resumen(EFinal, bob, 0, 1500, _PropsBob, libre, 0),
    jugador_props_ids(EFinal, bob, PropsBobIds),
    assertion(PropsBobIds == []),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [2]),
    assertion(IterTotal =:= 2),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 1).

% ============================================================
% HIPOTECAS
% ============================================================

test(esc12_hipoteca_basica) :-
    resolver_escenario_metricas(esc12, EFinal, Metricas),

    turno_actual(EFinal, 0),
    jugador_resumen(EFinal, ana, 1, 1470, PropsAna, libre, 0),
    jugador_props_ids(EFinal, ana, PropsAnaIds),

    assertion(PropsAnaIds == [marron1]),
    assertion(PropsAna == [titulo(marron1, si, 0)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == []),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc13_deshipoteca_basica) :-
    resolver_escenario_metricas(esc13, EFinal, Metricas),

    turno_actual(EFinal, 0),
    jugador_resumen(EFinal, ana, 1, 1437, PropsAna, libre, 0),
    jugador_props_ids(EFinal, ana, PropsAnaIds),

    assertion(PropsAnaIds == [marron1]),
    assertion(PropsAna == [titulo(marron1, no, 0)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == []),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc14_alquiler_bloqueado_por_hipoteca) :-
    resolver_escenario_metricas(esc14, EFinal, Metricas),

    turno_actual(EFinal, 1),

    jugador_resumen(EFinal, ana, 1, 1500, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1500, PropsBob, libre, 0),
    assertion(PropsBob == [titulo(marron1, si, 0)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1]),
    assertion(IterTotal =:= 1),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc16_hipotecar_mantiene_patrimonio) :-
    estado_inicial(esc16, E0),
    E0 = estado([JugAna0 | _], Tablero, _),
    patrimonio_jugador(JugAna0, Tablero, PatrimonioInicial),

    resolver_escenario_metricas(esc16, EFinal, _Metricas),
    jugador_por_nombre(EFinal, ana, JugAnaF),
    patrimonio_jugador(JugAnaF, Tablero, PatrimonioFinal),

    assertion(PatrimonioInicial =:= 1500),
    assertion(PatrimonioFinal =:= 1500).

test(esc17_deshipotecar_baja_patrimonio) :-
    resolver_escenario_metricas(esc17, EFinal, _Metricas),
    EFinal = estado(_Js, Tablero, _Turno),
    jugador_por_nombre(EFinal, ana, JugAnaF),
    patrimonio_jugador(JugAnaF, Tablero, PatrimonioFinal),

    jugador_resumen(EFinal, ana, 1, 1437, PropsAna, libre, 0),
    assertion(PropsAna == [titulo(marron1, no, 0)]),
    assertion(PatrimonioFinal =:= 1497).

test(esc17_ranking_tras_deshipoteca) :-
    resolver_escenario_metricas(esc17, EFinal, _Metricas),
    ranking_jugadores(EFinal, Ranking),
    assertion(Ranking == [
        ranking(bob, 1500, 1500, 0, 0),
        ranking(ana, 1497, 1437, 60, 1)
    ]).

% ============================================================
% CASAS
% ============================================================

test(esc18_construccion_casa_basica) :-
    once(resolver_escenario_metricas(esc18, EFinal, Metricas)),

    turno_actual(EFinal, 0),
    jugador_resumen(EFinal, ana, 0, 1330, PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1500, PropsBob, libre, 0),

    assertion(PropsAna == [titulo(marron2, no, 0), titulo(marron1, no, 1)]),
    assertion(PropsBob == []),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == []),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc19_alquiler_con_una_casa) :-
    resolver_escenario_metricas(esc19, EFinal, Metricas),

    turno_actual(EFinal, 1),
    jugador_resumen(EFinal, ana, 1, 1470, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1360, PropsBob, libre, 0),

    assertion(PropsBob == [titulo(marron2, no, 0), titulo(marron1, no, 1)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1]),
    assertion(IterTotal =:= 1),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 1),
    assertion(Bancarrotas =:= 0).

test(esc20_alquiler_con_dos_casas) :-
    resolver_escenario_metricas(esc20, EFinal, Metricas),

    turno_actual(EFinal, 1),
    jugador_resumen(EFinal, ana, 1, 1410, _PropsAna, libre, 0),
    jugador_resumen(EFinal, bob, 0, 1370, PropsBob, libre, 0),

    assertion(PropsBob == [titulo(marron2, no, 0), titulo(marron1, no, 2)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == [1]),
    assertion(IterTotal =:= 1),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 1),
    assertion(Bancarrotas =:= 0).

test(esc21_construir_casa_mantiene_patrimonio) :-
    once(estado_inicial(esc21, E0)),
    E0 = estado([JugAna0, JugBob0], Tablero, _),
    patrimonio_jugador(JugAna0, Tablero, PatrimonioAna0),
    patrimonio_jugador(JugBob0, Tablero, PatrimonioBob0),

    once(resolver_escenario_metricas(esc21, EFinal, _Metricas)),
    EFinal = estado(JsF, _, _),
    get_jugador(ana, JsF, JugAnaF),
    get_jugador(bob, JsF, JugBobF),

    patrimonio_jugador(JugAnaF, Tablero, PatrimonioAnaF),
    patrimonio_jugador(JugBobF, Tablero, PatrimonioBobF),

    assertion(PatrimonioAna0 =:= 1500),
    assertion(PatrimonioAnaF =:= 1500),
    assertion(PatrimonioBob0 =:= 1500),
    assertion(PatrimonioBobF =:= 1500).

test(esc21_ranking_tras_construir_casa) :-
    once(resolver_escenario_metricas(esc21, EFinal, _Metricas)),
    ranking_jugadores(EFinal, Ranking),
    assertion(Ranking == [
        ranking(bob, 1500, 1500, 0, 0),
        ranking(ana, 1500, 1330, 170, 2)
    ]).

test(esc22_no_construye_sin_monopolio) :-
    estado_inicial(esc22, E0),
    resolver_escenario_metricas(esc22, EFinal, Metricas),

    assertion(EFinal == E0),

    jugador_resumen(EFinal, ana, 0, 1440, PropsAna, libre, 0),
    assertion(PropsAna == [titulo(marron1, no, 0)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == []),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc23_no_construye_sobre_propiedad_hipotecada) :-
    estado_inicial(esc23, E0),
    resolver_escenario_metricas(esc23, EFinal, Metricas),

    assertion(EFinal == E0),

    jugador_resumen(EFinal, ana, 0, 1410, PropsAna, libre, 0),
    assertion(PropsAna == [titulo(marron2, no, 0), titulo(marron1, si, 0)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == []),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc24_no_construye_sin_dinero) :-
    estado_inicial(esc24, E0),
    resolver_escenario_metricas(esc24, EFinal, Metricas),

    assertion(EFinal == E0),

    jugador_resumen(EFinal, ana, 0, 40, PropsAna, libre, 0),
    assertion(PropsAna == [titulo(marron2, no, 0), titulo(marron1, no, 0)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == []),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

test(esc25_no_construye_mas_de_cuatro_casas) :-
    estado_inicial(esc25, E0),
    resolver_escenario_metricas(esc25, EFinal, Metricas),

    assertion(EFinal == E0),

    jugador_resumen(EFinal, ana, 0, 1330, PropsAna, libre, 0),
    assertion(PropsAna == [titulo(marron2, no, 0), titulo(marron1, no, 4)]),

    metricas_resumen(Metricas, IterPorTurno, IterTotal, Compras, Alquileres, Bancarrotas),
    assertion(IterPorTurno == []),
    assertion(IterTotal =:= 0),
    assertion(Compras =:= 0),
    assertion(Alquileres =:= 0),
    assertion(Bancarrotas =:= 0).

:- end_tests(monopoly).


