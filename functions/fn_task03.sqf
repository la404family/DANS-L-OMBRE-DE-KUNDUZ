if (!isServer) exitWith {};

// Attendre que les fonctions requises soient prêtes
waitUntil { !isNil "Mission_fnc_applyCivilianTemplate" };

// 1. Sélection du lieu du crash
private _all_locs = [];
for "_i" from 0 to 340 do {
    private _name = format ["waypoint_invisible_%1", _i];
    if (_i < 10) then { _name = format ["waypoint_invisible_00%1", _i]; };
    if (_i >= 10 && _i < 100) then { _name = format ["waypoint_invisible_0%1", _i]; };
    
    private _obj = missionNamespace getVariable [_name, objNull];
    if (!isNull _obj) then {
        _all_locs pushBack _obj;
    };
};

if (count _all_locs == 0) exitWith { systemChat "ERREUR: Aucun waypoint_invisible trouvé pour Task03"; };

private _crash_loc_obj = selectRandom _all_locs;
private _crash_pos = getPos _crash_loc_obj;

// 2. Séquence de Vol et Crash (Live)
private _heliSpawnObj = missionNamespace getVariable ["heli_fin_spawn", objNull];
private _spawnPos = [0,0,100];

if (!isNull _heliSpawnObj) then {
    _spawnPos = getPos _heliSpawnObj;
    _spawnPos set [2, 100]; // 100m alt
} else {
    // Fallback: 2km away
    _spawnPos = _crash_pos getPos [2000, random 360];
    _spawnPos set [2, 100];
};

private _heliType = "B_Heli_Light_01_F"; 
private _heli = createVehicle [_heliType, _spawnPos, [], 0, "FLY"]; 
_heli setPos _spawnPos;
_heli allowDamage false; // Invincible durant le vol/crash pour éviter les accidents
_heli flyInHeight 100;

// Création Pilote (Temporaire)
private _grpPilot = createGroup [west, true];
private _pilot = _grpPilot createUnit ["B_Helipilot_F", _spawnPos, [], 0, "NONE"];
_pilot moveInDriver _heli;
_grpPilot setBehaviour "CARELESS";
_grpPilot setCombatMode "BLUE"; // Ne tire pas, ignore le danger

// Apparence Pilote (Allié)
private _refUnitPilot = objNull;
if (count allPlayers > 0) then { _refUnitPilot = selectRandom allPlayers; };
if (!isNull _refUnitPilot) then { _pilot setUnitLoadout (getUnitLoadout _refUnitPilot); };

// Vol vers la zone
_heli doMove _crash_pos;

// Attente arrivée sur zone (ou destruction accidentelle)
waitUntil {
    sleep 1;
    (_heli distance2D _crash_pos) < 200 || !alive _heli
};

if (!alive _heli) exitWith { systemChat "ERREUR: Hélico détruit avant le crash scripté"; };

// Séquence de Crash Trigger
_heli setDamage 0.8; // Dégâts visuels
_heli setFuel 0;     // Panne moteur -> Chute

// Effet de fumée (Vanilla)
private _smoke = "#particlesource" createVehicle (getPos _heli);
_smoke setParticleClass "MediumDestructionSmoke"; 
_smoke attachTo [_heli, [0, 0, 0]];

// Attente Impact Sol
waitUntil {
    sleep 0.5;
    ((getPos _heli) select 2) < 2
};

// Stabilisation post-crash
sleep 2;
_heli setVelocity [0,0,0];

// Nettoyage Pilote (Il est "mort" ou éjecté, remplacé par les survivants scénarisés)
deleteVehicle _pilot; 
deleteGroup _grpPilot; // Nettoyage groupe temporaire

// La suite du script gère les survivants via _survivors...

// 3. Génération des Survivants
private _survivors = [];
private _refUnit = objNull;

// Recherche d'une unité de référence pour l'équipement
if (count allPlayers > 0) then { 
    _refUnit = selectRandom allPlayers; 
} else { 
    // Fallback sur les variables globales définies par l'utilisateur
    {
        private _u = missionNamespace getVariable [_x, objNull];
        if (!isNull _u) exitWith { _refUnit = _u; };
    } forEach ["player_0", "player_1", "player_2", "officier_0", "officier_1"];
};

