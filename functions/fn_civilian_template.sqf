/*
    fn_civilian_template.sqf
    Description:
    Récupère les tenues complètes des unités "civil_template_XX" placées dans l'éditeur.
    Stocke ces informations dans MISSION_CivilianTemplates (variable unifiée).
    Supprime les unités physiques une fois mémorisées.
    
    Format stocké: [Type, Loadout, Face, isFemale]
    
    Unités : civil_template_00 à civil_template_28
*/

if (!isServer) exitWith {};

diag_log "[TEMPLATE] === Démarrage mémorisation des templates civils ===";

// Variable UNIFIÉE (partagée avec fn_civilian_logique et fn_apply_civilian_profile)
MISSION_CivilianTemplates = [];

// Boucle sur les 29 templates possibles (00 à 28)
for "_i" from 0 to 28 do {
    private _suffix = if (_i < 10) then { "0" + str _i } else { str _i };
    private _varName = format ["civil_template_%1", _suffix];
    
    private _unit = missionNamespace getVariable [_varName, objNull];
    
    if (!isNull _unit) then {
        // Extraction des données
        private _type = typeOf _unit;
        private _loadout = getUnitLoadout _unit;
        private _face = face _unit;
        private _uniform = uniform _unit;
        
        // --- DETECTION DU GENRE (Multi-critères) ---
        private _isFemale = false;
        private _uLow = toLower _uniform;
        private _faceLow = toLower _face;
        
        // Critère 1: Uniforme contient mot-clé féminin
        if ((_uLow find "burqa" > -1) || (_uLow find "dress" > -1) || (_uLow find "woman" > -1) || (_uLow find "female" > -1)) then {
            _isFemale = true;
        };
        
        // Critère 2: Visage contient mot-clé féminin
        if ((_faceLow find "female" > -1) || (_faceLow find "woman" > -1)) then {
            _isFemale = true;
        };
        
        // Critère 3: Variable éditeur
        if (_unit getVariable ["isWoman", false]) then {
            _isFemale = true;
        };
        
        // Stockage au format unifié: [Type, Loadout, Face, isFemale]
        MISSION_CivilianTemplates pushBack [_type, _loadout, _face, _isFemale];
        
        diag_log format ["[TEMPLATE] Saved: %1 | Type: %2 | Uniform: %3 | Female: %4", _varName, _type, _uniform, _isFemale];
        
        // Nettoyage
        deleteVehicle _unit;
    };
};

// Fallback si aucun template trouvé
if (count MISSION_CivilianTemplates == 0) then {
    MISSION_CivilianTemplates = [["C_man_polo_1_F", [], "PersianHead_A3_01", false]];
    diag_log "[TEMPLATE] WARNING: No templates found, using fallback";
};

// Rendre la variable accessible partout (Clients + JIP)
publicVariable "MISSION_CivilianTemplates";

diag_log format ["[TEMPLATE] Terminé. %1 gabarits civils mémorisés.", count MISSION_CivilianTemplates];
