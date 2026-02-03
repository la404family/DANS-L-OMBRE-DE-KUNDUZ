# fn_task_fin.sqf - Système de Fin de Mission

## Exécution
- **Contexte** : Server uniquement (`if (!isServer) exitWith {}`)
- **Déclenchement** : Appelé depuis `init.sqf` via `spawn`

---

## Paramètres Configurables

| Variable | Valeur | Description |
|----------|--------|-------------|
| `_delayBeforeMessage` | 2-7s (random) | Délai avant lancement extraction |
| `_heliClass` | `amf_nh90_tth_transport` | Classe hélicoptère NH90 AMF |
| `_flyTime` | 100s | Durée vol de sortie avant fin mission |
| `_descentRate` | -3.0 m/s | Vitesse descente forcée |
| `_checkInterval` | 10s | Intervalle vérification joueurs embarqués |

---

## Objets Éditeur Requis

| Variable | Fallback | Description |
|----------|----------|-------------|
| `heli_fin` | `marker_4` → `respawn_west` → position joueur | Point d'atterrissage LZ |
| `heli_fin_spawn` | 3km direction aléatoire, alt 150m | Point de spawn hélicoptère |
| `heli_fin_direction` | Direction opposée au spawn | Point de sortie après embarquement |

---

## Flux d'Exécution

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. INITIALISATION                                               │
├─────────────────────────────────────────────────────────────────┤
│ • Récupération position heli_fin (ou fallbacks)                 │
│ • Récupération position heli_fin_spawn (ou spawn aléatoire 3km) │
│ • Délai aléatoire 2-7 secondes                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. CRÉATION TÂCHE                                               │
├─────────────────────────────────────────────────────────────────┤
│ • BIS_fnc_taskCreate : "task_evacuation"                        │
│ • Titre/Description localisés (STR_TASK_EVAC_*)                 │
│ • Icône : "takeoff"                                             │
│ • Délai 10s avant spawn hélicoptère                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. CRÉATION HÉLICOPTÈRE & ÉQUIPAGE                              │
├─────────────────────────────────────────────────────────────────┤
│ Hélicoptère:                                                    │
│ • Spawn en vol (FLY) à 100m altitude                            │
│ • allowDamage false (invincible)                                │
│                                                                 │
│ Équipage (groupe WEST):                                         │
│ • 1 Pilote (B_Helipilot_F) → driver                             │
│ • 1 Copilote (B_Helipilot_F) → turret [0]                       │
│ • N Mitrailleurs (B_Soldier_F) → autres tourelles               │
│                                                                 │
│ Configuration équipage:                                         │
│ • setCaptive true (ignoré par ennemis)                          │
│ • allowDamage false                                             │
│ • MISSION_TemplateApplied = true (protection script civil)      │
│ • disableAI: FSM, AUTOTARGET, TARGET, AUTOCOMBAT, SUPPRESSION   │
│ • setBehaviour "CARELESS" + setCombatMode "BLUE"                │
│ • Loadout: B_AMF_UBAS_DA_SUA_HK416                              │
│ • Casque pilote: H_PilotHelmetHeli_B (pilote/copilote)          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. SYSTÈME D'ATTERRISSAGE - 4 PHASES                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ PHASE 1 : TRANSIT VERS POINT D'APPROCHE                         │
│ ├── Altitude: 100m                                              │
│ ├── Vitesse: FULL                                               │
│ ├── Waypoint MOVE → 500m avant LZ                               │
│ └── Attente: distance < 100m                                    │
│                                                                 │
│ PHASE 2 : APPROCHE FINALE                                       │
│ ├── Altitude: 50m                                               │
│ ├── Vitesse: LIMITED (80 km/h max)                              │
│ ├── Waypoint MOVE → LZ                                          │
│ └── Attente: distance < 80m                                     │
│                                                                 │
│ PHASE 3 : POSITIONNEMENT AU-DESSUS LZ                           │
│ ├── Altitude: 20m                                               │
│ ├── Vitesse: 20 km/h max                                        │
│ ├── Waypoint MOVE → LZ (rayon complétion 10m)                   │
│ └── Attente: distance < 20m (timeout 60s)                       │
│                                                                 │
│ PHASE 4 : DESCENTE FORCÉE (setVelocity)                         │
│ ├── doStop + land "GET IN"                                      │
│ ├── Boucle 0.1s:                                                │
│ │   ├── Si alt > 1m: setVelocity descente -3.0 m/s              │
│ │   └── Si dérive > 3m: correction horizontale (max 2 m/s)      │
│ ├── Timeout: 60s                                                │
│ └── Sortie: isTouchingGround || alt < 0.5m                      │
│                                                                 │
│ FINALISATION:                                                   │
│ • setVelocity [0,0,0] (arrêt complet)                           │
│ • setFuel 0 (coupe moteur)                                      │
│ • deleteVehicle hélipad invisible                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. EMBARQUEMENT JOUEURS                                         │
├─────────────────────────────────────────────────────────────────┤
│ Préparation:                                                    │
│ • setVehicleLock "UNLOCKED"                                     │
│ • Ouverture rampe: animateSource/animateDoor "Ramp"             │
│ • Tâche → état "ASSIGNED"                                       │
│                                                                 │
│ Boucle vérification (toutes les 20s):                           │
│ • Compte joueurs vivants: alive && isPlayer && !isNull          │
│ • Compte joueurs à bord: vehicle == _heli                       │
│ • Affichage hint: STR_EVAC_PLAYER_COUNT                         │
│ • Si 0 joueur vivant: warning "Aucun survivant détecté..."      │
│ • Succès: tous les joueurs VIVANTS sont à bord                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. DÉCOLLAGE & FIN DE MISSION                                   │
├─────────────────────────────────────────────────────────────────┤
│ • Tâche → état "SUCCEEDED"                                      │
│ • Joueurs embarqués: hideObjectGlobal + allowDamage false       │
│ • Musique: "outro_00"                                           │
│ • Fermeture rampe/portes                                        │
│ • setVehicleLock "LOCKED"                                       │
│ • Destruction ennemis 1000m (EAST/INDEP/RESISTANCE)             │
│                                                                 │
│ Vol de sortie:                                                  │
│ • Direction: heli_fin_direction (ou opposée au spawn)           │
│ • Altitude: 50m                                                 │
│ • Vitesse: 300 km/h                                             │
│ • Durée: 120s (_flyTime)                                        │
│                                                                 │
│ • BIS_fnc_endMission "END1"                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Diagramme Approche Hélicoptère

