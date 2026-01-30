// EXPERT SQF arma3 -- code optimisé pour jeux multijoueurs et solo
// MIssion arma 3 unités françaises et jargon militaire français
// Nom de la mission : Operation PAMIR - Dans l'ombre de Kunduz
// player_0 à player_4 sont les unités joueur ou jouables
// waypoint_invisible_000 à waypoint_invisible_340 sont des road_invisible CUP_A1_Road_road_invisible pour déterminer le lieu des missions.
// civil_template_00  à civil_template_28 sont des civils dans l'éditeur qui servent de templates pour les civils
// ezan_00 à ezan_09 sont des haut parleur de type : Loudspeaker
// waypoint_livraison_000 à waypoint_livraison_127 sont des waypoints pour déterminer des points où l'hélicoptère peut atterir en sécurité


if (isServer) then {
    // INIT VARIABLES
    MISSION_var_helicopters = [
        ["task_x_helicoptere", "amf_nh90_tth_transport", "Huron Intro", 0, 0, []]
    ];
    
    // Définir le modèle d'équipement basé sur le joueur actuel (ou player_0 si défini dans l'éditeur)
    private _p = if (!isNil "player_0") then { player_0 } else { player };
    MISSION_var_model_player = [
        ["model_player", "", "", "", "", getUnitLoadout _p] 
    ];

    // Appel à la prière des ezan
    [] spawn Mission_fnc_ezan;

    // Mémorisation des gabarits civils (Templates civil_template_XX)
    call Mission_fnc_civilian_template;

    // Appel à l'introduction cinématique
    // [] spawn Mission_fnc_task_intro; 

    // Appel à la fonction de spawn des véhicules
    [] spawn Mission_fnc_spawn_vehicles;
    
    // Appel à la gestion des compétences IA
    [] spawn Mission_fnc_ajust_AI_skills;
    
    // Appel à la logique civile
    [] spawn Mission_fnc_civilian_logique;
    
    // Gestion automatique du Team Leader (IA -> Joueur)
    [] spawn Mission_fnc_ajust_team_leader;
    
    // Système de fin de mission (Extraction)
    [] spawn Mission_fnc_task_fin;
    
    // Modif Identité BLUFOR
    [] spawn Mission_fnc_ajust_BLUFOR_identity;
    
    // Modif Identité OPFOR / IND / CIV (Désactivé - remplacé par fn_apply_civilian_profile)
    // [] spawn Mission_fnc_ajust_OTHER_identity;
    
    // Modif Identité et voix FEMME (Burqa/Dress) (Désactivé - remplacé par fn_apply_civilian_profile)
    // [] spawn Mission_fnc_ajust_WOMAN_identity;


    // Force badge France AMF
    [] spawn Mission_fnc_ajuste_badge;

    // Appel à la livraison de véhicule (TEST SERVEUR UNIQUEMENT - A COMMENTER EN PROD)
    // [getPos _p] spawn Mission_fnc_livraison_vehicule;
    // ------------------------------
    // --- TACHES DE LA MISSION ---
    // ------------------------------
    // Appel au changement de civil en insurgé
    // [] spawn Mission_fnc_task_insurg;

    // Appel au sauvetage d'otage
    [] spawn Mission_fnc_task_ostage;
};

// --- CLIENT (JOUEUR) UNIQUEMENT ---
if (hasInterface) then {
    // Attendre que le joueur soit initialisé
    waitUntil {!isNull player};
    
    // Ajouter les options au menu Support (0-8)
    // Désactivé ici car géré dynamiquement par fn_ajust_team_leader.sqf
    // [player, "VehicleDrop"] call BIS_fnc_addCommMenuItem;
    // [player, "AmmoDrop"] call BIS_fnc_addCommMenuItem;
    // [player, "CASDrop"] call BIS_fnc_addCommMenuItem;
    
    // Message de bienvenue (Optionnel)
    // systemChat "Support logistique disponible (Menu 0-8)";
};