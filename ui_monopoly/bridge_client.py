import json
import random
import subprocess
from pathlib import Path


class PrologBridgeClient:
    def __init__(self, bridge_file: str = "bridge_trace_ui.pl"):
        project_root = Path(__file__).resolve().parent.parent
        self.bridge_file = (project_root / bridge_file).resolve()

    def _run_goal(self, goal: str) -> dict:
        if not self.bridge_file.exists():
            raise FileNotFoundError(f"No existe el bridge: {self.bridge_file}")

        result = subprocess.run(
            ["swipl", "-q", "-g", goal],
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode != 0:
            raise RuntimeError(
                "Error ejecutando SWI-Prolog\n"
                f"STDOUT:\n{result.stdout}\n\n"
                f"STDERR:\n{result.stderr}"
            )

        output = result.stdout.strip()
        if not output:
            raise RuntimeError("Prolog no devolvió salida.")

        try:
            return json.loads(output)
        except json.JSONDecodeError as e:
            raise RuntimeError(f"JSON inválido devuelto por Prolog:\n{output}") from e

    def list_scenarios(self) -> list[dict]:
        goal = (
            f"consult('{self.bridge_file.as_posix()}'), "
            f"listar_escenarios_ui(JSON), "
            f"write(JSON), nl, halt."
        )
        data = self._run_goal(goal)
        return data["escenarios"]

    def load_scenario_trace(self, scenario_id: str) -> dict:
        goal = (
            f"consult('{self.bridge_file.as_posix()}'), "
            f"traza_escenario_ui({scenario_id}, JSON), "
            f"write(JSON), nl, halt."
        )
        return self._run_goal(goal)

    def load_random_trace(
        self,
        num_players: int = 2,
        start_money: int = 1500,
        num_turns: int = 20,
        mode: str = "real",
        seed: int | None = None
    ) -> dict:
        rng = random.Random(seed)

        if mode == "real":
            tiradas = [
                f"tirada({rng.randint(1, 6)},{rng.randint(1, 6)})"
                for _ in range(num_turns)
            ]
        else:
            tiradas = [str(rng.randint(2, 12)) for _ in range(num_turns)]

        tiradas_term = "[" + ",".join(tiradas) + "]"

        goal = (
            f"consult('{self.bridge_file.as_posix()}'), "
            f"traza_tiradas_base_ui({num_players}, {start_money}, {tiradas_term}, JSON), "
            f"write(JSON), nl, halt."
        )
        return self._run_goal(goal)