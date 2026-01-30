/*
    fn_apply_civilian_profile.sqf
    VERSION 3.0 - CORRECTIF CRITIQUE
    
    ORDRE CORRECT:
    1. Appliquer le LOADOUT (tenue)
    2. FORCER le visage APRÈS le loadout
    3. FORCER le nom APRÈS tout
    
    Arguments:
    0: Object - L'unité à modifier
    1: Boolean (optionnel) - Forcer le genre féminin (défaut: détection auto)
*/

if (!isServer) exitWith {};

params ["_unit", ["_forceFemale", false]];

if (isNull _unit || !alive _unit) exitWith {
    diag_log "[IDENTITY] ERROR: Unit is null or dead";
};

diag_log format ["[IDENTITY] ========== START Processing: %1 ==========", _unit];

// --- 1. ATTENDRE LES TEMPLATES ---
private _timeout = time + 5;
waitUntil {
    !isNil "MISSION_CivilianTemplates" && {count MISSION_CivilianTemplates > 0} || {time > _timeout}
};

private _templates = missionNamespace getVariable ["MISSION_CivilianTemplates", []];
diag_log format ["[IDENTITY] Templates available: %1", count _templates];

// Fallback si aucun template
if (count _templates == 0) then {
    _templates = [["C_man_polo_1_F", [], "PersianHead_A3_01", false]];
    diag_log "[IDENTITY] WARNING: Using fallback template";
};

// --- 2. SÉLECTION DU TEMPLATE ---
private _selectedTemplate = [];

// Si on force le genre féminin, chercher un template féminin
if (_forceFemale) then {
    private _femaleTemplates = _templates select {_x select 3};
    if (count _femaleTemplates > 0) then {
        _selectedTemplate = selectRandom _femaleTemplates;
        diag_log "[IDENTITY] Forced FEMALE template selection";
    } else {
        _selectedTemplate = selectRandom _templates;
        diag_log "[IDENTITY] WARNING: No female template found, using random";
    };
} else {
    _selectedTemplate = selectRandom _templates;
};

// Format: [Type, Loadout, Face, isFemale]
_selectedTemplate params ["_type", "_loadout", "_templateFace", ["_isFemale", false]];

// Force le genre si demandé
if (_forceFemale) then { _isFemale = true; };

diag_log format ["[IDENTITY] Selected: Type=%1 | isFemale=%2", _type, _isFemale];

// --- 3. NETTOYAGE COMPLET ---
removeUniform _unit;
removeGoggles _unit;
removeHeadgear _unit;
removeVest _unit;
removeBackpack _unit;
removeAllAssignedItems _unit;
removeAllWeapons _unit;

// --- 4. APPLICATION DU LOADOUT ---
if (count _loadout > 0) then {
    _unit setUnitLoadout _loadout;
    diag_log format ["[IDENTITY] Applied loadout from template"];
};

// --- 5. RE-VÉRIFICATION DU GENRE ---
private _actualUniform = uniform _unit;
private _uLow = toLower _actualUniform;
diag_log format ["[IDENTITY] Actual uniform after loadout: %1", _actualUniform];

if ((_uLow find "burqa" > -1) || (_uLow find "dress" > -1) || (_uLow find "woman" > -1) || (_uLow find "female" > -1)) then {
    _isFemale = true;
    diag_log "[IDENTITY] Gender OVERRIDE: FEMALE detected from uniform keyword";
};

// --- 6. APPLICATION IDENTITÉ (APRÈS LOADOUT - CRITIQUE) ---
sleep 0.1; // Petit délai pour synchronisation

