/*
    fn_ajust_team_leader.sqf
    Assure que le leader du groupe est toujours un joueur humain si possible,
    et lui attribue les options de commandement (VehicleDrop, AmmoDrop, CASDrop).
    S'exécute en boucle locale sur chaque client.
    
    Gère aussi la réapparition des menus après le cooldown de 20 minutes.
*/

if (!hasInterface) exitWith {}; // Uniquement sur les clients joueurs

[] spawn {
    sleep 10;

    // IDs de menus (-1 = pas attribué)
    private _idVeh = -1;
    private _idAmmo = -1;
    private _idCAS = -1;
    
    // Suivi du joueur pour reset au respawn
    private _lastPlayerObj = player;

    while {true} do {
        private _group = group player;
        
        // --- 0. RESET SI RESPAWN ---
        if (player != _lastPlayerObj) then {
            _lastPlayerObj = player;
            _idVeh = -1;
            _idAmmo = -1;
            _idCAS = -1;
        };
        
        // --- 1. GESTION DU LEADERSHIP (Auto-Promote) ---
        if (!isNull _group) then {
            private _leader = leader _group;
            if (!isPlayer _leader) then {
                private _newLeader = objNull;
                {
                    if (isPlayer _x && alive _x) exitWith { _newLeader = _x; };
                } forEach (units _group);
                if (!isNull _newLeader) then { _group selectLeader _newLeader; };
            };
        };

        // --- 2. GESTION DES MENUS DE SUPPORT AVEC COOLDOWN ---
        if (player == leader group player) then {
            // A. VEHICULE
            private _lastUseVeh = missionNamespace getVariable ["MISSION_LastUse_Vehicle", -9999];
            if (time > _lastUseVeh + 1200) then {
                // Cooldown terminé -> On doit avoir le menu
                if (_idVeh == -1) then {
                    _idVeh = [player, "VehicleDrop"] call BIS_fnc_addCommMenuItem;
                    systemChat "Commandement : Livraison Véhicule DISPONIBLE.";
                };
            } else {
                // Cooldown actif -> On ne doit PAS avoir le menu
                if (_idVeh != -1) then {
                    [player, _idVeh] call BIS_fnc_removeCommMenuItem;
                    _idVeh = -1;
                };
            };

            // B. MUNITIONS
            private _lastUseAmmo = missionNamespace getVariable ["MISSION_LastUse_Ammo", -9999];
            if (time > _lastUseAmmo + 1200) then {
                if (_idAmmo == -1) then {
                    _idAmmo = [player, "AmmoDrop"] call BIS_fnc_addCommMenuItem;
                    systemChat "Commandement : Ravitaillement Munitions DISPONIBLE.";
                };
            } else {
                if (_idAmmo != -1) then {
                    [player, _idAmmo] call BIS_fnc_removeCommMenuItem;
                    _idAmmo = -1;
                };
            };

            // C. CAS (Soutien Aérien)
            private _lastUseCAS = missionNamespace getVariable ["MISSION_LastUse_CAS", -9999];
            if (time > _lastUseCAS + 1200) then {
                if (_idCAS == -1) then {
                    _idCAS = [player, "CASDrop"] call BIS_fnc_addCommMenuItem;
                    systemChat "Commandement : Soutien Aérien (CAS) DISPONIBLE.";
                };
            } else {
                if (_idCAS != -1) then {
                    [player, _idCAS] call BIS_fnc_removeCommMenuItem;
                    _idCAS = -1;
                };
            };
            
        } else {
            // Pas leader -> Tout retirer
            if (_idVeh != -1) then { [player, _idVeh] call BIS_fnc_removeCommMenuItem; _idVeh = -1; };
            if (_idAmmo != -1) then { [player, _idAmmo] call BIS_fnc_removeCommMenuItem; _idAmmo = -1; };
            if (_idCAS != -1) then { [player, _idCAS] call BIS_fnc_removeCommMenuItem; _idCAS = -1; };
        };
        
        sleep 2;
    };
};