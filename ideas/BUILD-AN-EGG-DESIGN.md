# Build an Egg! — design on top of a Build the Pyramid! teardown (2026-10-01)
**Status: design only. Nothing has been built.**

**Sources:**
- Teardown files in `pyramid-teardown/` (01 mechanics, 02 UI/money, 03 rewards/live-ops, 04 presentation/policy).
- All Pyramid numbers come from web-search snippets and two fan-wiki repos dated Sep 18–30. Roblox pages could not be opened directly from here, so **play the game for an hour before building** and fill in the gaps listed at the bottom.

## 0. The decision: Build an Egg, not Build the Nest
- **"Build an Egg!" promises the payoff in the title.** You build something that hatches. With "Build the Nest" the egg arrives as a second step, which makes the 30-second promise weaker.
- **Your "great egg or terrible egg" idea only works if what you build IS the egg.** The shell's quality is visible as it goes up.
- **Name check (searched Oct 1):** no Roblox game called "Build an Egg", "Build the Egg" or "Build a Giant Egg". The nearest are Steal a Giant Egg and Egg Upgrade Tree, which are different games.
- **Title options:** **Build an Egg!** (main). Alternates: Build the Egg! / Build a Giant Egg.
- **Format:** same "Build the X!" format as theirs, but a different noun and a different twist, so it won't trip the copycat filter.

## 1. What we copy 1:1 from Build the Pyramid!
These are systems, numbers and structure, not their assets.

| Pyramid (verified in snippets) | Build an Egg! (copy) |
|---|---|
| Quarry pit, hold E on a stone, start carrying 1 block | **Shell Quarry** pit, hold E on a shell piece, start carrying 1 piece |
| Carry across the desert, place in a green band that climbs tier by tier | Carry across the nest valley, place in a glowing band that climbs **ring by ring** up the egg |
| +1 Coin and +1 to the server counter per block | Same: +1 Coin, +1 to the server counter |
| One shared server target (171,700 blocks) | One shared egg target. **Same 171,700** for the Common Egg at launch (see polish note) |
| Two stats: Speed (walk) and Strength (carry capacity) | Same two stats, same names |
| Treadmills = Speed, benches = Strength; step in to auto-train, jump to stop, trains while AFK | Same. Reskin: treadmill = "Nest Run", bench = "Shell Lift" |
| Gym ladder 1x, 2x (1 egg), 5x (3), 10x (8), 25x (15), 50x (25), 75x (50), 100x (100), ADMIN 250x (pass only) | **Identical gates and multipliers**, gated by eggs hatched |
| Gym-skip passes: R$29 / 99 / 199 / 399 / 699 / 899 / 1,099 / ADMIN 1,499 | **Identical prices** |
| Coin upgrades: Bulk Pickup 50/300/850/2,400/6,600; Bulk Place 50/300/850/2,400; Range 25/150/425 (+20% per tier) | **Identical costs and effects** |
| Pharaoh pass (R$120–149): 2x pyramids credited, insta pickup, insta place, aura | **Golden Goose** pass, R$149: 2x eggs credited, insta pickup, insta place, golden aura |
| Stacking 1.5x Speed / 1.5x Strength products, price rises each buy | Same |
| 5,000-block server pack (R$100), 50,000-block drop | **Shell Drop** 5,000 (R$100) and **Mega Drop** 50,000 (price TBD), which also raise egg quality (see §2) |
| Completion: short monument scene → click → +1 → interior with 3 chambers + 2x training pool for ~3 min → reset | Completion: the egg glows and cracks (scene) → everyone hatches (see §2) → you can walk **inside the cracked shell** for 3 min with 2x training → reset with a new egg |
| Pyramid projects Basic / Silver / Gold / Void / Gem | Egg types Common / Silver / Golden / Void / Gem, plus a weekly themed egg |
| Rank titles over names: Apprentice 0 → Artisan 1 → Chief Mason 8 → Prophet of Ra → High Priest | Hatchling 0 → Nester 1 → Egg Chief 8 → Shell Sage → Mother of Dragons-style top title (same thresholds) |
| Leaderboard: blocks, Speed, Strength, pyramids | Same, plus "Best Pet" |
| FREE GIFT board at spawn: like + favorite + group = +1,500 Speed, +1,500 Strength | Identical |
| Codes button top-left, settings cog top-left, shop on the right, CODES sign at the quarry | Identical layout |
| Codes: WELCOME 500/500, FREECODE 500 coins, an update code with big boosts, an apology code after bugs, capped codes (1,000 / 2,000 uses) | Same pattern on launch day |
| 50-player servers (cut from 100 for lag) | **Launch at 50** |
| Description: "Pick up blocks and carry them… Work together… Train… Complete pyramids to become even stronger!" | "Grab shell pieces and carry them to the giant egg. Work together with the whole server. Train your speed and strength. Hatch the egg — the more you build, the better your pet!" |

