if (!isServer) exitWith {};

 
waitUntil { !isNil "Mission_fnc_applyCivilianTemplate" };

 
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

if (count _all_locs == 0) exitWith { systemChat "ERREUR: Aucun waypoint_invisible trouvé pour Task03"; };

private _crash_loc_obj = selectRandom _all_locs;
private _crash_pos = getPos _crash_loc_obj;

 
private _heliSpawnObj = missionNamespace getVariable ["heli_fin_spawn", objNull];
private _spawnPos = [0,0,100];

if (!isNull _heliSpawnObj) then {
    _spawnPos = getPos _heliSpawnObj;
    _spawnPos set [2, 100];  
} else {
     
    _spawnPos = _crash_pos getPos [2000, random 360];
    _spawnPos set [2, 100];
};

private _heliType = "B_Heli_Light_01_F"; 
private _heli = createVehicle [_heliType, _spawnPos, [], 0, "FLY"]; 
_heli setPos _spawnPos;
_heli allowDamage false;  
_heli flyInHeight 100;

 
private _grpPilot = createGroup [west, true];
private _pilot = _grpPilot createUnit ["B_Helipilot_F", _spawnPos, [], 0, "NONE"];
_pilot moveInDriver _heli;
_grpPilot setBehaviour "CARELESS";
_grpPilot setCombatMode "BLUE";  

 
private _refUnitPilot = objNull;
if (count allPlayers > 0) then { _refUnitPilot = selectRandom allPlayers; };
if (!isNull _refUnitPilot) then { _pilot setUnitLoadout (getUnitLoadout _refUnitPilot); };

 
_heli doMove _crash_pos;

 
waitUntil {
    sleep 1;
    (_heli distance2D _crash_pos) < 200 || !alive _heli
};

if (!alive _heli) exitWith { systemChat "ERREUR: Hélico détruit avant le crash scripté"; };

 
// 1. Déclenchement de la panne
_heli setDamage 0.8;
_heli setHit ["HitVRotor", 1]; // Panne rotor de queue -> Vrille naturelle
_heli setFuel 0;              // Coupure moteur -> Chute

private _smoke = "#particlesource" createVehicle (getPos _heli);
_smoke setParticleClass "MediumDestructionSmoke"; 
_smoke attachTo [_heli, [0, 0, 0]];

// 2. Simulation de perte de contrôle (Vrille + Roulis)
[_heli] spawn {
    params ["_h"];
    private _duration = 0;
    while { alive _h && (getPos _h select 2) > 5 && _duration < 10 } do {
        // Ajout d'une composante de roulis (Bank) progressive pour le "retourner"
        private _vUp = vectorUp _h;
        _h setVectorUp [
            (_vUp select 0) + 0.08,  // Force le basculement X
            (_vUp select 1) + 0.02,  // Léger basculement Y
            (_vUp select 2)
        ];
        
        // Ajout d'une rotation angulaire brutale (Velocity)
        private _vel = velocity _h;
        _h setVelocity [
            (_vel select 0),
            (_vel select 1),
            (_vel select 2) - 0.5 // Accélère la chute légèrement
        ];
        
        sleep 0.1;
        _duration = _duration + 0.1;
    };
};

waitUntil {
    sleep 0.5;
    ((getPos _heli) select 2) < 2
};

 
sleep 2;
_heli setVelocity [0,0,0];

 
deleteVehicle _pilot; 
deleteGroup _grpPilot;  

 

 
private _survivors = [];
private _refUnit = objNull;

 
if (count allPlayers > 0) then { 
    _refUnit = selectRandom allPlayers; 
} else { 
     
    {
        private _u = missionNamespace getVariable [_x, objNull];
        if (!isNull _u) exitWith { _refUnit = _u; };
    } forEach ["player_0", "player_1", "player_2", "officier_0", "officier_1"];
};

 
private _survivorClass = "B_Soldier_F";
if (!isNull _refUnit) then { _survivorClass = typeOf _refUnit; };

