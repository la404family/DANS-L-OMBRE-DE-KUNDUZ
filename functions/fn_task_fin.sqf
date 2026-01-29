/*
    fn_task_fin.sqf
    
    Description:
    Système de fin de mission avec extraction par hélicoptère (Relève sur zone).
    Optimisé pour le MULTIPLAYER.
    - Création de tache "EXTRACTION" / EXFILTRATION
    - Compteur de joueurs (Pax brêlés X / Y)
    - Hélicoptère CARELESS mais combat mode RED (défensif)
    - Invisibilité des joueurs une fois dans l'hélicoptère
*/

if (!isServer) exitWith {};

diag_log "[FIN_MISSION] === Démarrage du système de fin de mission ===";

// --- CONFIGURATION ---
// Délai avant déclenchement : 35 à 45 minutes
private _delayBeforeMessage = 2100 + floor(random 600); 

// Hélicoptère identique à l'intro (NH90 Caïman AMF)
private _heliClass = "amf_nh90_tth_transport"; 
private _flyTime = 120; // 120 secondes de vol avant fin de mission

// Position d'atterrissage - objet invisible heli_fin
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

// Position de spawn hélico (heli_fin_spawn ou random 3km)
private _heliFinSpawnObj = missionNamespace getVariable ["heli_fin_spawn", objNull];
private _heliSpawnPos = [0,0,0];

if (!isNull _heliFinSpawnObj) then {
    _heliSpawnPos = getPos _heliFinSpawnObj;
    diag_log "[FIN_MISSION] Utilisation du point de spawn défini : heli_fin_spawn";
} else {
    // Fallback: Random 3km
    private _rndDir = random 360;
    _heliSpawnPos = _landingPos getPos [3000, _rndDir];
    diag_log "[FIN_MISSION] heli_fin_spawn introuvable. Spawn aléatoire à 3km.";
};
_heliSpawnPos set [2, 150];

diag_log format ["[FIN_MISSION] Hélico spawn prévu en: %1", _heliSpawnPos];
diag_log format ["[FIN_MISSION] Extraction dans %1 secondes", _delayBeforeMessage];

