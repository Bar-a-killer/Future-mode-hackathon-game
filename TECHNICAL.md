# NOXCAT - Technical Documentation

## Architecture Overview

NOXCAT uses a modular event-driven architecture built on Godot 4.7 with the following core systems:

```
┌─────────────────────────────────────────────────────────────┐
│                      Main Game Loop                          │
│                    (RoundManager FSM)                        │
└─────────────────────────────────────────────────────────────┘
              ↓              ↓              ↓
    ┌──────────────┐ ┌────────────┐ ┌──────────────┐
    │   Monsters   │ │   Player   │ │   UI/Items   │
    │  & Bullets   │ │  & Input   │ │   & Effects  │
    └──────────────┘ └────────────┘ └──────────────┘
              ↓              ↓              ↓
    ┌─────────────────────────────────────────────┐
    │         EventBus (Signal Hub)               │
    └─────────────────────────────────────────────┘
              ↓              ↓              ↓
    ┌──────────────┐ ┌────────────┐ ┌──────────────┐
    │ GridManager  │ │   Wallet   │ │MusicManager  │
    │ (Occupancy)  │ │  (Score)   │ │  (Audio)     │
    └──────────────┘ └────────────┘ └──────────────┘
```

## Autoload Systems (Global Singletons)

### EventBus
**File**: `autoload/event_bus.gd`

Central signal hub for all game events. Decouples components through loose coupling.

**Key Signals**:
```gdscript
signal round_state_changed(new_state, old_state)
signal wave_spawn_requested(wave_index)
signal monster_spawned(monster)
signal monster_died(monster, grid_pos)
signal bullet_hit_monster(bullet, monster)
signal player_damaged(amount, new_hp)
signal player_healed(amount, new_hp)
signal game_over
signal boss_defeated
signal boss_warning
signal item_selected(item)
signal status_applied(target, status_name)
```

### RoundManager
**File**: `autoload/round_manager.gd`

Implements the game loop using a Finite State Machine (FSM):

```
WAVE_SPAWN → PLAYER_AIM → RESOLVE → MONSTER_ATTACK → MOVEMENT_CHECK → SLOT_MACHINE_CHECK → GAME_OVER_CHECK → (GAME_OVER or back to WAVE_SPAWN)
```

**States**:
- **WAVE_SPAWN**: Spawn enemies for the round (or boss at round 10)
- **PLAYER_AIM**: Player can shoot
- **RESOLVE**: Prepare for monster actions
- **MONSTER_ATTACK**: Monsters move and attack
- **MOVEMENT_CHECK**: Player randomly moves to different lane
- **SLOT_MACHINE_CHECK**: Every 3 rounds, show item selection
- **GAME_OVER_CHECK**: Check if player is dead
- **GAME_OVER**: End game state

**Boss Logic**:
- Round 9: Boss warning displayed
- Round 10: Boss spawns, no regular monsters generated
- After Round 10: Boss prevents monster spawning until defeated

### GridManager
**File**: `autoload/grid_manager.gd`

Manages grid-based monster positioning and occupancy.

**Grid Layout**:
- 7 columns (0-6) × 9 rows (0-8)
- Cell size: 90×90 pixels
- Spawn row: Row 1 (where monsters appear)
- Origin: (45, 90)

**Key Functions**:
```gdscript
func cell_to_world(cell: Vector2i) -> Vector2
func world_to_cell(pos: Vector2) -> Vector2i
func is_occupied(cell: Vector2i) -> bool
func occupy(cell: Vector2i, node: Node)
func vacate(cell: Vector2i)
func get_wave_spawn_cells(count: int, row: int) -> Array[Vector2i]
```

### Wallet
**File**: `autoload/wallet.gd`

Manages player score and economic systems.

**Events**:
- Score changes trigger UI updates
- Death handling and resets

### ItemManager
**File**: `autoload/item_manager.gd`

Manages collectible power-ups and their effects.

**Item Pool**: 11 items with different effects
- Damage modifiers (Fireball, Triple Shot, Wave Shot, Enlarge Bullet)
- Defensive items (Freeze Gun, Shockwave, Random Heal)
- Economy items (Instant Score, Score x2, Random Ball Boost)
- Utility (Portal)

### MusicManager
**File**: `autoload/music_manager.gd`

Manages background music playback with loop support.

**Features**:
- Auto-loops background music
- Fade out on game over
- Fade in on game restart

## Core Game Objects

### Monster (MonsterBase)
**File**: `scenes/monsters/monster_base.gd`

Base class for all enemies with shared behavior.

