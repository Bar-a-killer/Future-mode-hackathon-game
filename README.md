# NOXCAT

A Godot 4 tower defense game featuring strategic ball shooting mechanics, status effects, and boss encounters.

## Features

- **Ball Shooting Mechanics** - Aim and fire balls to destroy incoming monsters
- **Status Effects** - Apply fire and freeze effects to control enemies
- **Item System** - Collect power-ups including fireballs, freeze guns, shields, and more
- **Boss Encounters** - Face a challenging boss at round 10
- **Progressive Difficulty** - More challenging waves as you advance
- **Sound** - Background music that loops throughout gameplay

## System Requirements

- **Godot Engine 4.7+** (tested with 4.7.2)
- **Windows 10+** or macOS/Linux with Godot support
- **Minimum RAM**: 2GB
- **GPU**: Any GPU that supports OpenGL Compatibility mode

## How to Run Locally

### Option 1: Using Godot Editor

1. **Download Godot**
   - Download Godot 4.7.2 from [godotengine.org](https://godotengine.org)
   - Choose the version matching your OS

2. **Open the Project**
   - Launch Godot Editor
   - Click "Open Project" and navigate to the `noxcat` folder
   - Select `project.godot` and open

3. **Run the Game**
   - Press `F5` or click the Play button (▶) in the top right
   - The game will launch in a new window

### Option 2: Using Command Line

```bash
# Navigate to project directory
cd noxcat

# Run with Godot executable
"C:\path\to\Godot_v4.7.2-stable_win64.exe" --path .
```

### Option 3: Export as Standalone

1. In Godot Editor: `Project` → `Export...`
2. Create a new Windows export template
3. Configure export settings
4. Click `Export Project`
5. Run the generated `.exe` file

## Gameplay

### Controls
- **Mouse** - Aim and adjust shooting angle
- **Left Click** - Fire balls
- **Navigate UI** - Click buttons to select items

### Objective
- Destroy all waves of monsters
- Reach round 10 and defeat the boss
- Survive as long as possible to maximize score

### Game Mechanics
- **Waves** - Monsters spawn in regular waves
- **Items** - Every 3 rounds, pick one of 3 random power-ups
- **Status Effects**:
  - **Fire** - Deals damage over time (2x damage to frozen enemies)
  - **Freeze** - Stops enemy movement and attacks for 1 round
- **Boss Round** - Round 9 shows warning, Round 10 spawns final boss

## Project Structure

```
noxcat/
├── scenes/           # Game scenes and UI
│   ├── main/        # Main game scene
│   ├── player/      # Player/turret scene
│   ├── monsters/    # Monster prefabs
│   ├── ui/          # UI elements
│   └── orbs/        # Score orb effects
├── autoload/        # Global singletons
├── resources/       # Data files (items, stats)
├── picture/         # Game assets and sprites
├── music/          # Background music
├── scripts/        # Additional scripts
└── project.godot   # Project configuration
```

## Build Output

The `demo/` folder contains exported build files for distribution.

## Credits

- **Engine**: Godot 4.7.2
- **Music**: FesliyanStudios.com
- **Development**: NOXCAT Team

## Troubleshooting

### Game Won't Start
- Ensure Godot 4.7+ is installed
- Check that all asset files exist in `picture/` folder
- Verify `music/FesliyanStudios.com.mp3` is present

### Performance Issues
- Disable V-Sync in Project Settings if frame rate is low
- Reduce visual effects intensity
- Check that GPU drivers are up to date

### Missing Audio
- Verify music file exists at `music/FesliyanStudios.com.mp3`
- Check audio device is working
- Restart the game if audio doesn't play

## License

See LICENSE file for license details.
