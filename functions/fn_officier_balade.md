# Documentation : fn_officier_balade.sqf

## Description
Ce script gère le comportement autonome des officiers (`officier_0` et `officier_1`) côté serveur. Il définit une boucle de vie alternant entre des phases de repos (assis) et des phases de patrouille continue, avec une gestion de la panique en cas de tirs.

## Configuration des Unités
Les officiers sont configurés pour être des non-combattants stricts :
*   **Invincibilité** : `allowDamage false`.
*   **Camouflage** : `setCaptive true` (ignorés par l'IA ennemie).
*   **Comportement** : `CARELESS` (insouciant), `BLUE` (ne tirent jamais).
*   **IA Désactivée** : `AUTOTARGET`, `TARGET`, `FSM`, `SUPPRESSION`, `COVER`, `AUTOCOMBAT` pour empêcher toute réaction de combat.
*   **Arme** : L'arme est forcée à l'étui (`SwitchWeapon`) au démarrage et pendant les déplacements.

## Logique Comportementale

### 1. Gestion de la Panique
*   **Déclencheur** : Événement `FiredNear` (coup de feu détecté à proximité).
*   **Réaction** : La variable `Mission_Panic` passe à `true`. L'officier interrompt immédiatement son action courante et se déplace en vitesse `FULL` (course) vers sa chaise pour s'y réfugier.

### 2. Phase "Assis" (Repos)
*   **Déplacement** : L'unité rejoint sa chaise assignée.
*   **Installation** :
    *   Vitesse réglée sur `LIMITED`.
    *   L'officier est positionné sur la chaise avec un **offset de rotation** (180° ou 0°) pour s'asseoir dans le bon sens.
    *   Animation : `HubSittingChairC_idle1`.
*   **Observation** : L'officier regarde (`doWatch` / `lookAt`) un objet cible spécifique (`dossier_0` ou `ordinateur_1`).
*   **Durée** : 180 secondes (3 minutes).
*   **Panique** : Une fois assis, l'état de panique est réinitialisé (`false`).

### 3. Phase "Patrouille" (Rondes)
*   **Déclenchement** : Après s'être levé (`AmovPercMstpSnonWnonDnon`).
*   **Trajet** : L'officier sélectionne aléatoirement entre 3 et 5 points de passage (parmi `balade_officier_0` à `balade_officier_8`).
*   **Mouvement** :
    *   Vitesse `LIMITED` (marche).
    *   Déplacement continu : **Aucune pause** aux points de passage. Dès qu'un point est atteint (< 2m), il passe au suivant.
    *   Si la panique est déclenchée pendant le trajet, la patrouille est annulée pour retourner à la phase "Assis".

## Initialisation Spécifique

| Unité | Chaise assignée | Cible du regard | Offset Rotation | Délai départ |
| :--- | :--- | :--- | :--- | :--- |
| `officier_0` | `chaise_officier_0` | `dossier_0` | 180° | immédiat |
| `officier_1` | `chaise_officier_1` | `ordinateur_1` | 0° | +5 secondes |
