% ============================================================
% tests.pl  —  Batería de pruebas automáticas (plunit, SWI-Prolog)
%
% Ejecutar:
%   ?- [tests].
%   ?- run_tests.
%
% Si todos los tests pasan, significa que:
% - La representación del estado/tablero es coherente.
% - Las utilidades de acceso/actualización funcionan.
% - El movimiento por el tablero (incluido bonus de salida) funciona.
% - El avance de turno y la simulación por listas funcionan.
% - La regla de compra y la regla de alquiler funcionan en escenarios dirigidos.
% - Se mantienen invariantes básicos (posiciones válidas, no duplicados, etc.).
% ============================================================

:- begin_tests(monopolio).

% Carga el código del proyecto (ajusta si tu fichero principal tiene otro nombre).
:- [main].

% ------------------------------------------------------------
% Helpers de pruebas (no forman parte del juego, solo test)
% ------------------------------------------------------------

% Un turno completo aplicando el "pipeline" actual de reglas:
% mover -> compra -> alquiler -> avanzar_turno
% Si los tests end-to-end pasan, significa que la composición de predicados
% funciona correctamente en conjunto.
turno_con_reglas(EstadoIn, Tirada, EstadoOut) :-
    mover(EstadoIn, Tirada, E1, _Paso),
    regla_compra(E1, E2),
    regla_alquiler(E2, E3),
    avanzar_turno(E3, EstadoOut).

% --- Invariantes minimas del modelo (para tests) ---

dinero_no_negativo(jugador(_, _, Din, _)) :- Din >= 0.
pos_valida(jugador(_, Pos, _, _)) :- Pos >= 0, Pos < 40.
props_son_atomicas(jugador(_, _, _, Props)) :- maplist(atom, Props).

% Si esto se cumple, significa que un jugador NO tiene duplicados en su lista de propiedades.
sin_props_duplicadas(jugador(_, _, _, Props)) :-
    sort(Props, PropsUnicas),
    length(Props, L),
    length(PropsUnicas, L).

% Si esto se cumple, significa que una propiedad NO aparece en dos jugadores distintos.
ninguna_prop_repetida_entre_jugadores(Js) :-
    findall(P, (member(jugador(_,_,_,Props), Js), member(P, Props)), Todas),
    sort(Todas, Unicas),
    length(Todas, L),
    length(Unicas, L).

% Si esto se cumple, significa que el estado respeta invariantes básicos:
% - Tablero de 40 casillas
% - Turno en rango
% - Posiciones de jugadores en 0..39
% - Dinero no negativo
% - Propiedades son átomos
% - Sin duplicados por jugador
% - Ninguna propiedad repetida entre jugadores
estado_valido(estado(Js, Tablero, Turno)) :-
    length(Tablero, 40),
    length(Js, N), N > 0,
    Turno >= 0, Turno < N,
    maplist(pos_valida, Js),
    maplist(dinero_no_negativo, Js),
    maplist(props_son_atomicas, Js),
    maplist(sin_props_duplicadas, Js),
    ninguna_prop_repetida_entre_jugadores(Js).

% ============================================================
% ISSUE 3 — TABLERO
% ============================================================

% Si este test pasa, significa que el tablero base tiene exactamente 40 casillas.
test(tablero_longitud_40, [true(L = 40)]) :-
    tablero_base(T),
    length(T, L).

% Si este test pasa, significa que las casillas clave (0,1,39) están donde deben.
test(tablero_casillas_clave, [true((C0,C1,C39) = (salida, propiedad(marron1,60,marron), propiedad(azul2,400,azul)))]) :-
    tablero_base(T),
    nth0(0, T, C0),
    nth0(1, T, C1),
    nth0(39, T, C39).

% ============================================================
% ISSUE 1 — ESTADO INICIAL
% ============================================================

% Si este test pasa, significa que el estado inicial:
% - tiene dos jugadores ana/bob
% - ambos en pos 0 con 1500 y sin propiedades
% - turno inicial = 0
test(estado_inicial_forma, [true((JA,JB,Turno) = (jugador(ana,0,1500,[]), jugador(bob,0,1500,[]), 0))]) :-
    estado_inicial(estado(Js, _Tab, Turno)),
    get_jugador(ana, Js, JA),
    get_jugador(bob, Js, JB).

% ============================================================
% ISSUE 2 — UTILIDADES
% ============================================================

% Si este test pasa, significa que get_jugador/3 recupera correctamente por nombre.
test(get_jugador_recupera, [true(J = jugador(ana,0,1500,[]))]) :-
    estado_inicial(estado(Js, _Tab, _Turno)),
    get_jugador(ana, Js, J).

% Si este test pasa, significa que set_jugador/4 sustituye un jugador en la lista.
test(set_jugador_sustituye, [true(J2 = jugador(ana,0,999,[]))]) :-
    estado_inicial(estado(Js, _Tab, _Turno)),
    set_jugador(ana, Js, jugador(ana,0,999,[]), Js2),
    get_jugador(ana, Js2, J2).

