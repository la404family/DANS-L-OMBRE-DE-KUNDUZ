if (!isServer) exitWith {};

// --- CONFIGURATION ---
CIVIL_CHANGE_IntervalMin  = 10    // Intervalle minimum en secondes
CIVIL_CHANGE_IntervalMax  = 15;   // Intervalle maximum en secondes
CIVIL_CHANGE_MinDistance  = 600;    // Distance minimum du joueur pour être éligible
CIVIL_CHANGE_RequiredCount = 3;    // Nombre de civils requis
CIVIL_CHANGE_Debug        = false; // Mode debug

// --- FONCTION UTILITAIRE: LOG ---
CIVIL_CHANGE_fnc_log = {
    params ["_msg"];
    if (CIVIL_CHANGE_Debug) then { 
        systemChat format ["[CIVIL_CHANGE] %1", _msg]; 
        diag_log format ["[CIVIL_CHANGE] %1", _msg];
    };
};

// --- FONCTION PRINCIPALE: CONVERSION D'UN CIVIL EN INSURGÉ ---
CIVIL_CHANGE_fnc_convertToInsurgent = {
    params ["_civil"];
    
    if (!alive _civil) exitWith { objNull };
    
    // Sauvegarder l'uniforme et l'apparence
    private _pos = getPosATL _civil;
    private _dir = getDir _civil;
    private _uniform = uniform _civil;
    private _vest = vest _civil;
    private _headgear = headgear _civil;
    private _goggles = goggles _civil; // Gère les "cagoules" / lunettes
    private _face = face _civil;
    
    // Supprimer le civil (agent)
    deleteVehicle _civil;
    
    // Créer un vrai unit OPFOR
    private _grp = createGroup [east, true]; // Groupe OPFOR avec deleteWhenEmpty
    private _insurgent = _grp createUnit ["O_G_Soldier_F", _pos, [], 0, "NONE"];
    
    _insurgent setDir _dir;
    _insurgent setFace _face;
    
    // Retirer tout l'équipement par défaut
    removeAllWeapons _insurgent;
    removeAllItems _insurgent;
    removeAllAssignedItems _insurgent;
    removeBackpack _insurgent;
    removeUniform _insurgent;
    removeVest _insurgent;
    removeHeadgear _insurgent;
    removeGoggles _insurgent;
    
    // Remettre l'apparence civile (même tenue)
    if (_uniform != "") then { _insurgent forceAddUniform _uniform; };
    if (_vest != "") then { _insurgent addVest _vest; };
    if (_headgear != "") then { _insurgent addHeadgear _headgear; };
    if (_goggles != "") then { _insurgent addGoggles _goggles; };
    
    // Ajouter le sac coyote
    _insurgent addBackpack "B_Messenger_Coyote_F";
    
    // Ajouter l'AKM et les munitions
    _insurgent addWeapon "rhs_weap_akmn";
    _insurgent addPrimaryWeaponItem "rhs_30Rnd_762x39mm"; // Chargeur RHS 7.62
    _insurgent addPrimaryWeaponItem "rhs_acc_2dpZenit"; // Lampe torche 2DP Zenit
    _insurgent enableGunLights "forceOn"; // Force la lampe allumée (la nuit) de préférence
    
    // Ajouter des munitions supplémentaires dans le sac
    for "_i" from 1 to 6 do {
        _insurgent addItemToBackpack "rhs_30Rnd_762x39mm";
    };
    
    // Ajouter items de base
    _insurgent linkItem "ItemMap";
    _insurgent linkItem "ItemCompass";
    _insurgent linkItem "ItemRadio";
    
    // Configurer le comportement de combat
    _insurgent setCombatMode "RED";
    _insurgent setBehaviour "COMBAT";
    _insurgent setSkill 0.5;
    
    // Activer toutes les capacités IA
    _insurgent enableAI "ALL";
    
    // Marquer comme insurgé converti
    _insurgent setVariable ["CIVIL_CHANGE_Converted", true, true];
    
    ["Insurgé créé à partir d'un civil"] call CIVIL_CHANGE_fnc_log;
    
    _insurgent
};

