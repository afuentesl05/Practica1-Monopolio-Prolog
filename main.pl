% =====================================
% ISSUE 1 – REPRESENTACIÓN DEL ESTADO
% =====================================

/*
Representación formal del estado global del juego.

Un estado del juego se modela como:

    estado(Jugadores, Tablero, Turno)

Donde:

- Jugadores es una lista de estructuras jugador/4:
      jugador(Nombre, Posicion, Dinero, Propiedades)

    * Nombre: átomo identificador del jugador.
    * Posicion: entero que representa el índice de la casilla en el tablero.
    * Dinero: entero que representa el saldo actual.
    * Propiedades: lista de identificadores de propiedades (átomos).

- Tablero es una lista lineal de casillas.
  Cada casilla será un término (por ejemplo: salida, carta,
  impuesto(Cantidad), propiedad(Id, Precio, Color), etc.).

- Turno representa el jugador activo.
  Se modela como índice entero sobre la lista Jugadores,
  lo que facilita el cálculo del siguiente turno mediante aritmética modular.
*/

/*
Estructuras base del modelo:
- estado(Jugadores, Tablero, Turno).
- jugador(Nombre, Posicion, Dinero, Propiedades).
*/

% Estado inicial mínimo para pruebas
estado_inicial(
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).


% =====================================
% PREPARACIÓN PARA DOBLES + CÁRCEL
% =====================================

/*
Compatibilidad progresiva de jugador/4 -> jugador/5.

Nuevo objetivo:
- jugador(Nombre, Pos, Dinero, Props, EstadoTurno)

Pero, para no romper el proyecto actual:
- seguimos aceptando jugador/4
- si un jugador aún no tiene EstadoTurno explícito, se asume:
    estado_turno(libre, 0)

EstadoTurno:
- estado_turno(Libertad, DoblesSeguidos)
- Libertad = libre ; carcel(TurnosRestantes)
*/

estado_turno_inicial(estado_turno(libre, 0)).

%% jugador_campos(+Jugador, -Nombre, -Pos, -Din, -Props, -EstadoTurno)
%  Extrae campos tanto de jugador/4 como de jugador/5.
jugador_campos(jugador(N, Pos, Din, Props), N, Pos, Din, Props, EstadoTurno) :-
    estado_turno_inicial(EstadoTurno).
jugador_campos(jugador(N, Pos, Din, Props, EstadoTurno), N, Pos, Din, Props, EstadoTurno).

%% jugador_reconstruir_como(+Original, +Nombre, +Pos, +Din, +Props, +EstadoTurno, -Nuevo)
%  Reconstruye conservando la "forma" del original:
%  - si Original era jugador/4, devuelve jugador/4
%  - si Original era jugador/5, devuelve jugador/5
jugador_reconstruir_como(Original, N, Pos, Din, Props, EstadoTurno, Nuevo) :-
    (   Original = jugador(_, _, _, _)
    ->  Nuevo = jugador(N, Pos, Din, Props)
    ;   Nuevo = jugador(N, Pos, Din, Props, EstadoTurno)
    ).

%% update_estado_turno(+Jugador, +NuevoEstadoTurno, -JugadorActualizado)
%  Este sí fuerza la versión jugador/5, porque jugador/4 no puede almacenar estado de turno.
update_estado_turno(Jugador, NuevoEstadoTurno,
                    jugador(N, Pos, Din, Props, NuevoEstadoTurno)) :-
    jugador_campos(Jugador, N, Pos, Din, Props, _).

%% jugador_en_carcel(+Jugador, -TurnosRestantes)
jugador_en_carcel(Jugador, TurnosRestantes) :-
    jugador_campos(Jugador, _N, _Pos, _Din, _Props,
                   estado_turno(carcel(TurnosRestantes), _Dobles)).

%% dobles_seguidos_jugador(+Jugador, -Dobles)
dobles_seguidos_jugador(Jugador, Dobles) :-
    jugador_campos(Jugador, _N, _Pos, _Din, _Props,
                   estado_turno(_Libertad, Dobles)).

