 

if (!hasInterface) exitWith {};

 
[] spawn {
    private _fnc_addHealAction = {
        params ["_unit"];
        
         
        if (_unit getVariable ["MISSION_Action_Heal_Added", false]) exitWith {};
        _unit setVariable ["MISSION_Action_Heal_Added", true];

        _unit addAction [
            localize "STR_ACTION_HEAL",  
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                
                private _unitsHealed = 0;
                private _unitsNeedHealButNoKit = 0;

                 
                private _aiUnits = (units group _caller) select { !isPlayer _x && alive _x };

                {
                     
                    if (damage _x > 0.1) then {
                        
                         
                        if ("FirstAidKit" in items _x || "Medikit" in items _x) then {
                            _x action ["HealSoldierSelf", _x];
                            _unitsHealed = _unitsHealed + 1;
                        } else {
                            _unitsNeedHealButNoKit = _unitsNeedHealButNoKit + 1;
                        };
                    };
                } forEach _aiUnits;

                 
                if (_unitsHealed > 0) then {
                    hint format ["Ordre de soin exécuté par %1 IA(s).", _unitsHealed];
                } else {
                    if (_unitsNeedHealButNoKit > 0) then {
                        hint "Attention : Des IA sont blessées mais manquent de kits de soin !";
                    } else {
                        hint "Aucune IA ne nécessite de soins urgents (>10% dégâts).";
                    };
                };
            },
            [],
            1.5, 
            false, 
            true, 
            "", 
             
            "leader group _target == _target && (count (units group _target select {!isPlayer _x}) > 0)"
        ];
    };

     
    private _lastPlayer = objNull;
    while {true} do {
        waitUntil { player != _lastPlayer };  
        
        _lastPlayer = player;
        if (!isNull _lastPlayer) then {
            [_lastPlayer] call _fnc_addHealAction;
        };
    };
};