// Si toujours rien, on crée un dummy temporaire ou on garde B_Soldier_F
private _survivorClass = "B_Soldier_F";
if (!isNull _refUnit) then { _survivorClass = typeOf _refUnit; };

private _grpSurvivors = createGroup [west, true];

// Spawn autour de l'épave finale
for "_i" from 1 to 5 do {
    private _spawnPos = _heli getPos [5 + (random 5), random 360];
    private _survivor = _grpSurvivors createUnit [_survivorClass, _spawnPos, [], 0, "NONE"];
    
    _survivor allowDamage false; // Invincible temporairement
    _survivor setDir (random 360);
    _survivor setPos [_spawnPos select 0, _spawnPos select 1, 0.7]; // 0.7m du sol
    
    // Copie de l'équipement si référence existante
    if (!isNull _refUnit) then {
        _survivor setUnitLoadout (getUnitLoadout _refUnit);
    };

    _survivor setCaptive true; // Ignoré par les ennemis initialement
    _survivor setHit ["legs", 1]; // Jambes cassées
    
    // Désactiver IA pour figer au sol
    _survivor disableAI "ANIM";
    _survivor disableAI "MOVE";
    _survivor disableAI "TARGET";
    _survivor disableAI "AUTOTARGET";
    
    // Animation de blessé (Spécifique)
    _survivor switchMove "AinjPpneMstpSnonWrflDnon"; 
    
    // Timer Invincibilité + Rééquipement (5s après spawn)
    [_survivor, _refUnit] spawn {
        params ["_unit", "_refUnit"];
        sleep 5;
        
        if (!alive _unit) exitWith {};

        // 1. On retire tout (Strip)
        removeAllWeapons _unit;
        removeAllItems _unit;
        removeAllAssignedItems _unit;
        removeUniform _unit;
        removeVest _unit;
        removeBackpack _unit;
        removeHeadgear _unit;
        removeGoggles _unit;

        // 2. Identité Aléatoire (Basé sur fn_ajust_BLUFOR_identity)
        // Note: On utilise une version simplifiée ici pour éviter la duplication massive de tableaux
        private _faces = ["WhiteHead_01","WhiteHead_02","WhiteHead_03","WhiteHead_04","WhiteHead_05","AfricanHead_01","AfricanHead_02","AsianHead_A3_01","AsianHead_A3_02","GreekHead_A3_01"];
        private _face = selectRandom _faces;
        
        private _speakers = ["Male01FRE", "Male02FRE", "Male03FRE"];
        private _speaker = selectRandom _speakers;
        
        private _firstNames = ["Julien", "Thomas", "Nicolas", "Alexandre", "Maxime", "Guillaume", "Lucas", "Romain", "Moussa", "Mehdi"];
        private _lastNames = ["Martin", "Bernard", "Petit", "Dubois", "Moreau", "Laurent", "Girard", "N'Diaye", "Benali"];
        private _name = format ["%1 %2", selectRandom _firstNames, selectRandom _lastNames];

        [_unit, _face, _speaker, _name] call {
            params ["_u", "_f", "_s", "_n"];
            _u setFace _f;
            _u setSpeaker _s;
            _u setName _n;
        };

        // 3. Équipement (Copie Joueur ou Officier)
        if (!isNull _refUnit) then {
            _unit setUnitLoadout (getUnitLoadout _refUnit);
        } else {
            // Fallback si aucune ref: Équipement Vanilla basique
            _unit forceAddUniform "U_B_CombatUniform_mcam";
            _unit addVest "V_PlateCarrier1_rgr";
            _unit addHeadgear "H_HelmetB";
            _unit addWeapon "arifle_MX_F";
            _unit addPrimaryWeaponItem "acc_flashlight";
            _unit linkItem "ItemMap";
            _unit linkItem "ItemCompass";
            _unit linkItem "ItemRadio";
        };

        _unit allowDamage true; 
    };

    // Définition du temps de survie individuel (5 à 15 minutes)
    _survivor setVariable ["MISSION_Bleedout_Limit", 300 + (random 600), true];
    _survivor setVariable ["MISSION_Task03_is_stabilized", false, true];

    _survivors pushBack _survivor;

// Ajout Action de Soin (Logique détaillée)
    // FIX: Utilisation de localize pour le titre de l'action
    [
        _survivor,
        [
            localize "STR_ACTION_HEAL_SURVIVOR",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                
                // Animation du soigneur (Médecin accroupi)
                _caller playMove "AinvPknlMstpSnonWnonDnon_medic_1";
                
                sleep 6;
                
                if (alive _target && alive _caller) then {
                    // Marquage Logique
                    _target setVariable ["MISSION_Task03_is_stabilized", true, true];
                    _target setVariable ["MISSION_Stabilized_Time", serverTime, true];

                    // Réinitialisation Physique
                    _target setDamage 0;
                    _target setCaptive false;

                    // Réactivation de l'IA
                    _target enableAI "ANIM";
                    _target enableAI "MOVE";
                    _target enableAI "TARGET";
                    _target enableAI "AUTOTARGET";
                    
                    // Transition Visuelle (La "Cinématique") - Passage fluide en position de tir couché
                    [_target, "AmovPpneMstpSrasWrflDnon"] remoteExec ["switchMove", 0];
                    
                    // Intégration Tactique
                    [_target] joinSilent (group _caller);
                    _target doFollow _caller;
                    
                    // Suppression de l'action
                    [_target, _actionId] remoteExec ["removeAction", 0];
                    
                    systemChat localize "STR_MSG_SURVIVOR_SAVED";
                };
            },
            [],
            1.5,
            true,
            true,
            "",
            "alive _target && !(_target getVariable ['MISSION_Task03_is_stabilized', false]) && (_this distance _target < 5)", 
            3
        ]
    ] remoteExec ["addAction", 0, true];
};