%% update_dobles_seguidos(+Jugador, +NuevoDobles, -JugadorActualizado)
update_dobles_seguidos(Jugador, NuevoDobles, Jugador2) :-
    jugador_campos(Jugador, _N, _Pos, _Din, _Props,
                   estado_turno(Libertad, _Dobles)),
    update_estado_turno(Jugador, estado_turno(Libertad, NuevoDobles), Jugador2).

%% poner_en_carcel(+Jugador, +TurnosRestantes, -JugadorActualizado)
poner_en_carcel(Jugador, TurnosRestantes, Jugador2) :-
    update_estado_turno(Jugador, estado_turno(carcel(TurnosRestantes), 0), Jugador2).

%% liberar_jugador(+Jugador, -JugadorActualizado)
liberar_jugador(Jugador, Jugador2) :-
    update_estado_turno(Jugador, estado_turno(libre, 0), Jugador2).


% =====================================
% SOPORTE DE TIRADAS REALES
% =====================================

/*
Compatibilidad:
- entero        -> avance total legacy
- tirada(D1,D2) -> tirada real de dos dados

Importante:
- es_doble/1 SOLO reconoce tirada/2.
- Un entero NO se considera doble, para no romper escenarios antiguos.
*/

valor_tirada(Tirada, Tirada) :-
    integer(Tirada),
    Tirada >= 0,
    !.
valor_tirada(tirada(D1, D2), Valor) :-
    integer(D1), D1 >= 0,
    integer(D2), D2 >= 0,
    Valor is D1 + D2.

es_doble(tirada(D, D)) :-
    integer(D),
    D >= 0.

posicion_carcel(10).

/*
  set_dobles_seguidos_compatible(+Jugador, +NuevoDobles, -Jugador2)

  Compatibilidad progresiva:
  - si el resultado es estado inicial libre+0, colapsa a jugador/4
  - si hay estado relevante (dobles>0 o cárcel), usa jugador/5
*/
set_dobles_seguidos_compatible(Jugador, NuevoDobles, Jugador2) :-
    jugador_campos(Jugador, N, Pos, Din, Props, estado_turno(Libertad, _)),
    (   Libertad = libre,
        NuevoDobles =:= 0
    ->  Jugador2 = jugador(N, Pos, Din, Props)
    ;   Jugador2 = jugador(N, Pos, Din, Props,
                           estado_turno(Libertad, NuevoDobles))
    ).

actualizar_dobles_activo_compatible(
    estado(Js, Tablero, Turno),
    NuevoDobles,
    estado(Js2, Tablero, Turno)
) :-
    nth0(Turno, Js, Jugador),
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno),
    set_dobles_seguidos_compatible(Jugador, NuevoDobles, Jugador2),
    set_jugador(Nombre, Js, Jugador2, Js2).

enviar_activo_a_carcel(
    estado(Js, Tablero, Turno),
    TurnosRestantes,
    estado(Js2, Tablero, Turno)
) :-
    nth0(Turno, Js, Jugador),
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno),
    posicion_carcel(PosCarcel),
    update_pos(Jugador, PosCarcel, J1),
    poner_en_carcel(J1, TurnosRestantes, J2),
    set_jugador(Nombre, Js, J2, Js2).

/*
  cerrar_turno(+EstadoReglas, +NombreActivo, +RepiteTurno, -EstadoOut)

  - Si no quedan jugadores, no avanza.
  - Si hay doble y el jugador activo sigue vivo, repite turno.
  - En otro caso, avanza.
*/
cerrar_turno(EstadoReglas, _NombreActivo, _RepiteTurno, EstadoReglas) :-
    EstadoReglas = estado([], _Tab, _Turno),
    !.
cerrar_turno(EstadoReglas, NombreActivo, si, EstadoReglas) :-
    EstadoReglas = estado(Js, _Tab, _Turno),
    get_jugador(NombreActivo, Js, _),
    !.
cerrar_turno(EstadoReglas, _NombreActivo, _RepiteTurno, EstadoOut) :-
    avanzar_turno(EstadoReglas, EstadoOut).


% =====================================
% ISSUE 2 – UTILIDADES DE ACTUALIZACIÓN
% =====================================

/*
Capa funcional de acceso/actualización.

- get_jugador/3: extrae el jugador por Nombre.
- set_jugador/4: sustituye el jugador por Nombre, devolviendo nueva lista.
- update_pos/3, update_dinero/3, add_prop/3: transformaciones puras.

Diseño para evitar choicepoints:
- Predicados deterministas bajo el invariante "Nombre único".
- Cortes (!) tras encontrar el objetivo en la lista.
*/

