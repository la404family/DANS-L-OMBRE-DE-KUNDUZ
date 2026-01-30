/*
    File: fn_ajust_BLUFOR_identity.sqf
    Description: Système d'identité dynamique pour les unités BLUFOR.
    
    [ANALYSE & LOGIQUE]
    Ce script assure la cohérence des identités (Nom, Visage, Voix) en multijoueur.
    
    1. PROBLÉMATIQUE MULTIJOUEUR :
       - Les commandes `setName`, `setSpeaker` et `setIdentity` ont un effet LOCAL.
       - Si le serveur change le nom d'une unité, les joueurs ne le voient pas forcément mis à jour.
       - Il faut donc exécuter ces commandes sur TOUTES les machines (Clients + Serveur + JIP).
    
    2. STRATÉGIE (Calcul Centralisé -> Application Globale) :
       - Le script (si exécuté sur le serveur) détecte les nouvelles unités.
       - Il choisit ALÉATOIREMENT mais UNE SEULE FOIS l'identité (Nom + Visage).
       - Il envoie ensuite ces données précises à TOUT LE MONDE via `remoteExec`.
       - Cela garantit que tous les joueurs voient le MEME visage et le MEME nom pour une unité donnée.
       
    3. GESTION DES ETHNIES :
       - Le script associe des visages spécifiques (White, African, Asian, etc.) en fonction de l'origine du nom.
       - Cela évite d'avoir un "Moussa Diop" avec un visage de type caucasien.
*/

// --- 1. BASES DE DONNÉES DES NOMS ---
// Classés par ethnie pour assurer une correspondance Nom <-> Visage cohérente

// Noms Africains -> Visages "AfricanHead_0x"
private _names_african = [
    ["Moussa Diallo", "Moussa", "Diallo"], 
    ["Mamadou Traoré", "Mamadou", "Traoré"], 
    ["Ibrahim Keita", "Ibrahim", "Keita"], 
    ["Sekou Diop", "Sekou", "Diop"], 
    ["Ousmane Sy", "Ousmane", "Sy"], 
    ["Bakary Sow", "Bakary", "Sow"], 
    ["Ismaël Koné", "Ismaël", "Koné"]
];

// Noms Maghrébins/Arabes -> Visages Perses/Grecs (Proches visuellement)
private _names_arab = [
    ["Mehdi Benali", "Mehdi", "Benali"], 
    ["Sofiane Haddad", "Sofiane", "Haddad"], 
    ["Karim Mansouri", "Karim", "Mansouri"], 
    ["Mohamed Trabelsi", "Mohamed", "Trabelsi"], 
    ["Walid Belkacem", "Walid", "Belkacem"], 
    ["Hicham Bouzid", "Hicham", "Bouzid"], 
    ["Adel Gharbi", "Adel", "Gharbi"], 
    ["Nassim Saïdi", "Nassim", "Saïdi"], 
    ["Rachid Ziani", "Rachid", "Ziani"], 
    ["Adam Khayat", "Adam", "Khayat"], 
    ["Rayane Meriah", "Rayane", "Meriah"]
];

// Noms Asiatiques -> Visages "AsianHead_A3_0x"
private _names_asian = [
    ["Minh Tuan Nguyen", "Minh Tuan", "Nguyen"],
    ["Kevin Le", "Kevin", "Le"],
    ["Thomas Vo", "Thomas", "Vo"],
    ["Nicolas Hoang", "Nicolas", "Hoang"],
    ["Pierre Dang", "Pierre", "Dang"],
    ["Jun Li", "Jun", "Li"],
    ["Hao Wang", "Hao", "Wang"],
    ["Kenji Sato", "Kenji", "Sato"],
    ["Jun-ho Kang", "Jun-ho", "Kang"],
    ["Si-woo Cho", "Si-woo", "Cho"],
    ["Yer Xiong", "Yer", "Xiong"]
];

