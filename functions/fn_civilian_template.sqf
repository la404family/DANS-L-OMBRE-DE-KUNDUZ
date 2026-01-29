/*
    fn_civilian_template.sqf
    Description:
    Récupère les tenues, lunettes/cagoules (Facewear) et casques des unités "civil_template_XX" placées dans l'éditeur.
    Stocke ces informations dans une variable globale pour utilisation ultérieure.
    Supprime les unités physiques une fois mémorisées.
    
    Unités : civil_template_00 à civil_template_28
*/

if (!isServer) exitWith {};

diag_log "[TEMPLATE] === Démarrage mémorisation des templates civils ===";

MISSION_var_CivilianTemplates = [];

// Boucle sur les 29 templates possibles (00 à 28)
for "_i" from 0 to 28 do {
    // Formatage du nom de variable : civil_template_00, civil_template_01, etc.
    private _suffix = if (_i < 10) then { "0" + str _i } else { str _i };
    private _varName = format ["civil_template_%1", _suffix];
    
    // Récupération de l'objet
    private _unit = missionNamespace getVariable [_varName, objNull];
    
    if (!isNull _unit) then {
        // Extraction du Loadout visuel
        private _uniform = uniform _unit;
        private _facewear = goggles _unit;   // Correspond à "Facewear" / Lunettes / Cagoules
        private _headgear = headgear _unit;  // Casque / Chapeau
        
        // Stockage dans le tableau global : [Uniforme, Cagoule, Chapeau]
        MISSION_var_CivilianTemplates pushBack [_uniform, _facewear, _headgear];
        
        // Suppression de l'unité de référence pour nettoyer la map
        deleteVehicle _unit;
        
        // Log pour debug
        // diag_log format ["[TEMPLATE] Mémorisé %1 : %2 | %3", _varName, _uniform, _facewear];
    };
};

// Rendre la variable accessible partout (Clients + JIP)
publicVariable "MISSION_var_CivilianTemplates";

diag_log format ["[TEMPLATE] Terminé. %1 gabarits civils mémorisés.", count MISSION_var_CivilianTemplates];
