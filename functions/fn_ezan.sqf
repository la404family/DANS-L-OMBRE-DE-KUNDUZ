/*
    File: fn_ezan.sqf
    Description: Plays the ezan sound from 5 minarets every 30 minutes.
    OPTIMIZATION: Only sends network traffic to players within audible range (2000m).
*/

if (!isServer) exitWith {}; // Only run on server

// --- CONFIGURATION ---
private _soundRange = 2500; // Portée du son en mètres
// Liste des noms de variables des objets minarets
//ezan_00 à ezan_08
private _minaretsVars = ["ezan_00", "ezan_01", "ezan_02"];

// Attente initiale (aléatoire entre 5 minutes et 15 minutes)
sleep (300 + (random 600));

while {true} do {
    
    {
        private _varName = _x;
        // Récupérer l'objet via son nom de variable
        private _minaretObj = missionNamespace getVariable [_varName, objNull];
        
        if (!isNull _minaretObj) then {
            // OPTIMISATION NETWORK : Trouver les joueurs à portée audio uniquement
            private _nearbyPlayers = allPlayers select { (_x distance _minaretObj) < _soundRange };
            
            // Si des joueurs sont à portée, envoyer le son UNIQUEMENT à eux
            if (count _nearbyPlayers > 0) then {
                [_minaretObj, ["ezan", _soundRange, 1]] remoteExec ["say3D", _nearbyPlayers];
                // diag_log format ["[EZAN] Son joué sur %1 pour %2 joueurs", _varName, count _nearbyPlayers];
            };
        };
        
        // Décalage léger entre les minarets pour effet d'écho réaliste
        sleep 0.05;
        
    } forEach _minaretsVars;
    
    // Attendre 30 minutes avant le prochain appel
    sleep 1800;
};