// Noms du Pacifique -> Visages "TanoanHead_A3_0x"
private _names_pacific = [
    ["Teiva Tehuiotoa", "Teiva", "Tehuiotoa"], 
    ["Manaarii Puarai", "Manaarii", "Puarai"], 
    ["Teva Rohi", "Teva", "Rohi"], 
    ["Manua Tuihani", "Manua", "Tuihani"], 
    ["Keanu Loa", "Keanu", "Loa"], 
    ["Tamatoa Arii", "Tamatoa", "Arii"], 
    ["Ariitea Tehei", "Ariitea", "Tehei"]
];

// Noms Standards (Européens) -> Visages "WhiteHead_0x"
private _names_standard = [
    ["Julien Martin", "Julien", "Martin"], ["Thomas Bernard", "Thomas", "Bernard"], 
    ["Nicolas Petit", "Nicolas", "Petit"], ["Alexandre Dubois", "Alexandre", "Dubois"], 
    ["Maxime Moreau", "Maxime", "Moreau"], ["Guillaume Laurent", "Guillaume", "Laurent"], 
    ["Lucas Girard", "Lucas", "Girard"], ["Romain Roux", "Romain", "Roux"], 
    ["Clément Fournier", "Clément", "Fournier"], ["Mathieu Bonnet", "Mathieu", "Bonnet"], 
    ["Erwan Le Gall", "Erwan", "Le Gall"], ["Enzo Rossi", "Enzo", "Rossi"], 
    ["Loïc Kerbrat", "Loïc", "Kerbrat"], ["Kevin Martinez", "Kevin", "Martinez"], 
    ["David Rodriguez", "David", "Rodriguez"], ["Sébastien Leroux", "Sébastien", "Leroux"], 
    ["Christophe Chevalier", "Christophe", "Chevalier"], ["Benjamin François", "Benjamin", "François"], 
    ["Florian Robin", "Florian", "Robin"], ["Tiago Da Silva", "Tiago", "Da Silva"], 
    ["Adrien Masson", "Adrien", "Masson"], ["Bastien Sanchez", "Bastien", "Sanchez"], 
    ["Quentin Boyer", "Quentin", "Boyer"], ["Valentin André", "Valentin", "André"], 
    ["Jean-Baptiste Santini", "Jean-Baptiste", "Santini"], ["Rémi Philippe", "Rémi", "Philippe"], 
    ["Jordan Picart", "Jordan", "Picart"], ["Yoann Gautier", "Yoann", "Gautier"], 
    ["Steve Morel", "Steve", "Morel"], ["Dylan Caron", "Dylan", "Caron"], 
    ["Arnaud Perrin", "Arnaud", "Perrin"], ["Thibault Marchand", "Thibault", "Marchand"], 
    ["Dimitri Kowalski", "Dimitri", "Kowalski"], ["Xavier Dupuis", "Xavier", "Dupuis"], 
    ["Cyril Guérin", "Cyril", "Guérin"], ["Laurent Baron", "Laurent", "Baron"], 
    ["Jérôme Huet", "Jérôme", "Huet"], ["Fabien Roy", "Fabien", "Roy"], 
    ["Vincent Colin", "Vincent", "Colin"], ["Olivier Vidal", "Olivier", "Vidal"], 
    ["Pascal Aubert", "Pascal", "Aubert"], ["Éric Rey", "Éric", "Rey"], 
    ["Franck Charpentier", "Franck", "Charpentier"], ["Pierre Tessier", "Pierre", "Tessier"], 
    ["Simon Picard", "Simon", "Picard"], ["Louis Chauvin", "Louis", "Chauvin"], 
    ["Gabin Laporte", "Gabin", "Laporte"], ["Paul Renard", "Paul", "Renard"], 
    ["Victor Langlois", "Victor", "Langlois"], ["Arthur Prévost", "Arthur", "Prévost"], 
    ["Léo Martinet", "Léo", "Martinet"], ["Raphaël Joly", "Raphaël", "Joly"], 
    ["Gabriel Brun", "Gabriel", "Brun"], ["Yassine Faure", "Yassine", "Faure"], 
    ["Cédric Payet", "Cédric", "Payet"], ["Grégory Hoarau", "Grégory", "Hoarau"], 
    ["Stanislav Novak", "Stanislav", "Novak"], ["Alexis Ivanoff", "Alexis", "Ivanoff"], 
    ["Samuel Cohen", "Samuel", "Cohen"], ["Jonathan Lévy", "Jonathan", "Lévy"], 
    ["Anthony Garcia", "Anthony", "Garcia"], ["Damien Dos Santos", "Damien", "Dos Santos"], 
    ["Frédéric Muller", "Frédéric", "Muller"], ["Hans Weber", "Hans", "Weber"], 
    ["Bixente Etcheverry", "Bixente", "Etcheverry"], ["Ange Paoli", "Ange", "Paoli"], 
    ["Étienne Lemaire", "Étienne", "Lemaire"], ["Bruno Vincent", "Bruno", "Vincent"], 
    ["Hugues Lefebvre", "Hugues", "Lefebvre"], ["Mikaël Gauthier", "Mikaël", "Gauthier"], 
    ["Luis Fernandez", "Luis", "Fernandez"], ["Sylvain Blanchard", "Sylvain", "Blanchard"], 
    ["Axel Mercier", "Axel", "Mercier"], ["Killian Briand", "Killian", "Briand"], 
    ["Dorian Mounier", "Dorian", "Mounier"], ["Tristan Deschamps", "Tristan", "Deschamps"], 
    ["Alexis Fontaine", "Alexis", "Fontaine"], ["Sacha Popovic", "Sacha", "Popovic"], 
    ["Mattéo Ferrari", "Mattéo", "Ferrari"], ["Arthur Lefevre", "Arthur", "Lefevre"], 
    ["Jules Mercier", "Jules", "Mercier"], ["Martin Cote", "Martin", "Cote"], 
    ["Paul Dumas", "Paul", "Dumas"], ["Simon Fontaine", "Simon", "Fontaine"], 
    ["Louis Rousseau", "Louis", "Rousseau"], ["Gabin Chevalier", "Gabin", "Chevalier"], 
    ["Victor Giraud", "Victor", "Giraud"], ["Lucas Morin", "Lucas", "Morin"], 
    ["Antoine Brunet", "Antoine", "Brunet"], ["Baptiste Gaillard", "Baptiste", "Gaillard"], 
    ["Gaspard Barbier", "Gaspard", "Barbier"], ["Clément Arnaud", "Clément", "Arnaud"], 
    ["Mathis Dupuy", "Mathis", "Dupuy"], ["Maël Carpentier", "Maël", "Carpentier"], 
    ["Hugo Boucher", "Hugo", "Boucher"], ["Raphaël Denis", "Raphaël", "Denis"], 
    ["Sacha Aubry", "Sacha", "Aubry"], ["Noah Picard", "Noah", "Picard"], 
    ["Tom Colin", "Tom", "Colin"], ["Léo Vasseur", "Léo", "Vasseur"], 
    ["Théo Caron", "Théo", "Caron"], ["Nathan Hubert", "Nathan", "Hubert"], 
    ["Augustin Roche", "Augustin", "Roche"], ["Noé Deschamp", "Noé", "Deschamp"], 
    ["Ethan Rivet", "Ethan", "Rivet"], ["Evan Meyer", "Evan", "Meyer"], 
    ["Nolan Jacquet", "Nolan", "Jacquet"], ["Enzo Renard", "Enzo", "Renard"], 
    ["Aaron Charrier", "Aaron", "Charrier"], ["Axel Perrot", "Axel", "Perrot"], 
    ["Robin Guyot", "Robin", "Guyot"], ["Valentin Barre", "Valentin", "Barre"], 
    ["Nino Pons", "Nino", "Pons"], ["Eliott Munoz", "Eliott", "Munoz"], 
    ["Maxence Breton", "Maxence", "Breton"], ["Liam Fabre", "Liam", "Fabre"], 
    ["Timothée Dufour", "Timothée", "Dufour"], ["Marius Lecomte", "Marius", "Lecomte"], 
    ["Lenny Bourgeois", "Lenny", "Bourgeois"], ["Yanis Vidal", "Yanis", "Vidal"], 
    ["Isaac Benoit", "Isaac", "Benoit"], ["Adam Lemoine", "Adam", "Lemoine"], 
    ["Adrien Blanc", "Adrien", "Blanc"], ["Samuel Garnier", "Samuel", "Garnier"], 
    ["Benjamin Faure", "Benjamin", "Faure"], ["Maxime Reynaud", "Maxime", "Reynaud"], 
    ["Remi Prevost", "Remi", "Prevost"], ["Vincent Lacroix", "Vincent", "Lacroix"], 
    ["Pierre Marchal", "Pierre", "Marchal"]
];

