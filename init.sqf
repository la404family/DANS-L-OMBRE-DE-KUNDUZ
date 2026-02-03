systemChat ">>> INIT MISSION START <<<";
if (isServer) then {
    MISSION_var_helicopters = [
        ["task_x_helicoptere", "amf_nh90_tth_transport", "Huron Intro", 0, 0, []]
    ];
    [] spawn Mission_fnc_ajuste_badge;
    call Mission_fnc_civilian_template;
    [] spawn Mission_fnc_civilian_presence_logic;
    [] spawn Mission_fnc_ezan;
    [] spawn Mission_fnc_spawn_vehicles;
    [] spawn Mission_fnc_ajust_AI_skills;
    [] spawn Mission_fnc_ajust_team_leader;
    [] spawn Mission_fnc_task_fin;
    [] spawn Mission_fnc_ajust_BLUFOR_identity;
    [] spawn Mission_fnc_task_ostage;
};
if (hasInterface) then {
    waitUntil {!isNull player};
};
["INIT"] spawn Mission_fnc_livraison_gestion;
