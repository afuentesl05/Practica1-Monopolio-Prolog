% ============================================================
% scenarios.pl — Escenarios reproducibles y validaciones manuales
%
% Contenido:
% - Escenarios del proyecto
% - Impresión formateada del estado
% - Visualización de monopolios
% - Validaciones manuales del motor
%
% Este archivo reutiliza la lógica definida en main.pl.
% No añade reglas nuevas del juego.
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
Imprime el tablero completo, solo cuando se quiera inspeccionar explícitamente.
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

/*
mostrar_cabecera(+Titulo)
Cabecera uniforme para escenarios y validaciones.
*/
mostrar_cabecera(Titulo) :-
    writeln('================================'),
    writeln(Titulo),
    writeln('================================').

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
- Ana ya posee el monopolio marrón
- Sirve para verificar la Regla 2 (Monopolio)
- El motor iterativo no debe entrar en bucle
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
- monopolios iniciales
- tiradas
- estado final
- monopolios finales
*/
ejecutar_escenario(IdEscenario, EstadoFinal) :-
    estado_inicial(IdEscenario, EstadoInicial),
    tiradas_escenario(IdEscenario, Tiradas),

    atomic_list_concat(['ESCENARIO: ', IdEscenario], Titulo),
    mostrar_cabecera(Titulo), nl,

    writeln('ESTADO INICIAL'),
    writeln('--------------------------------'),
    mostrar_estado(EstadoInicial), nl,

    writeln('MONOPOLIOS INICIALES'),
    writeln('--------------------------------'),
    mostrar_monopolios(EstadoInicial), nl,

    writeln('TIRADAS DEL ESCENARIO'),
    writeln('--------------------------------'),
    writeln(Tiradas), nl,

    simular_turnos_con_reglas(EstadoInicial, Tiradas, EstadoFinal),

    writeln('ESTADO FINAL'),
    writeln('--------------------------------'),
    mostrar_estado(EstadoFinal), nl,

    writeln('MONOPOLIOS FINALES'),
    writeln('--------------------------------'),
    mostrar_monopolios(EstadoFinal),

    writeln('================================').

% ============================================================
% VALIDACIONES MANUALES DEL MOTOR
% ============================================================

/*
validar_mover_basico/0
Comprueba mover/4 sin cruce de salida.
Debe cambiar posición del jugador activo, pero no el turno.
*/
validar_mover_basico :-
    estado_inicial(E0),
    mostrar_cabecera('VALIDACION: mover/4 basico'), nl,

    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,

    mover(E0, 7, E1, Paso),

    writeln('Tras mover con tirada 7:'),
    mostrar_estado(E1),
    write('Paso por salida: '), writeln(Paso),
    writeln('================================').

/*
validar_turno_base/0
Comprueba turno_base/3.
Debe cambiar posición del jugador activo y avanzar el turno.
*/
validar_turno_base :-
    estado_inicial(E0),
    mostrar_cabecera('VALIDACION: turno_base/3'), nl,

    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,

    turno_base(E0, 7, E1),

    writeln('Tras turno_base con tirada 7:'),
    mostrar_estado(E1),
    writeln('================================').

/*
validar_modulo_y_salida/0
Comprueba modulo 40 y bonus de salida.
Se coloca a Ana en la casilla 39 y se mueve 2 posiciones.
Debe terminar en la casilla 1 y cobrar bonus de salida.
*/
validar_modulo_y_salida :-
    estado_inicial(estado(Js, Tab, 0)),
    set_jugador(ana, Js, jugador(ana, 39, 1500, []), Js2),
    E0 = estado(Js2, Tab, 0),

    mostrar_cabecera('VALIDACION: modulo 40 + bonus salida'), nl,

    writeln('Estado inicial modificado:'),
    mostrar_estado(E0), nl,

    mover(E0, 2, E1, Paso),

    writeln('Tras mover con tirada 2:'),
    mostrar_estado(E1),
    write('Paso por salida: '), writeln(Paso),
    writeln('================================').