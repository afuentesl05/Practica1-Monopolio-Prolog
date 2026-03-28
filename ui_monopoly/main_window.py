from PySide6.QtCore import Qt, QTimer
from PySide6.QtWidgets import (
    QComboBox,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QProgressBar,
    QScrollArea,
    QSpinBox,
    QSplitter,
    QVBoxLayout,
    QWidget,
)

from .board_widget import BoardWidget, PROPERTY_COLORS, player_color
from .bridge_client import PrologBridgeClient


class InfoCard(QFrame):
    def __init__(self, label: str, accent: str):
        super().__init__()
        self.setObjectName("infoCard")
        self.label = QLabel(label)
        self.label.setObjectName("infoCardLabel")
        self.value = QLabel("--")
        self.value.setObjectName(accent)
        self.value.setWordWrap(True)
        self.value.setProperty("role", "infoCardValue")

        layout = QVBoxLayout(self)
        layout.setContentsMargins(12, 10, 12, 10)
        layout.setSpacing(3)
        layout.addWidget(self.label)
        layout.addWidget(self.value)

    def set_value(self, text: str):
        self.value.setText(text)


class SectionCard(QFrame):
    def __init__(self, title: str):
        super().__init__()
        self.setObjectName("sectionCard")
        layout = QVBoxLayout(self)
        layout.setContentsMargins(12, 12, 12, 12)
        layout.setSpacing(8)

        title_label = QLabel(title)
        title_label.setObjectName("sectionTitle")
        layout.addWidget(title_label)

        self.body_layout = QVBoxLayout()
        self.body_layout.setSpacing(10)
        layout.addLayout(self.body_layout)


