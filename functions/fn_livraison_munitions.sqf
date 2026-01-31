/*
    fn_livraison_munitions.sqf
    EXPERT SQF arma3 -- code optimisé pour jeux multijoueurs et solo
    
    Exécution: [getPos player] remoteExec ["Mission_fnc_livraison_munitions", 2];
    
    Version optimisée - Basée sur fn_livraison_vehicule.sqf
*/

if (!isServer) exitWith {};

params [["_targetPos", [0,0,0], [[]]]];

// Assurer que la position a 3 éléments
if (count _targetPos < 3) then { _targetPos set [2, 0]; };

// --- COOLDOWN (20 Minutes) ---
// Variable globale : MISSION_LastUse_Ammo
private _lastUse = missionNamespace getVariable ["MISSION_LastUse_Ammo", -9999];
private _cooldownTime = 1200; // 20 minutes

if (time < _lastUse + _cooldownTime) exitWith {
     private _remaining = ceil ((_lastUse + _cooldownTime - time) / 60);
};

// Mise à jour du temps d'utilisation
missionNamespace setVariable ["MISSION_LastUse_Ammo", time, true];

// --- CONFIGURATION ---
private _spawnDist = 2000;
private _helicoClass = "B_AMF_Heli_Transport_01_F"; // Caracal (Même que véhicule)
private _vehClass = "B_supplyCrate_F"; // Caisse de munitions OTAN
private _flyHeight = 150;
private _hoverHeight = 10; // Hauteur de hover pour largage

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
        // diag_log format ["[MUNITIONS] Echec spawn hélico tentative %1", _spawnAttempts];
        sleep 1;
    };
};

