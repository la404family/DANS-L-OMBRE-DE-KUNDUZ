/*
    fn_task02.sqf
    Description: Mission de sauvetage d'otage dynamique sur 3 lieux potentiels avec extraction héliportée.
*/

if (!isServer) exitWith {};

// Attendre que le template civil soit prêt
waitUntil { !isNil "MISSION_fnc_applyCivilianTemplate" };

// -----------------------------------------------------------------------------
// 1. INITIALISATION ET SÉLECTION DES ZONES
// -----------------------------------------------------------------------------
private _all_locs = [];
for "_i" from 0 to 340 do {
    private _name = format ["waypoint_invisible_%1", if (_i < 10) then { "00" + str _i } else { if (_i < 100) then { "0" + str _i } else { str _i } }];
    private _obj = missionNamespace getVariable [_name, objNull];
    if (!isNull _obj) then { _all_locs pushBack _obj; };
};

private _selected_zones = [];
for "_i" from 1 to 3 do {
    if (count _all_locs > 0) then {
        private _loc = selectRandom _all_locs;
        _selected_zones pushBack _loc;
        _all_locs = _all_locs - [_loc];
    };
};

// Création des marqueurs "?"
private _zone_markers = [];
{
    private _mrk = createMarker [format ["mrk_task02_zone_%1", _forEachIndex], getPos _x];
    _mrk setMarkerType "mil_unknown";
    _mrk setMarkerColor "ColorYellow";
    _mrk setMarkerText "Zone Suspecte";
    _zone_markers pushBack _mrk;
} forEach _selected_zones;

// Sélection de la zone de l'otage
private _hostage_zone_idx = floor (random count _selected_zones);
private _hostage_unit = objNull;
private _guards_groups = [];

// -----------------------------------------------------------------------------
// 2. SPAWNING DES UNITÉS
// -----------------------------------------------------------------------------

{
    private _zone_pos = getPos _x;
    private _is_hostage_zone = (_forEachIndex == _hostage_zone_idx);
    
    // --- A. Configuration des Gardes ---
    private _grp = createGroup [east, true];
    _guards_groups pushBack _grp;
    
    private _num_guards = 3 + floor (random 3);
    for "_i" from 1 to _num_guards do {
        private _guard = _grp createUnit ["O_Soldier_F", _zone_pos, [], 10, "NONE"];
        [_guard] call Mission_fnc_applyCivilianTemplate;
        
        // Équipement Addon
        _guard addBackpack "B_Messenger_Coyote_F";
        for "_k" from 1 to 3 do { _guard addItemToBackpack "rhs_30Rnd_762x39mm_bakelite"; };
        _guard addWeapon "uk3cb_ak47";
        _guard addPrimaryWeaponItem "rhs_acc_2dpZenit";
        _guard addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
        
        // Comportement Patrouille (Thread léger)
        [_guard, _zone_pos] spawn {
            params ["_unit", "_center"];
            while { alive _unit } do {
                _unit doMove (_center getPos [random 25, random 360]);
                sleep (10 + random 20);
            };
        };
    };
    
    // --- B. Configuration de l'Otage ---
    if (_is_hostage_zone) then {
        private _hostage_grp = createGroup [civilian, true];
        _hostage_unit = _hostage_grp createUnit ["C_man_1", _zone_pos, [], 0, "NONE"];
        [_hostage_unit] call Mission_fnc_applyCivilianTemplate;
        
        _hostage_unit setCaptive true;
        _hostage_unit disableAI "MOVE";
        _hostage_unit disableAI "ANIM";
        
        // Animation "à genoux/ligoté" (exemple: Acts_AidlPsitMstpSsurWnonDnon_loop ou similaire)
        [_hostage_unit, "Acts_AidlPsitMstpSsurWnonDnon_loop"] remoteExec ["switchMove", 0, true];
        
        // Interaction JIP
        [
            _hostage_unit,
            "Libérer l'otage",
            "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
            "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
            "_this distance _target < 2",
            "_caller distance _target < 2",
            {},
            {},
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                // Déclenchement Libération
                MISSION_Task02_HostageRescued = true;
                publicVariable "MISSION_Task02_HostageRescued";
                
                // Retrait action
                [_target, _actionId] remoteExec ["BIS_fnc_holdActionRemove", 0, _target];
            },
            {},
            [],
            3,
            10,
            true,
            false
        ] remoteExec ["BIS_fnc_holdActionAdd", 0, _hostage_unit];
    };
} forEach _selected_zones;

