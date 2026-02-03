# Documentation : fn_ajust_AI_skills.sqf

## Description
Ce script exécute une boucle infinie (`while {true}`) qui ajuste périodiquement les compétences de toutes les unités contrôlées par l'IA présentes dans la mission.

## Logique du Code

### 1. Boucle Principale
Le script s'exécute en boucle continue. À chaque itération, il parcourt l'ensemble des unités présentes (`allUnits`).

### 2. Filtrage des Unités
Pour chaque unité (`_x`), le script vérifie trois conditions avant d'appliquer des modifications :
- L'unité doit être **vivante** (`alive _x`).
- L'unité doit être **locale** à la machine exécutant le script (`local _x`).
- L'unité ne doit **pas être un joueur** (`!isPlayer _x`).

### 3. Ajustement par Camp (Side)

#### Pour les camps OPFOR (`east`) et INDEPENDENT (`independent`)
Si l'unité appartient à l'un de ces camps, ses compétences sont définies comme suit :
*   **Précision de tir (`aimingAccuracy`)** : Valeur aléatoire entre **0.10** et **0.25**.
*   **Stabilité de visée (`aimingShake`)** : Valeur aléatoire entre **0.10** et **0.30**.
*   **Vitesse de visée (`aimingSpeed`)** : Valeur aléatoire entre **0.10** et **0.40**.
*   **Distance de repérage (`spotDistance`)** : Valeur aléatoire entre **0.10** et **0.60**.
*   **Temps de réaction (`spotTime`)** : Valeur aléatoire entre **0.10** et **0.50**.
*   **Courage** : Fixé à **1**.
*   **Vitesse de rechargement (`reloadSpeed`)** : Fixée à **0.6**.
*   **Commandement (`commanding`)** : Fixé à **0.4**.
*   **Compétence générale (`general`)** : Fixée à **0.5**.
*   **Fuite (`allowFleeing`)** : Désactivée (**0**).

#### Pour le camp BLUFOR (`west`)
Si l'unité appartient au camp BLUFOR, ses compétences sont définies avec des valeurs plus élevées :
*   **Précision de tir (`aimingAccuracy`)** : Valeur aléatoire entre **0.35** et **0.50**.
*   **Stabilité de visée (`aimingShake`)** : Valeur aléatoire entre **0.40** et **0.60**.
*   **Vitesse de visée (`aimingSpeed`)** : Valeur aléatoire entre **0.40** et **0.60**.
*   **Distance de repérage (`spotDistance`)** : Valeur aléatoire entre **0.60** et **0.80**.
*   **Temps de réaction (`spotTime`)** : Valeur aléatoire entre **0.65** et **0.75**.
*   **Courage** : Fixé à **1**.
*   **Vitesse de rechargement (`reloadSpeed`)** : Fixée à **0.75**.
*   **Commandement (`commanding`)** : Fixé à **0.6**.
*   **Compétence générale (`general`)** : Fixée à **0.65**.
*   **Fuite (`allowFleeing`)** : Désactivée (**0**).

### 4. Cycle
Une fois toutes les unités traitées, le script marque une pause de **60 secondes** (`sleep 60`) avant de recommencer la boucle.
