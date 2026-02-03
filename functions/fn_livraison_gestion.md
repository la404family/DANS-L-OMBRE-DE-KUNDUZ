# Documentation : fn_livraison_gestion.sqf

## Description
Ce script agit comme le système central de gestion pour les supports de mission (livraison de véhicules, munitions, et soutien aérien rapproché - CAS). Il gère l'initialisation des disponibilités, le traitement des demandes des joueurs (Request) et l'exécution serveur (Execute), ainsi que les délais de récupération (Cooldown).

## Logique du Code

Le script fonctionne selon trois modes distincts passés en premier paramètre (`_mode`) : `"INIT"`, `"REQUEST"`, et `"EXECUTE"`.

### 1. Mode "INIT" (Initialisation)
Ce mode configure l'état initial des supports au début de la mission.
*   **Protection Unique** : Utilise une variable `MISSION_Livraison_Local_Init` pour s'assurer que l'initialisation ne se lance qu'une seule fois par machine.
*   **Côté Serveur (`isServer`)** :
    *   Initialise le cooldown global `MISSION_Delivery_Global_Cooldown` à `false`.
    *   Lance trois processus parallèles (`spawn`) qui débloquent progressivement les supports après un délai aléatoire (120 à 240 secondes) :
        *   `MISSION_Unlock_Vehicle` (Véhicule)
        *   `MISSION_Unlock_Ammo` (Munitions)
        *   `MISSION_Unlock_CAS` (Soutien Aérien)
*   **Côté Client (`hasInterface`)** :
    *   Lance une boucle infinie (`while {true}`) pour gérer le menu de communication du joueur (`BIS_fnc_addCommMenuItem`).
    *   Surveille les variables de déblocage (`MISSION_Unlock_...`). Dès qu'un support devient disponible (variable à `true`), il ajoute l'option correspondante au menu radio du joueur et affiche un message de notification (`systemChat`).
    *   Gère le changement d'unité du joueur (respawn/changement de corps) pour réinitialiser les IDs de menu.

### 2. Mode "REQUEST" (Demande Client)
Ce mode est appelé lorsqu'un joueur sélectionne une option dans le menu radio.
*   **Paramètres** : Reçoit le type de demande (`_type`) et la position cible (`_pos`).
*   **Vérification de Disponibilité** : Vérifie si le support demandé est bien débloqué (`MISSION_Unlock_...`). Si non, affiche un message d'erreur et quitte.
*   **Vérification du Cooldown** : Vérifie si un cooldown global est actif (`MISSION_Delivery_Global_Cooldown`).
    *   Si oui (support en cours ou délai non écoulé) : Joue une séquence audio de refus ("Radio_In", son "negatif", "Radio_Out") et quitte.
*   **Envoi au Serveur** : Si tout est valide, envoie une requête d'exécution au serveur via `remoteExec` avec le mode `"EXECUTE"`.

### 3. Mode "EXECUTE" (Exécution Serveur)
Ce mode gère le lancement effectif de la mission de support.
*   **Sécurité Serveur** : Vérifie que le code s'exécute bien sur le serveur.
*   **Double Vérification** : Revérifie le cooldown global pour éviter les doublons simultanés.
*   **Activation du Cooldown** : Active immédiatement `MISSION_Delivery_Global_Cooldown` à `true`.
*   **Lancement du Support** : Lance (spawn) le script spécifique correspondant au type demandé :
    *   `VEHICLE` -> `Mission_fnc_livraison_vehicule`
    *   `AMMO` -> `Mission_fnc_livraison_munitions`
    *   `CAS` -> `Mission_fnc_livraison_soutienAR`
*   **Gestion du Délai de Récupération** : Lance un processus parallèle pour gérer la fin du cooldown.
    *   Attend une durée aléatoire entre **240 et 420 secondes** (4 à 7 minutes).
    *   Libère le cooldown (`MISSION_Delivery_Global_Cooldown = false`).
    *   Informe tous les joueurs via le chat système que les vecteurs sont de nouveau disponibles.
