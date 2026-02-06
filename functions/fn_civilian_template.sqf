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
        
        // 1. Initialisation temps réel et variables
        private _uLow = toLower _uniform;
        private _faceLow = toLower _face;
        private _isFemale = false;
        
        // 2. Méthode CONFIG (Moteur du jeu)
        if (getNumber (configFile >> "CfgVehicles" >> _type >> "woman") == 1) then {
            _isFemale = true;
        };

        // 3. Méthode CONFIG UNIFORME
        if (!_isFemale && _uniform != "") then {
            private _uniformClass = getText (configFile >> "CfgWeapons" >> _uniform >> "ItemInfo" >> "uniformClass");
            if (_uniformClass != "") then {
                if (getNumber (configFile >> "CfgVehicles" >> _uniformClass >> "woman") == 1) then {
                    _isFemale = true;
                };
            };
        };

        // 4. Méthode MOTS-CLÉS ÉTENDUE (Classname + DisplayName + Visage + Type)
        if (!_isFemale) then {
            private _keywords = ["woman", "female", "girl", "lady", "dress", "burqa", "abaya", "hijab", "chador", "skirt", "young"];
            
            // On récupère aussi le NOM D'AFFICHAGE de l'uniforme (ex: "Takistani Dress")
            private _uniformDisplayName = "";
            if (_uniform != "") then {
                _uniformDisplayName = toLower (getText (configFile >> "CfgWeapons" >> _uniform >> "displayName"));
            };
            
            {
                if ((_uLow find _x) > -1) exitWith { _isFemale = true; };
                if ((_faceLow find _x) > -1) exitWith { _isFemale = true; };
                if ((toLower(_type) find _x) > -1) exitWith { _isFemale = true; };
                if ((_uniformDisplayName find _x) > -1) exitWith { _isFemale = true; };
            } forEach _keywords;
        };

        // 3. Fallback variable script (sécurité)
        if (_unit getVariable ["isWoman", false]) then {
            _isFemale = true;
        };
        private _pitch = 0.8 + (random 0.2); // Par défaut Homme (Grave: 0.8 - 1.0)
        if (_isFemale) then {
            _pitch = 1.2 + (random 0.2); // Femme (Aigu: 1.2 - 1.4)
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
