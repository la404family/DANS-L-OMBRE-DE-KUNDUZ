# Documentation : fn_task01.sqf

Ce fichier gère la logique de la tâche "Task01" (Récupération de Renseignement) qui consiste à localiser et neutraliser un officier insurgé pour récupérer des documents secrets.

## Logique du Script

### 1. Sélection des Lieux et Spawn
*   Le script attend que la fonction `MISSION_fnc_applyCivilianTemplate` soit disponible.
*   Il scanne les objets nommés `waypoint_invisible_000` à `waypoint_invisible_340`.
*   Il sélectionne aléatoirement **3 lieux** parmi ceux trouvés.

### 2. Création des Unités (Officiers et Gardes)
Pour chacun des 3 lieux sélectionnés, un groupe OPFOR est créé :
*   **Officier** :
    *   Classe : `O_officer_F`.
    *   Apparence : Utiise le template civil (`Mission_fnc_applyCivilianTemplate`).
    *   Équipement spécifique ajouté après le template :
        *   Sac : `B_Messenger_Coyote_F`.
        *   Arme : `uk3cb_ak47` + lampe `rhs_acc_2dpZenit`.
        *   Munitions : 3 chargeurs `rhs_30Rnd_762x39mm_bakelite` dans le sac + 1 chargeur engagé.
*   **Gardes** :
    *   Nombre aléatoire entre 2 et 8 gardes par officier.
    *   Classe : `O_Soldier_F`.
    *   Même logique d'apparence et d'équipement que l'officier (Template civil + AK47/Sac messenger).
*   **Comportement** : Les groupes patrouillent dans un rayon de 25m autour de leur point de spawn (`BIS_fnc_taskPatrol`).

### 3. Gestion de la Cible
*   Un seul des 3 officiers créés est désigné comme la "Vraie Cible" (`MISSION_Task01_Target`).
*   La tâche "Task01" est créée pour tous les joueurs (`BIS_fnc_taskCreate`) avec pour description : "Récupérer les documents secrets détenus par un officier insurgé..."

### 4. Gestion des Marqueurs (Boucle)
Un processus parallèle surveille l'état des officiers tant que la mission n'est pas terminée :
*   **Marqueurs Officiers** :
    *   Chaque officier vivant est marqué par un point rouge (`mil_destroy`) nommé "Cible Potentielle".
    *   Si un officier meurt, son marqueur est **supprimé immédiatement**.
*   À la fin de la mission (succès), tous les marqueurs restants (officiers et documents) sont supprimés.

### 5. Logique de Récupération des Documents
Un second processus surveille la mort de l'officier cible (`_target_officer`) :
1.  **Apparition des Documents** :
    *   Dès que l'officier cible meurt, un objet `Land_Document_01_F` est créé à sa position.
    *   Position précise : `[(Pos X offset + 0.2), Pos Y, 0]`.
2.  **Marqueur Document** :
    *   Une croix blanche (`mil_objective`) nommée "Documents" apparaît sur la position du document.
3.  **Action Joueur** :
    *   Une action "Fouiller le corps / Récupérer documents" est ajoutée à l'officier mort.
    *   Si activée :
        *   Le document est supprimé.
        *   La tâche passe en "SUCCEEDED".
        *   La variable `MISSION_Task01_Complete` passe à `true`.

### 6. Conséquences de la Fin de Mission
Une fois les documents récupérés (`MISSION_Task01_Complete` est vrai) :
*   Le script analyse tous les groupes ennemis créés pour cette tâche.
*   Pour chaque unité ennemie encore vivante :
    *   **Distance > 1200m** du joueur le plus proche : L'unité est supprimée.
    *   **Distance <= 1200m** : L'unité passe en mode `COMBAT`, vitesse `FULL`, et reçoit l'ordre de se déplacer sur la position du joueur le plus proche (Contre-attaque/Traque).
