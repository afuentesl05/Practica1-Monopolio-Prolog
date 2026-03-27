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

% Estado inicial minimo para pruebas
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
% ISSUE 2 – UTILIDADES DE ACTUALIZACIÓN
% =====================================

/*
Capa funcional de acceso/actualización.

- get_jugador/3: extrae el jugador por Nombre.
- set_jugador/4: sustituye el jugador por Nombre, devolviendo nueva lista.
- update_pos/3, update_dinero/3, add_prop/3: transformaciones puras sobre jugador/4.

Diseño para evitar choicepoints:
- Predicados deterministas bajo el invariante "Nombre único".
- Cortes (!) tras encontrar el objetivo en la lista.
*/

/*
  get_jugador(+Nombre, +Jugadores, -Jugador)
    Verdadero si Jugador es el jugador con ese Nombre dentro de la lista Jugadores.
    Determinista si el Nombre es único.
*/
get_jugador(Nombre, [jugador(Nombre, Pos, Din, Props) | _],
            jugador(Nombre, Pos, Din, Props)) :- !.
get_jugador(Nombre, [_ | Resto], Jugador) :-
    get_jugador(Nombre, Resto, Jugador).

/*
  set_jugador(+Nombre, +Jugadores, +JugadorNuevo, -JugadoresNuevo)
    Sustituye al jugador con Nombre por JugadorNuevo, produciendo una nueva lista.
    Determinista si el Nombre es único.
*/
set_jugador(Nombre, [jugador(Nombre, _, _, _) | Resto],
            JugadorNuevo, [JugadorNuevo | Resto]) :- !.
set_jugador(Nombre, [J | Resto], JugadorNuevo, [J | RestoNuevo]) :-
    set_jugador(Nombre, Resto, JugadorNuevo, RestoNuevo).

/*
  update_pos(+Jugador, +NuevaPos, -JugadorActualizado)
*/
update_pos(jugador(N, _Pos, Din, Props), NuevaPos,
           jugador(N, NuevaPos, Din, Props)).

/*
  update_dinero(+Jugador, +NuevoDinero, -JugadorActualizado)
*/
update_dinero(jugador(N, Pos, _Din, Props), NuevoDinero,
              jugador(N, Pos, NuevoDinero, Props)).

/*
  add_prop(+Jugador, +PropId, -JugadorActualizado)
  Añade una propiedad.
*/
add_prop(jugador(N, Pos, Din, Props), PropId,
         jugador(N, Pos, Din, [PropId|Props])).


% =====================================
% ISSUE 3 – TABLERO BASE (40 CASILLAS)
% =====================================

/*
Estructura elegida:
- El tablero es una lista lineal de exactamente 40 casillas.
- La posición del jugador (Posicion en jugador/4) se interpreta como índice 0-based
  sobre la lista del tablero: 0..39.
- La consulta por casilla se hará por índice (p.ej. nth0/3) en futuras reglas.

Representación homogénea de casillas:
- salida
- propiedad(Id, Precio, Color)
- impuesto(Monto)
- carta
- especial(Tipo)  % casillas especiales extensibles (carcel, parking, etc.)
*/

tablero_base([
    salida,                              % 0
    propiedad(marron1,   60, marron),     % 1
    carta,                               % 2
    propiedad(marron2,   60, marron),     % 3
    impuesto(200),                       % 4
    especial(estacion1),                 % 5
    propiedad(celeste1, 100, celeste),   % 6
    carta,                               % 7
    propiedad(celeste2, 100, celeste),   % 8
    propiedad(celeste3, 120, celeste),   % 9

    especial(carcel_visita),             % 10
    propiedad(rosa1,    140, rosa),      % 11
    especial(servicio1),                 % 12
    propiedad(rosa2,    140, rosa),      % 13
    propiedad(rosa3,    160, rosa),      % 14
    especial(estacion2),                 % 15
    propiedad(naranja1, 180, naranja),   % 16
    carta,                               % 17
    propiedad(naranja2, 180, naranja),   % 18
    propiedad(naranja3, 200, naranja),   % 19

    especial(parking),                   % 20
    propiedad(rojo1,    220, rojo),      % 21
    carta,                               % 22
    propiedad(rojo2,    220, rojo),      % 23
    propiedad(rojo3,    240, rojo),      % 24
    especial(estacion3),                 % 25
    propiedad(amarillo1,260, amarillo),  % 26
    propiedad(amarillo2,260, amarillo),  % 27
    especial(servicio2),                 % 28
    propiedad(amarillo3,280, amarillo),  % 29

    especial(ir_carcel),                 % 30
    propiedad(verde1,   300, verde),     % 31
    propiedad(verde2,   300, verde),     % 32
    carta,                               % 33
    propiedad(verde3,   320, verde),     % 34
    especial(estacion4),                 % 35
    carta,                               % 36
    propiedad(azul1,    350, azul),      % 37
    impuesto(100),                       % 38
    propiedad(azul2,    400, azul)       % 39
]).

