# Documentation : fn_civilian_presence_logic.sqf

## Description
Ce script gère l'application des templates (apparence, équipement) et l'attribution des identités (noms) pour les civils présents dans la mission. Il s'exécute uniquement sur le serveur pour garantir une synchronisation cohérente.

## Logique du Code

### 1. Initialisation
*   **Vérification Serveur** : Le script s'arrête immédiatement s'il n'est pas exécuté sur le serveur.
*   **Bases de Données de Noms** : Deux tableaux globaux sont définis :
    *   `MISSION_CivilianNames_Male` : Contient une vaste liste de noms masculins (principalement à consonance moyen-orientale/asiatique).
    *   `MISSION_CivilianNames_Female` : Contient une vaste liste de noms féminins.
*   **Attente des Templates** : Le script attend que la variable globale `MISSION_CivilianTemplates` soit définie et non vide (cette variable est censée contenir les configurations de civils disponibles).

### 2. Fonction d'Application (`MISSION_fnc_applyCivilianTemplate`)
Cette fonction est le cœur du système. Elle prend un agent en paramètre et effectue les opérations suivantes :
1.  **Vérifications de Sécurité** :
    *   L'agent ne doit pas être nul.
    *   L'agent doit être vivant.
    *   L'agent ne doit pas être un joueur.
    *   L'agent ne doit pas avoir déjà reçu un template (vérifié via la variable `MISSION_TemplateApplied`).
2.  **Marquage** : La variable `MISSION_TemplateApplied` est définie à `true` sur l'agent pour éviter une ré-application.
3.  **Sélection du Template** : Un template est choisi aléatoirement parmi `MISSION_CivilianTemplates`. Ce template contient :
    *   Le type.
    *   L'équipement (`_loadout`).
    *   Le visage (`_face`).
    *   Le genre (`_isFemale`).
    *   La tonalité de voix (`_pitch`).
4.  **Application des Attributs** :
    *   **Visage** : Appliqué via `setFace` (diffusé globalement via `remoteExec`).
    *   **Équipement** : Appliqué via `setUnitLoadout`.
    *   **Tonalité** : Appliquée via `setPitch` (diffusé globalement).
5.  **Attribution du Nom** :
    *   Sélectionne la liste de noms appropriée (Homme/Femme) en fonction du template.
    *   Choisit un nom aléatoire dans la liste.
    *   Applique le nom complet via `setName` (diffusé globalement).

### 3. Traitement Initial
Le script récupère tous les agents existants (`agents`) qui sont de type "Homme" (`CAManBase`), vivants et non-joueurs. Pour chacun d'eux, il appelle `MISSION_fnc_applyCivilianTemplate`.

### 4. Gestion des Nouveaux Spawns
Un gestionnaire d'événement de mission (`addMissionEventHandler`) de type `"EntityCreated"` est ajouté pour gérer les unités créées dynamiquement après le début de la mission :
*   Il détecte la création de toute nouvelle entité.
*   Si l'entité est un "Homme" (`CAManBase`), un processus parallèle (`spawn`) est lancé.
*   Après un délai d'une seconde (pour laisser le temps à l'initialisation du moteur), les vérifications de validité sont refaites (vivant, non-joueur).
*   Si tout est correct, `MISSION_fnc_applyCivilianTemplate` est appelé pour appliquer le template et l'identité.
