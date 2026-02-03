# OPERATION S.A.Y.E - Kunduz Valley

## Informations Mission
| Paramètre | Valeur |
|-----------|--------|
| Auteur | Kevin (@la404family) |
| Map | Kunduz Valley |
| Type | COOP |
| Joueurs | 1-40 |
| Respawn | BASE (délai 10s) |
| Faction | Armée Française (AMF) |

---

## Architecture du Projet

```
OPERATION%20SAYE.kunduz_valley/
├── description.ext          # Configuration mission + déclaration fonctions
├── init.sqf                 # Point d'entrée, initialisation serveur/client
├── mission.sqm              # Données éditeur 3DEN
├── stringtable.xml          # Localisation FR/EN
│
├── functions/               # Scripts SQF
│   ├── fn_ajust_AI_skills.sqf
│   ├── fn_ajust_BLUFOR_identity.sqf
│   ├── fn_ajust_team_leader.sqf
│   ├── fn_ajuste_badge.sqf
│   ├── fn_civilian_presence_logic.sqf
│   ├── fn_civilian_template.sqf
│   ├── fn_ezan.sqf
│   ├── fn_livraison_gestion.sqf
│   ├── fn_livraison_munitions.sqf
│   ├── fn_livraison_soutienAR.sqf
│   ├── fn_livraison_vehicule.sqf
│   ├── fn_spawn_vehicles.sqf
│   ├── fn_task_fin.sqf
│   └── fn_task_intro.sqf
│
├── dialogs/
│   ├── defines.hpp          # Macros UI (CT_*, ST_*, couleurs)
│   └── vehicle_menu.hpp     # Dialog garage véhicules (IDD 8888)
│
├── audio/                   # Sons radio livraisons
│   ├── livraison01-09.ogg
│   ├── negatif01-04.ogg
│   └── soutien01-04.ogg
│
└── music/
    ├── ezan.ogg             # Appel à la prière
    ├── intro.ogg
    └── outro.ogg
```

---

## Flux d'Initialisation

```
init.sqf
    │
    ├─[SERVER]─────────────────────────────────────────────────────────────┐
    │   ├── MISSION_var_helicopters (variable globale hélicos)             │
    │   ├── Mission_fnc_ajuste_badge ──────────────────────────────────────│─► Synchronise insignes BLUFOR
    │   ├── Mission_fnc_civilian_template ─────────────────────────────────│─► Mémorise templates civils (civil_template_00-33)
    │   ├── Mission_fnc_civilian_presence_logic ───────────────────────────│─► Applique apparence civils dynamiquement
    │   ├── Mission_fnc_ezan ──────────────────────────────────────────────│─► Diffuse prière depuis minarets (ezan_00-09)
    │   ├── Mission_fnc_spawn_vehicles ────────────────────────────────────│─► Ajoute action garage aux joueurs
    │   ├── Mission_fnc_ajust_AI_skills ───────────────────────────────────│─► Configure skills IA (EAST/WEST)
    │   ├── Mission_fnc_ajust_team_leader ─────────────────────────────────│─► Force leader humain
    │   ├── Mission_fnc_task_fin                                           │
    │   └── Mission_fnc_ajust_BLUFOR_identity ─────────────────────────────│─► Noms français aux BLUFOR
    │                                                                      │
    └─[CLIENT]─────────────────────────────────────────────────────────────┘
        └── Mission_fnc_livraison_gestion ["INIT"] ────► Menu radio (0-8)
```

---

## Système de Livraison

### Architecture
```
CfgCommunicationMenu (description.ext)
    ├── VehicleDrop  ──┐
    ├── AmmoDrop     ──┼──► Mission_fnc_livraison_gestion
    └── CASDrop      ──┘
                          │
                          ▼
              ┌─────────────────────────┐
              │ livraison_gestion.sqf   │
              │  ├── MODE: INIT         │ → Ajoute items menu radio (déverrouillage progressif 120-240s)
              │  ├── MODE: REQUEST      │ → Client demande, vérifie cooldown
              │  └── MODE: EXECUTE      │ → Server exécute livraison
              └─────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
fn_livraison_      fn_livraison_     fn_livraison_
vehicule.sqf       munitions.sqf     soutienAR.sqf
```

### Variables Globales Livraison
| Variable | Type | Description |
|----------|------|-------------|
| `MISSION_Unlock_Vehicle` | Bool | Déverrouille livraison véhicule |
| `MISSION_Unlock_Ammo` | Bool | Déverrouille livraison munitions |
| `MISSION_Unlock_CAS` | Bool | Déverrouille soutien aérien |
| `MISSION_Delivery_Global_Cooldown` | Bool | Cooldown global (240-420s) |

### Objets Éditeur Requis
- `waypoint_livraison_000` à `waypoint_livraison_127` : Points d'atterrissage sécurisés

---

## Système Civils

### Flux
```
fn_civilian_template.sqf (SERVER)
    │
    │  Lit civil_template_00 à civil_template_33 (objets éditeur)
    │  Extrait: type, loadout, face, isFemale, pitch
    │  Stocke dans MISSION_CivilianTemplates
    │  Supprime les templates de la map
    │
    ▼
fn_civilian_presence_logic.sqf (SERVER)
    │
    │  Définit MISSION_CivilianNames_Male/Female (150+ noms afghans)
    │  Définit MISSION_fnc_applyCivilianTemplate
    │  Applique aux agents existants
    │  Écoute "EntityCreated" pour nouveaux civils
    │
    ▼
    Tous les civils/OPFOR/INDEP reçoivent:
    - Apparence aléatoire (template)
    - Nom afghan aléatoire
    - Pitch voix ajusté (femmes: 1.2-1.4)
```

