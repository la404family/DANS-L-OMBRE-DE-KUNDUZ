# Documentation de `fn_spawn_weather_and_time.sqf`

Ce script permet aux joueurs de contrôler la météo (heure, couverture nuageuse, brouillard) via une interface utilisateur dédiée.

## Modes de Fonctionnement

### 1. INIT (`INIT`)
*   **Contexte** : Initialisation client.
*   **Action** :
    *   Attend le début de la mission (`time > 0`).
    *   Ajoute l'action "Météo et Heure" (`STR_ACTION_WEATHER`) au joueur.
    *   **Condition** : Le joueur doit être dans la zone `weather_and_time_request`.

### 2. Ouverture de l'Interface (`OPEN`)
*   **Action** :
    *   Crée le dialogue `Refour_Weather_Time_Dialog` (ID 9999).
    *   Initialise et remplit les Combo Box (Listes déroulantes) :
        *   **Heure** (IDC 2100) : Choix prédéfinis (3h, 5h, 7h... 22h).
        *   **Nuages** (IDC 2101) : Pourcentage (5% à 95%).
        *   **Brouillard** (IDC 2102) : Pourcentage (0% à 2.5%).
    *   Définit la sélection par défaut sur le premier élément de chaque liste.

### 3. Application (`APPLY`)
*   **Contexte** : Lorsque le joueur valide ses choix.
*   **Logique** :
    1.  Récupère les données sélectionnées dans les listes déroulantes.
    2.  Vérifie que les sélections sont valides.
    3.  **Synchronisation Serveur** (`remoteExec` sur cible 2) :
        *   Envoie les paramètres (heure, nuages, brouillard) au serveur.
        *   **Mise à jour Heure** : Modifie l'heure (`setDate`) et force les minutes à 0.
        *   **Mise à jour Nuages** : Applique le changement immédiatement (`setOvercast`, `forceWeatherChange`).
        *   **Mise à jour Brouillard** : Applique le brouillard (`setFog`) avec une transition rapide.
        *   **Sync** : Force la synchronisation (`simulWeatherSync`).
    4.  **Retour Utilisateur** : Affiche un hint confirmant les nouvelles valeurs et ferme le dialogue.

## Configuration Requise
*   **Dialogues** : `Refour_Weather_Time_Dialog` avec IDCs 2100, 2101, 2102.
*   **Objets Mission** : Trigger/Marqueur `weather_and_time_request`.
*   **Localisation** : Clés `STR_ACTION_WEATHER`, `STR_LABEL_TIME`, `STR_LABEL_CLOUDS`, `STR_LABEL_FOG`.
