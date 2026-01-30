/*
    Author: Kevin
    Description:
    Ajuste l'identité (visage et voix) des civils femmes (Burqa, Dress, woman)
    dans un rayon de 550m autour des joueurs.
    S'exécute toutes les 45 secondes.
    VOIX : Farsi (Male01PER, Male02PER, Male03PER) avec Pitch 1.2 ou 1.4
    VISAGE : max_female1 à max_female17
    NOM : Un des 100 noms féminins
*/

if (!isServer) exitWith {};

while {true} do {
    // Récupérer tous les joueurs (y compris les machines clientes en MP)
    private _players = allPlayers;
    
    // Optimisation : Ne scanne que si des joueurs sont présents
    if (count _players > 0) then {
        
        // Trouver toutes les entités civiles/ennemies dans un rayon de 550m autour de chaque joueur
        private _unitsToProcess = [];
        
        {
            private _p = _x;
            private _nearUnits = _p nearEntities ["Man", 550];
            {
                if (!(_x in _unitsToProcess)) then {
                    _unitsToProcess pushBack _x;
                };
            } forEach _nearUnits;
        } forEach _players;
        
        // Traiter chaque unité trouvée
        {
            private _unit = _x;
            
            // Vérifier si l'identité a déjà été forcée
            if (!(_unit getVariable ["Mission_var_identitySet", false])) then {
                
                private _uniform = toLower (uniform _unit);
                private _name = toLower (name _unit); // Attention: name retourne le nom "ingame" pas le classname
                private _unitNameVar = toLower (vehicleVarName _unit); // Nom de variable dans l'éditeur
                private _strUnit = str _unit; // Représentation string pour debug ou check
                
                // Critères de détection:
                // 1. Côté : Civil, OPFOR, Indépendant
                if (side _unit in [civilian, east, independent]) then {
                     
                    // Critères de détection femme : 
                    // 1. Uniforme contient "burqa" ou "dress"
                    // 2. Nom de variable ou d'unité contient "woman"
                    if (
                        (_uniform find "burqa" > -1) || 
                        (_uniform find "dress" > -1) || 
                        (_uniform find "woman" > -1) || 
                        (_unitNameVar find "woman" > -1) ||
                        (["woman", _name] call BIS_fnc_inString) 
                    ) then {
                        
                        // --- CHANGEMENT IDENTITE ---
                    
                    // 1. Visage : max_female1 à max_female17
                    // Générer un nombre aléatoire entre 1 et 17
                    private _faceIndex = floor (random 17) + 1; 
                    private _faceName = format ["max_female%1", _faceIndex];
                    
                    // Appliquer visage
                    [_unit, _faceName] remoteExec ["setFace", 0, _unit];
                    
                    // 2. Voix : Perse (Farsi) avec Pitch élevé
                    // Arma 3 Vanilla Persian speakers: Male01PER, Male02PER, Male03PER
                    private _speakers = ["Male01PER", "Male02PER", "Male03PER"];
                    private _selectedSpeaker = selectRandom _speakers;
                    
                    [_unit, _selectedSpeaker] remoteExec ["setSpeaker", 0, _unit];
                    
                    // 3. Pitch : 1.2 ou 1.4
                    private _pitch = selectRandom [1.2, 1.4];
                    [_unit, _pitch] remoteExec ["setPitch", 0, _unit];
                    
                    // 4. Nom Féminin
                    private _names = [
                        "Aadila Nouri", "Aaliyah Massoud", "Amani Rahimi", "Anahita Ratebzad", "Anisa Wahab",
                        "Arezoo Tanha", "Aryana Sayeed", "Asma Jahangir", "Atefa Mamanoor", "Aziza Siddiqui",
                        "Bahar Pars", "Banu Ghazanfar", "Baran Kosari", "Behnaz Jafari", "Benafsha Yaqoobi",
                        "Bibi Aisha", "Bushra Maneka", "Darya Safai", "Deana Uppal", "Delaram Karkhir",
                        "Donya Dadrasan", "Elaha Soroor", "Elham Shahin", "Faiza Darkhani", "Farah Pahlavi",
                        "Fariba Hachtroudi", "Farkhunda Zahra", "Fatima Bhutto", "Fawzia Koofi", "Fereshteh Kazemi",
                        "Forough Farrokhzad", "Freshta Karim", "Ghazal Sadat", "Golshifteh Farahani", "Googoosh Atashin",
                        "Habiba Sarabi", "Haifa Wehbe", "Hamida Barmaki", "Hania Amir", "Hasina Safi",
                        "Hawa Alam", "Hayat Mirshad", "Hediyeh Tehrani", "Hina Rabbani", "Homira Qaderi",
                        "Huda Kattan", "Jamila Afghani", "Kamila Sidiqi", "Kubra Khademi", "Laila Freivalds",
                        "Latifa Nabizada", "Leena Alam", "Leila Hatami", "Lina Ben Mhenni", "Mahbouba Seraj",
                        "Mahira Khan", "Malalai Joya", "Manal al-Sharif", "Mariam Ghani", "Marjane Satrapi",
                        "Maryam Monsef", "Massouda Jalal", "Meena Keshwar", "Mehrenegar Rostami", "Mina Mangal",
                        "Mitra Hajjar", "Mozhdah Jamalzadah", "Muniba Mazari", "Nadia Anjuman", "Nahid Persson",
                        "Nargis Fakhri", "Nasrin Sotoudeh", "Nelofer Pazira", "Niki Karimi", "Niloufar Ardalan",
                        "Noor Jehan", "Parvin Etesami", "Qamar Gul", "Rabea Balkhi", "Rahima Jami",
                        "Rola Ghani", "Roya Mahboob", "Saba Qamar", "Sahraa Karimi", "Sajal Aly",
                        "Samira Makhmalbaf", "Sanam Baloch", "Sarah Shahi", "Seeta Qasemi", "Shabana Azmi",
                        "Shaharzad Akbar", "Shirin Ebadi", "Shukria Barakzai", "Sima Samar", "Soheila Siddiq",
                        "Soraya Tarzi", "Tahmineh Milani", "Taraneh Alidoosti", "Yasmin Levy", "Zarifa Ghafari"
                    ];
                    
                    private _randomName = selectRandom _names;
                    private _nameParts = _randomName splitString " ";
                    private _firstName = _nameParts select 0;
                    private _lastName = "";
                    if (count _nameParts > 1) then {
                         _lastName = _nameParts select 1;
                    };
                    
                    // Appliquer le nom globalement
                    // Syntax: unit setName [name, firstName, lastName]
                    [_unit, [_randomName, _firstName, _lastName]] remoteExec ["setName", 0, _unit];

                    // Marquer comme traité
                    _unit setVariable ["Mission_var_identitySet", true, true];
                    
                    // Debug (Optionnel)
                    // diag_log format ["WOMAN IDENTITY APPLIED: %1 | Face: %2 | Name: %3", _unit, _faceName, _randomName];
                };
             };
            };
        } forEach _unitsToProcess;
    };
    
    // Attendre 45 secondes avant le prochain scan
    sleep 45;
};
