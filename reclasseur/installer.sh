#!/usr/bin/env bash
# Installe le reclasseur de mem : node-llama-cpp (version exacte du package-lock) et Qwen3-Reranker-4B Q4_K_M
# (GGUF de giladgd sur Hugging Face, 2,5 Go, empreinte SHA-256 vérifiée).
# Usage : ./installer.sh [--service]   (--service : écrit et active l'unité systemd utilisateur mem-reclasseur)
# Installs mem's reranker: node-llama-cpp (exact version) and the Qwen3-Reranker-4B Q4_K_M GGUF (2.5 GB, SHA-256 checked).
set -euo pipefail

ICI="$(cd "$(dirname "$0")" && pwd)"
DEST="${MEM_RECLASSEUR:-$HOME/.local/share/mem/reclasseur}"
MODELE="qwen3-reranker-4b-q4_k_m.gguf"
URL="https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF/resolve/main/Qwen3-Reranker-4B.Q4_K_M.gguf"
SHA256="941f7d1d1524251c026a797b803ac9575545c5d7aa19b26e0e49661d7720af49"

NODE="$(command -v node || true)"
[ -n "$NODE" ] || { echo "node introuvable (Node.js 20 ou plus) / node not found" >&2; exit 1; }
"$NODE" -e 'process.exit(+process.versions.node.split(".")[0] >= 20 ? 0 : 1)' \
  || { echo "Node.js 20 ou plus requis (trouvé : $("$NODE" --version)) / Node.js 20+ required" >&2; exit 1; }
command -v npm >/dev/null || { echo "npm introuvable / npm not found" >&2; exit 1; }

mkdir -p "$DEST"
cp "$ICI/reclasser.mjs" "$ICI/serveur.mjs" "$ICI/package.json" "$ICI/package-lock.json" "$DEST/"
(cd "$DEST" && npm ci --omit=dev --no-audit --no-fund)

if [ -f "$DEST/$MODELE" ] && echo "$SHA256  $DEST/$MODELE" | sha256sum -c --status; then
  echo "modèle déjà présent et vérifié / model already present"
else
  curl -L --fail --retry 3 -o "$DEST/$MODELE.part" "$URL"
  echo "$SHA256  $DEST/$MODELE.part" | sha256sum -c --status \
    || { echo "empreinte SHA-256 incorrecte : fichier rejeté / SHA-256 mismatch" >&2; rm -f "$DEST/$MODELE.part"; exit 1; }
  mv "$DEST/$MODELE.part" "$DEST/$MODELE"
fi

# Essai à blanc, sans réseau si unshare le permet / dry run, offline when unshare allows it.
ESSAI='{"q":"où est la clé ?","docs":["la clé est sous le paillasson","il pleut"]}'
if unshare -rn true 2>/dev/null; then
  (cd "$DEST" && echo "$ESSAI" | unshare -rn "$NODE" reclasser.mjs) && echo
else
  echo "unshare -rn refusé (espaces de noms non privilégiés bloqués) : mem lancera le reclasseur sans lui" >&2
  (cd "$DEST" && echo "$ESSAI" | "$NODE" reclasser.mjs) && echo
fi

if [ "${1:-}" = "--service" ]; then
  UNITE="$HOME/.config/systemd/user/mem-reclasseur.service"
  mkdir -p "$(dirname "$UNITE")"
  UNSHARE=""; unshare -rn true 2>/dev/null && UNSHARE="$(command -v unshare) -rn "
  sed -e "s#@UNSHARE@#$UNSHARE#" -e "s#@NODE@#$NODE#" -e "s#@DEST@#$DEST#" "$ICI/../systemd/mem-reclasseur.service" > "$UNITE"
  systemctl --user daemon-reload
  systemctl --user enable --now mem-reclasseur
  systemctl --user --no-pager status mem-reclasseur | head -5
fi
echo "reclasseur installé dans $DEST / reranker installed"
