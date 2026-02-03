if (!isServer) exitWith {};
params [["_targetPos", [0,0,0], [[]]]];
if (count _targetPos < 3) then { _targetPos set [2, 0]; };
private _spawnDist = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F";  
private _vehClass = "amf_pvp_01_top_TDF_f";
private _flyHeight = 150;
private _hoverHeight = 10;  
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
private _cargo = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -15]);
_cargo allowDamage false;
private _originalMass = getMass _cargo;
_cargo setMass 800;  
_heli setSlingLoad _cargo;
[] spawn {
    "Radio_In" remoteExec ["playSound", 0];
    sleep 0.2;
    private _snd = selectRandom ["livraison01", "livraison02", "livraison03", "livraison04", "livraison05", "livraison06", "livraison07", "livraison08", "livraison09"];
    _snd remoteExec ["playSound", 0];
    sleep 2.5;  
    "Radio_Out" remoteExec ["playSound", 0];
};
[_heli, _cargo, _targetPos, _group, _crew, _spawnPos, _originalMass, _hoverHeight] spawn {
    params ["_heli", "_cargo", "_targetPos", "_group", "_crew", "_homeBase", "_originalMass", "_hoverHeight"];
    private _dropPos = +_targetPos;
    private _closestWp = objNull;
    private _minDist = 999999;
    for "_i" from 0 to 127 do {
        private _suffix = if (_i < 10) then { format ["00%1", _i] } else { if (_i < 100) then { format ["0%1", _i] } else { str _i } };
        private _wp = missionNamespace getVariable [format ["waypoint_livraison_%1", _suffix], objNull];
        if (!isNull _wp) then {
            private _dist = _wp distance2D _targetPos;
            if (_dist < _minDist) then {
                _minDist = _dist;
                _closestWp = _wp;
            };
        };
    };
    if (!isNull _closestWp) then {
        _dropPos = getPos _closestWp;
        if (count _dropPos < 3) then { _dropPos set [2, 0]; };
    } else {
        if (count _dropPos >= 2) then {
            private _flatCheck = _dropPos isFlatEmpty [5, -1, 0.2, 5, 0, false, objNull];
            if (_flatCheck isEqualTo []) then {
                private _safePos = [_dropPos, 0, 150, 5, 0, 0.2, 0, [], _dropPos] call BIS_fnc_findSafePos;
                if (_safePos isEqualType [] && {count _safePos >= 2}) then {
                    if (_safePos distance2D _dropPos < 500) then {
                        _dropPos = _safePos;
                        if (count _dropPos < 3) then { _dropPos set [2, 0]; };
                    };
                };
            };
        };
    };
    private _markerName = format ["livraison_mrk_%1", floor(random 10000)];
    private _marker = createMarker [_markerName, _dropPos];
    _marker setMarkerType "mil_pickup";
    _marker setMarkerColor "ColorBlue";
    _marker setMarkerText (localize "STR_LIVRAISON_MARKER_TEXT");
    [_marker] spawn {
        params ["_m"];
        sleep 120;
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
        ((_heli distance2D _dropPos) < 200) || _approachTimeout > 180 || !alive _heli
    };
    if (!alive _heli) exitWith {
    };
    deleteWaypoint _wp1;
    _heli flyInHeight _hoverHeight;
    _heli flyInHeightASL [_hoverHeight, _hoverHeight, _hoverHeight];
    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";
    _wp2 setWaypointSpeed "FULL";
    _heli doMove _dropPos;
    private _positionTimeout = 0;
    waitUntil {
        sleep 0.5;
        _positionTimeout = _positionTimeout + 0.5;
        ((_heli distance2D _dropPos) < 3) || _positionTimeout > 30 || !alive _heli
    };
    if (!alive _heli) exitWith {
    };
    doStop _heli;
    _heli flyInHeight _hoverHeight;
    private _dropTimeout = 0;
    private _cargoGrounded = false;
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.5;
        private _newHeight = _hoverHeight - _dropTimeout;
        if (_newHeight < 5) then { _newHeight = 5; };
        _heli flyInHeight _newHeight;
        _heli flyInHeightASL [_newHeight, _newHeight, _newHeight];
        _cargoGrounded = (getPosATL _cargo select 2) < 3;
        if ((getPosATL _heli select 2) < 4) then {
            _cargoGrounded = true;
        };
        _cargoGrounded || _dropTimeout > 30 || !alive _heli || !alive _cargo
    };
    if (!alive _heli || !alive _cargo) exitWith {
    };
    private _dropTime = time;
      sleep 1;
    private _allRopes = ropes _heli;
    {
        ropeDestroy _x;
    } forEach _allRopes;
    _heli setSlingLoad objNull;
    sleep 1;
    _cargo setVelocity [0, 0, 0];
    _cargo setVectorUp [0, 0, 1];
    _cargo setMass _originalMass;
    _cargo allowDamage true;
    sleep 1;
    while {(count (waypoints _group)) > 0} do {
        deleteWaypoint [_group, 0];
    };
    _heli flyInHeight 150;
    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    _heli doMove _homeBase;
    waitUntil {
        sleep 5;
        (_heli distance2D _targetPos > 1500) || !alive _heli || (time - _dropTime > 180)
    };
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
};