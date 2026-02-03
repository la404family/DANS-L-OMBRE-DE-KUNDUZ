if (!isServer) exitWith {};

private _waypoints = [];
for "_i" from 0 to 8 do {
    private _varName = format ["balade_officier_%1", _i];
    private _obj = missionNamespace getVariable [_varName, objNull];
    if (!isNull _obj) then { _waypoints pushBack _obj; };
};
if (count _waypoints == 0) exitWith { systemChat "ERREUR: Aucun point balade_officier trouvés !"; };

private _fnc_gerer_officier = {
    params ["_unit", "_chair", "_watchTarget", "_otherUnit", "_waypoints", "_sitOffset"];
    
    if (isNull _unit) exitWith {};

    _unit allowDamage false;
    _unit setCaptive true;
    _unit setBehaviour "CARELESS";
    _unit setCombatMode "BLUE";
    _unit disableAI "AUTOTARGET";
    _unit disableAI "TARGET";
    _unit disableAI "FSM"; 
    _unit disableAI "SUPPRESSION";
    _unit disableAI "COVER";
    _unit disableAI "AUTOCOMBAT";
    
    _unit setVariable ["Mission_Panic", false];
    
    if (currentWeapon _unit != "") then { _unit action ["SwitchWeapon", _unit, _unit, 100]; };
    
    _unit addEventHandler ["FiredNear", {
        params ["_unit"];
        if !(_unit getVariable ["Mission_Panic", false]) then {
            _unit setVariable ["Mission_Panic", true];
            _unit doMove (getPos _unit); 
        };
    }];

    while {alive _unit} do {
        
        private _speed = if (_unit getVariable ["Mission_Panic", false]) then {"FULL"} else {"LIMITED"};
        _unit setSpeedMode _speed;
        if (currentWeapon _unit != "") then { _unit action ["SwitchWeapon", _unit, _unit, 100]; }; 

        _unit doMove (getPos _chair);
        
        waitUntil {sleep 1; (_unit distance _chair) < 2 || !alive _unit};
        if (!alive _unit) exitWith {};

        _unit setVariable ["Mission_Panic", false]; 
        _unit setSpeedMode "LIMITED"; 
        _unit disableAI "MOVE"; 
        _unit setPos (getPos _chair);
        _unit setDir (getDir _chair + _sitOffset);
        _unit switchMove "HubSittingChairC_idle1";
        
        if (!isNull _watchTarget) then { _unit doWatch _watchTarget; _unit lookAt _watchTarget; };

        for "_k" from 1 to 180 do {
            sleep 1;
            if (!alive _unit) exitWith {};
            if (!isNull _watchTarget) then { _unit doWatch _watchTarget; };
            if (animationState _unit != "HubSittingChairC_idle1") then { _unit switchMove "HubSittingChairC_idle1"; };
        };
        
        _unit switchMove "AmovPercMstpSnonWnonDnon";
        sleep 2; 
        _unit enableAI "MOVE"; 
        _unit doWatch objNull; 
        _unit setUnitPos "UP"; 

        private _nb_points = 3 + floor(random 3);
        
        for "_i" from 1 to _nb_points do {
            if (_unit getVariable ["Mission_Panic", false]) exitWith {}; 
            
            private _targetObj = selectRandom _waypoints;
            _unit doMove (getPos _targetObj);
            
            private _arrived = false;
            private _abortMove = false;
            private _timeout = time + 120;
            
            waitUntil {
                sleep 0.5;
                if (!alive _unit) exitWith {true};
                
                if (_unit getVariable ["Mission_Panic", false]) exitWith {_abortMove = true; true};
                
                if ((_unit distance _targetObj) < 2) exitWith {_arrived = true; true};
                if (time > _timeout) exitWith {true};
                
                false
            };
            
            if (_abortMove) exitWith {};
        };
        
        sleep 0.1;
    };
};

[
    officier_0, chaise_officier_0, missionNamespace getVariable ["dossier_0", objNull], 
    officier_1, _waypoints, 180
] spawn _fnc_gerer_officier;

sleep 5;

[
    officier_1, chaise_officier_1, missionNamespace getVariable ["ordinateur_1", objNull], 
    officier_0, _waypoints, 0
] spawn _fnc_gerer_officier;
