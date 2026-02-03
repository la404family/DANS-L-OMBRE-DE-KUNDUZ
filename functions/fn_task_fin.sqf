if (!isServer) exitWith {};
diag_log "[FIN_MISSION] === Démarrage du système de fin de mission ===";
private _delayBeforeMessage = 2100 + floor(random 700); 
private _heliClass = "amf_nh90_tth_transport"; 
private _flyTime = 100;  
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
    // --- Création Hélicoptère et Équipage ---
    private _heli = createVehicle [_heliClass, _heliSpawnPos, [], 0, "FLY"];
    _heli setPos _heliSpawnPos;
    _heli setDir (_heliSpawnPos getDir _landingPos);
    _heli flyInHeight 100;
    _heli setFuel 1;
    _heli allowDamage false;
    
    // Création groupe et équipage BLUFOR
    private _group = createGroup [west, true];
    
    // Pilote
    private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
    _pilot moveInDriver _heli;
    
    // Copilote
    private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
    _copilot moveInTurret [_heli, [0]];
    
    // Mitrailleurs (tourelles disponibles sauf copilote [0])
    private _turrets = allTurrets _heli select { _x isNotEqualTo [0] };
    {
        private _gunner = _group createUnit ["B_Soldier_F", [0,0,0], [], 0, "NONE"];
        _gunner moveInTurret [_heli, _x];
    } forEach _turrets;
    
    // Liste équipage complet
    private _crew = crew _heli;
    diag_log format ["[FIN_MISSION] Équipage créé: %1 membres", count _crew];
    
    // Application apparence BLUFOR AMF
    private _targetClass = "B_AMF_UBAS_DA_SUA_HK416";
    private _targetConfig = configFile >> "CfgVehicles" >> _targetClass;
    
    {
        _x setCaptive true;
        _x allowDamage false;
        _x setVariable ["MISSION_TemplateApplied", true, true]; // Protection script civil
        
        // Désactivation complète IA combat - NE TIRE JAMAIS
        _x disableAI "FSM";
        _x disableAI "AUTOTARGET";
        _x disableAI "TARGET";
        _x disableAI "AUTOCOMBAT";
        _x disableAI "SUPPRESSION";
        _x setBehaviour "CARELESS";
        _x setCombatMode "BLUE";
        
        // Application loadout BLUFOR si classe existe
        if (isClass _targetConfig) then {
            private _loadout = getUnitLoadout _targetClass;
            _x setUnitLoadout _loadout;
            // Casque pilote pour le pilote et copilote
            if (_x == _pilot || _x == _copilot) then {
                removeHeadgear _x;
                _x addHeadgear "H_PilotHelmetHeli_B";
            };
        };
    } forEach _crew;
    
    if !(isClass _targetConfig) then {
        diag_log format ["[FIN_MISSION] WARN: Classe %1 introuvable, loadout par défaut conservé", _targetClass];
    };
    
    // Configuration groupe
    _group setBehaviour "CARELESS";
    _group setCombatMode "BLUE";
    _group setSpeedMode "FULL";
    
    // =============================================================================
    // SYSTÈME D'ATTERRISSAGE RÉALISTE - APPROCHE EN 4 PHASES
    // =============================================================================
    
    // Hélipad invisible sur heli_fin - guide l'IA pilote
    private _helipad = createVehicle ["Land_HelipadEmpty_F", _landingPos, [], 0, "CAN_COLLIDE"];
    _helipad setPosATL [_landingPos select 0, _landingPos select 1, 0];
    
    // Direction d'approche (face au vent si possible, sinon direction spawn)
    private _approachDir = _heliSpawnPos getDir _landingPos;
    
    // Point d'approche initiale : 500m avant la LZ, altitude 80m
    private _approachPoint = _landingPos getPos [500, _approachDir + 180];
    _approachPoint set [2, 0];
    
    // Point de stationnaire : directement au-dessus de heli_fin à 30m
    private _hoverPoint = +_landingPos;
    _hoverPoint set [2, 30];
    
    diag_log format ["[FIN_MISSION] LZ: %1 | Approche depuis: %2", _landingPos, _approachPoint];
    
    // -----------------------------------------------------------------------------
    // PHASE 1 : TRANSIT VERS POINT D'APPROCHE (haute altitude, vitesse max)
    // -----------------------------------------------------------------------------
    diag_log "[FIN_MISSION] PHASE 1 - Transit vers point d'approche";
    
    _heli flyInHeight 100;
    _group setSpeedMode "FULL";
    
    private _wp1 = _group addWaypoint [_approachPoint, 0];
    _wp1 setWaypointType "MOVE";
    _wp1 setWaypointBehaviour "CARELESS";
    _wp1 setWaypointSpeed "FULL";
    _wp1 setWaypointCompletionRadius 50;
    
    _heli doMove _approachPoint;
    
    waitUntil {
        sleep 1;
        (_heli distance2D _approachPoint) < 100 || !alive _heli
    };
    if (!alive _heli) exitWith { deleteVehicle _helipad; };
    
    // -----------------------------------------------------------------------------
    // PHASE 2 : APPROCHE FINALE (ralentissement, descente progressive vers LZ)
    // -----------------------------------------------------------------------------
    diag_log "[FIN_MISSION] PHASE 2 - Approche finale vers LZ";
    
    deleteWaypoint _wp1;
    _group setSpeedMode "LIMITED";
    _heli flyInHeight 50;
    _heli limitSpeed 80;
    
    private _wp2 = _group addWaypoint [_landingPos, 0];
    _wp2 setWaypointType "MOVE";
    _wp2 setWaypointBehaviour "CARELESS";
    _wp2 setWaypointSpeed "LIMITED";
    _wp2 setWaypointCompletionRadius 20;
    
    _heli doMove _landingPos;
    
    waitUntil {
        sleep 1;
        (_heli distance2D _landingPos) < 80 || !alive _heli
    };
    if (!alive _heli) exitWith { deleteVehicle _helipad; };
    
    // -----------------------------------------------------------------------------
    // PHASE 3 : STATIONNAIRE AU-DESSUS DE LA LZ (précision horizontale)
    // -----------------------------------------------------------------------------
    diag_log "[FIN_MISSION] PHASE 3 - Positionnement au-dessus de la LZ";
    
    deleteWaypoint _wp2;
    _heli limitSpeed 20;
    _heli flyInHeight 20;
    
    // Waypoint direct sur la LZ
    private _wp3 = _group addWaypoint [_landingPos, 0];
    _wp3 setWaypointType "MOVE";
    _wp3 setWaypointBehaviour "CARELESS";
    _wp3 setWaypointSpeed "LIMITED";
    _wp3 setWaypointCompletionRadius 10;
    
    _heli doMove _landingPos;
    
    // Attendre que l'hélico soit AU-DESSUS de la LZ (< 20m horizontal)
    private _positionTimeout = time + 60;
    waitUntil {
        sleep 0.5;
        private _dist2D = _heli distance2D _landingPos;
        _dist2D < 20 || time > _positionTimeout || !alive _heli
    };
    if (!alive _heli) exitWith { deleteVehicle _helipad; };
    
    diag_log format ["[FIN_MISSION] Hélico au-dessus LZ - Alt: %1m, Dist: %2m", 
        round ((getPosATL _heli) select 2), 
        round (_heli distance2D _landingPos)];
    
    // -----------------------------------------------------------------------------
    // PHASE 4 : DESCENTE FORCÉE AVEC setVelocity
    // -----------------------------------------------------------------------------
    diag_log "[FIN_MISSION] PHASE 4 - Descente forcée";
    
    deleteWaypoint _wp3;
    
    // Stopper tout mouvement IA
    doStop _heli;
    _heli flyInHeight 0;
    _heli land "GET IN";
    
    // Paramètres descente
    private _descentRate = -3.0;  // m/s descente
    private _maxDescentTime = 60;
    private _timeStart = time;
    
    // Boucle de descente forcée
    waitUntil {
        sleep 0.1;
        
        private _posHeli = getPosATL _heli;
        private _alt = _posHeli select 2;
        private _dist2D = _heli distance2D _landingPos;
        private _vel = velocity _heli;
        
        // Si encore en l'air (> 1m)
        if (_alt > 1) then {
            // Calcul vecteur correction horizontale vers LZ
            private _dirToLZ = _heli getDir _landingPos;
            private _correctionH = 0;
            
            // Si dérive > 3m, correction horizontale douce
            if (_dist2D > 3) then {
                _correctionH = (_dist2D min 10) / 5;  // max 2 m/s correction
            };
            
            private _velX = (sin _dirToLZ) * _correctionH;
            private _velY = (cos _dirToLZ) * _correctionH;
            
            // Appliquer descente verticale + correction horizontale
            _heli setVelocity [_velX, _velY, _descentRate];
        };
        
        // Log toutes les secondes
        if ((time - _timeStart) % 1 < 0.15) then {
            diag_log format ["[FIN_MISSION] Descente: Alt=%1m | Dist=%2m | VelZ=%3", 
                round _alt, round _dist2D, round ((_vel select 2) * 10) / 10];
        };
        
        // Conditions de sortie : au sol, très bas, timeout, ou détruit
        isTouchingGround _heli || _alt < 0.5 || (time - _timeStart) > _maxDescentTime || !alive _heli
    };
    
    // -----------------------------------------------------------------------------
    // FINALISATION
    // -----------------------------------------------------------------------------
    if (alive _heli) then {
        _heli setVelocity [0, 0, 0];
        _heli setFuel 0;
        diag_log "[FIN_MISSION] ✓ Atterrissage réussi";
    } else {
        diag_log "[FIN_MISSION] Hélicoptère détruit pendant descente";
    };
    
    deleteVehicle _helipad;
    sleep 2;
    doStop _heli;
    
    _heli setVehicleLock "UNLOCKED"; 
    _heli animateSource ["Ramp", 1];
    _heli animateDoor ["Ramp", 1];
    ["task_evacuation", _landingPos] call BIS_fnc_taskSetDestination;
    ["task_evacuation", "ASSIGNED"] call BIS_fnc_taskSetState;
    diag_log "[FIN_MISSION] En attente embarquement...";
    
    // =========================================================================
    // SYSTÈME DE COMPTAGE JOUEURS OPTIMISÉ
    // Vérifie toutes les 10s : joueurs connectés, vivants, embarqués
    // =========================================================================
    private _checkInterval = 10;
    private _allPlayersInHeli = false;
    private _lastCheck = time - _checkInterval; // Force première vérification immédiate
    
    while {!_allPlayersInHeli} do {
        sleep 1;
        
        // Vérification toutes les 20 secondes
        if (time - _lastCheck >= _checkInterval) then {
            _lastCheck = time;
            
            // Compte joueurs VIVANTS et CONNECTÉS (recalculé à chaque check)
            private _alivePlayers = allPlayers select { 
                alive _x && 
                isPlayer _x && 
                !isNull _x 
            };
            private _totalAlive = count _alivePlayers;
            
            // Compte joueurs dans l'hélico
            private _playersInHeli = _alivePlayers select { (vehicle _x) == _heli };
            private _countInHeli = count _playersInHeli;
            
            // Log serveur
            diag_log format ["[FIN_MISSION] Check embarquement: %1/%2 joueurs vivants à bord", 
                _countInHeli, _totalAlive];
            
            // Message aux joueurs
            if (_totalAlive > 0) then {
                private _msg = format [localize "STR_EVAC_PLAYER_COUNT", _countInHeli, _totalAlive];
                _msg remoteExec ["hintSilent", 0];
                
                // Condition de succès : tous les joueurs VIVANTS sont à bord
                if (_countInHeli >= _totalAlive) then {
                    _allPlayersInHeli = true;
                    diag_log "[FIN_MISSION] ✓ Tous les joueurs vivants sont embarqués";
                };
            } else {
                // Aucun joueur vivant - fin de mission échec ou attente respawn
                diag_log "[FIN_MISSION] WARN: Aucun joueur vivant détecté";
                "Aucun survivant détecté..." remoteExec ["hintSilent", 0];
            };
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
    ["outro_00"] remoteExec ["playMusic", 0];  
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
    _heli flyInHeight 50;
    _heli doMove _exitPos;
    _heli limitspeed 300;
    sleep _flyTime;
    ["END1", true] remoteExec ["BIS_fnc_endMission", 0];
};