% ============================================================
% scenarios.pl — Escenarios reproducibles del proyecto
%
% Ejecutar:
%   ?- [scenarios].
%   ?- ejecutar_escenario(esc1, EstadoFinal).
%   ?- ejecutar_escenario(esc2, EstadoFinal).
%
% Este archivo contiene:
% - Escenarios reproducibles del juego
% - Helpers de impresión del estado
% - Helpers de visualización de monopolios
% - Validaciones manuales del motor
%
% No añade lógica nueva del Monopoly: reutiliza main.pl.
% ============================================================

:- [main].

% ============================================================
% IMPRESIÓN FORMATEADA
% ============================================================

/*
mostrar_estado(+Estado)
Imprime el estado de forma limpia:
- jugadores
- turno
No imprime el tablero completo para evitar ruido visual.
*/
mostrar_estado(estado(Jugadores, _Tablero, Turno)) :-
    writeln('Jugadores:'),
    mostrar_jugadores(Jugadores),
    nl,
    write('Turno: '), writeln(Turno).

mostrar_jugadores([]).
mostrar_jugadores([jugador(Nombre, Pos, Din, Props) | Resto]) :-
    write('  - jugador('),
    write(Nombre), write(', '),
    write(Pos), write(', '),
    write(Din), write(', '),
    write(Props), writeln(')'),
    mostrar_jugadores(Resto).

/*
mostrar_tablero(+Estado)
Imprime el tablero completo una sola vez, si se desea inspeccionar.
*/
mostrar_tablero(estado(_Jugadores, Tablero, _Turno)) :-
    writeln('Tablero:'),
    mostrar_tablero_aux(Tablero, 0).

mostrar_tablero_aux([], _).
mostrar_tablero_aux([Casilla | Resto], Indice) :-
    write('  ['), write(Indice), write('] '),
    writeln(Casilla),
    Indice1 is Indice + 1,
    mostrar_tablero_aux(Resto, Indice1).

% ============================================================
% HELPERS DE INSPECCIÓN
% ============================================================

resumen_jugadores(estado(Js, _, _), Js).
resumen_turno(estado(_, _, Turno), Turno).

% ============================================================
% DETECCIÓN DE MONOPOLIOS EN UN ESTADO
% ============================================================

/*
mostrar_monopolios(+Estado)
Imprime qué jugadores tienen monopolios y de qué colores.
*/
mostrar_monopolios(estado(Js, Tablero, _Turno)) :-
    writeln('Monopolios detectados:'),
    mostrar_monopolios_jugadores(Js, Tablero).

mostrar_monopolios_jugadores([], _).
mostrar_monopolios_jugadores([Jugador | Resto], Tablero) :-
    Jugador = jugador(Nombre, _Pos, _Din, _Props),
    colores_monopolio_jugador(Jugador, Tablero, Colores),
    write('  '), write(Nombre), write(' -> '), writeln(Colores),
    mostrar_monopolios_jugadores(Resto, Tablero).

% ============================================================
% ESCENARIO 1 — COMPRAS INICIALES
% ============================================================

/*
Escenario 1:
- 2 jugadores
- primeras compras forzadas mediante tiradas predefinidas

Secuencia:
- Ana: 1 -> marron1
- Bob: 3 -> marron2
- Ana: 5 -> celeste1
- Bob: 5 -> celeste2
*/

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

% ============================================================
% ESCENARIO 2 — JUGADOR CON MONOPOLIO FORMADO
% ============================================================

/*
Escenario 2:
- ana ya posee el monopolio marrón
- sirve para verificar la Regla 2 (Monopolio)
- el motor iterativo no debe entrar en bucle
*/

estado_inicial(esc2,
    estado(
        [ jugador(ana, 0, 1380, [marron2, marron1]),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc2, [1]).

% ============================================================
% EJECUCIÓN GENERAL DE ESCENARIOS
% ============================================================

/*
ejecutar_escenario(+IdEscenario, -EstadoFinal)

Ejecuta cualquier escenario definido mediante:
- estado_inicial/2
- tiradas_escenario/2

Muestra:
- estado inicial
- tiradas
- monopolios iniciales
- estado final
- monopolios finales
*/
ejecutar_escenario(IdEscenario, EstadoFinal) :-
    estado_inicial(IdEscenario, EstadoInicial),
    tiradas_escenario(IdEscenario, Tiradas),

    writeln('================================'),
    write('ESCENARIO: '), writeln(IdEscenario),
    writeln('================================'),
    nl,

    writeln('ESTADO INICIAL'),
    writeln('--------------------------------'),
    mostrar_estado(EstadoInicial),
    nl,

    writeln('MONOPOLIOS INICIALES'),
    writeln('--------------------------------'),
    mostrar_monopolios(EstadoInicial),
    nl,

    writeln('TIRADAS DEL ESCENARIO'),
    writeln('--------------------------------'),
    writeln(Tiradas),
    nl,

    simular_turnos_con_reglas(EstadoInicial, Tiradas, EstadoFinal),

    writeln('ESTADO FINAL'),
    writeln('--------------------------------'),
    mostrar_estado(EstadoFinal),
    nl,

    writeln('MONOPOLIOS FINALES'),
    writeln('--------------------------------'),
    mostrar_monopolios(EstadoFinal),
    writeln('================================').

% ============================================================
% VALIDACIONES MANUALES DEL MOTOR
% ============================================================

/*
Comprueba mover/4 sin cruce de salida.
Debe cambiar posición del jugador activo, pero NO el turno.
*/
validar_mover_basico :-
    estado_inicial(E0),
    writeln('=============================='),
    writeln('VALIDACION: mover/4 basico'),
    writeln('=============================='),
    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,
    mover(E0, 7, E1, Paso),
    writeln('Tras mover con tirada 7:'),
    mostrar_estado(E1),
    write('Paso por salida: '), writeln(Paso),
    writeln('==============================').

/*
Comprueba turno_base/3.
Debe cambiar posición del jugador activo Y avanzar el turno.
*/
validar_turno_base :-
    estado_inicial(E0),
    writeln('=============================='),
    writeln('VALIDACION: turno_base/3'),
    writeln('=============================='),
    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,
    turno_base(E0, 7, E1),
    writeln('Tras turno_base con tirada 7:'),
    mostrar_estado(E1),
    writeln('==============================').

/*
Comprueba modulo 40 y bonus de salida.
Se coloca a ana en la casilla 39 y se mueve 2 posiciones.
Debe terminar en la casilla 1 y cobrar bonus de salida.
*/
validar_modulo_y_salida :-
    estado_inicial(estado(Js, Tab, 0)),
    set_jugador(ana, Js, jugador(ana, 39, 1500, []), Js2),
    E0 = estado(Js2, Tab, 0),
    writeln('=============================='),
    writeln('VALIDACION: modulo 40 + bonus salida'),
    writeln('=============================='),
    writeln('Estado inicial modificado:'),
    mostrar_estado(E0), nl,
    mover(E0, 2, E1, Paso),
    writeln('Tras mover con tirada 2:'),
    mostrar_estado(E1),
    write('Paso por salida: '), writeln(Paso),
    writeln('==============================').