```
                    [heli_fin_spawn]
                         │
                         │ 100m altitude
                         │ Vitesse FULL
                         ▼
              ┌──────────────────────┐
              │   POINT D'APPROCHE   │ ← 500m de la LZ
              │   (Phase 1 → 2)      │
              └──────────────────────┘
                         │
                         │ 50m altitude
                         │ 80 km/h max
                         ▼
              ┌──────────────────────┐
              │   AU-DESSUS LZ       │ ← < 20m horizontal
              │   (Phase 2 → 3)      │   20m altitude
              └──────────────────────┘
                         │
                         │ setVelocity
                         │ -3.0 m/s descente
                         ▼
              ┌──────────────────────┐
              │     [heli_fin]       │ ← LZ
              │   (Phase 4 - Sol)    │
              └──────────────────────┘
```

---

## Logs Serveur (diag_log)

| Préfixe | Message |
|---------|---------|
| `[FIN_MISSION]` | Tous les logs du système |
| `=== ... ===` | Étapes majeures |
| `PHASE X -` | Phases d'atterrissage |
| `✓` | Succès |
| `WARN:` | Avertissements |
| `ERREUR:` | Erreurs (fallbacks utilisés) |
| `ERREUR CRITIQUE:` | Erreurs bloquantes |

---

## Dépendances

### Fonctions BIS
- `BIS_fnc_taskCreate`
- `BIS_fnc_taskSetDestination`
- `BIS_fnc_taskSetState`
- `BIS_fnc_endMission`

### Localisation (stringtable.xml)
- `STR_TASK_EVAC_DESC`
- `STR_TASK_EVAC_TITLE`
- `STR_EVAC_PLAYER_COUNT`

### Mods
- **AMF** : `amf_nh90_tth_transport`, `B_AMF_UBAS_DA_SUA_HK416`

### Musique (CfgMusic)
- `outro_00`
