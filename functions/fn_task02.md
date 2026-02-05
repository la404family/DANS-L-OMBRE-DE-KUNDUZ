# Documentation : fn_task02.sqf

Ce fichier gère la mission de sauvetage d'otage ("Task02"). Voici le déroulement logique du script :

## 1. Initialisation et Sélection des Zones
*   **Vérification Serveur** : Le script ne s'exécute que sur le serveur.
*   **Attente** : Attend que la fonction `MISSION_fnc_applyCivilianTemplate` soit définie.
*   **Repérage des Lieux** :
    *   Parcourt les objets nommés `waypoint_invisible_000` à `waypoint_invisible_340`.
    *   Sélectionne aléatoirement **3 zones uniques**.
    *   Crée des marqueurs jaunes "Zone Suspecte" (`mil_unknown`) sur ces positions.

## 2. Création de l'Environnement (Spawning)
Une des 3 zones est choisie au hasard pour contenir l'otage. Pour chaque zone sélectionnée :
*   **Gardes (Opfor)** :
    *   Crée un groupe de **3 à 6 gardes** (`O_Soldier_F`) équipés d'AK47 (`uk3cb_ak47`).
    *   Applique un template civil aux gardes pour les dissimuler/habiller.
    *   Les gardes patrouillent aléatoirement dans un rayon de 25m autour du centre de leur zone.
*   **Otage (Civilian) - Uniquement dans la zone cible** :
    *   L'unité (`C_man_1`) est créée et un template civil lui est appliqué.
    *   **État** : Captif, mouvements et animations désactivés.
    *   **Animation** : Joue l'animation de prisonnier (`Acts_AidlPsitMstpSsurWnonDnon_loop`).
    *   **Action** : Une "Hold Action" intitulée "Libérer l'otage" est ajoutée sur l'unité.

## 3. Création de la Tâche
*   La tâche **"Task02"** est créée avec le statut "CREATED".
*   Objectif : Localiser et extraire le VIP.

## 4. Phase de Libération
Le script attend que l'otage soit libéré (via l'action joueur) ou qu'il meure.
*   **Si l'héritage meurt** : La tâche échoue ("FAILED") et le script s'arrête.
*   **Si l'otage est libéré** :
    *   La tâche passe en "ASSIGNED" avec la position de l'otage comme destination.
    *   L'otage se lève, redevient mobile et suit automatiquement le joueur le plus proche (vérification toutes les 5 secondes).

## 5. Réaction Ennemie
Une fois l'otage libéré :
*   Les marqueurs de zone sont supprimés.
*   **Nettoyage** : Les gardes situés à plus de 1200m sont supprimés.
*   **Traque** : Les gardes restants passent en mode "COMBAT" (Vitesse "FULL") et se déplacent vers la position du joueur le plus proche pour attaquer.

## 6. Phase d'Extraction
*   **Point d'Extraction (LZ)** : Le script cherche le `waypoint_livraison_XXX` le plus proche de l'otage.
*   **Hélicoptère** :
    *   Un `B_AMF_Heli_Transport_01_F` spawn à 2km de la LZ (altitude 500m).
    *   L'équipage (Pilote, Copilote, Gunners) est créé.
    *   L'hélicoptère se déplace vers la LZ à 50m d'altitude.
*   **Atterrissage** :
    *   Une fois proche (< 300m), l'hélicoptère atterrit (`land "GET IN"`).
    *   Une fois au sol, le moteur est coupé (`setFuel 0`).

## 7. Embarquement et Départ
*   Lorsque l'otage est à moins de 30m de l'hélicoptère :
    *   Il rejoint le groupe de l'hélicoptère et monte à bord (Cargo).
    *   L'hélicoptère redémarre (`setFuel 1`).
    *   Les ennemis intensifient la traque (reveal sur les joueurs).
*   **Départ** : Le script attend que **l'otage soit à bord ET qu'aucun joueur ne soit à bord** (Condition : `_hostageIn && !_playersIn`).
    *   *Note : Cela implique que les joueurs doivent charger l'otage mais ne pas partir avec l'hélicoptère d'extraction.*

## 8. Fin de Mission
*   L'hélicoptère se verrouille, décolle vers `[0,0,0]` (hors map) à 100m d'altitude.
*   La tâche passe en **"SUCCEEDED"**.
*   **Nettoyage final** : Une fois l'hélicoptère à plus de 2km des joueurs, il est supprimé avec son équipage et l'otage.
