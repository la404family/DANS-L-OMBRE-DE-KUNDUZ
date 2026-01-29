/*
    fn_livraison_vehicule.sqf
    EXPERT SQF arma3 -- code optimisé pour jeux multijoueurs et solo
    
    Exécution: [getPos player] remoteExec ["Mission_fnc_livraison_vehicule", 2];
*/

if (!isServer) exitWith {};

params ["_targetPos"];

if (_targetPos isEqualTo [0,0,0]) exitWith {
    diag_log "[LIVRAISON] Erreur: Position invalide";
};

// --- CONFIGURATION ---
private _spawnDist = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F"; // Caracal
private _vehClass = "AMF_VBMRL_762_Tundra"; 
private _flyHeight = 150;

// Calcul du point de départ (direction aléatoire depuis la cible)
private _dir = random 360;
private _spawnPos = [
    (_targetPos select 0) + (sin _dir * _spawnDist),
    (_targetPos select 1) + (cos _dir * _spawnDist),
    _flyHeight
];

// 1. SPAWN HÉLICOPTÈRE - directement en vol
private _heli = createVehicle [_helicoClass, _spawnPos, [], 0, "FLY"];
_heli setPos _spawnPos;
_heli setDir (_dir + 180);
_heli flyInHeight _flyHeight;
_heli allowDamage false;

// Créer l'équipage
private _group = createGroup [WEST, true];
private _crew = [];

private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
_crew pushBack _pilot;

private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;

// Configuration IA - Comportement logistique
_group setBehaviour "CARELESS";
_group setCombatMode "BLUE";
_group setSpeedMode "FULL";

{
    _x disableAI "AUTOCOMBAT";
    _x disableAI "AUTOTARGET";
    _x disableAI "TARGET";
    _x disableAI "FSM";
    _x setCaptive true;
    _x allowDamage false;
} forEach _crew;

// 2. VÉHICULE & SLING LOAD
private _cargo = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -10]);
_cargo allowDamage false;
private _originalMass = getMass _cargo;
_cargo setMass 1000; // Allègement pour transport
_heli setSlingLoad _cargo;

(localize "STR_LIVRAISON_INBOUND") remoteExec ["systemChat", 0];
diag_log format ["[LIVRAISON] Créé en %1, cible %2", _spawnPos, _targetPos];

// 3. BOUCLE DE GESTION
[_heli, _cargo, _targetPos, _group, _crew, _spawnPos, _originalMass] spawn {
    params ["_heli", "_cargo", "_targetPos", "_group", "_crew", "_homeBase", "_originalMass"];
    
    // Trouver point de largage (Priorité: waypoint_invisible > route)
    private _dropPos = _targetPos;
    private _wps = nearestObjects [_targetPos, ["CUP_A1_Road_road_invisible"], 300];
    if (count _wps > 0) then {
        _dropPos = getPos (_wps select 0);
    } else {
        private _roads = _targetPos nearRoads 150;
        if (count _roads > 0) then { _dropPos = getPos (_roads select 0); };
    };
    
    // Waypoint approche
    private _wp1 = _group addWaypoint [_dropPos, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointSpeed "FULL";
    
    _heli doMove _dropPos;
    
    waitUntil { sleep 1; (_heli distance2D _dropPos) < 300 || !alive _heli };
    if (!alive _heli) exitWith { diag_log "[LIVRAISON] Détruit pendant approche"; };

    deleteWaypoint _wp1;
    
    // Descente
    _heli flyInHeight 15;
    _heli flyInHeightASL [15, 15, 15];
    
    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";
    
    _heli doMove _dropPos;
    
    private _timeout = 0;
    waitUntil { 
        sleep 0.5; 
        _timeout = _timeout + 0.5;
        ((_heli distance2D _dropPos) < 50) || _timeout > 60 || !alive _heli 
    };
    
    if (!alive _heli) exitWith { diag_log "[LIVRAISON] Détruit pendant descente"; };

    // Stationnaire
    doStop _heli;
    _heli flyInHeight 5;
    
    private _dropTimeout = 0;
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.5;
        ((getPosATL _heli select 2) < 15) || _dropTimeout > 20
    };
    
    sleep 2;
    
    // Largage
    private _dropTime = -1;
    if (alive _heli && alive _cargo) then {
        _heli setSlingLoad objNull;
        detach _cargo;
        _cargo setVelocity [0,0,0];
        
        waitUntil { sleep 0.1; (getPosATL _cargo select 2) < 1 };
        
        _cargo setMass _originalMass;
        _cargo allowDamage true;
        
        (localize "STR_LIVRAISON_DROPPED") remoteExec ["systemChat", 0];
        diag_log "[LIVRAISON] Véhicule largué";
        _dropTime = time;
    };
    
    sleep 3;
    
    // Retour base
    deleteWaypoint [_group, 0];
    
    _heli flyInHeight 150;
    
    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    
    _heli doMove _homeBase;
    
    // Nettoyage
    waitUntil { 
        sleep 5; 
        (_heli distance2D _targetPos > 2000) || !alive _heli || (_dropTime > 0 && {time - _dropTime > 120})
    };
    
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
    
    diag_log "[LIVRAISON] Entités supprimées";
};