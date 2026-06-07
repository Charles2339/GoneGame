Game name-- "Gone:endless runner"

# 🎮 Android 2D Modern Endless Runner — Complete Game Development Prompt

---

## OVERVIEW & VISION

You are building a **modern 2D endless runner for Android** — a polished, fast-paced mobile game where the player character runs automatically and the player's job is to survive as long as possible by jumping, sliding, and dodging increasingly difficult procedurally-generated obstacles. The game must feel **physically convincing**, visually stunning, and deeply satisfying to play. Think a spiritual fusion of Alto's Odyssey's fluidity, Subway Surfers' momentum, and Hollow Knight's animation quality — but in a 2D side-scrolling format.

The target platform is **Android (API level 24+, Android 7.0 and above)**. The target device range is mid-range Android phones (2GB–4GB RAM, Mali/Adreno GPU). The game must run at a **locked 60 FPS** on mid-range hardware with no frame drops during normal gameplay.

---

## ENGINE & FRAMEWORK

### Primary Engine: Godot 4.x (latest stable)

Use **Godot 4.3 or newer** (check godotengine.org for the latest stable release at time of development). Do NOT use Godot 3.x — Godot 4 has a fundamentally superior 2D physics engine, better GPU rendering pipeline, improved animation system, and much better Android export toolchain.

**Why Godot 4:**
- Built-in CharacterBody2D with `move_and_slide()` for smooth, frame-rate-independent character movement
- PhysicsServer2D for fine-grained physics control
- AnimationTree with StateMachine for blended, reactive animations
- Parallax layers built into the engine natively
- One-click Android APK/AAB export (after SDK setup)
- GDScript 2.0 is Python-like, readable, and fast to prototype in
- No royalties, no licensing cost

### Language: GDScript (primary) + C# (optional optimization)

Use **GDScript** for all game logic, UI, and scene management. It is tightly integrated with Godot and has zero overhead for engine API calls. If you later need to squeeze performance (e.g., procedural generation loops running every frame), migrate those specific scripts to **C# (Mono)** while keeping the rest in GDScript. Do not use C++ (GDExtension) unless you have a very specific, profiled bottleneck.

### Android Export Setup

- Install **Android Studio** to get the Android SDK and Build Tools
- In Godot: Editor → Export → Android
- Set minimum SDK to **24**, target SDK to **34**
- Enable **Gradle build** (not the legacy export)
- Sign with a keystore for Play Store submission
- Enable **arm64-v8a** as the primary architecture; include **armeabi-v7a** as fallback for older devices
- Set orientation to **Landscape** (locked)
- Enable **Immersive Mode** (hide system bars) via the Android export settings

---

## PROJECT STRUCTURE

Organize your Godot project with this folder structure:

```
res://
├── scenes/
│   ├── game/
│   │   ├── Main.tscn              # Root game scene
│   │   ├── GameWorld.tscn         # The scrolling world
│   │   ├── Player.tscn            # Player character
│   │   ├── Ground.tscn            # Ground segment
│   │   └── obstacles/
│   │       ├── ObstacleBase.tscn
│   │       ├── LowBarrier.tscn
│   │       ├── HighBarrier.tscn
│   │       ├── FloatingPlatform.tscn
│   │       └── PitGap.tscn
│   ├── ui/
│   │   ├── HUD.tscn
│   │   ├── MainMenu.tscn
│   │   ├── GameOver.tscn
│   │   └── PauseMenu.tscn
│   └── effects/
│       ├── DustParticle.tscn
│       ├── LandingImpact.tscn
│       └── DeathExplosion.tscn
├── scripts/
│   ├── player/
│   │   ├── PlayerController.gd
│   │   ├── PlayerAnimator.gd
│   │   └── PlayerState.gd
│   ├── world/
│   │   ├── WorldManager.gd
│   │   ├── ChunkSpawner.gd
│   │   ├── ObstacleSpawner.gd
│   │   └── DifficultyManager.gd
│   ├── systems/
│   │   ├── ScoreManager.gd
│   │   ├── SaveManager.gd
│   │   ├── AudioManager.gd
│   │   └── InputManager.gd
│   └── ui/
│       ├── HUDController.gd
│       └── MenuController.gd
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── environment/
│   │   ├── obstacles/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── shaders/
└── autoloads/
    ├── GameManager.gd
    ├── EventBus.gd
    └── Constants.gd
```

