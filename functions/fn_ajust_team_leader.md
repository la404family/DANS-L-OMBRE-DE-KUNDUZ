# Documentation : fn_ajust_team_leader.sqf

## Description
Ce script s'assure qu'un joueur humain est toujours désigné comme chef de groupe (Team Leader) s'il y a une unité IA actuellement à la tête du groupe. Il est exécuté localement sur les machines disposant d'une interface (clients).

## Logique du Code

### 1. Initialisation
Le script commence par vérifier si l'instance dispose d'une interface (`hasInterface`). Si ce n'est pas le cas (serveur dédié sans joueur), il s'arrête immédiatement pour économiser des ressources.

### 2. Boucle Principale
Le cœur du script réside dans une boucle `spawn`ée qui s'exécute indéfiniment (`while {true}`).
- **Délai initial** : Une pause de 10 secondes est observée au démarrage avant d'entrer dans la boucle.
- **Fréquence** : La boucle s'exécute toutes les 5 secondes (`sleep 5`).

### 3. Vérification du Chef de Groupe
À chaque itération, le script effectue les actions suivantes :
1.  Récupère le groupe du joueur local (`group player`).
2.  Vérifie si le groupe n'est pas nul (`!isNull`).
3.  Récupère le leader actuel du groupe (`leader _group`).
4.  Vérifie si ce leader **n'est pas un joueur** (`!isPlayer _leader`).

### 4. Réassignation du Leadership
Si le leader actuel est une IA (non-joueur) :
1.  Le script parcourt toutes les unités du groupe (`units _group`).
2.  Il cherche la première unité qui est à la fois **un joueur** (`isPlayer`) et **vivante** (`alive`).
3.  Si un tel joueur est trouvé, il est désigné comme nouveau chef de groupe via la commande `selectLeader`.

Cela garantit que le commandement du groupe est transféré à un joueur humain dès que possible si une IA se retrouve en charge.