// 4. Génération de la Menace (Ennemis - Vanilla) - 2 Groupes distincts
private _allEnemyGroups = [];

for "_g" from 1 to 2 do {
    private _grpEnemies = createGroup [east, true];
    _allEnemyGroups pushBack _grpEnemies;
    
    // Position spawn légèrement décalée pour chaque groupe autour de l'épave
    private _enemyPos = _heli getPos [15 + (random 15), random 360];

    // Chef d'équipe ennemi
    private _leader = _grpEnemies createUnit ["O_Soldier_F", _enemyPos, [], 0, "NONE"];
    [_leader] call Mission_fnc_applyCivilianTemplate;
    _leader addBackpack "B_FieldPack_khk"; 
    _leader addWeapon "arifle_TRG20_F"; 
    _leader addPrimaryWeaponItem "acc_flashlight"; 
    _leader addPrimaryWeaponItem "30Rnd_556x45_Stanag"; 
    for "_i" from 1 to 3 do { _leader addItemToBackpack "30Rnd_556x45_Stanag"; };

    // Membres de l'escouade (3 à 6 membres + Leader = 4 à 7 total)
    for "_i" from 1 to (3 + (random 3)) do {
        private _unit = _grpEnemies createUnit ["O_Soldier_F", _enemyPos, [], 0, "NONE"];
        [_unit] call Mission_fnc_applyCivilianTemplate;
        
        _unit addBackpack "B_FieldPack_khk";
        _unit addWeapon "arifle_TRG20_F"; 
        _unit addPrimaryWeaponItem "acc_flashlight";
        _unit addPrimaryWeaponItem "30Rnd_556x45_Stanag";
        for "_j" from 1 to 3 do { _unit addItemToBackpack "30Rnd_556x45_Stanag"; };
    };

    // Comportement Patrouille Ultra-Aggressive (COMBAT RED) - Rayon serré (5-20m)
    [_grpEnemies, _heli] spawn {
        params ["_grp", "_heli"];
        
        _grp setBehaviour "COMBAT";
        _grp setCombatMode "RED";
        _grp setSpeedMode "FULL";
        
        while { ({alive _x} count (units _grp)) > 0 } do {
            // Point aléatoire TRES PROCHE de l'épave (5-20m)
            private _movePos = _heli getPos [5 + (random 15), random 360];
            
            {
                if (alive _x) then {
                    _x doMove _movePos;
                    _x setUnitPos "AUTO"; 
                };
            } forEach (units _grp);
            
            // Rafraîchissement rapide (20s)
            sleep 20;
        };
    };
};
// Note: _grpEnemies variable interne à la boucle, on utilise _allEnemyGroups pour référence future si besoin.

