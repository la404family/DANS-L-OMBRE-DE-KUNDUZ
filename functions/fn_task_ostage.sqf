if (!isServer) exitWith {};
waitUntil { !isNil "MISSION_fnc_applyCivilianTemplate" };
private _possibleLocs = [];
for "_i" from 0 to 340 do {
    private _suffix = if (_i < 10) then {format ["00%1", _i]} else {if (_i < 100) then {format ["0%1", _i]} else {str _i}};
    private _wp = missionNamespace getVariable [format ["waypoint_invisible_%1", _suffix], objNull];
    if (!isNull _wp) then { _possibleLocs pushBack _wp; };
};
if (_possibleLocs isEqualTo []) exitWith { systemChat "ERREUR: Pas de waypoint hostage"; };
private _objectiveObj = selectRandom _possibleLocs;
private _posObjective = getPos _objectiveObj;
private _searchCenter = _posObjective getPos [random 30, random 360];
private _markerName = format ["m_%1", floor(random 99999)];
private _marker = createMarker [_markerName, _searchCenter];
_marker setMarkerType "Empty";  
_marker setMarkerShape "ELLIPSE";
_marker setMarkerSize [75, 75];  
_marker setMarkerColor "ColorOrange";
_marker setMarkerBrush "Border";
_marker setMarkerText (localize "STR_TASK_OSTAGE_MARKER");
private _taskID = format ["task_hostage_%1", floor(random 99999)];
[
    true, 
    _taskID, 
    [localize "STR_TASK_OSTAGE_DESC", localize "STR_TASK_OSTAGE_TITLE", "MARKER"], 
    _searchCenter,  
    "CREATED", 
    1, 
    true, 
    "SEARCH", 
    true
] call BIS_fnc_taskCreate;
private _civGroup = createGroup [civilian, true];
private _hostage = _civGroup createUnit ["C_man_polo_1_F", [0,0,0], [], 0, "NONE"];  
_hostage setPosATL [(_posObjective select 0), (_posObjective select 1), 0.8]; 
sleep 0.2;
[_hostage] call MISSION_fnc_applyCivilianTemplate;
if (name _hostage == "Error: No unit" || name _hostage == "Panas Papadopoulo") then {
     private _backupName = selectRandom MISSION_CivilianNames_Male;
     [_hostage, (_backupName select 0)] remoteExec ["setName", 0, true];
};[_hostage] call MISSION_fnc_applyCivilianTemplate;
_hostage setCaptive true;
_hostage setVariable ["isCaptive", true, true];
_hostage disableAI "ANIM";
_hostage disableAI "MOVE";
_hostage switchMove "Acts_ExecutionVictim_Loop";
[
    _hostage,
    localize "STR_ACTION_FREE_HOSTAGE",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
    "alive _target && _target getVariable ['isCaptive', false]",
    "true",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _target setVariable ["isCaptive", false, true];
        [_target, "Acts_ExecutionVictim_Unbow"] remoteExec ["switchMove", 0];
        [_target] spawn {
            params ["_civ"];
            sleep 8;
            _civ setCaptive false;
            _civ enableAI "ANIM";
            _civ enableAI "MOVE";
            _civ switchMove "";
            _civ setUnitPos "UP";
            _civ setBehaviour "CARELESS";
            while {alive _civ && !(_civ getVariable ["inHeli", false])} do {
                private _nearest = objNull;
                private _distMin = 9999;
                {
                    if (alive _x && isPlayer _x) then {
                        private _d = _x distance _civ;
                        if (_d < _distMin) then { _distMin = _d; _nearest = _x; };
                    };
                } forEach allPlayers;
                if (!isNull _nearest && _distMin > 5) then {
                    _civ doMove (getPos _nearest);
                };
                sleep 3;
            };
        };
    },
    {},
    [],
    2,
    0,
    true,
    false
] call BIS_fnc_holdActionAdd;
private _unitsToSpawn = 3 + floor(random 5);
while {_unitsToSpawn > 0} do {
    private _groupSize = if (_unitsToSpawn >= 3) then {3} else {2};
    _unitsToSpawn = _unitsToSpawn - _groupSize;
    private _grpEnemy = createGroup [east, true];
    private _spawnPosEnemy = _posObjective getPos [15 + random 15, random 360];
    for "_i" from 1 to _groupSize do {
        private _unit = _grpEnemy createUnit ["O_Soldier_F", _spawnPosEnemy, [], 0, "NONE"];  
        [_unit] call MISSION_fnc_applyCivilianTemplate;
        removeAllWeapons _unit;
        _unit addBackpack "B_Messenger_Coyote_F";
        _unit addWeapon "rhs_weap_akmn";
        _unit addPrimaryWeaponItem "rhs_30Rnd_762x39mm";
        _unit addPrimaryWeaponItem "rhs_acc_2dpZenit";
        _unit addItemToBackpack "rhs_30Rnd_762x39mm";
        _unit addItemToBackpack "rhs_30Rnd_762x39mm";
        _unit linkItem "ItemMap";
        _unit linkItem "ItemCompass";
        _unit linkItem "ItemRadio";
    };
    [_grpEnemy, _posObjective] spawn {
        params ["_grp", "_center"];
        _grp setBehaviour "SAFE";
        _grp setSpeedMode "LIMITED";
        while {{alive _x} count units _grp > 0} do {
            (leader _grp) doMove (_center getPos [random 40, random 360]);
            sleep (30 + random 45);
        };
    };
};
[_taskID, _hostage, _posObjective, _marker] spawn {
    params ["_taskID", "_hostage", "_posObjective", "_marker"];
    waitUntil { sleep 1; !alive _hostage || !(_hostage getVariable ["isCaptive", true]) };
    if (!alive _hostage) exitWith { 
        [_taskID, "FAILED"] call BIS_fnc_taskSetState; 
        deleteMarker _marker; 
        (localize "STR_TASK_OSTAGE_DEAD") remoteExec ["hint", 0];
    };
    [_taskID, "ASSIGNED"] call BIS_fnc_taskSetState;
    deleteMarker _marker;
    private _lzLocs = [];
    for "_i" from 0 to 127 do {
        private _suffix = if (_i < 10) then {format ["00%1", _i]} else {if (_i < 100) then {format ["0%1", _i]} else {str _i}};
        private _wp = missionNamespace getVariable [format ["waypoint_livraison_%1", _suffix], objNull];
        if (!isNull _wp) then { _lzLocs pushBack _wp; };
    };
    private _lzObj = [_lzLocs, _hostage] call BIS_fnc_nearestPosition;
    if (typeName _lzObj != "OBJECT" || isNull _lzObj) exitWith { systemChat "ERREUR: Pas de LZ"; };
    private _posLZ = getPos _lzObj;
    private _heliClass = "B_AMF_Heli_Transport_01_F";
    private _spawnPosHeli = _posLZ getPos [2500, random 360];
    _spawnPosHeli set [2, 200];
    private _heli = createVehicle [_heliClass, _spawnPosHeli, [], 0, "FLY"];
    _heli setPos _spawnPosHeli;
    _heli flyInHeight 150;
    _heli allowDamage false; 
    createVehicleCrew _heli;
    private _grpHeli = group driver _heli;
    _grpHeli setBehaviour "CARELESS";
    _grpHeli setCombatMode "RED";  
    _heli lock 2;
    private _markerLZ = createMarker [format ["mrk_extract_%1", _taskID], _posLZ];
    _markerLZ setMarkerType "mil_pickup";
    _markerLZ setMarkerColor "ColorBlue";
    _markerLZ setMarkerText (localize "STR_MARKER_EXTRACTION");
    [_taskID, _posLZ] call BIS_fnc_taskSetDestination;
    (localize "STR_HINT_EXTRACTION_INCOMING") remoteExec ["hint", 0];
    _heli doMove _posLZ;
    waitUntil { sleep 1; (_heli distance2D _posLZ) < 300 || !alive _heli };
    if (alive _heli) then {
        _heli land "GET IN";
        waitUntil { sleep 1; (getPosATL _heli select 2) < 2 };
        _heli setFuel 0;
        _heli animateSource ["Ramp", 1];
        waitUntil {
            sleep 1;
            if (!alive _hostage || !alive _heli) exitWith {true};
            if (_hostage distance _heli < 35 && !(_hostage getVariable ["inHeli", false])) then {
                 _hostage setVariable ["inHeli", true];
                 _hostage assignAsCargo _heli;
                 [_hostage] orderGetIn true;
                 _hostage moveInCargo _heli;
            };
            (vehicle _hostage == _heli)
        };
        if (alive _hostage && alive _heli) then {
            (localize "STR_HINT_EXTRACTION_TAKEOFF") remoteExec ["hint", 0];
            _heli animateSource ["Ramp", 0];
            sleep 2;
            _heli setFuel 1;
            _heli doMove (_posLZ getPos [4000, random 360]);
            sleep 10;
            [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
            deleteMarker _markerLZ;
        } else {
             [_taskID, "FAILED"] call BIS_fnc_taskSetState;
             deleteMarker _markerLZ;
        };
    };
    sleep 60;
    if (alive _heli) then {
        {deleteVehicle _x} forEach crew _heli;
        deleteVehicle _heli;
    };
    deleteVehicle _hostage;
    deleteGroup _grpHeli;
    deleteMarker _markerLZ;
};