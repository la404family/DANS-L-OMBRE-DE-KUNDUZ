/*
    fn_livraison_vehicule.sqf
    EXPERT SQF arma3 -- code optimisé pour jeux multijoueurs et solo
    
    Exécution: [getPos player] remoteExec ["Mission_fnc_livraison_vehicule", 2];
    
    Version optimisée - Résout les problèmes de:
    - Précision de positionnement
    - Non-largage du véhicule
    - Véhicule traîné au sol
*/

if (!isServer) exitWith {};

params [["_targetPos", [0,0,0], [[]]]];

if (_targetPos isEqualTo [0,0,0] || {count _targetPos < 2}) exitWith {
    // diag_log "[LIVRAISON] Erreur: Position invalide";
};

// Assurer que la position a 3 éléments
if (count _targetPos < 3) then { _targetPos set [2, 0]; };

// --- CONFIGURATION ---
private _spawnDist = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F"; // Caracal
private _vehClass = "amf_pvp_01_top_TDF_f";
private _flyHeight = 150;
private _hoverHeight = 10; // Hauteur de hover pour largage (assez haut pour stabilité IA)

// Calcul du point de départ (direction aléatoire depuis la cible)
private _dir = random 360;
private _spawnPos = _targetPos getPos [_spawnDist, _dir];
_spawnPos set [2, _flyHeight];

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
        // diag_log format ["[LIVRAISON] Echec spawn hélico tentative %1", _spawnAttempts];
        sleep 1;
    };
};

if (isNull _heli) exitWith {
    // diag_log "[LIVRAISON] CRITIQUE: Impossible de faire spawner l'hélicoptère après 5 essais";
};

// Créer l'équipage
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

// Configuration IA - CARELESS (ignore le danger, continue la route) + RED (engage l'ennemi)
_group setBehaviour "CARELESS";
_group setCombatMode "RED";
_group setSpeedMode "FULL";

// L'équipage peut combattre mais reste invulnérable et continue sa mission
{
    _x disableAI "FSM";        // Désactive les comportements complexes (pas de fuite)
    _x allowDamage false;      // Invulnérable pour garantir la livraison
    // NE PAS utiliser setCaptive - l'ennemi doit pouvoir les cibler
    // NE PAS désactiver AUTOCOMBAT - ils doivent riposter
} forEach _crew;

// 2. VÉHICULE & SLING LOAD
private _cargo = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -15]);
_cargo allowDamage false;
private _originalMass = getMass _cargo;
_cargo setMass 800; // Allègement pour transport
_heli setSlingLoad _cargo;

// Message radio global
// (localize "STR_LIVRAISON_INBOUND") remoteExec ["systemChat", 0];

// diag_log format ["[LIVRAISON] Hélicoptère créé en %1, direction cible %2", _spawnPos, _targetPos];

