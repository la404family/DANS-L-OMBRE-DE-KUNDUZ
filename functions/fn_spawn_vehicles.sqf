params [["_mode", "INIT"], ["_params", []]];

switch (_mode) do {
    case "INIT": {
        // Condition : Interface uniquement (joueur)
        if (!hasInterface) exitWith {};
        
        // Attend que le joueur soit prêt
        waitUntil { !isNull player };
        
        // Ajoute l'action d'ouverture du garage
        player addAction [
            localize "STR_ACTION_GARAGE", 
            {
                ["OPEN_UI"] call MISSION_fnc_spawn_vehicles;
            },
            [],
            1.5, 
            true, 
            true, 
            "",
            "player inArea vehicles_request_2" // Visible dans la zone dédiée
        ];
    };

    case "OPEN_UI": {
        createDialog "Refour_Vehicle_Dialog";
        
        // Attend l'ouverture réelle du dialogue
        waitUntil {!isNull (findDisplay 8888)};
        
        private _display = findDisplay 8888;
        private _ctrlList = _display displayCtrl 1500;
        
        lbClear _ctrlList;

        // Récupération des véhicules
        private _sideInt = (side player) call BIS_fnc_sideID;
        private _cfgVehicles = configFile >> "CfgVehicles";
        
        // Filtre de base : portée et camp
        private _units = "
            (getNumber (_x >> 'scope') >= 2) && 
            (getNumber (_x >> 'side') == _sideInt)
        " configClasses _cfgVehicles;

        private _amfVehicles = [];
        private _otherVehicles = [];

        {
            private _class = _x;
            private _className = configName _class;
            
            // Logique de filtrage stricte (Car uniquement, pas de tank/apc/air/etc)
            if (_className isKindOf "Car") then {
                private _isExcluded = 
                    (_className isKindOf "Tank") || 
                    (_className isKindOf "Wheeled_APC_F") ||  
                    (_className isKindOf "Air") || 
                    (_className isKindOf "Ship") || 
                    (_className isKindOf "StaticWeapon") ||
                    (_className isKindOf "UAV");
                    
                if (!_isExcluded) then {
                    private _displayName = getText (_class >> "displayName");
                    private _picture = getText (_class >> "picture");
                    
                    // Categorisation
                    if (["AMF", _className] call BIS_fnc_inString) then {
                         _amfVehicles pushBack [_displayName, _className, _picture];
                    } else {
                         _otherVehicles pushBack [_displayName, _className, _picture];
                    };
                };
            };
        } forEach _units;

        // Tri alphabétique
        _amfVehicles sort true;
        _otherVehicles sort true;

        // Affichage - AMF (Or)
        if (count _amfVehicles > 0) then {
            private _headerIndex = _ctrlList lbAdd "=== AMF ===";
            _ctrlList lbSetColor [_headerIndex, [0.85, 0.64, 0.13, 1]];  
            _ctrlList lbSetData [_headerIndex, "HEADER"];  
            {
                _x params ["_name", "_data", "_pic"];
                private _index = _ctrlList lbAdd _name;
                _ctrlList lbSetData [_index, _data];
                if (_pic != "") then { _ctrlList lbSetPicture [_index, _pic]; };
            } forEach _amfVehicles;
        };

        // Affichage - Autres (Gris)
        if (count _otherVehicles > 0) then {
            if (count _amfVehicles > 0) then { _ctrlList lbAdd ""; }; // Spacer
            private _headerIndex = _ctrlList lbAdd "=== AUTRES ===";
            _ctrlList lbSetColor [_headerIndex, [0.7, 0.7, 0.7, 1]];  
            _ctrlList lbSetData [_headerIndex, "HEADER"];
            {
                _x params ["_name", "_data", "_pic"];
                private _index = _ctrlList lbAdd _name;
                _ctrlList lbSetData [_index, _data];
                if (_pic != "") then { _ctrlList lbSetPicture [_index, _pic]; };
            } forEach _otherVehicles;
        };

        if (lbSize _ctrlList > 0) then {
            _ctrlList lbSetCurSel 0;
        };
    };

    case "SPAWN": {
        disableSerialization;
        private _display = findDisplay 8888;
        private _listBox = _display displayCtrl 1500;

        // Validation
        private _indexSelection = lbCurSel _listBox;
        if (_indexSelection == -1) exitWith {
            systemChat (localize "STR_ERR_NO_VEHICLE_SELECTED");
        };

        // Récupération des données sélectionnés
        // Récupération des données sélectionnés
        private _classname = _listBox lbData _indexSelection;
        if (_classname == "HEADER" || _classname == "") exitWith {
             systemChat (localize "STR_ERR_INVALID_SELECTION");
        };
        private _displayName = _listBox lbText _indexSelection;

        // Ferme le dialogue
        closeDialog 1;

        // Spawn dans un nouveau thread pour permettre l'attente (sleep)
        [_classname, _displayName] spawn {
            params ["_classname", "_displayName"];

            // Suppression des véhicules existants dans la zone "vehicles_request_2" pour éviter l'empilement
            private _spawnPos = [];
            private _spawnDir = 0;

            if (!isNil "vehicles_spawner_1" && {!isNull vehicles_spawner_1}) then {
                _spawnPos = getPosATL vehicles_spawner_1;
                _spawnDir = getDir vehicles_spawner_1;
                
                // Nettoyage de la zone avant spawn (seulement véhicules)
                // Rayon de 6m autour du spawner
                private _nearVehicles = nearestObjects [_spawnPos, ["Car", "Tank", "Helicopter", "Motorcycle", "Air", "Ship"], 6];
                {
                    deleteVehicle _x;
                } forEach _nearVehicles;
                
                sleep 0.2; // Petite pause pour la suppression
                
                // Ajuste la hauteur (Z) légèrement
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            } else {
                systemChat (localize "STR_DEBUG_NO_SPAWNER");
                // Position par défaut derrière le joueur
                _spawnPos = player getRelPos [10, 0]; 
                _spawnDir = getDir player;
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            };

            // Processus de création du véhicule (vide)
            private _veh = createVehicle [_classname, _spawnPos, [], 0, "CAN_COLLIDE"];
            _veh setDir _spawnDir;
            _veh setPosATL _spawnPos;
            
            // Notification
            hint format [localize "STR_VEHICLE_AVAILABLE", _displayName];
        };
    };

    case "DELETE": {
        // Supprime tous les véhicules présents dans la zone du déclencheur (trigger)
        private _deletedCount = 0;
        
        if (!isNil "vehicles_request_2" && {!isNull vehicles_request_2}) then {
            private _vehiclesInArea = entities ["Car", "Tank", "Helicopter", "Motorcycle", "Air", "Ship"] select {_x inArea vehicles_request_2};
            
            {
                deleteVehicle _x;
                _deletedCount = _deletedCount + 1;
            } forEach _vehiclesInArea;
            
            hint format [localize "STR_VEHICLES_DELETED", _deletedCount];
        } else {
            systemChat "DEBUG: vehicles_request_2 trigger not found.";
        };
    };
};