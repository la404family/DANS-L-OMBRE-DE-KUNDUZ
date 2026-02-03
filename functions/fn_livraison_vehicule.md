# Documentation : fn_livraison_vehicule.sqf

## Description
Ce script gère la livraison héliportée d'un véhicule léger (`amf_pvp_01_top_TDF_f`) par élingage (sling loading). Il utilise un hélicoptère de transport qui livre le véhicule à une position cible, le dépose au sol, puis retourne à sa base.

## Logique du Code

### 1. Initialisation et Spawn
*   **Sécurité Serveur** : Exécution exclusive sur le serveur.
*   **Paramètres** : Position cible (`_targetPos`), avec validation de la coordonnée Z.
*   **Configuration** :
    *   Hélicoptère : `B_AMF_Heli_Transport_01_F`
    *   Véhicule à livrer : `amf_pvp_01_top_TDF_f`
    *   Altitude de vol : 150m
    *   Distance de spawn : 2000m
*   **Création Véhicule** : Tentative de création de l'hélicoptère (5 essais max).
*   **Équipage** : Crée un groupe BLUFOR avec pilote, copilote et artilleurs pour protéger l'appareil. Comportement `CARELESS` (ignorer menaces), `COMBAT MODE RED` (feu à volonté), `SPEED FULL`.

### 2. Attachement de la Charge (Cargo)
*   Création du véhicule cible sous l'hélicoptère.
*   Modification de la masse du véhicule à 800kg pour faciliter le transport.
*   Attachement via `setSlingLoad`.

### 3. Audio et Notification
*   Diffusion de sons radio confirmant la livraison via `remoteExec` à tous les joueurs.

### 4. Séquence de Livraison (Processus Parallèle)

#### A. Sélection du Point de Largage
*   Recherche du waypoint de livraison le plus proche (`waypoint_livraison_XX`).
*   À défaut, recherche d'une zone plate et sécurisée dans un rayon de 500m autour de la cible.
*   Création d'un marqueur temporaire (Bleu, "Pickup") sur le point de largage exact.

#### B. Approche Rapide
*   L'hélicoptère se dirige vers la zone à pleine vitesse.
*   Attente d'arrivée à moins de 200m de distance.

#### C. Phase de Descente
*   Ralentissement et stabilisation à 10m d'altitude (`_hoverHeight`).
*   Positionnement précis au-dessus de la cible (< 3m).
*   Arrêt complet (`doStop`).

#### D. Descente Finale et Largage
*   Descente progressive de l'altitude de vol jusqu'à ce que le véhicule touche le sol ou que l'hélicoptère soit dangereusement bas (< 4m).
*   Une fois le contact sol détecté :
    *   Détachement des cordes (`ropeDestroy`).
    *   Rétablissement de la physique du véhicule (masse originale, vélocité nulle).
    *   Activation des dégâts sur le véhicule.

#### E. Retour Base
*   L'hélicoptère remonte à 150m.
*   Retour vers le point de spawn initial.
*   Suppression de l'hélicoptère et de l'équipage une fois distant (> 1500m) ou après timeout (3 minutes post-largage).
