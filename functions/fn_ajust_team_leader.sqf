/*
    fn_ajust_team_leader.sqf
    Assure que le leader du groupe est toujours un joueur humain si possible.
    S'exécute en boucle locale sur chaque client.
*/

if (!hasInterface) exitWith {}; // Uniquement sur les clients joueurs

[] spawn {
    // Petit délai au démarrage
    sleep 10;
    
    while {true} do {
        private _group = group player;
        
        // Sécurité : Si le joueur a un groupe valide
        if (!isNull _group) then {
            private _leader = leader _group;

            // Si le leader actuel est une IA (et qu'on a des joueurs dans le groupe)
            if (!isPlayer _leader) then {
                
                // Chercher un candidat humain valide (Joueur + Vivant)
                private _newLeader = objNull;
                
                {
                    if (isPlayer _x && alive _x) exitWith {
                        _newLeader = _x;
                    };
                } forEach (units _group);
                
                // Si un candidat est trouvé, on lui donne le lead
                if (!isNull _newLeader) then {
                    // La commande est globale, donc tous les clients verront le changement
                    _group selectLeader _newLeader;
                    
                    // Log optionnel pour debug
                    // systemChat format ["[Auto-Leader] Leadership transféré à %1", name _newLeader];
                };
            };
        };
        
        // Vérification périodique (10 secondes)
        sleep 10;
    };
};