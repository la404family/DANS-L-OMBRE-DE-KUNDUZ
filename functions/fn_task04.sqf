 

if (!isServer) exitWith {};

 
 
 

MISSION_TASK04_Debug = true;  

MISSION_fnc_logTask04 = {
    params ["_msg"];
    diag_log format ["[TASK04] %1", _msg];
    if (MISSION_TASK04_Debug) then { systemChat format ["[TASK04] %1", _msg]; };
};

 
sleep 2;
["Initialisation..."] call MISSION_fnc_logTask04;

 
 
 

MISSION_fnc_task04_createMilitia = {
    params ["_pos", "_isChief"];
    
    private _grp = createGroup [independent, true];
    private _unitType = if (_isChief) then { "I_G_officer_F" } else { "I_G_Soldier_F" };
    private _unit = _grp createUnit [_unitType, _pos, [], 0, "NONE"];
    
    // Positionnement SAFE
    private _terrainZ = getTerrainHeightASL _pos;
    private _safePos = [_pos select 0, _pos select 1, _terrainZ + 0.7];
    _unit setPosASL _safePos;
    
    // Invulnérabilité temporaire
    _unit allowDamage false;
    [_unit] spawn { sleep 3; _this select 0 allowDamage true; };

    // 1. Apparence Civile
    if (!isNil "MISSION_fnc_applyCivilianTemplate") then {
        [_unit] call MISSION_fnc_applyCivilianTemplate;
    };
    
    // 2. Equipement Spécifique (après template)
    removeAllWeapons _unit;
    // removeAllItems _unit; // On garde les items du template (map, etc) ? Le template nettoie souvent déjà.
    
    // Sac à dos
    _unit addBackpack "B_Messenger_Coyote_F";
    
    // Arme et Accessoire
    _unit addWeapon "uk3cb_ak47";
    _unit addPrimaryWeaponItem "rhs_acc_2dpZenit";
    
    // Munitions
    // 1 chargeur engagé (ajouté automatiquement avec addWeapon si compatible, mais on force pour être sûr)
    _unit addPrimaryWeaponItem "rhs_30Rnd_762x39mm_bakelite";
    
    // 3 chargeurs dans le sac
    for "_i" from 1 to 3 do { _unit addItemToBackpack "rhs_30Rnd_762x39mm_bakelite"; };
    
    // Arme de poing pour le chef ? Le request dit : "Arme : uk3cb_ak47..." pour apparence/équipement. Je suppose pour tout le monde. 
    // Mais gardons la logique chef/soldat si besoin différent ? Le request dit "Apparence... Équipement spécifique...".
    // Il ne distingue pas Chef vs Soldat pour ces items. Donc on applique à tous.
    
    _unit setBehaviour "SAFE";
    
    _unit
};

 
 
 

// Nouvelle fonction : CHANGE de camp sans respawn (garde équipement/visage)
MISSION_fnc_task04_changeSide = {
    params ["_unit", "_newSide"];
    if (!alive _unit) exitWith { _unit };
    
    // Créer un groupe temporaire du nouveau camp
    private _newGrp = createGroup [_newSide, true];
    
    // Faire rejoindre l'unité au nouveau groupe
    [_unit] joinSilent _newGrp;
    
    // Activer le combat
    _unit setBehaviour "COMBAT";
    _unit setCombatMode "RED";
    
    // On retourne l'unité (c'est toujours le même objet)
    _unit
};

