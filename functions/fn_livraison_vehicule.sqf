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
private _spawnPos = _targetPos getPos [_spawnDist, _dir];
_spawnPos set [2, _flyHeight];

// 1. SPAWN HÉLICOPTÈRE - directement en vol
private _heli = createVehicle [_helicoClass, _spawnPos, [], 0, "FLY"];
_heli setPos _spawnPos;
_heli setDir (_dir + 180);
_heli flyInHeight _flyHeight;
_heli allowDamage false;

// Créer l'équipage
private _group = createGroup [WEST, true];
private _crew = [];

// Pilote
private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_pilot moveInDriver _heli;
_crew pushBack _pilot;

// Co-pilote
private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
_copilot moveInTurret [_heli, [0]];
_crew pushBack _copilot;

// Configuration IA - Comportement logistique
_group setBehaviour "CARELESS";
_group setCombatMode "BLUE";
_group setSpeedMode "FULL";

// Désactiver complètement le combat et rendre INDESTRUCTIBLE
{
    _x disableAI "AUTOCOMBAT";
    _x disableAI "AUTOTARGET";
    _x disableAI "TARGET";
    _x disableAI "FSM";
    _x setCaptive true;
    _x allowDamage false; // Équipage indestructible (permanent)
} forEach _crew;

// 2. VÉHICULE & SLING LOAD
private _cargo = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -10]);
_cargo allowDamage false; // Véhicule indestructible pendant transport
private _originalMass = getMass _cargo;
_cargo setMass 1000; // Allègement pour transport
_heli setSlingLoad _cargo;

// Message radio global
(localize "STR_LIVRAISON_INBOUND") remoteExec ["systemChat", 0];

diag_log format ["[LIVRAISON] Hélicoptère créé en %1, direction cible %2", _spawnPos, _targetPos];

// 3. BOUCLE DE GESTION
[_heli, _cargo, _targetPos, _group, _crew, _spawnPos, _originalMass] spawn {
    params ["_heli", "_cargo", "_targetPos", "_group", "_crew", "_homeBase", "_originalMass"];

    // Trouver point de largage sur waypoint_invisible (routes sécurisées) ou fallback
    private _dropPos = _targetPos;
    private _closestWp = objNull;
    private _minDist = 999999;

    // Chercher manuellement le waypoint le plus proche
    for "_i" from 0 to 340 do {
        private _suffix = "";
        if (_i < 10) then { _suffix = format ["00%1", _i] }
        else { if (_i < 100) then { _suffix = format ["0%1", _i] } else { _suffix = str _i } };

        private _wp = missionNamespace getVariable [format ["waypoint_invisible_%1", _suffix], objNull];

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
        diag_log format ["[LIVRAISON] Waypoint trouvé: %1 à %2m", _closestWp, _minDist];
    } else {
        diag_log "[LIVRAISON] AVERTISSEMENT: Aucun waypoint trouvé (Fallback position cible)";
    };

    // Vérifier si la position est plate et sans encombre, sinon trouver une meilleure
    if (!(_dropPos isEqualType [] && {count _dropPos >= 2})) then {
        _dropPos = +_targetPos;
    };
    if ((count _dropPos) < 3) then { _dropPos set [2, 0]; };

    if ((_dropPos isFlatEmpty [5, -1, 0.1, 5, 0, false, objNull]) isEqualTo []) then {
        private _safePos = [_dropPos, 0, 200, 5, 0, 0.1, 0, [], _dropPos] call BIS_fnc_findSafePos;
        if (_safePos isEqualType [] && {count _safePos >= 2}) then {
            if ((count _safePos) < 3) then { _safePos set [2, 0]; };
            if (_safePos distance2D _dropPos < 200) then {
                _dropPos = _safePos;
                diag_log format ["[LIVRAISON] Position ajustée pour zone plate et claire: %1", _dropPos];
            } else {
                diag_log "[LIVRAISON] Impossible de trouver une position plate et claire proche";
            };
        } else {
            diag_log "[LIVRAISON] BIS_fnc_findSafePos a échoué (position invalide)";
        };
    };

    // Créer un waypoint pour forcer le mouvement
    private _wp1 = _group addWaypoint [_dropPos, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointSpeed "FULL";

    _heli doMove _dropPos;

    // -- Phase d'approche --
    waitUntil { sleep 1; (_heli distance2D _dropPos) < 300 || !alive _heli };

    if (!alive _heli) exitWith {
        diag_log "[LIVRAISON] Hélicoptère détruit pendant l'approche";
    };

    // Supprimer le waypoint précédent
    deleteWaypoint _wp1;

    // FORCER la descente avec plusieurs méthodes
    _heli flyInHeight 15;
    _heli flyInHeightASL [15, 15, 15];

    // Nouveau waypoint à basse altitude
    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";

    _heli doMove _dropPos;

    diag_log "[LIVRAISON] Début descente pour largage";

    // Attente position précise
    private _timeout = 0;
    waitUntil {
        sleep 0.5;
        _timeout = _timeout + 0.5;
        ((_heli distance2D _dropPos) < 100) || _timeout > 60 || !alive _heli
    };

    if (!alive _heli) exitWith {
        diag_log "[LIVRAISON] Hélicoptère détruit pendant la descente";
    };

    // Arrêt stationnaire forcé
    doStop _heli;
    _heli flyInHeight 5;

    // Attendre que l'hélico soit assez bas ou timeout
    private _dropTimeout = 0;
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.5;
        ((getPos _heli select 2) < 10) || _dropTimeout > 15
    };

    sleep 2; // Stabilisation

    // -- Largage --
    private _dropTime = -1;
    if (alive _heli && alive _cargo) then {
        _heli setSlingLoad objNull;
        detach _cargo;
        _cargo setVelocity [0,0,0];

        // Attente sol (Timeout 5s) pour éviter blocage si toit/arbre
        private _groundTimer = 0;
        waitUntil {
            sleep 0.1;
            _groundTimer = _groundTimer + 0.1;
            (getPosATL _cargo select 2) < 1 || _groundTimer > 5
        };

        _cargo setMass _originalMass;
        _cargo allowDamage true; // Véhicule devient DESTRUCTIBLE après largage

        (localize "STR_LIVRAISON_DROPPED") remoteExec ["systemChat", 0];
        diag_log format ["[LIVRAISON] Véhicule largué en %1 - Véhicule maintenant destructible", _dropPos];
        _dropTime = time;
    };

    sleep 3;

    // -- Retour base (hélico reste INDESTRUCTIBLE) --
    deleteWaypoint [_group, 0];

    _heli flyInHeight 150;

    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";

    _heli doMove _homeBase;

    // -- Nettoyage --
    waitUntil {
        sleep 5;
        (_heli distance2D _targetPos > 1500) ||
        !alive _heli ||
        (_dropTime > 0 && {time - _dropTime > 150})
    };

    // Suppression propre
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;

    diag_log "[LIVRAISON] Hélicoptère et équipage supprimés";
};