### Variables Globales Civils
| Variable | Type | Description |
|----------|------|-------------|
| `MISSION_CivilianTemplates` | Array | [[type, loadout, face, isFemale, pitch], ...] |
| `MISSION_CivilianNames_Male` | Array | Noms masculins afghans |
| `MISSION_CivilianNames_Female` | Array | Noms féminins afghans |

---

## Système Garage Véhicules

### Flux
```
fn_spawn_vehicles.sqf
    │
    ├── MODE: INIT (hasInterface)
    │       Ajoute action "Accéder au Parc Véhicules"
    │       Condition: player inArea vehicles_request
    │
    ├── MODE: OPEN_UI
    │       Ouvre Dialog IDD 8888 (vehicle_menu.hpp)
    │       Liste véhicules WEST (Cars, excl. blindés/air)
    │       Tri: AMF en premier (orange), autres (gris)
    │
    ├── MODE: SPAWN
    │       Supprime véhicules existants dans zone
    │       Crée véhicule sur vehicles_spawner
    │
    └── MODE: DELETE
        Supprime tous véhicules dans vehicles_request
```

### Objets Éditeur Requis
| Nom Variable | Type | Fonction |
|--------------|------|----------|
| `vehicles_request` | Trigger/Area | Zone d'activation menu |
| `vehicles_spawner` | Object | Position/direction spawn |

---

## Système Audio

### CfgSounds (description.ext)
| Son | Fichier | Usage |
|-----|---------|-------|
| `Radio_In` | A3 vanilla | Début transmission |
| `Radio_Out` | A3 vanilla | Fin transmission |
| `livraison01-09` | audio/*.ogg | Confirmations livraison |
| `soutien01-04` | audio/*.ogg | Confirmations CAS |
| `negatif01-04` | audio/*.ogg | Refus (cooldown) |

### CfgMusic
| Piste | Fichier | Usage |
|-------|---------|-------|
| `ezan` | music/ezan.ogg | Appel prière (say3D 2500m) |
| `intro_00` | music/intro.ogg | Musique intro |
| `outro_00` | music/outro.ogg | Musique fin |

---

## Système Ezan (Appel à la Prière)

```
fn_ezan.sqf (SERVER)
    │
    │  Délai initial: 300-900s
    │  Boucle infinie (1800s interval)
    │
    └── Pour chaque minaret (ezan_00, ezan_01, ezan_02):
            Si joueurs < 2500m → say3D "ezan"
```

### Objets Éditeur Requis
- `ezan_00`, `ezan_01`, `ezan_02` : Loudspeakers (minarets)

---

## Skills IA

### fn_ajust_AI_skills.sqf
| Skill | OPFOR/INDEP | BLUFOR |
|-------|-------------|--------|
| aimingAccuracy | 0.10-0.25 | 0.35-0.50 |
| aimingShake | 0.10-0.30 | 0.40-0.60 |
| aimingSpeed | 0.10-0.40 | 0.40-0.60 |
| spotDistance | 0.10-0.60 | 0.60-0.80 |
| spotTime | 0.10-0.50 | 0.65-0.75 |
| courage | 1.0 | 1.0 |
| allowFleeing | 0 | 0 |

Boucle de mise à jour: 60s

---

## Identités BLUFOR

### fn_ajust_BLUFOR_identity.sqf
Bases de noms français diversifiées:
- `_names_standard` : Noms français classiques
- `_names_african` : Origines africaines
- `_names_arab` : Origines maghrébines
- `_names_asian` : Origines asiatiques
- `_names_pacific` : Origines pacifiques

---

## CfgRemoteExec

| Fonction | allowedTargets | Description |
|----------|----------------|-------------|
| `Mission_fnc_ezan` | 0 (tous) | Diffusion audio |
| `Mission_fnc_livraison_gestion` | 2 (server) | Exécution livraisons |

| Commande | allowedTargets |
|----------|----------------|
| `playSoundParams` | 0 |
| `playSound` | 0 |
| `systemChat` | 0 |

---

## Objets Éditeur Référencés

| Variable | Quantité | Type | Usage |
|----------|----------|------|-------|
| `player_0` à `player_4` | 5 | Unités | Joueurs/jouables |
| `waypoint_invisible_000` à `340` | 341 | CUP_A1_Road_road_invisible | Points missions |
| `civil_template_00` à `33` | 34 | Civils | Templates apparence |
| `ezan_00` à `09` | 10 | Loudspeaker | Minarets |
| `waypoint_livraison_000` à `127` | 128 | Markers/Objects | LZ hélicos |
| `vehicles_request` | 1 | Trigger | Zone garage |
| `vehicles_spawner` | 1 | Object | Spawn véhicules |

---

## Dépendances Mods

- **AMF** (Armées de France) : Véhicules, uniformes, insignes
- **CUP** : Objets terrain (road_invisible)

---

## Localisation (stringtable.xml)

### Packages
- `Intro` : Textes cinématique
- `VehicleSystem` : Interface garage + livraisons

### Clés Principales
| ID | FR |
|----|-----|
| `STR_ACTION_GARAGE` | Accéder au Parc Véhicules |
| `STR_ACTION_DELIVERY` | Demander Livraison Véhicule |
| `STR_ACTION_AMMO_DELIVERY` | Demander Ravitaillement Munitions |
| `STR_ACTION_CAS` | Demander Soutien Aérien (50m) |
| `STR_LIVRAISON_INBOUND` | PC à toutes les unités : Transport en route... |