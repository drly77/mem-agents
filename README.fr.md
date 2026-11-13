# mem — chercher dans la mémoire de vos agents de code

*English: [README.md](README.md)*

Claude Code (et OpenClaude) gardent une mémoire par projet : des notes Markdown dans
`~/.claude/projects/<projet>/memory/`, avec un index `MEMORY.md` chargé à chaque session.
Quand la mémoire dépasse quelques dizaines de notes, l'agent ne peut plus tout relire :
il cherche avec `grep`, et rate tout ce qui est dit avec d'autres mots.

`mem` est un seul script Python qui cherche dans ces notes **en local** :

- **par mots** : SQLite FTS5 (BM25), accents ignorés, titres et descriptions pesés plus lourd ;
- **par le sens** (facultatif) : vecteurs bge-m3 calculés par un Ollama local ;
- **avec reclassement** (facultatif) : les 10 premiers passages sont renotés par
  Qwen3-Reranker-4B (llama.cpp par node-llama-cpp), sans accès réseau.

Les notes restent la seule source : `mem` n'en tient qu'un index, refait dès qu'une note change.
Aucun texte ne quitte la machine.

```
mem chercher "qui a le droit de déployer ?"
mem chercher --vite "migration base"        # sans reclassement : ~0,3 s
mem voir project/deploiement.md:12
mem ajouter --type feedback "titre" < texte
mem etat                                     # notes, passages, lignes écartées comme secrets
mem bench questions.tsv                      # top 1, top 3, MRR sur vos propres questions
mem selftest
```

## Installation

1. **Le script** (Python 3.11 ou plus, testé avec 3.11 et 3.12 ; numpy pour la recherche par le sens) :
   ```
   install -m 755 mem ~/.local/bin/mem
   mem selftest
   ```
   Lancé depuis un dossier de projet (ou un de ses sous-dossiers, worktrees compris), `mem` trouve
   la mémoire Claude Code de ce projet. Ailleurs : `--dossier` ou `MEM_DIR`. Il n'ouvre jamais par
   défaut la mémoire d'un autre projet.

2. **La recherche par le sens** (facultatif) : [Ollama](https://ollama.com) en local, puis
   `ollama pull bge-m3`. Sans Ollama, `mem` cherche par mots seulement, sans erreur.

3. **Le reclassement** (facultatif) : Node.js 20 ou plus, puis
   ```
   cd reclasseur && ./installer.sh --service
   ```
   Le script installe node-llama-cpp 3.20.0 (version exacte), télécharge le modèle depuis Hugging Face
   (2,5 Go), vérifie son empreinte SHA-256 et, avec `--service`, active une unité systemd utilisateur
   qui garde le modèle chargé. Sans le service, `mem` charge le modèle à chaque recherche (plus lent).

## Ce que ça coûte, ce que ça rapporte

Mesuré sur un portable (Ryzen 7 8845HS, Radeon 780M intégrée, llama.cpp par Vulkan), sur une mémoire
réelle de 182 notes :

| Mode | Durée d'une recherche |
|---|---|
| `--vite` (mots + sens) | ~0,3 s |
| avec reclassement, service actif | ~6 à 8 s |
| avec reclassement, sans service | ~9 s |
| avec reclassement, processeur seul | ~38 s : utilisez `--vite` ou `MEM_RECLASSER=0` |

Qualité, sur un banc **privé** de 200 questions écrites par un autre agent à partir de cette mémoire
(paraphrases, situations, états passés). MRR : moyenne de 1/rang de la bonne note (1 = toujours en tête).

| | MRR, banc de 200 | MRR, banc de 50 tenu à l'écart |
|---|---|---|
| mots + sens | 0,65 | 0,69 |
| mots + sens + reclassement | 0,74 | 0,78 |

Limites de ces chiffres : un seul corpus, en français, d'un seul projet ; le choix du reclasseur a été
fait sur ce banc et sur un second de 50 questions. Mesurez sur vos propres questions avec `mem bench`
(format dans `exemples/questions.tsv`) avant de vous fier au reclassement.

## Secrets

Une ligne qui ressemble à un secret (clé privée, jeton connu, `password: …`, URL à identifiants,
longue suite aléatoire…) n'entre pas dans l'index : sa valeur devient `[masqué]`, ou la ligne est
retirée, et `mem etat` la compte. C'est un **filet**, pas une garantie : un mot de passe écrit en
minuscules dans une phrase (« le mot de passe est hunter ») ne se distingue pas de « le mot de passe
est requis » et reste visible. La seule règle sûre : ne pas écrire de secret dans la mémoire.

## Réglages

| Variable | Rôle |
|---|---|
| `MEM_DIR` | dossier mémoire |
| `MEM_DB` | base de l'index (sinon `~/.local/share/mem/<projet>.db`, 0600) |
| `MEM_SENS=0` | sans recherche par le sens |
| `MEM_SENS_URL` | adresse d'Ollama (`http://127.0.0.1:11434/api/embed`) |
| `MEM_SENS_GARDER=0` | laisser Ollama décharger bge-m3 au bout de 5 minutes |
| `MEM_RECLASSER=0` | sans reclassement (comme `--vite`) |
| `MEM_RECLASSEUR` | dossier du reclasseur |
| `MEM_SYNONYMES` | groupes de synonymes en plus (sinon `~/.config/mem/synonymes.txt`) |

Synonymes propres à un projet : un groupe par ligne, mots séparés par des virgules.
```
relecteur, relecture, revue-de-code
conteneur, vm, proxmox
```

Conventions reconnues : l'en-tête YAML des notes Claude Code (`name`, `description`, `metadata.type`),
les dates en tête d'entrée (`- 08/11 …`, `## 2026-11-08`), et les notes de reprise (« POINT DE
REPRISE ») traitées comme un journal : leurs vieux passages passent derrière les règles, sauf si la
question demande le « dernier » état.

Sur certains systèmes (par exemple Ubuntu 24.04), les espaces de noms non privilégiés sont bloqués :
`unshare -rn` échoue, et l'installateur écrit alors l'unité sans lui. Le reclasseur ne fait de toute
façon aucun appel réseau ; `unshare` n'est qu'une seconde barrière.

## Licences

`mem` : MIT (voir [LICENSE](LICENSE)). Modèles, téléchargés à l'installation et jamais fournis ici :
bge-m3 (MIT, BAAI), Qwen3-Reranker-4B (Apache 2.0, Qwen) dans sa conversion GGUF de
[giladgd](https://huggingface.co/giladgd/Qwen3-Reranker-4B-GGUF).
