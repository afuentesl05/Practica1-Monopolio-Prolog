from PySide6.QtCore import Qt
from PySide6.QtGui import QFont
from PySide6.QtWidgets import QFrame, QGridLayout, QHBoxLayout, QLabel, QSizePolicy, QVBoxLayout, QWidget


PROPERTY_COLORS = {
    "marron": ("#8B5A2B", "#FFFFFF"),
    "celeste": ("#78D7FF", "#08111D"),
    "rosa": ("#FF71B8", "#140916"),
    "naranja": ("#FF9B3F", "#18110A"),
    "rojo": ("#EF4444", "#FFFFFF"),
    "amarillo": ("#F4D35E", "#18150B"),
    "verde": ("#41B883", "#07150F"),
    "azul": ("#4C8DFF", "#FFFFFF"),
}

SPECIAL_TYPE_COLORS = {
    "salida": ("#3CCF91", "#07170F"),
    "carta": ("#A855F7", "#FFFFFF"),
    "impuesto": ("#64748B", "#FFFFFF"),
    "especial": ("#4B5563", "#FFFFFF"),
}

PLAYER_CHIP_COLORS = [
    "#ff8a5b",
    "#43c2ff",
    "#63d471",
    "#ffd166",
    "#f26ca7",
    "#7d8cff",
    "#e879f9",
    "#22d3ee",
]


def short_player(name: str) -> str:
    lowered = name.lower()
    if lowered.startswith("jugador"):
        suffix = lowered.replace("jugador", "")
        return f"J{suffix}" if suffix else "J"
    return name[:3].upper()


def player_color(index: int) -> str:
    return PLAYER_CHIP_COLORS[index % len(PLAYER_CHIP_COLORS)]


class PlayerChip(QLabel):
    def __init__(self, text: str, color: str):
        super().__init__(text)
        self.setAlignment(Qt.AlignCenter)
        self.setStyleSheet(
            f"""
            QLabel {{
                background-color: {color};
                color: #08111D;
                border: 1px solid rgba(36, 48, 63, 0.18);
                border-radius: 10px;
                padding: 2px 7px;
                font-size: 10px;
                font-weight: 900;
            }}
            """
        )


class HouseDot(QLabel):
    def __init__(self):
        super().__init__(" ")
        self.setStyleSheet(
            """
            QLabel {
                background: #4bbf73;
                border: 1px solid #2f8f52;
                border-radius: 5px;
            }
            """
        )