// 3. BOUCLE DE GESTION
[_heli, _cargo, _targetPos, _group, _crew, _spawnPos, _originalMass, _hoverHeight] spawn {
    params ["_heli", "_cargo", "_targetPos", "_group", "_crew", "_homeBase", "_originalMass", "_hoverHeight"];

    // --- RECHERCHE DU POINT DE LARGAGE ---
    private _dropPos = +_targetPos;
    private _closestWp = objNull;
    private _minDist = 999999;

    // Chercher le waypoint de livraison le plus proche (000 à 127)
    for "_i" from 0 to 127 do {
        private _suffix = if (_i < 10) then { format ["00%1", _i] } else { if (_i < 100) then { format ["0%1", _i] } else { str _i } };
        private _wp = missionNamespace getVariable [format ["waypoint_livraison_%1", _suffix], objNull];

        if (!isNull _wp) then {
            private _dist = _wp distance2D _targetPos;
            if (_dist < _minDist) then {
                _minDist = _dist;
                _closestWp = _wp;
            };
        };
    };

    // Utiliser le waypoint trouvé ou fallback sur position cible
    if (!isNull _closestWp) then {
        _dropPos = getPos _closestWp;
        if (count _dropPos < 3) then { _dropPos set [2, 0]; };
        // diag_log format ["[LIVRAISON] Waypoint SÉCURISÉ trouvé: %1 à %2m", _closestWp, _minDist];
    } else {
        // diag_log "[LIVRAISON] AVERTISSEMENT: Aucun waypoint_livraison trouvé, utilisation position cible";
        
        // Vérification terrain plat (uniquement si pas de waypoint)
        if (count _dropPos >= 2) then {
            private _flatCheck = _dropPos isFlatEmpty [5, -1, 0.2, 5, 0, false, objNull];
            if (_flatCheck isEqualTo []) then {
                private _safePos = [_dropPos, 0, 150, 5, 0, 0.2, 0, [], _dropPos] call BIS_fnc_findSafePos;
                if (_safePos isEqualType [] && {count _safePos >= 2}) then {
                    if (_safePos distance2D _dropPos < 500) then {
                        _dropPos = _safePos;
                        if (count _dropPos < 3) then { _dropPos set [2, 0]; };
                        // diag_log format ["[LIVRAISON] Position ajustée: %1", _dropPos];
                    };
                };
            };
        };
    };

    // --- MARKER SUR CARTE ---
    private _markerName = format ["livraison_mrk_%1", floor(random 10000)];
    private _marker = createMarker [_markerName, _dropPos];
    _marker setMarkerType "mil_pickup";
    _marker setMarkerColor "ColorBlue";
    _marker setMarkerText (localize "STR_LIVRAISON_MARKER_TEXT");

    // Suppression automatique du marker après 2 minutes
    [_marker] spawn {
        params ["_m"];
        sleep 120;
        deleteMarker _m;
    };

    // --- PHASE 1: APPROCHE ---
    private _wp1 = _group addWaypoint [_dropPos, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointSpeed "FULL";
    _heli doMove _dropPos;

    // diag_log "[LIVRAISON] Phase 1: Approche en cours";

    // Attendre approche (< 200m ou timeout 180s)
    private _approachTimeout = 0;
    waitUntil {
        sleep 1;
        _approachTimeout = _approachTimeout + 1;
        ((_heli distance2D _dropPos) < 200) || _approachTimeout > 180 || !alive _heli
    };

    if (!alive _heli) exitWith {
        // diag_log "[LIVRAISON] Hélicoptère détruit pendant l'approche";
    };

    // --- PHASE 2: DESCENTE ET HOVER ---
    // diag_log "[LIVRAISON] Phase 2: Descente pour largage";
    
    deleteWaypoint _wp1;
    
    // Forcer descente progressive
    _heli flyInHeight _hoverHeight;
    _heli flyInHeightASL [_hoverHeight, _hoverHeight, _hoverHeight];
    
    // Nouveau waypoint précis
    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";
    _wp2 setWaypointSpeed "FULL";
    
    _heli doMove _dropPos;

    // Attendre que l'hélico soit proche horizontalement (< 3m) ou timeout
    private _positionTimeout = 0;
    waitUntil {
        sleep 0.5;
        _positionTimeout = _positionTimeout + 0.5;
        ((_heli distance2D _dropPos) < 3) || _positionTimeout > 30 || !alive _heli
    };

    if (!alive _heli) exitWith {
        // diag_log "[LIVRAISON] Hélicoptère détruit pendant le positionnement";
    };

    // Arrêt stationnaire
    doStop _heli;
    _heli flyInHeight _hoverHeight;

    // diag_log format ["[LIVRAISON] Hover à %1m, distance horizontale: %2m", _hoverHeight, _heli distance2D _dropPos];

    // --- PHASE 3: ATTENTE CONTACT SOL DU VÉHICULE ---
    // diag_log "[LIVRAISON] Phase 3: Attente contact sol du véhicule";
    
    private _dropTimeout = 0;
    private _cargoGrounded = false;
    
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.5;
        
        // Descente progressive: -1m toutes les 0.5s, minimum 3m du sol
        private _newHeight = _hoverHeight - _dropTimeout;
        if (_newHeight < 5) then { _newHeight = 5; };
        _heli flyInHeight _newHeight;
        _heli flyInHeightASL [_newHeight, _newHeight, _newHeight];
        
        // Le véhicule est au sol si son altitude ATL < 3m
        _cargoGrounded = (getPosATL _cargo select 2) < 3;
        // si l'hélico est à moins de 4 metre du sol on passe à la phase 4
        //Si vous vouliez vérifier la hauteur, il faudrait utiliser (getPosATL _heli select 2) < 3
        if ((getPosATL _heli select 2) < 4) then {
            _cargoGrounded = true;
        };
        _cargoGrounded || _dropTimeout > 30 || !alive _heli || !alive _cargo
    };

    if (!alive _heli || !alive _cargo) exitWith {
        // diag_log "[LIVRAISON] Hélicoptère ou véhicule détruit pendant le largage";
       
    };

    // --- PHASE 4: LARGAGE FORCÉ ---
    // diag_log "[LIVRAISON] Phase 4: Largage forcé";
    
    
    private _dropTime = time;
      sleep 1;
    // 1. DÉTRUIRE TOUS LES CÂBLES
    private _allRopes = ropes _heli;
    {
        ropeDestroy _x;
    } forEach _allRopes;
    
    // 2. DÉTACHER LE SLING LOAD
    _heli setSlingLoad objNull;
    
    // 3. PAUSE COURTE POUR LAISSER LA PHYSIQUE SE STABILISER
    sleep 1;
    
    _cargo setVelocity [0, 0, 0];
    _cargo setVectorUp [0, 0, 1];
    
    // 5. RESTAURER LES PROPRIÉTÉS DU VÉHICULE
    _cargo setMass _originalMass;
    _cargo allowDamage true;
    
    // Message global
    // (localize "STR_LIVRAISON_DROPPED") remoteExec ["systemChat", 0];
    // diag_log format ["[LIVRAISON] Véhicule largué en %1", _dropPos];

    // --- PHASE 5: DÉPART ---
    // diag_log "[LIVRAISON] Phase 5: Retour à la base";
    
    sleep 1;
    
    // Nettoyer les waypoints
    while {(count (waypoints _group)) > 0} do {
        deleteWaypoint [_group, 0];
    };
    
    // Remonter
    _heli flyInHeight 150;
    
    // Waypoint de retour
    private _wpHome = _group addWaypoint [_homeBase, 0];
    _wpHome setWaypointType "MOVE";
    _wpHome setWaypointBehaviour "CARELESS";
    _wpHome setWaypointSpeed "FULL";
    
    _heli doMove _homeBase;

    // --- NETTOYAGE ---
    waitUntil {
        sleep 5;
        (_heli distance2D _targetPos > 1500) || !alive _heli || (time - _dropTime > 180)
    };

    // Suppression propre
    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;

    // diag_log "[LIVRAISON] Hélicoptère et équipage supprimés - Mission terminée";
};