---

## CORE SYSTEMS

### 1. Player Controller (`PlayerController.gd`)

The player character uses **CharacterBody2D** as its base node. This is critical — do NOT use RigidBody2D for the player. CharacterBody2D gives you direct, deterministic control over velocity while still interacting with the physics world.

**Physics properties to tune:**
```gdscript
const GRAVITY: float = 2800.0          # Strong gravity for snappy feel
const JUMP_FORCE: float = -900.0       # Initial jump velocity
const DOUBLE_JUMP_FORCE: float = -750.0
const RUN_SPEED: float = 500.0         # Constant horizontal speed
const SLIDE_DURATION: float = 0.5      # Seconds player stays crouched
const COYOTE_TIME: float = 0.1         # Seconds after leaving edge where jump is still allowed
const JUMP_BUFFER_TIME: float = 0.12   # Input buffering window for jump
```

**Implement a Finite State Machine (FSM)** for the player. States:
- `RUNNING` — default state, character moves at constant speed
- `JUMPING` — ascending phase, hold jump to extend slightly (variable jump height)
- `FALLING` — descending phase, apply extra gravity multiplier (1.5x) for weight
- `DOUBLE_JUMPING` — second jump in air
- `SLIDING` — crouch slide under obstacles, collision shape shrinks
- `DEAD` — ragdoll/death animation, no input accepted

Variable jump height: when the player releases the jump button early while ascending, multiply gravity by 2.5x immediately. This gives a "floaty short hop" vs "full arc" feel that is essential for skill expression.

**Coyote time:** Start a timer when the player walks off a ledge. If they press jump within `COYOTE_TIME` seconds, allow the jump as if they were still grounded. This makes the game feel fair and responsive.

**Jump input buffering:** If the player presses jump while in the air but within `JUMP_BUFFER_TIME` seconds of landing, execute the jump immediately upon landing. This prevents the frustration of "I pressed jump but nothing happened."

### 2. World & Chunk System (`WorldManager.gd`, `ChunkSpawner.gd`)

The world is built from **reusable chunks** (segments) that tile seamlessly. Each chunk is a scene containing: ground tiles, decorative background elements, obstacle spawn points, and collectible positions.

**Chunk pooling:** Never instantiate and free chunks at runtime. Instead, maintain a pool of pre-instantiated chunk scenes (8–10 chunks). When a chunk scrolls fully off the left edge of the screen, reset it and move it to the right edge of the rightmost active chunk. This eliminates GC pressure and keeps memory usage flat.

**Chunk types to build:**
- `FlatChunk` — simple flat ground, safe zone
- `GapChunk` — ground with a pit the player must jump over
- `RaisedChunk` — elevated platform section
- `DescendChunk` — ground drops lower
- `ObstacleChunk` — dense obstacle layout, high tension
- `BonusChunk` — coin/gem collection corridor, reward section

**Scrolling speed:** Start at 500 px/s. Increase by 15 px/s every 10 seconds of survival. Cap at 950 px/s. The world moves left; the player is stationary horizontally (at x = 200 on screen) but logically moving right in world space.

### 3. Obstacle System (`ObstacleSpawner.gd`)

Obstacles are **StaticBody2D** nodes with CollisionShape2D. They must be visually readable at a glance — the player needs to identify the obstacle type in under 200ms while moving.

**Obstacle types:**
- **Low barrier** — waist-height wall, player must jump
- **High barrier** — full-height wall, player must slide under a gap or it's impassable
- **Floating platform** — above the player's head, must duck, or can jump on top as a shortcut
- **Saw blade / spikes** — on the ground, triggers death on any contact (no forgiveness hitbox)
- **Falling stalactite** — drops from ceiling with a warning shadow, timed dodge
- **Moving platform gap** — gap in the floor that oscillates in width

**Obstacle patterns:** Don't spawn obstacles randomly in isolation. Build a library of 20–30 handcrafted **obstacle patterns** (sequences of 2–4 obstacles with specific spacing). The spawner picks from this library based on difficulty tier. This ensures the game is always fair and playable, unlike pure random spawning which can create impossible combinations.

