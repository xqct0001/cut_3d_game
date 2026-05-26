from __future__ import annotations

from pathlib import Path
import shutil


def ensure_profile_templates(source_dir: Path, target_dir: Path) -> None:
    target_dir.mkdir(parents=True, exist_ok=True)
    for name in ("default.toml", "sample-third-person.toml"):
        source = source_dir / name
        target = target_dir / name
        if source.exists() and not target.exists():
            shutil.copy2(source, target)
