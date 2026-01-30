/*
    Auteur: Kevin
    Nom: fn_ajust_OTHER_identity.sqf
    Description: Assigne une identité arabe (Visage + Voix Perse) aux OPFOR et Indépendants.
    Vérifie toutes les 10 secondes.
    S'applique UNIQUEMENT aux IA qui ne sont PAS des femmes.
*/

// Liste des noms arabes
// Format: [nom_complet, prénom, nom_famille]
private _names_arab_full = [
    ["Afaq Khan", "Afaq", "Khan"],
    ["Ahd Rahimi", "Ahd", "Rahimi"],
    ["Ahlam Zadran", "Ahlam", "Zadran"],
    ["Akhtar Durrani", "Akhtar", "Durrani"],
    ["Almas Wardak", "Almas", "Wardak"],
    ["Amal Shinwari", "Amal", "Shinwari"],
    ["Amani Popal", "Amani", "Popal"],
    ["Anis Kakar", "Anis", "Kakar"],
    ["Anwar Niazi", "Anwar", "Niazi"],
    ["Aram Ahmadi", "Aram", "Ahmadi"],
    ["Areej Mohammadi", "Areej", "Mohammadi"],
    ["Arya Rostami", "Arya", "Rostami"],
    ["Ashna Karimi", "Ashna", "Karimi"],
    ["Asil Faizi", "Asil", "Faizi"],
    ["Atish Noori", "Atish", "Noori"],
    ["Ava Hashemi", "Ava", "Hashemi"],
    ["Awad Saleh", "Awad", "Saleh"],
    ["Ayin Zare", "Ayin", "Zare"],
    ["Azad Mousavi", "Azad", "Mousavi"],
    ["Azar Hosseini", "Azar", "Hosseini"],
    ["Badr Rezaei", "Badr", "Rezaei"],
    ["Bahar Jafari", "Bahar", "Jafari"],
    ["Baran Sadeghi", "Baran", "Sadeghi"],
    ["Barin Heidari", "Barin", "Heidari"],
    ["Bayan Moradi", "Bayan", "Moradi"],
    ["Dana Ghasemi", "Dana", "Ghasemi"],
    ["Darya Ebrahimi", "Darya", "Ebrahimi"],
    ["Del Amiri", "Del", "Amiri"],
    ["Delaram Taheri", "Delaram", "Taheri"],
    ["Delshad Shams", "Delshad", "Shams"],
    ["Diya Maleki", "Diya", "Maleki"],
    ["Dua Nazari", "Dua", "Nazari"],
    ["Ehsan Habibi", "Ehsan", "Habibi"],
    ["Elham Azimi", "Elham", "Azimi"],
    ["Etidal Sharif", "Etidal", "Sharif"],
    ["Fajr Yousefi", "Fajr", "Yousefi"],
    ["Farah Mahmoudi", "Farah", "Mahmoudi"],
    ["Farhat Saleh", "Farhat", "Saleh"],
    ["Fida Qasemi", "Fida", "Qasemi"],
    ["Firdaws Akbari", "Firdaws", "Akbari"],
    ["Ghali Baghlan", "Ghali", "Baghlan"],
    ["Ghufran Kunduzi", "Ghufran", "Kunduzi"],
    ["Gol Herati", "Gol", "Herati"],
    ["Gul Panjshiri", "Gul", "Panjshiri"],
    ["Hasti Samangani", "Hasti", "Samangani"],
    ["Hawa Balkhi", "Hawa", "Balkhi"],
    ["Hayat Ghazni", "Hayat", "Ghazni"],
    ["Hekmat Logari", "Hekmat", "Logari"],
    ["Hiyam Farah", "Hiyam", "Farah"],
    ["Huda Badakhshi", "Huda", "Badakhshi"],
    ["Hur Takhar", "Hur", "Takhar"],
    ["Ikhlas Sarwari", "Ikhlas", "Sarwari"],
    ["Ikram Hotak", "Ikram", "Hotak"],
    ["Ilham Barakzai", "Ilham", "Barakzai"],
    ["Iman Alizai", "Iman", "Alizai"],
    ["Inayat Ghilzai", "Inayat", "Ghilzai"],
    ["Intisar Ahmadzai", "Intisar", "Ahmadzai"],
    ["Iqbal Orakzai", "Iqbal", "Orakzai"],
    ["Irfan Yusufzai", "Irfan", "Yusufzai"],
    ["Ismat Momand", "Ismat", "Momand"],
    ["Ithar Waziri", "Ithar", "Waziri"],
    ["Izzat Mehsud", "Izzat", "Mehsud"],
    ["Jahan Khyber", "Jahan", "Khyber"],
    ["Jan Afridi", "Jan", "Afridi"],
    ["Janan Bangash", "Janan", "Bangash"],
    ["Jihad Turi", "Jihad", "Turi"],
    ["Joud Khattak", "Joud", "Khattak"],
    ["Karam Mangal", "Karam", "Mangal"],
    ["Kawsar Safi", "Kawsar", "Safi"],
    ["Khurshid Tanai", "Khurshid", "Tanai"],
    ["Kian Zazai", "Kian", "Zazai"],
    ["Lian Tani", "Lian", "Tani"],
    ["Mah Sabari", "Mah", "Sabari"],
    ["Mahan Chamkani", "Mahan", "Chamkani"],
    ["Malak Gorbaz", "Malak", "Gorbaz"],
    ["Manar Ismail", "Manar", "Ismail"],
    ["Maram Haq", "Maram", "Haq"],
    ["Mehr Din", "Mehr", "Din"],
    ["Mina Shah", "Mina", "Shah"],
    ["Misbah Ullah", "Misbah", "Ullah"],
    ["Muna Yar", "Muna", "Yar"],
    ["Munir Zai", "Munir", "Zai"],
    ["Naba Gul", "Naba", "Gul"],
    ["Najah Sher", "Najah", "Sher"],
    ["Najwa Mir", "Najwa", "Mir"],
    ["Nakisa Wali", "Nakisa", "Wali"],
    ["Nasim Jan", "Nasim", "Jan"],
    ["Nawal Dad", "Nawal", "Dad"],
    ["Nawar Bai", "Nawar", "Bai"],
    ["Niaz Baig", "Niaz", "Baig"],
    ["Nidal Bakhsh", "Nidal", "Bakhsh"],
    ["Nihal Dost", "Nihal", "Dost"],
    ["Nimat Yar", "Nimat", "Yar"],
    ["Noor Zadah", "Noor", "Zadah"],
    ["Parvaz Shah", "Parvaz", "Shah"],
    ["Payam Khel", "Payam", "Khel"],
    ["Qamar Zai", "Qamar", "Zai"],
    ["Qismat Khan", "Qismat", "Khan"],
    ["Rabab Alvi", "Rabab", "Alvi"],
    ["Raha Shirazi", "Raha", "Shirazi"]
];

