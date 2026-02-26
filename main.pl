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


% Estructuras base del modelo:
% estado(Jugadores, Tablero, Turno).
% jugador(Nombre, Posicion, Dinero, Propiedades).

% Estado inicial minimo para pruebas
estado_inicial(
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        [ salida,
          propiedad(marron1, 60, marron),
          carta,
          impuesto(200)
        ],
        0
    )
).

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

%% get_jugador(+Nombre, +Jugadores, -Jugador)
%  Verdadero si Jugador es el jugador con ese Nombre dentro de la lista Jugadores.
%  Determinista si el Nombre es único.
get_jugador(Nombre, [jugador(Nombre, Pos, Din, Props) | _],
            jugador(Nombre, Pos, Din, Props)) :- !.
get_jugador(Nombre, [_ | Resto], Jugador) :-
    get_jugador(Nombre, Resto, Jugador).

%% set_jugador(+Nombre, +Jugadores, +JugadorNuevo, -JugadoresNuevo)
%  Sustituye al jugador con Nombre por JugadorNuevo, produciendo una nueva lista.
%  Determinista si el Nombre es único.
set_jugador(Nombre, [jugador(Nombre, _, _, _) | Resto],
            JugadorNuevo, [JugadorNuevo | Resto]) :- !.
set_jugador(Nombre, [J | Resto], JugadorNuevo, [J | RestoNuevo]) :-
    set_jugador(Nombre, Resto, JugadorNuevo, RestoNuevo).

%% update_pos(+Jugador, +NuevaPos, -JugadorActualizado)
update_pos(jugador(N, _Pos, Din, Props), NuevaPos,
           jugador(N, NuevaPos, Din, Props)).

%% update_dinero(+Jugador, +NuevoDinero, -JugadorActualizado)
update_dinero(jugador(N, Pos, _Din, Props), NuevoDinero,
              jugador(N, Pos, NuevoDinero, Props)).

%% add_prop(+Jugador, +PropId, -JugadorActualizado)
%  Añade una propiedad al final (sin comprobar duplicados).
add_prop(jugador(N, Pos, Din, Props), PropId,
         jugador(N, Pos, Din, Props2)) :-
    append(Props, [PropId], Props2).