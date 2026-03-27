import json
from PySide6.QtCore import Qt, QTimer
from PySide6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton,
    QLabel, QComboBox, QSpinBox, QPlainTextEdit, QMessageBox, QSplitter
)

from .bridge_client import PrologBridgeClient
from .board_widget import BoardWidget

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Monopoly Prolog UI")
        self.resize(1720, 960)
        self.setMinimumSize(1400, 820)
        self.setStyleSheet("""
            QMainWindow, QWidget {
                background-color: #111418;
                color: #EAEFF5;
                font-size: 12px;
            }

            QLabel {
                color: #EAEFF5;
            }

            QComboBox, QSpinBox, QPlainTextEdit {
                background-color: #1C2128;
                color: #EAEFF5;
                border: 1px solid #3A4552;
                border-radius: 6px;
                padding: 6px;
            }

            QPushButton {
                background-color: #26303A;
                color: #F5F7FA;
                border: 1px solid #3F4D5C;
                border-radius: 6px;
                padding: 8px 12px;
                font-weight: 700;
            }

            QPushButton:hover {
                background-color: #324050;
            }

            QPushButton:pressed {
                background-color: #1E2933;
            }

            QSplitter::handle {
                background-color: #26303A;
                width: 2px;
            }
        """)

        self.client = PrologBridgeClient()
        self.trace_data = None
        self.current_index = 0

        self.timer = QTimer()
        self.timer.timeout.connect(self.next_step)

        self._build_ui()
        self._load_scenarios()

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)

        main_layout = QVBoxLayout()
        central.setLayout(main_layout)

        # Barra superior
        top_bar = QHBoxLayout()

        self.scenario_combo = QComboBox()
        self.load_scenario_btn = QPushButton("Cargar escenario")

        self.random_turns_spin = QSpinBox()
        self.random_turns_spin.setRange(1, 500)
        self.random_turns_spin.setValue(20)

        self.random_btn = QPushButton("Partida aleatoria")

        self.prev_btn = QPushButton("Anterior")
        self.next_btn = QPushButton("Siguiente")
        self.autoplay_btn = QPushButton("Autoplay")

        top_bar.addWidget(QLabel("Escenario:"))
        top_bar.addWidget(self.scenario_combo)
        top_bar.addWidget(self.load_scenario_btn)
        top_bar.addSpacing(20)
        top_bar.addWidget(QLabel("Turnos aleatorios:"))
        top_bar.addWidget(self.random_turns_spin)
        top_bar.addWidget(self.random_btn)
        top_bar.addSpacing(20)
        top_bar.addWidget(self.prev_btn)
        top_bar.addWidget(self.next_btn)
        top_bar.addWidget(self.autoplay_btn)

        main_layout.addLayout(top_bar)

        # Zona principal
        splitter = QSplitter(Qt.Horizontal)

        self.board_widget = BoardWidget()

        right_panel = QWidget()
        right_layout = QVBoxLayout()
        right_panel.setLayout(right_layout)
        right_panel.setMinimumWidth(300)
        right_panel.setMaximumWidth(380)

        self.step_title = QLabel("Sin traza cargada")
        self.step_title.setStyleSheet("""
            font-size: 22px;
            font-weight: 900;
            color: #FFFFFF;
            padding: 6px 0;
        """)
        self.players_box = QPlainTextEdit()
        self.players_box.setReadOnly(True)

        self.summary_box = QPlainTextEdit()
        self.summary_box.setReadOnly(True)

        self.metrics_box = QPlainTextEdit()
        self.metrics_box.setReadOnly(True)

        for box in (self.players_box, self.summary_box, self.metrics_box):
            box.setStyleSheet("""
                QPlainTextEdit {
                    background-color: #1A1F26;
                    color: #E8EDF3;
                    border: 1px solid #374250;
                    border-radius: 8px;
                    padding: 8px;
                    font-family: Consolas, 'Courier New', monospace;
                    font-size: 12px;
                }
            """)

        right_layout.addWidget(self.step_title)
        right_layout.addWidget(QLabel("Jugadores"))
        right_layout.addWidget(self.players_box, 2)
        right_layout.addWidget(QLabel("Resumen del paso"))
        right_layout.addWidget(self.summary_box, 2)
        right_layout.addWidget(QLabel("Métricas"))
        right_layout.addWidget(self.metrics_box, 1)

        splitter.addWidget(self.board_widget)
        splitter.addWidget(right_panel)
        splitter.setSizes([1380, 320])

        main_layout.addWidget(splitter)

        # Conexiones
        self.load_scenario_btn.clicked.connect(self.load_selected_scenario)
        self.random_btn.clicked.connect(self.load_random_trace)
        self.prev_btn.clicked.connect(self.prev_step)
        self.next_btn.clicked.connect(self.next_step)
        self.autoplay_btn.clicked.connect(self.toggle_autoplay)

    def _load_scenarios(self):
        try:
            escenarios = self.client.list_scenarios()
            self.scenario_combo.clear()
            for esc in escenarios:
                self.scenario_combo.addItem(
                    f"{esc['id']} - {esc['descripcion']}",
                    esc["id"]
                )
        except Exception as e:
            QMessageBox.critical(self, "Error", str(e))

    def load_selected_scenario(self):
        scenario_id = self.scenario_combo.currentData()
        if not scenario_id:
            return

        try:
            self.trace_data = self.client.load_scenario_trace(scenario_id)
            self.current_index = 0
            self.render_current_step()
        except Exception as e:
            QMessageBox.critical(self, "Error", str(e))

    def load_random_trace(self):
        num_turns = self.random_turns_spin.value()
        try:
            self.trace_data = self.client.load_random_trace(
                num_players=2,
                start_money=1500,
                num_turns=num_turns,
                mode="real"
            )
            self.current_index = 0
            self.render_current_step()
        except Exception as e:
            QMessageBox.critical(self, "Error", str(e))

    def prev_step(self):
        if not self.trace_data:
            return
        if self.current_index > 0:
            self.current_index -= 1
            self.render_current_step()

    def next_step(self):
        if not self.trace_data:
            return
        max_index = len(self.trace_data["pasos"])
        if self.current_index < max_index:
            self.current_index += 1
            self.render_current_step()
        else:
            self.timer.stop()
            self.autoplay_btn.setText("Autoplay")

    def toggle_autoplay(self):
        if self.timer.isActive():
            self.timer.stop()
            self.autoplay_btn.setText("Autoplay")
        else:
            self.timer.start(1200)
            self.autoplay_btn.setText("Pausar")

    def _format_players(self, state: dict) -> str:
        lines = []
        for i, player in enumerate(state["jugadores"]):
            activo = " <== TURNO" if i == state["turno"] else ""
            props = []
            for p in player["propiedades"]:
                marca = []
                if p["hipotecada"]:
                    marca.append("H")
                if p["casas"] > 0:
                    marca.append(f"{p['casas']}c")
                suf = f" ({','.join(marca)})" if marca else ""
                props.append(f"{p['id']}{suf}")

            props_txt = ", ".join(props) if props else "-"
            et = player["estado_turno"]
            lines.append(
                f"{player['nombre']}\n"
                f"  pos={player['posicion']} din={player['dinero']}\n"
                f"  estado={et['modo']} carcel={et['turnos_carcel']} dobles={et['dobles_seguidos']}\n"
                f"  props={props_txt}{activo}\n"
            )
        return "\n".join(lines)

    def render_current_step(self):
        if not self.trace_data:
            return

        board = self.trace_data["tablero"]
        pasos = self.trace_data["pasos"]

        if self.current_index == 0:
            state = self.trace_data["estado_inicial"]
            self.step_title.setText("Estado inicial")
            self.summary_box.setPlainText("Aún no se ha ejecutado ninguna acción.")
        else:
            paso = pasos[self.current_index - 1]
            state = paso["estado_despues"]

            accion_txt = json.dumps(paso["accion"], indent=2, ensure_ascii=False)
            resumen_txt = json.dumps(paso["resumen"], indent=2, ensure_ascii=False)
            delta_txt = json.dumps(paso["metricas_delta"], indent=2, ensure_ascii=False)

            self.step_title.setText(f"Paso {paso['num_paso']}")
            self.summary_box.setPlainText(
                "ACCIÓN\n"
                f"{accion_txt}\n\n"
                "RESUMEN\n"
                f"{resumen_txt}\n\n"
                "DELTA MÉTRICAS\n"
                f"{delta_txt}"
            )

        self.board_widget.render_state(board, state)
        self.players_box.setPlainText(self._format_players(state))
        self.metrics_box.setPlainText(
            json.dumps(self.trace_data["metricas_finales"], indent=2, ensure_ascii=False)
        )