**Key Features**:
- **Status System**: Fire (damage over time) and Freeze (movement block)
- **Hit Feedback**: Visual scaling and flash animation on damage
- **Grid Movement**: Moves forward one cell per round (unless frozen/is_boss)
- **Boss Flag**: `is_boss` prevents movement and triggers victory condition

**Status Effects**:
```gdscript
const FIRE_DURATION := 2           # Ticks
const FREEZE_DURATION := 1         # Ticks
const FIRE_TICK_DAMAGE := 2        # Per tick
```

**Monster Types**:
1. Small Melee (HP: 20, Scale: 0.06)
2. Small Ranged (HP: 15, Scale: 0.05)
3. Big Melee (HP: 40, Scale: 0.07)
4. Big Melee Special (HP: 50, Scale: 0.08)
5. Boss (HP: 200, Scale: 0.18, Attack: 9999)

### Player
**File**: `scenes/player/player.gd`

Player-controlled turret with health and firing mechanics.

**Attributes**:
- HP: Tracks current health (starts at 100)
- Can Aim: Flag for input acceptance during PLAYER_AIM state
- Ball Count: Modified by items
- Lane Position: 5 lanes (columns 1, 2, 3, 4, 5)

**Mechanics**:
- Mouse-based aiming
- Click to fire balls
- Takes damage from monsters
- Random lane movement every 2-4 rounds

### Bullet
**File**: `scenes/player/bullet.gd`

Projectile fired by player toward monsters.

**Mechanics**:
- Collision detection with monsters
- Applies damage and status effects
- Scales based on item modifiers
- Destroyed on monster hit or map edge

### Score Orb
**File**: `scenes/orbs/score_orb.gd`

Floating item dropped by dying monsters.

**Mechanics**:
- Float upward
- Auto-collect when near player
- Trigger score changes
- Tween animation for visual feedback

## Game Data Structures

### ItemData Resource
**File**: `resources/items/item_data.gd`

Defines item properties and effects.

**Fields**:
```gdscript
var id: StringName              # Unique identifier
var display_name: String        # UI name
var description: String         # Effect description
var icon: Texture2D             # UI icon
var icon_region: Rect2          # Cropped region
var effect_type: int            # 0=modifier, 1=one-shot, 2=passive
```

### MonsterStats Resource
**File**: `resources/monsters/monster_stats.gd`

Defines monster attributes.

**Fields**:
```gdscript
var max_hp: int
var attack_power: int
var frontal_damage_reduction: float  # Armor
var score_orb_drop_chance: float
```

## Visual Effects System

### StatusOverlay
**File**: `scenes/monsters/status_overlay.gd`

Animated status effect overlays for freeze and fire.

**Fire Effect**:
- Two layers (FireA back, FireB front) with different animation frequencies
- Scales: Back 1.52×, Front 0.84× (at 0.6 original size)
- Breathing and floating animation

**Freeze Effect**:
- Ice shell overlay
- Scale: 0.928× (at 0.6 original size)
- Subtle rotation and breathing

**Animation Constants**:
```gdscript
const ICE_COVER := 0.696         # Size relative to monster
const FIRE_BACK_COVER := 1.14
const FIRE_FRONT_COVER := 0.63
const FIRE_Y_BIAS := -0.32        # Vertical offset
```

## UI Systems

### HUD
**File**: `scenes/ui/hud.tscn`

Main UI overlay showing:
- Current round number
- Player HP
- Current score
- Active item modifier

### GameOverScreen
**File**: `scenes/ui/game_over_screen.gd`

End game screen with:
- "GAME OVER" message
- Final score display
- Restart button
- Music fade out

### VictoryScreen
**File**: `scenes/ui/victory_screen.gd`

Boss defeat screen with:
- "VICTORY!" message
- Final score
- Restart button

### BossWarningScreen
**File**: `scenes/ui/boss_warning_screen.gd`

Pre-boss notification:
- Large red "BOSS WARNING!" text (120pt)
- Pop-out animation
- Displays at round 9 entrance

### SlotMachineUI
**File**: `scenes/slot_machine/slot_machine_ui.gd`

Item selection interface:
- 3 reels spinning animation
- Item preview with description
- Hover tooltips

## Damage System

### Damage Flow
```
Bullet → Monster.take_damage()
         ↓
    Check status effects
         ↓
    Apply multipliers (2× if frozen + opposite element)
         ↓
    Apply armor reduction
         ↓
    Apply status effect
         ↓
    Check if dead → die() or _play_hit_feedback()
```

### Fire + Freeze Interaction
- Fire burns away freeze status
- Freeze extinguishes fire status
- Switching status is instant (old status erased)
- Fire damage 2× against frozen enemies