% Si este test pasa, significa que update_pos/3 cambia solo la posición.
test(update_pos_cambia_pos, [true(J2 = jugador(ana,7,1500,[]))]) :-
    update_pos(jugador(ana,0,1500,[]), 7, J2).

% Si este test pasa, significa que update_dinero/3 cambia solo el dinero.
test(update_dinero_cambia_dinero, [true(J2 = jugador(ana,0,1300,[]))]) :-
    update_dinero(jugador(ana,0,1500,[]), 1300, J2).

% Si este test pasa, significa que add_prop/3 añade una propiedad al final de la lista.
test(add_prop_anade, [true(J2 = jugador(ana,0,1500,[marron1]))]) :-
    add_prop(jugador(ana,0,1500,[]), marron1, J2).

% ============================================================
% ISSUE 4 — MOVIMIENTO
% ============================================================

% Si este test pasa, significa que mover/4:
% - mueve al jugador del turno
% - no da bonus si no cruza salida
% - deja Turno igual (mover no cambia turno)
test(mover_basico_sin_salida, [true((Paso,JA,TurnoOut) = (no, jugador(ana,7,1500,[]), 0))]) :-
    estado_inicial(estado(Js, Tab, 0)),
    mover(estado(Js, Tab, 0), 7, estado(Js2, _Tab2, TurnoOut), Paso),
    get_jugador(ana, Js2, JA).

% Si este test pasa, significa que mover/4 aplica correctamente:
% - cruce de salida
% - bonus de 200
% - posición circular con mod 40
test(mover_paso_salida_bonus, [true((Paso,Pos,Din) = (si,1,1700))]) :-
    estado_inicial(estado(Js, Tab, 0)),
    set_jugador(ana, Js, jugador(ana,39,1500,[]), Js2),
    mover(estado(Js2, Tab, 0), 2, estado(Js3, _Tab3, _Turno3), Paso),
    get_jugador(ana, Js3, jugador(ana, Pos, Din, _Props)).

% Si este test pasa, significa que mover/4 falla para tiradas negativas (según tu contrato).
test(mover_falla_tirada_negativa, [fail]) :-
    estado_inicial(E0),
    mover(E0, -1, _E1, _Paso).

% Si este test pasa, significa que mover/4 falla cuando Tirada es variable (por integer/1).
test(mover_falla_tirada_variable, [fail]) :-
    estado_inicial(E0),
    mover(E0, _T, _E1, _Paso).

% ============================================================
% ISSUE 4/5 — TURNOS Y SIMULACIÓN
% ============================================================

% Si este test pasa, significa que avanzar_turno/2 rota el turno correctamente (0->1).
test(avanzar_turno_01, [true(T2 = 1)]) :-
    estado_inicial(estado(Js, Tab, 0)),
    avanzar_turno(estado(Js, Tab, 0), estado(_Js2, _Tab2, T2)).

% Si este test pasa, significa que avanzar_turno/2 es circular (con 2 jugadores):
% desde Turno=1 pasa a Turno=0.
test(avanzar_turno_10, [true(T2 = 0)]) :-
    estado_inicial(estado(Js, Tab, _)),
    avanzar_turno(estado(Js, Tab, 1), estado(_Js2, _Tab2, T2)).

% Si este test pasa, significa que turno_base/3 realiza:
% - mover al jugador activo
% - avanzar turno al final
test(turno_base_mueve_y_avanza, [true((JA,T2) = (jugador(ana,5,1500,[]), 1))]) :-
    estado_inicial(estado(Js, Tab, 0)),
    turno_base(estado(Js, Tab, 0), 5, estado(Js2, _Tab2, T2)),
    get_jugador(ana, Js2, JA).

% Si este test pasa, significa que simular/5:
% - consume exactamente N tiradas
% - devuelve las tiradas restantes correctas
test(simular_consumo_parcial, [true(Rest = [3,4])]) :-
    estado_inicial(E0),
    simular(E0, [1,2,3,4], 2, _E2, Rest).

% Si este test pasa, significa que simular/5:
% - con N=0 no consume tiradas y devuelve el mismo estado
test(simular_n0_no_consumo, [true((EOut,Rest) = (E0,[1,2,3]))]) :-
    estado_inicial(E0),
    simular(E0, [1,2,3], 0, EOut, Rest).

% Si este test pasa, significa que simular/5 falla si no hay suficientes tiradas para N.
test(simular_falla_si_faltan_tiradas, [fail]) :-
    estado_inicial(E0),
    simular(E0, [1], 2, _E2, _Rest).

% Si este test pasa, significa que simular_movimientos/3 (wrapper):
% - consume toda la lista
% - equivale a simular N=length(lista)
test(simular_movimientos_consume_todo, [true(TFinal = 0)]) :-
    estado_inicial(estado(Js, Tab, 0)),
    simular_movimientos(estado(Js, Tab, 0), [1,1], estado(_JsF, _TabF, TFinal)).