get_jugador(Nombre, [Jugador | _], Jugador) :-
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno), !.
get_jugador(Nombre, [_ | Resto], Jugador) :-
    get_jugador(Nombre, Resto, Jugador).

set_jugador(Nombre, [Jugador | Resto],
            JugadorNuevo, [JugadorNuevo | Resto]) :-
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno), !.
set_jugador(Nombre, [J | Resto], JugadorNuevo, [J | RestoNuevo]) :-
    set_jugador(Nombre, Resto, JugadorNuevo, RestoNuevo).

update_pos(Jugador, NuevaPos, JugadorActualizado) :-
    jugador_campos(Jugador, N, _Pos, Din, Props, EstadoTurno),
    jugador_reconstruir_como(Jugador, N, NuevaPos, Din, Props, EstadoTurno, JugadorActualizado).

update_dinero(Jugador, NuevoDinero, JugadorActualizado) :-
    jugador_campos(Jugador, N, Pos, _Din, Props, EstadoTurno),
    jugador_reconstruir_como(Jugador, N, Pos, NuevoDinero, Props, EstadoTurno, JugadorActualizado).

add_prop(Jugador, PropId, JugadorActualizado) :-
    jugador_campos(Jugador, N, Pos, Din, Props, EstadoTurno),
    jugador_reconstruir_como(Jugador, N, Pos, Din, [PropId | Props], EstadoTurno, JugadorActualizado).


% =====================================
% ISSUE 3 – TABLERO BASE (40 CASILLAS)
% =====================================

/*
Representación homogénea de casillas:
- salida
- propiedad(Id, Precio, Color)
- impuesto(Monto)
- carta
- especial(Tipo)
*/

tablero_base([
    salida,                                % 0
    propiedad(marron1,   60, marron),      % 1
    carta,                                 % 2
    propiedad(marron2,   60, marron),      % 3
    impuesto(200),                         % 4
    especial(estacion1),                   % 5
    propiedad(celeste1, 100, celeste),     % 6
    carta,                                 % 7
    propiedad(celeste2, 100, celeste),     % 8
    propiedad(celeste3, 120, celeste),     % 9

    especial(carcel_visita),               % 10
    propiedad(rosa1,    140, rosa),        % 11
    especial(servicio1),                   % 12
    propiedad(rosa2,    140, rosa),        % 13
    propiedad(rosa3,    160, rosa),        % 14
    especial(estacion2),                   % 15
    propiedad(naranja1, 180, naranja),     % 16
    carta,                                 % 17
    propiedad(naranja2, 180, naranja),     % 18
    propiedad(naranja3, 200, naranja),     % 19

    especial(parking),                     % 20
    propiedad(rojo1,    220, rojo),        % 21
    carta,                                 % 22
    propiedad(rojo2,    220, rojo),        % 23
    propiedad(rojo3,    240, rojo),        % 24
    especial(estacion3),                   % 25
    propiedad(amarillo1,260, amarillo),    % 26
    propiedad(amarillo2,260, amarillo),    % 27
    especial(servicio2),                   % 28
    propiedad(amarillo3,280, amarillo),    % 29

    especial(ir_carcel),                   % 30
    propiedad(verde1,   300, verde),       % 31
    propiedad(verde2,   300, verde),       % 32
    carta,                                 % 33
    propiedad(verde3,   320, verde),       % 34
    especial(estacion4),                   % 35
    carta,                                 % 36
    propiedad(azul1,    350, azul),        % 37
    impuesto(100),                         % 38
    propiedad(azul2,    400, azul)         % 39
]).


% =====================================
% ISSUE 4 – MOVIMIENTO SOBRE EL TABLERO
% =====================================

bonus_salida(200).

