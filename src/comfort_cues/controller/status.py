from __future__ import annotations


def extract_exe_name(status_text: str) -> str:
    for prefix in (
        "Active: ",
        "Unsupported ratio: ",
        "Unsupported window: ",
        "Window detected but no matched profile: ",
        "Bind failed: ",
    ):
        if status_text.startswith(prefix):
            payload = status_text.removeprefix(prefix)
            return payload.split(" - ", 1)[0].lower()
    return ""
