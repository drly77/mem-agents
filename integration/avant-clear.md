---
description: Préparer un /clear ou un /compact — point de reprise neuf dans la mémoire, ancien point archivé mot pour mot
---
La session va être vidée (/clear) ou compactée (/compact). Prépare ta reprise, et rien d'autre ; si une tâche est au milieu d'une étape, termine-la d'abord.

1. Relis ton point de reprise actuel : `project/point-de-reprise.md` (ou la note de `$MEM_POINT_NOTE`) dans le dossier mémoire, que `mem etat` affiche ; puis ce que tu as fait depuis.
2. Écris le point neuf dans un fichier temporaire. Il commence par `## POINT DE REPRISE JJ/MM HHhMM (avant /clear)` ou `(avant /compact)` (heure : `date`) et contient :
   - l'état vérifié en direct (branche, dernier commit, ce qui est déployé), sinon « dernier état connu … » ;
   - les travaux en cours : fichiers, commits, branches, commandes de fond et leurs journaux ;
   - les décisions prises, avec leur raison ;
   - ce qui attend une réponse ou un accord ;
   - la prochaine étape ;
   - une section `### À FAIRE EN PREMIER après le /clear ou le /compact` : les commandes à relancer, les vérifications à refaire.
   Tout ce qui n'est pas dans ce point sera perdu au /clear (un /compact n'en garde qu'un résumé). Jamais de secret : `mem point` refuse une ligne qui en a l'air.
3. `mem point <fichier>` : l'ancien point part mot pour mot dans `archive/point-de-reprise.md` (ou `$MEM_POINT_ARCHIVE`), le contrôle de perte vérifie qu'aucune ligne n'a disparu, et le dossier mémoire est commité s'il est un dépôt git. S'il refuse, rien n'est changé : corrige et relance.
4. Dis en une ligne que tu es prêt (taille du point, commit éventuel).
