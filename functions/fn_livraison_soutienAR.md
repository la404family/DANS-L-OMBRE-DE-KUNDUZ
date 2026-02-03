# Documentation : fn_livraison_soutienAR.sqf

## Description
Ce script gère l'appel de soutien aérien rapproché (CAS - Close Air Support). Il fait apparaître un hélicoptère de combat qui se rend sur zone, effectue une surveillance active en tournant autour de la position cible pour engager l'ennemi, puis retourne à la base après un temps imparti.

## Logique du Code

### 1. Initialisation et Spawn
*   **Sécurité Serveur** : Exécution exclusive sur le serveur.
*   **Paramètres** : Prend la position cible (`_targetPos`) en argument.
*   **Configuration** :
    *   Hélicoptère : `B_AMF_Heli_Transport_01_F`
    *   Altitude de vol initial : 150m
    *   Altitude de combat (Loiter) : 10m (très bas)
    *   Rayon de rotation : 25m
    *   Durée de l'intervention : 120 secondes (2 minutes)
    *   Distance de spawn : 2000m
*   **Création Véhicule** : Tentative de création de l'hélicoptère (jusqu'à 5 essais).
*   **Équipage** : Crée un groupe BLUFOR (`WEST`), un pilote, un copilote, et remplit toutes les tourelles actives avec des artilleurs. L'IA est configurée pour être agressive (`COMBAT MODE "RED"`), rapide (`SPEED "FULL"`), mais "insouciante" du danger pour soi-même (`BEHAVIOUR "CARELESS"`) afin de focaliser sur l'attaque.

### 2. Audio et Notification
*   Joue une séquence audio ("Radio_In", "soutienXX", "Radio_Out") diffusée à tous les joueurs pour confirmer l'arrivée du support.

### 3. Séquence d'Attaque (Processus Parallèle)

#### A. Détermination de la Zone de Combat
*   Le script vérifie si la position cible est valide.
*   Il cherche une position plate/sûre (`isFlatEmpty`, `findSafePos`) à proximité si nécessaire.
*   Un marqueur "Attention" (Rouge) est créé sur la zone pour signaler l'intervention aux joueurs. Il disparaît une minute après la fin de la mission.

#### B. Approche
*   L'hélicoptère fonce vers la zone cible (`MOVE`, `FULL`, `CARELESS`).
*   Le script attend qu'il soit à moins de 300m.

#### C. Combat sur Zone (Loiter)
*   L'hélicoptère descend à 10m d'altitude.
*   Un waypoint de type **LOITER** (Cercler) est activé autour de la cible avec un rayon de 25m.
*   Vitesse réduite à `LIMITED` pour une meilleure visée.
*   **Boucle de Détection** :
    *   Pendant 120 secondes, le script scanne les entités ("Man", "Car", "Tank") dans un rayon de 400m.
    *   Si des ennemis (`EAST` ou `RESISTANCE`) sont détectés, ils sont "révélés" (`reveal`) au groupe de l'hélicoptère avec un niveau de connaissance maximal (4) pour forcer l'engagement immédiat.

#### D. Désengagement et Retour
*   Tous les waypoints sont supprimés.
*   L'hélicoptère remonte à 150m.
*   Il retourne vers son point d'origine.
*   Une fois loin (> 2000m) ou l'hélicoptère détruit, l'unité et son groupe sont supprimés.
