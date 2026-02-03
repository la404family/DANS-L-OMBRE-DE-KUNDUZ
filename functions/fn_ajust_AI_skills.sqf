while {true} do {
    {
        if (alive _x && {local _x} && {!isPlayer _x}) then {
            private _side = side _x;
            if (_side == east || _side == independent) then {
                _x setSkill ["aimingAccuracy", 0.10 + random 0.15];    
                _x setSkill ["aimingShake",   0.10 + random 0.20];    
                _x setSkill ["aimingSpeed",   0.10 + random 0.30];    
                _x setSkill ["spotDistance",  0.10 + random 0.50];    
                _x setSkill ["spotTime",      0.10 + random 0.40];    
                _x setSkill ["courage", 1];
                _x setSkill ["reloadSpeed", 0.6];
                _x setSkill ["commanding", 0.4];
                _x setSkill ["general", 0.5];
                _x allowFleeing 0;
            };
            if (_side == west) then {
                _x setSkill ["aimingAccuracy", 0.35 + random 0.15];    
                _x setSkill ["aimingShake",   0.40 + random 0.20];    
                _x setSkill ["aimingSpeed",   0.40 + random 0.20];    
                _x setSkill ["spotDistance",  0.60 + random 0.20];    
                _x setSkill ["spotTime",      0.65 + random 0.10];    
                _x setSkill ["courage", 1];
                _x setSkill ["reloadSpeed", 0.75];
                _x setSkill ["commanding", 0.6];
                _x setSkill ["general", 0.65];
                _x allowFleeing 0;
            };
        };
    } forEach allUnits;
    sleep 60;
};
