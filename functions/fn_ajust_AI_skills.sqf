/*
    Description: Ajuste les compétences des IA (OPFOR, INDEP, BLUFOR) chaque minute.
*/

while {true} do {
    {
        // Traitement des unités VIVANTES, LOCALES et NON-JOUEURS
        // local _x : Indispensable pour que setSkill fonctionne (effet local)
        // !isPlayer _x : Inutile de régler les skills d'un joueur humain
        if (alive _x && {local _x} && {!isPlayer _x}) then {
            private _side = side _x;
            
            // --- Ajustement OPFOR & INDEPENDANT (Ennemis / Insurgés) ---
            // Compétences volontairement plus basses pour simuler un manque d'entraînement
            if (_side == east || _side == independent) then {
                _x setSkill ["aimingAccuracy", 0.10 + random 0.15];   // Précision faible : 0.10 -> 0.25 (Variable à chaque boucle)
                _x setSkill ["aimingShake",   0.10 + random 0.20];   // Stabilité : 0.10 -> 0.30
                _x setSkill ["aimingSpeed",   0.10 + random 0.30];   // Vitesse : 0.10 -> 0.40
                _x setSkill ["spotDistance",  0.10 + random 0.50];   // Repérage : 0.10 -> 0.60
                _x setSkill ["spotTime",      0.10 + random 0.40];   // Réflexe : 0.10 -> 0.50
                _x setSkill ["courage", 1];
                _x setSkill ["reloadSpeed", 0.6];
                _x setSkill ["commanding", 0.4];
                _x setSkill ["general", 0.5];
                _x allowFleeing 0;
            };

            // --- Ajustement BLUFOR (Alliés / Soldats Pro) ---
            // Compétences élevées pour simuler des soldats entraînés
            if (_side == west) then {
                _x setSkill ["aimingAccuracy", 0.35 + random 0.15];   // Précision correcte : 0.35 -> 0.50 (Variable à chaque boucle)
                _x setSkill ["aimingShake",   0.40 + random 0.20];   // Stabilité : 0.40 -> 0.60
                _x setSkill ["aimingSpeed",   0.40 + random 0.20];   // Vitesse : 0.40 -> 0.60
                _x setSkill ["spotDistance",  0.60 + random 0.20];   // Repèrent de loin : 0.60 -> 0.80
                _x setSkill ["spotTime",      0.65 + random 0.10];   // Réflexe : 0.65 -> 0.75
                _x setSkill ["courage", 1];
                _x setSkill ["reloadSpeed", 0.75];
                _x setSkill ["commanding", 0.6];
                _x setSkill ["general", 0.65];
                _x allowFleeing 0;
            };
        };
    } forEach allUnits;

    // Pause de 60 secondes avant le prochain cycle
    // Chaque machine gère ses propres unités indépendamment
    sleep 60;
};
