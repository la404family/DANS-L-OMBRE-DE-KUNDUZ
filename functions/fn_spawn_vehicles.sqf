params [["_mode", "INIT"], ["_params", []]];
switch (_mode) do {
    case "INIT": {
        if (!hasInterface) exitWith {};
        _params params [["_unit", player]];
        if (isNull _unit) then { _unit = player; };
        waitUntil { !isNull _unit };
        if (_unit getVariable ["MISSION_vehiclesActionAdded", false]) exitWith {};
        _unit setVariable ["MISSION_vehiclesActionAdded", true];
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
            "player inArea vehicles_request_2"  
        ];
    };
    case "OPEN_UI": {
        createDialog "Refour_Vehicle_Dialog";
        waitUntil {!isNull (findDisplay 8888)};
        private _display = findDisplay 8888;
        private _ctrlList = _display displayCtrl 1500;
        lbClear _ctrlList;
        private _sideInt = (side player) call BIS_fnc_sideID;
        private _cfgVehicles = configFile >> "CfgVehicles";
        private _units = "
            (getNumber (_x >> 'scope') >= 2) && 
            (getNumber (_x >> 'side') == _sideInt)
        " configClasses _cfgVehicles;
        private _amfVehicles = [];
        private _otherVehicles = [];
        {
            private _class = _x;
            private _className = configName _class;
            private _isValidType = (_className isKindOf "Car");
            private _isExcluded = 
                (_className isKindOf "Tank") || 
                (_className isKindOf "Wheeled_APC_F") ||  
                (_className isKindOf "Air") || 
                (_className isKindOf "Ship") || 
                (_className isKindOf "StaticWeapon") ||
                (_className isKindOf "UAV");  
            if (_isValidType && !_isExcluded) then {
                private _displayName = getText (_class >> "displayName");
                private _factionClass = getText (_class >> "faction");
                private _factionDisplayName = getText (configFile >> "CfgFactionClasses" >> _factionClass >> "displayName");
                if (_factionDisplayName == "") then { _factionDisplayName = _factionClass; };  
                private _entryText = format ["[%1] %2", _factionDisplayName, _displayName];
                if (["AMF", _className] call BIS_fnc_inString) then {
                    _amfVehicles pushBack [_entryText, _className, _class];
                } else {
                    _otherVehicles pushBack [_entryText, _className, _class];
                };
            };
        } forEach _units;
        _amfVehicles sort true;
        _otherVehicles sort true;
        if (count _amfVehicles > 0) then {
            private _headerIndex = _ctrlList lbAdd (localize "STR_HEADER_AMF");
            _ctrlList lbSetColor [_headerIndex, [0.89, 0.69, 0.2, 1]];  
            _ctrlList lbSetData [_headerIndex, "HEADER"];  
            {
                _x params ["_text", "_data", "_configClass"];
                private _index = _ctrlList lbAdd _text;
                _ctrlList lbSetData [_index, _data];
                private _pic = getText (_configClass >> "picture");
                if (_pic != "") then {
                    _ctrlList lbSetPicture [_index, _pic];
                };
            } forEach _amfVehicles;
            _ctrlList lbAdd ""; 
        };
        if (count _otherVehicles > 0) then {
            private _headerIndex = _ctrlList lbAdd (localize "STR_HEADER_OTHER");
            _ctrlList lbSetColor [_headerIndex, [0.7, 0.7, 0.7, 1]];  
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
        private _indexSelection = lbCurSel _listBox;
        if (_indexSelection == -1) exitWith {
            systemChat (localize "STR_ERR_NO_VEHICLE_SELECTED");
        };
        private _classname = _listBox lbData _indexSelection;
        if (_classname == "HEADER" || _classname == "") exitWith {
             systemChat (localize "STR_ERR_INVALID_SELECTION");
        };
        private _displayName = _listBox lbText _indexSelection;
        closeDialog 1;
        [_classname, _displayName] spawn {
            params ["_classname", "_displayName"];
            if (!isNil "vehicles_request_2" && {!isNull vehicles_request_2}) then {
                private _vehiclesInArea = entities [["Car"], [], false, false] select {_x inArea vehicles_request_2};
                if (count _vehiclesInArea > 0) then {
                    {
                        deleteVehicle _x;
                    } forEach _vehiclesInArea;
                    sleep 0.5;
                };
            };
            private _spawnPos = [];
            private _spawnDir = 0;
            if (!isNil "vehicles_spawner_1" && {!isNull vehicles_spawner_1}) then {
                _spawnPos = getPosATL vehicles_spawner_1;
                _spawnDir = getDir vehicles_spawner_1;
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            } else {
                systemChat (localize "STR_DEBUG_NO_SPAWNER");
                _spawnPos = player getRelPos [10, 0]; 
                _spawnDir = getDir player;
                _spawnPos = [_spawnPos select 0, _spawnPos select 1, (_spawnPos select 2) + 0.1];
            };
            private _veh = createVehicle [_classname, _spawnPos, [], 0, "CAN_COLLIDE"];
            _veh setDir _spawnDir;
            _veh setPosATL _spawnPos;
            hint format [localize "STR_VEHICLE_AVAILABLE", _displayName];
        };
    };
    case "DELETE": {
        private _deletedCount = 0;
        if (!isNil "vehicles_request_2" && {!isNull vehicles_request_2}) then {
            private _vehiclesInArea = entities [["Car"], [], false, false] select {_x inArea vehicles_request_2};
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