// Fonction Client pour ajouter l'action localement (plus fiable via remoteExec)
MISSION_fnc_task04_addLocalAction = {
    params ["_chief", "_guards", "_markerName"];
    
    // Sécurité: Client seulement
    if (!hasInterface) exitWith {};

    // SystemChat pour confirmer que le code s'exécute chez le client (Debug)
    // systemChat "[Task04] Interaction disponible avec le chef.";

    _chief addAction [
        "<t color='#FFFF00'>Parler au Chef</t>", 
        {
            params ["_target", "_caller", "_id", "_args"];
            _args params ["_guards", "_markerName"];
            
            // Anti-spam global
            if (missionNamespace getVariable ["MISSION_Task04_ScenarioTriggered", false]) exitWith {};
            missionNamespace setVariable ["MISSION_Task04_ScenarioTriggered", true, true];
            
            _target removeAction _id;
            
            private _scen = 1 + floor(random 3);
            
            // Lancer le scénario sur le serveur
            [_scen, _target, _guards, _markerName] remoteExec ["MISSION_fnc_task04_runScenario", 2];
        },
        [_guards, _markerName],
        10, // Priorité MAX
        true,
        true,
        "",
        "alive _target && _this distance _target < 5",
        5
    ];
};

 
 
 

 
[] spawn {
    
     
    private _all_locs = [];
    for "_i" from 0 to 340 do {
        private _name = format ["waypoint_invisible_%1", _i];
        if (_i < 10) then { _name = format ["waypoint_invisible_00%1", _i]; };
        if (_i >= 10 && _i < 100) then { _name = format ["waypoint_invisible_0%1", _i]; };
        
        private _obj = missionNamespace getVariable [_name, objNull];
        if (!isNull _obj) then { _all_locs pushBack _obj; };
    };

    if (count _all_locs == 0) exitWith { ["ERREUR: Pas de waypoints_invisible!"] call MISSION_fnc_logTask04; };
    
    private _locationObj = selectRandom _all_locs;
    private _missionPos = getPos _locationObj;
    
    ["Position sélectionnée: " + str(_missionPos)] call MISSION_fnc_logTask04;

     
    
     
    private _chief = [_missionPos, true] call MISSION_fnc_task04_createMilitia;
    
     
     
     
    _chief disableAI "MOVE";
    _chief disableAI "ANIM";  
    _chief setUnitPos "UP";
    _chief switchMove "Acts_CivilTalking_1"; 
     
     
     
     
    _chief addEventHandler ["AnimDone", {
        params ["_unit", "_anim"];
        if (alive _unit && (_unit getVariable ["MISSION_Task04_Status", "WAIT"] == "WAIT")) then {
            _unit switchMove "Acts_CivilTalking_1";
        };
    }];
    _chief setVariable ["MISSION_Task04_Status", "WAIT", true];
    
     
    private _guards = [];
    private _numGuards = 2 + floor(random 3);
    for "_i" from 1 to _numGuards do {
        private _gPos = _missionPos getPos [5 + random 15, random 360];
        private _guard = [_gPos, false] call MISSION_fnc_task04_createMilitia;
        _guards pushBack _guard;
        
         
        [_guard, _missionPos] spawn {
            params ["_unit", "_center"];
            _unit setSpeedMode "LIMITED";
            while {alive _unit && behaviour _unit != "COMBAT"} do {
                if (behaviour _unit == "COMBAT") exitWith {};
                private _dst = _center getPos [5 + random 20, random 360];
                _unit doMove _dst;
                waitUntil {sleep 1; (!alive _unit) || (_unit distance2D _dst < 2) || (unitReady _unit) || behaviour _unit == "COMBAT"};
                sleep (15 + random 25);
            };
        };
    };

     
    private _markerName = "mrk_task04_target";
    deleteMarker _markerName;
    createMarker [_markerName, _missionPos];
    _markerName setMarkerType "mil_warning";
    _markerName setMarkerColor "ColorOrange";
    _markerName setMarkerText (localize "STR_TASK04_MARKER");

    [true, "Task04", ["$STR_TASK04_DESC", "$STR_TASK04_TITLE", "$STR_TASK04_MARKER"], _locationObj, "ASSIGNED", 1, true, "meet", true] call BIS_fnc_taskCreate;

     
    missionNamespace setVariable ["MISSION_Task04_ScenarioTriggered", false, true];
    
     
    MISSION_fnc_task04_runScenario = {
        params ["_scenario", "_officer", "_guards", "_markerName"];
        
        _officer setVariable ["MISSION_Task04_Status", "ACTION", true];
        _officer enableAI "ANIM";  
        _officer enableAI "MOVE";  
        _officer switchMove "";    
        
        switch (_scenario) do {
            case 1: { // SUCCES STANDARD
                ["Scenario 1: Succès"] call MISSION_fnc_logTask04;
                _officer globalChat (localize "STR_TASK04_WIN");
                
                // Révélation des mines
                for "_i" from 0 to 50 do {
                    private _m = format ["mine_%1", _i];
                    if (getMarkerColor _m != "") then {
                        private _rev = createMarker [format ["rev_%1", _i], getMarkerPos _m];
                        _rev setMarkerType "hd_deny"; _rev setMarkerColor "ColorRed"; _rev setMarkerText "DANGER";
                    };
                };
                
                ["Task04", "SUCCEEDED"] call BIS_fnc_taskSetState;
                deleteMarker _markerName;
            };
            case 2: { // TRAHISON DIRECTE
                ["Scenario 2: Trahison"] call MISSION_fnc_logTask04;
                _officer globalChat (localize "STR_TASK04_TREASON");
                deleteMarker _markerName;
                sleep 1;
                
                // Tout le monde passe OPFOR (EAST) via changement de groupe
                { [_x, east] call MISSION_fnc_task04_changeSide } forEach _guards;
                [_officer, east] call MISSION_fnc_task04_changeSide;
                
                // Attaque
                { _x doFire (allPlayers select 0) } forEach ([_officer] + _guards);
                
                // Victoire si tout le monde meurt
                waitUntil { sleep 5; ({alive _x} count ([_officer] + _guards)) == 0 };
                ["Task04", "SUCCEEDED"] call BIS_fnc_taskSetState;
            };
            case 3: { // MUTINERIE (TRAHISON INTERNE)
                ["Scenario 3: Mutinerie"] call MISSION_fnc_logTask04;
                _officer globalChat (localize "STR_TASK04_MUTINY");
                deleteMarker _markerName;
                
                // Révélation des mines (comme succès)
                for "_i" from 0 to 50 do {
                    private _m = format ["mine_%1", _i];
                    if (getMarkerColor _m != "") then {
                        private _rev = createMarker [format ["rev_%1", _i], getMarkerPos _m];
                        _rev setMarkerType "hd_deny"; _rev setMarkerColor "ColorRed"; _rev setMarkerText "DANGER";
                    };
                };
                
                sleep 1;
                 
                // Chef passe BLUFOR (WEST), Gardes passent OPFOR (EAST)
                [_officer, west] call MISSION_fnc_task04_changeSide;
                { [_x, east] call MISSION_fnc_task04_changeSide } forEach _guards;
                
                // Les gardes attaquent le chef
                { _x doFire _officer } forEach _guards;
                _officer setUnitPos "MIDDLE"; // Se met à couvert un peu
                
                // Condition de fin : Chef mort OU tous gardes morts
                waitUntil { sleep 2; (!alive _officer) || ({alive _x} count _guards == 0) };
                
                if (alive _officer) then { ["Task04", "SUCCEEDED"] call BIS_fnc_taskSetState; }
                else { ["Task04", "FAILED"] call BIS_fnc_taskSetState; };
            };
        };
    };

     
    // Ajout de l'action via la fonction dédiée
    [_chief, _guards, _markerName] remoteExec ["MISSION_fnc_task04_addLocalAction", 0, str(_chief)];  
    
     
    // Surveillance simple : Attente fin mission ou mort anticipée
    waitUntil {
        sleep 5;
        // Si le chef meurt et que le scénario n'est pas déclenché -> FAIL
        if (!alive _chief && !(missionNamespace getVariable ["MISSION_Task04_ScenarioTriggered", false])) exitWith {
             ["CHEF MORT AVANT INTERACTION"] call MISSION_fnc_logTask04;
             ["Task04", "FAILED"] call BIS_fnc_taskSetState;
             deleteMarker _markerName;
             true
        };
        
        // Si la tâche est terminée (Succès/Echec/Annulé)
        (["Task04"] call BIS_fnc_taskState) in ["SUCCEEDED", "FAILED", "CANCELED"]
    };
    
    // Nettoyage final (Garbage Collector locale)
    // Attend que les joueurs soient loin (> 1500m) pour supprimer les unités
    waitUntil {
        sleep 10;
        private _p = allPlayers select { alive _x };
        if (count _p == 0) then { false } else {
            ([_p, _missionPos] call BIS_fnc_nearestPosition) distance2D _missionPos > 1500
        };
    };
    
    { deleteVehicle _x } forEach ([_chief] + _guards);
    // Pas de redémarrage.
};