// --- 2. FONCTION D'APPLICATION LOCALE ---
// Cette fonction sera exécutée sur TOUTES les machines via remoteExec
Mission_fnc_applyIdentity_Impl = {
    params ["_unit", "_nameData", "_selectedFace", "_selectedSpeaker", "_pitch"];
    
    // Sécurité : ne jamais traiter une unité invalide ou morte
    if (isNull _unit || !alive _unit) exitWith {};
    
    // Extraction des composants du nom
    _nameData params ["_fullName", "_firstName", "_lastName"];
    
    // 1. Application du visage
    // setFace a un effet global, mais l'appliquer partout assure une synchro immédiate
    _unit setFace _selectedFace;
    
    // 2. Application du nom
    // setName a un effet LOCAL (doit être exécuté sur chaque client)
    if !(_nameData isEqualTo []) then {
        _unit setName [_fullName, _firstName, _lastName];
    };
    
    // 3. Application de la voix
    // setSpeaker a un effet LOCAL
    _unit setSpeaker _selectedSpeaker;
    
    // 3.5 Application du pitch (tonalité)
    // setPitch est local
    _unit setPitch _pitch;
    
    // 4. Force la mise à jour de l'identité dans le moteur
    _unit setIdentity "";
    
    // Debug local (uniquement pour vérifier si les clients reçoivent l'info)
    // if (hasInterface) then { systemChat format ["Identité reçue pour %1", name _unit]; };
};

