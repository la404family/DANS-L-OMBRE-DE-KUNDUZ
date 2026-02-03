/*
    fn_livraison_gestion.sqf
    Gestionnaire centralisé des livraisons (Véhicule, Munitions, CAS).
    Gère les délais d'activation (2-4 min), les verrous globaux multijoueurs et l'optimisation.
    
    Auteur: [Votre Nom/Pseudo]
    
    Appel Init (init.sqf):
    ["INIT"] spawn Mission_fnc_livraison_gestion;
    
    Appel Request (Menu Support):
    ["REQUEST", ["TYPE", _pos]] spawn Mission_fnc_livraison_gestion;
*/

params ["_mode", ["_params", []]];

// --- 1. INITIALISATION (Lancement Serveur + Client) ---
if (_mode == "INIT") exitWith {
    // PROTECTION: Eviter double initialisation (Host)
    if (missionNamespace getVariable ["MISSION_Livraison_Local_Init", false]) exitWith {};
    missionNamespace setVariable ["MISSION_Livraison_Local_Init", true];
    
    // SERVER SIDE: Gestion des timers et variables
    if (isServer) then {
        // Variable de verrou global (True = occupé)
        missionNamespace setVariable ["MISSION_Delivery_Global_Cooldown", false, true];
        
        // --- Timers d'activation aléatoires (2 à 4 minutes) ---
        // Véhicule
        [] spawn {
            sleep (120 + random 120);
            missionNamespace setVariable ["MISSION_Unlock_Vehicle", true, true];
        };
        // Munitions
        [] spawn {
            sleep (120 + random 120);
            missionNamespace setVariable ["MISSION_Unlock_Ammo", true, true];
        };
        // CAS
        [] spawn {
            sleep (120 + random 120);
            missionNamespace setVariable ["MISSION_Unlock_CAS", true, true];
        };
    };

    // CLIENT SIDE: Gestion des menus (Apparition & Respawn)
    if (hasInterface) then {
        [] spawn {
            waitUntil { !isNull player };
            
            private _idVeh = -1;
            private _idAmmo = -1;
            private _idCAS = -1;
            private _lastPlayer = player;
            
            while {true} do {
                // 1. Détection RESPAWN
                if (player != _lastPlayer) then {
                    _lastPlayer = player;
                    // Les menus sont perdus à la mort, on reset les IDs
                    _idVeh = -1;
                    _idAmmo = -1;
                    _idCAS = -1;
                    waitUntil { alive player };
                };
                
                // 2. Vérification et Ajout des Menus (si débloqués et pas encore ajoutés)
                
                // Véhicule
                if (_idVeh == -1 && {missionNamespace getVariable ["MISSION_Unlock_Vehicle", false]}) then {
                    _idVeh = [player, "VehicleDrop"] call BIS_fnc_addCommMenuItem;
                    systemChat localize "STR_LIVRAISON_VEHICLE_AVAILABLE"; // "Véhicule disponible"
                    if (isNil "STR_LIVRAISON_VEHICLE_AVAILABLE") then { systemChat "Radio : Livraison Véhicule DISPONIBLE."; };
                };
                
                // Munitions
                if (_idAmmo == -1 && {missionNamespace getVariable ["MISSION_Unlock_Ammo", false]}) then {
                    _idAmmo = [player, "AmmoDrop"] call BIS_fnc_addCommMenuItem;
                     systemChat localize "STR_LIVRAISON_AMMO_AVAILABLE";
                     if (isNil "STR_LIVRAISON_AMMO_AVAILABLE") then { systemChat "Radio : Largage Munitions DISPONIBLE."; };
                };
                
                // CAS
                if (_idCAS == -1 && {missionNamespace getVariable ["MISSION_Unlock_CAS", false]}) then {
                    _idCAS = [player, "CASDrop"] call BIS_fnc_addCommMenuItem;
                    systemChat localize "STR_LIVRAISON_CAS_AVAILABLE";
                    if (isNil "STR_LIVRAISON_CAS_AVAILABLE") then { systemChat "Radio : Soutien Aérien (CAS) DISPONIBLE."; };
                };
                
                sleep 5;
            };
        };
    };
};

// --- 2. REQUÊTE CLIENT (Appelé via le menu) ---
if (_mode == "REQUEST") exitWith {
    _params params ["_type", "_pos"];
    
    // Check 1: Est-ce que le système est débloqué ? (Sécurité double)
    private _isUnlocked = switch (_type) do {
        case "VEHICLE": { missionNamespace getVariable ["MISSION_Unlock_Vehicle", false] };
        case "AMMO": { missionNamespace getVariable ["MISSION_Unlock_Ammo", false] };
        case "CAS": { missionNamespace getVariable ["MISSION_Unlock_CAS", false] };
        default { false };
    };
    
    if (!_isUnlocked) exitWith {
        hint "Soutien non disponible pour le moment.";
    };
    
    // Check 2: Est-ce qu'une livraison est déjà en cours (Cooldown Global 4-7 min) ?
    if (missionNamespace getVariable ["MISSION_Delivery_Global_Cooldown", false]) exitWith {
        // hint "QG: Négatif. Nos vecteurs sont indisponibles ou en rechargement. Réessayez plus tard.";
        [] spawn {
            playSound "Radio_In";
            sleep 0.2;
            private _snd = selectRandom ["negatif01", "negatif02", "negatif03", "negatif04"];
            playSound _snd;
            sleep 2.5;
            playSound "Radio_Out";
        };
    };
    
    // Si OK, on envoie la demande au serveur pour exécution
    ["EXECUTE", [_type, _pos]] remoteExec ["Mission_fnc_livraison_gestion", 2];
};

// --- 3. EXÉCUTION SERVEUR (Logique de gestion) ---
if (_mode == "EXECUTE") exitWith {
    if (!isServer) exitWith {};
    _params params ["_type", "_pos"];
    
    // Double vérification serveur (Anti-Race Condition)
    if (missionNamespace getVariable ["MISSION_Delivery_Global_Cooldown", false]) exitWith {};
    
    // VERROUILLAGE DU SYSTÈME
    missionNamespace setVariable ["MISSION_Delivery_Global_Cooldown", true, true];
    
    // Lancement de la fonction spécifique
    // Note: Les fonctions individuelles ne doivent plus gérer leurs propres cooldowns
    switch (_type) do {
        case "VEHICLE": { [_pos] spawn Mission_fnc_livraison_vehicule; };
        case "AMMO": { [_pos] spawn Mission_fnc_livraison_munitions; };
        case "CAS": { [_pos] spawn Mission_fnc_livraison_soutienAR; };
    };
    
    // GESTION DU COOLDOWN (4 à 7 minutes)
    [] spawn {
        // Temps de rechargement aléatoire entre 4 min (240s) et 7 min (420s)
        private _cooldown = 240 + random 180;
        
        sleep _cooldown;
        
        // DÉVERROUILLAGE
        missionNamespace setVariable ["MISSION_Delivery_Global_Cooldown", false, true];
        
        // Notification aux joueurs
        "QG: Vecteurs de ravitaillement disponibles." remoteExec ["systemChat", 0];
    };
};
