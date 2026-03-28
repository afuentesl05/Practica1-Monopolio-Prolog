from __future__ import annotations

from collections import Counter
from statistics import mean

from PySide6.QtCore import Qt
from PySide6.QtGui import QColor
from PySide6.QtWidgets import (
    QComboBox,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QHeaderView,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QSpinBox,
    QTableWidget,
    QTableWidgetItem,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from .bridge_client import BatchBridgeClient


def money(value: int | None) -> str:
    if value is None:
        return "-"
    return f"${value}"


class StatCard(QFrame):
    def __init__(self, label: str, accent: str) -> None:
        super().__init__()
        self.setObjectName("StatCard")
        self.setProperty("accent", accent)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(18, 16, 18, 14)
        layout.setSpacing(4)

        self.label = QLabel(label)
        self.label.setObjectName("StatLabel")

        self.value = QLabel("--")
        self.value.setObjectName("StatValue")

        self.subtext = QLabel("")
        self.subtext.setObjectName("StatSubtext")
        self.subtext.setWordWrap(True)

        layout.addWidget(self.label)
        layout.addWidget(self.value)
        layout.addWidget(self.subtext)
        layout.addStretch(1)

    def set_content(self, value: str, subtext: str = "") -> None:
        self.value.setText(value)
        self.subtext.setText(subtext)


class BatchMainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.bridge = BatchBridgeClient()
        self.batch_result: dict | None = None

        self.setWindowTitle("Monopoly Prolog Batch Analytics")
        self._build_ui()
        self._apply_styles()

    def _build_ui(self) -> None:
        root = QWidget()
        self.setCentralWidget(root)

        outer = QVBoxLayout(root)
        outer.setContentsMargins(20, 18, 20, 18)
        outer.setSpacing(14)

        hero = QFrame()
        hero.setObjectName("HeroCard")
        hero_layout = QVBoxLayout(hero)
        hero_layout.setContentsMargins(22, 18, 22, 18)
        hero_layout.setSpacing(3)

        eyebrow = QLabel("ANALISIS DE SIMULACIONES")
        eyebrow.setObjectName("Eyebrow")
        title = QLabel("Banco de partidas aleatorias")
        title.setObjectName("Title")
        subtitle = QLabel(
            "Ejecuta N simulaciones completas con el motor en Prolog y revisa cuantas "
            "terminan, como se reparte la riqueza y quien domina el ranking final."
        )
        subtitle.setObjectName("Subtitle")
        subtitle.setWordWrap(True)

        hero_layout.addWidget(eyebrow)
        hero_layout.addWidget(title)
        hero_layout.addWidget(subtitle)
        outer.addWidget(hero)

        controls = QFrame()
        controls.setObjectName("PanelCard")
        controls_layout = QGridLayout(controls)
        controls_layout.setContentsMargins(18, 16, 18, 16)
        controls_layout.setHorizontalSpacing(14)
        controls_layout.setVerticalSpacing(12)

        self.simulations_input = self._spinbox(100, 1, 10000)
        self.players_input = self._spinbox(2, 2, 8)
        self.money_input = self._spinbox(1500, 0, 100000)
        self.turns_input = self._spinbox(100, 1, 5000)

        self.mode_input = QComboBox()
        self.mode_input.addItem("Real (2 dados)", "real")
        self.mode_input.addItem("Legacy (suma 2-12)", "legacy")

        self.run_button = QPushButton("Ejecutar simulaciones")
        self.run_button.setObjectName("PrimaryButton")
        self.run_button.clicked.connect(self._run_batch)

        controls_layout.addWidget(self._field("Simulaciones", self.simulations_input), 0, 0)
        controls_layout.addWidget(self._field("Jugadores", self.players_input), 0, 1)
        controls_layout.addWidget(self._field("Dinero inicial", self.money_input), 0, 2)
        controls_layout.addWidget(self._field("Turnos maximos", self.turns_input), 0, 3)
        controls_layout.addWidget(self._field("Modo de tirada", self.mode_input), 0, 4)
        controls_layout.addWidget(self.run_button, 0, 5, alignment=Qt.AlignBottom)
        controls_layout.setColumnStretch(5, 1)
        outer.addWidget(controls)

        stats_row = QHBoxLayout()
        stats_row.setSpacing(12)
        self.total_card = StatCard("Simulaciones", "blue")
        self.finished_card = StatCard("Finalizadas", "green")
        self.pending_card = StatCard("No finalizadas", "orange")
        self.turns_card = StatCard("Media de turnos", "gold")
        self.bankruptcies_card = StatCard("Bancarrotas medias", "rose")

        for card in (
            self.total_card,
            self.finished_card,
            self.pending_card,
            self.turns_card,
            self.bankruptcies_card,
        ):
            stats_row.addWidget(card, 1)
        outer.addLayout(stats_row)

        body = QHBoxLayout()
        body.setSpacing(14)

        left_column = QVBoxLayout()
        left_column.setSpacing(12)

        table_card = QFrame()
        table_card.setObjectName("PanelCard")
        table_layout = QVBoxLayout(table_card)
        table_layout.setContentsMargins(16, 14, 16, 16)
        table_layout.setSpacing(10)

        table_title = QLabel("Resultados individuales")
        table_title.setObjectName("SectionTitle")

        self.results_table = QTableWidget(0, 10)
        self.results_table.setHorizontalHeaderLabels(
            [
                "#",
                "Estado",
                "Turnos",
                "Restantes",
                "Ganador",
                "Lider final",
                "Patrimonio lider",
                "Compras",
                "Alquileres",
                "Bancarrotas",
            ]
        )
        self.results_table.verticalHeader().setVisible(False)
        self.results_table.setSelectionBehavior(QTableWidget.SelectRows)
        self.results_table.setEditTriggers(QTableWidget.NoEditTriggers)
        self.results_table.setAlternatingRowColors(True)
        self.results_table.setWordWrap(False)
        self.results_table.setSortingEnabled(False)
        self.results_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.results_table.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeToContents)
        self.results_table.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeToContents)
        self.results_table.horizontalHeader().setSectionResizeMode(2, QHeaderView.ResizeToContents)
        self.results_table.horizontalHeader().setSectionResizeMode(3, QHeaderView.ResizeToContents)
        self.results_table.itemSelectionChanged.connect(self._show_selected_simulation)

        table_layout.addWidget(table_title)
        table_layout.addWidget(self.results_table, 1)
        left_column.addWidget(table_card, 1)

        right_column = QVBoxLayout()
        right_column.setSpacing(12)

        overview_card = QFrame()
        overview_card.setObjectName("PanelCard")
        overview_layout = QVBoxLayout(overview_card)
        overview_layout.setContentsMargins(16, 14, 16, 16)
        overview_layout.setSpacing(10)

        overview_title = QLabel("Lectura agregada")
        overview_title.setObjectName("SectionTitle")
        self.overview_text = QTextEdit()
        self.overview_text.setReadOnly(True)
        self.overview_text.setMinimumHeight(240)

        overview_layout.addWidget(overview_title)
        overview_layout.addWidget(self.overview_text)

        detail_card = QFrame()
        detail_card.setObjectName("PanelCard")
        detail_layout = QVBoxLayout(detail_card)
        detail_layout.setContentsMargins(16, 14, 16, 16)
        detail_layout.setSpacing(10)

        detail_title = QLabel("Detalle de simulacion")
        detail_title.setObjectName("SectionTitle")
        self.detail_text = QTextEdit()
        self.detail_text.setReadOnly(True)
        self.detail_text.setMinimumHeight(320)

        detail_layout.addWidget(detail_title)
        detail_layout.addWidget(self.detail_text)

        right_column.addWidget(overview_card)
        right_column.addWidget(detail_card, 1)

        body.addLayout(left_column, 7)
        body.addLayout(right_column, 4)
        outer.addLayout(body, 1)

        self._set_empty_state()

    def _spinbox(self, value: int, minimum: int, maximum: int) -> QSpinBox:
        box = QSpinBox()
        box.setRange(minimum, maximum)
        box.setValue(value)
        box.setButtonSymbols(QSpinBox.PlusMinus)
        return box

    def _field(self, label: str, widget: QWidget) -> QWidget:
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(6)

        field_label = QLabel(label)
        field_label.setObjectName("FieldLabel")
        layout.addWidget(field_label)
        layout.addWidget(widget)
        return container

    def _set_empty_state(self) -> None:
        self.total_card.set_content("--", "Configura un lote y lanzalo.")
        self.finished_card.set_content("--", "Veremos cuantas partidas alcanzan un final.")
        self.pending_card.set_content("--", "Control de partidas que agotan el limite.")
        self.turns_card.set_content("--", "Media de duracion del lote.")
        self.bankruptcies_card.set_content("--", "Intensidad media de bancarrotas.")
        self.overview_text.setPlainText(
            "Esta vista resume bancos de simulaciones completas ejecutadas sobre el motor en Prolog.\n\n"
            "Pulsa 'Ejecutar simulaciones' para rellenar el panel con metricas agregadas y "
            "comparar partidas individuales."
        )
        self.detail_text.setPlainText(
            "Selecciona una fila del resultado para inspeccionar el ranking final de esa simulacion, "
            "sus metricas y si la partida llego o no a terminar."
        )

    def _run_batch(self) -> None:
        self.run_button.setEnabled(False)
        self.run_button.setText("Ejecutando...")
        try:
            result = self.bridge.run_batch(
                simulations=self.simulations_input.value(),
                players=self.players_input.value(),
                start_money=self.money_input.value(),
                max_turns=self.turns_input.value(),
                mode=self.mode_input.currentData(),
            )
        except Exception as exc:
            QMessageBox.critical(
                self,
                "Error ejecutando simulaciones",
                str(exc),
            )
            return
        finally:
            self.run_button.setEnabled(True)
            self.run_button.setText("Ejecutar simulaciones")

        self.batch_result = result
        self._populate_ui(result)

    def _populate_ui(self, result: dict) -> None:
        simulations = result.get("simulaciones", [])
        summary = self._build_summary(simulations)

        self.total_card.set_content(str(summary["total"]), summary["config"])
        self.finished_card.set_content(
            str(summary["finished"]),
            f"{summary['finished_ratio']:.1f}% del lote finaliza antes del limite.",
        )
        self.pending_card.set_content(
            str(summary["unfinished"]),
            f"{summary['unfinished_ratio']:.1f}% agota turnos sin cerrar la partida.",
        )
        self.turns_card.set_content(
            f"{summary['avg_turns']:.1f}",
            f"Media entre {summary['min_turns']} y {summary['max_turns']} turnos.",
        )
        self.bankruptcies_card.set_content(
            f"{summary['avg_bankruptcies']:.2f}",
            f"Compras medias {summary['avg_buys']:.1f} | Alquileres medios {summary['avg_rents']:.1f}",
        )

        self._populate_table(simulations)
        self.overview_text.setHtml(self._overview_html(summary))

        if simulations:
            self.results_table.selectRow(0)
            self._show_selected_simulation()
        else:
            self.detail_text.setPlainText("No se han devuelto simulaciones.")

    def _build_summary(self, simulations: list[dict]) -> dict:
        total = len(simulations)
        finished = sum(1 for item in simulations if item.get("finalizada"))
        unfinished = total - finished
        turns = [item.get("turnos_jugados", 0) for item in simulations]
        metrics = [item.get("metricas", {}) for item in simulations]
        winners = [item.get("ganador") for item in simulations if item.get("ganador")]
        leaders = [item.get("lider") for item in simulations if item.get("lider")]

        top_winner = Counter(winners).most_common(1)
        top_leader = Counter(leaders).most_common(1)

        config = (
            f"{self.players_input.value()} jugadores | {self.turns_input.value()} turnos max. | "
            f"{self.mode_input.currentText()}"
        )

        return {
            "total": total,
            "finished": finished,
            "unfinished": unfinished,
            "finished_ratio": (finished / total * 100) if total else 0,
            "unfinished_ratio": (unfinished / total * 100) if total else 0,
            "avg_turns": mean(turns) if turns else 0,
            "min_turns": min(turns) if turns else 0,
            "max_turns": max(turns) if turns else 0,
            "avg_bankruptcies": mean(m.get("bancarrotas", 0) for m in metrics) if metrics else 0,
            "avg_buys": mean(m.get("compras", 0) for m in metrics) if metrics else 0,
            "avg_rents": mean(m.get("alquileres", 0) for m in metrics) if metrics else 0,
            "top_winner": top_winner[0] if top_winner else None,
            "top_leader": top_leader[0] if top_leader else None,
            "config": config,
        }

    def _populate_table(self, simulations: list[dict]) -> None:
        self.results_table.setRowCount(len(simulations))

        for row, item in enumerate(simulations):
            metrics = item.get("metricas", {})
            status = "Finalizada" if item.get("finalizada") else "Limite"
            values = [
                str(item.get("id", "-")),
                status,
                str(item.get("turnos_jugados", 0)),
                str(item.get("jugadores_restantes", "-")),
                item.get("ganador") or "-",
                item.get("lider") or "-",
                money(item.get("patrimonio_lider")),
                str(metrics.get("compras", 0)),
                str(metrics.get("alquileres", 0)),
                str(metrics.get("bancarrotas", 0)),
            ]
            for column, value in enumerate(values):
                table_item = QTableWidgetItem(value)
                if column in (0, 2, 3, 7, 8, 9):
                    table_item.setTextAlignment(Qt.AlignCenter)
                self.results_table.setItem(row, column, table_item)

            color = QColor("#e6f7ea" if item.get("finalizada") else "#fff1df")
            for column in range(self.results_table.columnCount()):
                self.results_table.item(row, column).setBackground(color)

        self.results_table.resizeRowsToContents()

    def _overview_html(self, summary: dict) -> str:
        winner_line = (
            f"<b>Ganador mas frecuente:</b> {summary['top_winner'][0]} "
            f"({summary['top_winner'][1]} partidas)<br>"
            if summary["top_winner"]
            else "<b>Ganador mas frecuente:</b> Ninguno todavia<br>"
        )
        leader_line = (
            f"<b>Lider final mas frecuente:</b> {summary['top_leader'][0]} "
            f"({summary['top_leader'][1]} partidas)<br>"
            if summary["top_leader"]
            else "<b>Lider final mas frecuente:</b> Sin datos<br>"
        )
        return (
            "<div style='line-height:1.55'>"
            f"<b>Configuracion:</b> {summary['config']}<br>"
            f"<b>Partidas finalizadas:</b> {summary['finished']} de {summary['total']} "
            f"({summary['finished_ratio']:.1f}%)<br>"
            f"<b>Partidas no finalizadas:</b> {summary['unfinished']} de {summary['total']} "
            f"({summary['unfinished_ratio']:.1f}%)<br>"
            f"<b>Duracion media:</b> {summary['avg_turns']:.1f} turnos<br>"
            f"<b>Bancarrotas medias:</b> {summary['avg_bankruptcies']:.2f}<br>"
            f"<b>Compras medias:</b> {summary['avg_buys']:.1f}<br>"
            f"<b>Alquileres medios:</b> {summary['avg_rents']:.1f}<br>"
            f"{winner_line}"
            f"{leader_line}"
            "<br><b>Lectura rapida:</b> usa la tabla para bajar a cada simulacion concreta y "
            "comparar si el lote se resuelve por eliminacion o por agotamiento del limite de turnos."
            "</div>"
        )

    def _show_selected_simulation(self) -> None:
        row = self.results_table.currentRow()
        if row < 0 or not self.batch_result:
            return

        simulations = self.batch_result.get("simulaciones", [])
        if row >= len(simulations):
            return

        sim = simulations[row]
        metrics = sim.get("metricas", {})
        ranking = sim.get("ranking_final", [])
        ranking_lines = []
        for pos, entry in enumerate(ranking, start=1):
            ranking_lines.append(
                f"{pos}. {entry.get('nombre', '-')}: patrimonio {money(entry.get('patrimonio'))}, "
                f"liquidez {money(entry.get('dinero'))}, propiedades {entry.get('num_propiedades', 0)}"
            )

        ranking_text = "\n".join(ranking_lines) if ranking_lines else "Sin ranking disponible."
        status = "finalizada" if sim.get("finalizada") else "no finalizada"
        detail = (
            f"Simulacion #{sim.get('id', '-')}\n"
            f"Estado: {status}\n"
            f"Turnos jugados: {sim.get('turnos_jugados', 0)} / {sim.get('turnos_limite', 0)}\n"
            f"Jugadores restantes: {sim.get('jugadores_restantes', '-')}\n"
            f"Ganador: {sim.get('ganador') or '-'}\n"
            f"Lider final: {sim.get('lider') or '-'}\n"
            f"Patrimonio lider: {money(sim.get('patrimonio_lider'))}\n"
            f"Liquidez lider: {money(sim.get('dinero_lider'))}\n"
            f"Valor propiedades lider: {money(sim.get('valor_propiedades_lider'))}\n\n"
            "Metricas:\n"
            f"- Compras: {metrics.get('compras', 0)}\n"
            f"- Alquileres: {metrics.get('alquileres', 0)}\n"
            f"- Bancarrotas: {metrics.get('bancarrotas', 0)}\n"
            f"- Iteraciones totales: {metrics.get('iter_total', 0)}\n\n"
            "Ranking final:\n"
            f"{ranking_text}"
        )
        self.detail_text.setPlainText(detail)

    def _apply_styles(self) -> None:
        self.setStyleSheet(
            """
            QMainWindow, QWidget {
                background: #f3efe4;
                color: #203243;
                font-family: "Segoe UI";
                font-size: 13px;
            }
            QFrame#HeroCard, QFrame#PanelCard, QFrame#StatCard {
                background: #fffdf8;
                border: 1px solid #d8ccb9;
                border-radius: 18px;
            }
            QLabel#Eyebrow {
                color: #6a7c8f;
                font-size: 11px;
                font-weight: 700;
                letter-spacing: 1px;
            }
            QLabel#Title {
                color: #16324b;
                font-size: 28px;
                font-weight: 800;
            }
            QLabel#Subtitle {
                color: #5f6c79;
                font-size: 13px;
            }
            QLabel#FieldLabel, QLabel#StatLabel {
                color: #6c7a88;
                font-size: 11px;
                font-weight: 700;
                letter-spacing: 0.8px;
            }
            QLabel#StatValue {
                color: #18354f;
                font-size: 24px;
                font-weight: 800;
            }
            QLabel#StatSubtext {
                color: #6c7a88;
                font-size: 12px;
            }
            QLabel#SectionTitle {
                color: #18354f;
                font-size: 18px;
                font-weight: 800;
            }
            QSpinBox, QComboBox, QTextEdit, QTableWidget {
                background: #fffaf1;
                border: 1px solid #d7cab5;
                border-radius: 12px;
                padding: 8px 10px;
                selection-background-color: #d7ebff;
                selection-color: #18354f;
            }
            QSpinBox::up-button, QSpinBox::down-button {
                width: 18px;
                border: none;
                background: transparent;
            }
            QComboBox::drop-down {
                border: none;
                width: 24px;
            }
            QPushButton#PrimaryButton {
                background: #1f7a5c;
                color: white;
                font-weight: 700;
                border: none;
                border-radius: 14px;
                padding: 12px 18px;
            }
            QPushButton#PrimaryButton:hover {
                background: #17664d;
            }
            QHeaderView::section {
                background: #f0e8da;
                color: #5d6e7e;
                border: none;
                border-bottom: 1px solid #d7cab5;
                padding: 10px 8px;
                font-weight: 700;
            }
            QTableWidget {
                gridline-color: #e8dece;
            }
            QTableWidget::item {
                padding: 8px;
            }
            QScrollBar:vertical {
                background: #f5efe5;
                width: 10px;
                margin: 4px;
            }
            QScrollBar::handle:vertical {
                background: #ccbda6;
                border-radius: 5px;
                min-height: 30px;
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                height: 0px;
            }
            """
        )
