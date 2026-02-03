/*
    File: fn_spawn_vehicles_cam.sqf
    Author: Kevin
    Description: 
        Gère l'affichage de la caméra de sécurité sur le tableau vidéo.
        La caméra est créée à la position de 'camera_projecteur' et regarde vers 'vehicles_spawner_1'.
        L'affichage s'active quand un joueur est dans 'vehicles_request_2'.
        Optimisé pour réduire la charge client.
*/

if (!hasInterface) exitWith {};

[] spawn {
    // Attente des objets nécessaires
    waitUntil {
        sleep 1;
        !isNil "vehicles_request_2" && 
        !isNil "tableau_video" && 
        !isNil "camera_projecteur" && 
        !isNil "vehicles_spawner_1"
    };

    // Initialisation du tableau en noir
    tableau_video setObjectTexture [0, "#(argb,8,8,3)color(0,0,0,1)"];

    private _cam = objNull;
    private _renderTarget = "rtt_vehicle_cam";
    
    // Boucle principale optimisée
    while {true} do {
        // Vérification si le joueur est dans la zone
        // On utilise 'sleep' pour ne pas surcharger le scheduler
        waitUntil {
            sleep 1; 
            player inArea vehicles_request_2
        };

        // Création de la caméra
        if (isNull _cam) then {
            private _camPos = getPosATL camera_projecteur;
            _camPos set [2, (_camPos select 2) + 0.5]; 
            _cam = "camera" camCreate _camPos;
            _cam cameraEffect ["Internal", "Back", _renderTarget];
            _cam camPrepareTarget vehicles_spawner_1;
            _cam camCommitPrepared 0;
            
            // Assignation de la texture au tableau
            // Utilisation de la texture RTT (Render Target Texture)
            tableau_video setObjectTexture [0, format ["#(argb,512,512,1)r2t(%1,1.0)", _renderTarget]];
        };

        // Tant que le joueur est dans la zone, on maintient la caméra
        // On verifie moins souvent une fois la cam active
        waitUntil {
            sleep 2;
            !(player inArea vehicles_request_2)
        };

        // Désactivation
        _cam cameraEffect ["TERMINATE", "BACK"];
        camDestroy _cam;
        _cam = objNull;
        
        // Remise au noir du tableau
        tableau_video setObjectTexture [0, "#(argb,8,8,3)color(0,0,0,1)"];
    };
};
