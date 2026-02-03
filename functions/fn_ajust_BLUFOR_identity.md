# Documentation : fn_ajust_BLUFOR_identity.sqf

## Description
Ce script gère l'attribution d'identités uniques et variées (noms, visages, voix, pitch) aux unités du camp BLUFOR (`west`) présentes dans la mission. Il s'exécute en boucle continue pour traiter les nouvelles unités qui apparaissent.

## Logique du Code

### 1. Listes de Noms par Ethnie
Le script définit plusieurs tableaux de noms correspondant à différentes origines ethniques :
*   **Africain** (`_names_african`)
*   **Arabe** (`_names_arab`)
*   **Asiatique** (`_names_asian`)
*   **Pacifique** (`_names_pacific`)
*   **Standard (Européen)** (`_names_standard`)

Chaque entrée contient le nom complet, le prénom et le nom de famille.

### 2. Fonction d'Application Locale (`Mission_fnc_applyIdentity_Impl`)
Cette fonction auxiliaire est exécutée sur les clients (via `remoteExec`) pour appliquer les changements visuels et sonores :
*   **Visage** (`setFace`) : Applique le visage sélectionné.
*   **Nom** (`setName`) : Applique le nom complet si les données sont valides.
*   **Voix** (`setSpeaker`) : Définit la voix de l'unité.
*   **Tonalité** (`setPitch`) : Ajuste la tonalité de la voix.
*   **Identité** (`setIdentity`) : Réinitialise l'identité par défaut.

### 3. Fonction de Traitement (`_fnc_processUnit`)
Cette fonction principale sélectionne et attribue une identité à une unité donnée :
1.  **Agrégation des Noms** : Combine toutes les listes de noms en associant chaque nom à son type ethnique ("Black", "Arab", "Asian", "Pacific", "White").
2.  **Gestion des Doublons** : Vérifie la liste globale `MISSION_UsedNames` pour éviter de réutiliser les mêmes noms. Si tous les noms ont été utilisés, la liste est réinitialisée avec un message d'avertissement dans les logs.
3.  **Sélection Aléatoire** : Choisit un nom disponible au hasard et l'ajoute à la liste des noms utilisés.
4.  **Attribution du Visage** : Sélectionne un visage aléatoire correspondant au type ethnique du nom choisi (parmi des listes prédéfinies de "Heads").
5.  **Attribution de la Voix** : Définit le "Speaker" en fonction de l'ethnie :
    *   "White" -> `Male01FRE`
    *   "Black" -> `Male02FRE`
    *   Autres -> `Male03FRE`
6.  **Variation de Tonalité** : Génère un pitch aléatoire entre 0.90 et 1.10.
7.  **Application** : Appelle `Mission_fnc_applyIdentity_Impl` via `remoteExec` pour synchroniser les changements.
8.  **Marquage** : Définit les variables `MISSION_IdentitySet` à `true` et `MISSION_Identity` avec les détails sur l'unité pour éviter un retraitement.

### 4. Boucle Principale
Le script exécute une boucle infinie (`while {true}`) :
*   Parcourt toutes les unités de la mission (`allUnits`).
*   Vérifie si l'unité est du camp **BLUFOR** (`west`), est **vivante**, et n'a **pas encore reçu d'identité** (`MISSION_IdentitySet` est false).
*   Si les conditions sont remplies, appelle `_fnc_processUnit` pour attribuer une identité.
*   Marque une pause de **45 secondes** (`sleep 45`) avant la prochaine itération.