class BoardCell(QFrame):
    def __init__(self):
        super().__init__()
        self.setFrameShape(QFrame.NoFrame)
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)

        self.position_label = QLabel("")
        self.position_label.setAlignment(Qt.AlignLeft | Qt.AlignTop)
        self.position_label.setObjectName("cellPos")
        self.position_label.hide()

        self.title_label = QLabel("")
        self.title_label.setAlignment(Qt.AlignLeft | Qt.AlignVCenter)
        self.title_label.setWordWrap(True)
        self.title_label.setObjectName("cellTitle")

        self.subtitle_label = QLabel("")
        self.subtitle_label.setAlignment(Qt.AlignLeft | Qt.AlignVCenter)
        self.subtitle_label.setWordWrap(False)
        self.subtitle_label.setObjectName("cellSubtitle")

        self.info_label = QLabel("")
        self.info_label.setAlignment(Qt.AlignLeft | Qt.AlignTop)
        self.info_label.setWordWrap(True)
        self.info_label.setObjectName("cellInfo")
        self.info_label.setTextFormat(Qt.PlainText)

        self.houses_layout = QHBoxLayout()
        self.houses_layout.setSpacing(4)
        self.houses_layout.setContentsMargins(0, 0, 0, 0)
        self.houses_layout.addStretch()

        houses_widget = QWidget()
        houses_widget.setLayout(self.houses_layout)

        self.players_layout = QHBoxLayout()
        self.players_layout.setSpacing(4)
        self.players_layout.setContentsMargins(0, 0, 0, 0)
        self.players_layout.addStretch()

        players_widget = QWidget()
        players_widget.setLayout(self.players_layout)

        top_row = QHBoxLayout()
        top_row.setContentsMargins(0, 0, 0, 0)
        top_row.addWidget(houses_widget)
        top_row.addStretch()

        layout = QVBoxLayout(self)
        layout.setContentsMargins(7, 7, 7, 7)
        layout.setSpacing(4)
        layout.addLayout(top_row)
        layout.addWidget(self.title_label)
        layout.addWidget(self.subtitle_label)
        layout.addWidget(self.info_label, 1)
        layout.addWidget(players_widget)
        self.update_density(92, 92)

    def update_density(self, width: int, height: int):
        short_side = max(72, min(width, height))
        long_side = max(width, height)
        padding_h = max(7, width // 14)
        padding_v = max(6, height // 14)
        spacing = max(4, short_side // 20)
        radius = max(8, short_side // 7)
        pos_font = max(8, short_side // 11)
        title_font = max(11, short_side // 7)
        subtitle_font = max(9, short_side // 10)
        info_font = max(9, short_side // 10)
        house_size = max(7, short_side // 10)

        layout = self.layout()
        if layout is not None:
            layout.setContentsMargins(padding_h, padding_v, padding_h, padding_v)
            layout.setSpacing(spacing)

        self.title_label.setFont(QFont("", title_font, QFont.Bold))
        self.subtitle_label.setFont(QFont("", subtitle_font, QFont.DemiBold))
        self.info_label.setFont(QFont("", info_font))

        for layout_row in (self.houses_layout, self.players_layout):
            layout_row.setSpacing(max(3, short_side // 24))

        for i in range(self.houses_layout.count()):
            widget = self.houses_layout.itemAt(i).widget()
            if widget is not None:
                widget.setFixedSize(house_size, house_size)
                widget.setStyleSheet(
                    f"""
                    QLabel {{
                        background: #6ee7b7;
                        border: 1px solid #c8ffe9;
                        border-radius: {house_size // 2}px;
                    }}
                    """
                )

    def _clear_layout_widgets(self, layout: QHBoxLayout):
        while layout.count():
            item = layout.takeAt(0)
            widget = item.widget()
            if widget is not None:
                widget.deleteLater()

    def set_players(self, players: list[str], player_indices: dict[str, int] | None = None):
        self._clear_layout_widgets(self.players_layout)
        player_indices = player_indices or {}
        for fallback_index, player in enumerate(players):
            color_index = player_indices.get(player, fallback_index)
            self.players_layout.addWidget(PlayerChip(short_player(player), player_color(color_index)))
        self.players_layout.addStretch()

    def set_houses(self, count: int):
        self._clear_layout_widgets(self.houses_layout)
        for _ in range(max(0, count)):
            self.houses_layout.addWidget(HouseDot())
        self.houses_layout.addStretch()

    def set_style(self, tone: str, accent: str, text_color: str, active: bool, owned: bool):
        border_color = "#c99700" if active else accent
        border_width = 3 if active else 2
        self.setStyleSheet(
            f"""
            QFrame {{
                background: {tone};
                border: {border_width}px solid {border_color};
                border-radius: 16px;
            }}
            QLabel {{
                background: transparent;
                color: {text_color};
                border: none;
            }}
            QLabel#cellTitle {{
                color: {accent};
            }}
            QLabel#cellSubtitle {{
                font-weight: 700;
                color: #22313f;
            }}
            QLabel#cellInfo {{
                color: #6b7280;
            }}
            """
        )

    def set_content(
        self,
        position: int,
        title: str,
        subtitle: str,
        info_lines: list[str],
        players: list[str],
        player_indices: dict[str, int] | None,
        houses: int,
        tone: str,
        accent: str,
        text_color: str,
        active: bool = False,
        owned: bool = False,
    ):
        self.title_label.setText(title)
        self.subtitle_label.setText(subtitle)
        self.info_label.setText("\n".join(info_lines))
        self.set_houses(houses)
        self.set_players(players, player_indices)
        self.set_style(tone, accent, text_color, active=active, owned=owned)


class CenterPanel(QFrame):
    def __init__(self):
        super().__init__()
        self.setStyleSheet(
            """
            QFrame {
                background: #fffaf0;
                border: 2px solid #d9ccb7;
                border-radius: 28px;
            }
            QLabel {
                background: transparent;
                color: #24303f;
            }
            QLabel#centerEyebrow {
                color: #8b1e24;
                font-size: 11px;
                font-weight: 900;
                letter-spacing: 1px;
            }
            QLabel#centerTitle {
                font-size: 30px;
                font-weight: 900;
                color: #16324b;
            }
            QLabel#centerLead {
                color: #2f4359;
                font-size: 16px;
                font-weight: 700;
            }
            QLabel#centerMeta {
                color: #6b7280;
                font-size: 13px;
            }
            """
        )

        self.eyebrow = QLabel("MONOPOLY PROLOG")
        self.eyebrow.setObjectName("centerEyebrow")
        self.eyebrow.setAlignment(Qt.AlignCenter)

        self.title = QLabel("Tablero de la partida")
        self.title.setObjectName("centerTitle")
        self.title.setAlignment(Qt.AlignCenter)

        self.lead = QLabel("Carga una traza para empezar la reproduccion")
        self.lead.setObjectName("centerLead")
        self.lead.setAlignment(Qt.AlignCenter)
        self.lead.setWordWrap(True)

        self.meta = QLabel("La logica corre en Prolog y esta vista te ayuda a leer cada cambio.")
        self.meta.setObjectName("centerMeta")
        self.meta.setAlignment(Qt.AlignCenter)
        self.meta.setWordWrap(True)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(18, 18, 18, 18)
        layout.setSpacing(8)
        layout.addStretch()
        layout.addWidget(self.eyebrow)
        layout.addWidget(self.title)
        layout.addWidget(self.lead)
        layout.addWidget(self.meta)
        layout.addStretch()
        self.update_density(70)

    def update_density(self, side: int):
        title_size = max(22, min(36, side // 6))
        lead_size = max(13, min(18, side // 10))
        meta_size = max(11, min(14, side // 14))
        eyebrow_size = max(9, min(12, side // 16))
        margins = max(18, min(30, side // 5))
        spacing = max(8, min(14, side // 18))
        layout = self.layout()
        if layout is not None:
            layout.setContentsMargins(margins, margins, margins, margins)
            layout.setSpacing(spacing)

        self.eyebrow.setFont(QFont("", eyebrow_size, QFont.Bold))
        self.title.setFont(QFont("", title_size, QFont.Bold))
        self.lead.setFont(QFont("", lead_size, QFont.DemiBold))
        self.meta.setFont(QFont("", meta_size))

    def set_context(self, context: dict | None):
        if not context:
            self.lead.setText("Carga una traza para empezar la reproduccion")
            self.meta.setText("La logica corre en Prolog y esta vista te ayuda a leer cada cambio.")
            return

        self.lead.setText(
            f"{context.get('step_title', 'Paso actual')}  •  Turno de {context.get('active_player', '-')}"
        )
        self.meta.setText(
            f"{context.get('progress', '-')}  •  {context.get('action', 'Sin accion actual')}"
        )


class BoardWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        self.setMinimumSize(1280, 980)
        self.grid = QGridLayout(self)
        self.grid.setSpacing(5)
        self.grid.setContentsMargins(2, 2, 2, 2)

        self.cells = {}
        self.mapping = self._build_ring_mapping()
        self.pos_to_grid = {pos: coords for coords, pos in self.mapping.items()}
        self.center_panel = CenterPanel()

        for row in range(11):
            for col in range(11):
                if (row, col) in self.mapping:
                    cell = BoardCell()
                    pos = self.mapping[(row, col)]
                    self.cells[pos] = cell
                    self.grid.addWidget(cell, row, col)
                elif 1 <= row <= 9 and 1 <= col <= 9:
                    if row == 4 and col == 4:
                        self.grid.addWidget(self.center_panel, 4, 4, 3, 3)
                    elif 4 <= row <= 6 and 4 <= col <= 6:
                        continue
                    else:
                        filler = QWidget()
                        filler.setStyleSheet("background: transparent;")
                        self.grid.addWidget(filler, row, col)

        self._update_board_scale()

    @staticmethod
    def _build_ring_mapping():
        mapping = {}

        col = 0
        for pos, row in enumerate(range(10, -1, -1)):
            mapping[(row, col)] = pos

        row = 0
        for index, col in enumerate(range(1, 11), start=11):
            mapping[(row, col)] = index

        col = 10
        for index, row in enumerate(range(1, 11), start=21):
            mapping[(row, col)] = index

        row = 10
        for index, col in enumerate(range(9, 0, -1), start=31):
            mapping[(row, col)] = index

        return mapping

    @staticmethod
    def _ownership_map(state: dict):
        owners = {}
        for player in state["jugadores"]:
            for prop in player["propiedades"]:
                owners[prop["id"]] = {
                    "owner": player["nombre"],
                    "casas": prop["casas"],
                    "hipotecada": prop["hipotecada"],
                }
        return owners

    @staticmethod
    def _players_by_position(state: dict):
        result = {}
        for player in state["jugadores"]:
            result.setdefault(player["posicion"], []).append(player["nombre"])
        return result

    @staticmethod
    def _player_index_map(state: dict):
        return {
            player["nombre"]: index
            for index, player in enumerate(state["jugadores"])
        }

    @staticmethod
    def _active_player_name(state: dict):
        turn = state["turno"]
        if 0 <= turn < len(state["jugadores"]):
            return state["jugadores"][turn]["nombre"]
        return None

    @staticmethod
    def _display_name(raw_name: str) -> str:
        return raw_name.replace("_", " ").title()

    @staticmethod
    def _short_name(raw_name: str, max_len: int = 11) -> str:
        pretty = raw_name.replace("_", " ").title()
        return pretty if len(pretty) <= max_len else pretty[: max_len - 1] + "…"

    def resizeEvent(self, event):
        super().resizeEvent(event)
        self._update_board_scale()

    def _update_board_scale(self):
        usable_width = max(1220, self.width() - 24)
        usable_height = max(940, self.height() - 24)

        band = max(84, min(108, usable_height // 10))
        lane = max(118, min(156, min((usable_width - 2 * band) // 9, (usable_height - 2 * band) // 9)))
        spacing = max(4, min(8, band // 18))

        self.grid.setHorizontalSpacing(spacing)
        self.grid.setVerticalSpacing(spacing)

        for col in range(11):
            width = band if col in (0, 10) else lane
            self.grid.setColumnMinimumWidth(col, width)
        for row in range(11):
            height = band if row in (0, 10) else lane
            self.grid.setRowMinimumHeight(row, height)

        for pos, cell in self.cells.items():
            row, col = self.pos_to_grid[pos]
            cell_width = band if col in (0, 10) else lane
            cell_height = band if row in (0, 10) else lane
            cell.setMinimumSize(0, 0)
            cell.setMaximumSize(16777215, 16777215)
            cell.setFixedSize(cell_width, cell_height)
            cell.update_density(cell_width, cell_height)

        center_width = lane * 3 + spacing * 2
        center_height = lane * 3 + spacing * 2
        self.center_panel.setMinimumSize(0, 0)
        self.center_panel.setMaximumSize(16777215, 16777215)
        self.center_panel.setFixedSize(center_width, center_height)
        self.center_panel.update_density(min(center_width, center_height))

    def render_state(self, board: list[dict], state: dict, context: dict | None = None):
        owners = self._ownership_map(state)
        players_by_pos = self._players_by_position(state)
        player_indices = self._player_index_map(state)
        active_player = self._active_player_name(state)
        self.center_panel.set_context(context)

        for pos, cell in self.cells.items():
            square = board[pos]
            players_here = players_by_pos.get(pos, [])
            is_active_here = active_player in players_here if active_player else False
            square_type = square["tipo"]
            houses = 0
            owned = False

            if square_type == "propiedad":
                color_name = square["color"]
                accent, _ = PROPERTY_COLORS.get(color_name, ("#8fb4ff", "#08111d"))
                text_color = "#24303f"
                tone = "#fffdf8"
                title = f"{color_name.upper()}  |  ${square['precio']}"
                subtitle = self._short_name(square["nombre"])

                owner_info = owners.get(square["nombre"])
                if owner_info:
                    owned = True
                    houses = owner_info["casas"]
                    if owner_info["hipotecada"]:
                        info_lines = [f"Dueno: {owner_info['owner']}", "Hipotecada"]
                    else:
                        info_lines = [f"Dueno: {owner_info['owner']}"]
                else:
                    info_lines = ["Disponible"]
            elif square_type == "impuesto":
                accent, _ = SPECIAL_TYPE_COLORS["impuesto"]
                text_color = "#24303f"
                tone = "#f7f4ef"
                title = f"${square['monto']}"
                subtitle = "Impuesto"
                info_lines = ["Casilla fiscal"]
            elif square_type == "carta":
                accent, _ = SPECIAL_TYPE_COLORS["carta"]
                text_color = "#24303f"
                tone = "#fcf7ff"
                title = "EVENTO"
                subtitle = "Carta"
                info_lines = ["Evento"]
            elif square_type == "salida":
                accent, _ = SPECIAL_TYPE_COLORS["salida"]
                text_color = "#24303f"
                tone = "#f3fbf5"
                title = "+200"
                subtitle = "Salida"
                info_lines = ["+200"]
            else:
                accent, _ = SPECIAL_TYPE_COLORS["especial"]
                text_color = "#24303f"
                tone = "#f6f4ef"
                title = self._short_name(square["nombre"])
                subtitle = "Especial"
                info_lines = ["Regla"]

            if players_here:
                info_lines.append("En casilla: " + ", ".join(players_here))

            cell.set_content(
                position=pos,
                title=title,
                subtitle=subtitle,
                info_lines=info_lines,
                players=players_here,
                player_indices=player_indices,
                houses=houses,
                tone=tone,
                accent=accent,
                text_color=text_color,
                active=is_active_here,
                owned=owned,
            )
