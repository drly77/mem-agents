---
name: deploiement
description: Comment la Boutique part en production — CI seule, depuis main, après relecture
metadata:
  type: project
---

Seule la CI met en production : un humain ne lance jamais le script de déploiement à la main.
La branche main est déployée chaque soir à 19 h, si la revue de code est approuvée et la suite verte.

**Why:** le 2026-03-02, un déploiement manuel depuis une branche locale a remis en ligne un correctif retiré.
**How to apply:** pour livrer, fusionner dans main et attendre le train de 19 h ; en urgence, déclencher le job « deploy » de la CI.