/*
  mover(+EstadoIn, +Tirada, -EstadoOut, -PasoSalida)
  Aplica la Tirada al jugador activo (según Turno).
*/
mover(estado(Js, Tablero, Turno), TiradaRaw,
      estado(Js2, Tablero, Turno), PasoSalida) :-
    valor_tirada(TiradaRaw, Tirada),
    length(Tablero, 40),
    nth0(Turno, Js, Jugador),
    jugador_campos(Jugador, Nombre, Pos, Din, _Props, _EstadoTurno),

    Suma is Pos + Tirada,
    (   Suma >= 40
    ->  PasoSalida = si,
        bonus_salida(B),
        Din2 is Din + B
    ;   PasoSalida = no,
        Din2 is Din
    ),

    NuevaPos is Suma mod 40,
    update_pos(Jugador, NuevaPos, Jtmp),
    update_dinero(Jtmp, Din2, Jugador2),

    set_jugador(Nombre, Js, Jugador2, Js2).

avanzar_turno(estado(Js, Tablero, Turno),
              estado(Js, Tablero, Turno2)) :-
    length(Js, N),
    N > 0,
    Turno2 is (Turno + 1) mod N.


% =====================================
% ISSUE 5 – ITERACIÓN POR TURNOS
% =====================================

turno_base(EstadoIn, Tirada, EstadoOut) :-
    mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
    avanzar_turno(EstadoMov, EstadoOut).

simular(Estado, Tiradas, 0, Estado, Tiradas) :- !.
simular(EstadoIn, [T|Ts], N, EstadoOut, TiradasRestantes) :-
    integer(N),
    N > 0,
    turno_base(EstadoIn, T, EstadoNext),
    N1 is N - 1,
    simular(EstadoNext, Ts, N1, EstadoOut, TiradasRestantes).

simular_movimientos(EstadoIn, ListaTiradas, EstadoOut) :-
    length(ListaTiradas, N),
    simular(EstadoIn, ListaTiradas, N, EstadoOut, []).


% =====================================
% HELPERS Compra y Alquiler
% =====================================

propietario_de(PropId, [Jugador | _], Nombre, Jugador) :-
    jugador_campos(Jugador, Nombre, _Pos, _Din, Props, _EstadoTurno),
    memberchk(PropId, Props), !.
propietario_de(PropId, [_ | Resto], NombreProp, JugadorProp) :-
    propietario_de(PropId, Resto, NombreProp, JugadorProp).

propiedad_sin_dueno(PropId, Jugadores) :-
    \+ propietario_de(PropId, Jugadores, _Nombre, _Jugador).

casilla_actual(estado(Js, Tablero, Turno), Casilla) :-
    nth0(Turno, Js, Jugador),
    jugador_campos(Jugador, _Nombre, Pos, _Din, _Props, _EstadoTurno),
    nth0(Pos, Tablero, Casilla).


% =====================================
% ISSUE 6 – REGLA 0 (COMPRA DE PROPIEDAD)
% =====================================

jugador_activo(estado(Js, _Tablero, Turno), Jugador) :-
    nth0(Turno, Js, Jugador).

regla_compra(EstadoIn, EstadoOut) :-
    EstadoIn = estado(Js, Tablero, Turno),
    jugador_activo(EstadoIn, Jugador),
    jugador_campos(Jugador, Nombre, _Pos, Din, _Props, _EstadoTurno),
    casilla_actual(EstadoIn, Casilla),

    (   Casilla = propiedad(PropId, Precio, _),
        propiedad_sin_dueno(PropId, Js),
        Din >= Precio
    ->  Din2 is Din - Precio,
        update_dinero(Jugador, Din2, Jtmp),
        add_prop(Jtmp, PropId, Jugador2),
        set_jugador(Nombre, Js, Jugador2, Js2),
        EstadoOut = estado(Js2, Tablero, Turno)
    ;   EstadoOut = EstadoIn
    ),
    !.


% =====================================
% ISSUE 7 – REGLA 1 (ALQUILER)
% =====================================

alquiler_casilla(propiedad(_PropId, Precio, _), Alquiler) :-
    Alquiler is Precio // 10.

