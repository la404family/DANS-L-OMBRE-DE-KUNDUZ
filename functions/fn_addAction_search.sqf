// =============================================================================
// fn_addAction_search.sqf - Action de fouille de bâtiments (CQB)
// Optimisé : utilise une variable d'état mise à jour toutes les 2s
// =============================================================================

if (!hasInterface) exitWith {};

// Variable d'état pour la condition d'action (mise à jour lente)
MISSION_Search_BuildingsNearby = false;

[] spawn {
    // -------------------------------------------------------------------------
    // BOUCLE DE MISE À JOUR DE L'ÉTAT (toutes les 2 secondes)
    // Remplace la vérification per-frame dans la condition addAction
    // -------------------------------------------------------------------------
    [] spawn {
        while {true} do {
            sleep 2;
            if (!isNull player && alive player) then {
                private _nearbyBuildings = nearestObjects [player, ["House", "Building"], 50];
                private _validBuildings = _nearbyBuildings select { count (_x buildingPos -1) > 0 };
                MISSION_Search_BuildingsNearby = (count _validBuildings > 0);
            } else {
                MISSION_Search_BuildingsNearby = false;
            };
        };
    };

    // -------------------------------------------------------------------------
    // FONCTION D'AJOUT D'ACTION
    // -------------------------------------------------------------------------
    private _fnc_addSearchAction = {
        params ["_unit"];
        
        if (_unit getVariable ["MISSION_Action_Search_Added", false]) exitWith {};
        _unit setVariable ["MISSION_Action_Search_Added", true];

        _unit addAction [
            localize "STR_ACTION_SEARCH",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];

                // Récupère les bâtiments (ici on peut se permettre car c'est au clic)
                private _nearbyBuildings = nearestObjects [_caller, ["House", "Building"], 50];
                private _validBuildings = _nearbyBuildings select { count (_x buildingPos -1) > 0 };

                if (count _validBuildings == 0) exitWith {
                    systemChat "Aucun bâtiment sécurisable à proximité";
                };

                private _allPositions = [];
                { _allPositions append (_x buildingPos -1); } forEach _validBuildings;
                if (count _allPositions == 0) exitWith { systemChat "Les bâtiments proches ne sont pas accessibles."; };

                _allPositions = _allPositions call BIS_fnc_arrayShuffle;

                private _squadAI = (units group _caller) select { !isPlayer _x && alive _x && vehicle _x == _x };
                if (count _squadAI == 0) exitWith { systemChat "Aucune unité disponible pour l'assaut."; };

                {
                    _x disableAI "AUTOCOMBAT";
                    _x disableAI "SUPPRESSION";
                    _x setUnitPos "UP";
                    _x setBehaviour "AWARE";
                    _x setSpeedMode "FULL";

                    if (count _allPositions > 0) then {
                        private _assignedPos = _allPositions deleteAt 0;
                        _x doMove _assignedPos;
                    } else {
                        _x doFollow _caller;
                    };
                } forEach _squadAI;

                [_squadAI] spawn {
                    params ["_units"];
                    sleep 180;
                    {
                        if (alive _x) then {
                            _x enableAI "AUTOCOMBAT";
                            _x enableAI "SUPPRESSION";
                            _x setUnitPos "AUTO";
                            _x setSpeedMode "NORMAL";
                            _x setBehaviour "AWARE";
                        };
                    } forEach _units;
                    systemChat "Fin du nettoyage.";
                };
            },
            [],
            1.5,
            false,
            true,
            "",
            // CONDITION OPTIMISÉE : utilise la variable d'état au lieu de nearestObjects
            "leader group _target == _target && (count (units group _target select {!isPlayer _x}) > 0) && MISSION_Search_BuildingsNearby"
        ];
    };

    // -------------------------------------------------------------------------
    // BOUCLE PRINCIPALE - Détection changement de joueur
    // -------------------------------------------------------------------------
    private _lastPlayer = objNull;
    while {true} do {
        waitUntil { player != _lastPlayer };
        
        _lastPlayer = player;
        if (!isNull _lastPlayer) then {
            [_lastPlayer] call _fnc_addSearchAction;
        };
    };
};
