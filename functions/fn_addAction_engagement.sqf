 

if (!hasInterface) exitWith {};

 
[] spawn {
    while {true} do {
        sleep 30;  

        private _player = player;
        
         
        if (!isNull _player && alive _player) then {
            
            private _group = group _player;
            private _isLeader = (leader _group == _player);
            private _hasAI = (count (units _group select {!isPlayer _x}) > 0);
            
             
            private _idGhost = _player getVariable ["MISSION_var_actGhost", -1];
            private _idVigilance = _player getVariable ["MISSION_var_actVigilance", -1];
            private _idAssault = _player getVariable ["MISSION_var_actAssault", -1];

            if (_isLeader && _hasAI) then {
                
                 
                 
                if (combatMode _group != "BLUE") then {
                    if (_idGhost == -1) then {
                        _idGhost = _player addAction [
                            localize "STR_ORDER_GHOST",
                            {
                                params ["_target", "_caller"];
                                (group _caller) setCombatMode "BLUE";
                                (group _caller) setBehaviour "STEALTH";
                                hint (localize "STR_HINT_GHOST");
                                 
                            },
                            nil, 1.5, false, true, "", 
                            "combatMode (group player) != 'BLUE'"
                        ];
                        _player setVariable ["MISSION_var_actGhost", _idGhost];
                    };
                } else {
                     
                    if (_idGhost != -1) then {
                        _player removeAction _idGhost;
                        _player setVariable ["MISSION_var_actGhost", -1];
                    };
                };

                 
                 
                if (combatMode _group != "YELLOW") then {
                    if (_idVigilance == -1) then {
                        _idVigilance = _player addAction [
                            localize "STR_ORDER_VIGILANCE",
                            {
                                params ["_target", "_caller"];
                                (group _caller) setCombatMode "YELLOW";
                                (group _caller) setBehaviour "AWARE";
                                hint (localize "STR_HINT_VIGILANCE");
                            },
                            nil, 1.5, false, true, "", 
                            "combatMode (group player) != 'YELLOW'"
                        ];
                        _player setVariable ["MISSION_var_actVigilance", _idVigilance];
                    };
                } else {
                    if (_idVigilance != -1) then {
                        _player removeAction _idVigilance;
                        _player setVariable ["MISSION_var_actVigilance", -1];
                    };
                };

                 
                 
                if (combatMode _group != "RED") then {
                    if (_idAssault == -1) then {
                        _idAssault = _player addAction [
                            localize "STR_ORDER_ASSAULT",
                            {
                                params ["_target", "_caller"];
                                (group _caller) setCombatMode "RED";
                                (group _caller) setBehaviour "COMBAT";
                                hint (localize "STR_HINT_ASSAULT");
                            },
                            nil, 1.5, false, true, "", 
                            "combatMode (group player) != 'RED'"
                        ];
                        _player setVariable ["MISSION_var_actAssault", _idAssault];
                    };
                } else {
                    if (_idAssault != -1) then {
                        _player removeAction _idAssault;
                        _player setVariable ["MISSION_var_actAssault", -1];
                    };
                };

            } else {
                 
                if (_idGhost != -1) then { _player removeAction _idGhost; _player setVariable ["MISSION_var_actGhost", -1]; };
                if (_idVigilance != -1) then { _player removeAction _idVigilance; _player setVariable ["MISSION_var_actVigilance", -1]; };
                if (_idAssault != -1) then { _player removeAction _idAssault; _player setVariable ["MISSION_var_actAssault", -1]; };
            };
        } else {
              
        };
    };
};
