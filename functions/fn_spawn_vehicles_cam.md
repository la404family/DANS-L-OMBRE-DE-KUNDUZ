# Documentation de `fn_spawn_vehicles_cam.sqf`

Ce script gère l'affichage d'une caméra de surveillance ("feed vidéo") sur un écran dans le jeu, montrant la zone d'apparition des véhicules. Ce système est optimisé pour ne s'activer que lorsque le joueur est à proximité.

## Fonctionnement

Le script s'exécute en boucle infinie sur le client (`hasInterface`).

### 1. Initialisation
*   **Attente des Objets** : Le script attend que les objets suivants soient définis et existants :
    *   `vehicles_request_2` : Zone (Trigger) où le joueur doit se trouver pour activer la caméra.
    *   `tableau_video` : L'objet physique (ex: écran TV, tableau) sur lequel l'image sera projetée.
    *   `camera_projecteur` : L'objet définissant la position de la caméra.
    *   `vehicles_spawner_1` : L'objet ciblé par la caméra (ce qu'elle regarde).
*   **État Initial** : L'écran `tableau_video` est mis au noir (texture `#(argb,8,8,3)color(0,0,0,1)`).

### 2. Activation (Joueur dans la zone)
*   Lorsque le joueur entre dans la zone `vehicles_request_2` :
    1.  **Création Caméra** : Une caméra est créée à la position de l'objet `camera_projecteur` (surélevée de 0.5m).
    2.  **Ciblage** : La caméra pointe vers l'objet `vehicles_spawner_1`.
    3.  **Rendu** : L'image de la caméra est envoyée vers une texture de rendu ("Render To Texture" ou RTT) nommée `rtt_vehicle_cam`.
    4.  **Projection** : La texture de l'objet `tableau_video` (sélection 0) est mise à jour pour afficher ce RTT (`#(argb,512,512,1)r2t(rtt_vehicle_cam,1.0)`).

### 3. Désactivation (Joueur hors zone)
*   Lorsque le joueur quitte la zone `vehicles_request_2` :
    1.  **Nettoyage** : La caméra est détruite (`camDestroy`) pour économiser les ressources.
    2.  **Écran Noir** : L'objet `tableau_video` repasse sur une texture noire.

## Optimization
Ce système de création/destruction dynamique évite d'avoir une caméra effectuant un rendu permanent ("Render Target") qui consommerait des FPS inutilement lorsque le joueur n'est pas devant l'écran.