regla_alquiler(EstadoIn, EstadoOut) :-
    EstadoIn = estado(Js, Tablero, Turno),
    jugador_activo(EstadoIn, JugActual),
    jugador_campos(JugActual, NombreAct, _PosAct, DinAct, _PropsAct, _EstadoTurnoAct),
    casilla_actual(EstadoIn, Casilla),

    (   Casilla = propiedad(PropId, _Precio, _),
        propietario_de(PropId, Js, NombreProp, JugProp),
        NombreProp \= NombreAct,
        alquiler_casilla(Casilla, Alq)
    ->  DinAct2 is DinAct - Alq,
        update_dinero(JugActual, DinAct2, JugAct2),
        set_jugador(NombreAct, Js, JugAct2, JsTmp),

        jugador_campos(JugProp, NombreProp, _PosP, DinP, _PropsP, _EstadoTurnoProp),
        DinP2 is DinP + Alq,
        update_dinero(JugProp, DinP2, JugProp2),
        set_jugador(NombreProp, JsTmp, JugProp2, Js2),

        EstadoOut = estado(Js2, Tablero, Turno)
    ;   EstadoOut = EstadoIn
    ),
    !.


% =====================================
% ISSUE 10 – REGLA 2 (MONOPOLIO)
% =====================================

propiedades_color([], _Color, []).
propiedades_color([propiedad(PropId, _Precio, Color) | Resto], Color, [PropId | PropsColor]) :-
    !,
    propiedades_color(Resto, Color, PropsColor).
propiedades_color([_ | Resto], Color, PropsColor) :-
    propiedades_color(Resto, Color, PropsColor).

colores_tablero(Tablero, ColoresUnicos) :-
    findall(Color,
            member(propiedad(_, _, Color), Tablero),
            ColoresDup),
    sort(ColoresDup, ColoresUnicos).

tiene_todas([], _).
tiene_todas([X | Xs], Lista) :-
    memberchk(X, Lista),
    tiene_todas(Xs, Lista).

monopolio_color(Jugador, Tablero, Color) :-
    jugador_campos(Jugador, _Nombre, _Pos, _Din, Props, _EstadoTurno),
    colores_tablero(Tablero, Colores),
    member(Color, Colores),
    propiedades_color(Tablero, Color, PropsColor),
    PropsColor \= [],
    tiene_todas(PropsColor, Props).

colores_monopolio_jugador(Jugador, Tablero, Colores) :-
    findall(Color,
            monopolio_color(Jugador, Tablero, Color),
            ColoresDup),
    sort(ColoresDup, Colores).

jugador_activo_monopolios(estado(Js, Tablero, Turno), Colores) :-
    nth0(Turno, Js, Jugador),
    colores_monopolio_jugador(Jugador, Tablero, Colores).

regla_monopolio(Estado, Estado).


% =====================================
% ISSUE 11 – REGLA 3 (BANCARROTA)
% =====================================

jugador_en_bancarrota(Jugador) :-
    jugador_campos(Jugador, _Nombre, _Pos, Dinero, _Props, _EstadoTurno),
    Dinero < 0.

primer_bancarrota([Jugador | _], 0, Jugador) :-
    jugador_en_bancarrota(Jugador), !.
primer_bancarrota([_ | Resto], Indice, Jugador) :-
    primer_bancarrota(Resto, IndiceResto, Jugador),
    Indice is IndiceResto + 1.

remove_nth0(0, [X | Xs], X, Xs) :- !.
remove_nth0(N, [X | Xs], Elem, [X | Ys]) :-
    N > 0,
    N1 is N - 1,
    remove_nth0(N1, Xs, Elem, Ys).

ajustar_turno_tras_eliminacion(_TurnoActual, _IndiceEliminado, 0, 0) :- !.
ajustar_turno_tras_eliminacion(TurnoActual, IndiceEliminado, NumRestantes, TurnoNuevo) :-
    (   IndiceEliminado < TurnoActual
    ->  TurnoTemp is TurnoActual - 1
    ;   IndiceEliminado =:= TurnoActual
    ->  TurnoTemp is TurnoActual mod NumRestantes
    ;   TurnoTemp is TurnoActual
    ),
    TurnoNuevo is TurnoTemp mod NumRestantes.

eliminar_jugador_por_indice(
    estado(Js, Tablero, Turno),
    IndiceEliminado,
    estado(Js2, Tablero, Turno2),
    JugadorEliminado
) :-
    remove_nth0(IndiceEliminado, Js, JugadorEliminado, Js2),
    length(Js2, NumRestantes),
    ajustar_turno_tras_eliminacion(Turno, IndiceEliminado, NumRestantes, Turno2).

