# Mini-Game Ideas

Victorian-era themed puzzles. Simple to implement, minimal art assets, maximum atmosphere.

---

## Tier 1: Minimal Assets (0-3 sprites)

### Labyrinth with Candle
- **Mechanic:** Top-down maze, completely dark except for small light radius around cursor/player
- **Objective:** Reach the exit
- **Creepy twist:** Drafts (invisible zones) extinguish the candle temporarily. Something moves in the darkness.
- **Assets:** None (walls are invisible colliders)

### Morse Code / Knocking
- **Mechanic:** Listen to a rhythm of knocks, repeat it by clicking with correct timing
- **Objective:** Match the pattern
- **Creepy twist:** Each round, a knock comes from a different direction. Who's responding?
- **Assets:** Black screen only

### Hot/Cold Search
- **Mechanic:** Click around the screen, audio/visual feedback indicates proximity to hidden target
- **Objective:** Find the hidden object
- **Creepy twist:** The "object" is a face. Or an eye that opens when found.
- **Assets:** One background

### Pendulum Timing
- **Mechanic:** Stop a swinging pendulum in the target zone
- **Objective:** Perfect timing
- **Creepy twist:** Each attempt, the pendulum swings faster. Clock chimes grow louder.
- **Assets:** Pendulum sprite, clock face

---

## Tier 2: Low Assets (4-8 sprites)

### Music Box Sequence
- **Mechanic:** Simon Says with musical notes from a music box
- **Objective:** Repeat the melody
- **Creepy twist:** The melody becomes a lullaby. Distorted. Slowing down.
- **Assets:** Music box, 4-5 keys/buttons

### Shadow Puppets
- **Mechanic:** Rotate objects to cast a shadow that matches target silhouette
- **Objective:** Align the shadow
- **Creepy twist:** The target silhouette is something wrong — a hanged figure, a creature
- **Assets:** 3-4 rotatable objects, target silhouette, candle

### Wind-Up Mechanism
- **Mechanic:** Hold/click to wind a key, but don't overwind (tension meter)
- **Objective:** Fill the meter without breaking
- **Creepy twist:** What are you winding up? It starts moving. Twitching.
- **Assets:** Key, mechanism, tension meter

### Photograph Development
- **Mechanic:** Hold to develop a photograph in solution, release at right moment
- **Objective:** Develop the image clearly (not under/over-exposed)
- **Creepy twist:** The photograph shows something that shouldn't be there
- **Assets:** Development tray, photograph (multiple exposure states)

### Stained Glass Assembly
- **Mechanic:** Drag and drop fragments into a frame
- **Objective:** Complete the image
- **Creepy twist:** When assembled, the image depicts something disturbing
- **Assets:** 5-7 glass fragments, frame

---

## Tier 3: Medium Assets (Public Domain Art)

### Find the Hidden Detail
- **Mechanic:** Examine a detailed engraving/painting, find the hidden symbol
- **Objective:** Click on the hidden element
- **Creepy twist:** The hidden element moves. Or wasn't there when you first looked.
- **Assets:** One detailed public domain artwork (modified)

### Spot the Difference
- **Mechanic:** Two nearly identical images, find the differences
- **Objective:** Click all differences
- **Creepy twist:** Differences appear/disappear. One difference is something alive.
- **Assets:** One image + variations

### Portrait Eyes
- **Mechanic:** Multiple portraits on a wall, one is watching you (eyes follow cursor)
- **Objective:** Identify which portrait is "alive"
- **Creepy twist:** Sometimes it's more than one. Sometimes it's all of them.
- **Assets:** 4-6 portrait frames (can reuse with variations)

---

## Creepy Enhancements (Apply to Any)

### Audio
- Distant coughing (sanatorium ambience)
- Gibberish doctor voices, muffled through walls
- Heartbeat/pulse monitor rhythm as background
- Music box melody distorted, played backwards
- Child's breathing, getting weaker

### Visual
- Vignette that slowly closes in (time pressure without a timer)
- Film grain / sepia filter
- Occasional screen flicker (candle flicker?)
- Something at the edge of the screen — gone when you look
- The painting's world decays as you progress

### Mechanical
- Timer isn't shown — sky darkens or candle burns down
- Success = something breaks/dies in the scene
- The "reward" animation is unsettling (scissors appearing, cutting sound)
- Return to hub shows the painting ruined — consequence is real

---

## Meta-Creepy (4th Wall)

### Save Corruption
- "Save failed" message that lies — save actually works
- Or vice versa — "Saved" but you're slightly earlier than expected

### Pause Doesn't Pause
- Sounds continue during pause
- Or: world pauses but breathing continues

### The Extra Button
- A button in controls labeled "Call" or "Ring Bell"
- Does nothing. Until the very end.

### Achievement Before Action
- "Collected 5 fragments" pops up before you collect the 5th
- As if the game knows

---

## Recommended Mini-Game Set (5 for MVP)

1. **Labyrinth with Candle** — pure atmosphere, no art needed
2. **Music Box Sequence** — simple mechanic, strong Victorian vibe
3. **Shadow Puppets** — visual puzzle, creepy potential
4. **Photograph Development** — timing game, narrative potential (what's in the photo?)
5. **Morse Code Knocking** — audio-only, maximum dread

Each takes 30-40 seconds. Each ends with the cutting ritual.

---

## Art Style Notes

- **Palette:** Sepia, brown, dark green, muted orange (candlelight)
- **Shadows:** Cold blue/black against warm light
- **Style:** Painterly, impressionistic — fits "inside a painting" theme
- **UI:** Minimal. No HUD if possible. Diegetic indicators (candle brightness, breathing sounds)