% =====================================
% ISSUE 4 – MOVIMIENTO SOBRE EL TABLERO
% =====================================

/*
Movimiento:
- mover/4 aplica una tirada (entero) al jugador del turno actual.
- Posición circular: NuevaPos is (Pos + Tirada) mod 40.
- Paso por salida: si (Pos + Tirada) >= 40, se suma BONUS_SALIDA.
- No usa aleatorio: para simular varias tiradas se usa una lista predefinida.

Nota:
- En Monopoly típico, BONUS_SALIDA = 200. Aquí lo fijamos como constante.
*/

bonus_salida(200).

/*
  mover(+EstadoIn, +Tirada, -EstadoOut, -PasoSalida)
  Aplica la Tirada al jugador activo (según Turno).
  PasoSalida = si O no según si se ha cruzado salida.
  Determinista.
*/
mover(estado(Js, Tablero, Turno), Tirada,
      estado(Js2, Tablero, Turno), PasoSalida) :-
    integer(Tirada),
    Tirada >= 0,
    length(Tablero, 40),                      % asegura mod 40 correcto (tablero fijo)
    nth0(Turno, Js, Jugador),                 % Jugador de lista jugadores con indice Turno
    Jugador = jugador(Nombre, Pos, Din, Props),

    Suma is Pos + Tirada,
    (   Suma >= 40
    ->  PasoSalida = si,
        bonus_salida(B),
        Din2 is Din + B
    ;   PasoSalida = no,
        Din2 is Din
    ),

    NuevaPos is Suma mod 40,
    Jugador2 = jugador(Nombre, NuevaPos, Din2, Props),

    set_jugador(Nombre, Js, Jugador2, Js2).

/*
   avanzar_turno(+EstadoIn, -EstadoOut)
   Pasa al siguiente jugador (circular).
*/
avanzar_turno(estado(Js, Tablero, Turno),
              estado(Js, Tablero, Turno2)) :-
    length(Js, N),
    N > 0,
    Turno2 is (Turno + 1) mod N.



% =====================================
% ISSUE 5 – ITERACIÓN POR TURNOS
% =====================================

/*
Motor de turnos básico (sin aplicar reglas):
- turno_base/3: mover + avanzar turno.
- simular/5: simula N turnos básicos consumiendo N tiradas.
- simular_movimientos/3: consume toda la lista de tiradas (wrapper).
*/

/*
 turno_base(+EstadoIn, +Tirada, -EstadoOut)
  Ejecuta un turno mínimo:
  1) mover al jugador activo con Tirada
  2) pasar al siguiente turno
*/
turno_base(EstadoIn, Tirada, EstadoOut) :-
    mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
    avanzar_turno(EstadoMov, EstadoOut).

/*
 simular(+EstadoIn, +Tiradas, +N, -EstadoOut, -TiradasRestantes)
  Simula N turnos básicos consumiendo N tiradas de la lista.
  - Si N = 0, no consume tiradas.
  - Si faltan tiradas para N, falla.
*/
simular(Estado, Tiradas, 0, Estado, Tiradas) :- !.
simular(EstadoIn, [T|Ts], N, EstadoOut, TiradasRestantes) :-
    integer(N),
    N > 0,
    turno_base(EstadoIn, T, EstadoNext),
    N1 is N - 1,
    simular(EstadoNext, Ts, N1, EstadoOut, TiradasRestantes).

/*
 simular_movimientos(+EstadoIn, +ListaTiradas, -EstadoOut)
  Wrapper que consume toda la lista de tiradas usando turnos básicos.
*/
simular_movimientos(EstadoIn, ListaTiradas, EstadoOut) :-
    length(ListaTiradas, N),
    simular(EstadoIn, ListaTiradas, N, EstadoOut, []).

% =====================================
% HELPERS Compra y Alquiler
% =====================================

/*
 propietario_de(+PropId, +Jugadores, -NombreProp, -JugadorProp)
  Determina el propietario de PropId. Falla si nadie la posee.
  Determinista si la propiedad solo puede pertenecer a un jugador.
*/
propietario_de(PropId, [jugador(Nombre,Pos,Din,Props)|_], Nombre, jugador(Nombre,Pos,Din,Props)) :-
    memberchk(PropId, Props), !.
