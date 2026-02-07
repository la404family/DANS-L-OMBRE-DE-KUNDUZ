# Documentation : fn_task05.sqf

Ce document détaille le fonctionnement du script `fn_task05.sqf`, qui gère une mission d'observation d'un conflit armé (Guerre Civile) entre deux factions locales.

## Vue d'Ensemble
La mission consiste à faire spawner deux factions (OPFOR et INDEP) habillées en civils mais armées, initialement neutres. Lorsque les joueurs approchent, le combat se déclenche. Les joueurs doivent observer l'affrontement via un drone fourni.
La tâche réussit lorsque toutes les forces OPFOR sont éliminées.

---

## 1. Initialisation
Le script commence par une série de vérifications et d'initialisations :
*   **Serveur uniquement** : `if (!isServer) exitWith {};`
*   **Variables Globales** :
    *   `MISSION_Task05_CombatStarted` : État du combat (Faux au départ).
    *   `MISSION_Task05_Complete` : État de la mission (Faux au départ).
    *   `MISSION_Task05_Drone` : Référence au drone (Null au départ).
*   **Attente des Templates** : Le script attend que `MISSION_CivilianTemplates` soit défini (ces templates contiennent les loadouts civils).

## 2. Sélection des Zones
Le script utilise les objets de type `waypoint_invisible_XXX` présents sur la carte :
*   **Zone 1 (Défenseurs - OPFOR)** : Choisie aléatoirement parmi tous les waypoints invisibles.
*   **Zone 2 (Attaquants - INDEP)** : Choisie aléatoirement, mais doit être à **plus de 550m** de la Zone 1.

Une tâche "Task05" de type "scout" est créée sur la position de la Zone 1.

## 3. Fonctions Internes
Trois fonctions locales sont définies pour gérer le spawning et l'habillage :

### `_fnc_applyTemplateAndIdentity`
Applique une apparence civile cohérente à une unité militaire :
*   Choisit un template aléatoire (Vêtements).
*   Gère le visage et le nom selon le sexe (Homme/Femme) et l'ethnie (Persan/Blanc).
*   Synchronise l'identité (Visage, Voix, Pitch, Nom) sur le réseau via `remoteExec`.

### `_fnc_spawnOPFOR`
Gère le spawn des défenseurs (Zone 1) :
*   Groupe **EAST**.
*   Unités initiales : `O_Soldier_F`.
*   Retire tout l'équipement militaire et applique le template civil.
*   **Délai 20s** : Donne un sac à dos et une **AK47** (uk3cb_ak47).
*   Comportement : **SAFE / LIMITED**, Patrouille rayon 100m.

### `_fnc_spawnINDEP`
Gère le spawn des attaquants (Zone 2) :
*   Groupe **INDEPENDENT**.
*   Unités initiales : `I_G_Soldier_F`.
*   Même logique d'équipement (Civil -> AK47).
*   Comportement : **SAFE / LIMITED**, Patrouille rayon 100m.

## 4. Spawning des Unités
*   **OPFOR** : 8 à 12 groupes sont créés autour de la Zone 1.
*   **INDEP** : 4 à 6 groupes sont créés autour de la Zone 2.
*   **Diplomatie** : Les factions sont initialement amies (`setFriend [..., 1]`).

## 5. Gestion du Drone
Un drone (`B_UAV_02_dynamicLoadout_F`) est créé pour les joueurs :
1.  **Spawn** : En l'air (500m) ou via la position de `heli_fin_direction`.
2.  **Configuration** : Invulnérable, Captif, Moteur allumé.
3.  **Comportement** :
    *   Suit le leader des joueurs jusqu'à 300m.
    *   Se déplace ensuite vers la Zone 1.
    *   Reste en orbite (Loiter) au-dessus de la Zone 1 (Rayon 600m, Altitude 200m).
    *   **Nettoyage** : Quitte la zone et disparait quand il est à plus de 1200 mètres des joueurs (en fin de mission).

## 6. Boucle Principale & Logique de Combat
Une boucle `while { !MISSION_Task05_Complete }` tourne toutes les 5 secondes pour gérer la mission.

### Déclenchement par Distance
La distance entre le joueur le plus proche et la Zone 1 détermine l'état :
*   **Distance A aléatoire entre 850 et 1200 mètres** :
    *   Si le combat n'a pas commencé, force le comportement **SAFE** (Calme).
*   **Distance A - 200m** = **Distance B** :
    *   Passe les unités en mode **AWARE** (Alerte).
*   **Distance B - 200m** = **Distance C** :
    *   **DÉCLENCHEMENT DU COMBAT** (`MISSION_Task05_CombatStarted = true`).
    *   Relations diplomatiques passent à **Ennemi** (0).
    *   **OPFOR** : Passe en **COMBAT / RED**.
    *   **INDEP** : Passe en **COMBAT / RED / FULL**, supprime ses waypoints et reçoit un waypoint **SAD** (Search and Destroy) sur la Zone 1.

### Maintenance
*   **Logique CQC (Close Quarters Combat)** : Toutes les 10 secondes, si le combat est actif ("Combat Started"), les unités INDEP situées à **moins de 50m** de la Zone 1 reçevront l'ordre d'attaquer l'unité OPFOR la plus proche.
*   **Ravitaillement** : Toutes les 60 secondes, les unités reçoivent des chargeurs supplémentaires pour prolonger le combat.
*   **Debug** : (1-3 sec) Affiche des marqueurs sur la carte pour suivre les unités vivantes.

## 7. Fin de Mission
La condition de victoire est l'élimination de tous les **OPFOR**.
La condition d'échec est l'élimination de tous les **INDEP**.

*   Si `_opforAlive == 0` (Victoire) :
    1.  `MISSION_Task05_Complete = true`.
    2.  Tâche définie sur **SUCCEEDED**.
    3.  **Départ des INDEP** : Les survivants INDEP rengainent et quittent la zone.
*   Si `_indepAlive == 0` (Échec) :
    1.  `MISSION_Task05_Complete = true`.
    2.  Tâche définie sur **FAILED**.

**Nettoyage final** :
*   Suppression des marqueurs de debug.
*   **Départ du Drone** : Le drone quitte la zone et est supprimé (Cas Victoire ou Échec).
