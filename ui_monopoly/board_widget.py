from PySide6.QtWidgets import QWidget, QGridLayout, QFrame, QLabel, QVBoxLayout, QHBoxLayout
from PySide6.QtCore import Qt


PROPERTY_COLORS = {
    "marron":   ("#8B5A2B", "#FFFFFF"),
    "celeste":  ("#87CEEB", "#111111"),
    "rosa":     ("#FF69B4", "#111111"),
    "naranja":  ("#FF8C00", "#111111"),
    "rojo":     ("#D32F2F", "#FFFFFF"),
    "amarillo": ("#FDD835", "#111111"),
    "verde":    ("#2E7D32", "#FFFFFF"),
    "azul":     ("#1565C0", "#FFFFFF"),
}

SPECIAL_TYPE_COLORS = {
    "salida":   ("#2E7D32", "#FFFFFF"),
    "carta":    ("#6A1B9A", "#FFFFFF"),
    "impuesto": ("#424242", "#FFFFFF"),
    "especial": ("#37474F", "#FFFFFF"),
}

PLAYER_CHIP_COLORS = [
    "#FF5252", "#42A5F5", "#66BB6A", "#FFCA28",
    "#AB47BC", "#26C6DA", "#EC407A", "#8D6E63"
]


def short_player(name: str) -> str:
    lower = name.lower()
    if lower.startswith("jugador"):
        suffix = lower.replace("jugador", "")
        return f"J{suffix}" if suffix else "J"
    return name[:3].upper()


def player_color(index: int) -> str:
    return PLAYER_CHIP_COLORS[index % len(PLAYER_CHIP_COLORS)]


class PlayerChip(QLabel):
    def __init__(self, text: str, color: str):
        super().__init__(text)
        self.setAlignment(Qt.AlignCenter)
        self.setStyleSheet(f"""
            QLabel {{
                background-color: {color};
                color: white;
                border-radius: 10px;
                padding: 2px 6px;
                font-size: 10px;
                font-weight: 700;
            }}
        """)


class BoardCell(QFrame):
    def __init__(self):
        super().__init__()
        self.setMinimumSize(92, 78)
        self.setFrameShape(QFrame.NoFrame)

        self.header = QLabel("")
        self.header.setAlignment(Qt.AlignCenter)

        self.subheader = QLabel("")
        self.subheader.setAlignment(Qt.AlignCenter)

        self.info = QLabel("")
        self.info.setAlignment(Qt.AlignTop | Qt.AlignLeft)
        self.info.setWordWrap(True)

        self.players_row = QHBoxLayout()
        self.players_row.setSpacing(4)
        self.players_row.setContentsMargins(0, 0, 0, 0)

        players_container = QWidget()
        players_container.setLayout(self.players_row)

        layout = QVBoxLayout()
        layout.setSpacing(4)
        layout.setContentsMargins(6, 6, 6, 6)
        layout.addWidget(self.header)
        layout.addWidget(self.subheader)
        layout.addWidget(self.info, 1)
        layout.addWidget(players_container)
        self.setLayout(layout)

    def clear_players(self):
        while self.players_row.count():
            item = self.players_row.takeAt(0)
            widget = item.widget()
            if widget is not None:
                widget.deleteLater()

    def set_players(self, players: list[str]):
        self.clear_players()
        for i, p in enumerate(players):
            self.players_row.addWidget(PlayerChip(short_player(p), player_color(i)))
        self.players_row.addStretch()

    def set_style(self, bg: str, fg: str, border: str, header_bg: str, active: bool = False):
        active_border = "#FFD54F" if active else border
        self.setStyleSheet(f"""
            QFrame {{
                background-color: {bg};
                border: 2px solid {active_border};
                border-radius: 8px;
            }}
            QLabel {{
                color: {fg};
                background: transparent;
            }}
        """)
        self.header.setStyleSheet(f"""
            QLabel {{
                background-color: {header_bg};
                color: {fg};
                border-radius: 4px;
                padding: 2px;
                font-size: 11px;
                font-weight: 800;
            }}
        """)
        self.subheader.setStyleSheet(f"""
            QLabel {{
                color: {fg};
                font-size: 10px;
                font-weight: 600;
            }}
        """)
        self.info.setStyleSheet(f"""
            QLabel {{
                color: {fg};
                font-size: 10px;
                font-weight: 500;
            }}
        """)

    def set_content(
        self,
        title: str,
        subtitle: str,
        info_lines: list[str],
        players: list[str],
        bg: str,
        fg: str,
        border: str,
        header_bg: str,
        active: bool = False
    ):
        self.header.setText(title)
        self.subheader.setText(subtitle)
        self.info.setText("\n".join(info_lines))
        self.set_players(players)
        self.set_style(bg, fg, border, header_bg, active=active)


class CenterPanel(QFrame):
    def __init__(self):
        super().__init__()
        self.setStyleSheet("""
            QFrame {
                background-color: #14171c;
                border: 2px dashed #2f3a46;
                border-radius: 14px;
            }
            QLabel {
                color: #EAEFF5;
                background: transparent;
            }
        """)

        title = QLabel("MONOPOLY")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 28px; font-weight: 900; letter-spacing: 2px;")

        subtitle = QLabel("Motor lógico en Prolog\nInterfaz visual en Python")
        subtitle.setAlignment(Qt.AlignCenter)
        subtitle.setStyleSheet("font-size: 15px; color: #B8C2CC; font-weight: 600;")

        hint = QLabel("Carga un escenario o genera una partida aleatoria\npara navegar paso a paso.")
        hint.setAlignment(Qt.AlignCenter)
        hint.setStyleSheet("font-size: 13px; color: #8FA1B3;")

        layout = QVBoxLayout()
        layout.addStretch()
        layout.addWidget(title)
        layout.addWidget(subtitle)
        layout.addSpacing(10)
        layout.addWidget(hint)
        layout.addStretch()
        self.setLayout(layout)


class BoardWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.grid = QGridLayout()
        self.grid.setSpacing(4)
        self.grid.setContentsMargins(4, 4, 4, 4)
        self.setLayout(self.grid)

        self.cells = {}
        self.mapping = self._build_ring_mapping()

        for row in range(11):
            for col in range(11):
                if (row, col) in self.mapping:
                    cell = BoardCell()
                    pos = self.mapping[(row, col)]
                    self.cells[pos] = cell
                    self.grid.addWidget(cell, row, col)
                else:
                    if 1 <= row <= 9 and 1 <= col <= 9:
                        if row == 5 and col == 5:
                            self.grid.addWidget(CenterPanel(), row, col, 1, 1)
                        else:
                            filler = QWidget()
                            self.grid.addWidget(filler, row, col)

    def _build_ring_mapping(self):
        mapping = {}

        col = 0
        for pos, row in enumerate(range(10, -1, -1)):
            mapping[(row, col)] = pos

        row = 0
        for i, col in enumerate(range(1, 11), start=11):
            mapping[(row, col)] = i

        col = 10
        for i, row in enumerate(range(1, 11), start=21):
            mapping[(row, col)] = i

        row = 10
        for i, col in enumerate(range(9, 0, -1), start=31):
            mapping[(row, col)] = i

        return mapping

    def _ownership_map(self, state: dict):
        owners = {}
        for player in state["jugadores"]:
            for prop in player["propiedades"]:
                owners[prop["id"]] = {
                    "owner": player["nombre"],
                    "casas": prop["casas"],
                    "hipotecada": prop["hipotecada"],
                }
        return owners

    def _players_by_position(self, state: dict):
        result = {}
        for player in state["jugadores"]:
            result.setdefault(player["posicion"], []).append(player["nombre"])
        return result

    def _active_player_name(self, state: dict):
        turno = state["turno"]
        if 0 <= turno < len(state["jugadores"]):
            return state["jugadores"][turno]["nombre"]
        return None

    def render_state(self, board: list[dict], state: dict):
        owners = self._ownership_map(state)
        players_by_pos = self._players_by_position(state)
        active_player = self._active_player_name(state)

        for pos, cell in self.cells.items():
            square = board[pos]
            players_here = players_by_pos.get(pos, [])
            is_active_here = active_player in players_here if active_player else False

            square_type = square["tipo"]

            if square_type == "propiedad":
                color_name = square["color"]
                header_bg, fg = PROPERTY_COLORS.get(color_name, ("#455A64", "#FFFFFF"))
                bg = "#1E232A"
                border = "#5C6773"

                title = f"{pos:02d} · {square['nombre']}"
                subtitle = f"PROPIEDAD · {color_name.upper()} · ${square['precio']}"

                info_lines = []
                owner_info = owners.get(square["nombre"])
                if owner_info:
                    info_lines.append(f"Dueño: {owner_info['owner']}")
                    info_lines.append(f"Casas: {owner_info['casas']}")
                    info_lines.append(f"Hipoteca: {'Sí' if owner_info['hipotecada'] else 'No'}")
                else:
                    info_lines.append("Dueño: -")
                    info_lines.append("Casas: 0")
                    info_lines.append("Hipoteca: No")

            elif square_type == "impuesto":
                header_bg, fg = SPECIAL_TYPE_COLORS["impuesto"]
                bg = "#23272E"
                border = "#5C6773"
                title = f"{pos:02d} · IMPUESTO"
                subtitle = f"PAGO OBLIGATORIO · ${square['monto']}"
                info_lines = ["Casilla fiscal"]

            elif square_type == "carta":
                header_bg, fg = SPECIAL_TYPE_COLORS["carta"]
                bg = "#23272E"
                border = "#5C6773"
                title = f"{pos:02d} · CARTA"
                subtitle = "EVENTO / CARTA"
                info_lines = ["Casilla de evento"]

            elif square_type == "salida":
                header_bg, fg = SPECIAL_TYPE_COLORS["salida"]
                bg = "#23272E"
                border = "#5C6773"
                title = f"{pos:02d} · SALIDA"
                subtitle = "BONUS AL PASAR"
                info_lines = ["Cobro habitual: +200"]

            else:
                header_bg, fg = SPECIAL_TYPE_COLORS["especial"]
                bg = "#23272E"
                border = "#5C6773"
                title = f"{pos:02d} · {square['nombre']}"
                subtitle = "CASILLA ESPECIAL"
                info_lines = ["Efecto especial del tablero"]

            if players_here:
                info_lines.append(f"Jugadores: {', '.join(players_here)}")

            cell.set_content(
                title=title,
                subtitle=subtitle,
                info_lines=info_lines,
                players=players_here,
                bg=bg,
                fg="#EAF0F6" if square_type != "propiedad" else "#F5F7FA",
                border=border,
                header_bg=header_bg,
                active=is_active_here
            )