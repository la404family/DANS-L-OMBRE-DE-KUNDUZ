/*
    fn_ajust_team_leader.sqf
    Assure que le leader du groupe est toujours un joueur humain si possible,
    et lui attribue les options de commandement (VehicleDrop, AmmoDrop, CASDrop).
    S'exécute en boucle locale sur chaque client.
    
    Gère aussi la réapparition des menus après le cooldown de 20 minutes.
*/

if (!hasInterface) exitWith {}; // Uniquement sur les clients joueurs

[] spawn {
    sleep 10;

    while {true} do {
        private _group = group player;
        
        // --- GESTION DU LEADERSHIP (Auto-Promote) ---
        if (!isNull _group) then {
            private _leader = leader _group;
            if (!isPlayer _leader) then {
                private _newLeader = objNull;
                {
                    if (isPlayer _x && alive _x) exitWith { _newLeader = _x; };
                } forEach (units _group);
                if (!isNull _newLeader) then { _group selectLeader _newLeader; };
            };
        };
        
        sleep 5;
    };
};