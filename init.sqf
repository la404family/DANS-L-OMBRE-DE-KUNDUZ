// EXPERT SQF arma3 -- code optimisé pour jeux multijoueurs et solo
// MIssion arma 3 unités françaises et jargon militaire français
// Nom de la mission : Operation PAMIR - Dans l'ombre de Kunduz
// player_0 à player_4 sont les unités joueur ou jouables
// waypoint_invisible_000 à waypoint_invisible_340 sont des road_invisible CUP_A1_Road_road_invisible pour déterminer le lieu des missions.
// civil_template_00  à civil_template_33 sont des civils dans l'éditeur qui servent de templates pour les civils
// ezan_00 à ezan_09 sont des haut parleur de type : Loudspeaker
// waypoint_livraison_000 à waypoint_livraison_127 sont des waypoints pour déterminer des points où l'hélicoptère peut atterir en sécurité
// balade_officier_0 à balade_officier_8 sont des héliports de placement pour le déplacement des officiers.
// officier_0 et officier_1 sont des officiers.
// chaise_officier_0 est la chaise de officier_0
// chaise_officier_1 est la chaise de officier_1
// tableau_video est un tableau qui affiche la vidéo
// camera_projecteur est un projecteur qui fait officie de caméra


systemChat ">>> INIT MISSION START <<<";
if (isServer) then {
    MISSION_var_helicopters = [
        ["task_x_helicoptere", "amf_nh90_tth_transport", "Huron Intro", 0, 0, []]
    ];
    [] spawn Mission_fnc_task_intro;
    [] spawn Mission_fnc_ajuste_badge;
    call Mission_fnc_civilian_template;
    [] spawn Mission_fnc_civilian_presence_logic;
    [] spawn Mission_fnc_ezan;
    [] spawn Mission_fnc_spawn_vehicles;
    [] spawn Mission_fnc_ajust_AI_skills;
    [] spawn Mission_fnc_ajust_team_leader;
    [] spawn Mission_fnc_task_fin;
    [] spawn Mission_fnc_ajust_BLUFOR_identity;
    [] spawn Mission_fnc_officier_balade;
    //--------------------------------------
    // TACHES DE MISSION ! 
    //--------------------------------------

    //[] spawn Mission_fnc_task01;
    //[] spawn Mission_fnc_task02;
    [] spawn Mission_fnc_task03;
};
if (hasInterface) then {
    waitUntil {!isNull player};
    [] spawn Mission_fnc_spawn_vehicles_cam;
    ["INIT"] spawn Mission_fnc_spawn_arsenal;
    ["INIT"] spawn Mission_fnc_spawn_weather_and_time;
    ["INIT"] spawn Mission_fnc_spawn_brothers_in_arms;
    [] spawn Mission_fnc_addAction_heal;
    [] spawn Mission_fnc_addAction_search;
    [] spawn Mission_fnc_addAction_engagement;
};
["INIT"] spawn Mission_fnc_livraison_gestion;