// Fonction locale pour appliquer l'identité à une unité
private _fnc_applyIdentity = {
    params ["_unit", "_nameData", "_selectedFace", "_selectedSpeaker", ["_clothingData", []]];
    
    if (isNull _unit || !alive _unit) exitWith {};
    
    // Appliquer l'habillage civil si disponible
    if !(_clothingData isEqualTo []) then {
        _clothingData params ["_uniform", "_facewear", "_headgear"];
        
        // On change l'uniforme (forceAddUniform conserve les items si possible)
        if (_uniform != "") then { _unit forceAddUniform _uniform; };
        
        removeGoggles _unit;
        if (_facewear != "") then { _unit addGoggles _facewear; };
        
        removeHeadgear _unit;
        if (_headgear != "") then { _unit addHeadgear _headgear; };
    };
    
    // Extraire les données du nom
    _nameData params ["_fullName", "_firstName", "_lastName"];
    
    // Appliquer le visage
    _unit setFace _selectedFace;
    
    // Appliquer le nom
    _unit setName [_fullName, _firstName, _lastName];
    
    // Appliquer la voix Perse
    _unit setSpeaker _selectedSpeaker;
    
    // Forcer la mise à jour de l'identité
    _unit setIdentity "";
    
    // Supprimer les Vision Nocturne (NVG)
    private _nvg = hmd _unit;
    if (_nvg != "") then {
        _unit unlinkItem _nvg;
        _unit removeItems _nvg;
    };
};

// Fonction pour traiter l'unité
private _fnc_processUnit = {
    params ["_unit", "_names_list", "_fnc_applyIdentity"];
    
    // Sélectionner un nom aléatoire
    private _selectedName = selectRandom _names_list;
    
    // Sélectionner un visage Arabe/Perse
    private _faces = [
        "PersianHead_A3_01","PersianHead_A3_02","PersianHead_A3_03",
        "GreekHead_A3_01","GreekHead_A3_02","GreekHead_A3_03",
        "GreekHead_A3_04","GreekHead_A3_05","GreekHead_A3_06"
    ];
    private _selectedFace = selectRandom _faces;
    
    // Sélectionner une voix Perse
    private _speakers = ["Male01PER", "Male02PER", "Male03PER"];
    private _selectedSpeaker = selectRandom _speakers;
    
    // Sélectionner une tenue civile (si disponible)
    private _clothingData = [];
    private _templates = missionNamespace getVariable ["MISSION_var_CivilianTemplates", []];
    if (count _templates > 0) then {
        _clothingData = selectRandom _templates;
    };
    
    // Appliquer l'identité sur toutes les machines
    [[_unit, _selectedName, _selectedFace, _selectedSpeaker, _clothingData], _fnc_applyIdentity] remoteExec ["call", 0, _unit];
    
    // Marquer l'unité comme traitée avec la variable STANDARDISÉE
    _unit setVariable ["Mission_var_identitySet", true, true];
};

// Boucle principale
while {true} do {
    private _unitsToProcess = [];
    
    // Récupérer les unités autour des joueurs (850m) pour optimiser
    if (count allPlayers > 0) then {
        {
            private _p = _x;
            private _near = _p nearEntities ["Man", 850];
            {
                if (!(_x in _unitsToProcess)) then {
                    _unitsToProcess pushBack _x;
                };
            } forEach _near;
        } forEach allPlayers;
    };

    {
        private _unit = _x;
        private _uniform = toLower (uniform _unit);
        
        // --- FILTRE "PAS UNE FEMME" ---
        // On vérifie que ce n'est PAS une femme visuellement
        if (
            (_uniform find "burqa" == -1) && 
            (_uniform find "dress" == -1) && 
            (_uniform find "woman" == -1)
        ) then {
            
            // Vérifie si l'unité est OPFOR, Indépendant ou CIVIL, IA, et pas traitée
            if (
                (side _unit == east || side _unit == resistance || side _unit == civilian) && 
                alive _unit && 
                !isPlayer _unit &&
                !(_unit getVariable ["Mission_var_identitySet", false])
            ) then {
                [_unit, _names_arab_full, _fnc_applyIdentity] call _fnc_processUnit;
            };
        };
        
    } forEach _unitsToProcess;
    
    sleep 10;
};
