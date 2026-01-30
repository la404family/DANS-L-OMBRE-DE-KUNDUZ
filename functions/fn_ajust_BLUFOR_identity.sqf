/*
    Auteur: Kevin
    Nom: fn_ajust_BLUFOR_identity.sqf
    Description: Assigne une identité, un visage et une voix française à tous les BLUFOR.
    Vérifie toutes les 10 secondes pour les nouvelles unités.
    Gère les ethnies (Africain, Arabe, Blanc) en fonction du nom.
    
    IMPORTANT: Cette fonction doit tourner sur TOUTES les machines (pas seulement serveur)
    pour que les identités soient correctement appliquées localement.
*/

// Listes des noms classés par ethnie pour l'attribution des visages
// Format: [nom_complet, prénom, nom_famille]
private _names_african = [
    ["Moussa Diallo", "Moussa", "Diallo"], 
    ["Mamadou Traoré", "Mamadou", "Traoré"], 
    ["Ibrahim Keita", "Ibrahim", "Keita"], 
    ["Sekou Diop", "Sekou", "Diop"], 
    ["Ousmane Sy", "Ousmane", "Sy"], 
    ["Bakary Sow", "Bakary", "Sow"], 
    ["Ismaël Koné", "Ismaël", "Koné"]
];

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

// Noms asiatiques
private _names_asian = [
    ["Minh Tuan Nguyen", "Minh Tuan", "Nguyen"], 
    ["David Pham", "David", "Pham"], 
    ["Julien Tran", "Julien", "Tran"], 
    ["Yong Ly", "Yong", "Ly"], 
    ["Miho Nguyen", "Miho", "Nguyen"], 
    ["Eric Do", "Eric", "Do"]
];

// Noms du pacifique/autres
private _names_pacific = [
    ["Teiva Tehuiotoa", "Teiva", "Tehuiotoa"], 
    ["Manaarii Puarai", "Manaarii", "Puarai"], 
    ["Teva Rohi", "Teva", "Rohi"], 
    ["Manua Tuihani", "Manua", "Tuihani"], 
    ["Keanu Loa", "Keanu", "Loa"], 
    ["Tamatoa Arii", "Tamatoa", "Arii"], 
    ["Ariitea Tehei", "Ariitea", "Tehei"]
];

// Tous les autres noms (type européen/blanc par défaut)
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

// Fonction locale pour appliquer l'identité à une unité
// Cette fonction doit être exécutée localement sur la machine qui contrôle l'unité
private _fnc_applyIdentity = {
    params ["_unit", "_nameData", "_selectedFace", "_selectedSpeaker"];
    
    if (isNull _unit || !alive _unit) exitWith {};
    
    // Extraire les données du nom
    _nameData params ["_fullName", "_firstName", "_lastName"];
    
    // Appliquer le visage (doit être fait avant setName)
    _unit setFace _selectedFace;
    
    // Appliquer le nom - Format: [nom_complet, prénom, nom_famille]
    // Le 3ème paramètre est le "nameSound" utilisé pour les voix radio
    if !(_nameData isEqualTo []) then {
        _unit setName [_fullName, _firstName, _lastName];
    };
    
    // Appliquer la voix française
    _unit setSpeaker _selectedSpeaker;
    
    // Forcer la mise à jour de l'identité
    _unit setIdentity "";
};

// Fonction pour déterminer le type de visage et appliquer l'identité
private _fnc_processUnit = {
    params ["_unit", "_names_african", "_names_arab", "_names_asian", "_names_pacific", "_names_standard", "_fnc_applyIdentity"];
    
    // Créer la liste complète avec type d'ethnie
    private _all_names_typed = [];
    { _all_names_typed pushBack [_x, "Black"]; } forEach _names_african;
    { _all_names_typed pushBack [_x, "Arab"]; } forEach _names_arab;
    { _all_names_typed pushBack [_x, "Asian"]; } forEach _names_asian;
    { _all_names_typed pushBack [_x, "Pacific"]; } forEach _names_pacific;
    { _all_names_typed pushBack [_x, "White"]; } forEach _names_standard;
    
    // Sélectionner un nom aléatoire avec son type
    private _selected = selectRandom _all_names_typed;
    private _nameData = _selected select 0;
    private _faceType = _selected select 1;
    
    // Sélectionner un visage spécifique selon l'ethnie
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
    
    // Sélectionner une voix française
    private _speakers = ["Male01FRE", "Male02FRE", "Male03FRE"];
    private _selectedSpeaker = selectRandom _speakers;
    
    // Appliquer l'identité sur toutes les machines
    // On utilise remoteExecCall avec l'unité comme cible pour exécuter là où l'unité est locale
    [[_unit, _nameData, _selectedFace, _selectedSpeaker], _fnc_applyIdentity] remoteExec ["call", 0, _unit];
    
    // Marquer l'unité comme traitée (synchronisé sur le réseau)
    _unit setVariable ["MISSION_IdentitySet", true, true];
    
    // Stocker les infos d'identité pour référence
    _unit setVariable ["MISSION_Identity", [_nameData select 0, _faceType, _selectedFace], true];
    
    // Debug (décommenter si besoin)
    // diag_log format ["[IDENTITE] %1 -> %2 (%3) visage: %4", _unit, _nameData select 0, _faceType, _selectedFace];
};

// Boucle principale infinie
while {true} do {
    
    // On itère sur allUnits pour trouver les BLUFOR non traités
    {
        private _unit = _x;
        
        // Vérifie si l'unité est BLUFOR, vivante et n'a pas déjà été traitée (Joueurs et IA)
        if (
            side _unit == west && 
            alive _unit && 
            !(_unit getVariable ["MISSION_IdentitySet", false])
        ) then {
            // Traiter l'unité
            [_unit, _names_african, _names_arab, _names_asian, _names_pacific, _names_standard, _fnc_applyIdentity] call _fnc_processUnit;
        };
        
    } forEach allUnits;
    
    // Attendre 45 secondes avant la prochaine vérification
    sleep 45;
};