// Marker de zone (Optionnel pour debug ou info joueurs)
private _mrk = createMarker ["mrk_task03_crash", _crash_pos];
_mrk setMarkerType "hd_objective";
_mrk setMarkerColor "ColorRed";
_mrk setMarkerText localize "STR_TASK03_MARKER";

// Création de la Tâche
[
    true,
    "Task03",
    [localize "STR_TASK03_DESC", localize "STR_TASK03_TITLE", localize "STR_TASK03_MARKER"],
    _crash_loc_obj,
    "CREATED",
    1,
    true,
    "heal",
    true
] call BIS_fnc_taskCreate;


// 5. Boucle de Gestion Mission
[_survivors, _crash_pos, _heli, _smoke, _allEnemyGroups, _mrk] spawn {
    params ["_survivors", "_crash_pos", "_heli", "_smoke", "_allEnemyGroups", "_mrk"];
    
    // Attente approche joueurs
    waitUntil { 
        sleep 5;
        // Vérification joueurs valides
        private _validPlayers = allPlayers select { alive _x };
        if (count _validPlayers == 0) exitWith { false };
        
        private _nearest = [_validPlayers, _crash_pos] call BIS_fnc_nearestPosition;
        (_nearest distance2D _crash_pos) < 200
    };
    
    systemChat ">>> TASK 03: Début du compte à rebours de survie <<<";
    
    // Début Compte à rebours
    private _startTime = time; // Utilisation de 'time' (plus fiable en local/hébergé)
    
    private _fnc_checkVictory = {
        params ["_survivors"];
        
        private _aliveCount = { alive _x } count _survivors;
        if (_aliveCount == 0) exitWith { false }; // Tous morts = Échec géré ailleurs

        private _stabilizedCount = {
            alive _x && (_x getVariable ["MISSION_Task03_is_stabilized", false])
        } count _survivors;

        // Victoire si tous les survivants en vie sont stabilisés
        (_stabilizedCount == _aliveCount)
    };

    private _missionActive = true;
    
    while { _missionActive } do {
        sleep 10; // Optimisation check
        
        // Gestion Mort Individuelle (Bleedout)
        {
            if (alive _x && !(_x getVariable ["MISSION_Task03_is_stabilized", false])) then {
                private _limit = _x getVariable ["MISSION_Bleedout_Limit", 300];
                private _elapsed = time - _startTime;
                
                if (_elapsed > _limit) then {
                    _x setDamage 1;
                    systemChat localize "STR_MSG_SURVIVOR_DIED";
                };
            };
        } forEach _survivors;
        
        // Vérification Victoire
        if ([_survivors] call _fnc_checkVictory) then {
            ["Task03", "SUCCEEDED"] call BIS_fnc_taskSetState;
            _missionActive = false;
        };
        
        // Vérification Défaite (Tous morts)
        private _aliveSurvivors = { alive _x } count _survivors;
        if (_aliveSurvivors == 0) then {
            ["Task03", "FAILED"] call BIS_fnc_taskSetState;
            _missionActive = false;
        };
    };
    
    // Nettoyage final après éloignement
    waitUntil {
        sleep 30; // Vérification toutes les 30 secondes comme demandé
        private _validPlayers = allPlayers select { alive _x };
        if (count _validPlayers == 0) exitWith { true };
        private _nearest = [_validPlayers, _crash_pos] call BIS_fnc_nearestPosition;
        (_nearest distance2D _crash_pos) > 1200
    };
    
    deleteVehicle _heli;
    deleteVehicle _smoke;
    deleteMarker _mrk;
    
    // Ennemis en chasse si vivants (Tous les groupes)
    {
        private _grp = _x;
        if (!isNull _grp) then {
            {
                if (alive _x) then {
                    private _nearest = [allPlayers, _x] call BIS_fnc_nearestPosition;
                    _x doMove (getPos _nearest);
                    _x setBehaviour "COMBAT";
                    _x setSpeedMode "FULL";
                };
            } forEach units _grp;
        };
    } forEach _allEnemyGroups;
};
