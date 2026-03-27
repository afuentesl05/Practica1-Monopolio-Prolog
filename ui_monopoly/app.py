import sys
from PySide6.QtWidgets import QApplication
from .main_window import MainWindow


def main():
    app = QApplication(sys.argv)
    window = MainWindow()

    screen = app.primaryScreen()
    geometry = screen.availableGeometry()

    screen_w = geometry.width()
    screen_h = geometry.height()

    target_w = int(screen_w * 0.92)
    target_h = int(screen_h * 0.88)

    ratio = 16 / 9
    if target_w / target_h > ratio:
        target_w = int(target_h * ratio)
    else:
        target_h = int(target_w / ratio)

    window.resize(target_w, target_h)

    frame = window.frameGeometry()
    frame.moveCenter(geometry.center())
    window.move(frame.topLeft())

    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()