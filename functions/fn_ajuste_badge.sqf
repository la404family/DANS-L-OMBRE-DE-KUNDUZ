/*
    fn_ajuste_badge.sqf
    Description:
    Force l'insigne "France (Haute Visibilité)" pour toutes les unités BLUFOR (Joueurs et IA).
    Vérification périodique toutes les 60 secondes.
    
    Insigne: AMF_FRANCE_HV
*/

if (!isServer) exitWith {};

diag_log "[BADGE_SYNC] Démarrage de la synchronisation des insignes...";

while {true} do {
    // Sélectionner toutes les unités BLUFOR vivantes (Joueurs et IA)
    private _bluforUnits = allUnits select { side _x == west && alive _x };
    
    {
        private _unit = _x;
        // Récupérer l'insigne actuel
        private _currentBadge = [_unit] call BIS_fnc_getUnitInsignia;
        
        // Si l'insigne n'est pas "AMF_FRANCE_HV", on l'applique
        if (_currentBadge != "AMF_FRANCE_HV") then {
            [_unit, "AMF_FRANCE_HV"] call BIS_fnc_setUnitInsignia;
        };
        
    } forEach _bluforUnits;
    
    // Pause de 60 secondes
    sleep 60;
};