aplicar_bancarrota_una_pasada(EstadoIn, EstadoOut) :-
    EstadoIn = estado(Js, _Tablero, _Turno),
    (   primer_bancarrota(Js, Indice, _Jugador)
    ->  eliminar_jugador_por_indice(EstadoIn, Indice, EstadoOut, _Eliminado)
    ;   EstadoOut = EstadoIn
    ).

regla_bancarrota(EstadoIn, EstadoOut) :-
    regla_bancarrota_aux(EstadoIn, EstadoOut),
    !.

regla_bancarrota_aux(EstadoActual, EstadoFinal) :-
    aplicar_bancarrota_una_pasada(EstadoActual, EstadoSiguiente),
    (   EstadoSiguiente == EstadoActual
    ->  EstadoFinal = EstadoActual
    ;   regla_bancarrota_aux(EstadoSiguiente, EstadoFinal)
    ).


% =====================================
% ISSUE 8 – MOTOR ITERATIVO DE REGLAS
% =====================================

/*
Motor iterativo de reglas:
- La implementación canónica es la instrumentada con métricas.
- Las versiones sin métricas son wrappers sobre ella.
*/

max_iter_reglas(10).

resolver_evento_casilla(EstadoIn, EstadoOut) :-
    metricas_init(M0),
    resolver_evento_casilla_metricas(EstadoIn, M0, EstadoOut, _).

aplicar_reglas_una_pasada(EstadoIn, EstadoOut) :-
    metricas_init(M0),
    aplicar_reglas_una_pasada_metricas(EstadoIn, M0, EstadoOut, _).

/*
 IterUsadas = número de pasadas ejecutadas.
*/
aplicar_reglas_hasta_estable(EstadoIn, MaxIter, EstadoOut, IterUsadas) :-
    metricas_init(M0),
    aplicar_reglas_hasta_estable_metricas(
        EstadoIn, MaxIter, EstadoOut, IterUsadas, M0, _
    ).

turno_con_reglas(EstadoIn, Tirada, EstadoOut) :-
    metricas_init(M0),
    turno_con_reglas_metricas(EstadoIn, Tirada, M0, EstadoOut, _).

/*
 Núcleo compartido de simulación.
*/
simular_con_reglas_core(Estado, Tiradas, 0, Estado, Tiradas, M, M) :- !.
simular_con_reglas_core(EstadoIn, [T | Ts], N, EstadoOut, TiradasRestantes, M0, MOut) :-
    integer(N),
    N > 0,
    turno_con_reglas_metricas(EstadoIn, T, M0, EstadoNext, M1),
    N1 is N - 1,
    simular_con_reglas_core(EstadoNext, Ts, N1, EstadoOut, TiradasRestantes, M1, MOut).

simular_con_reglas(EstadoIn, Tiradas, N, EstadoOut, TiradasRestantes) :-
    metricas_init(M0),
    simular_con_reglas_core(EstadoIn, Tiradas, N, EstadoOut, TiradasRestantes, M0, _).

simular_movimientos_con_reglas(EstadoIn, ListaTiradas, EstadoOut) :-
    simular_turnos_con_reglas_metricas(EstadoIn, ListaTiradas, EstadoOut, _).


% =====================================
% ISSUE 9 – INTEGRACIÓN REGLAS + TURNO
% =====================================

ejecutar_turno(EstadoIn, Tirada, EstadoOut) :-
    turno_con_reglas(EstadoIn, Tirada, EstadoOut).

simular_turnos_con_reglas(EstadoIn, ListaTiradas, EstadoOut) :-
    simular_turnos_con_reglas_metricas(EstadoIn, ListaTiradas, EstadoOut, _).


% =====================================
% ISSUE 17 – MEJORA 1: ITERACIÓN + MÉTRICAS
% =====================================

/*
Métricas del motor.

Representación:
- metricas(IterPorTurnoRev, IterTotal, Compras, Alquileres, Bancarrotas)
*/

metricas_init(metricas([], 0, 0, 0, 0)).

metricas_inc_compras(
    metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas),
    metricas(IterRev, IterTotal, Compras2, Alquileres, Bancarrotas)
) :-
    Compras2 is Compras + 1.

