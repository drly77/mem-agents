---
name: pas-de-force-push
description: Jamais de git push --force sur main ou une branche partagée
metadata:
  type: feedback
---

Ne jamais réécrire l'historique d'une branche que quelqu'un d'autre utilise : pas de `git push --force`
sur main ni sur une branche partagée. Sur sa propre branche, `--force-with-lease` seulement.

**Why:** un force push a effacé deux jours de commits d'une collègue.
**How to apply:** en cas de conflit, rebaser localement puis ouvrir une nouvelle branche si elle est partagée.