### Hit Feedback
- Flash white: 0.12s
- Scale punch: 1.08× multiplier
- Easing: BACK out

## Game Flow

### Single Round Flow

```
1. WAVE_SPAWN
   ├─ Emit wave_spawn_requested signal
   ├─ If round 9: Emit boss_warning signal
   ├─ If round 10: Spawn boss (no monsters)
   └─ Else: Spawn 4-6 random monsters

2. PLAYER_AIM (waits for player input)
   ├─ Player can aim and fire
   ├─ Bullets travel and collide
   └─ Volley_resolved signal triggers next state

3. POST_VOLLEY (0.5s delay)
   └─ Prepare for monster actions

4. MONSTER_ATTACK
   ├─ For each monster (sorted by depth):
   │  ├─ advance() - Move forward (if not frozen/boss)
   │  ├─ execute_attack() - Deal damage to player
   │  └─ tick_status() - Reduce status durations
   └─ Check for game over

5. MOVEMENT_CHECK (random every 2-4 rounds)
   └─ Player moves to random lane with animation

6. SLOT_MACHINE_CHECK (every 3 rounds)
   ├─ Show 3 random items
   ├─ Wait for selection
   └─ Apply chosen item effect

7. GAME_OVER_CHECK
   ├─ If player HP <= 0: Go to GAME_OVER
   └─ Else: Increment round, return to WAVE_SPAWN
```

### Boss Fight Special Case
- Round 9: Warning only, normal monsters spawn
- Round 10: Boss spawns, NO monsters spawn for any future rounds while boss alive
- Boss death: Victory condition triggered
- Boss stats: HP 200, Attack 9999 (one-shot)
- Boss behavior: Same as monsters but doesn't move forward

## Performance Considerations

### Optimizations
1. **Tween caching**: Killed tweens prevent animation pile-up
2. **Group-based queries**: `get_tree().get_nodes_in_group("monsters")`
3. **Signal connections**: Autoloads connect once in _ready()
4. **Object pooling**: Score orbs destroyed immediately
5. **Visual batching**: Polygon2D for walls instead of individual sprites

### Memory Management
- Monsters added to "monsters" group
- Monsters removed from group on death
- GridManager occupancy cleared on game reset
- Music looped (not reloaded)

## Extending the Game

### Adding a New Monster Type

1. Create stats resource: `resources/monsters/new_monster_stats.tres`
2. Create scene: `scenes/monsters/new_monster.tscn`
   - Inherits MonsterBase
   - Add Visual sprite with appropriate scale
   - Add StatusOverlay child
3. Export stats in inspector
4. Add to MONSTER_SCENES array in round_manager.gd

### Adding a New Item

1. Create resource: `resources/items/data/item_newitem.tres`
2. Set properties: name, description, icon, icon_region
3. Add to ItemManager.ITEM_POOL
4. Implement effect in ItemManager.apply_item()
5. Add icon image to `picture/` folder

### Adding a New Status Effect

1. Add constants to MonsterBase: `STATUS_NAME_DURATION`
2. Add tint to STATUS_TINTS dictionary
3. Implement animation in StatusOverlay._animate_STATUS()
4. Apply effect in apply_status() and take_damage()

## Dependencies

- **Godot 4.7.2**: Core engine
- **GDScript 2.0**: Strict type checking enabled
- **Tween System**: Animation framework
- **AudioStreamPlayer**: Music playback

## Known Limitations

1. **No pause system**: Game continues during menu
2. **No save/load**: Progress not saved
3. **Single difficulty**: Waves always scale similarly
4. **No multiplayer**: Single player only
5. **Limited custom keybinds**: Mouse-only controls

## Performance Targets

- **FPS**: 60 stable (desktop)
- **Memory**: ~200MB base + assets
- **Frame time**: < 16ms per frame
- **Monster limit**: Tested up to 20 monsters on screen

## Debug Features

### Console Commands (in Godot editor)
```gdscript
# Get all monsters
get_tree().get_nodes_in_group("monsters")

# Get grid state
GridManager._occupancy

# Get player stats
RoundManager.player.hp
RoundManager.player.ball_count
```

### Useful Print Statements
Add to RoundManager._enter_state() for state tracking:
```gdscript
print("Entering state: ", State.keys()[new_state])
```

## Future Improvements

1. **Difficulty scaling**: Progressive wave complexity
2. **Achievements system**: Reward player milestones
3. **Sound effects**: Add SFX for hits, spawns, effects
4. **Pause menu**: Ability to pause and resume
5. **Multiple bosses**: Different boss types per difficulty
6. **Particle effects**: Enhanced visual feedback
7. **Controller support**: Gamepad controls
