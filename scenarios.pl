% ============================================================
% scenarios.pl — Escenarios reproducibles y utilidades de inspección
%
% Contenido:
% - Escenarios del proyecto
% - Impresión formateada del estado
% - Visualización de monopolios, ranking y métricas
% - Predicados de ejecución manual de escenarios
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
mostrar_jugadores([Jugador | Resto]) :-
    mostrar_jugador(Jugador),
    mostrar_jugadores(Resto).

mostrar_jugador(Jugador) :-
    jugador_campos(Jugador, Nombre, Pos, Din, Props, EstadoTurno),
    write('  - jugador('),
    write(Nombre), write(', '),
    write(Pos), write(', '),
    write(Din), write(', '),
    write(Props),
    (   Jugador = jugador(_, _, _, _)
    ->  writeln(')')
    ;   write(', '),
        write(EstadoTurno),
        writeln(')')
    ).

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
    jugador_campos(Jugador, Nombre, _Pos, _Din, _Props, _EstadoTurno),
    colores_monopolio_jugador(Jugador, Tablero, Colores),
    write('  '), write(Nombre), write(' -> '), writeln(Colores),
    mostrar_monopolios_jugadores(Resto, Tablero).

/*
mostrar_ranking(+Estado)
Imprime el ranking dinámico de los jugadores según patrimonio total.
*/
mostrar_ranking(Estado) :-
    ranking_jugadores(Estado, Ranking),
    writeln('Ranking dinamico:'),
    mostrar_ranking_lista(Ranking, 1).

mostrar_ranking_lista([], _).
mostrar_ranking_lista(
    [ranking(Nombre, Patrimonio, Dinero, ValorProps, NumProps) | Resto],
    Pos
) :-
    write('  '), write(Pos), write('. '),
    write(Nombre),
    write(' -> patrimonio='), write(Patrimonio),
    write(' | dinero='), write(Dinero),
    write(' | valor_props='), write(ValorProps),
    write(' | num_props='), writeln(NumProps),
    Pos1 is Pos + 1,
    mostrar_ranking_lista(Resto, Pos1).

/*
mostrar_metricas(+Metricas)
Imprime métricas acumuladas de la simulación.
*/
mostrar_metricas(metricas(IterRev, IterTotal, Compras, Alquileres, Bancarrotas)) :-
    reverse(IterRev, IterPorTurno),
    writeln('Metricas:'),
    write('  Iteraciones por turno: '), writeln(IterPorTurno),
    write('  Iteraciones totales: '), writeln(IterTotal),
    write('  Compras: '), writeln(Compras),
    write('  Alquileres: '), writeln(Alquileres),
    write('  Bancarrotas/eliminaciones: '), writeln(Bancarrotas).

/*
mostrar_cabecera(+Titulo)
Cabecera uniforme para escenarios y validaciones.
*/
mostrar_cabecera(Titulo) :-
    writeln('================================'),
    writeln(Titulo),
    writeln('================================').

% ============================================================
% ESCENARIOS DEL PROYECTO
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

/*
Escenario 2:
- Ana ya posee el monopolio marrón.
- Sirve para verificar la detección de monopolio.
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

/*
Escenario 3:
- Ana empieza con dinero muy bajo.
- Bob ya es dueño de marron1.
- Ana cae en marron1, paga alquiler y entra en bancarrota.
*/
estado_inicial(esc3,
    estado(
        [ jugador(ana, 0, 5, []),
          jugador(bob, 0, 1500, [marron1])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc3, [1]).

/*
Escenario 4:
- alquileres consecutivos y simétricos
- ambos jugadores terminan con el mismo dinero inicial
*/
estado_inicial(esc4,
    estado(
        [ jugador(ana, 0, 1340, [celeste2, marron2]),
          jugador(bob, 0, 1340, [celeste1, marron1])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc4, [1,3,5,5]).

/*
Escenario 5:
- simulación completa de 10 turnos legacy
- integra movimiento, compra, alquiler, ranking y métricas
*/
estado_inicial(esc5,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc5, [1,3,5,5,2,1,1,3,3,4]).

/*
Escenario 6:
- doble simple
- permite comprobar que el jugador repite turno y que se conserva estado_turno
*/
estado_inicial(esc6,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc6, [tirada(3,3)]).

/*
Escenario 7:
- tres dobles seguidos del mismo jugador
- en la tercera tirada va a la cárcel
*/
estado_inicial(esc7,
    estado(
        [ jugador(ana, 0, 1500, []),
          jugador(bob, 0, 1500, [])
        ],
        Tablero,
        0
    )
) :-
    tablero_base(Tablero).

tiradas_escenario(esc7, [tirada(1,1), tirada(2,2), tirada(3,3)]).

% ============================================================
% EJECUCIÓN GENERAL DE ESCENARIOS
% ============================================================

/*
ejecutar_escenario(+IdEscenario, -EstadoFinal)
Ejecuta el escenario e imprime estado, monopolios, ranking y métricas.
*/
ejecutar_escenario(IdEscenario, EstadoFinal) :-
    ejecutar_escenario_metricas(IdEscenario, EstadoFinal, _Metricas).

/*
ejecutar_escenario_metricas(+IdEscenario, -EstadoFinal, -Metricas)
Versión que también devuelve las métricas acumuladas.
*/
ejecutar_escenario_metricas(IdEscenario, EstadoFinal, Metricas) :-
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

    simular_turnos_con_reglas_metricas(EstadoInicial, Tiradas, EstadoFinal, Metricas),

    writeln('ESTADO FINAL'),
    writeln('--------------------------------'),
    mostrar_estado(EstadoFinal), nl,

    writeln('MONOPOLIOS FINALES'),
    writeln('--------------------------------'),
    mostrar_monopolios(EstadoFinal), nl,

    writeln('RANKING FINAL'),
    writeln('--------------------------------'),
    mostrar_ranking(EstadoFinal), nl,

    writeln('METRICAS'),
    writeln('--------------------------------'),
    mostrar_metricas(Metricas), nl,

    writeln('================================').

% ============================================================
% VALIDACIONES MANUALES RÁPIDAS
% ============================================================

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

validar_turno_base :-
    estado_inicial(E0),
    mostrar_cabecera('VALIDACION: turno_base/3'), nl,

    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,

    turno_base(E0, 7, E1),

    writeln('Tras turno_base con tirada 7:'),
    mostrar_estado(E1),
    writeln('================================').

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

validar_doble_simple :-
    mostrar_cabecera('VALIDACION: doble simple'), nl,
    estado_inicial(esc6, E0),
    tiradas_escenario(esc6, Tiradas),
    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,
    writeln('Tiradas:'),
    writeln(Tiradas), nl,
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),
    writeln('Estado final:'),
    mostrar_estado(EFinal), nl,
    writeln('Metricas:'),
    mostrar_metricas(Metricas),
    writeln('================================').

validar_tercer_doble_carcel :-
    mostrar_cabecera('VALIDACION: tercer doble a carcel'), nl,
    estado_inicial(esc7, E0),
    tiradas_escenario(esc7, Tiradas),
    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,
    writeln('Tiradas:'),
    writeln(Tiradas), nl,
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),
    writeln('Estado final:'),
    mostrar_estado(EFinal), nl,
    writeln('Metricas:'),
    mostrar_metricas(Metricas),
    writeln('================================').
