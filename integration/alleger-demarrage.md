---
description: Alléger CLAUDE.md et MEMORY.md (relus à chaque tour) sans rien perdre — le détail part dans des notes que mem retrouve
---
Objectif : réduire au strict nécessaire les fichiers chargés à chaque démarrage (CLAUDE.md global et du projet, MEMORY.md), sans perdre une seule ligne. Ce qui sort de ces fichiers reste dans des notes de mémoire, et `mem search` le retrouve quand il le faut. Ne change aucune règle : tu déplaces, tu ne réécris pas le sens.

1. Mesure et sauvegarde, avant tout changement :
   - `wc -c ~/.claude/CLAUDE.md ./CLAUDE.md <dossier mémoire>/MEMORY.md` (le dossier mémoire : `mem status` l'affiche) ;
   - copie mot pour mot de chaque CLAUDE.md dans `<dossier mémoire>/archive/CLAUDE-global-AAAA-MM-JJ.md` et `archive/CLAUDE-projet-AAAA-MM-JJ.md` (extension .md : mem les indexe, et l'ancienne règle reste trouvable ; rien de CLAUDE.md ne peut donc se perdre) ;
   - puis `cp -a <dossier mémoire> <dossier temporaire>/memoire-avant` (pour le contrôle de perte de MEMORY.md et des notes, étape 5).
2. Trie chaque ligne de CLAUDE.md. Reste dans CLAUDE.md seulement ce qui doit jouer à CHAQUE tour, même quand l'agent ne pense pas à chercher :
   - les interdits et les règles de sécurité (secrets, actions irréversibles, ce qui demande un accord) ;
   - les réflexes qui déclenchent une recherche (« avant d'affirmer un état passé : `mem search` ») ;
   - l'environnement indispensable (chemins, commande des tests, environnement Python), une ligne pour chacun.
   Sort de CLAUDE.md, vers une note (`mem add --type feedback|project|reference "titre" < texte`) : l'historique, les incidents passés et leur récit, les exemples, les explications longues, les procédures détaillées, tout ce qui ne sert qu'à une tâche précise. La note garde le texte d'origine ; CLAUDE.md garde au plus une ligne qui y renvoie, si la règle doit rester visible.
3. Trie MEMORY.md : c'est un index, une ligne par règle durable (`- [Titre](fichier.md) — ce qu'il faut retenir`), jamais un état de chantier ni un compte rendu. Les lignes d'état, les dates, les points de reprise, les détails : dans les notes (une note existante si elle couvre déjà le sujet, sinon une note neuve). Les lignes retirées de MEMORY.md partent mot pour mot dans `archive/MEMORY-AAAA-MM-JJ.md` (extension .md obligatoire : check-loss ne compte que les .md). Ajoute en tête de MEMORY.md une ligne : « Tout le reste : `mem search "mots-clés"` ».
4. Ajoute à CLAUDE.md l'extrait `integration/CLAUDE.md.extrait` (s'il n'y est pas) : sans lui, l'agent ne pense pas à chercher ce qui n'est plus chargé.
5. Contrôle de perte : `mem check-loss <dossier temporaire>/memoire-avant <dossier mémoire>`. Il doit afficher 0 ligne perdue (chaque ligne d'avant existe encore, dans une note ou dans archive/). S'il signale une ligne perdue, remets-la dans une note ou dans archive/, puis relance. `mem stale` : aucun renvoi mort créé.
6. Essai : pour trois règles sorties de CLAUDE.md ou de MEMORY.md, pose la question qu'un agent se poserait (`mem search "…"`) : la note doit sortir dans les trois premiers résultats. Sinon, ajoute à la note un titre ou une description avec les mots qu'on chercherait.
7. Compte rendu en cinq lignes au plus : tailles avant et après (octets et lignes), nombre de notes créées, résultat de check-loss, et les lignes que tu as gardées dans CLAUDE.md par prudence. Si le dossier mémoire est un dépôt git, commite-le.

Ne supprime rien sans l'avoir d'abord archivé. Au moindre doute sur une règle (garder ou sortir), garde-la et signale-la dans le compte rendu.
