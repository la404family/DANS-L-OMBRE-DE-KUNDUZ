if (!isServer) exitWith {};

waitUntil { !isNil "MISSION_fnc_applyCivilianTemplate" };

private _all_locs = [];
for "_i" from 0 to 340 do {
    private _name = format ["waypoint_invisible_%1", _i];
    if (_i < 10) then { _name = format ["waypoint_invisible_00%1", _i]; };
    if (_i >= 10 && _i < 100) then { _name = format ["waypoint_invisible_0%1", _i]; };
    
    private _obj = missionNamespace getVariable [_name, objNull];
    if (!isNull _obj) then {
        _all_locs pushBack _obj;
    };
};

private _selected_locs = [];
for "_i" from 1 to 3 do {
    if (count _all_locs > 0) then {
        private _loc = selectRandom _all_locs;
        _selected_locs pushBack _loc;
        _all_locs = _all_locs - [_loc];
    };
};

private _officers = [];
private _target_officer = objNull;
private _groups = [];

{
    private _pos = getPos _x;
    private _grp = createGroup [east, true];
    _groups pushBack _grp;
    
    private _officer = _grp createUnit ["O_officer_F", _pos, [], 0, "NONE"];
    _officer setPos [(_pos select 0), (_pos select 1), 0.7];
    _officer allowDamage false;
    [_officer] spawn { sleep 2; _this select 0 allowDamage true; };
    _officers pushBack _officer;
    
    [_officer] call Mission_fnc_applyCivilianTemplate;

     
    _officer addBackpack "B_Messenger_Coyote_F";
    for "_i" from 1 to 3 do {_officer addItemToBackpack "rhs_30Rnd_762x39mm_bakelite";};
    _officer addWeapon "uk3cb_ak47";
    _officer addPrimaryWeaponItem "rhs_acc_2dpZenit";
    _officer addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
    
    private _num_guards = 2 + floor(random 7); 
    for "_j" from 1 to _num_guards do {
        if ((count units _grp) >= 3) then {
            _grp = createGroup [east, true];
            _groups pushBack _grp;
        };
        private _guard = _grp createUnit ["O_Soldier_F", _pos, [], 2, "NONE"];
        _guard setPos [(getPos _guard select 0), (getPos _guard select 1), 0.7];
        _guard allowDamage false;
        [_guard] spawn { sleep 2; _this select 0 allowDamage true; };
        [_guard] call Mission_fnc_applyCivilianTemplate;

         
        _guard addBackpack "B_Messenger_Coyote_F";
        for "_i" from 1 to 3 do {_guard addItemToBackpack "rhs_30Rnd_762x39mm_bakelite";};
        _guard addWeapon "uk3cb_ak47";
        _guard addPrimaryWeaponItem "rhs_acc_2dpZenit";
        _guard addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
    };
    
    [_grp, _pos, 25] call BIS_fnc_taskPatrol;
    
} forEach _selected_locs;

_target_officer = selectRandom _officers;
_target_officer setVariable ["MISSION_Task01_Target", true, true];

[
    true,
    "Task01",
    ["Récupérer les documents secrets détenus par un officier insurgé. Cible prioritaire identifiée dans le secteur. Neutralisez la cible et fouillez le corps.", "Récupération de Renseignement", ""],
    objNull,
    "CREATED",
    1,
    true,
    "search",
    true
] call BIS_fnc_taskCreate;

// Audio Début
["task01_start"] remoteExec ["playSound", 0];

[_officers] spawn {
    params ["_officers"];
     
    while { isNil "MISSION_Task01_Complete" } do {
        {
            private _markerName = format ["mrk_officer_%1", _x];
            if (alive _x) then {
                if (getMarkerColor _markerName == "") then {
                    createMarker [_markerName, getPos _x];
                    _markerName setMarkerType "mil_destroy"; 
                    _markerName setMarkerColor "ColorRed";
                    _markerName setMarkerText "Cible Potentielle";
                };
                _markerName setMarkerPos (getPos _x);
            } else {
                 
                deleteMarker _markerName;
            };
        } forEach _officers;
        sleep 2;
    };
     
    { deleteMarker format ["mrk_officer_%1", _x] } forEach _officers;
    deleteMarker "mrk_doc_task01";
};

[_target_officer, _groups] spawn {
    params ["_target", "_groups"];
    waitUntil {!alive _target};
    
    // Audio Mort Officier
    ["task01_officer_dead"] remoteExec ["playSound", 0];

    private _doc = createVehicle ["Land_Document_01_F", (getPos _target), [], 0, "CAN_COLLIDE"];
    _doc setPos [(getPos _target select 0) + 0.2, (getPos _target select 1), 0];
    
     
    private _mrkDoc = createMarker ["mrk_doc_task01", getPos _doc];
    _mrkDoc setMarkerType "mil_objective";  
    _mrkDoc setMarkerColor "ColorWhite";
    _mrkDoc setMarkerText "Documents";

    [
        _target,
        [
            "Fouiller le corps / Récupérer documents",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                _arguments params ["_doc"];
                
                deleteVehicle _doc;
                ["Task01", "SUCCEEDED"] call BIS_fnc_taskSetState;
                _target removeAction _actionId;
                
                MISSION_Task01_Complete = true; 
                publicVariable "MISSION_Task01_Complete";

                // Audio Succès
                ["task01_success"] remoteExec ["playSound", 0];
            },
            [_doc],
            1.5,
            true,
            true,
            "",
            "true",
            2
        ]
    ] remoteExec ["addAction", 0, true];
    
    waitUntil { !isNil "MISSION_Task01_Complete" && {MISSION_Task01_Complete} };
    
     
    {
        private _grp = _x;
        {
            if (alive _x) then {
                 
                private _alivePlayers = allPlayers select { alive _x };
                private _nearestPlayer = objNull;
                private _minDist = 99999;
                
                if (count _alivePlayers > 0) then {
                    _nearestPlayer = [_alivePlayers, _x] call BIS_fnc_nearestPosition;
                    _minDist = _x distance2D _nearestPlayer;
                };

                 
                if (_minDist > 1200) then {
                    deleteVehicle _x;
                } else {
                     
                    if (!isNull _nearestPlayer) then {
                        _x doMove (getPos _nearestPlayer);
                        _x setBehaviour "COMBAT";
                        _x setSpeedMode "FULL";
                    };
                };
            };
        } forEach (units _grp);
    } forEach _groups;
};