// --- BOUCLE PRINCIPALE ---
[_delayBeforeMessage, _heliClass, _flyTime, _landingPos, _heliSpawnPos] spawn {
    params ["_delayBeforeMessage", "_heliClass", "_flyTime", "_landingPos", "_heliSpawnPos"];
    
    // Attendre le délai configuré
    sleep _delayBeforeMessage;
    
    diag_log "[FIN_MISSION] === Délai écoulé - Lancement extraction ===";
    
    // ============================================================
    // CRÉATION DE LA TÂCHE D'EXTRACTION
    // ============================================================
    // Jargon militaire : Relève sur zone / Exfiltration
    
    [
        true,                                     // Visible pour tout le monde
        "task_evacuation",                        // ID de la tâche
        [
            localize "STR_TASK_EVAC_DESC",        // Description
            localize "STR_TASK_EVAC_TITLE",       // Titre
            "EXFILTRATION"                        // Marqueur HUD
        ],
        _landingPos,                              // Position de la tâche
        "CREATED",                                // État initial
        10,                                       // Priorité
        true,                                     // Notification
        "takeoff",                                // Type d'icône (héli décollant)
        true                                      // Toujours visible 3D
    ] call BIS_fnc_taskCreate;

    sleep 10; // Délai tactique

    // ============================================================
    // SPAWN DE L'HÉLICOPTÈRE D'EXTRACTION
    // ============================================================
    
    // Créer l'hélico en vol
    private _heli = createVehicle [_heliClass, _heliSpawnPos, [], 0, "FLY"];
    
    _heli setPos _heliSpawnPos;
    _heli setDir (_heliSpawnPos getDir _landingPos);
    _heli flyInHeight 100;
    _heli setFuel 1;
    
    // Créer l'équipage
    createVehicleCrew _heli;
    private _group = group driver _heli;
    private _crew = crew _heli;
    
    // IA : Reste sur sa trajectoire mais défend si attaqué
    _group setBehaviour "CARELESS";
    _group setCombatMode "RED";
    
    {
        _x setCaptive true;       
        _x allowDamage false;     
    } forEach _crew;
    
    _heli allowDamage false;      
    
    // Message radio : Vecteur en approche
    // (localize "STR_EVAC_INBOUND") remoteExec ["systemChat", 0];
    
    // ============================================================
    // VOL VERS LA BASE ET ATTERRISSAGE
    // ============================================================
    
    _heli doMove _landingPos;
    
    // Attendre l'approche
    waitUntil { sleep 1; (_heli distance2D _landingPos) < 300 || !alive _heli };
    
    // Forcer l'atterrissage
    _heli flyInHeight 0;
    _heli land "GET IN";
    
    // Approche finale
    waitUntil { sleep 1; (_heli distance2D _landingPos) < 50 };
    
    // Sécurité moteur pour le toucher des roues
    _heli setFuel 0; 
    
    // Attendre que l'hélico soit au sol
    private _landTimeout = 0;
    waitUntil { 
        sleep 1; 
        _landTimeout = _landTimeout + 1;
        ((getPos _heli select 2) < 2) || _landTimeout > 90 
    };
    
    doStop _heli;
    _heli setVehicleLock "UNLOCKED"; 
    
    // Ouvrir la rampe arrière (NH90 AMF = 'Ramp')
    _heli animateSource ["Ramp", 1];
    _heli animateDoor ["Ramp", 1];
    
    // Mettre à jour la tâche pour indiquer d'embarquer
    ["task_evacuation", _landingPos] call BIS_fnc_taskSetDestination;
    ["task_evacuation", "ASSIGNED"] call BIS_fnc_taskSetState;
    
    // ============================================================
    // BOUCLE D'ATTENTE ET COMPTEUR JOUEURS (Pax Check)
    // ============================================================
    
    diag_log "[FIN_MISSION] En attente embarquement...";
    
    private _allPlayersInHeli = false;
    
    while {!_allPlayersInHeli} do {
        sleep 5;
        
        // Récupérer les joueurs réellement connectés et vivants
        private _activePlayers = allPlayers select { alive _x && isPlayer _x };
        private _totalPlayers = count _activePlayers;
        
        if (_totalPlayers == 0) then { continue }; 
        
        // Compter combien sont dans l'hélico
        private _playersInHeli = { (vehicle _x) == _heli } count _activePlayers;
        
        // Afficher le statut (PAX : X / Y)
        private _msg = format [localize "STR_EVAC_PLAYER_COUNT", _playersInHeli, _totalPlayers];
        _msg remoteExec ["hintSilent", 0];
        
        // Condition de départ : Tout le monde est là
        if (_playersInHeli >= _totalPlayers && _totalPlayers > 0) then {
            _allPlayersInHeli = true;
        };
    };
    
    // ============================================================
    // DECOLLAGE (Extraction)
    // ============================================================
    
    // Message final
    // (localize "STR_EVAC_ALL_ABOARD") remoteExec ["systemChat", 0]; 
    ["task_evacuation", "SUCCEEDED"] call BIS_fnc_taskSetState;
    
    // Rendre les joueurs invisibles une fois à l'intérieur
    {
        if (isPlayer _x && (vehicle _x) == _heli) then {
            [_x, true] remoteExec ["hideObjectGlobal", 2]; 
            _x allowDamage false;
        };
    } forEach allPlayers;
    
    _heli land "NONE";
    
    // Fermer la rampe arrière
    ["intro_00"] remoteExec ["playMusic", 0]; // Musique épique de fin
    
    _heli animateSource ["door_rear_source", 0];
    _heli animateDoor ["door_rear_source", 0];
    _heli animateDoor ["ramp", 0];
    // vérouiller l'hélicoptère
    _heli setVehicleLock "LOCKED";
    sleep 2;
    
    // Redémarrage
    _heli setFuel 1;
    _heli engineOn true;
    
    // --- SECURISATION ZONE : Suppression des menaces alentours (1000m) ---
    {
        if (side _x == east || side _x == independent || side _x == resistance) then {
            _x setDamage 1;
        };
    } forEach (_heli nearEntities [["Man", "Car", "Tank", "Air"], 1000]);
    
    sleep 5;
    
    // Destination: heli_fin_direction ou point éloigné
    private _heliFinDirObj = missionNamespace getVariable ["heli_fin_direction", objNull];
    private _exitPos = [0,0,0];

    if (!isNull _heliFinDirObj) then {
         _exitPos = getPos _heliFinDirObj;
         diag_log "[FIN_MISSION] Sortie vers heli_fin_direction";
    } else {
        // Fallback: Opposé au spawn par rapport au landing
        private _dirExit = (_landingPos getDir _heliSpawnPos) + 180;
        _exitPos = _landingPos getPos [5000, _dirExit];
         diag_log "[FIN_MISSION] heli_fin_direction introuvable. Sortie opposée.";
    };
    
    _heli flyInHeight 200;
    _heli doMove _exitPos;
    _heli limitspeed 300;
    
    sleep _flyTime;
    
    // ============================================================
    // FIN DE MISSION
    // ============================================================
    
    // Terminer la mission
    ["END1", true] remoteExec ["BIS_fnc_endMission", 0];
};