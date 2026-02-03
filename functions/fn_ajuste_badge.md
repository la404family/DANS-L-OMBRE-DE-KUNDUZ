# Documentation : fn_ajuste_badge.sqf

## Description
Ce script gère la synchronisation et l'application automatique de l'insigne "AMF_FRANCE_HV" sur toutes les unités du camp BLUFOR. Il est conçu pour s'exécuter uniquement sur le serveur.

## Logique du Code

### 1. Vérification Serveur
Le script commence par vérifier s'il s'exécute sur le serveur (`isServer`). Si ce n'est pas le cas (ex: sur une machine client), il s'arrête immédiatement pour éviter une exécution redondante.

### 2. Log de Démarrage
Un message est envoyé au journal du serveur (`diag_log`) pour indiquer le démarrage du processus de synchronisation des insignes.

### 3. Boucle Principale
Le script entre dans une boucle infinie (`while {true}`), assurant une surveillance continue tout au long de la mission.

#### A. Sélection des Unités
À chaque itération, le script filtre et sélectionne toutes les unités qui remplissent deux conditions :
*   Appartiennent au camp **BLUFOR** (`side _x == west`).
*   Sont **vivantes** (`alive _x`).

#### B. Vérification et Application
Pour chaque unité sélectionnée :
1.  Le script récupère l'insigne actuellement porté par l'unité via `BIS_fnc_getUnitInsignia`.
2.  Il compare cet insigne avec la valeur cible : `"AMF_FRANCE_HV"`.
3.  Si l'insigne actuel est différent de l'insigne cible, il force l'application de l'insigne `"AMF_FRANCE_HV"` via `BIS_fnc_setUnitInsignia`.

#### C. Pause
Une fois toutes les unités traitées, le script marque une pause de **60 secondes** (`sleep 60`) avant de recommencer le cycle.
