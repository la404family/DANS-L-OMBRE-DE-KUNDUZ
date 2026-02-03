if (!isServer) exitWith {};
diag_log "[BADGE_SYNC] Démarrage de la synchronisation des insignes...";
while {true} do {
    private _bluforUnits = allUnits select { side _x == west && alive _x };
    {
        private _unit = _x;
        private _currentBadge = [_unit] call BIS_fnc_getUnitInsignia;
        if (_currentBadge != "AMF_FRANCE_HV") then {
            [_unit, "AMF_FRANCE_HV"] call BIS_fnc_setUnitInsignia;
        };
    } forEach _bluforUnits;
    sleep 60;
};