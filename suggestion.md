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
| **Début mission** | ~90 | Après création de la tâche | `task01_start` ✓ |
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
| **Début (crash visible)** | ~68 | Quand hélico se crashe | A IMPLEMENTER : task03_01, task03_02, task03_03 |
❌ Trouver la ligne de fin de mission pour message : "mission accomplished" 


---

## 5. `fn_task04.sqf` - Négociation Milice

| Moment | Ligne(s) | Description | Son existant |
|--------|----------|-------------|--------------|
| **Début mission** | ~212 | Après création tâche | A IMPLEMENTER : task04_01, task04_02, task04_03 |
| **Scénario 1 - Succès** | ~229 | Mines révélées | ❌ À ajouter |
| **Scénario 2 - Trahison** | ~245 | Combat déclenché | ❌ À ajouter |
| **Scénario 3 - Mutinerie** | Variable | Chef rejoint BLUFOR | ❌ À ajouter |