## 2. What we add: your idea, made rigorous
### 2a. A different egg every round
- The round's egg type is announced at reset ("NEXT: VOLCANO EGG").
- Each type has its own pet pool:
  - Common, Silver, Golden, Void and Gem eggs unlock as you progress, the same way their pyramid projects do.
  - A **weekly themed egg** (Pumpkin in late October, Frost in December) gives a Saturday drop day.
- The egg looks different as it rises: shell colour, pattern and glow.

### 2b. Great egg or terrible egg (the server decides together)
- **The quarry holds four kinds of shell piece:**

| Piece | Weight | Effect |
|---|---|---|
| Junk | light | lowers the egg's quality |
| Normal | — | — |
| Shiny | heavy | raises quality |
| Golden | very heavy, rare | raises quality a lot |

- **Heavy pieces are worth more but slow you down.** That makes Strength matter and forces a real choice every trip.
- **Egg Quality** = the weighted average of every piece placed. It shows as a big meter beside the server progress bar:
  - Cracked → Plain → Good → Great → Perfect → **Legendary**
- **Quality sets the hatch tier for the whole server.**
  - Rushing junk finishes fast but hatches bad pets.
  - Patient servers hatch great ones.
  - That creates a natural argument in chat: "STOP PLACING JUNK".
- **Shell Drop and Mega Drop products add Shiny or Golden pieces.** One purchase lifts the whole server's egg, so the buyer gets shown off to everyone and everyone thanks them. This is our version of their server block pack.

### 2c. Hatch scaled to your contribution (fixes their server-hop sniping)
- **The problem:** Pyramid gives everyone a flat +1. Guides tell players to hop into a server at 140K/171.7K blocks and snipe the win.
- **Our rule, part 1:** your hatch luck comes from your **share of pieces placed this round**.
  - The curve is logarithmic, so whales don't erase everyone else: `luck = 1 + 0.6 × log10(1 + pieces_you_placed)`.
  - Rough examples: 10 pieces ≈ ×1.6, 100 ≈ ×2.2, 1,000 ≈ ×2.8, 10,000 ≈ ×3.4.
- **Our rule, part 2:** you need at least 0.1% of the egg, or 60 seconds of active hauling, to hatch at all.
  - Below that you get a **Shell Fragment**, a consolation currency.
  - Late joiners still get something, but sniping no longer pays.
- **The hatch result** = egg type pool × server Egg Quality tier × your personal luck.
  - Odds are shown before the hatch and update live, which Roblox requires for any paid luck.

### 2d. Pets you equip for boosts
- **Each pet gives a multiplier:** Speed, Strength, or "Haul" (pieces per trip).
  - Bonuses add up within a type and multiply across types, the same structure Sol's RNG uses.
- **Equip slots:** 3 at the start. More from passes and rank.
- **Collection:** an index for each egg type, with a reward for completing each egg's set.
- **Merge:** 3 of the same pet → 1 bigger pet. This soaks up duplicates.
- **Why it matters:** pets give a second progression track next to the gyms. That's the "single-track progression" weakness the research flags in most games, Pyramid included.

## 3. Money (their model + the egg layer)
- **Kept from Pyramid:**
  - 8 gym-skip passes at the same prices
  - Golden Goose (= their Pharaoh)
  - stacking Speed and Strength products
  - server Shell Drops
