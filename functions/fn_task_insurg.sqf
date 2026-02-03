if (!isServer) exitWith {};
waitUntil { !isNil "MISSION_fnc_applyCivilianTemplate" };
CIVIL_CHANGE_MinDistance  = 500;     
CIVIL_CHANGE_RequiredCount = 2 + round(random 7);     
CIVIL_CHANGE_Debug        = false;  
CIVIL_CHANGE_fnc_log = {
    params ["_msg"];
    if (CIVIL_CHANGE_Debug) then { 
        systemChat format ["[CIVIL_TASK] %1", _msg]; 
        diag_log format ["[CIVIL_TASK] %1", _msg];
    };
};
CIVIL_CHANGE_fnc_convertToInsurgent = {
    params ["_civil"];
    if (!alive _civil) exitWith { objNull };
    private _pos = getPosATL _civil;
    private _dir = getDir _civil;
    private _uniform = uniform _civil;
    private _vest = vest _civil;
    private _headgear = headgear _civil;
    private _goggles = goggles _civil; 
    private _face = face _civil;
    deleteVehicle _civil;
    private _grp = createGroup [east, true]; 
    private _insurgent = _grp createUnit ["O_G_Soldier_F", _pos, [], 0, "NONE"];
    _insurgent setDir _dir;
    _insurgent setFace _face;
    removeAllWeapons _insurgent;
    removeAllItems _insurgent;
    removeAllAssignedItems _insurgent;
    removeBackpack _insurgent;
    removeUniform _insurgent;
    removeVest _insurgent;
    removeHeadgear _insurgent;
    removeGoggles _insurgent;
    if (_uniform != "") then { _insurgent forceAddUniform _uniform; };
    if (_vest != "") then { _insurgent addVest _vest; };
    if (_headgear != "") then { _insurgent addHeadgear _headgear; };
    if (_goggles != "") then { _insurgent addGoggles _goggles; };
    _insurgent addBackpack "B_Messenger_Coyote_F";
    _insurgent addWeapon "rhs_weap_akmn";
    _insurgent addPrimaryWeaponItem "rhs_30Rnd_762x39mm"; 
    _insurgent addPrimaryWeaponItem "rhs_acc_2dpZenit"; 
    for "_i" from 1 to 2 do {
        _insurgent addItemToBackpack "rhs_30Rnd_762x39mm";
    };
    _insurgent linkItem "ItemMap";
    _insurgent linkItem "ItemCompass";
    _insurgent linkItem "ItemRadio";
    _insurgent setCombatMode "RED";
    _insurgent setBehaviour "COMBAT";
    _insurgent setSkill 0.5;
    _insurgent enableAI "ALL";
    _insurgent setVariable ["CIVIL_CHANGE_Converted", true, true];
    _insurgent
};
CIVIL_CHANGE_fnc_attackNearestEnemy = {
    params ["_insurgent"];
    if (!alive _insurgent) exitWith {};
    private _enemies = allUnits select {
        alive _x && {side _x == west} && {!(_x getVariable ["CIVIL_CHANGE_Converted", false])}
    };
    if (count _enemies == 0) exitWith {};
    private _nearestEnemy = objNull;
    private _minDist = 99999;
    {
        private _dist = _insurgent distance _x;
        if (_dist < _minDist) then {
            _minDist = _dist;
            _nearestEnemy = _x;
        };
    } forEach _enemies;
    if (!isNull _nearestEnemy) then {
        private _grp = group _insurgent;
        _grp reveal [_nearestEnemy, 2];
        _insurgent doTarget _nearestEnemy;
        _insurgent doFire _nearestEnemy;
        private _wp = _grp addWaypoint [getPos _nearestEnemy, 30];
        _wp setWaypointType "SAD"; 
        _wp setWaypointBehaviour "COMBAT"; 
        _wp setWaypointCombatMode "RED";
        _wp setWaypointSpeed "FULL";
    };
};
[] spawn {
    sleep 10;
    ["Initialisation recherche insurgés..."] call CIVIL_CHANGE_fnc_log;
    private _insurgents = [];
    waitUntil {
        sleep 10;
        private _players = allPlayers select {alive _x && !(_x isKindOf "HeadlessClient_F")};
        private _ready = false;
        if (count _players > 0) then {
            private _referencePlayer = _players select 0;
            private _allCivilians = allUnits select {
                alive _x && 
                {side group _x == civilian} && 
                {!(_x getVariable ["CIVIL_CHANGE_Converted", false])} && 
                {_x distance _referencePlayer > CIVIL_CHANGE_MinDistance}
            };
            [format ["Civils trouvés: %1 / Requis: %2", count _allCivilians, CIVIL_CHANGE_RequiredCount]] call CIVIL_CHANGE_fnc_log;
            if (count _allCivilians >= CIVIL_CHANGE_RequiredCount) then {
                ["Civils localisés, conversion en cours..."] call CIVIL_CHANGE_fnc_log;
                private _shuffled = _allCivilians call BIS_fnc_arrayShuffle;
                for "_i" from 0 to (CIVIL_CHANGE_RequiredCount - 1) do {
                    private _civil = _shuffled select _i;
                    private _insurgent = [_civil] call CIVIL_CHANGE_fnc_convertToInsurgent;
                    if (!isNull _insurgent) then {
                        _insurgents pushBack _insurgent;
                        [_insurgent] spawn {
                            params ["_unit"];
                            sleep 2; 
                            [_unit] call CIVIL_CHANGE_fnc_attackNearestEnemy;
                        };
                    };
                    sleep 0.5;
                };
                _ready = true;
            };
        };
        _ready
    };
    if (count _insurgents == 0) exitWith {};
    [
        true,  
        "task_insurgents",  
        [
            localize "STR_TASK_INSURG_DESC",  
            localize "STR_TASK_INSURG_TITLE",  
            ""
        ],
        objNull,
        "CREATED", 
        1, 
        true, 
        "attack", 
        true
    ] call BIS_fnc_taskCreate;
    ["Tâche créée: Neutraliser les insurgés"] call CIVIL_CHANGE_fnc_log;
    private _activeMarkers = [];
    while { ({alive _x} count _insurgents) > 0 } do {
        { deleteMarker _x; } forEach _activeMarkers;
        _activeMarkers = [];
        {
            if (alive _x) then {
                private _pos = getPos _x;
                private _mrkName = format ["insurg_dot_%1_%2", _forEachIndex, diag_tickTime];
                private _mrk = createMarker [_mrkName, _pos];
                _mrk setMarkerType "mil_dot";
                _mrk setMarkerColor "ColorRed";
                _mrk setMarkerText "";  
                _activeMarkers pushBack _mrk;
            };
        } forEach _insurgents;
        private _delay = 3 + random 3;
        sleep _delay;
    };
    { deleteMarker _x; } forEach _activeMarkers;
    ["task_insurgents", "SUCCEEDED"] call BIS_fnc_taskSetState;
    ["Mission terminée : Insurgés neutralisés"] call CIVIL_CHANGE_fnc_log;
};