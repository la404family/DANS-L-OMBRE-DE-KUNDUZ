
 

 
params [["_mode", ""], ["_params", []]];

 
switch (_mode) do {
     
     
     
    case "INIT": {
         
        if (!hasInterface) exitWith {};
        
         
        waitUntil { !isNull player };
        
         
        player addAction [
            localize "STR_ACTION_ARSENAL",  
            {
                 
                 
                ["Open", [true]] call BIS_fnc_arsenal;
            },
            [],
            1.5, 
            true, 
            true, 
            "",
            "player inArea arsenal_request"  
        ];
        
         
         
         
         
        [] spawn {
            private _wasInArea = false;
            
            while {true} do {
                sleep 0.5;
                
                 
                if (isNil "arsenal_request") then {
                    continue;
                };
                
                 
                private _isInArea = player inArea arsenal_request;
                
                 
                if (_wasInArea && !_isInArea) then {
                     
                    ["SYNC", [player]] call MISSION_fnc_spawn_arsenal;
                };
                
                 
                _wasInArea = _isInArea;
            };
        };
    };

     
     
     
    case "SYNC": {
        _params params [["_unit", objNull]];
        
         
        if (isNull _unit) exitWith {};
        if (!alive _unit) exitWith {};
        
         
        if (leader group _unit != _unit) exitWith {};
        
         
        private _speakerClass = speaker _unit;
        
         
        if (_speakerClass == "") exitWith {};
        
         
         
         
        {
            if (!isPlayer _x && alive _x) then {
                _x setSpeaker _speakerClass;
            };
        } forEach (units group _unit);
        
         
         
         
         
        [[_unit, _speakerClass], {
            params ["_leader", "_voiceClass"];
            
             
            if (!hasInterface) exitWith {};
            if (isNull player) exitWith {};
            
             
            if (side player == side _leader) then {
                player setSpeaker _voiceClass;
                
                 
                {
                    if (!isPlayer _x && alive _x && local _x) then {
                        _x setSpeaker _voiceClass;
                    };
                } forEach (units group player);
            };
        }] remoteExec ["call", 0];
    };
};
