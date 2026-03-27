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
    mostrar_metricas(Metricas),
    
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

% ============================================================
% ESCENARIO 3 — BANCARROTA CONTROLADA POR ALQUILER
% ============================================================

/*
Escenario 3:
- Ana empieza con dinero muy bajo
- Bob ya es dueño de marron1
- Ana cae en marron1 y debe pagar alquiler
- El pago la deja con dinero negativo
- Se activa la Regla 3 (Bancarrota) y Ana es eliminada

Detalle:
- alquiler(marron1) = 60 // 10 = 6
- Ana empieza con 5
- Tras pagar 6 -> queda con -1
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



% ============================================================
% ESCENARIO 4 — ALQUILERES CONSECUTIVOS
% ============================================================

/*
Escenario 4:
- 2 jugadores
- varias propiedades ya tienen dueño
- las tiradas fuerzan varios alquileres consecutivos

Diseño:
- Bob posee marron1 y celeste1
- Ana posee marron2 y celeste2
- Secuencia de tiradas:
    Ana: 1  -> cae en marron1 (de Bob)     -> paga alquiler
    Bob: 3  -> cae en marron2 (de Ana)     -> paga alquiler
    Ana: 5  -> cae en celeste1 (de Bob)    -> paga alquiler
    Bob: 5  -> cae en celeste2 (de Ana)    -> paga alquiler

Alquileres esperados:
- marron1: 60 // 10 = 6
- marron2: 60 // 10 = 6
- celeste1: 100 // 10 = 10
- celeste2: 100 // 10 = 10

Resultado esperado:
- Se producen 4 alquileres consecutivos
- Las transferencias son coherentes
- Ambos jugadores acaban con el mismo dinero con el que empezaron
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
validar_alquileres_esc4/0
Ejecuta el escenario 4 y permite comprobar visualmente que:
- se encadenan varios alquileres
- las posiciones finales son correctas
- el dinero final es consistente
*/
validar_alquileres_esc4 :-
    mostrar_cabecera('VALIDACION: alquileres consecutivos en esc4'), nl,

    estado_inicial(esc4, E0),
    tiradas_escenario(esc4, Tiradas),

    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,

    writeln('Tiradas:'),
    writeln(Tiradas), nl,

    simular_turnos_con_reglas(E0, Tiradas, EFinal),

    writeln('Estado final:'),
    mostrar_estado(EFinal), nl,

    writeln('Monopolios finales:'),
    mostrar_monopolios(EFinal), nl,

    writeln('Comprobacion esperada:'),
    writeln('  - Ana termina en posicion 6'),
    writeln('  - Bob termina en posicion 8'),
    writeln('  - Ambos terminan con 1340'),
    writeln('================================').


/*
validar_alquileres_esc4_ok/0
Valida exactamente el estado final esperado del escenario 4.
*/
validar_alquileres_esc4_ok :-
    estado_inicial(esc4, E0),
    tiradas_escenario(esc4, Tiradas),
    simular_turnos_con_reglas(E0, Tiradas, EFinal),

    EFinal = estado(
        [ jugador(ana, 6, 1340, [celeste2, marron2]),
          jugador(bob, 8, 1340, [celeste1, marron1])
        ],
        _Tablero,
        0
    ).


validar_metricas_esc4 :-
    mostrar_cabecera('VALIDACION: metricas en esc4'), nl,
    estado_inicial(esc4, E0),
    tiradas_escenario(esc4, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),

    writeln('Estado final:'),
    mostrar_estado(EFinal), nl,

    writeln('Metricas obtenidas:'),
    mostrar_metricas(Metricas),
    writeln('================================').

% ============================================================
% ESCENARIO 5 — SIMULACIÓN COMPLETA DE 10 TURNOS
% ============================================================

/*
Escenario 5:
- 2 jugadores desde estado inicial normal
- 10 turnos consecutivos
- integra:
    * movimiento
    * compras
    * alquileres
    * motor iterativo de reglas
    * sistema de turnos
    * métricas

Secuencia de tiradas:
1) Ana: 1  -> marron1  -> compra
2) Bob: 3  -> marron2  -> compra
3) Ana: 5  -> celeste1 -> compra
4) Bob: 5  -> celeste2 -> compra
5) Ana: 2  -> celeste2 -> alquiler a Bob
6) Bob: 1  -> celeste3 -> compra
7) Ana: 1  -> celeste3 -> alquiler a Bob
8) Bob: 3  -> servicio1 -> sin efecto
9) Ana: 3  -> servicio1 -> sin efecto
10) Bob: 4 -> naranja1 -> compra
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
validar_esc5/0
Ejecuta el escenario 5 mostrando estado final y métricas.
*/
validar_esc5 :-
    mostrar_cabecera('VALIDACION: esc5 (10 turnos completos)'), nl,

    estado_inicial(esc5, E0),
    tiradas_escenario(esc5, Tiradas),

    writeln('Estado inicial:'),
    mostrar_estado(E0), nl,

    writeln('Tiradas:'),
    writeln(Tiradas), nl,

    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),

    writeln('Estado final:'),
    mostrar_estado(EFinal), nl,

    writeln('Monopolios finales:'),
    mostrar_monopolios(EFinal), nl,

    writeln('Metricas finales:'),
    mostrar_metricas(Metricas),
    writeln('================================').


/*
validar_esc5_ok/0
Valida exactamente el estado final y las métricas esperadas del escenario 5.

Nota:
- add_prop/3 añade al principio de la lista, por eso las propiedades
  aparecen en orden inverso al de adquisición.
*/
validar_esc5_ok :-
    estado_inicial(esc5, E0),
    tiradas_escenario(esc5, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, Metricas),

    EFinal = estado(
        [ jugador(ana, 12, 1318, [celeste1, marron1]),
          jugador(bob, 16, 1062, [naranja1, celeste3, celeste2, marron2])
        ],
        _Tablero,
        0
    ),

    Metricas = metricas(IterRev, 10, 6, 2, 0),
    reverse(IterRev, [1,1,1,1,1,1,1,1,1,1]).

/*
validar_ranking_esc5_ok/0
Valida que el ranking final del escenario 5 sea coherente.
*/
validar_ranking_esc5_ok :-
    estado_inicial(esc5, E0),
    tiradas_escenario(esc5, Tiradas),
    simular_turnos_con_reglas_metricas(E0, Tiradas, EFinal, _Metricas),

    ranking_jugadores(EFinal, Ranking),

    Ranking = [
        ranking(bob, 1522, 1062, 460, 4),
        ranking(ana, 1478, 1318, 160, 2)
    ].