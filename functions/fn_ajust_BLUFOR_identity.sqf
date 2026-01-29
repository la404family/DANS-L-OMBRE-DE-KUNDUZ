/*
    Auteur: Kevin
    Nom: fn_ajust_BLUFOR_identity.sqf
    Description: Assigne une identité, un visage et une voix française à tous les BLUFOR.
    Vérifie toutes les 60 secondes pour les nouvelles unités.
    Gère les ethnies (Africain, Arabe, Blanc) en fonction du nom.
*/

// Listes des noms classés par ethnie pour l'attribution des visages
private _names_african = [
    "Moussa Diallo", "Mamadou Traoré", "Ibrahim Keita", "Sekou Diop", 
    "Ousmane Sy", "Bakary Sow", "Ismaël Koné"
];

private _names_arab = [
    "Mehdi Benali", "Sofiane Haddad", "Karim Mansouri", "Mohamed Trabelsi", 
    "Walid Belkacem", "Hicham Bouzid", "Adel Gharbi", "Nassim Saïdi", 
    "Rachid Ziani", "Adam Khayat", "Rayane Meriah"
];

// Noms asiatiques (Pour info, traités avec visages asiatiques ou blancs selon dispo)
private _names_asian = [
    "Minh Tuan Nguyen", "David Pham", "Julien Tran", "Yong Ly", "Miho Nguyen", "Eric Do"
];

// Noms du pacifique/autres
private _names_pacific = [
    "Teiva Tehuiotoa", "Manaarii Puarai", "Teva Rohi", "Manua Tuihani", "Keanu Loa", "Tamatoa Arii", "Ariitea Tehei"
];

// Tous les autres noms (type européen/blanc par défaut)
private _names_standard = [
    "Julien Martin", "Thomas Bernard", "Nicolas Petit", "Alexandre Dubois", "Maxime Moreau", 
    "Guillaume Laurent", "Lucas Girard", "Romain Roux", "Clément Fournier", "Mathieu Bonnet", 
    "Erwan Le Gall", "Enzo Rossi", "Loïc Kerbrat", "Kevin Martinez", "David Rodriguez", 
    "Sébastien Leroux", "Christophe Chevalier", "Benjamin François", "Florian Robin", 
    "Tiago Da Silva", "Adrien Masson", "Bastien Sanchez", "Quentin Boyer", "Valentin André", 
    "Jean-Baptiste Santini", "Rémi Philippe", "Jordan Picart", "Yoann Gautier", "Steve Morel", 
    "Dylan Caron", "Arnaud Perrin", "Thibault Marchand", "Dimitri Kowalski", "Xavier Dupuis", 
    "Cyril Guérin", "Laurent Baron", "Jérôme Huet", "Fabien Roy", "Vincent Colin", 
    "Olivier Vidal", "Pascal Aubert", "Éric Rey", "Franck Charpentier", "Pierre Tessier", 
    "Simon Picard", "Louis Chauvin", "Gabin Laporte", "Paul Renard", "Victor Langlois", 
    "Arthur Prévost", "Léo Martinet", "Raphaël Joly", "Gabriel Brun", "Yassine Faure", 
    "Cédric Payet", "Grégory Hoarau", "Stanislav Novak", "Alexis Ivanoff", "Samuel Cohen", 
    "Jonathan Lévy", "Anthony Garcia", "Damien Dos Santos", "Frédéric Muller", "Hans Weber", 
    "Bixente Etcheverry", "Ange Paoli", "Étienne Lemaire", "Bruno Vincent", "Hugues Lefebvre", 
    "Mikaël Gauthier", "Luis Fernandez", "Sylvain Blanchard", "Axel Mercier", "Killian Briand", 
    "Dorian Mounier", "Tristan Deschamps", "Alexis Fontaine", "Sacha Popovic", "Mattéo Ferrari", 
    "Arthur Lefevre", "Jules Mercier", "Martin Cote", "Paul Dumas", "Simon Fontaine", 
    "Louis Rousseau", "Gabin Chevalier", "Victor Giraud", "Lucas Morin", "Antoine Brunet", 
    "Baptiste Gaillard", "Gaspard Barbier", "Clément Arnaud", "Mathis Dupuy", "Maël Carpentier", 
    "Hugo Boucher", "Raphaël Denis", "Sacha Aubry", "Noah Picard", "Tom Colin", 
    "Léo Vasseur", "Théo Caron", "Nathan Hubert", "Augustin Roche", "Noé Deschamp", 
    "Ethan Rivet", "Evan Meyer", "Nolan Jacquet", "Enzo Renard", "Aaron Charrier", 
    "Axel Perrot", "Robin Guyot", "Valentin Barre", "Nino Pons", "Eliott Munoz", 
    "Maxence Breton", "Liam Fabre", "Timothée Dufour", "Marius Lecomte", "Lenny Bourgeois", 
    "Yanis Vidal", "Isaac Benoit", "Adam Lemoine", "Adrien Blanc", "Samuel Garnier", 
    "Benjamin Faure", "Maxime Reynaud", "Remi Prevost", "Vincent Lacroix", "Pierre Marchal"
];

