/*
    GESTION INTELLIGENTE DES CIVILS - SYSTEME DYNAMIQUE
    - Pool: civil_00..41 convertis en données virtuelles (Templates)
    - Spawn: Jusqu'à CIV_MaxCivilians (65) si joueur dans une zone
    - Position: Sur 'point_daparission_XX' proche du joueur (300m)
    - Despawn: Si > 500m du joueur
*/

// S'assurer que le script tourne sur le serveur uniquement
if (!isServer) exitWith {};

// Éviter les doubles exécutions si appelé plusieurs fois par erreur
if (!isNil "CIV_Logic_Active") exitWith { systemChat "[CIV] Logic already active."; };
CIV_Logic_Active = true;

// Pour éviter de bloquer l'initialisation si appelé via call
if (!canSuspend) exitWith { _this spawn Mission_fnc_civilian_logique; };

// --- CONFIGURATION ---
CIV_DistanceFuite   = 35;
CIV_DistanceTir     = 50; // Distance de réaction aux tirs
CIV_VitesseFuite    = 45;
CIV_SpawnRadius     = 1200; // Rayon autour du joueur pour choisir les points de spawn
CIV_DespawnRadius   = 1500; // Distance de suppression (doit être > SpawnRadius)
CIV_MaxCivilians    = 45;  // Nombre TOTAL de civils actifs simultanément
CIV_Debug           = false;

// --- FONCTIONS LOCALES ---

private _fnc_log = {
    params ["_msg"];
    if (CIV_Debug) then { systemChat format ["[CIV] %1", _msg]; };
};

// --- CRÉATION AGENT (Depuis Template) ---
private _fnc_spawnAgent = {
    params ["_data", "_pos"];
    _data params ["_type", "_loadout", "_face"];

    private _agent = createAgent [_type, _pos, [], 0, "NONE"];
    _agent setDir (random 360);
    _agent setUnitLoadout _loadout;
    _agent setFace _face;
    
    // Optimisation & Setup
    _agent disableAI "FSM"; 
    _agent disableAI "MINEDETECTION";
    _agent disableAI "SUPPRESSION";
    _agent disableAI "COVER";
    _agent disableAI "AUTOTARGET";
    _agent disableAI "TARGET";
    _agent disableAI "WEAPONAIM";
    // Force peaceful/slow behavior by default
    _agent setBehaviour "CARELESS"; 
    _agent setUnitPos "UP"; // FORCE DEBOUT (CRITIQUE)
    _agent setSpeedMode "LIMITED";
    _agent forceSpeed 2; // FORCE WALK (approx 2m/s)
    
    // Event Handler PEUR DU TIR (FiredNear)
    _agent addEventHandler ["FiredNear", {
        params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];
        if (_distance < CIV_DistanceTir && {isPlayer _firer}) then {
             // OPTIMIZATION: If already fleeing, just extend timer without resetting animation
             if ((_unit getVariable ["CIV_State", "IDLE"]) == "FLEEING") then {
                 _unit setVariable ["CIV_StateTimer", time + 15]; // Extend to 15s
                 _unit setVariable ["CIV_ThreatPos", getPos _firer];
             } else {
                 _unit setVariable ["CIV_State", "FLEEING"];
                 _unit setVariable ["CIV_StateTimer", time + 15]; // Run for 15s
                 _unit setVariable ["CIV_ThreatPos", getPos _firer];
                 _unit switchMove ""; 
             };
        };
    }];
    
    _agent setVariable ["CIV_IsManaged", true, true];
    
    _agent
};