**Hitbox forgiveness:** Make collision shapes 10–15% smaller than the visual sprite on all sides. Players perceive hitboxes as unfair if they match the sprite exactly. This is standard practice in polished platformers (Celeste uses ~30% smaller hitboxes). The game should feel tight but never cheap.

### 4. Difficulty Manager (`DifficultyManager.gd`)

Difficulty is driven by a **continuous score multiplier curve**, not discrete levels. Use the following parameters:

```gdscript
# Time-based difficulty scaling
func get_current_difficulty(elapsed_time: float) -> float:
    return clamp(1.0 + (elapsed_time / 60.0) * 2.5, 1.0, 3.5)
```

At difficulty 1.0 (start):
- Obstacles from Tier 1 pool only (single obstacles, generous spacing)
- Gap size: 200–280px
- Scroll speed: 500 px/s

At difficulty 2.0 (1 minute in):
- Mix of Tier 1 and Tier 2 patterns
- Occasional double-obstacle combos
- Scroll speed: 650 px/s

At difficulty 3.5 (max, ~2.5 minutes in):
- Tier 3 patterns dominate
- Moving obstacles introduced
- Very short reaction windows
- Scroll speed: 950 px/s

### 5. Animation System (`PlayerAnimator.gd`)

Use **AnimationTree** with a **StateMachine** node (not just AnimationPlayer alone). Each animation state corresponds to the player FSM state.

**Required animations (minimum frame counts):**
- `idle` — 6–8 frames, subtle breathing/weight shift
- `run` — 8–12 frames, full run cycle with arm swing and foot plant
- `jump_start` — 4 frames, anticipation squat + launch
- `jump_air` — 4 frames, peak arc pose
- `fall` — 4 frames, falling tuck
- `land` — 3 frames, landing impact squash
- `double_jump` — 5 frames, mid-air kick/spin
- `slide` — 6 frames, dive into slide
- `slide_loop` — 2 frames, sustained crouch
- `slide_end` — 3 frames, rise from slide
- `death` — 10–12 frames, full death fall

**Squash and stretch:** This is the single most impactful animation technique for making a character feel alive. On jump launch, squash the character vertically 0.85x and stretch horizontally 1.15x for 2 frames. On landing, reverse: squash vertically 0.8x and stretch horizontally 1.2x for 3 frames, then spring back. Do this with `AnimationPlayer` tracks on the Sprite2D node's `scale` property.

**Root motion:** The run animation should not "slide" — ensure foot contacts match the scroll speed at low speeds. At higher speeds this matters less, but at the game start it's very noticeable.

**Sprite2D vs AnimatedSprite2D:** Use **AnimatedSprite2D** for the character with a SpriteFrames resource. Organize all animation frames within that resource. Keep the sprite atlas to a single texture (sprite sheet) for GPU batch efficiency.

---

## PHYSICS DETAILS

### Ground Detection

Use **two RayCast2D** nodes positioned at the bottom-left and bottom-right feet of the player. Check both rays for ground — if either detects a surface, the player is grounded. This prevents edge cases where walking off a ledge with only one foot on the edge causes jitter.

Set ray length to `12px` beyond the collision shape bottom. Cast downward.

### Slope Handling

For slopes (if your level design includes them), set `floor_max_angle` on CharacterBody2D to `deg_to_rad(46)`. Use `up_direction = Vector2.UP`. The built-in `move_and_slide()` handles slope sliding automatically.

### One-Way Platforms

For platforms the player can jump through from below but land on from above: use **StaticBody2D** with a **CollisionShape2D** and enable "One Way Collision" in the shape's properties. No extra code needed — Godot handles this natively.

### Physics Process vs Process

All physics and movement code goes in `_physics_process(delta)`. All visual/animation updates go in `_process(delta)`. Never mix them. The physics process runs at a fixed timestep (default 60Hz), ensuring deterministic, frame-rate-independent behavior.

---

## VISUAL DESIGN

### Art Style

**Neo-pixel with soft lighting** — high-resolution pixel art (not 8-bit retro, but modern "HD pixel art" at 32px or 48px character height) with dynamic lighting effects, glows, and particle systems layered on top. Reference games: Celeste, Dead Cells, Blasphemous for art quality targets.