if (_isFemale) then {
    // ======= PROFIL FEMME =======
    diag_log "[IDENTITY] >>> APPLYING FEMALE PROFILE <<<";
    
    // VISAGE FÉMININ
    private _faceIndex = floor (random 17) + 1;
    private _faceName = format ["max_female%1", _faceIndex];
    [_unit, _faceName] remoteExec ["setFace", 0, _unit];
    diag_log format ["[IDENTITY] FACE set to: %1", _faceName];
    
    // VOIX (remoteExec pour synchronisation MP)
    private _speaker = selectRandom ["Male01PER", "Male02PER", "Male03PER"];
    [_unit, _speaker] remoteExec ["setSpeaker", 0, _unit];
    _unit setPitch (1.2 + random 0.2);
    
    // NOM FÉMININ AFGHAN
   private _names = [
    // Liste originale
    "Aadila Nouri", "Aaliyah Massoud", "Amani Rahimi", "Anisa Wahab",
    "Bahar Pars", "Fatima Bhutto", "Ghazal Sadat", "Jamila Afghani",
    "Kubra Khademi", "Latifa Nabizada", "Malalai Joya", "Sima Samar",

    // Ajout de 150 noms féminins
    "Abir Al-Sahlani", "Afra Jalil", "Aisha Wardak", "Aleena Khan", "Alia Zadeh",
    "Almas Durrani", "Amal Alamuddin", "Amira Casar", "Anahita Ratebzad", "Anbar Nadiya",
    "Aqsa Parvez", "Ara Qadir", "Areeba Habib", "Arezoo Tanha", "Arwa Damon",
    "Asal Badiee", "Asma Jahangir", "Asra Nomani", "Atefeh Razavi", "Azadeh Moaveni",
    "Aziza Siddiqui", "Azra Akrami", "Badra Ali", "Bahira Sherif", "Balqis Ahmed",
    "Banu Ghazanfar", "Baran Kosari", "Baria Alamuddin", "Basma Hassan", "Batool Fakoor",
    "Bayan Mahmoud", "Beheshta Arghand", "Behnaz Jafari", "Benafsha Yaqoobi", "Bushra Maneka",
    "Dalia Mogahed", "Dana Ghazi", "Dania Khatib", "Darya Safai", "Deena Aljuhani",
    "Delaram Karkhir", "Delbar Nazari", "Dorsa Derakhshani", "Dua Khalil", "Durkhanai Ayubi",
    "Elaha Soroor", "Elham Shahin", "Elnaz Shakerdoost", "Esra Bilgic", "Faiza Darkhani",
    "Fakhria Khalil", "Farah Pahlavi", "Farangis Yeganegi", "Farhana Qasimi", "Fariba Hachtroudi",
    "Farkhunda Zahra", "Farzaneh Kaboli", "Fatemeh Motamed", "Fawzia Koofi", "Fereshteh Kazemi",
    "Fida Qasemi", "Forough Farrokhzad", "Fozia Koofi", "Freshta Karim", "Geeti Pasha",
    "Gelareh Abbasi", "Ghadir Mounib", "Golshifteh Farahani", "Habiba Sarabi", "Hadia Tajik",
    "Hafsa Zayyan", "Haifa Wehbe", "Hala Gorani", "Hamida Barmaki", "Hangama Zohra",
    "Hania Amir", "Hasina Safi", "Hawa Alam", "Hayat Mirshad", "Hediyeh Tehrani",
    "Hina Rabbani", "Hind Rostom", "Homa Darabi", "Homira Qaderi", "Huda Kattan",
    "Iman Abdulmajid", "Kamila Sidiqi", "Kawsar Sharifi", "Khadija Bashir", "Laila Freivalds",
    "Laila Haidari", "Layla Murad", "Leena Alam", "Leila Hatami", "Lima Azimi",
    "Lina Ben Mhenni", "Mahbouba Seraj", "Mahira Khan", "Manal al-Sharif", "Mariam Durrani",
    "Mariam Ghani", "Marjane Satrapi", "Marwa Elselehdar", "Maryam Monsef", "Massouda Jalal",
    "Meena Keshwar", "Mehrnaz Dabir", "Mina Mangal", "Mitra Hajjar", "Mona Zaki",
    "Mozhdah Jamalzadah", "Muna Wassef", "Muniba Mazari", "Nadia Anjuman", "Naghma Shaperai",
    "Nahid Persson", "Nargis Fakhri", "Nargis Nehan", "Nasrin Sotoudeh", "Nawal El Saadawi",
    "Nelofer Pazira", "Niki Karimi", "Niloufar Ardalan", "Niloufar Bayat", "Noor Jahan",
    "Palwasha Hassan", "Parvin Etesami", "Parwana Amiri", "Qamar Gul", "Rabea Balkhi",
    "Rahima Jami", "Rania Al-Abdullah", "Reem Abdullah", "Rola Ghani", "Roxana Saberi",
    "Roya Mahboob", "Saba Qamar", "Sahraa Karimi", "Sajal Aly", "Salma Zadeh",
    "Samira Makhmalbaf", "Sanam Baloch", "Sarah Shahi", "Seeta Qasemi", "Shabana Azmi",
    "Shaharzad Akbar", "Shirin Ebadi", "Shukria Barakzai", "Soheila Siddiq", "Soraya Tarzi",
    "Tahmina Alvi", "Tahmineh Milani", "Taraneh Alidoosti", "Vida Samadzai", "Wazhma Frogh",
    "Yalda Hakim", "Yasmin Levy", "Zainab Salbi", "Zara Kayani", "Zarghona Walid",
    "Zarifa Ghafari", "Zohra Karimi"
];
    private _fullNameStr = selectRandom _names;
    private _nameParts = _fullNameStr splitString " ";
    private _firstName = _nameParts select 0;
    private _lastName = if (count _nameParts > 1) then {_nameParts joinString " " select [count _firstName + 1]} else {""};
    private _fullName = _fullNameStr;
    
    // FORCER LE NOM (remoteExec pour synchronisation MP)
    [_unit, [_fullName, _firstName, _lastName]] remoteExec ["setName", 0, _unit];
    diag_log format ["[IDENTITY] NAME set to: %1", _fullName];
    
} else {
    // ======= PROFIL HOMME =======
    diag_log "[IDENTITY] >>> APPLYING MALE PROFILE <<<";
    
    // VISAGE MASCULIN
    private _maleFace = selectRandom [
        "PersianHead_A3_01", "PersianHead_A3_02", "PersianHead_A3_03"
    ];
    [_unit, _maleFace] remoteExec ["setFace", 0, _unit];
    diag_log format ["[IDENTITY] FACE set to: %1", _maleFace];
    
    // VOIX (remoteExec pour synchronisation MP)
    private _speaker = selectRandom ["Male01PER", "Male02PER", "Male03PER"];
    [_unit, _speaker] remoteExec ["setSpeaker", 0, _unit];
    _unit setPitch 1.0;
    
    // BARBE
    removeGoggles _unit; // Retirer d'abord
    if (isClass (configFile >> "CfgGlasses" >> "fsob_Beard01_Dark")) then {
        _unit addGoggles "fsob_Beard01_Dark";
        diag_log "[IDENTITY] BEARD applied: fsob_Beard01_Dark";
    } else {
        diag_log "[IDENTITY] WARNING: Beard class not found!";
    };
    
    // NOM MASCULIN AFGHAN
   private _maleNames = [
    // Liste originale (10)
    ["Afaq Khan", "Afaq", "Khan"],
    ["Akhtar Durrani", "Akhtar", "Durrani"],
    ["Anis Kakar", "Anis", "Kakar"],
    ["Azad Mousavi", "Azad", "Mousavi"],
    ["Faisal Karimi", "Faisal", "Karimi"],
    ["Habib Noori", "Habib", "Noori"],
    ["Jalil Hashemi", "Jalil", "Hashemi"],
    ["Karim Jafari", "Karim", "Jafari"],
    ["Omar Faizi", "Omar", "Faizi"],
    ["Rashid Taheri", "Rashid", "Taheri"],
    ["Abbas Alizadeh", "Abbas", "Alizadeh"],
    ["Abdullah Wardak", "Abdullah", "Wardak"],
    ["Adel Termos", "Adel", "Termos"],
    ["Adnan Malik", "Adnan", "Malik"],
    ["Ahmad Shah", "Ahmad", "Shah"],
    ["Ali Rezaei", "Ali", "Rezaei"],
    ["Amin Maalouf", "Amin", "Maalouf"],
    ["Amir Hosseini", "Amir", "Hosseini"],
    ["Amjad Sabri", "Amjad", "Sabri"],
    ["Arash Kamali", "Arash", "Kamali"],
    ["Arsalan Kazemi", "Arsalan", "Kazemi"],
    ["Asadullah Khalid", "Asadullah", "Khalid"],
    ["Ashraf Baradar", "Ashraf", "Baradar"],
    ["Atiq Rahimi", "Atiq", "Rahimi"],
    ["Ayman Odeh", "Ayman", "Odeh"],
    ["Aziz Ansari", "Aziz", "Ansari"],
    ["Babur Dostum", "Babur", "Dostum"],
    ["Bahram Radan", "Bahram", "Radan"],
    ["Baktash Siawash", "Baktash", "Siawash"],
    ["Bashir Ahmad", "Bashir", "Ahmad"],
    ["Bassam Tibi", "Bassam", "Tibi"],
    ["Behrouz Vosooghi", "Behrouz", "Vosooghi"],
    ["Bilal Mansour", "Bilal", "Mansour"],
    ["Boulos Khoury", "Boulos", "Khoury"],
    ["Cyrus Zarei", "Cyrus", "Zarei"],
    ["Danish Karokhel", "Danish", "Karokhel"],
    ["Dariush Eghbali", "Dariush", "Eghbali"],
    ["Dawood Sarkhosh", "Dawood", "Sarkhosh"],
    ["Ehsan Aman", "Ehsan", "Aman"],
    ["Elias Yasin", "Elias", "Yasin"],
    ["Emal Zakarya", "Emal", "Zakarya"],
    ["Esmail Khoi", "Esmail", "Khoi"],
    ["Fahim Dashty", "Fahim", "Dashty"],
    ["Farhad Darya", "Farhad", "Darya"],
    ["Farid Zaland", "Farid", "Zaland"],
    ["Farzad Farzin", "Farzad", "Farzin"],
    ["Fawad Ramiz", "Fawad", "Ramiz"],
    ["Faysal Qureshi", "Faysal", "Qureshi"],
    ["Fouad Ajami", "Fouad", "Ajami"],
    ["Ghafoor Bakhsh", "Ghafoor", "Bakhsh"],
    ["Ghassan Kanafani", "Ghassan", "Kanafani"],
    ["Ghulam Haider", "Ghulam", "Haider"],
    ["Gulbuddin Hekmatyar", "Gulbuddin", "Hekmatyar"],
    ["Hafez Assad", "Hafez", "Assad"],
    ["Hamid Karzai", "Hamid", "Karzai"],
    ["Hamza Yusuf", "Hamza", "Yusuf"],
    ["Haroon Yusufi", "Haroon", "Yusufi"],
    ["Hassan Rouhani", "Hassan", "Rouhani"],
    ["Hekmat Khalil", "Hekmat", "Khalil"],
    ["Hesam Din", "Hesam", "Din"],
    ["Homayoun Shajarian", "Homayoun", "Shajarian"],
    ["Hossein Alizadeh", "Hossein", "Alizadeh"],
    ["Ibrahim Maalouf", "Ibrahim", "Maalouf"],
    ["Idris Sadiqi", "Idris", "Sadiqi"],
    ["Ilyas Kashmiri", "Ilyas", "Kashmiri"],
    ["Imran Khan", "Imran", "Khan"],
    ["Ismael Jalal", "Ismael", "Jalal"],
    ["Jabbar Patel", "Jabbar", "Patel"],
    ["Jafar Panahi", "Jafar", "Panahi"],
    ["Jalal Talabani", "Jalal", "Talabani"],
    ["Jamal Khashoggi", "Jamal", "Khashoggi"],
    ["Jamil Sadeqi", "Jamil", "Sadeqi"],
    ["Javed Akhtar", "Javed", "Akhtar"],
    ["Jawad Sharif", "Jawad", "Sharif"],
    ["Kabir Bedi", "Kabir", "Bedi"],
    ["Kamal Salibi", "Kamal", "Salibi"],
    ["Kamran Hooman", "Kamran", "Hooman"],
    ["Kasra Nouri", "Kasra", "Nouri"],
    ["Kaveh Ahangar", "Kaveh", "Ahangar"],
    ["Khalid Hosseini", "Khalid", "Hosseini"],
    ["Khalil Zad", "Khalil", "Zad"],
    ["Khosrow Shakibai", "Khosrow", "Shakibai"],
    ["Kianoush Ayari", "Kianoush", "Ayari"],
    ["Latif Pedram", "Latif", "Pedram"],
    ["Mahdi Darius", "Mahdi", "Darius"],
    ["Mahmood Khan", "Mahmood", "Khan"],
    ["Majid Majidi", "Majid", "Majidi"],
    ["Malek Jahan", "Malek", "Jahan"],
    ["Mansour Bahrami", "Mansour", "Bahrami"],
    ["Marwan Barghouti", "Marwan", "Barghouti"],
    ["Masoud Shojaei", "Masoud", "Shojaei"],
    ["Mehdi Mahdavikia", "Mehdi", "Mahdavikia"],
    ["Mirwais Nejat", "Mirwais", "Nejat"],
    ["Mohammad Reza", "Mohammad", "Reza"],
    ["Mohsen Makhmalbaf", "Mohsen", "Makhmalbaf"],
    ["Morteza Pashaei", "Morteza", "Pashaei"],
    ["Munir Bashir", "Munir", "Bashir"],
    ["Mustafa Sandal", "Mustafa", "Sandal"],
    ["Nabil Shoail", "Nabil", "Shoail"],
    ["Nader Shah", "Nader", "Shah"],
    ["Naguib Mahfouz", "Naguib", "Mahfouz"],
    ["Najibullah Ahmadzai", "Najibullah", "Ahmadzai"],
    ["Naseeruddin Shah", "Naseeruddin", "Shah"],
    ["Nasser Al-Attiyah", "Nasser", "Al-Attiyah"],
    ["Navid Negahban", "Navid", "Negahban"],
    ["Nizar Qabbani", "Nizar", "Qabbani"],
    ["Omid Djalili", "Omid", "Djalili"],
    ["Osman Mir", "Osman", "Mir"],
    ["Parviz Parastui", "Parviz", "Parastui"],
    ["Payam Dehkordi", "Payam", "Dehkordi"],
    ["Qais Ulfat", "Qais", "Ulfat"],
    ["Qasim Soleimani", "Qasim", "Soleimani"],
    ["Rafik Hariri", "Rafik", "Hariri"],
    ["Rahim Shah", "Rahim", "Shah"],
    ["Rahman Baba", "Rahman", "Baba"],
    ["Rami Malek", "Rami", "Malek"],
    ["Ramzi Yousef", "Ramzi", "Yousef"],
    ["Reza Attaran", "Reza", "Attaran"],
    ["Rostam Farrokhzad", "Rostam", "Farrokhzad"],
    ["Saami Yusuf", "Saami", "Yusuf"],
    ["Saeed Rad", "Saeed", "Rad"],
    ["Salahuddin Rabbani", "Salahuddin", "Rabbani"],
    ["Salim Shaheen", "Salim", "Shaheen"],
    ["Salman Khan", "Salman", "Khan"],
    ["Saman Jalili", "Saman", "Jalili"],
    ["Sardar Azmoun", "Sardar", "Azmoun"],
    ["Shahrukh Khan", "Shahrukh", "Khan"],
    ["Shahzad Ismaily", "Shahzad", "Ismaily"],
    ["Shams Langroudi", "Shams", "Langroudi"],
    ["Sohrab Sepehri", "Sohrab", "Sepehri"],
    ["Sulaiman Layeq", "Sulaiman", "Layeq"],
    ["Tahir Qadri", "Tahir", "Qadri"],
    ["Tarek Fatah", "Tarek", "Fatah"],
    ["Tariq Ramadan", "Tariq", "Ramadan"],
    ["Ubaidullah Jan", "Ubaidullah", "Jan"],
    ["Vahid Amiri", "Vahid", "Amiri"],
    ["Walid Al-Shehri", "Walid", "Al-Shehri"],
    ["Waseem Badami", "Waseem", "Badami"],
    ["Yasin Malik", "Yasin", "Malik"],
    ["Yasser Arafat", "Yasser", "Arafat"],
    ["Yousef Chahine", "Yousef", "Chahine"],
    ["Zalmay Khalilzad", "Zalmay", "Khalilzad"],
    ["Zarif Zarif", "Zarif", "Zarif"],
    ["Zayn Malik", "Zayn", "Malik"],
    ["Zia Massoud", "Zia", "Massoud"]
];
    private _nameData = selectRandom _maleNames;
    _nameData params ["_fullName", "_firstName", "_lastName"];
    
    // FORCER LE NOM (remoteExec pour synchronisation MP)
    [_unit, [_fullName, _firstName, _lastName]] remoteExec ["setName", 0, _unit];
    diag_log format ["[IDENTITY] NAME set to: %1", _fullName];
};

// --- 7. MARQUAGE ---
_unit setVariable ["Mission_var_identitySet", true, true];
_unit setVariable ["Mission_var_isWoman", _isFemale, true];

diag_log format ["[IDENTITY] ========== COMPLETED: %1 | Name: %2 | Female: %3 ==========", _unit, name _unit, _isFemale];