// --- COMPORTEMENT (State Machine) ---
// États: IDLE, WANDERING, FLEEING
private _fnc_gererComportement = {
    params ["_agent", "_allAgents", "_wanderPoints"]; 

    if (!alive _agent) exitWith {};
    
    // SÉCURITÉ ANTI-RAMPAGE: On force debout si l'agent n'est pas en fuite
    if (unitPos _agent != "UP" && (_agent getVariable ["CIV_State", "IDLE"] != "FLEEING")) then {
        _agent setUnitPos "UP";
    };

    private _currentState = _agent getVariable ["CIV_State", "IDLE"];
    private _stateTimer   = _agent getVariable ["CIV_StateTimer", 0];
    
    // Menace Véhicule (cache de 1 seconde pour éviter les appels répétés)
    private _lastVehicleCheck = _agent getVariable ["CIV_LastVehicleCheck", 0];
    private _cachedMenace = _agent getVariable ["CIV_CachedMenace", objNull];
    private _menace = objNull;
    
    if (time - _lastVehicleCheck > 1) then {
        _menace = nearestObject [_agent, "LandVehicle"];
        _agent setVariable ["CIV_CachedMenace", _menace];
        _agent setVariable ["CIV_LastVehicleCheck", time];
    } else {
        _menace = _cachedMenace;
    };
    
    private _isMenace = (!isNull _menace && {(_agent distance _menace) < CIV_DistanceFuite} && {speed _menace > CIV_VitesseFuite});

    if (_isMenace) then {
        _currentState = "FLEEING";
        _stateTimer = time + 2;
        _agent setVariable ["CIV_State", _currentState];
        _agent setVariable ["CIV_StateTimer", _stateTimer];
        _agent setVariable ["CIV_ThreatPos", getPos _menace];
        _agent switchMove "";
    };

    // On sort si on est occupé, SAUF si on doit fuir (FLEEING est prioritaire)
    if (time < _stateTimer && !_isMenace && _currentState != "FLEEING") exitWith {}; 

    switch (_currentState) do {
        case "FLEEING": {
            // Calcul direction fuite
            private _threatPos = _agent getVariable ["CIV_ThreatPos", []];
            if (count _threatPos == 0 && _isMenace) then { _threatPos = getPos _menace; };
            
            if (_isMenace || time < _stateTimer) then {
                // On fuit
                private _dirFuite = if (count _threatPos > 0) then {
                    (_threatPos getDir _agent) + (random 40 - 20)
                } else {
                    getDir _agent // Fuite en avant par défaut
                };
                
                private _posFuite = _agent getPos [50, _dirFuite];
                
                _agent setUnitPos "UP";
                _agent setSpeedMode "FULL";
                _agent forceSpeed -1; // RELEASE SPEED LIMIT -> RUN
                _agent moveTo _posFuite; 
            } else {
                // Fin de fuite
                _agent setSpeedMode "LIMITED";
                _agent forceSpeed 2; // BACK TO WALK
                _agent setVariable ["CIV_State", "IDLE"];
                _agent setVariable ["CIV_StateTimer", time + random 2];
            };
        };
        case "IDLE": {
            _agent setUnitPos "UP"; // SÉCURITÉ
            private _decision = random 100;
            // 70% chance de se balader, 30% de rester idle
            if (_decision < 70) then { 
                _currentState = "WANDERING"; 
            } else { 
                _agent setVariable ["CIV_StateTimer", time + 5 + random 5]; 
            };
            _agent setVariable ["CIV_State", _currentState];
        };
        case "WANDERING": {
            _agent setUnitPos "UP"; // SÉCURITÉ
            private _dest = [];
            
            // ÉVITEMENT DE COLLISION
            // Si un autre civil est trop proche (< 2m), on se décale
            private _tropProche = _allAgents select { _x != _agent && {_x distance _agent < 2} };
            if (count _tropProche > 0) then {
                 // On fuit l'autre
                 private _other = _tropProche select 0;
                 private _dirFuite = _other getDir _agent; // Direction opposée
                 _dest = _agent getPos [5, _dirFuite + (random 60 - 30)];
            } else {
                if (count _wanderPoints > 0) then {
                    private _closePoints = _wanderPoints select {_x distance _agent < 400};
                    if (count _closePoints > 0) then {
                        private _wp = selectRandom _closePoints;
                        if (_wp isEqualType objNull) then { _dest = getPosATL _wp; } else { _dest = _wp; };
                        _dest = [(_dest select 0) + (random 4 - 2), (_dest select 1) + (random 4 - 2), _dest select 2];
                    };
                };
                if (count _dest == 0) then { _dest = _agent getPos [30, random 360]; };
            };

            _agent setSpeedMode "LIMITED";
            _agent forceSpeed 2; // ENSURE WALK
            _agent moveTo _dest;
            _agent setVariable ["CIV_State", "IDLE"]; 
            _agent setVariable ["CIV_StateTimer", time + 15 + random 15]; 
        };
    };
};

// --- MAIN SETUP ---

// 0. INIT & DATA COLLECTION
if (isNil "MISSION_CivilianTemplates") then {
    MISSION_CivilianTemplates = [];
    for "_i" from 0 to 41 do {
        private _varName = format ["civil_%1", if (_i < 10) then {"0" + str _i} else {str _i}];
        private _unit = missionNamespace getVariable [_varName, objNull];
        if (!isNull _unit) then {
            MISSION_CivilianTemplates pushBack [typeOf _unit, getUnitLoadout _unit, face _unit];
            deleteVehicle _unit;
        };
    };
    if (count MISSION_CivilianTemplates == 0) then {
         // Fallback default
         MISSION_CivilianTemplates = [["C_man_polo_1_F", [], "WhiteHead_01"]];
    };
};

private _poolTemplates = MISSION_CivilianTemplates; // Utilise la globale définie dans initServer.sqf ou ci-desssus
private _activeAgents = [];  // Agents spawnés
private _spawnPoints = [];   
private _wanderPoints = [];  
private _presenceZones = []; 

