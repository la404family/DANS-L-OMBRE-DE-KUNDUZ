# Documentation Technique : fn_task04.sqf

Ce document explique la logique fonctionnelle du script `fn_task04.sqf`, généré exclusivement à partir de l'analyse du code source.

## Description Globale
Ce script gère une mission dynamique persistante ("Task 04") qui se déroule côté serveur. Elle implique la création d'un chef de milice et de ses gardes à une position aléatoire, une interaction avec les joueurs, et la résolution de scénarios aléatoires (succès, trahison ou mutinerie).

## Pré-requis et Initialisation
*   **Exécution Serveur** : Le script se termine immédiatement s'il n'est pas exécuté sur le serveur (`!isServer`).
*   **Debug** : Une variable `MISSION_TASK04_Debug` permet d'afficher les logs dans le chat système.
*   **Logs** : Une fonction interne `MISSION_fnc_logTask04` gère les messages de diagnostic.

## Fonctions Utilitaires Internes

### `MISSION_fnc_task04_createMilitia`
Crée une unité de milice (Indépendant).
*   **Types** : Officier (`I_G_officer_F`) si chef, sinon Soldat (`I_G_Soldier_F`).
*   **Positionnement** : Ajuste la hauteur (Z + 0.7m) pour éviter le clipping au sol.
*   **Invulnérabilité temporaire** : 3 secondes au spawn.
*   **Personnalisation** : Applique un template civil via `MISSION_fnc_applyCivilianTemplate` si disponible.
*   **Équipement** : Retire les armes par défaut. Donne un pistolet (`hgun_Rook40_F`) au chef, et un fusil (`arifle_Mk20_F`) aux gardes.
*   **Comportement** : Mode "SAFE".

### `MISSION_fnc_task04_convertSide`
Change le camp d'une unité existante (utilisé pour les trahisons/mutineries).
*   **Méthode** : Crée une nouvelle unité du nouveau camp (`_newSide`) à la même position exact, avec la même direction, visage et loadout, puis supprime l'ancienne unité.
*   **Comportement** : Passe la nouvelle unité en mode "COMBAT" / "RED".

## Cycle de Vie de la Mission

### 1. Sélection de la Position
*   Le script cherche tous les objets nommés `waypoint_invisible_000` à `waypoint_invisible_340`.
*   Il en sélectionne un **aléatoirement** pour définir la position de la mission (`_missionPos`).

### 2. Spawning des Unités
*   **Chef** : Créé au centre.
    *   IA désactivée pour "MOVE" et "ANIM".
    *   Animation forcée : `Acts_CivilTalking_1`.
    *   Event Handler `AnimDone` pour boucler l'animation tant que le statut est "WAIT".
*   **Gardes** : 2 à 4 gardes générés aléatoirement autour du chef (rayon 5-20m).
    *   Ils patrouillent localement autour du chef avec des mouvements aléatoires.

### 3. Création de la Tâche
*   Un marqueur `mrk_task04_target` (Warning Orange) est créé sur la position.
*   La tâche "Task04" est assignée aux joueurs (`BIS_fnc_taskCreate`) avec le type "meet".

### 4. Interaction Joueur
Une action (`addAction`) est ajoutée sur le chef via `remoteExec` pour être visible de tous les joueurs.
*   **Condition** : Être en vie et à moins de 2 mètres.
*   **Effet** : Déclenche la sélection d'un scénario aléatoire.

## Gestion des Scénarios
Lorsqu'un joueur interagit avec le chef, un scénario est tiré au hasard (1, 2 ou 3) et exécuté via `MISSION_fnc_task04_runScenario`.

*   **Scénario 1 : Succès**
    *   Le chef donne l'information (`globalChat`).
    *   **Révélation des Mines** : Le script cherche les marqueurs `mine_0` à `mine_50`. Si un marqueur de mine existe (a une couleur), un marqueur "DANGER" (`rev_X`) est créé dessus.
    *   Tâche : **SUCCEEDED**.
    *   Le marqueur de zone est supprimé.

*   **Scénario 2 : Trahison (Ambush)**
    *   Le chef insulte les joueurs.
    *   **Conversion** : Le chef et les gardes passent côté **OPFOR** (`east`).
    *   Les unités engagent le feu sur le joueur qui a activé l'action.
    *   **Condition de fin** : La tâche passe en **SUCCEEDED** uniquement lorsque **tous** les ennemis (chef + gardes) sont morts.

*   **Scénario 3 : Mutinerie**
    *   Le chef déclare une mutinerie et donne l'info sur les mines (comme scénario 1).
    *   **Conversion** :
        *   Le Chef passe côté **BLUFOR** (`west`).
        *   Les Gardes passent côté **OPFOR** (`east`).
    *   Combat : Les gardes attaquent le chef (et les joueurs).
    *   **Condition de fin** : Attend la mort du chef OU la mort de tous les gardes.
        *   Si le Chef survit : Tâche **SUCCEEDED**.
        *   Si le Chef meurt : Tâche **FAILED**.

## Surveillance et Nettoyage

### Boucle de Contrôle (Toutes les 5 sec)
Tant que l'interaction n'a pas eu lieu :
1.  **Timeout** : Si le temps écoulé dépasse 1 heure (`3600`s) ET aucun joueur n'est à moins de 1200m -> Tâche **CANCELED**, suppression du marqueur, fin de la mission actuelle.
2.  **Mort Prématurée** : Si le chef meurt avant l'interaction -> Tâche **FAILED**, fin de la mission.

### Nettoyage (Garbage Collector)
Une fois la mission terminée (Succès, Échec ou Annulation) :
*   Attente que tous les joueurs soient à plus de **1500m** de la position.
*   Suppression de toutes les unités (Chef + Gardes) et du groupe.

### Redémarrage
*   Après le nettoyage, le script attend entre 5 et 10 minutes (`300 + random 300` secondes).
*   Il se relance lui-même (`[] spawn Mission_fnc_task04`) pour générer une nouvelle mission ailleurs.
