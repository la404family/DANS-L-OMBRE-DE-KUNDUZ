
### 6. Fichier : `functions/fn_addAction_search.sqf`
**Statut :** Fonctionnel, mais impact performance potentiel sur la condition.

-   **Performance (Condition `addAction`) :**
    -   La condition (paramètre 8) exécute `nearestObjects` et `buildingPos` *à chaque frame* (ou presque) lorsque le menu est ouvert ou évalué.
    -   `count (nearestObjects [_target, ['House', 'Building'], 50] select {count (_x buildingPos -1) > 0}) > 0` est extrêmement lourd pour une condition d'interface.
    -   *Optimisation impérative : utiliser une variable d'état mise à jour par une boucle lente (`sleep 2`), comme pour les autres actions.