if (isNull _heli) exitWith {
    // diag_log "[MUNITIONS] CRITIQUE: Impossible de faire spawner l'hélicoptère après 5 essais";
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
_group setBehaviour "CARELESS";
_group setCombatMode "RED";
_group setSpeedMode "FULL";

// L'équipage peut combattre mais reste invulnérable
{
    _x disableAI "FSM";        
    _x allowDamage false;      
} forEach _crew;

// 2. VÉHICULE (CAISSE) & SLING LOAD
private _cargo = createVehicle [_vehClass, [0,0,0], [], 0, "NONE"];
_cargo setPos (_heli modelToWorld [0, 0, -15]);
_cargo allowDamage false;
private _originalMass = getMass _cargo;
_cargo setMass 500; // Allègement pour transport
_heli setSlingLoad _cargo;

// --- REMPLISSAGE DYNAMIQUE DE LA CAISSE ---
clearWeaponCargoGlobal _cargo;
clearMagazineCargoGlobal _cargo;
clearItemCargoGlobal _cargo;
clearBackpackCargoGlobal _cargo;

private _allWeapons = [];
private _allMagazines = [];
private _allItems = [];
private _allBackpacks = [];

// Analyser tous les BLUFOR
{
    if (side _x == west) then {
        // Armes (Primaire, Secondaire, Poing)
        if (primaryWeapon _x != "") then { _allWeapons pushBackUnique (primaryWeapon _x); };
        if (secondaryWeapon _x != "") then { _allWeapons pushBackUnique (secondaryWeapon _x); };
        if (handgunWeapon _x != "") then { _allWeapons pushBackUnique (handgunWeapon _x); };
        
        // Chargeurs
        { _allMagazines pushBackUnique _x; } forEach (magazines _x);
        
        // Objets (Inventaire complet - Armes/Chargeurs déjà traités)
        // On utilise items + assignedItems pour tout couvrir (Jumelles, GPS, NVG, Bandages...)
        { _allItems pushBackUnique _x; } forEach (items _x);
        { _allItems pushBackUnique _x; } forEach (assignedItems _x);
        
        // Sac à dos
        if (backpack _x != "") then { _allBackpacks pushBackUnique (backpack _x); };
        // Veste/Casque aussi ? (Le user a dit "équipement en mains et dans les sacs", on inclut armes/chargeurs/items/sacs)
    };
} forEach allUnits;

// Remplir la caisse
{ _cargo addWeaponCargoGlobal [_x, 2]; } forEach _allWeapons;
{ _cargo addMagazineCargoGlobal [_x, 30]; } forEach _allMagazines;
{ _cargo addItemCargoGlobal [_x, 10]; } forEach _allItems;
{ _cargo addBackpackCargoGlobal [_x, 2]; } forEach _allBackpacks;

// Ajout spécifique fumigènes pour signalisation (toujours utile)
_cargo addMagazineCargoGlobal ["SmokeShell", 10];
_cargo addMagazineCargoGlobal ["SmokeShellGreen", 10];
// -------------------------------------------

// Audio de confirmation (Random + Pitch accéléré)
// Audio de confirmation (Random + Pitch accéléré)
// Audio de confirmation (Random + Pitch accéléré)
// Audio de confirmation (Radio In -> Voice -> Radio Out)
[] spawn {
    "Radio_In" remoteExec ["playSound", 0];
    sleep 0.2;
    private _snd = selectRandom ["livraison01", "livraison02", "livraison03", "livraison04", "livraison05", "livraison06", "livraison07", "livraison08", "livraison09"];
    _snd remoteExec ["playSound", 0];
    sleep 2.5; // Temps moyen pour la phrase
    "Radio_Out" remoteExec ["playSound", 0];
};

// Message radio global
// (localize "STR_LIVRAISON_AMMO_INBOUND") remoteExec ["systemChat", 0];

// 3. BOUCLE DE GESTION
[_heli, _cargo, _targetPos, _group, _crew, _spawnPos, _originalMass, _hoverHeight] spawn {
    params ["_heli", "_cargo", "_targetPos", "_group", "_crew", "_homeBase", "_originalMass", "_hoverHeight"];

    // --- RECHERCHE DU POINT DE LARGAGE ---
    private _dropPos = +_targetPos;
    private _closestWp = objNull;
    private _minDist = 999999;

    // Chercher le waypoint de livraison le plus proche
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

    // Utiliser le waypoint trouvé ou fallback
    if (!isNull _closestWp) then {
        _dropPos = getPos _closestWp;
        if (count _dropPos < 3) then { _dropPos set [2, 0]; };
    } else {
        if (count _dropPos >= 2) then {
            private _flatCheck = _dropPos isFlatEmpty [5, -1, 0.2, 5, 0, false, objNull];
            if (_flatCheck isEqualTo []) then {
                private _safePos = [_dropPos, 0, 150, 5, 0, 0.2, 0, [], _dropPos] call BIS_fnc_findSafePos;
                if (_safePos isEqualType [] && {count _safePos >= 2}) then {
                    if (_safePos distance2D _dropPos < 500) then {
                        _dropPos = _safePos;
                        if (count _dropPos < 3) then { _dropPos set [2, 0]; };
                    };
                };
            };
        };
    };

    // --- MARKER SUR CARTE ---
    private _markerName = format ["livraison_mrk_ammo_%1", floor(random 10000)];
    private _marker = createMarker [_markerName, _dropPos];
    _marker setMarkerType "mil_pickup";
    _marker setMarkerColor "ColorBlue";
    _marker setMarkerText (localize "STR_LIVRAISON_AMMO_MARKER");

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

    // Attendre approche
    private _approachTimeout = 0;
    waitUntil {
        sleep 1;
        _approachTimeout = _approachTimeout + 1;
        ((_heli distance2D _dropPos) < 200) || _approachTimeout > 180 || !alive _heli
    };

    if (!alive _heli) exitWith {};

    // --- PHASE 2: DESCENTE ET HOVER ---
    deleteWaypoint _wp1;
    
    _heli flyInHeight _hoverHeight;
    _heli flyInHeightASL [_hoverHeight, _hoverHeight, _hoverHeight];
    
    private _wp2 = _group addWaypoint [_dropPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";
    _wp2 setWaypointSpeed "FULL";
    
    _heli doMove _dropPos;

    private _positionTimeout = 0;
    waitUntil {
        sleep 0.5;
        _positionTimeout = _positionTimeout + 0.5;
        ((_heli distance2D _dropPos) < 3) || _positionTimeout > 30 || !alive _heli
    };

    if (!alive _heli) exitWith {};

    // Arrêt stationnaire
    doStop _heli;
    _heli flyInHeight _hoverHeight;

    // --- PHASE 3: ATTENTE CONTACT SOL DU VÉHICULE ---
    private _dropTimeout = 0;
    private _cargoGrounded = false;
    
    waitUntil {
        sleep 0.5;
        _dropTimeout = _dropTimeout + 0.5;
        
        private _newHeight = _hoverHeight - _dropTimeout;
        if (_newHeight < 5) then { _newHeight = 5; };
        _heli flyInHeight _newHeight;
        _heli flyInHeightASL [_newHeight, _newHeight, _newHeight];
        
        _cargoGrounded = (getPosATL _cargo select 2) < 3;
        if ((getPosATL _heli select 2) < 4) then {
            _cargoGrounded = true;
        };
        _cargoGrounded || _dropTimeout > 30 || !alive _heli || !alive _cargo
    };

    if (!alive _heli || !alive _cargo) exitWith {};

    // --- PHASE 4: LARGAGE FORCÉ ---
    private _dropTime = time;
    sleep 1;
    
    private _allRopes = ropes _heli;
    {
        ropeDestroy _x;
    } forEach _allRopes;
    
    _heli setSlingLoad objNull;
    
    sleep 1;
    
    _cargo setVelocity [0, 0, 0];
    _cargo setVectorUp [0, 0, 1];
    
    // 5. RESTAURER LES PROPRIÉTÉS
    _cargo setMass _originalMass;
    _cargo allowDamage true;
    
    // Message global
    // (localize "STR_LIVRAISON_AMMO_DROPPED") remoteExec ["systemChat", 0];

    // -------------------------------------------------------------
    // LOGIQUE SPÉCIFIQUE MUNITIONS : GESTION DISPARITION (5 MIN)
    // -------------------------------------------------------------
    [_cargo] spawn {
        params ["_crate"];
        sleep 300; // 5 minutes
        if (!alive _crate) exitWith {}; 
        
        // Ecran de fumée
        for "_i" from 0 to 360 step 20 do {
            private _smokePos = _crate getPos [1, _i];
            createVehicle ["SmokeShell", _smokePos, [], 0, "CAN_COLLIDE"];
        };
        
        sleep 7;
        deleteVehicle _crate;
    };
    // -------------------------------------------------------------

    // --- PHASE 5: DÉPART ---
    sleep 1;
    
    while {(count (waypoints _group)) > 0} do {
        deleteWaypoint [_group, 0];
    };
    
    _heli flyInHeight 150;
    
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

    { deleteVehicle _x } forEach _crew;
    deleteVehicle _heli;
    deleteGroup _group;
};