class RankingCard(QFrame):
    def __init__(self, entry: dict, leader_value: int, toggle_callback=None):
        super().__init__()
        self.setObjectName("playerCard")
        self.setCursor(Qt.PointingHandCursor)
        self.expanded = False
        self.toggle_callback = toggle_callback

        accent = player_color(entry["player_index"])
        self.accent = accent
        active = entry["active"]
        self.setProperty("active", active)

        rank_label = QLabel(f"#{entry['rank']}")
        rank_label.setObjectName("turnBadge")
        rank_label.setStyleSheet(
            f"background:{accent}; color:#08111d; padding:3px 8px; border-radius:9px; font-size:9px; font-weight:800;"
        )

        name = QLabel(entry["name"])
        name.setObjectName("playerName")

        self.expand_label = QLabel("Ver propiedades")
        self.expand_label.setObjectName("playerDetail")
        self.expand_label.setStyleSheet(f"color:{accent}; font-weight:700; font-size:10px;")

        active_label = QLabel("EN TURNO" if active else "EN ESPERA")
        active_label.setObjectName("turnBadge")
        active_label.setProperty("active", active)

        header = QHBoxLayout()
        header.setContentsMargins(0, 0, 0, 0)
        header.setSpacing(8)
        header.addWidget(rank_label)
        header.addWidget(name)
        header.addStretch()
        header.addWidget(active_label)

        total = QLabel(f"Patrimonio ${entry['net_worth']}")
        total.setObjectName("playerSummary")

        detail = QLabel(
            f"Liquidez ${entry['cash']}  |  Activos ${entry['assets']}  |  Propiedades {entry['properties']}"
        )
        detail.setObjectName("playerDetail")
        detail.setWordWrap(True)

        lead_pct = 0 if leader_value <= 0 else int((entry["net_worth"] / leader_value) * 100)
        lead_bar = QProgressBar()
        lead_bar.setRange(0, 100)
        lead_bar.setValue(max(0, min(100, lead_pct)))
        lead_bar.setFormat(f"{lead_pct}% del lider")
        lead_bar.setStyleSheet(
            """
            QProgressBar {
                min-height: 10px;
                max-height: 10px;
                border: 1px solid #d9ccb7;
                border-radius: 5px;
                background: #efe8db;
                text-align: center;
                color: transparent;
            }
            QProgressBar::chunk {
                border-radius: 4px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #5dd6ff, stop:1 #1f6feb);
            }
            """
        )

        split_label = QLabel(
            f"Distribucion: {entry['cash_pct']}% liquidez  |  {entry['asset_pct']}% activos"
        )
        split_label.setObjectName("playerDetail")
        split_label.setWordWrap(True)

        split_bar = QFrame()
        split_bar.setFixedHeight(10)
        split_bar.setStyleSheet("background:#efe8db; border:1px solid #d9ccb7; border-radius:5px;")

        split_layout = QHBoxLayout(split_bar)
        split_layout.setContentsMargins(1, 1, 1, 1)
        split_layout.setSpacing(0)

        cash_width = max(0, entry["cash_pct"])
        asset_width = max(0, entry["asset_pct"])

        cash_segment = QFrame()
        cash_segment.setStyleSheet("background:#57c7a0; border-radius:4px;")
        asset_segment = QFrame()
        asset_segment.setStyleSheet(f"background:{accent}; border-radius:4px;")
        split_layout.addWidget(cash_segment, cash_width)
        split_layout.addWidget(asset_segment, asset_width)

        self.properties_box = QFrame()
        self.properties_box.setStyleSheet(
            f"background:#faf6ed; border:1px solid {accent}; border-radius:12px;"
        )
        self.properties_box.hide()

        properties_layout = QVBoxLayout(self.properties_box)
        properties_layout.setContentsMargins(10, 8, 10, 8)
        properties_layout.setSpacing(6)

        if entry["property_items"]:
            for item in entry["property_items"]:
                row = QFrame()
                row.setStyleSheet(
                    "background:#fffdf8; border:1px solid #d9ccb7; border-radius:9px;"
                )
                row_layout = QVBoxLayout(row)
                row_layout.setContentsMargins(8, 6, 8, 6)
                row_layout.setSpacing(5)

                name_chip = QLabel(item["name"])
                name_chip.setStyleSheet(
                    f"background:{item['chip_bg']}; color:{item['chip_fg']}; border-radius:8px; padding:2px 8px; font-size:10px; font-weight:800;"
                )
                row_layout.addWidget(name_chip, 0, Qt.AlignLeft)

                badges_row = QHBoxLayout()
                badges_row.setContentsMargins(0, 0, 0, 0)
                badges_row.setSpacing(6)

                if item["badges"]:
                    for badge_text, badge_style in item["badges"]:
                        badge = QLabel(badge_text)
                        badge.setStyleSheet(badge_style)
                        badges_row.addWidget(badge)
                else:
                    clean_badge = QLabel("Sin cargas")
                    clean_badge.setStyleSheet(
                        "background:#eaf4ff; color:#2d6ea3; border-radius:8px; padding:2px 8px; font-size:10px; font-weight:700;"
                    )
                    badges_row.addWidget(clean_badge)

                badges_row.addStretch()
                row_layout.addLayout(badges_row)
                properties_layout.addWidget(row)
        else:
            empty_label = QLabel("Sin propiedades.")
            empty_label.setObjectName("playerDetail")
            properties_layout.addWidget(empty_label)

        stripe = QFrame()
        stripe.setFixedHeight(4)
        stripe.setStyleSheet(f"background-color:{accent}; border-radius:2px;")

        layout = QVBoxLayout(self)
        layout.setContentsMargins(14, 14, 14, 14)
        layout.setSpacing(8)
        layout.addWidget(stripe)
        layout.addLayout(header)
        layout.addWidget(self.expand_label, 0, Qt.AlignLeft)
        layout.addWidget(total)
        layout.addWidget(lead_bar)
        layout.addWidget(split_label)
        layout.addWidget(split_bar)
        layout.addWidget(detail)
        layout.addWidget(self.properties_box)

    def mousePressEvent(self, event):
        if callable(self.toggle_callback):
            self.toggle_callback(self)
        else:
            self.set_expanded(not self.expanded)
        super().mousePressEvent(event)

    def set_expanded(self, expanded: bool):
        self.expanded = expanded
        self.properties_box.setVisible(expanded)
        self.expand_label.setText("Ocultar propiedades" if expanded else "Ver propiedades")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Monopoly Prolog UI")
        self.resize(1720, 960)
        self.setMinimumSize(1420, 820)

        self.client = PrologBridgeClient()
        self.trace_data = None
        self.current_index = 0
        self.current_trace_label = "Sin traza"
        self.expanded_ranking_card = None

        self.timer = QTimer()
        self.timer.timeout.connect(self.next_step)

        self._apply_styles()
        self._build_ui()
        self._load_scenarios()

    def _apply_styles(self):
        self.setStyleSheet(
            """
            QMainWindow, QWidget {
                background: #f3efe4;
                color: #24303f;
                font-size: 12px;
            }

            QLabel {
                background: transparent;
                color: #24303f;
            }

            QComboBox, QSpinBox {
                min-height: 30px;
                background: #fffdf8;
                border: 1px solid #d2c5b0;
                border-radius: 9px;
                padding: 3px 8px;
                color: #24303f;
            }

            QComboBox::drop-down, QSpinBox::drop-down {
                width: 28px;
                border: none;
            }

            QPushButton {
                min-height: 30px;
                background: #fffdf8;
                border: 1px solid #ccbfa8;
                border-radius: 9px;
                padding: 4px 10px;
                font-weight: 700;
                color: #24303f;
            }

            QPushButton:hover {
                background: #f7f1e6;
                border-color: #b7aa95;
            }

            QPushButton:pressed {
                background: #efe6d6;
            }

            QPushButton[variant="primary"] {
                background: #db5b3f;
                border-color: #c04c33;
                color: #fffaf4;
            }

            QPushButton[variant="primary"]:hover {
                background: #e46a4e;
            }

            QPushButton[variant="accent"] {
                background: #1f8f6a;
                border-color: #167557;
                color: #fffdf8;
            }

            QPushButton[variant="danger"] {
                background: #8b2e3d;
                border-color: #d27480;
                color: #fffdf8;
            }

            QSplitter::handle {
                background: #d7ccb9;
                width: 3px;
            }

            QScrollArea {
                border: none;
                background: transparent;
            }

            QProgressBar {
                min-height: 12px;
                max-height: 12px;
                border: 1px solid #c8bba5;
                border-radius: 6px;
                background: #efe8db;
                text-align: center;
                color: #6c5f4c;
            }

            QProgressBar::chunk {
                border-radius: 5px;
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #54c0eb, stop:1 #2b6de0);
            }

            QFrame#heroCard {
                background: #f8f4eb;
                border: 1px solid #d9ccb7;
                border-radius: 14px;
            }

            QLabel#heroEyebrow {
                color: #8b1e24;
                font-size: 8px;
                font-weight: 800;
                letter-spacing: 1px;
            }

            QLabel#heroTitle {
                font-size: 15px;
                font-weight: 900;
                color: #16324b;
            }

            QLabel#heroSubtitle {
                color: #6c6a63;
                font-size: 9px;
            }

            QFrame#controlsCard, QFrame#sectionCard, QFrame#infoCard, QFrame#playerCard {
                background: #fffdf8;
                border: 1px solid #d9ccb7;
                border-radius: 16px;
            }

            QLabel#sectionTitle {
                font-size: 13px;
                font-weight: 800;
                color: #16324b;
            }

            QLabel#infoCardLabel {
                color: #7b7469;
                font-size: 9px;
                font-weight: 700;
                letter-spacing: 0.5px;
            }

            QLabel#infoCardValue {
                color: #16324b;
                font-size: 12px;
                font-weight: 800;
            }

            QLabel[role="infoCardValue"] {
                font-size: 12px;
                font-weight: 800;
            }

            QLabel#accentWarm {
                color: #bc7b00;
            }

            QLabel#accentCold {
                color: #007ea7;
            }

            QLabel#accentGreen {
                color: #18794e;
            }

            QLabel#accentPink {
                color: #b83280;
            }

            QLabel#metaLabel {
                color: #7b7469;
                font-size: 9px;
                font-weight: 700;
                text-transform: uppercase;
            }

            QLabel#stepTitle {
                font-size: 16px;
                font-weight: 900;
                color: #16324b;
            }

            QLabel#stepMeta {
                color: #6b7280;
                font-size: 11px;
            }

            QLabel#playerName {
                font-size: 14px;
                font-weight: 800;
                color: #16324b;
            }

            QLabel#playerSummary {
                color: #2f4359;
                font-size: 11px;
                font-weight: 600;
            }

            QLabel#playerDetail {
                color: #6b7280;
                font-size: 11px;
            }

            QLabel#turnBadge {
                padding: 3px 8px;
                border-radius: 9px;
                background: #e9dfcf;
                color: #5b6574;
                font-size: 9px;
                font-weight: 800;
            }

            QLabel#turnBadge[active="true"] {
                background: #1f6feb;
                color: #fffdf8;
            }

            QFrame#playerCard[active="true"] {
                border: 1px solid #77bdf2;
                background: #fffdf8;
            }
            """
        )

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)

        main_layout = QVBoxLayout(central)
        main_layout.setContentsMargins(8, 8, 8, 8)
        main_layout.setSpacing(6)

        main_layout.addWidget(self._build_hero())
        main_layout.addWidget(self._build_controls())
        main_layout.addLayout(self._build_summary_cards())
        main_layout.addWidget(self._build_main_splitter(), 1)

        self._update_navigation_state()

    def _build_hero(self) -> QWidget:
        card = QFrame()
        card.setObjectName("heroCard")
        layout = QVBoxLayout(card)
        layout.setContentsMargins(12, 7, 12, 7)
        layout.setSpacing(1)

        eyebrow = QLabel("INTERFAZ VISUAL")
        eyebrow.setObjectName("heroEyebrow")

        title = QLabel("Monopoly en Prolog, paso a paso")
        title.setObjectName("heroTitle")

        subtitle = QLabel(
            "Mantenemos intacta la logica del motor y hacemos la lectura de la partida mas clara: "
            "tablero, progreso, turno actual y cambios de estado en una sola vista."
        )
        subtitle.setObjectName("heroSubtitle")
        subtitle.setWordWrap(True)

        layout.addWidget(eyebrow)
        layout.addWidget(title)
        layout.addWidget(subtitle)
        card.setMaximumHeight(58)
        return card

    def _build_controls(self) -> QWidget:
        card = QFrame()
        card.setObjectName("controlsCard")
        layout = QGridLayout(card)
        layout.setContentsMargins(10, 8, 10, 8)
        layout.setHorizontalSpacing(7)
        layout.setVerticalSpacing(4)

        self.scenario_combo = QComboBox()
        self.load_scenario_btn = QPushButton("Cargar escenario")
        self.load_scenario_btn.setProperty("variant", "primary")
        self.load_scenario_btn.style().unpolish(self.load_scenario_btn)
        self.load_scenario_btn.style().polish(self.load_scenario_btn)

        self.random_turns_spin = QSpinBox()
        self.random_turns_spin.setRange(1, 500)
        self.random_turns_spin.setValue(20)

        self.random_btn = QPushButton("Generar partida aleatoria")
        self.random_btn.setProperty("variant", "accent")
        self.random_btn.style().unpolish(self.random_btn)
        self.random_btn.style().polish(self.random_btn)

        self.prev_btn = QPushButton("Anterior")
        self.next_btn = QPushButton("Siguiente")
        self.autoplay_btn = QPushButton("Autoplay")

        layout.addWidget(self._meta_label("Escenario"), 0, 0)
        layout.addWidget(self.scenario_combo, 1, 0, 1, 3)
        layout.addWidget(self.load_scenario_btn, 1, 3)

        layout.addWidget(self._meta_label("Turnos aleatorios"), 0, 4)
        layout.addWidget(self.random_turns_spin, 1, 4)
        layout.addWidget(self.random_btn, 1, 5)

        layout.addWidget(self._meta_label("Navegacion"), 0, 6)
        layout.addWidget(self.prev_btn, 1, 6)
        layout.addWidget(self.next_btn, 1, 7)
        layout.addWidget(self.autoplay_btn, 1, 8)

        layout.setColumnStretch(2, 1)
        card.setMaximumHeight(74)

        self.load_scenario_btn.clicked.connect(self.load_selected_scenario)
        self.random_btn.clicked.connect(self.load_random_trace)
        self.prev_btn.clicked.connect(self.prev_step)
        self.next_btn.clicked.connect(self.next_step)
        self.autoplay_btn.clicked.connect(self.toggle_autoplay)
        return card

    def _build_summary_cards(self):
        layout = QHBoxLayout()
        layout.setSpacing(6)

        self.scenario_card = InfoCard("Escenario", "accentCold")
        self.progress_card = InfoCard("Progreso", "accentWarm")
        self.actor_card = InfoCard("Jugador activo", "accentGreen")
        self.action_card = InfoCard("Accion", "accentPink")

        for card in (self.scenario_card, self.progress_card, self.actor_card, self.action_card):
            layout.addWidget(card)
            card.setMaximumHeight(52)

        return layout

    def _build_main_splitter(self):
        splitter = QSplitter(Qt.Horizontal)

        self.board_widget = BoardWidget()
        board_scroll = QScrollArea()
        board_scroll.setWidgetResizable(True)
        board_scroll.setAlignment(Qt.AlignCenter)
        board_scroll.setWidget(self.board_widget)

        right_panel = QWidget()
        right_panel.setMinimumWidth(370)
        right_panel.setMaximumWidth(420)
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(8)

        step_card = SectionCard("Paso actual")
        self.step_title = QLabel("Carga una traza para comenzar")
        self.step_title.setObjectName("stepTitle")
        self.step_meta = QLabel("El tablero y el resumen se actualizaran conforme avances.")
        self.step_meta.setObjectName("stepMeta")
        self.step_progress = QProgressBar()
        self.step_progress.setRange(0, 100)
        self.step_progress.setValue(0)
        step_card.body_layout.addWidget(self.step_title)
        step_card.body_layout.addWidget(self.step_meta)
        step_card.body_layout.addWidget(self.step_progress)

        ranking_card = SectionCard("Ranking dinamico")
        self.ranking_container = QWidget()
        self.ranking_container.setMinimumWidth(0)
        self.ranking_layout = QVBoxLayout(self.ranking_container)
        self.ranking_layout.setContentsMargins(0, 0, 0, 0)
        self.ranking_layout.setSpacing(10)
        self.ranking_layout.addStretch()

        ranking_scroll = QScrollArea()
        ranking_scroll.setWidgetResizable(True)
        ranking_scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        ranking_scroll.setWidget(self.ranking_container)
        ranking_scroll.setMinimumHeight(430)
        ranking_card.body_layout.addWidget(ranking_scroll)

        right_layout.addWidget(step_card)
        right_layout.addWidget(ranking_card, 1)

        splitter.addWidget(board_scroll)
        splitter.addWidget(right_panel)
        splitter.setSizes([1540, 420])
        return splitter

    @staticmethod
    def _meta_label(text: str) -> QLabel:
        label = QLabel(text)
        label.setObjectName("metaLabel")
        return label

    def _load_scenarios(self):
        try:
            escenarios = self.client.list_scenarios()
            self.scenario_combo.clear()
            for esc in escenarios:
                self.scenario_combo.addItem(f"{esc['id']} - {esc['descripcion']}", esc["id"])
        except Exception as exc:
            QMessageBox.critical(self, "Error", str(exc))

    def load_selected_scenario(self):
        scenario_id = self.scenario_combo.currentData()
        if not scenario_id:
            return

        try:
            self._reset_autoplay()
            self.trace_data = self.client.load_scenario_trace(scenario_id)
            self.current_index = 0
            self.current_trace_label = self.scenario_combo.currentText()
            self.render_current_step()
        except Exception as exc:
            QMessageBox.critical(self, "Error", str(exc))

    def load_random_trace(self):
        num_turns = self.random_turns_spin.value()
        try:
            self._reset_autoplay()
            self.trace_data = self.client.load_random_trace(
                num_players=2,
                start_money=1500,
                num_turns=num_turns,
                mode="real",
            )
            self.current_index = 0
            self.current_trace_label = f"Partida aleatoria ({num_turns} turnos)"
            self.render_current_step()
        except Exception as exc:
            QMessageBox.critical(self, "Error", str(exc))

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
            self.autoplay_btn.setProperty("variant", "")
            self.autoplay_btn.style().unpolish(self.autoplay_btn)
            self.autoplay_btn.style().polish(self.autoplay_btn)

    def toggle_autoplay(self):
        if self.timer.isActive():
            self.timer.stop()
            self.autoplay_btn.setText("Autoplay")
            self.autoplay_btn.setProperty("variant", "")
        else:
            self.timer.start(1200)
            self.autoplay_btn.setText("Pausar")
            self.autoplay_btn.setProperty("variant", "danger")
        self.autoplay_btn.style().unpolish(self.autoplay_btn)
        self.autoplay_btn.style().polish(self.autoplay_btn)

    def _scenario_label(self) -> str:
        return self.current_trace_label

    def _reset_autoplay(self):
        self.timer.stop()
        self.autoplay_btn.setText("Autoplay")
        self.autoplay_btn.setProperty("variant", "")
        self.autoplay_btn.style().unpolish(self.autoplay_btn)
        self.autoplay_btn.style().polish(self.autoplay_btn)

    def _action_title(self, action: dict) -> str:
        action_type = action.get("tipo", "accion")
        if action_type == "tirar":
            tirada = action.get("tirada", {})
            if tirada.get("modo") == "real":
                return f"Tirada {tirada.get('d1', '?')} + {tirada.get('d2', '?')} = {tirada.get('total', '?')}"
            return f"Tirada {tirada.get('total', '?')}"
        if action_type in {"hipotecar", "deshipotecar", "construir_casa", "intentar_construir_casa"}:
            prop = action.get("propiedad", "-")
            return f"{action_type.replace('_', ' ').title()} en {prop}"
        return action_type.replace("_", " ").title()

    def _ranking_entries(self, state: dict, board: list[dict]) -> list[dict]:
        ranking_data = state.get("ranking", [])
        active_name = self._active_player_name(state)
        players_by_name = {
            player["nombre"]: (index, player)
            for index, player in enumerate(state.get("jugadores", []))
        }
        property_styles = {}
        for square in board:
            if square.get("tipo") == "propiedad":
                chip_bg, chip_fg = PROPERTY_COLORS.get(square.get("color"), ("#8fb4ff", "#08111d"))
                property_styles[square["nombre"]] = {
                    "chip_bg": chip_bg,
                    "chip_fg": chip_fg,
                }
        entries = []

        for rank_index, item in enumerate(ranking_data):
            net_worth = item["patrimonio"]
            cash = item["dinero"]
            assets = item["valor_propiedades"]
            cash_pct = 100 if net_worth <= 0 else round((cash / net_worth) * 100)
            asset_pct = 100 - cash_pct if net_worth > 0 else 0
            player_index, player_data = players_by_name.get(item["nombre"], (rank_index, {"propiedades": []}))
            property_items = []
            for prop in player_data.get("propiedades", []):
                badges = []
                if prop["casas"] > 0:
                    house_label = "1 casa" if prop["casas"] == 1 else f"{prop['casas']} casas"
                    badges.append(
                        (
                            house_label,
                            "background:#21452d; color:#8ef0b2; border-radius:8px; padding:2px 8px; font-size:10px; font-weight:700;"
                        )
                    )
                if prop["hipotecada"]:
                    badges.append(
                        (
                            "Hipotecada",
                            "background:#4a2531; color:#ffb3c1; border-radius:8px; padding:2px 8px; font-size:10px; font-weight:700;"
                        )
                    )
                property_items.append(
                    {
                        "name": prop["id"],
                        "badges": badges,
                        "chip_bg": property_styles.get(prop["id"], {}).get("chip_bg", "#8fb4ff"),
                        "chip_fg": property_styles.get(prop["id"], {}).get("chip_fg", "#08111d"),
                    }
                )
            entries.append(
                {
                    "index": rank_index,
                    "player_index": player_index,
                    "name": item["nombre"],
                    "cash": cash,
                    "assets": assets,
                    "net_worth": net_worth,
                    "properties": item["num_propiedades"],
                    "cash_pct": cash_pct,
                    "asset_pct": asset_pct,
                    "active": item["nombre"] == active_name,
                    "property_items": property_items,
                }
            )

        for rank, entry in enumerate(entries, start=1):
            entry["rank"] = rank
        return entries

    def _toggle_ranking_card(self, clicked_card):
        if self.expanded_ranking_card is clicked_card:
            clicked_card.set_expanded(False)
            self.expanded_ranking_card = None
            return

        if self.expanded_ranking_card is not None:
            self.expanded_ranking_card.set_expanded(False)

        clicked_card.set_expanded(True)
        self.expanded_ranking_card = clicked_card

    def _set_ranking(self, state: dict, board: list[dict]):
        self.expanded_ranking_card = None
        while self.ranking_layout.count():
            item = self.ranking_layout.takeAt(0)
            widget = item.widget()
            if widget is not None:
                widget.deleteLater()

        ranking = self._ranking_entries(state, board)
        if not ranking:
            empty = QLabel("Sin datos de jugadores.")
            empty.setObjectName("playerDetail")
            self.ranking_layout.addWidget(empty)
            self.ranking_layout.addStretch()
            return

        leader_value = max(entry["net_worth"] for entry in ranking)
        for entry in ranking:
            self.ranking_layout.addWidget(
                RankingCard(entry, leader_value, toggle_callback=self._toggle_ranking_card)
            )
        self.ranking_layout.addStretch()

    def _update_navigation_state(self):
        has_trace = bool(self.trace_data)
        total_steps = len(self.trace_data["pasos"]) if has_trace else 0
        self.prev_btn.setEnabled(has_trace and self.current_index > 0)
        self.next_btn.setEnabled(has_trace and self.current_index < total_steps)
        self.autoplay_btn.setEnabled(has_trace and total_steps > 0)

    def render_current_step(self):
        if not self.trace_data:
            return

        board = self.trace_data["tablero"]
        steps = self.trace_data["pasos"]
        total_steps = len(steps)

        if self.current_index == 0:
            state = self.trace_data["estado_inicial"]
            current_step = None
            self.step_title.setText("Estado inicial")
            self.step_meta.setText(
                f"Preparado para reproducir {total_steps} pasos. Usa Siguiente o activa Autoplay."
            )
            progress_value = 0
            progress_text = f"0 / {total_steps} pasos"
            actor_text = self._active_player_name(state)
            action_text = "Esperando primer movimiento"
        else:
            current_step = steps[self.current_index - 1]
            state = current_step["estado_despues"]
            actor_text = current_step["resumen"].get("actor", "-")
            action_text = self._action_title(current_step["accion"])
            progress_value = int((self.current_index / max(total_steps, 1)) * 100)
            progress_text = f"{self.current_index} / {total_steps} pasos"
            self.step_title.setText(f"Paso {current_step['num_paso']}")
            self.step_meta.setText(
                f"{actor_text} ejecuta la accion actual y deja el estado listo para "
                f"{self._active_player_name(state)}."
            )

        self.scenario_card.set_value(self._scenario_label())
        self.progress_card.set_value(progress_text)
        self.actor_card.set_value(actor_text)
        self.action_card.set_value(action_text)
        self.step_progress.setValue(progress_value)

        self._set_ranking(state, board)

        context = {
            "step_title": self.step_title.text(),
            "progress": progress_text,
            "active_player": self._active_player_name(state),
            "action": action_text,
        }
        self.board_widget.render_state(board, state, context=context)
        self._update_navigation_state()

    @staticmethod
    def _active_player_name(state: dict) -> str:
        turn = state.get("turno", -1)
        players = state.get("jugadores", [])
        if 0 <= turn < len(players):
            return players[turn]["nombre"]
        return "-"

    @staticmethod
    def _escape(text) -> str:
        value = str(text)
        return (
            value.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
        )