// Collecte Points
for "_i" from 0 to 62 do {
    private _n = format ["point_daparission_%1", if (_i<10) then {"0"+str _i} else {str _i}];
    private _o = missionNamespace getVariable [_n, objNull];
    if (!isNull _o) then {_spawnPoints pushBack (getPosATL _o)};
};
for "_i" from 0 to 82 do {
    private _n = format ["presence_position_%1", if (_i<10) then {"0"+str _i} else {str _i}];
    private _o = missionNamespace getVariable [_n, objNull];
    if (!isNull _o) then {_wanderPoints pushBack _o};
};
for "_i" from 0 to 8 do {
    private _n = format ["civil_presence_%1", "0"+str _i]; // 00 à 08
    private _o = missionNamespace getVariable [_n, objNull];
    if (!isNull _o) then {_presenceZones pushBack _o};
};

// 1. HARVEST & HIDE EDITOR UNITS (00 à 41) - DÉJÀ FAIT DANS INITSERVER.SQF
// On s'assure juste que poolTemplates n'est pas vide (normalement initServer s'en charge)
if (isNil "_poolTemplates" || {count _poolTemplates == 0}) then {
    // Fallback ultime si initServer a échoué (ne devrait pas arriver)
    _poolTemplates = [["C_man_polo_1_F", [], "WhiteHead_01"]];
    if (CIV_Debug) then { systemChat "[CIV-CRITICAL] Global templates missing, using fallback."; };
};

if (CIV_Debug) then { systemChat format ["[CIV] Templates: %1. Spawns: %2. Zones: %3", count _poolTemplates, count _spawnPoints, count _presenceZones]; };
sleep 1;

// 2. RUNTIME LOOP
while {true} do {
    private _startTime = diag_tickTime;
    private _players = allPlayers select {!(_x isKindOf "HeadlessClient_F")};
    
    // Nettoyage morts
    _activeAgents = _activeAgents select {alive _x};

    // --- A. SPAWN LOGIC ---
    // On spawn seulement si on n'a pas atteint le MAX de pop
    
    // Check global limits first before doing heavy geo checks
    if (count _activeAgents < CIV_MaxCivilians) then {
        // Find players in valid zones first
        private _playersInZone = _players select {
            private _p = _x;
            _presenceZones findIf {_p distance _x < 500} != -1
        };

        if (count _playersInZone > 0) then {
            // Pick a random player in a zone to spawn around
            private _targetPlayer = selectRandom _playersInZone;
            private _targetPos = getPosATL _targetPlayer;
            
            // Filter spawn points for this player
            private _validSpawns = _spawnPoints select {
                private _dist = _x distance _targetPos;
                _dist < CIV_SpawnRadius && _dist > 40
            };
            
            if (count _validSpawns > 0) then {
                    // OPTIMISATION: Spawn jusqu'à 3 civils par boucle (staggered)
                    private _toSpawn = (CIV_MaxCivilians - count _activeAgents) min 3;
                    for "_j" from 1 to _toSpawn do {
                         if (count _activeAgents < CIV_MaxCivilians) then {
                             private _spawnPos = selectRandom _validSpawns;
                             private _template = selectRandom _poolTemplates;
                             
                             private _newAgent = [_template, _spawnPos] call _fnc_spawnAgent;
                             if (!isNull _newAgent) then {
                                _activeAgents pushBack _newAgent;
                                if (CIV_Debug) then { systemChat "[CIV] Spawned Agent"; };
                             };
                         };
                    };
            };
        };
    };

    // --- B. DESPAWN LOGIC ---
    // Process reverse to allow deletion
    for "_i" from (count _activeAgents - 1) to 0 step -1 do {
        private _a = _activeAgents select _i;
        
        // Check distance joueurs
        private _far = true;
        
        // Optimized check: nearest player
        private _nearestPlayer = objNull;
        private _minDist = 99999;
        {
            private _d = _x distance _a;
            if (_d < _minDist) then {_minDist = _d; _nearestPlayer = _x;};
        } forEach _players;

        if (_minDist < CIV_DespawnRadius) then { _far = false; };

        if (_far) then {
             // Just delete (template is safe in pool)
             deleteVehicle _a;
             _activeAgents deleteAt _i;
             if (CIV_Debug) then { systemChat "[CIV] Despawned Agent (Far)"; };
        };
    };

    // --- C. BEHAVIOR UPDATES ---
    // Distribute updates over frames if too many agents (Unscheduled safe check)
    {
        [_x, _activeAgents, _wanderPoints] call _fnc_gererComportement;
        // NO RECURSIVE CALL HERE!
        // sleep 0.001; // Optional: yield if script lag is high, but with 45 agents and efficient logic, it should be fine per second.
    } forEach _activeAgents;

    // Dynamic sleep to maintain decent logic rate (approx 1s) loop
    private _elapsed = diag_tickTime - _startTime;
    private _sleepTime = (1 - _elapsed) max 0.1;
    sleep _sleepTime;
};