private _grpSurvivors = createGroup [west, true];

 
for "_i" from 1 to 5 do {
    private _spawnPos = _heli getPos [5 + (random 5), random 360];
    private _survivor = _grpSurvivors createUnit [_survivorClass, _spawnPos, [], 0, "NONE"];
    
    _survivor allowDamage false;  
    _survivor setDir (random 360);
    _survivor setPos [_spawnPos select 0, _spawnPos select 1, 0.7];  
    
     
    if (!isNull _refUnit) then {
        _survivor setUnitLoadout (getUnitLoadout _refUnit);
    };

    _survivor setCaptive true;  
    _survivor setHit ["legs", 1];  
    
     
    _survivor disableAI "ANIM";
    _survivor disableAI "MOVE";
    _survivor disableAI "TARGET";
    _survivor disableAI "AUTOTARGET";
    
     
    _survivor switchMove "AinjPpneMstpSnonWrflDnon"; 
    
     
    [_survivor, _refUnit] spawn {
        params ["_unit", "_refUnit"];
        sleep 5;
        
        if (!alive _unit) exitWith {};

         
        removeAllWeapons _unit;
        removeAllItems _unit;
        removeAllAssignedItems _unit;
        removeUniform _unit;
        removeVest _unit;
        removeBackpack _unit;
        removeHeadgear _unit;
        removeGoggles _unit;

         
         
        private _faces = ["WhiteHead_01","WhiteHead_02","WhiteHead_03","WhiteHead_04","WhiteHead_05","AfricanHead_01","AfricanHead_02","AsianHead_A3_01","AsianHead_A3_02","GreekHead_A3_01"];
        private _face = selectRandom _faces;
        
        private _speakers = ["Male01FRE", "Male02FRE", "Male03FRE"];
        private _speaker = "NoVoice"; // Silence tant qu'ils sont au sol (sera rétabli au soin)
        
        private _firstNames = ["Julien", "Thomas", "Nicolas", "Alexandre", "Maxime", "Guillaume", "Lucas", "Romain", "Moussa", "Mehdi"];
        private _lastNames = ["Martin", "Bernard", "Petit", "Dubois", "Moreau", "Laurent", "Girard", "N'Diaye", "Benali"];
        private _name = format ["%1 %2", selectRandom _firstNames, selectRandom _lastNames];

        [_unit, _face, _speaker, _name] call {
            params ["_u", "_f", "_s", "_n"];
            _u setFace _f;
            _u setSpeaker _s;
            _u setName _n;
        };

         
        if (!isNull _refUnit) then {
            _unit setUnitLoadout (getUnitLoadout _refUnit);
        } else {
             
            _unit forceAddUniform "U_B_CombatUniform_mcam";
            _unit addVest "V_PlateCarrier1_rgr";
            _unit addHeadgear "H_HelmetB";
            _unit addWeapon "arifle_MX_F";
            _unit addPrimaryWeaponItem "acc_flashlight";
            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemRadio";
        };

        _unit allowDamage true; 
    };

     
    _survivor setVariable ["MISSION_Bleedout_Limit", 300 + (random 600), true];
    _survivor setVariable ["MISSION_Task03_is_stabilized", false, true];

    _survivors pushBack _survivor;

 
     
    [
        _survivor,
        [
            localize "STR_ACTION_HEAL_SURVIVOR",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                
                 
                _caller playMove "AinvPknlMstpSnonWnonDnon_medic_1";
                
                sleep 6;
                
                if (alive _target && alive _caller) then {
                     
                    _target setVariable ["MISSION_Task03_is_stabilized", true, true];
                    _target setVariable ["MISSION_Stabilized_Time", serverTime, true];

                     
                    _target setDamage 0;
                    _target setCaptive false;

                     
                    _target enableAI "ANIM";
                    _target enableAI "MOVE";
                    _target enableAI "TARGET";
                    _target enableAI "AUTOTARGET";
                    
                     
                    [_target, "AmovPpneMstpSrasWrflDnon"] remoteExec ["switchMove", 0];
                    
                    // Rétablissement de la voix
                    private _speakers = ["Male01FRE", "Male02FRE", "Male03FRE"];
                    [_target, (selectRandom _speakers)] remoteExec ["setSpeaker", 0];
                    
                     
                    [_target] joinSilent (group _caller);
                    _target doFollow _caller;
                    
                     
                    [_target, _actionId] remoteExec ["removeAction", 0];
                    
                    systemChat localize "STR_MSG_SURVIVOR_SAVED";
                };
            },
            [],
            1.5,
            true,
            true,
            "",
            "alive _target && !(_target getVariable ['MISSION_Task03_is_stabilized', false]) && (_this distance _target < 5)", 
            3
        ]
    ] remoteExec ["addAction", 0, true];
};

 
private _allEnemyGroups = [];