propietario_de(PropId, [_|Resto], NombreProp, JugadorProp) :-
    propietario_de(PropId, Resto, NombreProp, JugadorProp).

/*
 propiedad_sin_dueno(+PropId, +Jugadores)
  Verdadero si la propiedad no tiene propietario.
*/
propiedad_sin_dueno(PropId, Jugadores) :-
    \+ propietario_de(PropId, Jugadores, _Nombre, _Jugador).

/*
 casilla_actual(+Estado, -Casilla)
  Obtiene la casilla donde está el jugador activo.
*/
casilla_actual(estado(Js, Tablero, Turno), Casilla) :-
    nth0(Turno, Js, jugador(_, Pos, _, _)),
    nth0(Pos, Tablero, Casilla).

% =====================================
% ISSUE 6 – REGLA 0 (COMPRA DE PROPIEDAD)
% =====================================

/*
Regla 0 (Compra):
Si el jugador activo cae en una casilla propiedad(PropId, Precio, _),
y la propiedad no tiene dueño,
y el jugador tiene Dinero >= Precio,
entonces:
- se descuenta el Precio del dinero
- se añade PropId a la lista de propiedades del jugador
- se actualiza la lista de jugadores en el estado

La regla es determinista y siempre tiene éxito:
si no se compra, devuelve el mismo estado.
*/

/*
 jugador_activo(+Estado, -Jugador)
  Obtiene el jugador activo (según Turno).
*/
jugador_activo(estado(Js, _Tablero, Turno), Jugador) :-
    nth0(Turno, Js, Jugador).


/*
 regla_compra(+EstadoIn, -EstadoOut)
  Aplica la compra si procede. Si no procede, EstadoOut = EstadoIn.
  Determinista.
*/
regla_compra(EstadoIn, EstadoOut) :-
    EstadoIn = estado(Js, Tablero, Turno),
    jugador_activo(EstadoIn, Jugador),
    Jugador = jugador(Nombre, _Pos, Din, _Props),
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

/*
Regla 1 (Alquiler):
Si el jugador activo cae en una casilla propiedad(PropId, Precio, _)
y la propiedad tiene dueño distinto del jugador actual,
entonces:
- se resta el alquiler al jugador actual
- se suma el alquiler al propietario
- se actualiza la lista de jugadores en el estado

Cálculo:
- alquiler = Precio // 10

La regla es determinista y siempre tiene éxito:
si no aplica, devuelve el mismo estado.
*/

/*
 alquiler_casilla(+Casilla, -Alquiler)
  Calcula el alquiler a partir del precio de la propiedad.
*/
alquiler_casilla(propiedad(_PropId, Precio, _), Alquiler) :-
    Alquiler is Precio // 10.

