if (!isServer) exitWith {};
diag_log "[FIN_MISSION] === Démarrage du système de fin de mission ===";
private _delayBeforeMessage = 2100 + floor(random 600); 
private _heliClass = "amf_nh90_tth_transport"; 
private _flyTime = 120;  
private _heliFinObj = missionNamespace getVariable ["heli_fin", objNull];
private _landingPos = [0, 0, 0];
if (!isNull _heliFinObj) then {
    _landingPos = getPos _heliFinObj;
    diag_log "[FIN_MISSION] Objet heli_fin trouvé !";
} else {
    diag_log "[FIN_MISSION] ERREUR: Objet heli_fin non trouvé! Recherche de marker_4...";
    if (getMarkerColor "marker_4" != "") then {
        _landingPos = getMarkerPos "marker_4";
    } else {
        diag_log "[FIN_MISSION] ERREUR: marker_4 non trouvé! Utilisation de respawn_west";
        _landingPos = getMarkerPos "respawn_west";
    };
};
if (_landingPos isEqualTo [0,0,0]) then {
    diag_log "[FIN_MISSION] ERREUR CRITIQUE: Aucun point d'atterrissage trouvé! Abandon.";
    _landingPos = getPos (allPlayers select 0);
};
diag_log format ["[FIN_MISSION] Position atterrissage: %1", _landingPos];
private _heliFinSpawnObj = missionNamespace getVariable ["heli_fin_spawn", objNull];
private _heliSpawnPos = [0,0,0];
if (!isNull _heliFinSpawnObj) then {
    _heliSpawnPos = getPos _heliFinSpawnObj;
    diag_log "[FIN_MISSION] Utilisation du point de spawn défini : heli_fin_spawn";
} else {
    private _rndDir = random 360;
    _heliSpawnPos = _landingPos getPos [3000, _rndDir];
    diag_log "[FIN_MISSION] heli_fin_spawn introuvable. Spawn aléatoire à 3km.";
};
_heliSpawnPos set [2, 150];
diag_log format ["[FIN_MISSION] Hélico spawn prévu en: %1", _heliSpawnPos];
diag_log format ["[FIN_MISSION] Extraction dans %1 secondes", _delayBeforeMessage];
[_delayBeforeMessage, _heliClass, _flyTime, _landingPos, _heliSpawnPos] spawn {
    params ["_delayBeforeMessage", "_heliClass", "_flyTime", "_landingPos", "_heliSpawnPos"];
    sleep _delayBeforeMessage;
    diag_log "[FIN_MISSION] === Délai écoulé - Lancement extraction ===";
    [
        true,                                      
        "task_evacuation",                         
        [
            localize "STR_TASK_EVAC_DESC",         
            localize "STR_TASK_EVAC_TITLE",        
            "EXFILTRATION"                         
        ],
        _landingPos,                               
        "CREATED",                                 
        10,                                        
        true,                                      
        "takeoff",                                 
        true                                       
    ] call BIS_fnc_taskCreate;
    sleep 10;  
    private _heli = createVehicle [_heliClass, _heliSpawnPos, [], 0, "FLY"];
    _heli setPos _heliSpawnPos;
    _heli setDir (_heliSpawnPos getDir _landingPos);
    _heli flyInHeight 100;
    _heli setFuel 1;
    createVehicleCrew _heli;
    private _group = group driver _heli;
    private _crew = crew _heli;
    _group setBehaviour "CARELESS";
    _group setCombatMode "RED";
    {
        _x setCaptive true;       
        _x allowDamage false;     
    } forEach _crew;
    _heli allowDamage false;      
    _heli doMove _landingPos;
    waitUntil { sleep 1; (_heli distance2D _landingPos) < 300 || !alive _heli };
    _heli flyInHeight 0;
    _heli land "GET IN";
    waitUntil { sleep 1; (_heli distance2D _landingPos) < 50 };
    _heli setFuel 0; 
    private _landTimeout = 0;
    waitUntil { 
        sleep 1; 
        _landTimeout = _landTimeout + 1;
        ((getPos _heli select 2) < 2) || _landTimeout > 90 
    };
    doStop _heli;
    _heli setVehicleLock "UNLOCKED"; 
    _heli animateSource ["Ramp", 1];
    _heli animateDoor ["Ramp", 1];
    ["task_evacuation", _landingPos] call BIS_fnc_taskSetDestination;
    ["task_evacuation", "ASSIGNED"] call BIS_fnc_taskSetState;
    diag_log "[FIN_MISSION] En attente embarquement...";
    private _allPlayersInHeli = false;
    while {!_allPlayersInHeli} do {
        sleep 5;
        private _activePlayers = allPlayers select { alive _x && isPlayer _x };
        private _totalPlayers = count _activePlayers;
        if (_totalPlayers == 0) then { continue }; 
        private _playersInHeli = { (vehicle _x) == _heli } count _activePlayers;
        private _msg = format [localize "STR_EVAC_PLAYER_COUNT", _playersInHeli, _totalPlayers];
        _msg remoteExec ["hintSilent", 0];
        if (_playersInHeli >= _totalPlayers && _totalPlayers > 0) then {
            _allPlayersInHeli = true;
        };
    };
    ["task_evacuation", "SUCCEEDED"] call BIS_fnc_taskSetState;
    {
        if (isPlayer _x && (vehicle _x) == _heli) then {
            [_x, true] remoteExec ["hideObjectGlobal", 2]; 
            _x allowDamage false;
        };
    } forEach allPlayers;
    _heli land "NONE";
    ["intro_00"] remoteExec ["playMusic", 0];  
    _heli animateSource ["door_rear_source", 0];
    _heli animateDoor ["door_rear_source", 0];
    _heli animateDoor ["ramp", 0];
    _heli setVehicleLock "LOCKED";
    sleep 2;
    _heli setFuel 1;
    _heli engineOn true;
    {
        if (side _x == east || side _x == independent || side _x == resistance) then {
            _x setDamage 1;
        };
    } forEach (_heli nearEntities [["Man", "Car", "Tank", "Air"], 1000]);
    sleep 5;
    private _heliFinDirObj = missionNamespace getVariable ["heli_fin_direction", objNull];
    private _exitPos = [0,0,0];
    if (!isNull _heliFinDirObj) then {
         _exitPos = getPos _heliFinDirObj;
         diag_log "[FIN_MISSION] Sortie vers heli_fin_direction";
    } else {
        private _dirExit = (_landingPos getDir _heliSpawnPos) + 180;
        _exitPos = _landingPos getPos [5000, _dirExit];
         diag_log "[FIN_MISSION] heli_fin_direction introuvable. Sortie opposée.";
    };
    _heli flyInHeight 200;
    _heli doMove _exitPos;
    _heli limitspeed 300;
    sleep _flyTime;
    ["END1", true] remoteExec ["BIS_fnc_endMission", 0];
};