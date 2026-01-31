/*
    fn_livraison_soutienAR.sqf
    EXPERT SQF arma3 -- code optimisé pour jeux multijoueurs et solo
    
    Exécution: [getPos player] remoteExec ["Mission_fnc_livraison_soutienAR", 2];
    
    Version: SOUTIEN AÉRIEN RAPPROCHÉ (CAS)
    - Identique livraison (Spawn, Approche)
    - Pas de cargo
    - Action: Loiter (Orbite) à 10m d'altitude, rayon 25m (diamètre 50m) pendant 2 minutes.
*/

if (!isServer) exitWith {};

params [["_targetPos", [0,0,0], [[]]]];

// Assurer que la position a 3 éléments
if (count _targetPos < 3) then { _targetPos set [2, 0]; };

// --- COOLDOWN (20 Minutes) ---
// Variable globale : MISSION_LastUse_CAS
private _lastUse = missionNamespace getVariable ["MISSION_LastUse_CAS", -9999];
private _cooldownTime = 1200; // 20 minutes

if (time < _lastUse + _cooldownTime) exitWith {
    private _remaining = ceil ((_lastUse + _cooldownTime - time) / 60);
};

// Mise à jour du temps d'utilisation
missionNamespace setVariable ["MISSION_LastUse_CAS", time, true];

// --- CONFIGURATION ---
private _spawnDist = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F"; // Caracal (Même que véhicule)
private _flyHeight = 150;
private _loiterHeight = 10; // Altitude de combat rase-mottes demandée
private _loiterRadius = 25; // Rayon 25m = Diamètre 50m
private _loiterDuration = 120; // 2 minutes

// Calcul du point de départ (direction aléatoire depuis la cible)
private _dir = random 360;
// Calcul Manuel (Plus robuste que getPos)
private _spawnPos = _targetPos vectorAdd [(_spawnDist * (sin _dir)), (_spawnDist * (cos _dir)), _flyHeight];
// Assurer que c'est un Array de 3 nombres pour createVehicle
if (count _spawnPos < 3) then { _spawnPos set [2, _flyHeight]; };

// 1. SPAWN HÉLICOPTÈRE - directement en vol
private _heli = objNull;
private _spawnAttempts = 0;

while {isNull _heli && _spawnAttempts < 5} do {
    _spawnAttempts = _spawnAttempts + 1;
    _heli = createVehicle [_helicoClass, _spawnPos, [], 0, "FLY"];
    
    // Vérification rapide de réussite
    if (!isNull _heli) then {
        _heli setPos _spawnPos;
        _heli setDir (_dir + 180);
        _heli flyInHeight _flyHeight;
        _heli allowDamage false;
    } else {
        // diag_log format ["[CAS] Echec spawn hélico tentative %1", _spawnAttempts];
        sleep 1;
    };
};

if (isNull _heli) exitWith {
    // diag_log "[CAS] CRITIQUE: Impossible de faire spawner l'hélicoptère après 5 essais";
};

// Créer l'équipage (Copie exacte de fn_livraison_vehicule.sqf)
private _group = createGroup [WEST, true];
private _crew = [];

// Pilote
private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
_crew pushBack _pilot;

// Co-pilote (tourelle 0)
private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;

// Tireurs de porte (tourelles 1 et 2)
private _turrets = allTurrets _heli;
private _gunnerTurrets = _turrets select { _x isNotEqualTo [0] }; // Exclure co-pilote

{
    private _gunner = _group createUnit ["B_Soldier_F", [0,0,0], [], 0, "NONE"];
    _gunner moveInTurret [_heli, _x];
    _crew pushBack _gunner;
} forEach _gunnerTurrets;

// Configuration IA
_group setBehaviour "CARELESS"; // Ignore le danger pour rester sur la trajectoire (mais les tireurs tirent)
_group setCombatMode "RED"; // Feu à volonté
_group setSpeedMode "FULL";

// L'équipage peut combattre mais reste invulnérable
{
    _x disableAI "FSM";        
    _x allowDamage false;      
} forEach _crew;

// PAS DE CARGO POUR LE CAS

// Message radio global
// Audio de confirmation (Radio In -> Voice -> Radio Out)
[] spawn {
    "Radio_In" remoteExec ["playSound", 0];
    sleep 0.2;
    private _snd = selectRandom ["soutien01", "soutien02", "soutien03", "soutien04"];
    _snd remoteExec ["playSound", 0];
    sleep 2.5; // Temps moyen pour la phrase
    "Radio_Out" remoteExec ["playSound", 0];
};

