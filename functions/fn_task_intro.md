# fn_task_intro.sqf - Système d'Introduction Cinématique

## Exécution
- **Client** : `if (hasInterface)` → Cinématique visuelle + effets
- **Serveur** : `if (isServer)` → Création hélicoptère + gestion unités

---

## Architecture Dual Client/Server

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT                                  │
│  (Cinématique visuelle, caméra, effets post-process)            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ publicVariable "MISSION_intro_heli"
                              │
┌─────────────────────────────────────────────────────────────────┐
│                         SERVER                                  │
│  (Création hélico, embarquement, vol, débarquement)             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Partie CLIENT

### Initialisation
| Action | Description |
|--------|-------------|
| Badge BLUFOR | Applique insigne `AMF_FRANCE_HV` à toutes les unités WEST |
| `cutText "BLACK FADED"` | Écran noir immédiat |
| `fadeSound 0` | Coupe le son |
| `showCinemaBorder true` | Bandes noires cinéma |
| `disableUserInput true` | Désactive contrôles joueur |
| `player allowDamage false` | Joueur invincible |

### Effets Post-Process

#### ColorCorrections (ppEffect 1500)
```sqf
[1, 1.0, -0.05, [0.2, 0.2, 0.2, 0.0], [0.8, 0.8, 0.9, 0.7], [0.1, 0.1, 0.2, 0]]
```
- Tons légèrement bleutés/froids
- Contraste réduit

#### FilmGrain (ppEffect 2005)
```sqf
[0.1, 1, 1, 0.1, 1, false]
```
- Grain cinématographique léger

### Séquence Caméra

#### Plan 1-2 : Survol Ville (15s)
```
Position: waypoint_invisible_XXX (random 0-340)
          → waypoint_invisible_YYY (différent)
          
Caméra:   100-150m altitude
          Travelling lent entre deux points aléatoires
          FOV: 0.65
```

#### Textes Affichés
| Timing | Contenu | Localisation |
|--------|---------|--------------|
| +3s | Auteur + "présente..." | `STR_INTRO_AUTHOR`, `STR_INTRO_PRESENTS` |
| +11s | Titre mission | `STR_INTRO_TITLE` |

#### Plan 3 : Vue depuis Hélicoptère (15s)
```
Attente: MISSION_intro_heli (publicVariable serveur)

Caméra:   Attachée à l'hélico [0, 0.8, -0.7]
          Vue arrière (direction [0,1,0])
          FOV: 0.9
          
Texte:    STR_INTRO_SUBTITLE (bas écran)
```

#### Plan 4 : Orbite autour Hélicoptère (14s)
```
Orbite:   Angle -90° → +45° (135° total)
          Distance: 35m → 25m
          Hauteur: 12m au-dessus hélico
          
Update:   0.1s interval
          0.5s commit time
          FOV: 0.75
```

#### Plan 5 : Vue Aérienne QG
```
Position: QG_Center ou vehicles_spawner
          90m au sud, 35m altitude
          
Caméra:   Léger mouvement oscillant (sin/cos * 12)
          Zoom progressif (FOV 0.55 → 0.2)
          Suivi descente hélico
```

### Fin Cinématique
| Action | Description |
|--------|-------------|
| `waitUntil { vehicle player == player }` | Attend débarquement |
| `camDestroy _cam` | Détruit caméra |
| `ppEffectDestroy` | Supprime effets |
| `player switchCamera "INTERNAL"` | Vue FPS normale |
| `showCinemaBorder false` | Retire bandes noires |
| `player allowDamage true` | Vulnérabilité restaurée |
| `disableUserInput false` | Contrôles restaurés |
| Texte final | `STR_MISSION_START` + `STR_MISSION_START_SUBTITLE` |
| `MISSION_intro_finished = true` | Signal fin intro |

### Timeout Sécurité
```sqf
[] spawn {
    sleep 90;   
    disableUserInput false;
    player allowDamage true;        
    showCinemaBorder false;         
};
```
→ Force fin après 90s si blocage

---

## Partie SERVER

### Dépendances
```sqf
waitUntil {!isNil "MISSION_var_helicopters"};
```
Attend la variable définie dans `init.sqf`

### Configuration Hélicoptère

| Paramètre | Source | Valeur |
|-----------|--------|--------|
| Classe | `MISSION_var_helicopters` | `amf_nh90_tth_transport` |
| Spawn | 1300m de `vehicles_spawner` | Direction aléatoire |
| Altitude départ | 200m | `flyInHeight 150` |
| Vitesse approche | 200 km/h | `limitspeed 200` |

### Création Équipage
```sqf
createVehicleCrew _heli;
_grpHeli setBehaviour "CARELESS";
_grpHeli setCombatMode "BLUE";
{ _x allowDamage false; } forEach crew _heli;
```

