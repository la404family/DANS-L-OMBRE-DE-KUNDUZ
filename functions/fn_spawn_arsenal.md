# Documentation de `fn_spawn_arsenal.sqf`

Ce script gère l'accès à l'Arsenal Virtuel de Bohemia Interactive et synchronise la voix du joueur avec son groupe IA.

## Fonctions Principales

### 1. Initialisation (`INIT`)

*   **Vérification Client** : S'assure que le script ne s'exécute que sur les machines possédant une interface (joueurs), et non sur un serveur dédié.
*   **Action Arsenal** : Ajoute une action molette "Accéder à l'Armurerie" (localisée via `STR_ACTION_ARSENAL`) au joueur.
    *   **Condition** : Le joueur doit se trouver dans la zone définie par le trigger ou marqueur `arsenal_request`.
    *   **Exécution** : Ouvre l'arsenal virtuel standard (`BIS_fnc_arsenal`).
*   **Boucle de Synchronisation** : Lance un thread (spawn) qui surveille la position du joueur.
    *   Si le joueur sort de la zone `arsenal_request` (après y avoir été), le script déclenche une synchronisation (`SYNC`).

### 2. Synchronisation (`SYNC`)

Cette partie assure que les choix de personnalisation (notamment la voix/Speaker) sont appliqués de manière cohérente au groupe.

*   **Déclencheur** : Appelée automatiquement lorsque le joueur quitte la zone de l'arsenal.
*   **Sécurité** :
    *   Vérifie que l'unité est valide et vivante.
    *   Vérifie que l'unité est bien le chef de son groupe (seul le leader impose la voix).
*   **Logique** :
    1.  Récupère la classe de voix du joueur (`speaker`).
    2.  Applique cette voix à toutes les unités IA du groupe du joueur.
    3.  **Diffusion Réseau** : Utilise `remoteExec` pour propager cette modification à tous les clients et au serveur.
        *   Ceci garantit que tous les joueurs entendent la même voix pour ce groupe.
        *   Une sécurité supplémentaire vérifie que l'application ne se fait que si le joueur local est du même camp que le leader (évite des conflits inter-factions).

## Résumé du Flux

1.  Le joueur entre dans la zone.
2.  Il ouvre l'arsenal et modifie son équipement/identité.
3.  Il quitte la zone.
4.  Le script détecte la sortie et applique la voix du joueur à toutes ses IA subordonnées.