Alternatively, if you use vector/raster hand-drawn art: aim for the style of Rayman Legends — smooth, expressive, colorful with strong silhouette reads.

**Color palette per biome:**
- Biome 1 (Forest): Deep greens (#1a3a2a), warm amber (#e8a84c), dark teal (#0d2b2b)
- Biome 2 (Neon City): Near-black (#0a0a1a), electric cyan (#00f5ff), hot magenta (#ff0066)
- Biome 3 (Desert Ruins): Terracotta (#b84c2a), sandy tan (#d4aa70), burnt sienna (#8b3a1e)

### Parallax Background System

Use Godot's built-in **ParallaxBackground** node with multiple **ParallaxLayer** children. Structure:

| Layer | Content | Scroll Factor |
|-------|---------|---------------|
| Layer 0 | Sky gradient / solid color | 0.0 (fixed) |
| Layer 1 | Distant mountains/clouds | 0.1 |
| Layer 2 | Far background structures | 0.25 |
| Layer 3 | Mid-distance trees/buildings | 0.45 |
| Layer 4 | Near background details | 0.7 |
| Layer 5 | Ground/foreground decorations | 1.0 |

Each layer tiles horizontally. Set `mirroring` on ParallaxLayer to auto-tile.

### Shader Effects

Write these as Godot `.gdshader` files in `res://assets/shaders/`:

**Speed lines shader** (applies to background at high speed):
- Radial lines emanating from center-right
- Opacity scales with current speed ratio (current_speed / max_speed)
- Use `TIME` uniform for animation

**Character outline shader:**
- Single-pixel outline around the character sprite
- Tinted by current state (white normally, red on near-death, gold on invincibility)
- Essential for readability against complex backgrounds

**Ground tile normal map lighting:**
- Even simple ground tiles benefit from a normal map + a moving light source
- Creates sense of depth without expensive 3D rendering

**Glitch/distortion shader** (death screen):
- Scanline distortion, chromatic aberration
- Triggered on player death for 1.5 seconds before game over UI appears

### Particle Systems

Use **GPUParticles2D** (not CPUParticles2D) for all particles — GPU particles have near-zero CPU overhead.

**Required particle effects:**
- **Foot dust** — emits when running on ground, 4–6 particles, gray-white dust puffs, emits from foot contact points
- **Landing impact** — 8–12 particles on landing, radial burst, varies in intensity with fall height
- **Jump trail** — 3–5 particles emitted behind the character during ascent
- **Coin/gem collect** — 6 star-shaped particles burst on collection, tinted to match gem color
- **Death explosion** — 20–30 particles, large burst, mix of character color + sparks
- **Speed streaks** — horizontal lines behind the character, start appearing above 70% max speed
- **Obstacle destruction** (if obstacles break) — debris particles

---

## AUDIO

### Audio Engine Setup

Use Godot's built-in **AudioStreamPlayer** and **AudioStreamPlayer2D** nodes. Create **Audio Buses** in the Audio panel:

- `Master` — main output
- `Music` — background music, route through reverb + lowpass filter
- `SFX` — sound effects, no reverb
- `UI` — UI sounds, separate control

### Music

Use **dynamic adaptive music** — not a single looping track. Structure your music as:

- **Base layer** — drums and bass, always playing
- **Tension layer** — additional instruments, crossfades in at difficulty 2.0+
- **Danger layer** — intense instrumentation, fades in at near-death or max speed
- **Menu theme** — separate, calmer track

Crossfade between layers using `Tween` to smoothly adjust volume over 2–3 seconds. This makes the music feel alive and responsive to gameplay.

**Audio format:** Use `.ogg` for music (compressed, good loop points) and `.wav` for SFX (low latency, no decompression delay). Never use `.mp3` in Godot — loop points are unreliable.

### Sound Effects (required list)

- `jump.wav` — short, snappy, slightly pitched up
- `double_jump.wav` — different tone from single jump, whoosh element
- `land_soft.wav` / `land_hard.wav` — two versions based on fall height
- `slide_start.wav` — scraping/swoosh
- `coin_collect.wav` — short musical chime, pitch shifts +50 cents per chain collect
- `obstacle_hit.wav` — impact thud
- `death.wav` — dramatic hit + crunch
- `speed_up.wav` — engine rev or whoosh, plays on each speed increase
- `ui_tap.wav` — short click for menu buttons
- `ui_confirm.wav` — positive confirm sound
- `milestone_ding.wav` — plays at every 100m or score milestone

**Pitch randomization:** For frequently played sounds (footsteps, coin collects), randomize pitch by ±5% on each play to prevent auditory fatigue:
```gdscript
var player = AudioStreamPlayer.new()
player.pitch_scale = randf_range(0.95, 1.05)
```

---

## INPUT SYSTEM

### Touch Input (`InputManager.gd`)

Handle touch input through Godot's `_input(event)` with `InputEventScreenTouch` and `InputEventScreenDrag`.

**Gesture scheme:**
- **Tap anywhere** — Jump (if grounded or within coyote time)
- **Double tap** — Double jump (if airborne)
- **Swipe down** — Slide (triggers slide state)
- **Swipe up** — Jump (alternative to tap)
- **Long press** — Hold jump (variable height, sustained by holding)

Divide the screen into zones for tap:
- Left 40% — alternative input zone (some players prefer left-hand taps)
- Right 60% — main input zone
- Both zones respond to all gestures

**Input buffering implementation:**
```gdscript
var jump_buffer_timer: float = 0.0
var JUMP_BUFFER: float = 0.12

func _input(event):
    if event is InputEventScreenTouch and event.pressed:
        jump_buffer_timer = JUMP_BUFFER

func _physics_process(delta):
    jump_buffer_timer -= delta
    if jump_buffer_timer > 0 and is_on_floor():
        execute_jump()
        jump_buffer_timer = 0.0
```

---

## SCORING & PROGRESSION

### Score System (`ScoreManager.gd`)

- **Distance score**: +1 point per meter traveled (1 meter = 100px at base resolution)
- **Obstacle dodge bonus**: +10 points per obstacle passed within 0.3s of a near-miss (hitbox close call detection)
- **Coin/gem collect**: +5 points per coin, +25 per gem
- **Combo multiplier**: consecutive obstacle clears without taking damage multiply score by 1.1x, stacking up to 3.5x, resets on hit
- **Speed bonus**: at max scroll speed, score multiplier gains +0.5x

Display score in the HUD as a large, readable number in the top-center. Use a custom bitmap font (or a clean sans-serif from Google Fonts bundled in-project) at minimum 48px.

**High score persistence:** Use `SaveManager.gd` with Godot's `FileAccess` API:
```gdscript
const SAVE_PATH = "user://save_data.cfg"

func save_highscore(score: int):
    var config = ConfigFile.new()
    config.set_value("scores", "high_score", score)
    config.save(SAVE_PATH)

func load_highscore() -> int:
    var config = ConfigFile.new()
    if config.load(SAVE_PATH) == OK:
        return config.get_value("scores", "high_score", 0)
    return 0
```

### Collectibles

- **Coins** — small gold circles, scattered throughout chunks, +5 score
- **Gems** — larger, color-coded by rarity (blue/green/red/rainbow), +25/50/100/500 score
- **Power-up orbs** — grant temporary abilities:
  - **Shield** — absorb one hit (15 seconds)
  - **Magnet** — auto-collect coins within 200px radius (10 seconds)
  - **Slow-mo** — reduces scroll speed by 30% for 5 seconds (visual: time-warp shader)
  - **Score doubler** — 2x score multiplier (10 seconds)

---

## UI / HUD

### HUD Layout (landscape)

```
┌─────────────────────────────────────────────────────┐
│ [SCORE: 00000]              [♥♥♥]     [⏸ PAUSE]   │
│                                                      │
│                                                      │
│         [GAME WORLD]                                 │
│                                                      │
│ [POWER-UP ICON + TIMER BAR]                          │
└─────────────────────────────────────────────────────┘
```

**HUD nodes (all CanvasLayer, layer 10):**
- Score label — top left, updates every frame
- Lives/health indicator — top center (if using lives system)
- Pause button — top right, icon only (40x40 touch target minimum)
- Power-up slot — bottom left, shows active power-up icon + depleting bar
- Distance meter — optional, top right below pause, shows meters traveled

**Animate score increments:** When score increases, briefly scale the score label to 1.15x then back to 1.0 over 0.15 seconds using Tween. This makes scoring feel tactile.

### Main Menu

- Animated background (parallax scrolling, same assets as game)
- Player character doing idle animation in foreground
- Large "PLAY" button — center, minimum 120px height tap target
- "LEADERBOARD" and "SETTINGS" buttons below
- High score displayed below the game title
- Subtle particle ambient effects (floating leaves, dust, etc.)

### Game Over Screen

- Slide-up panel from bottom with spring animation
- Show: SCORE (large), BEST (if new record, flash "NEW BEST!" in gold)
- Buttons: RETRY (primary, prominent) and HOME (secondary)
- Share score button (uses Android's native share intent via Godot's OS.shell_open or a plugin)
- Interstitial ad slot (bottom banner) — implement but only enable if using AdMob

---

## PERFORMANCE OPTIMIZATION

### Rendering

- Enable **2D batching** in Godot Project Settings → Rendering → 2D → Use Batching
- Keep all sprites on the same texture atlas (sprite sheet) — Godot batches draw calls for sprites from the same texture automatically
- Limit the number of unique materials/shaders active at once to under 10
- Use **VisibleOnScreenNotifier2D** on off-screen objects to pause their processes
- Set `process_mode = PROCESS_MODE_DISABLED` on inactive nodes instead of hiding them

### Memory

- **Object pooling** for all frequently spawned objects: obstacles, coins, particles, ground chunks
- Never call `queue_free()` on pooled objects — deactivate and return to pool instead
- Keep audio streams loaded in memory if they're played frequently (footsteps, jump sounds)
- Unload biome assets when transitioning to a new biome

### Profile Targets (test on mid-range device)

- CPU frame time: < 8ms (leaving 8ms headroom for 60fps = 16.7ms budget)
- GPU frame time: < 10ms
- Memory usage: < 150MB RAM
- APK size: < 80MB uncompressed (use Godot's resource compression)

### Android-Specific

- Use `DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)` on startup
- Request `WAKE_LOCK` permission to prevent screen sleep during gameplay
- Handle `notification(NOTIFICATION_WM_GO_BACK_REQUEST)` for the Android back button (show pause menu, not exit)
- Handle `notification(NOTIFICATION_APPLICATION_PAUSED)` — auto-pause game and silence audio when app is backgrounded
- Test on actual hardware — the Android emulator does not accurately represent GPU performance

---

## GAME FEEL POLISH ("JUICE")

This section is what separates a good game from a great one. Implement every item here.

### Camera

Use **Camera2D** with the following settings:
- **Drag horizontal**: enabled, drag left margin 0.6, drag right margin 0.4 (camera leads slightly in the direction of travel)
- **Position smoothing**: enabled, speed 8.0
- **Trauma system**: when obstacles are barely missed or player is hit, apply camera shake via a `trauma` variable that decays over time:

```gdscript
var trauma: float = 0.0
var TRAUMA_DECAY: float = 2.0
var MAX_OFFSET: float = 12.0

func add_trauma(amount: float):
    trauma = min(trauma + amount, 1.0)

func _process(delta):
    trauma = max(trauma - TRAUMA_DECAY * delta, 0.0)
    var shake_amount = trauma * trauma  # Square for non-linear falloff
    camera.offset = Vector2(
        randf_range(-MAX_OFFSET, MAX_OFFSET) * shake_amount,
        randf_range(-MAX_OFFSET, MAX_OFFSET) * shake_amount * 0.5
    )
```

### Hit Stop (Freeze Frames)

On death or major impact, freeze the game for **3–5 frames** (50–80ms):
```gdscript
func hit_stop(duration: float = 0.06):
    Engine.time_scale = 0.0
    await get_tree().create_timer(duration, true, false, true).timeout
    Engine.time_scale = 1.0
```

This is a technique from fighting games that makes impacts feel dramatically powerful.

### Screen Flash

On death: flash the screen white for 1 frame, then apply the glitch shader. Use a full-screen ColorRect on a CanvasLayer above everything, modulate alpha to 1.0 for one frame then tween to 0.

### Milestone Moments

Every 500m traveled:
- Briefly slow time to 0.3x for 0.5 seconds (Matrix-style)
- Display distance milestone text that animates in (scale from 2.0 to 1.0, fade out)
- Play the milestone sound

### Near-Miss Detection

Track when an obstacle passes within 60px of the player without collision. Trigger:
- "CLOSE!" text popup above player
- +10 score bonus
- Small adrenaline camera shake (trauma += 0.2)
- This rewards skilled play and makes narrow escapes feel intentional rather than lucky

---

## MONETIZATION (Optional but Structured)

If releasing on the Play Store:

**Recommended model: Free with optional cosmetics**

- Core gameplay 100% free, no paywalls
- Cosmetic character skins sold for $0.99–$2.99 each
- "Remove Ads" one-time purchase ($2.99)
- Rewarded ads (Google AdMob): "Watch an ad to continue from where you died once per run"
  - Never force ads mid-gameplay
  - Only show after game over

**Google Play Services integration:**
- Use the **Godot Google Play Games Services** plugin (available on GitHub)
- Implement Leaderboards for high score
- Implement Achievements (first 100m, first 1000m, 5 consecutive runs, etc.)

---

## TESTING CHECKLIST

Before release, validate:

- [ ] 60fps locked on Samsung Galaxy A32 (or equivalent mid-range device)
- [ ] No memory leaks after 20+ consecutive runs (check with Android Profiler)
- [ ] App resumes correctly after backgrounding (call/notification interruption)
- [ ] All touch gestures recognized correctly in landscape and portrait (if you support both)
- [ ] High score saves and loads correctly after app restart
- [ ] All audio plays at correct volumes and loops cleanly
- [ ] No z-fighting or sprite flickering at any scroll speed
- [ ] Death always triggers correctly (no pass-through collisions at high speed)
- [ ] Game pause/resume works from both pause button and Android back button
- [ ] APK installs and runs on Android 7.0 (API 24) cleanly

---

## DEVELOPMENT MILESTONES

Follow this order to avoid building features on broken foundations:

**Week 1–2: Core Loop**
- Player CharacterBody2D with jump and slide
- Flat scrolling ground
- Death on obstacle contact
- Score counter

**Week 3–4: World System**
- Chunk pooling and spawning
- 3 obstacle types
- Parallax backgrounds
- Difficulty scaling

**Week 5–6: Animation & Feel**
- Full animation state machine
- Particles (dust, landing, death)
- Camera shake / trauma
- Sound effects

**Week 7–8: Content & UI**
- 6+ chunk types
- 20+ obstacle patterns
- Main menu, HUD, game over screen
- High score persistence

**Week 9–10: Polish & Optimization**
- All shader effects
- Adaptive music
- Performance profiling
- Bug fixes

**Week 11–12: Release Preparation**
- Play Store listing assets (screenshots, icon, feature graphic)
- Privacy policy (required for Play Store)
- Final testing across 3+ physical devices
- APK signing and release build

---

## RESOURCES & REFERENCES

**Art Assets (free):**
- itch.io — search "endless runner assets", "platformer character sprites"
- Kenney.nl — free game assets, professional quality
- OpenGameArt.org — CC0 licensed sprites and tiles

**Audio (free):**
- freesound.org — CC0 sound effects
- incompetech.com (Kevin MacLeod) — royalty-free music
- zapsplat.com — free SFX with attribution

**Godot Learning:**
- docs.godotengine.org — official docs (always read this first)
- GDQuest on YouTube — best Godot tutorial channel
- KidsCanCode on YouTube — excellent platformer physics tutorials
- Godot Discord — active community for questions

**Reference Games to Study:**
- Celeste — perfect platformer physics, study its coyote time and buffering
- Alto's Odyssey — fluid momentum and feel
- Geometry Dash — timing-based obstacle design
- Dead Cells — animation quality and juice

---

*This document covers everything needed to build a production-quality 2D endless runner for Android using Godot 4. Follow the milestones in order, implement the physics details precisely, and never skip the "juice" section — that's what players actually feel.*
