# PLX – Monopoly Reasoning in Prolog

Práctica 1 de la asignatura **Conocimiento y Razonamiento Automatizado (2025-26)**.

## 🎯 Objetivo

Implementar en Prolog una representación simbólica del juego del Monopolio,
centrándose en:

- Manipulación avanzada de listas
- Representación de estados dinámicos
- Aplicación iterativa de reglas
- Razonamiento automatizado
- Control de turnos

No se utilizan librerías externas ni predicados avanzados.
Todo el razonamiento se implementa manualmente con los mecanismos básicos de Prolog.

---

## 🧠 Componentes del sistema

- Representación del tablero (lista de 40 elementos)
- Representación del estado global:
  - Jugadores
  - Turno actual
  - Propiedades
- Simulación de movimiento
- Aplicación de reglas:
  - Compra
  - Alquiler
  - Monopolio
  - Bancarrota
- Iteración por turnos
- Métricas

---

## Estructura

- main.pl
- reglas.pl
- metricas.pl
- Informe.pdf

---

## 👥 Equipo

- Lucía Cantero Anchuelo
- Álvaro Fuentes Lozano
- Rodrigo Rey Henche

---

## 🛠 Entorno

- SWI-Prolog
- VSCode


## 📂 Estructura

PLX-Monopoly-Reasoning/
├─ main.pl
├─ README.md
├─ docs/
│  ├─ Informe.pdf            
│  ├─ minutas/
│  │  ├─ minuta_01.md
│  │  ├─ minuta_02.md
│  │  └─ minuta_03.md
│  └─ enunciado/
│     └─ Practica1_2025-26.pdf  
├─ tests/
│  └─ main_test.pl          
└─ .gitignore