// Création de la Tâche
[
    true,
    "Task02",
    ["Une personne VIP est retenue en otage dans l'une des zones suspectes. Localisez l'otage, libérez-le et extrayez-le par hélicoptère.", "Sauvetage d'Otage", "search"],
    objNull,
    "CREATED",
    1,
    true,
    "search",
    true
] call BIS_fnc_taskCreate;

// -----------------------------------------------------------------------------
// 3. LOGIQUE DE SURVEILLANCE ET LIBÉRATION
// -----------------------------------------------------------------------------

// Gestion Échec si mort avant extraction
[_hostage_unit] spawn {
    params ["_hostage"];
    waitUntil { !alive _hostage || (missionNamespace getVariable ["MISSION_Task02_Complete", false]) };
    
    if (!alive _hostage) then {
        ["Task02", "FAILED"] call BIS_fnc_taskSetState;
        MISSION_Task02_Failed = true;
        publicVariable "MISSION_Task02_Failed";
    };
};

// Attente Libération
waitUntil { missionNamespace getVariable ["MISSION_Task02_HostageRescued", false] || !alive _hostage_unit };

if (!alive _hostage_unit) exitWith {}; // Echec géré par le spawn ci-dessus

["Task02", getPos _hostage_unit] call BIS_fnc_taskSetDestination;
["Task02", "ASSIGNED"] call BIS_fnc_taskSetState;

// --- A. Comportement Otage (Escorte) ---
[_hostage_unit] spawn {
    params ["_unit"];
    
    [_unit, "AmovPercMstpSnonWnonDnon"] remoteExec ["switchMove", 0]; // Debout
    _unit enableAI "ANIM";
    _unit enableAI "MOVE";
    _unit enableAI "AUTOTARGET";
    _unit enableAI "TARGET";
    _unit setCaptive false; 
    
    while { alive _unit && !(missionNamespace getVariable ["MISSION_Task02_InHeli", false]) } do {
        _unit setUnitPos "UP";
        _unit setBehaviour "CARELESS";
        _unit setSkill ["courage", 1];
        
        // Suivre joueur le plus proche
        private _nearestPlayer = objNull;
        private _minDist = 99999;
        {
            private _d = _x distance2D _unit;
            if (_d < _minDist) then { _minDist = _d; _nearestPlayer = _x; };
        } forEach (allPlayers select { alive _x });
        
        if (!isNull _nearestPlayer) then {
            _unit doMove (getPos _nearestPlayer);
        };
        
        sleep 5;
    };
};

