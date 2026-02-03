 

if (!hasInterface) exitWith {};

[] spawn {
     
    waitUntil {
        sleep 1;
        !isNil "vehicles_request_2" && 
        !isNil "tableau_video" && 
        !isNil "camera_projecteur" && 
        !isNil "vehicles_spawner_1"
    };

     
    tableau_video setObjectTexture [0, "#(argb,8,8,3)color(0,0,0,1)"];

    private _cam = objNull;
    private _renderTarget = "rtt_vehicle_cam";
    
     
    while {true} do {
         
         
        waitUntil {
            sleep 1; 
            player inArea vehicles_request_2
        };

         
        if (isNull _cam) then {
            private _camPos = getPosATL camera_projecteur;
            _camPos set [2, (_camPos select 2) + 0.5]; 
            _cam = "camera" camCreate _camPos;
            _cam cameraEffect ["Internal", "Back", _renderTarget];
            _cam camPrepareTarget vehicles_spawner_1;
            _cam camCommitPrepared 0;
            
             
             
            tableau_video setObjectTexture [0, format ["#(argb,512,512,1)r2t(%1,1.0)", _renderTarget]];
        };

         
         
        waitUntil {
            sleep 2;
            !(player inArea vehicles_request_2)
        };

         
        _cam cameraEffect ["TERMINATE", "BACK"];
        camDestroy _cam;
        _cam = objNull;
        
         
        tableau_video setObjectTexture [0, "#(argb,8,8,3)color(0,0,0,1)"];
    };
};
