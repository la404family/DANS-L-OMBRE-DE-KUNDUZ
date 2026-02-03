if (!hasInterface) exitWith {};  
[] spawn {
    sleep 10;
    while {true} do {
        private _group = group player;
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