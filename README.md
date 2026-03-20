# Cyber Lobster Aquaculture 🦞

A Godot 4.x simulation game where you raise a digital lobster to make money.

## Project Structure

```
cyber-lobster/
├── project.godot      # Godot project config
├── scenes/
│   └── main.tscn     # Main game scene
├── scripts/
│   └── main.gd       # Core game logic
├── resources/        # Assets (to be added)
└── icon.svg          # Game icon
```

## Game Design

### Core Loop (Per Day)
1. **Morning** - Choose activity: High Work / Medium Work / Slack Off
2. **Evening** - Lobster reports results, player responds (Scold / PUA / Comfort)
3. **Night Shop** - Buy decorations with earnings
4. **Night Sleep** - Daily growth & evolution calculation

### Stats
- **Stress** (0-100)
- **Resentment** (0-100)
- **Productivity** (0-100)
- **Money** - Earned from work

### Evolution Types
- **Normal** - Default lobster
- **Corporate Slave** - High stress, low resentment (6 mechanical arms)
- **Chaotic Evil** - High stress, high resentment (dark body, red eyes)
- **Lazy** - Low stress, low resentment (fat, sunglasses)

## How to Run

1. Open Godot 4.x
2. Import this project folder
3. Press F5 to run

## To Build for itch.io

1. Project → Export
2. Add HTML5 preset
3. Export to `build/`
4. Upload to itch.io

## Status

- [x] Project structure created
- [x] Core game logic (4 phases)
- [x] Stats & evolution system
- [x] Combat system with enemies
- [x] Boss battle (Slime King)
- [x] Skill system (Dash, Ground Slam, Magic Shot, Heal)
- [x] Clicker mini-game
- [x] Particle effects & audio
- [ ] Complete UI implementation
- [ ] LLM integration (Minimax API)
- [ ] Sprite art for evolution types
- [x] Build & publish (v1.4.0)