for "_g" from 1 to 2 do {
    private _grpEnemies = createGroup [east, true];
    _allEnemyGroups pushBack _grpEnemies;
    
     
    private _enemyPos = _heli getPos [35 + (random 15), random 360];

     
    private _leader = _grpEnemies createUnit ["O_Soldier_F", _enemyPos, [], 0, "NONE"];
    [_leader] call Mission_fnc_applyCivilianTemplate;
    _leader addBackpack "B_Messenger_Coyote_F";
    _leader addWeapon "uk3cb_ak47";
    _leader addPrimaryWeaponItem "rhs_acc_2dpZenit";
    _leader addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
    for "_i" from 1 to 3 do { _leader addItemToBackpack "rhs_30Rnd_762x39mm_bakelite"; };

     
    for "_i" from 1 to (3 + (random 3)) do {
        private _unit = _grpEnemies createUnit ["O_Soldier_F", _enemyPos, [], 0, "NONE"];
        [_unit] call Mission_fnc_applyCivilianTemplate;
        
        _unit addBackpack "B_Messenger_Coyote_F";
        _unit addWeapon "uk3cb_ak47";
        _unit addPrimaryWeaponItem "rhs_acc_2dpZenit";
        _unit addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
        for "_j" from 1 to 3 do { _unit addItemToBackpack "rhs_30Rnd_762x39mm_bakelite"; };
    };

     
    [_grpEnemies, _heli] spawn {
        params ["_grp", "_heli"];
        
        _grp setBehaviour "COMBAT";
        _grp setCombatMode "RED";
        _grp setSpeedMode "FULL";
        
        while { ({alive _x} count (units _grp)) > 0 } do {
             
            private _movePos = _heli getPos [40 + (random 15), random 360];
            
            {
                if (alive _x) then {
                    _x doMove _movePos;
                    _x setUnitPos "AUTO"; 
                };
            } forEach (units _grp);
            
             
            sleep 20;
        };
    };
};
 

 
private _mrk = createMarker ["mrk_task03_crash", _crash_pos];
_mrk setMarkerType "hd_objective";
_mrk setMarkerColor "ColorRed";
_mrk setMarkerText localize "STR_TASK03_MARKER";

 
[
    true,
    "Task03",
    [localize "STR_TASK03_DESC", localize "STR_TASK03_TITLE", localize "STR_TASK03_MARKER"],
    _crash_loc_obj,
    "CREATED",
    1,
    true,
    "heal",
    true
] call BIS_fnc_taskCreate;


 
[_survivors, _crash_pos, _heli, _smoke, _allEnemyGroups, _mrk] spawn {
    params ["_survivors", "_crash_pos", "_heli", "_smoke", "_allEnemyGroups", "_mrk"];
    
     
    waitUntil { 
        sleep 5;
         
        private _validPlayers = allPlayers select { alive _x };
        if (count _validPlayers == 0) exitWith { false };
        
        private _nearest = [_validPlayers, _crash_pos] call BIS_fnc_nearestPosition;
        (_nearest distance2D _crash_pos) < 200
    };
    
    systemChat ">>> TASK 03: Début du compte à rebours de survie <<<";
    
     
    private _startTime = time;  
    
    private _fnc_checkVictory = {
        params ["_survivors"];
        
        private _aliveCount = { alive _x } count _survivors;
        if (_aliveCount == 0) exitWith { false };  

        private _stabilizedCount = {
            alive _x && (_x getVariable ["MISSION_Task03_is_stabilized", false])
        } count _survivors;

         
        (_stabilizedCount == _aliveCount)
    };

    private _missionActive = true;
    
    while { _missionActive } do {
        sleep 10;  
        
         
        {
            if (alive _x && !(_x getVariable ["MISSION_Task03_is_stabilized", false])) then {
                private _limit = _x getVariable ["MISSION_Bleedout_Limit", 300];
                private _elapsed = time - _startTime;
                
                if (_elapsed > _limit) then {
                    _x setDamage 1;
                    systemChat localize "STR_MSG_SURVIVOR_DIED";
                };
            };
        } forEach _survivors;
        
         
        if ([_survivors] call _fnc_checkVictory) then {
            ["Task03", "SUCCEEDED"] call BIS_fnc_taskSetState;
            _missionActive = false;
        };
        
         
        private _aliveSurvivors = { alive _x } count _survivors;
        if (_aliveSurvivors == 0) then {
            ["Task03", "FAILED"] call BIS_fnc_taskSetState;
            _missionActive = false;
        };
    };
    
     
    waitUntil {
        sleep 30;  
        private _validPlayers = allPlayers select { alive _x };
        if (count _validPlayers == 0) exitWith { true };
        private _nearest = [_validPlayers, _crash_pos] call BIS_fnc_nearestPosition;
        (_nearest distance2D _crash_pos) > 1200
    };
    
    deleteVehicle _heli;
    deleteVehicle _smoke;
    deleteMarker _mrk;
    
     
    {
        private _grp = _x;
        if (!isNull _grp) then {
            {
                if (alive _x) then {
                    private _nearest = [allPlayers, _x] call BIS_fnc_nearestPosition;
                    _x doMove (getPos _nearest);
                    _x setBehaviour "COMBAT";
                    _x setSpeedMode "FULL";
                };
            } forEach units _grp;
        };
    } forEach _allEnemyGroups;
};
