 
if (!isServer) exitWith {};

 
MISSION_Task05_CombatStarted = false;
MISSION_Task05_Complete = false;
MISSION_Task05_Drone = objNull;
publicVariable "MISSION_Task05_CombatStarted";

 
waitUntil { !isNil "MISSION_CivilianTemplates" && {count MISSION_CivilianTemplates > 0} };

 
private _all_locs = [];
for "_i" from 0 to 340 do {
    private _name = format ["waypoint_invisible_%1", if (_i < 10) then { "00" + str _i } else { if (_i < 100) then { "0" + str _i } else { str _i } }];
    private _obj = missionNamespace getVariable [_name, objNull];
    if (!isNull _obj) then { _all_locs pushBack _obj; };
};

if (count _all_locs == 0) exitWith { systemChat "[TASK05] ERREUR: Aucun waypoint trouvé!"; };

 
private _zone1_obj = selectRandom _all_locs;
private _zone1_pos = getPos _zone1_obj;

 
private _possible_zone2 = _all_locs select { (_x distance2D _zone1_pos) > 550 };
if (count _possible_zone2 == 0) exitWith { systemChat "[TASK05] ERREUR: Pas de Zone 2 valide (>550m)!"; };
private _zone2_obj = [_possible_zone2, _zone1_pos] call BIS_fnc_nearestPosition;
private _zone2_pos = getPos _zone2_obj;

 
[
    true,
    "Task05",
    ["Observez le conflit entre factions locales via le drone. Attendez que les forces s'entretuent.", "Guerre Civile", "Zone de conflit"],
    _zone1_pos,
    "CREATED",
    1,
    true,
    "scout",
    true
] call BIS_fnc_taskCreate;

 

