# Documentation : fn_ezan.sqf

## Description
Ce script gère la lecture périodique de l'appel à la prière ("ezan") depuis les minarets de la carte. Il s'exécute uniquement sur le serveur pour garantir une synchronisation globale.

## Logique du Code

### 1. Configuration Initiale
*   **Vérification Serveur** : Le script s'arrête immédiatement s'il n'est pas exécuté sur le serveur.
*   **Paramètres** :
    *   `_soundRange` : Portée du son définie à **2500 mètres**.
    *   `_minaretsVars` : Liste des noms de variables associés aux objets minarets (`"ezan_00"`, `"ezan_01"`, `"ezan_02"`).

### 2. Délai Initial
Avant de commencer la boucle principale, le script attend un temps aléatoire compris entre **5 et 15 minutes** (`sleep (300 + (random 600))`). Cela permet de décaler le premier appel par rapport au début de la mission.

### 3. Boucle Principale
Le script entre dans une boucle infinie (`while {true}`) qui répète les actions suivantes :

#### A. Parcours des Minarets
Pour chaque minaret défini dans `_minaretsVars` :
1.  **Récupération de l'objet** : Cherche l'objet correspondant au nom de variable dans l'espace de noms de la mission via `missionNamespace getVariable`.
2.  **Vérification** : Si l'objet existe (`!isNull`) :
    *   **Détection des Joueurs** : Recherche tous les joueurs (`allPlayers`) situés à moins de **2500m** (`_soundRange`) du minaret.
    *   **Lecture du Son** : Si au moins un joueur est à portée, le son `"ezan"` est joué en 3D sur le minaret via `say3D`. Cette commande est exécutée à distance (`remoteExec`) uniquement sur les clients des joueurs concernés.
3.  **Attente** : Une micro-pause de **0.05 seconde** est effectuée entre chaque minaret pour éviter de surcharger le script.

#### B. Intervalle
Une fois tous les minarets traités, le script marque une pause de **30 minutes** (`sleep 1800`) avant de relancer le cycle d'appel à la prière.
