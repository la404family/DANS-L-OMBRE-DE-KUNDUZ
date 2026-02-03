
 

params [["_mode", ""], ["_params", []]];

 
if (isNil "MISSION_selectedBrothers") then {
    MISSION_selectedBrothers = [];
};

switch (_mode) do {
     
     
     
    case "INIT": {
         
        if (!hasInterface) exitWith {};
        
         
        waitUntil { !isNull player };
        
         
        player addAction [
            localize "STR_ADD_BROTHER",  
            {
                 
                ["OPEN_UI"] call MISSION_fnc_spawn_brothers_in_arms;
            },
            [],
            1.5, 
            true, 
            true, 
            "",
            "player inArea brothers_in_arms_request"  
        ];
        
         
         
         
        [] spawn {
            while {true} do {
                sleep 0.1;
                
                 
                if (isNil "brothers_in_arms_spawner_trigger" || isNil "brothers_in_arms_spawner_1") then {
                    continue;
                };
                
                 
                if (player inArea brothers_in_arms_spawner_trigger) then {
                     
                    hint (localize "STR_ZONE_RESERVED");
                    
                     
                    private _exitPos = getPosATL brothers_in_arms_spawner_1;
                    private _playerPos = getPosATL player;
                    private _direction = _playerPos getDir _exitPos;
                    
                     
                    private _pushDistance = 0.7;
                    private _newPos = player getRelPos [_pushDistance, _direction - (getDir player)];
                    player setPosATL [_newPos select 0, _newPos select 1, getPosATL player select 2];
                };
            };
        };
    };

     
     
     
    case "OPEN_UI": {
         
        MISSION_selectedBrothers = [];
        
         
        createDialog "Refour_Recruit_Dialog";
        
         
        waitUntil {!isNull (findDisplay 8888)};
        
        private _display = findDisplay 8888;
        private _ctrlAvailable = _display displayCtrl 1500;  
        private _ctrlSelected = _display displayCtrl 1503;   
        private _ctrlCounter = _display displayCtrl 1502;    
        
         
        lbClear _ctrlAvailable;
        lbClear _ctrlSelected;
        
         
        private _currentGroupCount = {alive _x && !isPlayer _x} count (units group player);
        
         
        _ctrlCounter ctrlSetText format ["%1 / 14", _currentGroupCount];
        
         
        if (_currentGroupCount >= 14) then {
            _ctrlCounter ctrlSetTextColor [1, 0.2, 0.2, 1];  
        } else {
            if (_currentGroupCount >= 10) then {
                _ctrlCounter ctrlSetTextColor [1, 0.8, 0, 1];  
            } else {
                _ctrlCounter ctrlSetTextColor [0.6, 1, 0.2, 1];  
            };
        };

         
        private _sideInt = (side player) call BIS_fnc_sideID;
        private _cfgVehicles = configFile >> "CfgVehicles";
        
         
        private _units = "
            (getNumber (_x >> 'scope') == 2) && 
            (getText (_x >> 'simulation') == 'soldier') && 
            (getNumber (_x >> 'side') == _sideInt)
        " configClasses _cfgVehicles;

         
        private _listAMF = [];
        private _listOther = [];

        {
            private _class = _x;
            private _displayName = getText (_class >> "displayName");
            private _className = configName _class;
            private _factionClass = getText (_class >> "faction");
            
             
            private _factionDisplayName = getText (configFile >> "CfgFactionClasses" >> _factionClass >> "displayName");
            if (_factionDisplayName == "") then { _factionDisplayName = _factionClass; };

             
            private _entryText = format ["[%1] %2", _factionDisplayName, _displayName];
            
             
             
            private _isAMF = (["AMF", _displayName] call BIS_fnc_inString) || 
                             (["AMF", _className] call BIS_fnc_inString) || 
                             (["B_AMF", _className] call BIS_fnc_inString) ||
                             (["France", _factionDisplayName] call BIS_fnc_inString);
            
            if (_isAMF) then {
                _listAMF pushBack [_entryText, _className];
            } else {
                _listOther pushBack [_entryText, _className];
            };

        } forEach _units;

         
        _listAMF sort true;
        _listOther sort true;

         
        private _textLikeMe = localize "STR_BROTHERS_LIKE_ME";
        if (_textLikeMe == "" || _textLikeMe == "STR_BROTHERS_LIKE_ME") then { _textLikeMe = "Un soldat comme moi !"; };
        
        private _likeMeIndex = _ctrlAvailable lbAdd _textLikeMe;
        _ctrlAvailable lbSetData [_likeMeIndex, "LIKE_ME"];
        _ctrlAvailable lbSetColor [_likeMeIndex, [0.85, 0.85, 0, 1]];

         
        if (count _listAMF > 0) then {
            private _headerAMF = localize "STR_HEADER_AMF"; 
            if (_headerAMF == "" || _headerAMF == "STR_HEADER_AMF") then { _headerAMF = "--- UNITÉS AMF ---"; };
            
            private _indexHeader = _ctrlAvailable lbAdd _headerAMF;
            _ctrlAvailable lbSetColor [_indexHeader, [1, 0.8, 0, 1]];  
            _ctrlAvailable lbSetData [_indexHeader, ""];  

            {
                _x params ["_text", "_data"];
                private _index = _ctrlAvailable lbAdd _text;
                _ctrlAvailable lbSetData [_index, _data];
            } forEach _listAMF;
        };

         
        if (count _listOther > 0) then {
            private _headerOther = localize "STR_HEADER_OTHER";
            if (_headerOther == "" || _headerOther == "STR_HEADER_OTHER") then { _headerOther = "--- AUTRES UNITÉS ---"; };

            private _indexHeader = _ctrlAvailable lbAdd _headerOther;
            _ctrlAvailable lbSetColor [_indexHeader, [0.7, 0.7, 0.7, 1]];  
            _ctrlAvailable lbSetData [_indexHeader, ""];

            {
                _x params ["_text", "_data"];
                private _index = _ctrlAvailable lbAdd _text;
                _ctrlAvailable lbSetData [_index, _data];
            } forEach _listOther;
        };

         
        if (lbSize _ctrlAvailable > 0) then {
            _ctrlAvailable lbSetCurSel 0;
        };
    };

     
     
     
    case "ADD": {
        disableSerialization;
        private _display = findDisplay 8888;
        if (isNull _display) exitWith {};
        
        private _ctrlAvailable = _display displayCtrl 1500;
        private _ctrlSelected = _display displayCtrl 1503;
        private _ctrlCounter = _display displayCtrl 1502;
        
         
        private _currentGroupCount = {alive _x && !isPlayer _x} count (units group player);
        private _selectedCount = count MISSION_selectedBrothers;
        private _totalCount = _currentGroupCount + _selectedCount;
        
         
        if (_totalCount >= 14) exitWith {
             
            playSound "AddItemFailed";
             
            hint localize "STR_MAX_UNITS_REACHED";
        };
        
         
        private _index = lbCurSel _ctrlAvailable;
        if (_index == -1) exitWith {};
        
        private _className = _ctrlAvailable lbData _index;
        
         
        if (_className == "") exitWith {};
        
        private _displayName = _ctrlAvailable lbText _index;
        
         
        MISSION_selectedBrothers pushBack [_className, _displayName];
        
         
        private _newIndex = _ctrlSelected lbAdd _displayName;
        _ctrlSelected lbSetData [_newIndex, _className];
        
         
        if (_className == "LIKE_ME") then {
            _ctrlSelected lbSetColor [_newIndex, [0.85, 0.85, 0, 1]];
        };
        
         
        _selectedCount = count MISSION_selectedBrothers;
        _totalCount = _currentGroupCount + _selectedCount;
        _ctrlCounter ctrlSetText format ["%1 / 14", _totalCount];
        
         
        if (_totalCount >= 14) then {
            _ctrlCounter ctrlSetTextColor [1, 0.2, 0.2, 1];  
        } else {
            if (_totalCount >= 10) then {
                _ctrlCounter ctrlSetTextColor [1, 0.8, 0, 1];  
            } else {
                _ctrlCounter ctrlSetTextColor [0.6, 1, 0.2, 1];  
            };
        };
    };

     
     
     
    case "VALIDATE": {
        disableSerialization;
        
         
        if (count MISSION_selectedBrothers == 0) exitWith {
            hint localize "STR_NO_UNITS_SELECTED";
        };
        
         
        closeDialog 1;
        
         
        private _unitsToSpawn = +MISSION_selectedBrothers;
        MISSION_selectedBrothers = [];
        
         
        private _totalUnits = count _unitsToSpawn;
        hint format [localize "STR_SPAWNING_UNITS", _totalUnits];
        
         
        [_unitsToSpawn] spawn {
            params ["_units"];
            
            private _spawnIndex = 0;
            
            {
                _x params ["_classOrType", "_displayName"];
                _spawnIndex = _spawnIndex + 1;
                
                 
                private _spawnPos = [];
                if (!isNil "brothers_in_arms_spawner" && {!isNull brothers_in_arms_spawner}) then {
                    _spawnPos = getPosATL brothers_in_arms_spawner;
                } else {
                    _spawnPos = player getRelPos [5, 0]; 
                };

                 
                 
                 
                
                 
                private _smokePos = +_spawnPos;
                _smokePos set [2, (_spawnPos select 2) + 0.5];

                 
                private _smoke = "SmokeShellWhite" createVehicle _smokePos;
                
                 
                private _source = "#particlesource" createVehicle _smokePos;
                _source setParticleParams [
                    ["\A3\Data_F\ParticleEffects\Universal\Universal.p3d", 16, 12, 8, 1],
                    "", "Billboard", 1, 3, [0, 0, 0.5], [0, 0, 2], 1, 1.5, 1, 0.3,
                    [2, 4, 8], [[1, 1, 1, 0.6], [1, 1, 1, 0.4], [1, 1, 1, 0]], [1],
                    0.1, 0.3, "", "", ""
                ];
                _source setParticleRandom [2, [1, 1, 0.5], [1, 1, 0.5], 0, 0.5, [0, 0, 0, 0.1], 0, 0];
                _source setDropInterval 0.01;
                
                 
                [_source] spawn {
                    params ["_src"];
                    sleep 3;
                    if (!isNull _src) then { deleteVehicle _src; };
                };
                
                 
                sleep 0.4;

                 
                private _tempGroup = createGroup [side player, true];
                private _newUnit = objNull;

                if (_classOrType == "LIKE_ME") then {
                     
                    _newUnit = _tempGroup createUnit [typeOf player, _spawnPos, [], 0, "CAN_COLLIDE"];
                    
                    if (isNull _newUnit) then {
                        _newUnit = _tempGroup createUnit ["B_Soldier_F", _spawnPos, [], 0, "CAN_COLLIDE"];
                    };

                    if (!isNull _newUnit) then {
                        _newUnit setUnitLoadout (getUnitLoadout player);
                        
                         
                        private _faces = [
                            "WhiteHead_01", "WhiteHead_02", "WhiteHead_03", "WhiteHead_04", "WhiteHead_05",
                            "WhiteHead_06", "WhiteHead_07", "WhiteHead_08", "WhiteHead_09", "WhiteHead_10",
                            "WhiteHead_11", "WhiteHead_12", "WhiteHead_13", "WhiteHead_14", "WhiteHead_15",
                            "WhiteHead_16", "WhiteHead_17", "WhiteHead_18", "WhiteHead_19", "WhiteHead_20",
                            "AfricanHead_01", "AfricanHead_02", "AfricanHead_03",
                            "AsianHead_A3_01", "AsianHead_A3_02", "AsianHead_A3_03",
                            "GreekHead_A3_01", "GreekHead_A3_02", "GreekHead_A3_03", "GreekHead_A3_04",
                            "PersianHead_A3_01", "PersianHead_A3_02", "PersianHead_A3_03"
                        ];
                        _newUnit setFace (selectRandom _faces);
                    };
                } else {
                     
                    _newUnit = _tempGroup createUnit [_classOrType, _spawnPos, [], 0, "CAN_COLLIDE"];
                };

                 
                if (isNull _newUnit) then {
                    deleteGroup _tempGroup;
                } else {
                     
                    if (!isNil "brothers_in_arms_spawner" && {!isNull brothers_in_arms_spawner}) then {
                        _newUnit setDir (getDir brothers_in_arms_spawner);
                    };
                    
                     
                    sleep 0.5;
                    
                     
                     
                     
                     
                    _newUnit setSpeaker (speaker player);
                    
                     
                    addSwitchableUnit _newUnit;
                    
                     
                    private _leaderInsignia = [player] call BIS_fnc_getUnitInsignia;
                    if (_leaderInsignia != "") then {
                        [_newUnit, _leaderInsignia] call BIS_fnc_setUnitInsignia;
                    };
                    
                     
                    
                     
                     
                     
                    if (!isNil "brothers_in_arms_spawner_1" && {!isNull brothers_in_arms_spawner_1}) then {
                        private _exitPos = getPosATL brothers_in_arms_spawner_1;
                        
                        _newUnit doMove _exitPos;
                        _newUnit setSpeedMode "FULL";
                        
                        private _timeout = time + 10;
                        waitUntil {
                            sleep 0.3;
                            (_newUnit distance2D _exitPos < 2) || (time > _timeout) || !alive _newUnit
                        };
                        
                        doStop _newUnit;
                    };
                    
                     
                    [_newUnit] joinSilent (group player);
                    
                     
                    hint format [localize "STR_UNIT_JOINED", _displayName];
                    
                     
                    deleteGroup _tempGroup;
                };
                
                 
                if (_spawnIndex < count _units) then {
                    sleep 2;
                };
                
            } forEach _units;
            
             
            hint format [localize "STR_ALL_UNITS_SPAWNED", count _units];
        };
    };

     
     
     
    case "RESET": {
        disableSerialization;
        
         
        private _playerGroup = group player;
        private _unitsToDelete = [];
        
         
        {
            if (!isPlayer _x && alive _x) then {
                _unitsToDelete pushBack _x;
            };
        } forEach (units _playerGroup);
        
         
        private _count = count _unitsToDelete;
        
         
        {
            deleteVehicle _x;
        } forEach _unitsToDelete;
        
         
        if (_count > 0) then {
            hint format [localize "STR_AI_RESET_COUNT", _count];
        } else {
            hint localize "STR_AI_RESET_NONE";
        };
        
         
        private _display = findDisplay 8888;
        if (!isNull _display) then {
            private _ctrlCounter = _display displayCtrl 1502;
            
             
            private _currentGroupCount = 0;  
            private _selectedCount = count MISSION_selectedBrothers;  
            private _totalCount = _currentGroupCount + _selectedCount;
            
            _ctrlCounter ctrlSetText format ["%1 / 14", _totalCount];
            
             
            if (_totalCount >= 14) then {
                _ctrlCounter ctrlSetTextColor [1, 0.2, 0.2, 1];
            } else {
                if (_totalCount >= 10) then {
                    _ctrlCounter ctrlSetTextColor [1, 0.8, 0, 1];
                } else {
                    _ctrlCounter ctrlSetTextColor [0.6, 1, 0.2, 1];
                };
            };
        };
    };
};