/*
 regla_alquiler(+EstadoIn, -EstadoOut)
  Aplica alquiler si procede. Si no procede, EstadoOut = EstadoIn.
  Determinista.
*/
regla_alquiler(EstadoIn, EstadoOut) :-
    EstadoIn = estado(Js, Tablero, Turno),
    jugador_activo(EstadoIn, JugActual),
    JugActual = jugador(NombreAct, _PosAct, DinAct, _PropsAct),
    casilla_actual(EstadoIn, Casilla),

    (   Casilla = propiedad(PropId, _Precio, _),
        propietario_de(PropId, Js, NombreProp, JugProp),
        NombreProp \= NombreAct,
        alquiler_casilla(Casilla, Alq)
    ->  % actualizar pagador
        DinAct2 is DinAct - Alq,
        update_dinero(JugActual, DinAct2, JugAct2),
        set_jugador(NombreAct, Js, JugAct2, JsTmp),

        % actualizar propietario
        JugProp = jugador(NombreProp, _PosP, DinP, _PropsP),
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

/*
Regla 2 (Monopolio):
Si un jugador posee todas las propiedades de un mismo color,
queda habilitado para construir casas en ese grupo de color.

La habilitación se expone mediante predicados de consulta.
regla_monopolio/2 no modifica el estado.
*/

/*
 propiedades_color(+Tablero, +Color, -PropIds)
  Devuelve la lista de identificadores de propiedades del color indicado.
*/
propiedades_color([], _Color, []).
propiedades_color([propiedad(PropId, _Precio, Color) | Resto], Color, [PropId | PropsColor]) :-
    !,
    propiedades_color(Resto, Color, PropsColor).
propiedades_color([_ | Resto], Color, PropsColor) :-
    propiedades_color(Resto, Color, PropsColor).

/*
 colores_tablero(+Tablero, -ColoresUnicos)
  Devuelve la lista de colores presentes en el tablero (solo casillas propiedad/3),
  sin duplicados.
*/
colores_tablero(Tablero, ColoresUnicos) :-
    findall(Color,
            member(propiedad(_, _, Color), Tablero),
            ColoresDup),
    sort(ColoresDup, ColoresUnicos).

/*
 tiene_todas(+Sublista, +Lista)
  Verdadero si todos los elementos de Sublista pertenecen a Lista.
*/
tiene_todas([], _).
tiene_todas([X | Xs], Lista) :-
    memberchk(X, Lista),
    tiene_todas(Xs, Lista).

/*
 monopolio_color(+Jugador, +Tablero, ?Color)
  Verdadero si Jugador posee todas las propiedades del Color.
  Exige que exista al menos una propiedad de ese color.
*/
monopolio_color(jugador(_Nombre, _Pos, _Din, Props), Tablero, Color) :-
    colores_tablero(Tablero, Colores),
    member(Color, Colores),
    propiedades_color(Tablero, Color, PropsColor),
    PropsColor \= [],
    tiene_todas(PropsColor, Props).

/*
 colores_monopolio_jugador(+Jugador, +Tablero, -Colores)
  Devuelve la lista de colores sobre los que el jugador tiene monopolio.
*/
colores_monopolio_jugador(Jugador, Tablero, Colores) :-
    findall(Color,
            monopolio_color(Jugador, Tablero, Color),
            ColoresDup),
    sort(ColoresDup, Colores).

/*
 jugador_activo_monopolios(+Estado, -Colores)
  Devuelve los colores monopolizados por el jugador activo.
*/
jugador_activo_monopolios(estado(Js, Tablero, Turno), Colores) :-
    nth0(Turno, Js, Jugador),
    colores_monopolio_jugador(Jugador, Tablero, Colores).

/*
 regla_monopolio(+EstadoIn, -EstadoOut)
  Regla no destructiva.
*/
regla_monopolio(Estado, Estado).



% =====================================
% ISSUE 11 – REGLA 3 (BANCARROTA)
% =====================================

/*
Regla 3 (Bancarrota):
Si un jugador tiene dinero negativo, se elimina de la lista global de jugadores.
Sus propiedades desaparecen con él (vuelven implícitamente al banco).
Se ajusta el índice de turno para mantener consistencia.

La regla elimina iterativamente a todos los jugadores en bancarrota.
*/

/*
 jugador_en_bancarrota(+Jugador)
  Verdadero si el jugador tiene dinero negativo.
*/
jugador_en_bancarrota(jugador(_Nombre, _Pos, Dinero, _Props)) :-
    Dinero < 0.

/*
 primer_bancarrota(+Jugadores, -Indice, -Jugador)
  Obtiene el primer jugador de la lista con dinero negativo.
*/
primer_bancarrota([Jugador | _], 0, Jugador) :-
    jugador_en_bancarrota(Jugador), !.
primer_bancarrota([_ | Resto], Indice, Jugador) :-
    primer_bancarrota(Resto, IndiceResto, Jugador),
    Indice is IndiceResto + 1.

/*
 remove_nth0(+Indice, +Lista, -Elem, -ListaSinElem)
  Elimina el elemento en posición Indice de una lista.
*/
remove_nth0(0, [X | Xs], X, Xs) :- !.
remove_nth0(N, [X | Xs], Elem, [X | Ys]) :-
    N > 0,
    N1 is N - 1,
    remove_nth0(N1, Xs, Elem, Ys).

/*
 ajustar_turno_tras_eliminacion(+TurnoActual, +IndiceEliminado, +NumJugadoresRestantes, -TurnoNuevo)
  Ajusta el turno tras eliminar un jugador.
*/
ajustar_turno_tras_eliminacion(_TurnoActual, _IndiceEliminado, 0, 0) :- !.
ajustar_turno_tras_eliminacion(TurnoActual, IndiceEliminado, NumRestantes, TurnoNuevo) :-
    (   IndiceEliminado < TurnoActual
    ->  TurnoTemp is TurnoActual - 1
    ;   IndiceEliminado =:= TurnoActual
    ->  TurnoTemp is TurnoActual mod NumRestantes
    ;   TurnoTemp is TurnoActual
    ),
    TurnoNuevo is TurnoTemp mod NumRestantes.

/*
 eliminar_jugador_por_indice(+EstadoIn, +IndiceEliminado, -EstadoOut, -JugadorEliminado)
  Elimina al jugador situado en IndiceEliminado y ajusta el turno.
*/
eliminar_jugador_por_indice(
    estado(Js, Tablero, Turno),
    IndiceEliminado,
    estado(Js2, Tablero, Turno2),
    JugadorEliminado
) :-
    remove_nth0(IndiceEliminado, Js, JugadorEliminado, Js2),
    length(Js2, NumRestantes),
    ajustar_turno_tras_eliminacion(Turno, IndiceEliminado, NumRestantes, Turno2).

/*
 aplicar_bancarrota_una_pasada(+EstadoIn, -EstadoOut)
  Si existe al menos un jugador en bancarrota, elimina al primero encontrado.
  Si no existe ninguno, devuelve el mismo estado.
*/
aplicar_bancarrota_una_pasada(EstadoIn, EstadoOut) :-
    EstadoIn = estado(Js, _Tablero, _Turno),
    (   primer_bancarrota(Js, Indice, _Jugador)
    ->  eliminar_jugador_por_indice(EstadoIn, Indice, EstadoOut, _Eliminado)
    ;   EstadoOut = EstadoIn
    ).

/*
 regla_bancarrota(+EstadoIn, -EstadoOut)
  Elimina iterativamente a todos los jugadores con dinero negativo.
*/
regla_bancarrota(EstadoIn, EstadoOut) :-
    regla_bancarrota_aux(EstadoIn, EstadoOut),
    !.

regla_bancarrota_aux(EstadoActual, EstadoFinal) :-
    aplicar_bancarrota_una_pasada(EstadoActual, EstadoSiguiente),
    (   EstadoSiguiente == EstadoActual
    ->  EstadoFinal = EstadoActual
    ;   regla_bancarrota_aux(EstadoSiguiente, EstadoFinal)
    ).


/*
 resolver_evento_casilla(+EstadoIn, -EstadoOut)
  Aplica una sola vez el efecto principal de la casilla actual:
  - compra si procede
  - en caso contrario, alquiler si procede
  - si no aplica nada, deja el estado igual

  Importante:
  compra y alquiler NO deben entrar en el motor iterativo,
  porque no son reglas de cierre y podrían reaplicarse indefinidamente.
*/
resolver_evento_casilla(EstadoIn, EstadoOut) :-
    regla_compra(EstadoIn, E1),
    (   E1 == EstadoIn
    ->  regla_alquiler(EstadoIn, EstadoOut)
    ;   EstadoOut = E1
    ).


% =====================================
% ISSUE 8 – MOTOR ITERATIVO DE REGLAS
% =====================================

/*
Motor iterativo de reglas:
- aplicar_reglas_una_pasada/2 aplica las reglas en orden fijo.
- aplicar_reglas_hasta_estable/4 repite pasadas hasta estabilidad o límite.
- turno_con_reglas/3 integra movimiento + reglas + avance de turno.
- simular_con_reglas/5 y simular_movimientos_con_reglas/3 simulan turnos reales.
*/

% Límite de seguridad para evitar iteraciones infinitas.
max_iter_reglas(10).

/*
 aplicar_reglas_una_pasada(+EstadoIn, -EstadoOut)
  Aplica una vez todas las reglas disponibles, en orden fijo.
*/
/*
aplicar_reglas_una_pasada(EstadoIn, EstadoOut) :-
    regla_compra(EstadoIn, E1),
    regla_alquiler(E1, E2),
    regla_monopolio(E2, E3),
    regla_bancarrota(E3, EstadoOut).*/

aplicar_reglas_una_pasada(EstadoIn, EstadoOut) :-
    regla_monopolio(EstadoIn, E1),
    regla_bancarrota(E1, EstadoOut).

/*
 aplicar_reglas_hasta_estable(+EstadoIn, +MaxIter, -EstadoOut, -IterUsadas)
  Repite la aplicación de reglas hasta que:
  - el estado deje de cambiar, o
  - se alcance el límite MaxIter.
*/
aplicar_reglas_hasta_estable(EstadoIn, MaxIter, EstadoOut, IterUsadas) :-
    integer(MaxIter),
    MaxIter >= 0,
    aplicar_reglas_hasta_estable_aux(EstadoIn, MaxIter, EstadoOut, 0, IterUsadas).

aplicar_reglas_hasta_estable_aux(EstadoActual, 0, EstadoActual, Acum, Acum) :- !.
aplicar_reglas_hasta_estable_aux(EstadoActual, MaxRestante, EstadoFinal, Acum, IterUsadas) :-
    aplicar_reglas_una_pasada(EstadoActual, EstadoSiguiente),
    (   EstadoSiguiente == EstadoActual
    ->  EstadoFinal = EstadoActual,
        IterUsadas = Acum
    ;   Max1 is MaxRestante - 1,
        Acum1 is Acum + 1,
        aplicar_reglas_hasta_estable_aux(EstadoSiguiente, Max1, EstadoFinal, Acum1, IterUsadas)
    ).

/*
 turno_con_reglas(+EstadoIn, +Tirada, -EstadoOut)
  Ejecuta un turno completo del juego con reglas.
*/

/*
turno_con_reglas(EstadoIn, Tirada, EstadoOut) :-
    mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
    max_iter_reglas(Max),
    aplicar_reglas_hasta_estable(EstadoMov, Max, EstadoReglas, _IterUsadas),
    EstadoReglas = estado(Js, _Tab, _Turno),
    (   Js = []
    ->  EstadoOut = EstadoReglas
    ;   avanzar_turno(EstadoReglas, EstadoOut)
    ).
*/
turno_con_reglas(EstadoIn, Tirada, EstadoOut) :-
    mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
    resolver_evento_casilla(EstadoMov, EstadoEvento),
    max_iter_reglas(Max),
    aplicar_reglas_hasta_estable(EstadoEvento, Max, EstadoReglas, _IterUsadas),
    EstadoReglas = estado(Js, _Tab, _Turno),
    (   Js = []
    ->  EstadoOut = EstadoReglas
    ;   avanzar_turno(EstadoReglas, EstadoOut)
    ).

/*
 simular_con_reglas(+EstadoIn, +Tiradas, +N, -EstadoOut, -TiradasRestantes)
  Simula N turnos completos (con reglas) consumiendo N tiradas.
*/
simular_con_reglas(Estado, Tiradas, 0, Estado, Tiradas) :- !.
simular_con_reglas(EstadoIn, [T|Ts], N, EstadoOut, TiradasRestantes) :-
    integer(N),
    N > 0,
    turno_con_reglas(EstadoIn, T, EstadoNext),
    N1 is N - 1,
    simular_con_reglas(EstadoNext, Ts, N1, EstadoOut, TiradasRestantes).

/*
 simular_movimientos_con_reglas(+EstadoIn, +ListaTiradas, -EstadoOut)
  Wrapper que consume toda la lista de tiradas aplicando turnos completos con reglas.
*/
simular_movimientos_con_reglas(EstadoIn, ListaTiradas, EstadoOut) :-
    length(ListaTiradas, N),
    simular_con_reglas(EstadoIn, ListaTiradas, N, EstadoOut, []).



% =====================================
% ISSUE 9 – INTEGRACIÓN REGLAS + TURNO
% =====================================

/*
Interfaz semántica del turno real y simulación completa.
*/

/*
 ejecutar_turno(+EstadoIn, +Tirada, -EstadoOut)
  Ejecuta un turno completo (alias del turno real).
*/
ejecutar_turno(EstadoIn, Tirada, EstadoOut) :-
    turno_con_reglas(EstadoIn, Tirada, EstadoOut).

/*
 simular_turnos_con_reglas(+EstadoIn, +ListaTiradas, -EstadoOut)
  Ejecuta tantos turnos completos como tiradas haya en la lista.
*/
simular_turnos_con_reglas(EstadoIn, ListaTiradas, EstadoOut) :-
    simular_movimientos_con_reglas(EstadoIn, ListaTiradas, EstadoOut).

% =====================================
% ISSUE 17 – MEJORA 1: ITERACIÓN + MÉTRICAS
% =====================================

/*
Métricas del motor.

Representación:
- metricas(IterPorTurnoRev, IterTotal, Compras, Alquileres, Bancarrotas)

Donde:
- IterPorTurnoRev almacena, en orden inverso, cuántas pasadas del motor
  de reglas se ejecutaron en cada turno (se guarda al revés por eficiencia O(1)).
- IterTotal es la suma total de iteraciones/pasadas del motor.
- Compras cuenta cuántas compras se ejecutaron realmente.
- Alquileres cuenta cuántos alquileres se ejecutaron realmente.
- Bancarrotas cuenta cuántos jugadores fueron eliminados.
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


/*
Wrappers instrumentados de reglas.
No sustituyen a las reglas existentes; simplemente las reutilizan y
actualizan métricas si realmente hubo cambio.
*/

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


/*
Una pasada del motor de reglas con métricas.
*/
/*
aplicar_reglas_una_pasada_metricas(EstadoIn, M0, EstadoOut, MOut) :-
    regla_compra_metricas(EstadoIn, M0, E1, M1),
    regla_alquiler_metricas(E1, M1, E2, M2),
    regla_monopolio_metricas(E2, M2, E3, M3),
    regla_bancarrota_metricas(E3, M3, EstadoOut, MOut).
*/

aplicar_reglas_una_pasada_metricas(EstadoIn, M0, EstadoOut, MOut) :-
    regla_monopolio_metricas(EstadoIn, M0, E1, M1),
    regla_bancarrota_metricas(E1, M1, EstadoOut, MOut).


/*
aplicar_reglas_hasta_estable_metricas(+EstadoIn, +MaxIter, -EstadoOut, -IterUsadas, +M0, -MOut)

- Repite pasadas del motor hasta estabilidad o hasta agotar el límite.
- IterUsadas cuenta cuántas pasadas se ejecutaron realmente en ese turno.
*/
aplicar_reglas_hasta_estable_metricas(EstadoIn, MaxIter, EstadoOut, IterUsadas, M0, MOut) :-
    integer(MaxIter),
    MaxIter >= 0,
    aplicar_reglas_hasta_estable_metricas_aux(EstadoIn, MaxIter, EstadoOut, 0, IterUsadas, M0, MOut).

aplicar_reglas_hasta_estable_metricas_aux(EstadoActual, 0, EstadoActual, Acum, Acum, M, M) :- !.
aplicar_reglas_hasta_estable_metricas_aux(EstadoActual, MaxRestante, EstadoFinal, Acum, IterUsadas, M0, MOut) :-
    aplicar_reglas_una_pasada_metricas(EstadoActual, M0, EstadoSiguiente, M1),
    Acum1 is Acum + 1,
    (   EstadoSiguiente == EstadoActual
    ->  EstadoFinal = EstadoActual,
        IterUsadas = Acum1,
        MOut = M1
    ;   Max1 is MaxRestante - 1,
        aplicar_reglas_hasta_estable_metricas_aux(EstadoSiguiente, Max1, EstadoFinal, Acum1, IterUsadas, M1, MOut)
    ).


/*
turno_con_reglas_metricas(+EstadoIn, +Tirada, +M0, -EstadoOut, -MOut)

Turno real con instrumentación:
1) mover
2) aplicar reglas hasta estable
3) registrar iteraciones del turno
4) avanzar turno (si quedan jugadores)
*/
/*
turno_con_reglas_metricas(EstadoIn, Tirada, M0, EstadoOut, MOut) :-
    mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
    max_iter_reglas(Max),
    aplicar_reglas_hasta_estable_metricas(EstadoMov, Max, EstadoReglas, IterTurno, M0, M1),
    metricas_registrar_iter_turno(M1, IterTurno, M2),
    EstadoReglas = estado(Js, _Tab, _Turno),
    (   Js = []
    ->  EstadoOut = EstadoReglas
    ;   avanzar_turno(EstadoReglas, EstadoOut)
    ),
    MOut = M2.
*/

turno_con_reglas_metricas(EstadoIn, Tirada, M0, EstadoOut, MOut) :-
    mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
    resolver_evento_casilla_metricas(EstadoMov, M0, EstadoEvento, M1),
    max_iter_reglas(Max),
    aplicar_reglas_hasta_estable_metricas(EstadoEvento, Max, EstadoReglas, IterTurno, M1, M2),
    metricas_registrar_iter_turno(M2, IterTurno, M3),
    EstadoReglas = estado(Js, _Tab, _Turno),
    (   Js = []
    ->  EstadoOut = EstadoReglas
    ;   avanzar_turno(EstadoReglas, EstadoOut)
    ),
    MOut = M3.


/*
Simulación completa con métricas.
*/

simular_turnos_con_reglas_metricas(EstadoIn, ListaTiradas, EstadoOut, MetricasOut) :-
    metricas_init(M0),
    simular_turnos_con_reglas_metricas_aux(EstadoIn, ListaTiradas, EstadoOut, M0, MetricasOut).

simular_turnos_con_reglas_metricas_aux(Estado, [], Estado, M, M) :- !.
simular_turnos_con_reglas_metricas_aux(EstadoIn, [T | Ts], EstadoOut, M0, MOut) :-
    turno_con_reglas_metricas(EstadoIn, T, M0, EstadoNext, M1),
    simular_turnos_con_reglas_metricas_aux(EstadoNext, Ts, EstadoOut, M1, MOut).

resolver_evento_casilla_metricas(EstadoIn, M0, EstadoOut, MOut) :-
    regla_compra(EstadoIn, E1),
    (   E1 == EstadoIn
    ->  regla_alquiler(EstadoIn, E2),
        (   E2 == EstadoIn
        ->  EstadoOut = EstadoIn,
            MOut = M0
        ;   EstadoOut = E2,
            metricas_inc_alquileres(M0, MOut)
        )
    ;   EstadoOut = E1,
        metricas_inc_compras(M0, MOut)
    ).

% =====================================
% ISSUE 18 – MEJORA 2: PATRIMONIO + RANKING DINÁMICO
% =====================================

/*
Patrimonio total de un jugador.

Definición actual:
- Patrimonio = Dinero + valor total de propiedades

Nota:
- Si en el futuro se añaden casas/hoteles/mejoras como parte del estado,
  este predicado es el punto natural donde extender el cálculo.
*/

 /*
  valor_propiedad_tablero(+PropId, +Tablero, -Precio)
  Obtiene el precio de una propiedad según el tablero.
  Determinista si cada PropId aparece una sola vez en el tablero.
*/
valor_propiedad_tablero(PropId, Tablero, Precio) :-
    memberchk(propiedad(PropId, Precio, _Color), Tablero).

/*
  valor_propiedades(+Propiedades, +Tablero, -ValorTotal)
  Suma el valor total de una lista de propiedades.
*/
valor_propiedades([], _Tablero, 0).
valor_propiedades([PropId | Resto], Tablero, ValorTotal) :-
    valor_propiedad_tablero(PropId, Tablero, Precio),
    valor_propiedades(Resto, Tablero, ValorResto),
    ValorTotal is Precio + ValorResto.

/*
  patrimonio_jugador(+Jugador, +Tablero, -Patrimonio)
  Calcula el patrimonio total de un jugador.
*/
patrimonio_jugador(jugador(_Nombre, _Pos, Dinero, Props), Tablero, Patrimonio) :-
    valor_propiedades(Props, Tablero, ValorProps),
    Patrimonio is Dinero + ValorProps.


/*
Ranking dinámico.

Criterio de orden:
1) mayor patrimonio total
2) en empate, mayor dinero
3) en empate, nombre ascendente

Representación de cada entrada del ranking:
- ranking(Nombre, Patrimonio, Dinero, ValorPropiedades, NumPropiedades)
*/

 /*
  entrada_ranking(+Jugador, +Tablero, -Entrada, -Clave)
  Construye una entrada del ranking y su clave de orden.
*/
entrada_ranking(
    jugador(Nombre, _Pos, Dinero, Props),
    Tablero,
    ranking(Nombre, Patrimonio, Dinero, ValorProps, NumProps),
    k(NegPatrimonio, NegDinero, Nombre)
) :-
    valor_propiedades(Props, Tablero, ValorProps),
    length(Props, NumProps),
    Patrimonio is Dinero + ValorProps,
    NegPatrimonio is -Patrimonio,
    NegDinero is -Dinero.

/*
  construir_pares_ranking(+Jugadores, +Tablero, -Pares)
  Construye pares Clave-Entrada para ordenarlos con keysort/2.
*/
construir_pares_ranking([], _Tablero, []).
construir_pares_ranking([Jugador | Resto], Tablero, [Clave-Entrada | ParesResto]) :-
    entrada_ranking(Jugador, Tablero, Entrada, Clave),
    construir_pares_ranking(Resto, Tablero, ParesResto).

/*
  extraer_entradas_ranking(+ParesOrdenados, -Ranking)
  Elimina las claves y deja solo las entradas del ranking.
*/
extraer_entradas_ranking([], []).
extraer_entradas_ranking([_Clave-Entrada | Resto], [Entrada | RankingResto]) :-
    extraer_entradas_ranking(Resto, RankingResto).

/*
  ranking_jugadores(+Estado, -Ranking)
  Devuelve el ranking ordenado de los jugadores del estado.
*/
ranking_jugadores(estado(Js, Tablero, _Turno), Ranking) :-
    construir_pares_ranking(Js, Tablero, Pares),
    keysort(Pares, ParesOrdenados),
    extraer_entradas_ranking(ParesOrdenados, Ranking).