metricas_inc_alquileres(
    metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas),
    metricas(IterRev, IterTotal, Compras, Alquileres2, Bancarrotas)
) :-
    Alquileres2 is Alquileres + 1.

metricas_inc_bancarrotas_n(
    metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas),
    N,
    metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas2)
) :-
    Bancarrotas2 is Bancarrotas + N.

metricas_registrar_iter_turno(
    metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas),
    IterTurno,
    metricas([IterTurno | IterRev], IterTotal2, Compras, Alquileres, Bancarrotas)
) :-
    IterTotal2 is IterTotal + IterTurno.


regla_compra_metricas(EstadoIn, M0, EstadoOut, M1) :-
    regla_compra(EstadoIn, EstadoOut),
    (   EstadoOut == EstadoIn
    ->  M1 = M0
    ;   metricas_inc_compras(M0, M1)
    ).

regla_alquiler_metricas(EstadoIn, M0, EstadoOut, M1) :-
    regla_alquiler(EstadoIn, EstadoOut),
    (   EstadoOut == EstadoIn
    ->  M1 = M0
    ;   metricas_inc_alquileres(M0, M1)
    ).

regla_monopolio_metricas(EstadoIn, M, EstadoOut, M) :-
    regla_monopolio(EstadoIn, EstadoOut).

regla_bancarrota_metricas(EstadoIn, M0, EstadoOut, M1) :-
    regla_bancarrota(EstadoIn, EstadoOut),
    EstadoIn = estado(Js0, _Tab0, _Turno0),
    EstadoOut = estado(Js1, _Tab1, _Turno1),
    length(Js0, N0),
    length(Js1, N1),
    Eliminados is N0 - N1,
    metricas_inc_bancarrotas_n(M0, Eliminados, M1).

aplicar_reglas_una_pasada_metricas(EstadoIn, M0, EstadoOut, MOut) :-
    regla_monopolio_metricas(EstadoIn, M0, E1, M1),
    regla_bancarrota_metricas(E1, M1, EstadoOut, MOut).

/*
 IterUsadas = número de pasadas ejecutadas.
*/
aplicar_reglas_hasta_estable_metricas(EstadoIn, MaxIter, EstadoOut, IterUsadas, M0, MOut) :-
    integer(MaxIter),
    MaxIter >= 0,
    aplicar_reglas_hasta_estable_metricas_aux(
        EstadoIn, MaxIter, EstadoOut, 0, IterUsadas, M0, MOut
    ).

aplicar_reglas_hasta_estable_metricas_aux(EstadoActual, 0, EstadoActual, Acum, Acum, M, M) :- !.
aplicar_reglas_hasta_estable_metricas_aux(EstadoActual, MaxRestante, EstadoFinal, Acum, IterUsadas, M0, MOut) :-
    aplicar_reglas_una_pasada_metricas(EstadoActual, M0, EstadoSiguiente, M1),
    Acum1 is Acum + 1,
    (   EstadoSiguiente == EstadoActual
    ->  EstadoFinal = EstadoActual,
        IterUsadas = Acum1,
        MOut = M1
    ;   Max1 is MaxRestante - 1,
        aplicar_reglas_hasta_estable_metricas_aux(
            EstadoSiguiente, Max1, EstadoFinal, Acum1, IterUsadas, M1, MOut
        )
    ).

resolver_evento_casilla_metricas(EstadoIn, M0, EstadoOut, MOut) :-
    regla_compra_metricas(EstadoIn, M0, E1, M1),
    (   E1 == EstadoIn
    ->  regla_alquiler_metricas(EstadoIn, M1, EstadoOut, MOut)
    ;   EstadoOut = E1,
        MOut = M1
    ).

