#!/usr/bin/env bash
# Installe le reclasseur de mem : llama-server (llama.cpp b12128, archive officielle, empreinte SHA-256 vérifiée)
# et Qwen3-Reranker-4B Q4_0 (GGUF de giladgd sur Hugging Face, 2,4 Go, empreinte SHA-256 vérifiée).
# Usage : ./installer.sh [--service] [--cpu | --llama-server CHEMIN]
#   --service           écrit et active l'unité systemd utilisateur mem-reclasseur (Linux)
#   --cpu               llama.cpp sans carte graphique (sinon : Vulkan, Linux x86_64)
#   --llama-server C    un llama-server déjà installé (CUDA, ROCm, ARM, autre version…), rien n'est téléchargé
# Installs mem's reranker: llama-server (llama.cpp b12128) and the Qwen3-Reranker-4B Q4_0 GGUF, both SHA-256 checked.
set -euo pipefail

ICI="$(cd "$(dirname "$0")" && pwd)"
DEST="${MEM_RECLASSEUR:-$HOME/.local/share/mem/reclasseur}"
MODELE="qwen3-reranker-4b-q4_0.gguf"
URL_MODELE="https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF/resolve/main/Qwen3-Reranker-4B.Q4_0.gguf"
SHA_MODELE="b01097a2ff38a220dc80eb88e2bc7196675e7a5645ee21632f2f06003ecd7fd8"
VERSION="b12128"
ARCHIVE="llama-$VERSION-bin-ubuntu-vulkan-x64.tar.gz"
SHA_ARCHIVE="630d8e57080290005ec8df8126d324c7167ea4a4a8691919262a9ae7d0c5b210"
SERVICE=0; LLAMA=""
while [ $# -gt 0 ]; do
  case "$1" in
    --service) SERVICE=1 ;;
    --cpu) ARCHIVE="llama-$VERSION-bin-ubuntu-x64.tar.gz"
           SHA_ARCHIVE="a03e1f92e039dc23b630748db27f57f6287aa09a9d015c4eec6fc037657edf1e" ;;
    --llama-server) LLAMA="$(realpath "${2:?chemin de llama-server attendu / llama-server path expected}")"; shift ;;
    *) echo "option inconnue / unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

telecharger() {  # URL SHA256 DESTINATION
  if [ -f "$3" ] && echo "$2  $3" | sha256sum -c --status; then
    echo "déjà présent et vérifié / already present: $(basename "$3")"; return
  fi
  curl -L --fail --retry 3 -o "$3.part" "$1"
  echo "$2  $3.part" | sha256sum -c --status \
    || { echo "empreinte SHA-256 incorrecte : fichier rejeté / SHA-256 mismatch" >&2; rm -f "$3.part"; exit 1; }
  mv "$3.part" "$3"
}

mkdir -p "$DEST"
if [ -z "$LLAMA" ]; then
  [ "$(uname -sm)" = "Linux x86_64" ] \
    || { echo "archive fournie pour Linux x86_64 seulement : installez llama.cpp puis --llama-server CHEMIN / Linux x86_64 only, use --llama-server" >&2; exit 1; }
  telecharger "https://github.com/ggml-org/llama.cpp/releases/download/$VERSION/$ARCHIVE" "$SHA_ARCHIVE" "$DEST/$ARCHIVE"
  rm -rf "$DEST/llama-$VERSION" && tar -xzf "$DEST/$ARCHIVE" -C "$DEST" && rm -f "$DEST/$ARCHIVE"
  LLAMA="$DEST/llama-$VERSION/llama-server"
fi
[ -x "$LLAMA" ] || { echo "llama-server introuvable / not found: $LLAMA" >&2; exit 1; }
telecharger "$URL_MODELE" "$SHA_MODELE" "$DEST/$MODELE"

UNSHARE=""
if unshare -rn true 2>/dev/null; then UNSHARE="$(command -v unshare) -rn "
else echo "unshare -rn refusé (espaces de noms non privilégiés bloqués) : llama-server tournera sans lui / unshare -rn refused" >&2; fi

# Essai à blanc sur un socket provisoire / dry run on a temporary socket.
SOCK="${XDG_RUNTIME_DIR:-$DEST}/mem-reclasseur-essai.$$.sock"
# shellcheck disable=SC2086
(umask 077; exec $UNSHARE"$LLAMA" -m "$DEST/$MODELE" --rerank -ngl 99 -np 2 -c 4096 --no-webui --log-disable --host "$SOCK") &
PID=$!; trap 'kill $PID 2>/dev/null; rm -f "$SOCK"' EXIT
for _ in $(seq 120); do
  curl -s --unix-socket "$SOCK" http://x/health 2>/dev/null | grep -q '"ok"' && break
  kill -0 $PID 2>/dev/null || { echo "llama-server s'est arrêté / llama-server exited" >&2; exit 1; }
  sleep 1
done
curl -s --fail --unix-socket "$SOCK" http://x/v1/rerank -H 'Content-Type: application/json' \
  -d '{"query":"où est la clé ?","documents":["la clé est sous le paillasson","il pleut"]}' \
  || { echo "essai du reclassement échoué / rerank test failed" >&2; exit 1; }
echo
kill $PID 2>/dev/null; wait $PID 2>/dev/null || true; rm -f "$SOCK"; trap - EXIT

if [ "$SERVICE" = 1 ]; then
  UNITE="$HOME/.config/systemd/user/mem-reclasseur.service"
  mkdir -p "$(dirname "$UNITE")"
  sed -e "s#@UNSHARE@#$UNSHARE#" -e "s#@LLAMA@#$LLAMA#" -e "s#@MODELE@#$DEST/$MODELE#" "$ICI/../systemd/mem-reclasseur.service" > "$UNITE"
  systemctl --user daemon-reload
  systemctl --user enable mem-reclasseur
  systemctl --user restart mem-reclasseur
  systemctl --user --no-pager status mem-reclasseur | head -5
fi
echo "reclasseur installé dans $DEST / reranker installed"
