# Documentation : fn_livraison_munitions.sqf

## Description
Ce script gère la livraison héliportée d'une caisse de munitions et de ravitaillement à une position demandée par le joueur. Il couvre l'apparition de l'hélicoptère, le chargement de la caisse, le vol jusqu'à la zone, le largage à basse altitude (sling loading), et le retour à la base.

## Logique du Code

### 1. Initialisation et Spawn
*   **Sécurité Serveur** : Le script s'exécute uniquement sur le serveur.
*   **Paramètres** : Prend la position cible (`_targetPos`) en argument. Si la coordonnée Z est manquante, elle est fixée à 0.
*   **Configuration** :
    *   Hélicoptère : `B_AMF_Heli_Transport_01_F`
    *   Caisse : `B_supplyCrate_F`
    *   Altitude de vol : 150m
    *   Distance de spawn : 2000m (direction aléatoire)
*   **Création Véhicule** : Tente jusqu'à 5 fois de créer l'hélicoptère à la position de spawn calculée. S'il échoue, le script s'arrête.
*   **Équipage** : Crée un groupe BLUFOR (`WEST`), un pilote, un copilote, et remplit toutes les tourelles actives avec des artilleurs. L'IA est configurée en mode "CARELESS" (insouciant) et "RED" (combat) pour ignorer les menaces et se concentrer sur la livraison.

### 2. Préparation de la Cargaison
*   **Création Caisse** : Une caisse de ravitaillement est créée et positionnée sous l'hélicoptère.
*   **Attachement** : La caisse est attachée par élingage (`setSlingLoad`). Sa masse est temporairement réduite à 500kg pour faciliter le vol.
*   **Remplissage Automatique** :
    *   Le script vide d'abord complètement le contenu de la caisse.
    *   Il scanne **toutes les unités BLUFOR** présentes sur la carte pour recenser leurs armes, chargeurs, objets et sacs à dos.
    *   Il remplit la caisse avec :
        *   2x chaque arme trouvée.
        *   30x chaque chargeur trouvé.
        *   10x chaque objet trouvé.
        *   2x chaque sac à dos trouvé.
        *   Ajoute spécifiquement des fumigènes (blancs et verts).

### 3. Audio et Notification
*   **Sons Radio** : Joue une séquence audio ("Radio_In", son de confirmation aléatoire "livraisonXX", "Radio_Out") diffusée globalement à tous les joueurs.

### 4. Vol et Largage (Processus Parallèle)
Le script lance un `spawn` pour gérer la phase de vol sans bloquer le serveur.

#### A. Sélection du Point de Largage
*   Le script cherche le **waypoint de livraison** le plus proche (`waypoint_livraison_000` à `127`) de la position demandée.
*   Si aucun waypoint n'est trouvé, il tente de trouver une **position plate et sûre** (`isFlatEmpty`, `BIS_fnc_findSafePos`) dans un rayon de 150m.
*   Un marqueur temporaire (Bleu, "Pickup") est créé sur la zone de largage (visible 2 minutes).

#### B. Approche
*   L'hélicoptère reçoit l'ordre de se déplacer (`doMove`) vers la zone de largage.
*   Il vole à vitesse maximale (`FULL`).
*   Le script attend que l'hélicoptère soit à moins de 200m de la cible (ou timeout de 3 minutes).

#### C. Stabilisation et Descente
*   L'hélicoptère ralentit et descend à 10m d'altitude (`_hoverHeight`).
*   Il s'approche précisément de la cible (< 3m de distance 2D ou timeout 30s).
*   Il s'arrête (`doStop`) et stabilise son altitude.
*   Il descend progressivement jusqu'à ce que la caisse touche le sol (< 3m d'altitude) ou que l'hélicoptère soit trop bas.

#### D. Largage
*   Les cordes sont détachées (`ropeDestroy`, `setSlingLoad objNull`).
*   La physique de la caisse est rétablie (vitesse nulle, verticale, masse originale).
*   La caisse devient vulnérable aux dégâts (`allowDamage true`).
*   **Auto-Destruction** : Un timer est lancé sur la caisse : après 5 minutes (300s), elle émet des fumigènes pendant quelques secondes puis est supprimée.

#### E. Retour Base et Nettoyage
*   L'hélicoptère remonte à 150m et retourne vers son point d'origine.
*   Le script attend qu'il soit loin (> 1500m) ou que 3 minutes se soient écoulées depuis le largage.
*   L'hélicoptère et son équipage sont alors supprimés pour libérer les ressources.
