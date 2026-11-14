#!/usr/bin/env python3
"""Hook PostToolUse (Write) de Claude Code : une note de mémoire neuve qui redit une note existante est
signalée à l'agent, qui complète plutôt l'existante.

Seulement pour un .md d'un dossier mémoire de Claude Code (…/.claude/projects/<projet>/memory/), hors
archive/ et MEMORY.md. Silencieux s'il n'y a rien de proche, ou si le sens n'est pas disponible (Ollama
absent, numpy absent) : le hook ne bloque jamais l'écriture, il prévient (code 2 = message montré à l'agent).
Réglage : ~/.claude/settings.json, "PostToolUse": [{"matcher": "Write", "hooks": [{"type": "command",
"command": "python3 ~/.claude/hooks/mem-voisins.py"}]}].
"""
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

DELAI = 60  # secondes : réindexer la note neuve demande ses vecteurs à Ollama


def racine_memoire(chemin: Path) -> Path | None:
    parties = chemin.parts
    for i in range(len(parties) - 1, 2, -1):
        if parties[i] == "memory" and parties[i - 2] == "projects" and parties[i - 3] == ".claude":
            return Path(*parties[: i + 1])
    return None


def main() -> int:
    try:
        entree = json.load(sys.stdin)
    except ValueError:
        return 0
    chemin = (entree.get("tool_input") or {}).get("file_path") or ""
    if not chemin.endswith(".md"):
        return 0
    chemin = Path(chemin).expanduser().resolve()
    racine = racine_memoire(chemin)
    if racine is None:
        return 0
    rel = chemin.relative_to(racine).as_posix()
    if rel.startswith("archive/") or chemin.name == "MEMORY.md":
        return 0
    mem = shutil.which("mem") or str(Path.home() / ".local" / "bin" / "mem")
    try:
        r = subprocess.run([mem, "--dossier", str(racine), "voisins", rel], capture_output=True, text=True,
                           timeout=DELAI, env={**os.environ, "MEM_RECLASSER": "0"})
    except (OSError, subprocess.TimeoutExpired):
        return 0
    if r.returncode != 1 or not r.stdout.strip():
        return 0
    print(f"mem : la note {rel} ressemble à des notes existantes :\n{r.stdout.rstrip()}\n"
          "Si elle redit l'une d'elles : reporte ce qu'elle apporte dans la note existante, puis retire celle-ci "
          "(et sa ligne de MEMORY.md). Si le sujet est vraiment autre, garde-la.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
