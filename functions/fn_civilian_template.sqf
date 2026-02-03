if (!isServer) exitWith {};
systemChat "[TEMPLATE] Script demarré...";
diag_log "[TEMPLATE] === Démarrage mémorisation des templates civils ===";
MISSION_CivilianTemplates = [];
for "_i" from 0 to 33 do {
    private _suffix = if (_i < 10) then { "0" + str _i } else { str _i };
    private _varName = format ["civil_template_%1", _suffix];
    private _unit = missionNamespace getVariable [_varName, objNull];
    if (!isNull _unit) then {
        removeAllWeapons _unit;
        removeAllItems _unit;
        removeAllAssignedItems _unit;
        private _type = typeOf _unit;
        private _loadout = getUnitLoadout _unit;
        private _face = face _unit;
        private _uniform = uniform _unit;
        private _isFemale = false;
        private _uLow = toLower _uniform;
        private _faceLow = toLower _face;
        if ((_uLow find "burqa" > -1) || (_uLow find "dress" > -1) || (_uLow find "woman" > -1) || (_uLow find "female" > -1)) then {
            _isFemale = true;
        };
        if ((_faceLow find "female" > -1) || (_faceLow find "woman" > -1)) then {
            _isFemale = true;
        };
        if (_unit getVariable ["isWoman", false]) then {
            _isFemale = true;
        };
        private _pitch = 1.0;
        if (_isFemale) then {
            _pitch = 1.2 + (random 0.2); 
        };
        MISSION_CivilianTemplates pushBack [_type, _loadout, _face, _isFemale, _pitch];
        diag_log format ["[TEMPLATE] Saved: %1 | Type: %2 | Female: %3 | Pitch: %4", _varName, _type, _isFemale, _pitch];
        deleteVehicle _unit;
    };
};
if (count MISSION_CivilianTemplates == 0) then {
    MISSION_CivilianTemplates = [["C_man_polo_1_F", [], "PersianHead_A3_01", false, 1.0]];
    diag_log "[TEMPLATE] WARNING: No templates found, using fallback";
};
publicVariable "MISSION_CivilianTemplates";
private _msg = format ["[TEMPLATE] Terminé. %1 gabarits civils mémorisés.", count MISSION_CivilianTemplates];
diag_log _msg;
systemChat _msg;  
