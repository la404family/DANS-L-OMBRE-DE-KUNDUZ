/*
    task_ostage.sqf
    Mission: Sauvetage d'otage (HVT)
    - 1 Zone (waypoint_invisible_XXX)
    - 1 Otage (Template Civil)
    - 3-7 Ennemis
    - Extraction Hélico (waypoint_livraison_XXX)
*/

if (!isServer) exitWith {};

// --- 1. SELECTION DE LA ZONE ---
private _possibleLocs = [];

// Recherche des waypoints_invisible_000 à 340
for "_i" from 0 to 340 do {
    private _suffix = "";
    if (_i < 10) then { _suffix = format ["00%1", _i]; }
    else { if (_i < 100) then { _suffix = format ["0%1", _i]; } else { _suffix = str _i; }; };
    
    private _wp = missionNamespace getVariable [format ["waypoint_invisible_%1", _suffix], objNull];
    if (!isNull _wp) then { _possibleLocs pushBack _wp; };
};

if (_possibleLocs isEqualTo []) exitWith { 
    systemChat "ERREUR: Aucun 'waypoint_invisible_XXX' trouvé pour la mission Otage."; 
};

private _objectiveObj = selectRandom _possibleLocs;
private _posObjective = getPos _objectiveObj;

// --- 2. CREATION DE LA TACHE ---
private _taskID = format ["task_hostage_%1", floor(random 99999)];

[
    true,
    _taskID,
    [
        localize "STR_TASK_OSTAGE_DESC",
        localize "STR_TASK_OSTAGE_TITLE",
        "MARKER"
    ],
    _posObjective,
    "CREATED",
    1,
    true,
    "SEARCH",
    true
] call BIS_fnc_taskCreate;

// Marqueur de zone approximatif
private _marker = createMarker [format ["m_%1", _taskID], _posObjective getPos [random 30, random 360]];
_marker setMarkerType "hd_unknown";
_marker setMarkerColor "ColorOrange";
_marker setMarkerText (localize "STR_TASK_OSTAGE_MARKER");
_marker setMarkerShape "ELLIPSE";
_marker setMarkerSize [50, 50];
_marker setMarkerBrush "Border";

// --- 3. SPAWN OTAGE ---
private _civGroup = createGroup [civilian, true];
private _civType = "C_man_polo_1_F";

private _hostage = _civGroup createUnit [_civType, _posObjective, [], 0, "NONE"];
_hostage setPos [getPos _hostage select 0, getPos _hostage select 1, 0.7]; // Spawn à 0.7m du sol

// APPLICATION DU PROFIL CIVIL (Tenue + Identité)
// Le genre sera auto-détecté selon l'uniforme (Burqa = femme)
[_hostage] call Mission_fnc_apply_civilian_profile;

// Configuration Otage (spécifique mission)
_hostage setCaptive true;
// Note: removeAllWeapons déjà fait dans fn_apply_civilian_profile
_hostage disableAI "ANIM";
_hostage disableAI "MOVE";
_hostage switchMove "Acts_ExecutionVictim_Loop";
_hostage setVariable ["isCaptive", true, true];

