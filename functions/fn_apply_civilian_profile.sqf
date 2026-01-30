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
    private _femaleNames = [
        ["Aadila Nouri", "Aadila", "Nouri"],
        ["Aaliyah Massoud", "Aaliyah", "Massoud"],
        ["Amani Rahimi", "Amani", "Rahimi"],
        ["Anisa Wahab", "Anisa", "Wahab"],
        ["Fatima Bhutto", "Fatima", "Bhutto"],
        ["Jamila Afghani", "Jamila", "Afghani"],
        ["Latifa Nabizada", "Latifa", "Nabizada"],
        ["Malalai Joya", "Malalai", "Joya"],
        ["Sima Samar", "Sima", "Samar"],
        ["Zarifa Ghafari", "Zarifa", "Ghafari"]
    ];
    private _nameData = selectRandom _femaleNames;
    _nameData params ["_fullName", "_firstName", "_lastName"];
    
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
        ["Afaq Khan", "Afaq", "Khan"],
        ["Akhtar Durrani", "Akhtar", "Durrani"],
        ["Anis Kakar", "Anis", "Kakar"],
        ["Azad Mousavi", "Azad", "Mousavi"],
        ["Faisal Karimi", "Faisal", "Karimi"],
        ["Habib Noori", "Habib", "Noori"],
        ["Jalil Hashemi", "Jalil", "Hashemi"],
        ["Karim Jafari", "Karim", "Jafari"],
        ["Omar Faizi", "Omar", "Faizi"],
        ["Rashid Taheri", "Rashid", "Taheri"]
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
