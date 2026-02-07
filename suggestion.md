# Suggestions - Points d'insertion Messages Radio

Ce document liste les emplacements où des messages radio peuvent être ajoutés dans les scripts de mission.

---

## 1. `fn_task_intro.sqf` - Introduction

| Moment | Ligne(s) | Description | Exemple de message |
|--------|----------|-------------|-------------------|
| **Après débarquement** | ~231 | Quand `MISSION_intro_finished = true` | Message de bienvenue, briefing global de la mission |


---

## 2. `fn_task01.sqf` - Récupération de Renseignement

| Moment | Ligne(s) | Description | Son existant |
|--------|----------|-------------|--------------|
| **Documents récupérés** | ~150 | Après `MISSION_Task01_Complete = true` | `task01_success` ✓ |

---

## 3. `fn_task02.sqf` - Sauvetage d'Otage

| Moment | Ligne(s) | Description | Son existant |
|--------|----------|-------------|--------------|
| **Début mission** | ~129 | Après création tâche | ❌ À ajouter |
| **Hélico en approche** | ~240 | Après spawn hélico | ❌ À ajouter |
| **Embarquement terminé** | Variable | Quand otage + joueurs dans hélico | ❌ À ajouter |
| **Otage mort (échec)** | ~141 | Quand `!alive _hostage` | ❌ À ajouter |

---

## 4. `fn_task03.sqf` - Crash Hélicoptère

| Moment | Ligne(s) | Description | Son existant |
|--------|----------|-------------|--------------|

❌ Trouver la ligne de fin de mission pour message : "mission accomplished" 


---

## 5. `fn_task04.sqf` - Négociation Milice

| Moment | Ligne(s) | Description | Son existant |
|--------|----------|-------------|--------------|
| **Scénario 1 - Succès** | ~229 | Mines révélées | ❌ À ajouter |
| **Scénario 2 - Trahison** | ~245 | Combat déclenché | ❌ À ajouter |
| **Scénario 3 - Mutinerie** | Variable | Chef rejoint BLUFOR | ❌ À ajouter |


---

## 6. `fn_task05.sqf` - Guerre Civile (Observation Drone)

| Moment | Condition / Ligne approx. | Description | Suggestion Audio / Texte Radio |
|--------|---------------------------|-------------|--------------------------------|
| **Début de mission** | `taskCreate` (~Ligne 34) | Le drone est déployé, le QG informe de la situation. | **QG :** "Drone en position. Conflit imminent entre factions locales. Observez et confirmez l'engagement. Ne tirez pas sauf si nécessaire." |
| **Combat Déclenché** | `MISSION_Task05_CombatStarted = true` (~Ligne 327) | Le combat éclate entre OPFOR et INDEP. | **QG :** "Contact confirmé ! Ils s'entretuent. Maintenez la surveillance. Laissez-les s'affaiblir." |
| **Victoire (OPFOR éliminés)** | `_opforAlive == 0` (~Ligne 374) | Tous les ennemis sont morts, les alliés INDEP survivent. | **QG :** "Cibles OPFOR neutralisées. Bon travail. Les survivants INDEP se replient. Terminé." |
| **Échec (INDEP éliminés)** | `_indepAlive == 0` (~Ligne 365) | Tous les alliés sont morts. | **QG :** "Merde, tous les contacts alliés sont perdus. Mission compromise. Repliez-vous immédiatement !" |