// Action Holster
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
        
        // Animation et libération
        [_target] spawn {
            params ["_civ"];
            [_civ, "Acts_ExecutionVictim_Unbow"] remoteExec ["switchMove", 0];
            sleep 8;
            _civ setCaptive false;
            _civ enableAI "ANIM";
            _civ enableAI "MOVE";
            _civ switchMove "";
            
            // Logique de suivi du joueur
            [_civ] spawn {
                params ["_unit"];
                _unit setBehaviour "CARELESS";
                _unit setUnitPos "UP";
                
                while {alive _unit && !(_unit getVariable ["inHeli", false])} do {
                    private _nearest = objNull;
                    private _distMin = 9999;
                    {
                        if (alive _x && isPlayer _x) then {
                            private _d = _x distance _unit;
                            if (_d < _distMin) then { _distMin = _d; _nearest = _x; };
                        };
                    } forEach allPlayers;
                    
                    if (!isNull _nearest) then {
                        if (_distMin > 5) then {
                            _unit doMove (getPos _nearest);
                        };
                    };
                    sleep 3;
                };
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
        
        // Animation et libération
        [_target] spawn {
            params ["_civ"];
            [_civ, "Acts_ExecutionVictim_Unbow"] remoteExec ["switchMove", 0];
            sleep 8;
            _civ setCaptive false;
            _civ enableAI "ANIM";
            _civ enableAI "MOVE";
            _civ switchMove "";
            
            // Logique de suivi du joueur
            [_civ] spawn {
                params ["_unit"];
                _unit setBehaviour "CARELESS";
                _unit setUnitPos "UP";
                
                while {alive _unit && !(_unit getVariable ["inHeli", false])} do {
                    private _nearest = objNull;
                    private _distMin = 9999;
                    {
                        if (alive _x && isPlayer _x) then {
                            private _d = _x distance _unit;
                            if (_d < _distMin) then { _distMin = _d; _nearest = _x; };
                        };
                    } forEach allPlayers;
                    
                    if (!isNull _nearest) then {
                        if (_distMin > 5) then {
                            _unit doMove (getPos _nearest);
                        };
                    };
                    sleep 3;
                };
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


// --- 4. SPAWN ENNEMIS (3 à 7) ---
// --- 4. SPAWN ENNEMIS (3 à 7) ---
private _unitsToSpawn = 3 + floor(random 5); // 3 à 7

while {_unitsToSpawn > 0} do {
    // Détermine la taille du groupe (2 ou 3)
    private _groupSize = 2;
    if (_unitsToSpawn == 3) then { _groupSize = 3; }; 
    _unitsToSpawn = _unitsToSpawn - _groupSize;

    private _group = createGroup [east, true];
    private _spawnPos = _posObjective getPos [10 + random 20, random 360];

    for "_i" from 1 to _groupSize do {
        private _unit = _group createUnit ["O_Soldier_F", _spawnPos, [], 0, "NONE"];
        _unit setPos [getPos _unit select 0, getPos _unit select 1, 0.7]; // Spawn à 0.7m du sol
        
        // 1. APPLICATION DU PROFIL CIVIL (Tenue + Identité)
        [_unit] call Mission_fnc_apply_civilian_profile;
        
        // 2. RE-ARMEMENT INSURGÉ (AKMN + Sac bandoulière)
        // Le profil a nettoyé les armes/sacs, on rajoute l'équipement de combat
        _unit addBackpack "B_Messenger_Coyote_F";
        
        _unit addWeapon "rhs_weap_akmn";
        _unit addPrimaryWeaponItem "rhs_30Rnd_762x39mm"; 
        _unit addPrimaryWeaponItem "rhs_acc_2dpZenit"; 
        
        for "_j" from 1 to 2 do {
            _unit addItemToBackpack "rhs_30Rnd_762x39mm";
        };
        
        _unit linkItem "ItemMap";
        _unit linkItem "ItemCompass";
        _unit linkItem "ItemRadio";
    };
    
    // Patrouille de GROUPE
    [_group, _posObjective] spawn {
        params ["_grp", "_center"];
        _grp setBehaviour "SAFE";
        _grp setSpeedMode "LIMITED";
        
        while {{alive _x} count (units _grp) > 0} do {
            // Le leader décide du mouvement, les autres suivent
            (leader _grp) doMove (_center getPos [random 50, random 360]);
            sleep (30 + random 60);
        };
    };
};


// --- 5. GESTION EXTRACTION ---
[_taskID, _hostage, _posObjective, _marker] spawn {
    params ["_taskID", "_hostage", "_posObjective", "_marker"];
    
    // Attente libération
    waitUntil { sleep 1; !alive _hostage || !(_hostage getVariable ["isCaptive", true]) };
    
    if (!alive _hostage) exitWith { [_taskID, "FAILED"] call BIS_fnc_taskSetState; deleteMarker _marker; };
    
    [_taskID, "ASSIGNED"] call BIS_fnc_taskSetState;
    deleteMarker _marker;
    
    // --- 5a. Trouver LZ (waypoint_livraison_XXX) ---
    private _lzLocs = [];
    for "_i" from 0 to 127 do {
        private _suffix = "";
        if (_i < 10) then { _suffix = format ["00%1", _i]; }
        else { if (_i < 100) then { _suffix = format ["0%1", _i]; } else { _suffix = str _i; }; };
        
        private _wp = missionNamespace getVariable [format ["waypoint_livraison_%1", _suffix], objNull];
        if (!isNull _wp) then { _lzLocs pushBack _wp; };
    };
    
    private _lzObj = objNull;
    private _minDist = 99999;
    
    {
        private _d = _x distance2D _hostage;
        if (_d < _minDist) then { _minDist = _d; _lzObj = _x; };
    } forEach _lzLocs;
    
    if (isNull _lzObj) exitWith { systemChat "ERREUR: Pas de LZ trouvée"; };
    
    private _posLZ = getPos _lzObj;
    
    // --- 5b. Spawn Hélico Extraction (Logique fn_livraison_munitions) ---
    private _spawnDist = 2000;
    private _dir = random 360;
    private _spawnPosHeli = _posLZ getPos [_spawnDist, _dir];
    _spawnPosHeli set [2, 150];
    
    private _helicoClass = "B_AMF_Heli_Transport_01_F"; // Caracal
    private _heli = objNull;
    private _spawnAttempts = 0;
    
    // Boucle de spawn sécurisée
    while {isNull _heli && _spawnAttempts < 5} do {
        _spawnAttempts = _spawnAttempts + 1;
        _heli = createVehicle [_helicoClass, _spawnPosHeli, [], 0, "FLY"];
        
        if (!isNull _heli) then {
            _heli setPos _spawnPosHeli;
            _heli setDir (_dir + 180);
            _heli flyInHeight 150;
            _heli allowDamage false;
        } else {
            sleep 1;
        };
    };
    
    if (isNull _heli) exitWith { systemChat "ERREUR: Spawn Hélico échoué"; };
    
    // Création équipage manuel
    private _heliGroup = createGroup [WEST, true];
    private _crew = [];
    
    // Pilote
    private _pilot = _heliGroup createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
    _pilot moveInDriver _heli;
    _crew pushBack _pilot;
    
    // Co-pilote / Turrets
    {
        private _gunner = _heliGroup createUnit ["B_Soldier_F", [0,0,0], [], 0, "NONE"];
        _gunner moveInTurret [_heli, _x];
        _crew pushBack _gunner;
    } forEach (allTurrets _heli);
    
    // Config IA
    _heliGroup setBehaviour "CARELESS";
    _heliGroup setCombatMode "RED";
    _heliGroup setSpeedMode "FULL";
    
    {
        _x disableAI "FSM";        
        _x allowDamage false;      
    } forEach _crew;
    
    _heli lock 2; // Verrouillé pour les joueurs
    
    // --- 5c. Approche et Atterrissage (Logique fn_task_fin) ---
    // Marker temporaire
    private _markerLZ = createMarker [format ["mrk_extract_%1", _taskID], _posLZ];
    _markerLZ setMarkerType "mil_pickup";
    _markerLZ setMarkerColor "ColorBlue";
    _markerLZ setMarkerText (localize "STR_MARKER_EXTRACTION");

    [_taskID, _posLZ] call BIS_fnc_taskSetDestination;
    (localize "STR_HINT_EXTRACTION_INCOMING") remoteExec ["hint", 0];
    
    _heli doMove _posLZ;
    
    // Attendre approche
    waitUntil { sleep 1; (_heli distance2D _posLZ) < 300 || !alive _heli };
    if (!alive _heli) exitWith {};
    
    // Force atterrissage
    _heli flyInHeight 0;
    _heli land "GET IN";
    
    // Attendre sol
    private _landTimeout = 0;
    waitUntil { 
        sleep 1; 
        _landTimeout = _landTimeout + 1;
        ((getPos _heli select 2) < 2) || _landTimeout > 120 
    };
    
    doStop _heli;
    _heli setFuel 0; // Coupe moteur pour rester au sol
    
    // Ouverture portes/rampe si possible
    _heli animateSource ["Ramp", 1];
    _heli animateDoor ["Ramp", 1];
    _heli animateDoor ["Door_L", 1];
    _heli animateDoor ["Door_R", 1];
    
    // --- 5d. Embarquement ---
    private _hostageBoarded = false;
    
    waitUntil {
        sleep 1;
        if (!alive _hostage || !alive _heli) exitWith { true };
        
        private _dist = _hostage distance _heli;
        
        // Force embarquement si proche
        if (_dist < 30 && !(_hostage getVariable ["inHeli", false])) then {
            _hostage setVariable ["inHeli", true];
            _hostage assignAsCargo _heli;
            [_hostage] orderGetIn true;
            _hostage moveInCargo _heli;
        };
        
        if (vehicle _hostage == _heli) then { _hostageBoarded = true; };
        
        _hostageBoarded
    };
    
    // Gestion ECHEC : Si otage mort ou hélico détruit
    if (!alive _hostage || !alive _heli) then {
        [_taskID, "FAILED"] call BIS_fnc_taskSetState;
        deleteMarker _markerLZ;
        
        // Si otage mort mais hélico vivant : Départ
        if (alive _heli) then {
            _heli animateSource ["Ramp", 0];
            _heli animateDoor ["Ramp", 0];
            _heli setFuel 1;
            _heli engineOn true;
            _heli flyInHeight 200;
            _heli doMove (_posLZ getPos [5000, random 360]);
        };
    } else {

    
        // --- 5e. Départ (SUCCES) ---
    (localize "STR_HINT_EXTRACTION_TAKEOFF") remoteExec ["hint", 0]; // "Décollage !"
    
    // Fermeture portes
    _heli animateSource ["Ramp", 0];
    _heli animateDoor ["Ramp", 0];
    
    _heli setFuel 1;
    _heli engineOn true;
    _heli flyInHeight 200;
    
    private _exitPos = _posLZ getPos [5000, random 360];
    _heli doMove _exitPos;
    
    sleep 10;
    [_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
    deleteMarker _markerLZ;
    };
    
    // Cleanup
    waitUntil { sleep 5; (_heli distance2D _posLZ) > 2000 };
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteVehicle _hostage;
    deleteGroup _heliGroup;
    deleteGroup (group _hostage);
    deleteMarker _markerLZ;
};