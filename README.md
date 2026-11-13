# mem — search your coding agents' memory

*Français : [README.fr.md](README.fr.md)*

Claude Code (and OpenClaude) keep a per-project memory: Markdown notes in
`~/.claude/projects/<project>/memory/`, with a `MEMORY.md` index loaded into every session.
Once the memory grows past a few dozen notes, the agent can no longer reread it all:
it falls back to `grep`, and misses anything phrased with different words.

`mem` is a single Python script that searches those notes **locally**:

- **by words**: SQLite FTS5 (BM25), accent-insensitive, titles and descriptions weighted higher;
- **by meaning** (optional): bge-m3 embeddings computed by a local Ollama;
- **with reranking** (optional): the top 10 passages are rescored by Qwen3-Reranker-4B
  (llama.cpp through node-llama-cpp), with no network access.

The notes stay the only source of truth: `mem` only keeps an index, rebuilt whenever a note changes.
No text leaves the machine.

The tool itself speaks French (commands, help, messages); the commands are short and listed below.

```
mem chercher "who is allowed to deploy?"     # search
mem chercher --vite "database migration"     # no reranking: ~0.3 s
mem voir project/deploiement.md:12           # show a passage in context
mem ajouter --type feedback "title" < text   # add a note
mem etat                                     # notes, passages, lines withheld as secrets
mem bench questions.tsv                      # top 1, top 3, MRR on your own questions
mem selftest
```

## Install

1. **The script** (Python 3.11 or later, tested with 3.11 and 3.12; numpy for search by meaning):
   ```
   install -m 755 mem ~/.local/bin/mem
   mem selftest
   ```
   Run from a project directory (or any subdirectory, worktrees included), `mem` finds that
   project's Claude Code memory. Elsewhere: `--dossier` or `MEM_DIR`. It never opens another
   project's memory by default.

2. **Search by meaning** (optional): a local [Ollama](https://ollama.com), then `ollama pull bge-m3`.
   Without Ollama, `mem` searches by words only, without error.

3. **Reranking** (optional): Node.js 20 or later, then
   ```
   cd reclasseur && ./installer.sh --service
   ```
   It installs node-llama-cpp 3.20.0 (exact version), downloads the model from Hugging Face (2.5 GB),
   checks its SHA-256 and, with `--service`, enables a systemd user unit that keeps the model loaded.
   Without the service, `mem` loads the model on every search (slower).

## Cost and benefit

Measured on a laptop (Ryzen 7 8845HS, integrated Radeon 780M, llama.cpp over Vulkan), on a real
memory of 182 notes:

| Mode | Time per search |
|---|---|
| `--vite` (words + meaning) | ~0.3 s |
| reranking, service running | ~6 to 8 s |
| reranking, no service | ~9 s |
| reranking, CPU only | ~38 s: use `--vite` or `MEM_RECLASSER=0` |

Quality, on a **private** benchmark of 200 questions written by another agent from that memory
(paraphrases, situations, past states). MRR: mean of 1/rank of the right note (1 = always first).

| | MRR, 200-question set | MRR, 50-question held-out set |
|---|---|---|
| words + meaning | 0.65 | 0.69 |
| words + meaning + reranking | 0.74 | 0.78 |

Limits of these figures: a single corpus, in French, from a single project; the reranker was chosen
on these sets. Measure on your own questions with `mem bench` (format in `exemples/questions.tsv`)
before relying on reranking.

## Secrets

A line that looks like a secret (private key, known token format, `password: …`, URL with credentials,
long random string…) does not enter the index: its value becomes `[masqué]`, or the line is dropped,
and `mem etat` counts it. This is a **safety net, not a guarantee**: a lowercase password inside a
sentence ("the password is hunter") cannot be told apart from "the password is required" and stays
visible. The only reliable rule: do not write secrets into agent memory.

## Settings

| Variable | Purpose |
|---|---|
| `MEM_DIR` | memory directory |
| `MEM_DB` | index database (default `~/.local/share/mem/<project>.db`, mode 0600) |
| `MEM_SENS=0` | no search by meaning |
| `MEM_SENS_URL` | Ollama endpoint (`http://127.0.0.1:11434/api/embed`) |
| `MEM_SENS_GARDER=0` | let Ollama unload bge-m3 after 5 minutes |
| `MEM_RECLASSER=0` | no reranking (same as `--vite`) |
| `MEM_RECLASSEUR` | reranker directory |
| `MEM_SYNONYMES` | extra synonym groups (default `~/.config/mem/synonymes.txt`) |

Project-specific synonyms: one group per line, words separated by commas.
```
reviewer, review, code-review
container, vm, proxmox
```

The built-in synonyms, stop words and date formats are French; English notes are searched by words and
by meaning, but benefit less from those helpers.

Recognised conventions: the YAML front matter of Claude Code notes (`name`, `description`,
`metadata.type`), dates at the start of an entry (`- 08/11 …`, `## 2026-11-08`), and handover notes
("POINT DE REPRISE") treated as a log: their old passages rank below rules, unless the question asks
for the "latest" (« dernier ») state.

On some systems (Ubuntu 24.04 for instance), unprivileged user namespaces are blocked: `unshare -rn`
fails, and the installer then writes the unit without it. The reranker makes no network calls anyway;
`unshare` is only a second barrier.

## Licences

`mem`: MIT (see [LICENSE](LICENSE)). Models, downloaded at install time and never shipped here:
bge-m3 (MIT, BAAI), Qwen3-Reranker-4B (Apache 2.0, Qwen) in its GGUF conversion by
[giladgd](https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF).
