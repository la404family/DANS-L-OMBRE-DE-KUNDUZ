# Documentation : fn_task_fin.sqf

Ce document décrit le fonctionnement du script `fn_task_fin.sqf`, responsable de la gestion de la fin de mission et de l'exfiltration des joueurs.

## Vue d'ensemble
Le script gère l'apparition d'un hélicoptère d'extraction après un délai aléatoire, son atterrissage précis sur une zone désignée, la gestion de l'embarquement des joueurs, et la fin de la mission.

## Détails Techniques

### 1. Initialisation et Délais
*   **Condition de lancement** : Exécuté uniquement sur le serveur.
*   **Délai d'activation** : Le script attend entre **2100 et 2700 secondes** (35 à 45 minutes) avant de lancer la séquence d'extraction.

### 2. Détermination des Positions
Le script recherche dynamiquement les points clés :
*   **Zone d'atterrissage (LZ)** :
    1.  Objet `heli_fin` (Priorité 1)
    2.  Marqueur `marker_4` (Priorité 2)
    3.  Marqueur `respawn_west` (Défaut)
*   **Point d'apparition Hélicoptère** :
    1.  Objet `heli_fin_spawn` (Priorité 1)
    2.  Position aléatoire à **3000m** de la LZ (Défaut)

### 3. Création des Actifs
*   **Hélicoptère** : Classe `amf_nh90_tth_transport` (NH90 Caïman).
*   **Équipage** :
    *   Création d'un groupe BLUFOR (Pilote, Copilote, Mitrailleurs).
    *   **Configuration IA** : Comportement `CARELESS`, mode combat `BLUE` (Ne tire jamais, ignore les menaces).
    *   **Équipement** : Force le loadout `B_AMF_UBAS_DA_SUA_HK416` et applique un casque pilote aux pilotes.
    *   **Protection** : `allowDamage false` (Invulnérable).

### 4. Séquence d'Atterrissage (4 Phases)
Le script utilise un système de navigation personnalisé pour garantir un atterrissage précis :
1.  **Transit** : Vol haute altitude (100m) et vitesse maximale vers un point d'approche (500m de la LZ).
2.  **Approche Finale** : Ralentissement et descente à 50m d'altitude.
3.  **Stationnaire** : Positionnement précis au-dessus de la LZ (< 20m d'écart horizontal).
4.  **Descente Forcée** :
    *   Arrêt des moteurs IA (`doStop`, `land "GET IN"`).
    *   Application continue de `setVelocity` pour forcer une descente verticale douce (-3 m/s).
    *   Correction horizontale active pour contrer la dérive du vent ou de l'IA.
    *   Arrêt complet une fois au sol (`setFuel 0`).

### 5. Gestion de l'Embarquement
*   **Ouverture** : La rampe arrière s'ouvre automatiquement au sol.
*   **Tâche** : La tâche "EXFILTRATION" (`task_evacuation`) est assignée aux joueurs.
*   **Détection des Joueurs** :
    *   Une boucle vérifie toutes les **10 secondes** si tous les joueurs **vivants** et **connectés** sont à bord.
    *   Affiche un message de progression (ex: "2/4 joueurs vivants à bord").
    *   Le décollage ne se déclenche que lorsque 100% des survivants sont dans l'hélicoptère.

### 6. Phase Finale (Exfiltration)
Une fois l'embarquement validé :
1.  Fermeture de la rampe.
2.  Les joueurs sont cachés (`hideObjectGlobal`) et rendus invulnérables.
3.  Lancement de la musique `outro_00`.
4.  Destruction (dégâts complets) de toutes les entités hostiles (Est, Indépendant, Résistance) dans un rayon de 1km (Nettoyage de zone).
5.  Décollage et vol vers le point de sortie (`heli_fin_direction` ou opposé de l'approche).
6.  Fin de mission (`BIS_fnc_endMission` type "END1").
