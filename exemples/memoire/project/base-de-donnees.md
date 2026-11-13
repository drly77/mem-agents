---
name: base-de-donnees
description: Base de la Boutique — PostgreSQL 16, migrations Alembic, sauvegarde nocturne
metadata:
  type: project
---

PostgreSQL 16 sur le serveur db1. Chaque changement de schéma passe par une migration Alembic relue,
jamais par un ALTER TABLE à la main. Sauvegarde complète chaque nuit à 2 h, gardée 30 jours.

- 2026-04-10 : la table des commandes passe en partitions mensuelles (migration 0042).