// --- B. Réaction Ennemie ---
[_guards_groups] spawn {
    params ["_groups"];
    
    {
        private _grp = _x;
        {
            if (alive _x) then {
                private _nearestPlayer = objNull;
                private _minDist = 99999;
                
                // Trouver le joueur le plus proche
                private _alivePlayers = allPlayers select { alive _x };
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
        } forEach units _grp;
    } forEach _groups;
};

// -----------------------------------------------------------------------------
// 4. SÉQUENCE D'EXTRACTION
// -----------------------------------------------------------------------------

// Trigger & Sélection LZ
// Trouver la LZ (waypoint_livraison_XXX) la plus proche de l'otage
private _all_livraisons = [];
for "_i" from 0 to 127 do {
    private _name = format ["waypoint_livraison_%1", if (_i < 10) then { "00" + str _i } else { if (_i < 100) then { "0" + str _i } else { str _i } }];
    private _obj = missionNamespace getVariable [_name, objNull];
    if (!isNull _obj) then { _all_livraisons pushBack _obj; };
};

private _lz = [_all_livraisons, _hostage_unit] call BIS_fnc_nearestPosition;
if (isNull _lz) then { _lz = getPos _hostage_unit; }; // Fallback

// Spawn Héli
// Spawn Héli
private _heliClass = "B_AMF_Heli_Transport_01_F"; 

private _heliSpawnPos = (getPos _lz) vectorAdd [2000, 2000, 500]; // Loin
private _heli = createVehicle [_heliClass, _heliSpawnPos, [], 0, "FLY"];
private _heliGrp = createGroup [west, true];

// Pilote
private _pilot = _heliGrp createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
private _crew = [_pilot];

// Copilote
private _copilot = _heliGrp createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;

// Remplir toutes les autres tourelles
{
    if (_x isNotEqualTo [0]) then {
        private _u = _heliGrp createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
        _u moveInTurret [_heli, _x];
        _crew pushBack _u;
    };
} forEach (allTurrets _heli);

_heliGrp setBehaviour "CARELESS";
_heliGrp setCombatMode "RED";
_heli lock 2;
_heli allowDamage false; // Sécurité spawn

// Approche
_heli doMove (getPos _lz);
_heli flyInHeight 50;

// Update Tâche
// Update Tâche
["Task02", _lz] call BIS_fnc_taskSetDestination;
// Mettre à jour la description (facultatif, si besoin utiliser taskSetDescription ou recréer) - Suppression de l'appel erroné.

// Atterrissage
waitUntil { (_heli distance2D _lz) < 300 || !alive _heli };
if (!alive _heli) exitWith { ["Task02", "FAILED"] call BIS_fnc_taskSetState; };

_heli land "GET IN";

// Coupure moteur à l'atterrissage pour éviter le redécollage immédiat
[_heli] spawn {
    params ["_vec"];
    waitUntil { (getPosATL _vec select 2) < 1 };
    _vec setFuel 0;
};

// Machine à états : Embarquement
// Surveillance proximité otage -> hélico
private _boarding = false;
while { alive _hostage_unit && !_boarding && alive _heli } do {
    if ((_hostage_unit distance _heli) < 30) then {
        _boarding = true;
        MISSION_Task02_InHeli = true; // Stop loop escorte
        
        [_hostage_unit] joinSilent _heliGrp;
        _hostage_unit assignAsCargo _heli;
        [_hostage_unit] orderGetIn true;
        _hostage_unit allowDamage false;

        // Rendre le carburant
        _heli setFuel 1;

        // Supprimer les marqueurs
        { deleteMarker _x } forEach _zone_markers;

        // Ordonner l'attaque aux ennemis restants
        {
            private _grp = _x;
            _grp setBehaviour "COMBAT";
            _grp setCombatMode "RED";
            _grp setSpeedMode "FULL";
            {
                if (alive _x) then {
                    // Trouver joueur le plus proche
                    private _alivePlayers = allPlayers select { alive _x };
                    if (count _alivePlayers > 0) then {
                         private _target = [_alivePlayers, _x] call BIS_fnc_nearestPosition;
                         _grp reveal [_target, 4];
                         _x doMove (getPos _target);
                    };
                };
            } forEach units _grp;
        } forEach _guards_groups;
    };
    sleep 2;
};

// Conditions Décollage
waitUntil {
    sleep 5;
    private _hostageIn = (vehicle _hostage_unit == _heli);
    private _playersIn = (count (crew _heli select { isPlayer _x }) > 0);
    
    (_hostageIn && !_playersIn) || !alive _heli || !alive _hostage_unit
};

if (!alive _hostage_unit || !alive _heli) exitWith { ["Task02", "FAILED"] call BIS_fnc_taskSetState; };

// Départ
_heli lock 2; // Keep locked
_heli doMove [0,0,0];
_heli flyInHeight 100;

["Task02", "SUCCEEDED"] call BIS_fnc_taskSetState;
MISSION_Task02_Complete = true; 
publicVariable "MISSION_Task02_Complete";

// Cleanup
waitUntil {
    sleep 10;
    private _players = allPlayers select { alive _x };
    private _tooClose = _players findIf { (_x distance2D _heli) < 2000 } > -1;
    (!_tooClose) || !alive _heli
};

{ deleteVehicle _x } forEach (crew _heli);
deleteVehicle _heli;
if (alive _hostage_unit) then { deleteVehicle _hostage_unit; };