// 3. BOUCLE DE GESTION
[_heli, _targetPos, _group, _crew, _spawnPos, _loiterHeight, _loiterRadius, _loiterDuration] spawn {
    params ["_heli", "_targetPos", "_group", "_crew", "_homeBase", "_loiterHeight", "_loiterRadius", "_loiterDuration"];

    // --- RECHERCHE DU POINT DE LOITER ---
    // (Similaire livraison, on cherche un point sûr ou on utilise la cible directement)
    // Pour du CAS, on veut généralement être SUR l'ennemi/joueur, mais un check findSafePos évite de se prendre un arbre
    
    private _dropPos = +_targetPos;
    // On garde la logique de fallback sur position sûre au cas où la cible est dans un batiment
    if (count _dropPos >= 2) then {
        // Check simple : si c'est pas plat/vide, on décale un peu pour l'orbite
        private _flatCheck = _dropPos isFlatEmpty [5, -1, 0.4, 5, 0, false, objNull];
        if (_flatCheck isEqualTo []) then {
             private _safePos = [_dropPos, 0, 100, 5, 0, 0.4, 0, [], _dropPos] call BIS_fnc_findSafePos;
             if (_safePos isEqualType [] && {count _safePos >= 2}) then {
                _dropPos = _safePos;
                if (count _dropPos < 3) then { _dropPos set [2, 0]; };
             };
        };
    };

    // --- MARKER SUR CARTE ---
    private _markerName = format ["cas_mrk_%1", floor(random 10000)];
    private _marker = createMarker [_markerName, _dropPos];
    _marker setMarkerType "mil_warning";
    _marker setMarkerColor "ColorRed";
    _marker setMarkerText (localize "STR_CAS_MARKER");

    // Suppression automatique du marker à la fin
    [_marker, _loiterDuration] spawn {
        params ["_m", "_d"];
        sleep (_d + 60); // Durée mission + marge trajet
        deleteMarker _m;
    };

    // --- PHASE 1: APPROCHE ---
    private _wp1 = _group addWaypoint [_dropPos, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointSpeed "FULL";
    _heli doMove _dropPos;

    // Attendre approche (< 300m ou timeout)
    private _approachTimeout = 0;
    waitUntil {
        sleep 1;
        _approachTimeout = _approachTimeout + 1;
        ((_heli distance2D _dropPos) < 300) || _approachTimeout > 180 || !alive _heli
    };

    if (!alive _heli) exitWith {};

    // --- PHASE 2: DESCENTE ET COMBAT (LOITER) ---
    deleteWaypoint _wp1;
    
    // Descente rapide à l'altitude de combat
    _heli flyInHeight _loiterHeight;
    _heli flyInHeightASL [_loiterHeight, _loiterHeight, _loiterHeight];
    
    // Waypoint LOITER (Orbite)
    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "LOITER";
    _wp2 setWaypointLoiterType "CIRCLE";
    _wp2 setWaypointLoiterRadius _loiterRadius; // 25m (diamètre 50)
    _wp2 setWaypointBehaviour "CARELESS"; // Le pilote se focalise sur le vol
    _wp2 setWaypointCombatMode "RED"; // Les gunners tirent à volonté
    _wp2 setWaypointSpeed "LIMITED"; // Vitesse réduite pour l'orbite
    
    _heli doMove _dropPos;
    
    // Timer de mission
    // "Fait deux tours ou reste 2 minutes" -> On utilise le temps, plus fiable.
    // Timer de mission ACTIF (Boucle de détection et révélation des cibles)
    private _endTime = time + _loiterDuration;
    
    while {time < _endTime && alive _heli} do {
        // Révéler les ennemis proches à l'équipage
        private _nearEnemies = _heli nearEntities [["Man", "Car", "Tank"], 400];
        
        {
            if (side _x == east || side _x == resistance) then {
                _group reveal [_x, 4]; // 4 = TARGET (sait exactement où il est)
            };
        } forEach _nearEnemies;
        
        sleep 5;
    }; 
    
    if (!alive _heli) exitWith {};

    // --- PHASE 3: DÉPART ---
    
    // Nettoyer les waypoints
    while {(count (waypoints _group)) > 0} do {
        deleteWaypoint [_group, 0];
    };
    
    // Remonter
    _heli flyInHeight 150;
    _heli flyInHeightASL [150, 150, 150];
    
    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    
    _heli doMove _homeBase;

    // --- NETTOYAGE ---
    waitUntil {
        sleep 5;
        (_heli distance2D _targetPos > 2000) || !alive _heli
    };

    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
};