### Embarquement Joueurs
```sqf
// Collecte toutes les unités des groupes joueurs
private _allUnitsToBoard = [];
{
    private _playerGroup = group _x;
    { _allUnitsToBoard pushBack _x; } forEach (units _playerGroup);
} forEach playableUnits;

// Embarquement
{
    _x moveInCargo _heli;
    _x assignAsCargo _heli;
} forEach _allUnitsToBoard;
```

### Séquence Vol

```
┌─────────────────────────────────────────────────────────────────┐
│ T+0s    : Spawn 1300m, alt 200m, dir aléatoire                  │
│ T+1s    : doMove vers vehicles_spawner, 200 km/h                │
│ T+15s   : Ouverture portes/rampe arrière                        │
│ T+35s   : Ralentissement 120 km/h                               │
│ T+49s   : Attente distance < 250m                               │
│ T+?     : land "GET OUT"                                        │
│ T+?     : Attente altitude < 2m                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Animation Portes (multiples tentatives)
```sqf
// Plusieurs méthodes pour compatibilité mods
animateSource ["door_rear_source", 1]
animateDoor ["door_rear_source", 1]
animateSource ["Door_Rear_Source", 1]
animateSource ["Ramp", 1]
animateSource ["Door_1_source", 1]
```

### Débarquement Joueurs
```sqf
// Position en arc derrière l'hélico
private _dir = getDir _heli;
private _dist = 6 + (_unitIndex mod 3);        // 6-8m
private _angleOffset = 70 + (_unitIndex * 12); // Espacement 12°
private _pos = _heli getPos [_dist, _dir + _angleOffset];

moveOut _unit;
unassignVehicle _unit;
_unit setPos _pos;
```

### Sortie Hélicoptère
```sqf
// Configuration équipage passif
{
    _x disableAI "TARGET";
    _x disableAI "AUTOTARGET";
    _x disableAI "SUPPRESSION";
    _x disableAI "FSM";
    _x setBehaviour "CARELESS";
    _x allowDamage false;
} forEach _crew;

// Verrouillage et départ
_heli setVehicleLock "LOCKED";
_heli land "NONE";
_heli doMove (_destPos getPos [3000, _startDir]);
_heli flyInHeight 200;
_heli limitspeed 300;

// Nettoyage après 70s
sleep 70;
{ deleteVehicle _x } forEach _crew;
deleteVehicle _heli;
```

---

## Objets Éditeur Requis

| Variable | Type | Usage |
|----------|------|-------|
| `vehicles_spawner` | Object | Destination atterrissage |
| `batiment_officer` | Object | Cible caméra plan 1-2 (fallback) |
| `QG_Center` | Object | Cible caméra plan 5 (fallback: vehicles_spawner) |
| `waypoint_invisible_000-340` | Objects | Points aléatoires survol ville |

---

## Variables Globales

| Variable | Scope | Description |
|----------|-------|-------------|
| `MISSION_var_helicopters` | Public | Config hélicos (défini init.sqf) |
| `MISSION_intro_heli` | Public | Référence hélico intro |
| `MISSION_intro_finished` | Public | Signal fin cinématique |

---

## Localisation (stringtable.xml)

| Clé | Usage |
|-----|-------|
| `STR_INTRO_AUTHOR` | Nom auteur (plan 1) |
| `STR_INTRO_PRESENTS` | "présente..." (plan 1) |
| `STR_INTRO_TITLE` | Titre mission (plan 2) |
| `STR_INTRO_SUBTITLE` | Sous-titre (plan 3) |
| `STR_MISSION_START` | "OPERATION S.A.Y.E" (fin) |
| `STR_MISSION_START_SUBTITLE` | Instructions (fin) |

---

## Musique (CfgMusic)

| Piste | Timing |
|-------|--------|
| `intro_00` | Début cinématique, fade 3s |

---

## Timeline Complète

```
CLIENT                              SERVER
──────                              ──────
T+0s   Écran noir                   Attente MISSION_var_helicopters
       Effets post-process          
       
T+0.5s                              Création hélico 1300m
                                    Embarquement joueurs
                                    
T+1s                                Vol vers QG (200 km/h)

T+3s   Plan 1-2: Survol ville       
       Texte auteur                 
       
T+11s  Texte titre                  

T+15s  Attente MISSION_intro_heli   Ouverture portes

T+16s  Plan 3: Vue hélico           
       Texte sous-titre             

T+31s  Transition noire             

T+32s  Plan 4: Orbite hélico        Ralentissement 120 km/h

T+46s  Plan 5: Vue aérienne QG      Approche finale

T+?    Attente atterrissage         land "GET OUT"

T+?    Attente débarquement         Débarquement joueurs
                                    Fermeture portes
                                    
T+?    Fin cinématique              Décollage sortie
       Texte mission start          
       MISSION_intro_finished       
       
T+70s                               Suppression hélico
```

---

## Dépendances

### Fonctions BIS
- `BIS_fnc_dynamicText`
- `BIS_fnc_getUnitInsignia`
- `BIS_fnc_setUnitInsignia`

### Mods
- **AMF** : `amf_nh90_tth_transport`, insigne `AMF_FRANCE_HV`
