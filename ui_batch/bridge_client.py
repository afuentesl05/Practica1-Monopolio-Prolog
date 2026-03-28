import json
import subprocess
from pathlib import Path


class BatchBridgeClient:
    def __init__(self, bridge_file: str = "prolog/bridges/bridge_batch_ui.pl"):
        project_root = Path(__file__).resolve().parent.parent
        self.bridge_file = (project_root / bridge_file).resolve()

    def _run_goal(self, goal: str) -> dict:
        if not self.bridge_file.exists():
            raise FileNotFoundError(f"No existe el bridge: {self.bridge_file}")

        result = subprocess.run(
            ["swipl", "-q", "-g", goal],
            capture_output=True,
            text=True,
            check=False,
        )

        if result.returncode != 0:
            raise RuntimeError(
                "Error ejecutando SWI-Prolog\n"
                f"STDOUT:\n{result.stdout}\n\n"
                f"STDERR:\n{result.stderr}"
            )

        output = result.stdout.strip()
        if not output:
            raise RuntimeError("Prolog no devolvio salida.")

        try:
            return json.loads(output)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"JSON invalido devuelto por Prolog:\n{output}") from exc

    def run_batch(
        self,
        simulations: int,
        players: int,
        start_money: int,
        max_turns: int,
        mode: str,
    ) -> dict:
        goal = (
            f"consult('{self.bridge_file.as_posix()}'), "
            f"simulaciones_aleatorias_ui({simulations}, {players}, {start_money}, {max_turns}, {mode}, JSON), "
            f"write(JSON), nl, halt."
        )
        return self._run_goal(goal)