// --- FONCTION: TROUVER ET ATTAQUER L'ENNEMI LE PLUS PROCHE ---
CIVIL_CHANGE_fnc_attackNearestEnemy = {
    params ["_insurgent"];
    
    if (!alive _insurgent) exitWith {};
    
    // Trouver tous les ennemis (BLUFOR = joueurs)
    private _enemies = allUnits select {
        alive _x && 
        {side _x == west} && 
        {!(_x getVariable ["CIVIL_CHANGE_Converted", false])}
    };
    
    if (count _enemies == 0) exitWith {
        ["Aucun ennemi trouvé pour l'insurgé"] call CIVIL_CHANGE_fnc_log;
    };
    
    // Trouver l'ennemi le plus proche
    private _nearestEnemy = objNull;
    private _minDist = 99999;
    
    {
        private _dist = _insurgent distance _x;
        if (_dist < _minDist) then {
            _minDist = _dist;
            _nearestEnemy = _x;
        };
    } forEach _enemies;
    
    if (!isNull _nearestEnemy) then {
        // Donner l'ordre d'attaquer
        private _grp = group _insurgent;
        _grp reveal [_nearestEnemy, 4];
        _insurgent doTarget _nearestEnemy;
        _insurgent doFire _nearestEnemy;
        
        // Créer un waypoint d'attaque vers la position de l'ennemi
        private _wp = _grp addWaypoint [getPos _nearestEnemy, 30];
        _wp setWaypointType "SAD"; // Search and Destroy
        _wp setWaypointBehaviour "COMBAT";
        _wp setWaypointCombatMode "RED";
        _wp setWaypointSpeed "FULL";
        
        [format ["Insurgé attaque l'ennemi à %1m", round _minDist]] call CIVIL_CHANGE_fnc_log;
    };
};

// --- BOUCLE PRINCIPALE ---
[] spawn {
    // Attendre l'initialisation du système civil
    sleep 5;
    
    ["Système de conversion civils -> insurgés activé"] call CIVIL_CHANGE_fnc_log;
    
    while {true} do {
        // Récupérer tous les joueurs
        private _players = allPlayers select {alive _x && !(_x isKindOf "HeadlessClient_F")};
        
        if (count _players > 0) then {
            // Référence au premier joueur (ou leader)
            private _referencePlayer = _players select 0;
            
            // Trouver TOUS les civils actifs (modules éditeur + système personnalisé)
            // On cherche toutes les unités de side civilian qui sont loin du joueur
            private _allCivilians = allUnits select {
                alive _x && 
                {side group _x == civilian} && // Utiliser side group pour robustesse
                {!(_x getVariable ["CIVIL_CHANGE_Converted", false])} && // Pas déjà converti
                {_x distance _referencePlayer > CIVIL_CHANGE_MinDistance}
            };
            
            [format ["Civils éligibles trouvés: %1", count _allCivilians]] call CIVIL_CHANGE_fnc_log;
            
            // Si on a au moins civils éligibles
            if (count _allCivilians >= CIVIL_CHANGE_RequiredCount) then {
                // Mélanger et sélectionner civils
                private _shuffled = _allCivilians call BIS_fnc_arrayShuffle;
                private _selectedCivils = [];
                
                for "_i" from 0 to (CIVIL_CHANGE_RequiredCount - 1) do {
                    _selectedCivils pushBack (_shuffled select _i);
                };
                
                [format ["%1 civils sélectionnés pour conversion", count _selectedCivils]] call CIVIL_CHANGE_fnc_log;
                
                // Convertir chaque civil en insurgé
                {
                    private _insurgent = [_x] call CIVIL_CHANGE_fnc_convertToInsurgent;
                    
                    if (!isNull _insurgent) then {
                        // Attendre un court instant pour la stabilisation
                        sleep 0.5;
                        
                        // Ordonner d'attaquer l'ennemi le plus proche
                        [_insurgent] call CIVIL_CHANGE_fnc_attackNearestEnemy;
                    };
                    
                    sleep 0.2; // Petit délai entre chaque conversion
                } forEach _selectedCivils;
                
                ["Conversion terminée - insurgés actifs"] call CIVIL_CHANGE_fnc_log;
            } else {
                [format ["Pas assez de civils éligibles (%1/%2)", count _allCivilians, CIVIL_CHANGE_RequiredCount]] call CIVIL_CHANGE_fnc_log;
            };
        };
        
        // Attendre un intervalle aléatoire entre 35 et 200 secondes
        private _nextInterval = CIVIL_CHANGE_IntervalMin + random (CIVIL_CHANGE_IntervalMax - CIVIL_CHANGE_IntervalMin);
        [format ["Prochain check dans %1 secondes", round _nextInterval]] call CIVIL_CHANGE_fnc_log;
        sleep _nextInterval;
    };
};