// Regroupement de tous les noms pour tirage aléatoire global si besoin, 
// ou on pioche dans une liste globale et on déduit le visage.
private _all_names = _names_african + _names_arab + _names_asian + _names_pacific + _names_standard;

// Boucle principale infinie
while {true} do {
    
    // On ne traite que les unités BLUFOR (WEST) qui sont locale ou gérées par le serveur si script server-side
    // On itère sur allUnits pour trouver les BLUFOR
    {
        private _unit = _x;
        
        // Vérifie si l'unité est BLUFOR, vivante, et n'a pas déjà été traitée
        if (side _unit == west && alive _unit && !(_unit getVariable ["MISSION_IdentitySet", false])) then {
            
            // Choisir un nom aléatoire dans la liste globale qui n'a pas encore été attribué de préférence ?
            // Pour simplifier ici on prend un random dans la liste globale.
            private _name = selectRandom _all_names;
            
            // Déterminer le type de visage en fonction du nom choisi
            private _faceType = "White"; // Default
            
            if (_name in _names_african) then { _faceType = "Black"; };
            if (_name in _names_arab) then { _faceType = "Arab"; };
            if (_name in _names_asian) then { _faceType = "Asian"; };
            if (_name in _names_pacific) then { _faceType = "Pacific"; };

            // Sélectionner un visage spécifique
            // Arma 3 a des classes de visages : WhiteHead_01...21, AfricanHead_01...03, GreekHead_A3_01... (souvent utilisé pour arabe/méditerranéen), AsianHead_A3_01...
            // Note: Il vaut mieux utiliser des listes de classes valides.
            
            private _faces = [];
            switch (_faceType) do {
                case "Black": { 
                    _faces = ["AfricanHead_01","AfricanHead_02","AfricanHead_03","TanoanHead_A3_01","TanoanHead_A3_02","TanoanHead_A3_03","TanoanHead_A3_04","TanoanHead_A3_05","TanoanHead_A3_06","TanoanHead_A3_07","TanoanHead_A3_08"]; 
                };
                case "Arab": { 
                    _faces = ["PersianHead_A3_01","PersianHead_A3_02","PersianHead_A3_03","GreekHead_A3_01","GreekHead_A3_02","GreekHead_A3_03","GreekHead_A3_04","GreekHead_A3_05","GreekHead_A3_06","RunningManHead_01_F"]; 
                };
                case "Asian": {
                    _faces = ["AsianHead_A3_01","AsianHead_A3_02","AsianHead_A3_03","AsianHead_A3_04","AsianHead_A3_05"];
                    // Fallback si pas de mod: utiliser standard ou spécifique Tanoan parfois
                };
                case "Pacific": {
                    _faces = ["TanoanHead_A3_01","TanoanHead_A3_02","TanoanHead_A3_03","TanoanHead_A3_04","TanoanHead_A3_05"];
                };
                default { // White
                    _faces = ["WhiteHead_01","WhiteHead_02","WhiteHead_03","WhiteHead_04","WhiteHead_05","WhiteHead_06","WhiteHead_07","WhiteHead_08","WhiteHead_09","WhiteHead_10","WhiteHead_11","WhiteHead_12","WhiteHead_13","WhiteHead_14","WhiteHead_15","WhiteHead_16","WhiteHead_17","WhiteHead_18","WhiteHead_19","WhiteHead_20","WhiteHead_21"];
                };
            };
            
            private _selectedFace = selectRandom _faces;
            
            // Appliquer l'identité
            [_unit, _selectedFace] remoteExec ["setFace", 0, true]; // Global
            [_unit, _name] remoteExec ["setName", 0, true];     // Global
            
            // Appliquer la voix française
            // Voix dispo Vanilla avec DLC ou Mods: Male01FRE, Male02FRE, Male03FRE (Contact DLC ou autre ?)
            // Si pas de voix FRE dispo vanilla (souvent Male01ENG etc), on essaye quand même les classes standards si FR installé.
            // On va utiliser Male01FRE, Male02FRE, Male03FRE qui sont standard si le jeu est en FR ou avec extension.
            // Sinon fallback sur des voix anglaises si FR non dispo pour éviter le silence, mais user a demandé "Française uniquement".
            
            private _speakers = ["Male01FRE", "Male02FRE", "Male03FRE"];
            private _selectedSpeaker = selectRandom _speakers;
            
            [_unit, _selectedSpeaker] remoteExec ["setSpeaker", 0, true]; 
            
            // Marquer l'unité comme traitée
            _unit setVariable ["MISSION_IdentitySet", true, true];
            
            // Debug log
            // diag_log format ["MISSION IDENTITE: %1 nommé %2 (%3) avec visage %4", _unit, _name, _faceType, _selectedFace];
            // systemChat format ["Identité ajustée pour %1 (%2)", _name, _faceType];
        };
        
    } forEach allUnits;
    
    // Attendre 60 secondes avant la prochaine vérification
    uiSleep 10;
};