turno_con_reglas_metricas(EstadoIn, Tirada, M0, EstadoOut, MOut) :-
    jugador_activo(EstadoIn, JugadorActivo),
    jugador_campos(JugadorActivo, NombreAct, _Pos, _Din, _Props, _EstadoTurno),

    (   es_doble(Tirada)
    ->  dobles_seguidos_jugador(JugadorActivo, Dobles0),
        Dobles1 is Dobles0 + 1,
        (   Dobles1 >= 3
        ->  enviar_activo_a_carcel(EstadoIn, 3, EstadoCarcel),
            metricas_registrar_iter_turno(M0, 0, M1),
            cerrar_turno(EstadoCarcel, NombreAct, no, EstadoOut),
            MOut = M1
        ;   mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
            resolver_evento_casilla_metricas(EstadoMov, M0, EstadoEvento, M1),
            actualizar_dobles_activo_compatible(EstadoEvento, Dobles1, EstadoPrep),
            max_iter_reglas(Max),
            aplicar_reglas_hasta_estable_metricas(EstadoPrep, Max, EstadoReglas, IterTurno, M1, M2),
            metricas_registrar_iter_turno(M2, IterTurno, M3),
            cerrar_turno(EstadoReglas, NombreAct, si, EstadoOut),
            MOut = M3
        )
    ;   mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
        resolver_evento_casilla_metricas(EstadoMov, M0, EstadoEvento, M1),
        actualizar_dobles_activo_compatible(EstadoEvento, 0, EstadoPrep),
        max_iter_reglas(Max),
        aplicar_reglas_hasta_estable_metricas(EstadoPrep, Max, EstadoReglas, IterTurno, M1, M2),
        metricas_registrar_iter_turno(M2, IterTurno, M3),
        cerrar_turno(EstadoReglas, NombreAct, no, EstadoOut),
        MOut = M3
    ).

simular_turnos_con_reglas_metricas(EstadoIn, ListaTiradas, EstadoOut, MetricasOut) :-
    metricas_init(M0),
    length(ListaTiradas, N),
    simular_con_reglas_core(EstadoIn, ListaTiradas, N, EstadoOut, [], M0, MetricasOut).


% =====================================
% ISSUE 18 – MEJORA 2: PATRIMONIO + RANKING DINÁMICO
% =====================================

/*
Patrimonio total de un jugador.

Definición actual:
- Patrimonio = Dinero + valor total de propiedades
*/

valor_propiedad_tablero(PropId, Tablero, Precio) :-
    memberchk(propiedad(PropId, Precio, _Color), Tablero).

valor_propiedades([], _Tablero, 0).
valor_propiedades([PropId | Resto], Tablero, ValorTotal) :-
    valor_propiedad_tablero(PropId, Tablero, Precio),
    valor_propiedades(Resto, Tablero, ValorResto),
    ValorTotal is Precio + ValorResto.

patrimonio_jugador(Jugador, Tablero, Patrimonio) :-
    jugador_campos(Jugador, _Nombre, _Pos, Dinero, Props, _EstadoTurno),
    valor_propiedades(Props, Tablero, ValorProps),
    Patrimonio is Dinero + ValorProps.


/*
Ranking dinámico.

Criterio de orden:
1) mayor patrimonio total
2) en empate, mayor dinero
3) en empate, nombre ascendente

Representación:
- ranking(Nombre, Patrimonio, Dinero, ValorPropiedades, NumPropiedades)
*/

entrada_ranking(
    Jugador,
    Tablero,
    ranking(Nombre, Patrimonio, Dinero, ValorProps, NumProps),
    k(NegPatrimonio, NegDinero, Nombre)
) :-
    jugador_campos(Jugador, Nombre, _Pos, Dinero, Props, _EstadoTurno),
    valor_propiedades(Props, Tablero, ValorProps),
    length(Props, NumProps),
    Patrimonio is Dinero + ValorProps,
    NegPatrimonio is -Patrimonio,
    NegDinero is -Dinero.

construir_pares_ranking([], _Tablero, []).
construir_pares_ranking([Jugador | Resto], Tablero, [Clave-Entrada | ParesResto]) :-
    entrada_ranking(Jugador, Tablero, Entrada, Clave),
    construir_pares_ranking(Resto, Tablero, ParesResto).

extraer_entradas_ranking([], []).
extraer_entradas_ranking([_Clave-Entrada | Resto], [Entrada | RankingResto]) :-
    extraer_entradas_ranking(Resto, RankingResto).

ranking_jugadores(estado(Js, Tablero, _Turno), Ranking) :-
    construir_pares_ranking(Js, Tablero, Pares),
    keysort(Pares, ParesOrdenados),
    extraer_entradas_ranking(ParesOrdenados, Ranking).