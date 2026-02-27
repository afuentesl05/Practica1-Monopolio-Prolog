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
  Añade una propiedad al final (sin comprobar duplicados).
*/
add_prop(jugador(N, Pos, Din, Props), PropId,
         jugador(N, Pos, Din, Props2)) :-
    append(Props, [PropId], Props2).


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
    nth0(Turno, Js, Jugador),                 % jugador activo por índice
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

/*
   simular_movimientos(+EstadoIn, +ListaTiradas, -EstadoOut)
   Simula una secuencia de tiradas predefinidas, avanzando el turno tras cada movimiento.
   (Esto cumple la parte de "simulación mediante lista predefinida" sin aleatorio.)
*/

simular_movimientos(Estado, [], Estado) :- !.
simular_movimientos(EstadoIn, [T|Ts], EstadoOut) :-
    mover(EstadoIn, T, EstadoMov, _Paso),
    avanzar_turno(EstadoMov, EstadoNext),
    simular_movimientos(EstadoNext, Ts, EstadoOut).


% =====================================
% ISSUE 5 – ITERACIÓN POR TURNOS
% =====================================

/*
Motor de turnos (sin reglas aún):
- siguiente_turno/2: rota el jugador activo (Turno) circularmente.
- turno_base/3: ejecuta un turno mínimo: mover con tirada + pasar turno.
- simular/5: simula N turnos consecutivos consumiendo tiradas predefinidas.

Invariantes que preservamos:
- Turno siempre queda en 0..N-1
- Posicion de cada jugador queda en 0..39 (por mover/4 con mod 40)
- Tablero se mantiene (no se muta en estas issues)
*/

/*
 siguiente_turno(+EstadoIn, -EstadoOut)
  Alterna el jugador activo de forma circular.
*/
siguiente_turno(estado(Js, Tablero, Turno),
                estado(Js, Tablero, Turno2)) :-
    length(Js, N),
    N > 0,
    Turno2 is (Turno + 1) mod N.

/*
 turno_base(+EstadoIn, +Tirada, -EstadoOut)
  Ejecuta un turno mínimo:
  1) mover al jugador activo con Tirada
  2) pasar al siguiente turno
*/
turno_base(EstadoIn, Tirada, EstadoOut) :-
    mover(EstadoIn, Tirada, EstadoMov, _PasoSalida),
    siguiente_turno(EstadoMov, EstadoOut).


/*
 simular(+EstadoIn, +Tiradas, +N, -EstadoOut, -TiradasRestantes)
  Simula N turnos consecutivos consumiendo N tiradas de la lista.
  - Si N = 0, no consume tiradas.
  - Si faltan tiradas para N, falla (decisión explícita para evitar estados a medias).
*/
simular(Estado, Tiradas, 0, Estado, Tiradas) :- !.
simular(EstadoIn, [T|Ts], N, EstadoOut, TiradasRestantes) :-
    integer(N),
    N > 0,
    turno_base(EstadoIn, T, EstadoNext),
    N1 is N - 1,
    simular(EstadoNext, Ts, N1, EstadoOut, TiradasRestantes).