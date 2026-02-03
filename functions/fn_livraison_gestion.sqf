params ["_mode", ["_params", []]];
if (_mode == "INIT") exitWith {
    if (missionNamespace getVariable ["MISSION_Livraison_Local_Init", false]) exitWith {};
    missionNamespace setVariable ["MISSION_Livraison_Local_Init", true];
    if (isServer) then {
        missionNamespace setVariable ["MISSION_Delivery_Global_Cooldown", false, true];
        [] spawn {
            sleep (120 + random 120);
            missionNamespace setVariable ["MISSION_Unlock_Vehicle", true, true];
        };
        [] spawn {
            sleep (120 + random 120);
            missionNamespace setVariable ["MISSION_Unlock_Ammo", true, true];
        };
        [] spawn {
            sleep (120 + random 120);
            missionNamespace setVariable ["MISSION_Unlock_CAS", true, true];
        };
    };
    if (hasInterface) then {
        [] spawn {
            waitUntil { !isNull player };
            private _idVeh = -1;
            private _idAmmo = -1;
            private _idCAS = -1;
            private _lastPlayer = player;
            while {true} do {
                if (player != _lastPlayer) then {
                    _lastPlayer = player;
                    _idVeh = -1;
                    _idAmmo = -1;
                    _idCAS = -1;
                    waitUntil { alive player };
                };
                if (_idVeh == -1 && {missionNamespace getVariable ["MISSION_Unlock_Vehicle", false]}) then {
                    _idVeh = [player, "VehicleDrop"] call BIS_fnc_addCommMenuItem;
                };
                if (_idAmmo == -1 && {missionNamespace getVariable ["MISSION_Unlock_Ammo", false]}) then {
                    _idAmmo = [player, "AmmoDrop"] call BIS_fnc_addCommMenuItem;
                };
                if (_idCAS == -1 && {missionNamespace getVariable ["MISSION_Unlock_CAS", false]}) then {
                    _idCAS = [player, "CASDrop"] call BIS_fnc_addCommMenuItem;
                };
                sleep 5;
            };
        };
    };
};
if (_mode == "REQUEST") exitWith {
    _params params ["_type", "_pos"];
    private _isUnlocked = switch (_type) do {
        case "VEHICLE": { missionNamespace getVariable ["MISSION_Unlock_Vehicle", false] };
        case "AMMO": { missionNamespace getVariable ["MISSION_Unlock_Ammo", false] };
        case "CAS": { missionNamespace getVariable ["MISSION_Unlock_CAS", false] };
        default { false };
    };
    if (!_isUnlocked) exitWith {
        hint "Soutien non disponible pour le moment.";
    };
    if (missionNamespace getVariable ["MISSION_Delivery_Global_Cooldown", false]) exitWith {
        [] spawn {
            playSound "Radio_In";
            sleep 0.2;
            private _snd = selectRandom ["negatif01", "negatif02", "negatif03", "negatif04"];
            playSound _snd;
            sleep 2.5;
            playSound "Radio_Out";
        };
    };
    ["EXECUTE", [_type, _pos]] remoteExec ["Mission_fnc_livraison_gestion", 2];
};
if (_mode == "EXECUTE") exitWith {
    if (!isServer) exitWith {};
    _params params ["_type", "_pos"];
    if (missionNamespace getVariable ["MISSION_Delivery_Global_Cooldown", false]) exitWith {};
    missionNamespace setVariable ["MISSION_Delivery_Global_Cooldown", true, true];
    switch (_type) do {
        case "VEHICLE": { [_pos] spawn Mission_fnc_livraison_vehicule; };
        case "AMMO": { [_pos] spawn Mission_fnc_livraison_munitions; };
        case "CAS": { [_pos] spawn Mission_fnc_livraison_soutienAR; };
    };
    [] spawn {
        private _cooldown = 240 + random 180;
        sleep _cooldown;
        missionNamespace setVariable ["MISSION_Delivery_Global_Cooldown", false, true];
        "QG: Vecteurs de ravitaillement disponibles." remoteExec ["systemChat", 0];
    };
};
