if (hasInterface) then {
    [] spawn {
        private _bluforUnits = allUnits select { side _x == west && alive _x };
    {
        private _unit = _x;
        private _currentBadge = [_unit] call BIS_fnc_getUnitInsignia;
        if (_currentBadge != "AMF_FRANCE_HV") then {
            [_unit, "AMF_FRANCE_HV"] call BIS_fnc_setUnitInsignia;
        };
    } forEach _bluforUnits;
        diag_log "[INTRO] CLIENT: Script démarré";
        waitUntil { time > 0.1 };  
        diag_log "[INTRO] CLIENT: Engine initialisé, démarrage immédiat...";
        sleep 0.1;   
        diag_log "[INTRO] CLIENT: Début de la cinématique";
        disableSerialization;
        [] spawn {
            sleep 90;   
            disableUserInput false;
            disableUserInput true;
            disableUserInput false;
            player allowDamage true;        
            showCinemaBorder false;         
        };
        cutText ["", "BLACK FADED", 999];   
        0 fadeSound 0;                       
        showCinemaBorder true;               
        disableUserInput true;               
        waitUntil { !isNull player };
        player allowDamage false;            
        private _ppColor = ppEffectCreate ["ColorCorrections", 1500];   
        _ppColor ppEffectEnable true;
        _ppColor ppEffectAdjust [
            1,                     
            1.0,                   
            -0.05,                 
            [0.2, 0.2, 0.2, 0.0],  
            [0.8, 0.8, 0.9, 0.7],  
            [0.1, 0.1, 0.2, 0]     
        ]; 
        _ppColor ppEffectCommit 0;   
        private _ppGrain = ppEffectCreate ["FilmGrain", 2005];   
        _ppGrain ppEffectEnable true;
        _ppGrain ppEffectAdjust [0.1, 1, 1, 0.1, 1, false];   
        _ppGrain ppEffectCommit 0;
        private _targetHQ = if (!isNil "batiment_officer") then { batiment_officer } else { player };
        private _randomPosIndex1 = floor (random 341);
        private _posName1 = "";
        if (_randomPosIndex1 < 10) then { _posName1 = format ["waypoint_invisible_00%1", _randomPosIndex1]; }
        else { if (_randomPosIndex1 < 100) then { _posName1 = format ["waypoint_invisible_0%1", _randomPosIndex1]; }
        else { _posName1 = format ["waypoint_invisible_%1", _randomPosIndex1]; }; };
        private _targetCityMid = missionNamespace getVariable [_posName1, objNull];
        if (isNull _targetCityMid) then { _targetCityMid = _targetHQ; };
        private _randomPosIndex2 = floor (random 341);
        while { _randomPosIndex2 == _randomPosIndex1 } do { _randomPosIndex2 = floor (random 341); };
        private _posName2 = "";
        if (_randomPosIndex2 < 10) then { _posName2 = format ["waypoint_invisible_00%1", _randomPosIndex2]; }
        else { if (_randomPosIndex2 < 100) then { _posName2 = format ["waypoint_invisible_0%1", _randomPosIndex2]; }
        else { _posName2 = format ["waypoint_invisible_%1", _randomPosIndex2]; }; };
        private _targetCityEnd = missionNamespace getVariable [_posName2, objNull];
        if (isNull _targetCityEnd) then { _targetCityEnd = _targetHQ; };
        playMusic "intro_00";    
        3 fadeSound 1;          
        private _posCityStart = getPos _targetCityMid;
        private _cam = "camera" camCreate [(_posCityStart select 0), (_posCityStart select 1), 100];
        _cam cameraEffect ["INTERNAL", "BACK"];
        _cam camSetPos [(_posCityStart select 0) + 200, (_posCityStart select 1) - 200, 150];
        _cam camSetTarget _targetCityMid; 
        _cam camSetFov 0.65;
        _cam camCommit 0;
        waitUntil { camCommitted _cam };   
        cutText ["", "BLACK IN", 2];   
        private _posCityEnd = getPos _targetCityEnd;
        _cam camSetPos [(_posCityEnd select 0) + 80, (_posCityEnd select 1) + 80, 120];
        _cam camSetTarget _targetCityEnd;
        _cam camCommit 15; 
        sleep 3;
        [
            format [
                "<t size='2.0' color='#ffffff' font='PuristaBold' shadow='2'>%1</t><br/>" +
                "<t size='1.2' color='#ffffff' font='PuristaBold' shadow='2'>%2</t>",
                localize "STR_INTRO_AUTHOR",
                localize "STR_INTRO_PRESENTS"
            ],
            safeZoneX + 0.1,   
            safeZoneY + 0.2,   
            6,     
            2,     
            0,
            790    
        ] spawn BIS_fnc_dynamicText;
        sleep 8;  
        titleText [
            format [
                "<t size='3.0' color='#ffffff' font='PuristaBold' shadow='2'>%1</t>",
                localize "STR_INTRO_TITLE"
            ],
            "PLAIN", 1, true, true
        ];
        sleep 3.5;
        titleText ["", "PLAIN", 0.5];
        waitUntil { !isNil "MISSION_intro_heli" };
        private _camHeli = MISSION_intro_heli;
        if (isNull _camHeli) exitWith {
            hint "ERREUR: Hélicoptère introuvable";
        };
        sleep 0.1;
        detach _cam;
        sleep 1;
        cutText ["", "BLACK FADED", 1];   
        sleep 1;
        cutText ["", "BLACK IN", 1];        
        [
            format [
                "<t size='1.4' color='#dddddd' font='PuristaLight'>%1</t>",
                localize "STR_INTRO_SUBTITLE"
            ],
            -1, 
            safeZoneY + safeZoneH - 0.2,   
            7,  
            1,  
            0,  
            791  
        ] spawn BIS_fnc_dynamicText;
        _ppColor ppEffectAdjust [0.9, 1.2, -0.1, [0.3, 0.3, 0.3, 0.1], [0.7, 0.7, 0.8, 0.6], [0.2, 0.2, 0.3, 0.1]]; 
        _ppColor ppEffectCommit 1;
        _ppGrain ppEffectAdjust [0.15, 1.2, 1.2, 0.15, 1.2, false];
        _ppGrain ppEffectCommit 1;
        private _fixedPos = [0, 0.8, -0.7]; 
        _cam attachTo [_camHeli, _fixedPos];
        _cam setVectorDirAndUp [[0, 1, 0], [0, 0, 1]];
        _cam camSetFov 0.9;
        _cam camCommit 0;
        sleep 15;
        detach _cam;   
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        cutText ["", "BLACK IN", 1];
        _ppColor ppEffectAdjust [1, 1.0, -0.05, [0.2, 0.2, 0.2, 0.0], [0.8, 0.8, 0.9, 0.7], [0.1, 0.1, 0.2, 0]]; 
        _ppColor ppEffectCommit 1;
        _ppGrain ppEffectAdjust [0.05, 0.8, 0.8, 0.05, 0.8, false];
        _ppGrain ppEffectCommit 1;
        private _orbStartTime = time;
        private _orbDuration = 14;
        private _orbitAngle = -90;   
        private _updateInterval = 0.1;   
        private _commitTime = 0.5;       
        while { time < _orbStartTime + _orbDuration } do {
            private _progress = (time - _orbStartTime) / _orbDuration;
            _orbitAngle = -90 + (_progress * 135);
            private _distance = 35 - (_progress * 10);
            private _height = 12;
            private _heliPos = getPosATL _camHeli;
            private _heliDir = getDir _camHeli;
            private _finalAngle = _heliDir + _orbitAngle;
            private _camX = (_heliPos select 0) + (sin _finalAngle * _distance);
            private _camY = (_heliPos select 1) + (cos _finalAngle * _distance);
            private _camZ = (_heliPos select 2) + _height;
            _cam camSetPos [_camX, _camY, _camZ];
            _cam camSetTarget _camHeli;
            _cam camSetFov 0.75;
            _cam camCommit _commitTime;   
            sleep _updateInterval;   
        };
        detach _cam;
        cutText ["", "BLACK FADED", 0.5];
        sleep 0.5;
        private _qgPos = if (!isNil "QG_Center") then { getPos QG_Center } else { getPos vehicles_spawner };
        private _aerialCamPos = [
            (_qgPos select 0),
            (_qgPos select 1) - 90,
            (_qgPos select 2) + 35
        ];
        _cam camSetPos _aerialCamPos;
        _cam camSetTarget _qgPos;
        _cam camSetFov 0.55;
        _cam camCommit 0;
        waitUntil { camCommitted _cam };
        cutText ["", "BLACK IN", 1];
        private _rampOpened = false;
        private _plan5StartTime = time;
        while { !isTouchingGround _camHeli && (getPos _camHeli select 2) > 1 } do {
            private _progress = (time - _plan5StartTime) / 5;
            private _baseHeight = 35;
            private _descent = _progress * 5;  
            private _finalZ = ((_qgPos select 2) + _baseHeight - _descent) max ((_qgPos select 2) + 2);
            private _newCamPos = [
                (_qgPos select 0) + (sin (time * 5) * 12),
                (_qgPos select 1) - 90 + (cos (time * 5) * 12),
                _finalZ
            ];
            _cam camSetPos _newCamPos;
            _cam camSetFov ((0.55 - (_progress * 0.15)) max 0.2); 
            _cam camCommit 0.5;
            if (!_rampOpened && (getPos _camHeli select 2) < 30) then {
                 _rampOpened = true;
            };
            sleep 0.2;
        };
        sleep 2;
        cutText ["", "BLACK FADED", 1.5];
        waitUntil { vehicle player == player };
        sleep 1;
        cutText ["", "BLACK FADED", 1];
        sleep 1;
        _cam cameraEffect ["TERMINATE", "BACK"];   
        camDestroy _cam;                           
        ppEffectDestroy _ppColor;                  
        ppEffectDestroy _ppGrain;                  
        player switchCamera "INTERNAL";   
        showCinemaBorder false;           
        player allowDamage true;          
        disableUserInput false;
        disableUserInput true;
        disableUserInput false;
        cutText ["", "BLACK IN", 3];   
        [
            format [
                "<t size='2.0' color='#ffffff' font='PuristaBold'>%1</t><br/>" +
                "<t size='1.3' color='#cccccc' font='PuristaLight'>%2</t>",
                localize "STR_MISSION_START",           
                localize "STR_MISSION_START_SUBTITLE"   
            ],
            -1,    
            -1,    
            5,     
            1,     
            0,     
            793    
        ] spawn BIS_fnc_dynamicText;
        missionNamespace setVariable ["MISSION_intro_finished", true, true];
    };
};
if (isServer) then {
    [] spawn {
        diag_log "[INTRO] SERVER: Script démarré";
        diag_log "[INTRO] SERVER: Attente MISSION_var_helicopters...";
        waitUntil {!isNil "MISSION_var_helicopters" };    
        diag_log "[INTRO] SERVER: MISSION_var_helicopters OK";
        diag_log "[INTRO] SERVER: Démarrage immédiat...";
        sleep 0.5;   
        diag_log "[INTRO] SERVER: Début création hélico";
        private _heliData = [];
        { 
            if ((_x select 0) == "task_x_helicoptere") exitWith { _heliData = _x; }; 
        } forEach MISSION_var_helicopters;
        diag_log format ["[INTRO] SERVER: heliData = %1", _heliData];
        if (count _heliData == 0) exitWith { 
            diag_log "[INTRO] SERVER: ERREUR - Aucun hélicoptère trouvé!";
            missionNamespace setVariable ["MISSION_intro_finished", true, true];
        };
        private _destPos = getPosATL vehicles_spawner;   
        private _startDist = 1300; 
        private _startDir = random 360;   
        private _startPos = vehicles_spawner getPos [_startDist, _startDir];
        _startPos set [2, 200];   
        private _heliClass = _heliData select 1;   
        private _heli = createVehicle [_heliClass, _startPos, [], 0, "FLY"];
        _heli setPos _startPos;
        _heli setDir (_heli getDir _destPos);   
        _heli flyInHeight 150;                   
        _heli allowDamage false;                 
        MISSION_intro_heli = _heli;
        publicVariable "MISSION_intro_heli";
        createVehicleCrew _heli;   
        private _crew = crew _heli;
        { _x allowDamage false; } forEach _crew;   
        private _grpHeli = group driver _heli;
        _grpHeli setBehaviour "CARELESS";   
        _grpHeli setCombatMode "BLUE";      
        private _players = playableUnits;
        if (count _players == 0 && hasInterface) then { _players = [player]; };
        private _allUnitsToBoard = [];
        private _processedGroups = [];   
        {
            private _playerUnit = _x;
            private _playerGroup = group _playerUnit;
            if !(_playerGroup in _processedGroups) then {
                _processedGroups pushBack _playerGroup;
                {
                    if (alive _x && !(_x in _allUnitsToBoard)) then {
                        _allUnitsToBoard pushBack _x;
                    };
                } forEach (units _playerGroup);
            };
        } forEach _players;
        {
            if (alive _x && !(_x in _allUnitsToBoard)) then {
                _allUnitsToBoard pushBack _x;
            };
        } forEach _players;
        {
            private _unit = _x;
            _unit moveInCargo _heli;
            if (vehicle _unit == _unit) then { _unit moveInAny _heli; };
            _unit assignAsCargo _heli;
        } forEach _allUnitsToBoard;
        sleep 1;   
        _heli doMove _destPos;      
        _heli flyInHeight 150;      
        _heli limitspeed 200;       
        sleep 15;
        [_heli, ["door_rear_source", 1]] remoteExec ["animateSource", 0, true];
        _heli animateDoor ["door_rear_source", 1];
        [_heli, ["Door_Rear_Source", 1]] remoteExec ["animateSource", 0, true];
        _heli animateDoor ["Door_Rear_Source", 1];
        [_heli, ["Ramp", 1]] remoteExec ["animateSource", 0, true];
        _heli animateDoor ["Ramp", 1];
        [_heli, ["Door_Rear_Source", 1]] remoteExec ["animate", 0, true];
        _heli animateDoor ["Door_Rear_Source", 1];
        [_heli, ["Door_1_source", 1]] remoteExec ["animateSource", 0, true];
        _heli animateDoor ["Door_1_source", 1];
        [_heli, ["Ramp", 1]] remoteExec ["animateSource", 0, true];
        _heli animateDoor ["Ramp", 1];
        sleep 5;
        sleep 15;
        _heli limitspeed 120;   
        sleep 14;
        waitUntil { (_heli distance2D _destPos) < 250 };
        _heli land "GET OUT";
        waitUntil { (getPos _heli) select 2 < 2 };
        sleep 1;
        private _unitsToDisembark = [];
        private _processedGroupsDisembark = [];
        {
            private _playerUnit = _x;
            private _playerGroup = group _playerUnit;
            if !(_playerGroup in _processedGroupsDisembark) then {
                _processedGroupsDisembark pushBack _playerGroup;
                {
                    if (alive _x && vehicle _x == _heli && !(_x in _unitsToDisembark)) then {
                        _unitsToDisembark pushBack _x;
                    };
                } forEach (units _playerGroup);
            };
        } forEach _players;
        private _unitIndex = 0;
        {
            private _unit = _x;
            moveOut _unit;               
            unassignVehicle _unit;       
            private _dir = getDir _heli;
            private _dist = 6 + (_unitIndex mod 3);   
            private _angleOffset = 70 + (_unitIndex * 12);   
            private _pos = _heli getPos [_dist, _dir + _angleOffset];
            _pos set [2, 0];   
            _unit setPos _pos;
            _unit setDir _dir;    
            _unitIndex = _unitIndex + 1;
        } forEach _unitsToDisembark;
     _heli lock true;   
     _heli setVehicleLock "LOCKED";
        sleep 2;   
        _heli animateSource ["door_rear_source", 0];
        _heli animateDoor ["door_rear_source", 0];
        _heli animate ["door_rear_source", 0];
        {
            _x disableAI "TARGET";
            _x disableAI "AUTOTARGET";
            _x disableAI "SUPPRESSION";
            _x disableAI "FSM";  
            _x setBehaviour "CARELESS";  
            _x allowDamage false;
        } forEach _crew;
        _heli lock true;
        _heli setVehicleLock "LOCKED";
        _heli setEffectiveCommander (driver _heli);  
        _heli land "NONE";   
        private _exitPos = _destPos getPos [3000, _startDir];
        _heli doMove _exitPos;
        _heli flyInHeight 200;
        _heli limitspeed 300;   
        sleep 70;   
        { deleteVehicle _x } forEach _crew;
        deleteVehicle _heli;
    };
};