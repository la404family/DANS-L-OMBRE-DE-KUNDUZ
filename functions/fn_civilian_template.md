# Documentation : fn_civilian_template.sqf

## Description
Ce script parcourt une série d'unités prédéfinies dans l'éditeur (nommées `civil_template_00` à `civil_template_33`) pour enregistrer leurs caractéristiques (apparence, équipement, genre) dans une variable globale. Ces "templates" sont ensuite utilisés pour générer des civils aléatoires cohérents. Il supprime les unités sources après mémorisation.

## Logique du Code

### 1. Initialisation
*   **Vérification Serveur** : Le script ne s'exécute que sur le serveur.
*   **Logs** : Messages de démarrage dans le chat système et les logs serveur.
*   **Variable Globale** : Initialisation de `MISSION_CivilianTemplates` comme un tableau vide.

### 2. Boucle de Récupération (0 à 33)
Le script itère de 0 à 33 pour trouver des unités nommées `civil_template_XX` (ex: `civil_template_00`, `civil_template_05`, `civil_template_33`).

Pour chaque unité trouvée (`_unit`) :
1.  **Nettoyage** : Supprime toutes les armes, objets et équipements assignés de l'unité.
2.  **Extraction des Données** :
    *   `_type` : Classe de l'unité (`typeOf`).
    *   `_loadout` : Équipement complet (`getUnitLoadout`).
    *   `_face` : Visage (`face`).
    *   `_uniform` : Uniforme porté (`uniform`).
3.  **Détection du Genre (`_isFemale`)** :
    Analyse plusieurs critères pour déterminer si l'unité est féminine :
    *   Si le nom de l'uniforme contient "burqa", "dress", "woman" ou "female".
    *   Si le nom du visage contient "female" ou "woman".
    *   Si la variable de script `isWoman` sur l'unité est vraie.
4.  **Ajustement de la Voix (`_pitch`)** :
    *   Par défaut : **1.0**.
    *   Si femme détectée : Entre **1.2** et **1.4** (1.2 + random 0.2).
5.  **Enregistrement** : Ajoute un tableau `[_type, _loadout, _face, _isFemale, _pitch]` dans `MISSION_CivilianTemplates`.
6.  **Suppression** : Supprime l'unité source (`deleteVehicle`) pour ne pas la laisser sur la carte.

### 3. Gestion des Cas Vides
Si aucun template n'a été trouvé à la fin de la boucle (tableau vide), un template de secours ("fallback") est ajouté manuellement pour éviter les erreurs.
*   Template par défaut : `["C_man_polo_1_F", [], "PersianHead_A3_01", false, 1.0]`.

### 4. Finalisation
*   **Diffusion** : La variable `MISSION_CivilianTemplates` est diffusée à tous les clients (`publicVariable`).
*   **Logs de Fin** : Affiche le nombre total de templates mémorisés dans le chat et les logs.