// --- 3. FONCTION DE TRAITEMENT (Serveur/Source) ---
// Sélectionne l'identité et diffuse l'ordre d'application
// --- 3. FONCTION DE TRAITEMENT (Serveur/Source) ---
// Sélectionne l'identité et diffuse l'ordre d'application
private _fnc_processUnit = {
    params ["_unit", "_names_african", "_names_arab", "_names_asian", "_names_pacific", "_names_standard"];
    
    // A. Construction de la "Pool" de noms avec leur type ethnique associé
    private _all_names_typed = [];
    { _all_names_typed pushBack [_x, "Black"]; } forEach _names_african;
    { _all_names_typed pushBack [_x, "Arab"]; } forEach _names_arab;
    { _all_names_typed pushBack [_x, "Asian"]; } forEach _names_asian;
    { _all_names_typed pushBack [_x, "Pacific"]; } forEach _names_pacific;
    { _all_names_typed pushBack [_x, "White"]; } forEach _names_standard; // La majorité sera White
    
    // Init de la liste des noms déjà utilisés (Global variable on Server)
    if (isNil "MISSION_UsedNames") then { MISSION_UsedNames = []; };
    
    // B. Filtrage des doublons
    // On ne garde que les noms qui ne sont PAS dans MISSION_UsedNames
    private _available_names = _all_names_typed select { !((_x select 0 select 0) in MISSION_UsedNames) };
    
    // Sécurité : Si tous les noms ont été utilisés, on reset la liste (ou on autorise les doublons temporairement)
    if (count _available_names == 0) then {
        diag_log "[IDENTITY] WARNING: Tous les noms ont été utilisés ! Reset du cache de noms uniques.";
        MISSION_UsedNames = [];
        _available_names = _all_names_typed;
    };
    
    // C. Tirage aléatoire de l'identité
    // C'est ici que se décide le visage que TOUT LE MONDE verra
    private _selected = selectRandom _available_names;
    private _nameData = _selected select 0; // Ex: ["Moussa Diallo", ...]
    
    // Enregistrement du nom comme "Utilisé"
    MISSION_UsedNames pushBack (_nameData select 0);
    private _faceType = _selected select 1; // Ex: "Black"
    
    // C. Sélection d'un visage cohérent avec l'ethnie
    private _faces = [];
    switch (_faceType) do {
        case "Black": { 
            _faces = ["AfricanHead_01","AfricanHead_02","AfricanHead_03"]; 
        };
        case "Arab": { 
            _faces = ["PersianHead_A3_01","PersianHead_A3_02","PersianHead_A3_03","GreekHead_A3_01","GreekHead_A3_02","GreekHead_A3_03","GreekHead_A3_04","GreekHead_A3_05","GreekHead_A3_06"]; 
        };
        case "Asian": {
            _faces = ["AsianHead_A3_01","AsianHead_A3_02","AsianHead_A3_03"];
        };
        case "Pacific": {
            _faces = ["TanoanHead_A3_01","TanoanHead_A3_02","TanoanHead_A3_03","TanoanHead_A3_04","TanoanHead_A3_05"];
        };
        default { // White
            _faces = ["WhiteHead_01","WhiteHead_02","WhiteHead_03","WhiteHead_04","WhiteHead_05","WhiteHead_06","WhiteHead_07","WhiteHead_08","WhiteHead_09","WhiteHead_10","WhiteHead_11","WhiteHead_12","WhiteHead_13","WhiteHead_14","WhiteHead_15","WhiteHead_16","WhiteHead_17","WhiteHead_18","WhiteHead_19","WhiteHead_20","WhiteHead_21"];
        };
    };
    
    private _selectedFace = selectRandom _faces;
    
    // D. Sélection d'une voix cohérente avec l'ethnie
    private _selectedSpeaker = "";
    
    switch (_faceType) do {
        case "White": { 
             // "Standard" -> Male01FRE
            _selectedSpeaker = "Male01FRE"; 
        };
        case "Black": { 
            // "African" -> Male02FRE
            _selectedSpeaker = "Male02FRE"; 
        };
        default { 
            // Maghrébins, Asiatiques, du Pacifique -> Male03FRE
            _selectedSpeaker = "Male03FRE"; 
        };
    };
    
    // Generation d'une variation de tonalité (0.90 à 1.10)
    private _pitch = 0.90 + (random 0.20);
    
    // E. DIFFUSION GLOBALE (Le point clé)
    // On envoie le résultat du tirage (_selectedFace, _nameData...) à tout le réseau.
    // Target 0 = Tous les clients + Serveur. _unit (JIP) = Les joueurs qui se connectent après recevront aussi l'info.
    [_unit, _nameData, _selectedFace, _selectedSpeaker, _pitch] remoteExec ["Mission_fnc_applyIdentity_Impl", 0, _unit];
    
    // F. MARQUAGE
    // On marque l'unité comme "traitée" en global (true) pour éviter qu'une autre machine ne refasse le travail.
    _unit setVariable ["MISSION_IdentitySet", true, true];
    
    // Sauvegarde optionnelle pour persistance ou debug
    _unit setVariable ["MISSION_Identity", [_nameData select 0, _faceType, _selectedFace], true];
};

// --- 4. BOUCLE PRINCIPALE ---
while {true} do {
    
    // On itère sur allUnits pour trouver les BLUFOR non traités
    {
        private _unit = _x;
        
        // Critères de selection :
        // 1. BLUFOR (West)
        // 2. Vivant
        // 3. Pas encore traité (Variable MISSION_IdentitySet)
        if (
            side _unit == west && 
            alive _unit && 
            !(_unit getVariable ["MISSION_IdentitySet", false])
        ) then {
            // Lancer le traitement
            [_unit, _names_african, _names_arab, _names_asian, _names_pacific, _names_standard] call _fnc_processUnit;
        };
        
    } forEach allUnits;
    
    // Check toutes les 45 secondes pour économiser les ressources
    sleep 45;
};
