# Documentation de `fn_spawn_brothers_in_arms.sqf`

Ce script gère le système de recrutement "Frères d'armes", permettant au joueur de renforcer son escouade avec des unités IA ou des clones de lui-même.

## Modes de Fonctionnement

Le script utilise un système de `switch` sur le paramètre `_mode` pour gérer les différentes actions :

### 1. INIT (`INIT`)
*   **Contexte** : Exécuté au lancement de la mission (côté client uniquement).
*   **Actions** :
    *   Ajoute l'action "Recruter des frères d'armes" au joueur.
    *   L'action n'est visible que dans la zone définie par `brothers_in_arms_request`.
    *   Lance une boucle de sécurité qui repousse le joueur s'il entre dans la zone d'apparition des unités (`brothers_in_arms_spawner_trigger`), évitant ainsi les collisions lors du spawn.

### 2. Ouverture de l'Interface (`OPEN_UI`)
*   **Actions** :
    *   Crée le dialogue `Refour_Recruit_Dialog` (ID 8888).
    *   Récupère la liste des véhicules/unités compatibles (même camp, simulation "soldier", scope public).
    *   **Filtrage et Tri** :
        *   Trie les unités en deux catégories : **AMF** (si "AMF", "B_AMF" ou "France" dans le nom/classe) et **Autres**.
        *   Trie alphabétiquement chaque catégorie.
    *   **Peuplement de la liste** :
        1.  Ajoute l'option spéciale "Un soldat comme moi !" en tête.
        2.  Ajoute un en-tête pour les unités AMF, suivi des unités AMF.
        3.  Ajoute un en-tête pour les Autres unités, suivi des autres unités.
    *   Initialise le compteur d'unités (limite max: 14).

### 3. Ajout d'Unité (`ADD`)
*   **Contexte** : Lors du clic sur le bouton "AJOUTER".
*   **Logique** :
    *   Vérifie si la limite de 14 unités (groupe actuel + sélection) est atteinte.
    *   Bloque la sélection des en-têtes (catégories vides).
    *   Ajoute l'unité sélectionnée à la liste temporaire `MISSION_selectedBrothers`.
    *   Gère l'affichage spécifique (couleur dorée) pour l'option "Comme moi".
    *   Met à jour le compteur avec des codes couleurs (Vert/Orange/Rouge).

### 4. Validation et Spawn (`VALIDATE`)
*   **Contexte** : Lors de la confirmation.
*   **Processus de Spawn** :
    *   Ferme le dialogue et lance un thread séparé (`spawn`).
    *   Pour chaque unité sélectionnée :
        1.  **Effets Visuels** : Crée une fumigène blanche et des particules à la position du spawn (`brothers_in_arms_spawner` ou relative au joueur).
        2.  **Délai** : Attend 0.4s pour l'effet de fumée.
        3.  **Création** :
            *   Si "Comme moi" : Clone le joueur (équipement, mais visage aléatoire).
            *   Sinon : Crée l'unité standard.
        4.  **Configuration** :
            *   Applique la voix du joueur (`setSpeaker`).
            *   Rend l'unité jouable (`addSwitchableUnit`).
            *   Applique l'insigne du joueur.
        5.  **Mouvement** : Ordonne de se déplacer vers la sortie (`brothers_in_arms_spawner_1`).
        6.  **Intégration** : Rejoint le groupe du joueur.
        7.  **Temporisation** : Attend 2 secondes entre chaque unité.

### 5. Réinitialisation (`RESET`)
*   **Action** : Supprime toutes les unités IA du groupe du joueur.
*   **Détail** : Ne touche pas aux joueurs humains, seulement aux IA.
*   Met à jour le compteur si l'interface est ouverte.

## Configuration Requise
*   **Dialogues** : `Refour_Recruit_Dialog` avec les IDCs 1500 (Dispo), 1503 (Sélection), 1502 (Compteur).
*   **Objets Mission** :
    *   Trigger/Marqueur `brothers_in_arms_request` (Zone d'action).
    *   Objet `brothers_in_arms_spawner` (Point d'apparition).
    *   Trigger `brothers_in_arms_spawner_trigger` (Zone de sécurité).
    *   Objet `brothers_in_arms_spawner_1` (Point de sortie).
