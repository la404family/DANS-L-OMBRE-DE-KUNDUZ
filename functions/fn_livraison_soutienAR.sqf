if (!isServer) exitWith {};
params [["_targetPos", [0,0,0], [[]]]];
if (count _targetPos < 3) then { _targetPos set [2, 0]; };
private _spawnDist = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F";  
private _flyHeight = 150;
private _loiterHeight = 10;  
private _loiterRadius = 25;  
private _loiterDuration = 120;  
private _dir = random 360;
private _spawnPos = _targetPos vectorAdd [(_spawnDist * (sin _dir)), (_spawnDist * (cos _dir)), _flyHeight];
if (count _spawnPos < 3) then { _spawnPos set [2, _flyHeight]; };
private _heli = objNull;
private _spawnAttempts = 0;
while {isNull _heli && _spawnAttempts < 5} do {
    _spawnAttempts = _spawnAttempts + 1;
    _heli = createVehicle [_helicoClass, _spawnPos, [], 0, "FLY"];
    if (!isNull _heli) then {
        _heli setPos _spawnPos;
        _heli setDir (_dir + 180);
        _heli flyInHeight _flyHeight;
        _heli allowDamage false;
    } else {
        sleep 1;
    };
};
if (isNull _heli) exitWith {
};
private _group = createGroup [WEST, true];
private _crew = [];
private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
_crew pushBack _pilot;
private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;
private _turrets = allTurrets _heli;
private _gunnerTurrets = _turrets select { _x isNotEqualTo [0] };  
{
    private _gunner = _group createUnit ["B_Soldier_F", [0,0,0], [], 0, "NONE"];
    _gunner moveInTurret [_heli, _x];
    _crew pushBack _gunner;
} forEach _gunnerTurrets;
_group setBehaviour "CARELESS";  
_group setCombatMode "RED";  
_group setSpeedMode "FULL";
{
    _x disableAI "FSM";        
    _x allowDamage false;      
} forEach _crew;
[] spawn {
    "Radio_In" remoteExec ["playSound", 0];
    sleep 0.2;
    private _snd = selectRandom ["soutien01", "soutien02", "soutien03", "soutien04"];
    _snd remoteExec ["playSound", 0];
    sleep 2.5;  
    "Radio_Out" remoteExec ["playSound", 0];
};
[_heli, _targetPos, _group, _crew, _spawnPos, _loiterHeight, _loiterRadius, _loiterDuration] spawn {
    params ["_heli", "_targetPos", "_group", "_crew", "_homeBase", "_loiterHeight", "_loiterRadius", "_loiterDuration"];
    private _dropPos = +_targetPos;
    if (count _dropPos >= 2) then {
        private _flatCheck = _dropPos isFlatEmpty [5, -1, 0.4, 5, 0, false, objNull];
        if (_flatCheck isEqualTo []) then {
             private _safePos = [_dropPos, 0, 100, 5, 0, 0.4, 0, [], _dropPos] call BIS_fnc_findSafePos;
             if (_safePos isEqualType [] && {count _safePos >= 2}) then {
                _dropPos = _safePos;
                if (count _dropPos < 3) then { _dropPos set [2, 0]; };
             };
        };
    };
    private _markerName = format ["cas_mrk_%1", floor(random 10000)];
    private _marker = createMarker [_markerName, _dropPos];
    _marker setMarkerType "mil_warning";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText (localize "STR_CAS_MARKER");
    [_marker, _loiterDuration] spawn {
        params ["_m", "_d"];
        sleep (_d + 60);  
        deleteMarker _m;
    };
    private _wp1 = _group addWaypoint [_dropPos, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointSpeed "FULL";
    _heli doMove _dropPos;
    private _approachTimeout = 0;
    waitUntil {
        sleep 1;
        _approachTimeout = _approachTimeout + 1;
        ((_heli distance2D _dropPos) < 300) || _approachTimeout > 180 || !alive _heli
    };
    if (!alive _heli) exitWith {};
    deleteWaypoint _wp1;
    _heli flyInHeight _loiterHeight;
    _heli flyInHeightASL [_loiterHeight, _loiterHeight, _loiterHeight];
    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "LOITER";
    _wp2 setWaypointLoiterType "CIRCLE";
    _wp2 setWaypointLoiterRadius _loiterRadius;  
    _wp2 setWaypointBehaviour "CARELESS";  
    _wp2 setWaypointCombatMode "RED";  
    _wp2 setWaypointSpeed "LIMITED";  
    _heli doMove _dropPos;
    private _endTime = time + _loiterDuration;
    while {time < _endTime && alive _heli} do {
        private _nearEnemies = _heli nearEntities [["Man", "Car", "Tank"], 400];
        {
            if (side _x == east || side _x == resistance) then {
                _group reveal [_x, 4];  
            };
        } forEach _nearEnemies;
        sleep 5;
    }; 
    if (!alive _heli) exitWith {};
    while {(count (waypoints _group)) > 0} do {
        deleteWaypoint [_group, 0];
    };
    _heli flyInHeight 150;
    _heli flyInHeightASL [150, 150, 150];
    private _wpHome = _group addWaypoint [[0,0,0], 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    _heli doMove [0,0,0];
    waitUntil {
        sleep 5;
        private _players = allPlayers select { alive _x };
        private _tooClose = _players findIf { (_x distance2D _heli) < 2000 } > -1;
        (!_tooClose) || !alive _heli
    };
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
};