private _fnc_applyTemplateAndIdentity = {
    params ["_unit"];
    
     
    private _template = selectRandom MISSION_CivilianTemplates;
    _template params ["_type", "_loadout", "_face", "_isFemale", "_pitch"];
    
     
    _unit setUnitLoadout _loadout;
    [_unit, _face] remoteExec ["setFace", 0, true]; 
    
     
    private _newName = "";
    private _newFace = _face;  
    
    if (_isFemale) then {
         
         
        private _namesF = ["Aisha", "Fatima", "Zahra", "Maryam", "Leila", "Samira", "Farida", "Nadia", "Soraya", "Jamila", "Rukhsana", "Parveen", "Nasreen", "Shabnam", "Zainab"];
        private _lastNames = ["Khan", "Shah", "Zadran", "Waziri", "Popalzai", "Durrani", "Ghilzai", "Afridi", "Shinwari", "Mohammadi"];
        _newName = format ["%1 %2", selectRandom _namesF, selectRandom _lastNames];
         
    } else {
         
         
        private _namesM = ["Abdul", "Ahmed", "Ali", "Amir", "Babur", "Bahadir", "Dostum", "Fahim", "Farhad", "Ghulam", "Habib", "Hassan", "Ismail", "Jamal", "Kamal"];
        private _lastNames = ["Khan", "Shah", "Zadran", "Waziri", "Popalzai", "Durrani", "Ghilzai", "Afridi", "Shinwari", "Mohammadi"];
        _newName = format ["%1 %2", selectRandom _namesM, selectRandom _lastNames];
        
         
        private _facesM = ["PersianHead_A3_01", "PersianHead_A3_02", "PersianHead_A3_03", "WhiteHead_02", "WhiteHead_05"];
        _newFace = selectRandom _facesM; 
    };
    
     
    private _speaker = selectRandom ["Male01PER", "Male02PER", "Male03PER"];
    
    [
        [_unit, _newFace, _speaker, _newName, _pitch],
        {
            params ["_u", "_f", "_s", "_n", "_p"];
            if (isNull _u) exitWith {};
            _u setFace _f;
            _u setSpeaker _s;
            _u setName _n;
            _u setPitch _p;
        }
    ] remoteExec ["call", 0, _unit];
};

 
private _fnc_spawnOPFOR = {
    params ["_pos", "_count"];
    private _grp = createGroup [east, true];
    
    for "_i" from 1 to _count do {
        private _spawnPos = _pos getPos [10 + (random 40), random 360];
        
         
        private _unit = _grp createUnit ["O_Soldier_F", _spawnPos, [], 0, "NONE"]; 
        
         
        removeAllWeapons _unit;
        removeAllItems _unit;
        removeAllAssignedItems _unit;
        removeBackpack _unit;
        removeUniform _unit;
        removeVest _unit;
        removeHeadgear _unit;
        removeGoggles _unit;
        
         
        [_unit] call _fnc_applyTemplateAndIdentity;
        
         
        [_unit] spawn {
            params ["_unit"];
            sleep 20; 
            if (!alive _unit) exitWith {};
            
            removeBackpack _unit;
            _unit addBackpack "B_Messenger_Coyote_F";
            _unit addWeapon "uk3cb_ak47";
            _unit addPrimaryWeaponItem "rhs_acc_2dpZenit";
            _unit addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
            for "_j" from 1 to 3 do { _unit addItemToBackpack "rhs_30Rnd_762x39mm_bakelite"; };
        };
    };
    
    _grp setBehaviour "SAFE";
    _grp setSpeedMode "LIMITED";
    [_grp, _pos, 100] call BIS_fnc_taskPatrol;
    
    _grp
};

 
private _fnc_spawnINDEP = {
    params ["_pos", "_count"];
    private _grp = createGroup [independent, true];
    
    for "_i" from 1 to _count do {
        private _spawnPos = _pos getPos [10 + (random 40), random 360];
        
         
        private _unit = _grp createUnit ["I_G_Soldier_F", _spawnPos, [], 0, "NONE"];
        
         

        [_unit] call _fnc_applyTemplateAndIdentity;
        
        _unit enableFatigue false;
        _unit setUnitPos "MIDDLE";
        
        [_unit] spawn {
            params ["_unit"];
            sleep 20;
            if (!alive _unit) exitWith {};
            
            removeBackpack _unit; 
            _unit addBackpack "UK3CB_LFR_B_B_MESSENGER_MED";
            _unit addWeapon "uk3cb_ak47";
            _unit addPrimaryWeaponItem "rhs_acc_2dpZenit";
            _unit addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
            for "_j" from 1 to 3 do { _unit addItemToBackpack "rhs_30Rnd_762x39mm_bakelite"; };
        };
    };
    
    _grp setBehaviour "SAFE";
    _grp setSpeedMode "LIMITED";
    [_grp, _pos, 100] call BIS_fnc_taskPatrol;
    
    _grp
};

 
private _groupsOPFOR = [];
private _groupsINDEP = [];

 
for "_i" from 1 to (4 + floor(random 3)) do {
    _groupsOPFOR pushBack ([_zone1_pos, 2 + floor(random 3)] call _fnc_spawnOPFOR);
};

 
for "_i" from 1 to (4 + floor(random 3)) do {
    _groupsINDEP pushBack ([_zone2_pos, 2 + floor(random 3)] call _fnc_spawnINDEP);
};

 
east setFriend [independent, 1];
independent setFriend [east, 1];

 
[_zone1_pos] spawn {
    params ["_zone1_pos"];
    
    sleep 35;
    
    private _spawnObj = missionNamespace getVariable ["heli_fin_direction", objNull];
     
    private _spawnPos = if (isNull _spawnObj) then { (_zone1_pos getPos [3000, random 360]) } else { getPos _spawnObj };
    _spawnPos set [2, 500];  
    
     
    private _drone = createVehicle ["B_UAV_02_dynamicLoadout_F", _spawnPos, [], 0, "FLY"];
    createVehicleCrew _drone; 
    _drone setVelocityModelSpace [0, 100, 0]; // Vitesse initiale pour éviter le décrochage
    _drone allowDamage false;
    _drone setCaptive true;
    _drone engineOn true;
    _drone flyInHeight 500;
    
    MISSION_Task05_Drone = _drone;
    publicVariable "MISSION_Task05_Drone";
    
    { _x reveal [_drone, 0]; } forEach allUnits;  
    
     
    private _grpDrone = group (driver _drone);
    _grpDrone setBehaviour "CARELESS";
    _grpDrone setCombatMode "BLUE";
    _grpDrone setSpeedMode "FULL";
    
     
    private _leader = selectRandom (allPlayers select {alive _x});
    if (isNil "_leader") then { _leader = allPlayers select 0 };
    if (isNil "_leader") then { _leader = _zone1_pos };  
    
    _drone doMove (getPos _leader);
    _drone flyInHeight 100;  
    
     
    private _t = time;
    waitUntil { 
        sleep 1;
        (_drone distance2D _leader) < 300 || !alive _drone || (time - _t > 120)
    };
    
     
    _drone doMove _zone1_pos;
    _drone flyInHeight 200;
    
    _t = time;
    waitUntil { 
        sleep 1;
        (_drone distance2D _zone1_pos) < 500 || !alive _drone || (time - _t > 120)
    };
    
     
     
    private _wp = _grpDrone addWaypoint [_zone1_pos, 0];
    _wp setWaypointType "LOITER";
    _wp setWaypointLoiterRadius 600;
    _wp setWaypointLoiterAltitude 200;
    _grpDrone setCurrentWaypoint _wp;
};

 
[_zone1_pos, _groupsOPFOR, _groupsINDEP, _zone2_pos] spawn {
    params ["_zone1_pos", "_groupsOPFOR", "_groupsINDEP", "_zone2_pos"];
    
    private _markers = [];
    private _lastResupply = time;
    
    while { !MISSION_Task05_Complete } do {
        sleep 5; 
        
         
        if (random 100 < 10) then { 
             { deleteMarker _x } forEach _markers;
             _markers = [];
             {
                private _grp = _x;
                {
                    if (alive _x) then {
                        private _m = createMarker [format ["mrk_unit_%1", netId _x], getPos _x];
                        _m setMarkerType "hd_dot";
                        _m setMarkerColor (if (side _x == east) then { "ColorRed" } else { "ColorGreen" });
                        _m setMarkerText "";
                        _markers pushBack _m;
                    };
                } forEach units _grp;
             } forEach (_groupsOPFOR + _groupsINDEP);
        };
        
        private _players = allPlayers select { alive _x };
        if (count _players == 0) exitWith {};
        private _nearestPlayer = [_players, _zone1_pos] call BIS_fnc_nearestPosition;
        private _distInfo = _nearestPlayer distance2D _zone1_pos;
        
         
        // IMPORTANT: Forcer le comportement non-combat si > 500m
        if (!MISSION_Task05_CombatStarted) then {
            // Si pas combat, rester SAFE/LIMITED
            if (_distInfo >= 500) then {
                 { 
                    if (behaviour (leader _x) != "SAFE") then { 
                        _x setBehaviour "SAFE"; 
                        _x setSpeedMode "LIMITED";
                    };
                 } forEach (_groupsOPFOR + _groupsINDEP);
            };
        };
        
        // --- LOGIQUE COMBAT ---
        if (!MISSION_Task05_CombatStarted) then {
            
            // Trigger AWARE (< 500m)
            if (_distInfo < 500 && _distInfo >= 400) then {
                { 
                    if (behaviour (leader _x) != "AWARE") then {
                        _x setBehaviour "AWARE"; 
                    };
                } forEach (_groupsOPFOR + _groupsINDEP);
            };
            
            // Trigger COMBAT (< 400m)
            if (_distInfo < 400) then {
                MISSION_Task05_CombatStarted = true;
                publicVariable "MISSION_Task05_CombatStarted";
                
                east setFriend [independent, 0];
                independent setFriend [east, 0];
                
                {
                    _x setBehaviour "COMBAT";
                    _x setCombatMode "RED";
                } forEach _groupsOPFOR;
                
                {
                    _x setBehaviour "COMBAT";
                    _x setCombatMode "RED";
                    _x setSpeedMode "FULL";
                    while {(count (waypoints _x)) > 0} do { deleteWaypoint ((waypoints _x) select 0); };
                    private _wp = _x addWaypoint [_zone1_pos, 0];
                    _wp setWaypointType "SAD";
                    { 
                        _x setUnitPos "MIDDLE"; 
                        _x enableFatigue false;
                    } forEach units _x;
                } forEach _groupsINDEP;
                
                systemChat "[TASK05] Combat Déclenché !";
            };
        };
        
         
        if (time - _lastResupply > 60) then {
            {
                {
                    if (alive _x) then {
                         for "_j" from 1 to 3 do { _x addItemToBackpack "rhs_30Rnd_762x39mm_bakelite"; };
                    };
                } forEach units _x;
            } forEach (_groupsOPFOR + _groupsINDEP);
            _lastResupply = time;
        };
        
         
        private _opforAlive = 0;
        { _opforAlive = _opforAlive + ({alive _x} count (units _x)); } forEach _groupsOPFOR;
        
        if (_opforAlive == 0) then {
            MISSION_Task05_Complete = true;
            publicVariable "MISSION_Task05_Complete";
            ["Task05", "SUCCEEDED"] call BIS_fnc_taskSetState;
            
            { deleteMarker _x } forEach _markers;
            
            {
                if ({alive _x} count (units _x) > 0) then {
                    _x setBehaviour "CARELESS";
                    _x setSpeedMode "LIMITED";
                    _x setCombatMode "BLUE";
                    
                    { 
                        _x setUnitPos "UP";
                        _x disableAI "TARGET";
                        _x disableAI "AUTOTARGET";
                        [_x] spawn {
                            params ["_unit"];
                            sleep 1;
                            _unit action ["SwitchWeapon", _unit, _unit, 100];
                        };
                    } forEach units _x; 
                    
                    private _exitPos = (getPos (leader _x)) getPos [2000, random 360];
                    _x move _exitPos;
                    
                    [_x] spawn {
                        params ["_grp"];
                        sleep 10;
                        waitUntil { 
                            sleep 5;
                            private _nearestPlayer = [allPlayers, (leader _grp)] call BIS_fnc_nearestPosition;
                            ((leader _grp) distance2D _nearestPlayer) > 1200
                        };
                        { deleteVehicle _x } forEach units _grp;
                        deleteGroup _grp;
                    };
                };
            } forEach _groupsINDEP;
            
            if (!isNull MISSION_Task05_Drone) then {
                MISSION_Task05_Drone doMove [0,0,100];
                [MISSION_Task05_Drone] spawn {
                    params ["_d"];
                    waitUntil { 
                        sleep 5;
                        private _nearestPlayer = [allPlayers, _d] call BIS_fnc_nearestPosition;
                        (_d distance2D _nearestPlayer) > 1200
                    };
                    {deleteVehicle _x} forEach crew _d;
                    deleteVehicle _d;
                };
            };
        };
    };
};