% ============================================================
% ISSUE 6 — REGLA 0 (COMPRA)
% ============================================================

% Si este test pasa, significa que regla_compra/2:
% - compra una propiedad libre si el jugador tiene dinero
% - descuenta el precio
% - añade la propiedad a su lista
test(compra_propiedad_libre, [true(JA = jugador(ana,1,1440,[marron1]))]) :-
    estado_inicial(estado(Js, Tab, 0)),
    mover(estado(Js, Tab, 0), 1, E1, _Paso),     % Ana cae en marron1 (precio 60)
    regla_compra(E1, E2),
    E2 = estado(Js2, _Tab2, _Turno2),
    get_jugador(ana, Js2, JA).

% Si este test pasa, significa que regla_compra/2 NO compra si la propiedad ya tiene dueño.
test(compra_no_si_tiene_dueno, [true(JB = jugador(bob,1,1500,[]))]) :-
    % 1) Ana compra marron1
    estado_inicial(E0),
    mover(E0, 1, E1, _Paso1),
    regla_compra(E1, E2),
    % 2) Pasamos turno a Bob y lo movemos a marron1
    avanzar_turno(E2, E3),
    mover(E3, 1, E4, _Paso2),
    regla_compra(E4, E5),
    E5 = estado(Js5, _Tab5, _Turno5),
    get_jugador(bob, Js5, JB).

% ============================================================
% ISSUE 7 — REGLA 1 (ALQUILER)
% ============================================================

% Si este test pasa, significa que alquiler_casilla/2 calcula correctamente Precio//10.
test(alquiler_casilla_calculo, [true(A = 6)]) :-
    alquiler_casilla(propiedad(marron1, 60, marron), A).

% Si este test pasa, significa que propietario_de/4 encuentra correctamente al dueño de una propiedad.
test(propietario_de_encuentra, [true(NombreProp = ana)]) :-
    estado_inicial(estado(Js, _Tab, _Turno)),
    set_jugador(ana, Js, jugador(ana,0,1500,[marron1]), Js2),
    propietario_de(marron1, Js2, NombreProp, _JugProp).

% Si este test pasa, significa que regla_alquiler/2:
% - resta alquiler al jugador activo (pagador)
% - suma alquiler al propietario
% - no hay auto-pago
test(alquiler_transferencia_dinero, [true((JA,JB) = (
        jugador(ana,1,1446,[marron1]),
        jugador(bob,1,1494,[])
    ))]) :-
    % Preparación: Ana compra marron1 y queda en pos 1
    estado_inicial(estado(Js, Tab, 0)),
    mover(estado(Js, Tab, 0), 1, E1, _Paso1),
    regla_compra(E1, E2),

    % Cambiamos turno a Bob y lo movemos a pos 1
    avanzar_turno(E2, E3),
    mover(E3, 1, E4, _Paso2),

    % Aplicamos alquiler
    regla_alquiler(E4, E5),
    E5 = estado(Js5, _Tab5, _Turno5),
    get_jugador(ana, Js5, JA),
    get_jugador(bob, Js5, JB).

% Si este test pasa, significa que regla_alquiler/2 NO aplica si el jugador cae en su propia propiedad.
test(alquiler_no_autopago, [true(JA = jugador(ana,1,1440,[marron1]))]) :-
    estado_inicial(estado(Js, Tab, 0)),
    mover(estado(Js, Tab, 0), 1, E1, _Paso1),
    regla_compra(E1, E2),
    % Ana sigue en turno 0, está en su propiedad; aplicar alquiler no deberia cambiar nada
    regla_alquiler(E2, E3),
    E3 = estado(Js3, _Tab3, _Turno3),
    get_jugador(ana, Js3, JA).

% ============================================================
% END-TO-END + INVARIANTES
% ============================================================

% Si este test pasa, significa que el sistema completo (turno_con_reglas/3):
% - permite compra en el turno de Ana
% - permite alquiler en el turno de Bob
% - avanza turnos correctamente
% - produce exactamente el estado esperado tras 3 turnos dirigidos
test(end_to_end_compra_y_alquiler, [true((JA,JB,TurnoF) = (
        jugador(ana, 2, 1446, [marron1]),
        jugador(bob, 1, 1494, []),
        1
    ))]) :-
    estado_inicial(E0),
    turno_con_reglas(E0, 1, E1),
    turno_con_reglas(E1, 1, E2),
    turno_con_reglas(E2, 1, E3),
    E3 = estado(JsF, _Tab, TurnoF),
    get_jugador(ana, JsF, JA),
    get_jugador(bob, JsF, JB).

% Si este test pasa, significa que tras el escenario end-to-end:
% el estado respeta invariantes básicos (posiciones, dinero, duplicados, etc.).
test(invariantes_end_to_end, [true]) :-
    estado_inicial(E0),
    turno_con_reglas(E0, 1, E1),
    turno_con_reglas(E1, 1, E2),
    turno_con_reglas(E2, 1, E3),
    estado_valido(E3).

:- end_tests(monopolio).