- **New products, each placed at its pain moment:**

| Product | Price | Fires when |
|---|---|---|
| Hatch Luck ×2 (this round) | R$49 | at the 95% countdown |
| Lucky Shell (your next 50 pieces count as Shiny) | R$29 | when quality is trending down |
| +1 Pet Slot | R$149 pass | when you equip your 4th pet |
| Auto-Merge | R$199 pass | — |

- **Rule:** Robux buys luck, speed and skips, never a guaranteed pet. Show odds summing to 100%, update them live while a boost is active, and gate PolicyService regions.

## 4. Map (same structure, new skin)
- **Layout:**
  - Spawn: FREE GIFT board and shop counter.
  - **Shell Quarry**: a pit with glowing piece types visible by colour, plus the CODES sign.
  - A valley path, with a green trail on your first trip.
  - At the centre, the **giant egg sitting in a huge straw nest**.
  - A ring of gyms around the nest, ordered 1x → 100x, ADMIN on a raised platform.
- **Interior after the hatch:** walk inside the cracked shell, where a "2X TRAINING INSIDE" sign leads to a yolk-gold pool. This copies the Waters of Nu.
- **Scale:** the egg is skyscraper-sized, so it's visible from spawn. Same reason the pyramid is.
- **Look:** keep their palette logic (warm sunset, readable silhouette) with original assets.

## 5. Thumbnail and icon
- **Same composition as theirs:** a muscular character flexing on top of the half-built giant egg, arm raised, sunset sky.
- **Our additions:**
  - a pet bursting out of a crack
  - the quality meter at "LEGENDARY"
- **Never reuse their art, colours or character.** That's the copycat filter's "same title and visuals" example.

## 6. SFX / VFX (Pyramid's are undocumented, so these are ours)
- **SFX:**
  - a pickup "clack" (pitch rises with piece rarity)
  - a place "thunk" with a ring sweep when a ring completes
  - the quality meter rising and falling
  - a crack-and-hatch fanfare scaled by tier
- **VFX:**
  - a rarity glow on carried pieces
  - a shimmer up the egg as quality improves, cracks as it falls
  - a beam-and-burst on hatch, scaled by rarity
- **Performance:** cap all effects for low-end mobile (50-player servers lagged at 100 in Pyramid).

## 7. Polish we add AFTER the 1:1 core works (from their player complaints)
1. **Slow first hours.** Make the first Common Egg 25,000 pieces instead of 171,700, so a new server hatches within its first session. Scale later eggs up.
2. **Lag at 100 players.** Launch at 50. Batch counter updates (send every 0.5s, not every placement).
3. **Exploit scripts** (auto pickup/place/train are everywhere for Pyramid). Make pickup and place server-authoritative with distance and rate checks, and don't trust "I'm holding N pieces" from the client.
4. **Pharaoh pass feels pay-to-win.** Golden Goose gives 2x credit and speed but **not** extra hatch luck.
5. **No live-ops cadence** (Pyramid has none). A weekly themed egg every Saturday morning (PT), and a Pumpkin Egg for Halloween.
6. **Code failures on laggy servers.** Redeem codes server-side with retries.

## 8. Gaps to fill by playing Pyramid for an hour (before production)
1. Stat gain per rep and per gym tier; the Strength → carry formula; caps.
2. Average round time at 50 players (stopwatch two rounds).
3. Current pyramid size (171,700 vs ~240,000) and the sizes of each project tier.
4. Where purchase prompts appear; whether the progress bar is on-screen or a billboard.
5. Carry and place animation timings; SFX and music.
6. The Golden Goose price we should match: 120 or 149 R$.
7. Whether the 2x training pool needs a minimum contribution.

## Next steps
1. You play Pyramid for an hour with the checklist in §8.
2. I fill in the numbers and run a simulation of pacing (time to first hatch, to the 2x gym, to 10x).
3. Production: config modules, server-authoritative systems, and the UI build sheet. Only when you say go.
