import sys
from PySide6.QtWidgets import QApplication
from .main_window import BatchMainWindow


def main():
    app = QApplication(sys.argv)
    window = BatchMainWindow()

    screen = app.primaryScreen()
    geometry = screen.availableGeometry()

    target_w = int(geometry.width() * 0.9)
    target_h = int(geometry.height() * 0.88)

    window.resize(target_w, target_h)
    frame = window.frameGeometry()
    frame.moveCenter(geometry.center())
    window.move(frame.topLeft())

    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
