if (!isServer) exitWith {};  
private _soundRange = 2500;  
private _minaretsVars = ["ezan_00", "ezan_01", "ezan_02"];
sleep (300 + (random 600));
while {true} do {
    {
        private _varName = _x;
        private _minaretObj = missionNamespace getVariable [_varName, objNull];
        if (!isNull _minaretObj) then {
            private _nearbyPlayers = allPlayers select { (_x distance _minaretObj) < _soundRange };
            if (count _nearbyPlayers > 0) then {
                [_minaretObj, ["ezan", _soundRange, 1]] remoteExec ["say3D", _nearbyPlayers];
            };
        };
        sleep 0.05;
    } forEach _minaretsVars;
    sleep 1800;
};