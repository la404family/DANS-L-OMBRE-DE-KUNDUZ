
/*
    Description :
    Cette fonction gère le système de spawn de véhicules (garage).
    Elle permet l'apparition de véhicules terrestres, et gère leur suppression.
    Modes : INIT, OPEN_UI, SPAWN, DELETE.
*/

params [["_mode", "INIT"], ["_params", []]];

switch (_mode) do {
    case "INIT": {
        // Condition : Interface uniquement (joueur)
        if (!hasInterface) exitWith {};

        // Récupère l'unité cible (défaut: player)
        _params params [["_unit", player]];
        
        // Sécurité : Si l'unité passée est nulle (ex: problème respawn), on utilise player local
        if (isNull _unit) then { _unit = player; };

        // Attend que l'unité soit prête
        waitUntil { !isNull _unit };
        
        // ============================================================
        // ANTI-DOUBLON: Vérifie si l'action a déjà été ajoutée
        // ============================================================
        if (_unit getVariable ["MISSION_vehiclesActionAdded", false]) exitWith {};
        _unit setVariable ["MISSION_vehiclesActionAdded", true];
        
        // Ajoute l'action d'ouverture du garage
        _unit addAction [
            localize "STR_ACTION_GARAGE", 
            {
                ["OPEN_UI"] call MISSION_fnc_spawn_vehicles;
            },
            [],
            1.5, 
            true, 
            true, 
            "",
            "player inArea vehicles_request" // Visible dans la zone dédiée
        ];

        // AJOUT SUPPORT (Menu Communications 0-8)
        if (player == _unit) then {
            [player, "VehicleDrop"] call BIS_fnc_addCommMenuItem;
            systemChat "Support logistique disponible (Menu 0-8).";
        };
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
        
        // Filtre initial : portée publique et même camp
        private _units = "
            (getNumber (_x >> 'scope') >= 2) && 
            (getNumber (_x >> 'side') == _sideInt)
        " configClasses _cfgVehicles;

        private _amfVehicles = [];
        private _otherVehicles = [];

        {
            private _class = _x;
            private _className = configName _class;
            
            // Logique de filtrage STRICTE : Uniquement Voitures et Camions
            // "Car" inclut les voitures, camions, quads, etc. dans l'héritage Arma 3
            
            private _isValidType = (_className isKindOf "Car");
            
            // Exclusions explicites de sécurité (bien que "Car" n'inclue généralement pas Tanks/Air/Ship)
            // Certains mods peuvent avoir des héritages étranges
            private _isExcluded = 
                (_className isKindOf "Tank") || 
                (_className isKindOf "Wheeled_APC_F") || // Exclusion des VBCI, AMX-10, etc.
                (_className isKindOf "Air") || 
                (_className isKindOf "Ship") || 
                (_className isKindOf "StaticWeapon") ||
                (_className isKindOf "UAV"); // Drones

            if (_isValidType && !_isExcluded) then {
                private _displayName = getText (_class >> "displayName");
                private _factionClass = getText (_class >> "faction");
                
                private _factionDisplayName = getText (configFile >> "CfgFactionClasses" >> _factionClass >> "displayName");
                if (_factionDisplayName == "") then { _factionDisplayName = _factionClass; }; // Fallback
    
                private _entryText = format ["[%1] %2", _factionDisplayName, _displayName];
                
                // Tri AMF vs Autres
                // On détecte "AMF" dans le nom de classe (insensible à la casse)
                if (["AMF", _className] call BIS_fnc_inString) then {
                    _amfVehicles pushBack [_entryText, _className, _class];
                } else {
                    _otherVehicles pushBack [_entryText, _className, _class];
                };
            };

        } forEach _units;

        // Tri alphabétique des deux listes
        _amfVehicles sort true;
        _otherVehicles sort true;

        // --- AJOUT LISTE AMF ---
        if (count _amfVehicles > 0) then {
            private _headerIndex = _ctrlList lbAdd (localize "STR_HEADER_AMF");
            _ctrlList lbSetColor [_headerIndex, [0.89, 0.69, 0.2, 1]]; // Couleur Or/Jaune pour le titre
            _ctrlList lbSetData [_headerIndex, "HEADER"]; // Marqueur pour empêcher la sélection

            {
                _x params ["_text", "_data", "_configClass"];
                private _index = _ctrlList lbAdd _text;
                _ctrlList lbSetData [_index, _data];
                
                private _pic = getText (_configClass >> "picture");
                if (_pic != "") then {
                    _ctrlList lbSetPicture [_index, _pic];
                };
            } forEach _amfVehicles;
            
            // Espaceur
            _ctrlList lbAdd ""; 
        };

        // --- AJOUT LISTE AUTRES ---
        if (count _otherVehicles > 0) then {
            private _headerIndex = _ctrlList lbAdd (localize "STR_HEADER_OTHER");
            _ctrlList lbSetColor [_headerIndex, [0.7, 0.7, 0.7, 1]]; // Couleur Grise
            _ctrlList lbSetData [_headerIndex, "HEADER"];

            {
                _x params ["_text", "_data", "_configClass"];
                private _index = _ctrlList lbAdd _text;
                _ctrlList lbSetData [_index, _data];
                
                private _pic = getText (_configClass >> "picture");
                if (_pic != "") then {
                    _ctrlList lbSetPicture [_index, _pic];
                };
            } forEach _otherVehicles;
        };

        if (lbSize _ctrlList > 0) then {
            // Sélectionner le premier élément qui n'est pas un header
            for "_i" from 0 to ((lbSize _ctrlList) - 1) do {
                if (_ctrlList lbData _i != "HEADER" && _ctrlList lbData _i != "") exitWith {
                    _ctrlList lbSetCurSel _i;
                };
            };
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
        private _classname = _listBox lbData _indexSelection;
        
        // Empêcher de sélectionner les headers
        if (_classname == "HEADER" || _classname == "") exitWith {
             systemChat (localize "STR_ERR_INVALID_SELECTION");
        };

        private _displayName = _listBox lbText _indexSelection;

        // Ferme le dialogue
        closeDialog 1;

        // Spawn dans un nouveau thread pour permettre l'attente (sleep)
        [_classname, _displayName] spawn {
            params ["_classname", "_displayName"];

            // Suppression des véhicules existants dans la zone "vehicles_request" pour éviter l'empilement
            if (!isNil "vehicles_request" && {!isNull vehicles_request}) then {
                // OPTIMISATION : Scan ciblé "Car" uniquement
                private _vehiclesInArea = entities [["Car"], [], false, false] select {_x inArea vehicles_request};
                
                if (count _vehiclesInArea > 0) then {
                    {
                        deleteVehicle _x;
                    } forEach _vehiclesInArea;
                    
                    // Attente pour éviter les collisions physique
                    sleep 0.5;
                };
            };

            // Définition de la position d'apparition
            private _spawnPos = [];
            private _spawnDir = 0;

            if (!isNil "vehicles_spawner" && {!isNull vehicles_spawner}) then {
                _spawnPos = getPosATL vehicles_spawner;
                _spawnDir = getDir vehicles_spawner;
                
                // Ajuste la hauteur (Z) légèrement pour éviter que le véhicule soit "dans" le sol
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            } else {
                systemChat (localize "STR_DEBUG_NO_SPAWNER");
                // Position par défaut derrière le joueur
                _spawnPos = player getRelPos [10, 0]; 
                _spawnDir = getDir player;
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            };

            // Processus de création du véhicule
            // "NONE" est mieux que "CAN_COLLIDE" pour les véhicules au sol pour qu'ils s'alignent au terrain, 
            // mais gardons CAN_COLLIDE si l'utilisateur n'a pas demandé de chgt là dessus, sauf que pour spawn propre : 
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
        
        if (!isNil "vehicles_request" && {!isNull vehicles_request}) then {
            // OPTIMISATION MAJEURE : Utilisation de 'entities' au lieu de 'vehicles'.
            // entities cherche uniquement les types specifiés, beaucoup plus rapide.
            // On ne cherche que "Car" (inclut camions) car c'est le seul type spawnable maintenant.
            private _vehiclesInArea = entities [["Car"], [], false, false] select {_x inArea vehicles_request};
            
            {
                deleteVehicle _x;
                _deletedCount = _deletedCount + 1;
            } forEach _vehiclesInArea;
            
            hint format [localize "STR_VEHICLES_DELETED", _deletedCount];
        } else {
            systemChat "DEBUG: vehicles_request trigger not found.";
        };
    };
};
