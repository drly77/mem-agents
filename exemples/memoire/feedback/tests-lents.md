---
name: tests-lents
description: La suite complète prend 25 minutes ; lancer d'abord les tests du module touché
metadata:
  type: feedback
---

La suite complète des tests dure environ 25 minutes. Lancer d'abord les tests du module modifié
(`pytest tests/panier`), puis la suite complète une seule fois avant de demander la relecture.

**Why:** relancer la suite entière à chaque retouche bloquait la machine de dev tout l'après-midi.
**How to apply:** suite ciblée pendant le travail, suite complète avant la revue.
