# Documentation : fn_spawn_vehicles.sqf

## Description
Ce script gère le système de "Garage" permettant aux joueurs de faire apparaître ou supprimer des véhicules terrestres. Il inclut l'initialisation de l'action sur le joueur, la construction de l'interface utilisateur (GUI) avec filtrage des véhicules, et la logique d'apparition physique (Spawn).

## Logique du Code

Le script fonctionne selon quatre modes passés en premier paramètre (`_mode`) : `"INIT"`, `"OPEN_UI"`, `"SPAWN"`, et `"DELETE"`.

### 1. Mode "INIT" (Initialisation)
Ce mode configure l'accès au garage pour le joueur.
*   **Vérification Client** : S'assure que le script s'exécute avec une interface client.
*   **Ajout Action** : Ajoute une action molette ("Garage") au joueur.
    *   Condition d'affichage : Le joueur doit être dans la zone définie par le déclencheur `vehicles_request_2`.
    *   Effet : Appelle la fonction avec le mode `"OPEN_UI"`.

### 2. Mode "OPEN_UI" (Ouverture Interface)
Ce mode construit et affiche la liste des véhicules disponibles.
*   **Création Dialogue** : Ouvre l'interface `Refour_Vehicle_Dialog`.
*   **Filtrage des Véhicules** :
    *   Parcourt la configuration `CfgVehicles`.
    *   Sélectionne uniquement les véhicules accessibles (`scope >= 2`) et du même camp que le joueur (`side == side player`).
    *   **Filtres Types** : Garde uniquement les classes de type `"Car"` (voitures/camions) et exclut explicitement : Tanks, APC à roues, Aéronefs, Bateaux, Armes statiques, et Drones.
*   **Tri et Catégorisation** :
    *   Sépare les véhicules en deux listes : **AMF** (si le nom contient "AMF") et **Autres**.
    *   Trie les listes par nom.
*   **Remplissage Liste (ListBox)** :
    *   Ajoute un en-tête "AMF" (couleur or) suivi des véhicules AMF.
    *   Ajoute un en-tête "AUTRES" (couleur grise) suivi des autres véhicules.
    *   Associe chaque entrée à ses données (`classname`) et son image (`picture`).

### 3. Mode "SPAWN" (Apparition)
Ce mode est déclenché par le bouton "Valider" de l'interface.
*   **Vérification Sélection** : Assure qu'un véhicule valide est sélectionné (pas un en-tête ou vide).
*   **Nettoyage Zone** :
    *   Vérifie la présence du déclencheur `vehicles_request_2`.
    *   Supprime tous les véhicules (`Car`) déjà présents dans cette zone pour éviter les collisions.
*   **Positionnement** :
    *   Cherche l'objet logique `vehicles_spawner_1` pour déterminer la position et l'orientation précises.
    *   En cas d'absence (debug), utilise une position relative à 10m devant le joueur.
*   **Création** :
    *   Ferme l'interface.
    *   Crée le véhicule (`createVehicle` avec `CAN_COLLIDE` pour éviter les explosions).
    *   Ajuste précisément la position (`setPosATL`) et l'orientation (`setDir`).
    *   Affiche un message de confirmation.

### 4. Mode "DELETE" (Suppression)
Ce mode permet de ranger/supprimer les véhicules.
*   **Zone de Suppression** : Utilise le déclencheur `vehicles_request_2` pour identifier la zone.
*   **Action** : Supprime tous les véhicules de type `"Car"` situés à l'intérieur de cette zone.
*   **Feedback** : Affiche le nombre de véhicules supprimés ou un message d'erreur si le déclencheur est introuvable.
