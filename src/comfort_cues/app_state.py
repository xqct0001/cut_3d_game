from __future__ import annotations

from dataclasses import asdict, dataclass
from pathlib import Path
import json
import os


@dataclass(slots=True)
class AppState:
    app_enabled: bool = True
    launch_to_tray: bool = False
    ui_language: str = "en"


def default_data_root() -> Path:
    return default_app_state_path().parent


def default_app_state_path() -> Path:
    if os.name == "nt":
        base = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
        return base / "Comfort Cues" / "app-state.json"
    return Path.home() / ".comfort-cues" / "app-state.json"


def load_app_state(path: Path) -> AppState:
    if not path.exists():
        return AppState()

    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError):
        return AppState()

    return AppState(
        app_enabled=bool(payload.get("app_enabled", True)),
        launch_to_tray=bool(payload.get("launch_to_tray", False)),
        ui_language="zh" if str(payload.get("ui_language", "en")).strip().lower() == "zh" else "en",
    )


def save_app_state(path: Path, state: AppState) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(asdict(state), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
