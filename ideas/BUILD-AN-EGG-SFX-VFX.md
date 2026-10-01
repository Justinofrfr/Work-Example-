# Build an Egg! — full SFX + VFX + UI-feel spec (2026-10-01)
Build the Pyramid!'s own sounds and effects are not documented anywhere reachable from here. Everything below is our design, written to be clearer and juicier than a plain build sim.

**Where to get sounds**
- **Roblox Creator Store → Audio:** free, already licensed for Roblox, uploaded by Roblox. Search the "Store search" terms in each table.
- **sfxmint.com:** CC0, free, no attribution. Its API is blocked from this session, so use the set and role names below on your side (for example `https://sfxmint.com/api/v1/sets/retro-game`).
- **Music:** SFXMint has none. Use Roblox's licensed music library in the Creator Store.

**Rules for every sound**
- One sound per event.
- UI cues ≤ 300 ms at volume 0.3–0.5. World cues 0.4–0.7.
- Use 3D sounds (parented to a part) for world events and 2D (SoundService) for UI.
- Settings toggles: Music, SFX, Effects quality (High / Low / Off).

**Rarity colour tokens** (used by every effect)

| Rarity | Hex |
|---|---|
| Junk | #6B5B4A |
| Normal | #E8E2D0 |
| Shiny | #7FD8FF |
| Golden | #FFC93C |
| Legendary | #B66DFF |
| Mythic | #FF4FA3 |

Light emission rises with rarity: Junk 0 → Mythic 1.

---

## 1. World and ambience
| Event | SFX (description · length · how to play) | Store search / SFXMint | VFX |
|---|---|---|---|
| Nest valley ambience | soft wind, distant birds, light leaves · loop · 2D 0.25 | "wind birds ambience loop" / role `forest-loop` or `wind` | slow drifting dust motes near the egg (Rate 4, Lifetime 6–8 s, Size 0.2, Transparency 0.7) |
| Background music | upbeat light adventure loop; second track for the final 10% | Creator Store music library: "adventure upbeat", "hype build" | — |
| Final 10% music swap | music crossfades to a faster track over 2 s | — | sky slowly tints warmer (Atmosphere Haze +0.5 tween over 10 s) |
| Next egg announced | short horn and whoosh · 1.2 s · 2D 0.5 | "fanfare short horn" / set `video-editing` role `riser` | big banner "NEXT: VOLCANO EGG" slides in from the top (see UI §6) |

## 2. Quarry: picking up pieces (fires every 1–3 s, so keep them short)
| Event | SFX | Store / SFXMint | VFX |
|---|---|---|---|
| Pick up Junk | dull stone thud · 120 ms · 3D 0.4 · pitch 0.9 | "rock thud short" / search "dull stone thud" | small brown dust puff (6 particles, Lifetime 0.4) |
| Pick up Normal | clean stone clack · 120 ms · 3D 0.45 · pitch 1.0 | "stone click" / role `click` (`ui-crisp`) | white dust puff (6 particles) |
| Pick up Shiny | crystal "ting" · 200 ms · 3D 0.5 · pitch 1.1 | "crystal ting" / role `pickup` (`retro-game`) | 8 blue sparkles burst + PointLight flash 0.2 s |
| Pick up Golden | rich chime and shimmer tail · 400 ms · 3D 0.6 | "magic chime" / role `powerup` | 14 gold sparkles + upward light beam 0.5 s + nearby players see the glow |
| Bulk pickup (2–5 at once) | play the single cue once, pitch +5% per extra piece (never stack 5 sounds) | — | pieces pop onto the stack one by one, 0.05 s apart |
| Carrying (idle) | none (silence keeps it clean) | — | carried stack keeps its rarity glow; Golden adds a faint trail (Trail, Lifetime 0.3) |
| Stack full | soft "bonk" · 150 ms · 2D 0.35 | role `error` (`ui-soft`) | capacity counter shakes (UI §6) |

## 3. Egg site: placing pieces
| Event | SFX | Store / SFXMint | VFX |
|---|---|---|---|
| Place a piece | solid "thunk" · 150 ms · 3D 0.5 · **pitch rises 0.9 → 1.3 as the build climbs ring by ring**, so progress is audible | "stone place thud" / role `land` (`platformer`) | dust ring at the placement point (8 particles outward, Lifetime 0.35) + piece snaps in with a 0.12 s scale pop (0.8 → 1.0, Back easing) |
| Place a Shiny / Golden piece | thunk + layered sparkle · 250 ms | add role `pickup` on top | local shimmer spreads 4 studs across the shell surface |
| Place outside the glowing band | soft "nope" · 120 ms · 2D 0.3 | role `error` (`ui-soft`) | band flashes white twice |
| Floating +1 coin | tiny coin tick · 60 ms · 2D 0.25 · **max 6 per second per player** | role `coin` | pooled BillboardGui "+1" drifts up 3 studs and fades over 0.6 s (pool of 20 per client) |
| Ring completed | rising sweep and whoosh · 0.8 s · 3D 0.6, heard server-wide | "whoosh sweep up" / set `video-editing` role `whoosh` | a light Beam races around the ring in 0.8 s + the glowing band moves up with a 0.4 s tween |

## 4. Egg quality (your good egg / bad egg mechanic)
| Event | SFX | Store / SFXMint | VFX |
|---|---|---|---|
| Quality ticks up | gentle rising chime · 200 ms · 2D 0.3 · **max once every 2 s** | role `correct` (`learning`) | quality meter fills with a 0.3 s tween; the shell gets a soft shimmer pulse |
| Quality ticks down | small "crack" · 200 ms · 2D 0.35 · max once every 2 s | "ice crack small" / search "small crack" | thin crack decal flickers on the shell; meter needle dips with a red flash |
| Tier up (e.g. Good → Great) | stinger and sparkle · 1.0 s · 2D 0.55 | role `level-up` / set `learning` role `level_up` | whole shell changes colour/pattern over 1 s; banner "EGG QUALITY: GREAT!" |
| Tier down (e.g. Good → Plain) | low thud and crack · 0.8 s · 2D 0.5 | "glass crack heavy" / set `horror-game` role `stinger` (short) | big crack decal sweeps across the shell; screen edge flashes red for 0.3 s |
| Reaching LEGENDARY quality | deep impact and shimmer · 1.5 s · 2D 0.6 | set `video-editing` role `braam` | purple aura around the egg (2 ParticleEmitters, Rate 20, ring shape) + god rays (SunRays Intensity tween) |

## 5. Server milestones and completion
| Event | SFX | Store / SFXMint | VFX |
|---|---|---|---|
| 25 / 50 / 75% built | horn blast · 1.2 s · 2D 0.5 | "victory horn short" | 4 fireworks bursts above the egg (Rate burst 30, Lifetime 1.5); banner "50% BUILT!" |
| 90% | tension riser starts (music swap) | set `video-editing` role `riser` | egg starts a slow wobble (CFrame sine, 0.5° amplitude) |
| 95% countdown | clock tick every second for the last 5% · 80 ms · 2D 0.35 | role `countdown` (`checkout` / `puzzle-game`) | progress bar pulses; Hatch Luck prompt appears (money §3) |
| Last piece placed | heavy stone slam · 0.6 s · 3D 0.8 | role `hit` / "stone slam" | camera shake: magnitude 0.6, 0.4 s, all players within 300 studs |
| Egg glows | rising hum · 2.5 s · 3D 0.6 | "magic charge up" | egg Neon material glow from 0 → 1 over 2.5 s; light rays from the cracks |
| Egg cracks | multi-crack sequence · 1.5 s · 3D 0.7 | "egg crack" or "ice crack" layered | 3 crack-decal stages, 0.5 s apart; 12 shell-fragment parts fall (anchored afterwards, cleaned up after 10 s) |
| Egg bursts | big burst and impact · 1 s · 2D 0.8 | role `explosion` (soft variant) | white flash (ColorCorrection Brightness +0.4 for 0.2 s) + 60 shell confetti + shockwave ring (Beam expanding over 0.5 s) |
| Completion fanfare (scaled by egg quality) | Cracked: short jingle · Good: fanfare · Legendary: full fanfare + cheer | role `win` / set `puzzle-game` role `celebration` | Cracked: small confetti · Legendary: confetti + rainbow fireworks + 5 s of golden rain |

## 6. Hatch reveal (per player; the clip moment)
**Sequence:** drumroll → shake → reveal. Total 3.5 s. A Skip button appears after the 2nd hatch.

| Step | SFX | VFX / UI |
|---|---|---|
| Drumroll | rising drum/tick roll · 1.5 s · 2D 0.5 (search "drum roll short") | egg icon in the centre of the screen shakes harder over 1.5 s (rotation ±3° → ±12°) |
| Hint | rarity "teaser" tone (same pitch for all rarities until Epic, so it doesn't spoil) | glow colour shows from Rare up, a tease |
| Reveal: Common | soft pop · 200 ms | pet card pops in (scale 0 → 1.1 → 1.0, Back easing 0.3 s), white sparkles |
| Reveal: Rare | pop + sparkle · 400 ms | blue burst, 20 sparkles |
| Reveal: Epic | whoosh + chime · 700 ms | purple beam behind the card, 40 sparkles, light camera shake 0.2 |
| Reveal: Legendary | impact + shimmer · 1.2 s | golden beam, rotating rays behind the card, screen-edge glow, shake 0.4 |
| Reveal: Mythic | big impact + long shimmer · 2 s · plus a **server-wide announcement** chime | pink/rainbow beam, rays, confetti, shake 0.6, chat and banner: "Lezi hatched a MYTHIC Lava Dragon!" |
| Shell Fragment (below the minimum) | small "tink" · 150 ms | fragment icon flies to the currency counter |

## 7. Pets
| Event | SFX | VFX |
|---|---|---|
| Equip | pop · 150 ms (role `pop`, `ui-crisp`) | pet spawns beside you with a 0.25 s scale pop + a ring of 8 sparkles in its rarity colour |
| Unequip | soft pop down · 120 ms | pet shrinks out over 0.2 s |
| Pet following you | none | idle bob (sine 0.3 studs, 1.2 s); rarity glow for Legendary and up only (budget) |
| Merge 3 → 1 | whirl → ding · 1.2 s (search "magic swirl" + role `success`) | 3 pets spiral into the centre over 0.8 s → white flash → bigger pet pops out |
| New pet in collection index | page-flip + chime · 0.5 s | index slot fills with a 0.3 s colour wipe; "NEW!" tag |
| Index set complete | level-up stinger · 1 s | confetti + reward card |

## 8. Gyms and stats
| Event | SFX | VFX |
|---|---|---|
| Start training (step in) | "whoosh in" · 200 ms | gym pad lights up in the gym tier colour |
| Training rep (repeats) | none per rep (avoids spam); a soft loop of the treadmill/bench hum · 2D 0.2 while training | aura around the player in the gym tier colour (Rate 6) |
| Stat milestone (every ×10 of your stat) | tick-up chime · 150 ms | stat number pulses (scale 1.0 → 1.15 → 1.0, 0.2 s) |
| Unlocked a new gym (2x, 5x …) | gate opening + fanfare · 1.2 s | gym gate swings open (Hinge tween 1 s) + fireworks + banner "10x GYM UNLOCKED!" |
| Locked gym touched | soft "locked" clunk · 150 ms | lock icon wiggles; shows "Hatch 8 eggs or unlock now" with the gamepass button (the Pyramid gate-skip pattern) |
| Inside-the-egg 2x pool | water splash on enter · 0.5 s + water loop | yolk-gold water shimmer, bubbles (Rate 10), "2X TRAINING" floating sign |

## 9. Progression, rank and money
| Event | SFX | VFX |
|---|---|---|
| Rank up (Hatchling → Nester …) | level-up stinger · 1 s (role `level-up`) | burst around the player in the rank colour; new title above your name with a 0.3 s pop |
| Coin upgrade bought (Bulk Pickup etc.) | purchase blip · 250 ms (role `purchase-success`) | upgrade card flashes green; button shakes once |
| Can't afford | soft error · 150 ms | price text flashes red; the Robux shortcut button pulses once |
| Robux purchase complete | checkout success · 0.6 s (set `checkout` role `success`) | item card glow + confetti burst in the panel |
| Someone buys a **Shell Drop** | server-wide horn + rain whoosh · 1.5 s | **Golden pieces rain from the sky over the quarry for 8 s** (pooled parts, max 40 visible) + banner "Lezi dropped 5,000 GOLDEN SHELLS!" |
| Golden Goose pass owner | none | permanent golden aura (Rate 3, gentle) + golden trail when carrying |
| Free Gift claimed | reward chime · 0.6 s (set `checkout` role `reward`) | gift box opens, +1,500 numbers fly to the stat counters |
| Code redeemed / invalid | success chime / soft error | green / red flash on the code box |

## 10. UI feel (every screen)
- **Buttons:** hover scale 1.0 → 1.05 (0.08 s, Quad Out). Press 0.95 (0.05 s). Release back to 1.0 (0.1 s, Back Out). Click SFX: role `click` (`ui-crisp`), volume 0.35. No hover sound on touch devices.
- **Panels:** open by sliding up 20 px and fading in (0.2 s, Quint Out) with role `modal`. Close 0.15 s with role `swipe`.
- **Server progress bar** (top centre): fill tweens 0.25 s per update. Server updates are batched every 0.5 s. A shine sweeps across the bar every 5 s.
- **Quality meter** (beside the progress bar): the needle tweens 0.3 s, colour follows the tier, and it shakes on a tier drop.
- **Your contribution %** (under the bar): count-up tween, plus a small sparkle when it crosses 1%, 5% and 10%.
- **Banners** (milestones, next egg, Shell Drop, Mythic): slide in from the top (0.35 s, Back Out), hold 2.5 s, slide out (0.25 s). Show at most one at a time; others queue.
- **Number pop-ups:** pooled. Big numbers abbreviate as 1.2K / 3.4M.

## 11. Camera
- **Shake:** only for the last piece (0.6), egg burst (0.8), and Epic and higher hatches (0.2–0.6). Always under 0.5 s. A setting turns it off.
- **Completion cutscene:** optional 6 s orbit of the egg: rise → crack → burst. The skip button shows from second 1. Plays once per round, and only for players who contributed.

## 12. Performance budget (the anti-lag rules)
- **Effects run on the client.** The server sends one batched event (e.g. `PlacementBatch` every 0.5 s) and each client plays the effects locally.
- **Particle budget:**
  - At most 300 live particles per client.
  - Emitters at most Rate 30.
  - Effects more than 150 studs away are culled.
  - "Low" effects quality halves the rates; "Off" keeps only the UI tweens.
- **No `Highlight` instances on pieces** (Roblox caps how many render). Use Neon material + PointLight for Shiny and better only.
- **Pooling:** shell fragments, coin pop-ups, golden rain parts and confetti are all pooled. Nothing is created per placement.
- **Sounds:** preload the 8 most-used (pickup ×4, place, coin, click, ring complete). Rate-limit repeating cues: coin 6/s, quality tick 1 per 2 s.
- **Mobile check:** test on a low-end phone in a 50-player server during the final 10% (the worst case).

## 13. Shopping list to collect
- **About 45 sounds:**
  - 4 pickups
  - 3 places
  - 4 quality cues
  - 6 completion cues
  - 6 hatch tiers
  - 6 pet cues
  - 6 gym cues
  - 6 economy cues
  - 4 UI cues
  - ambience
  - 2 music tracks
- **About 12 particle textures:** dust puff, sparkle, star, confetti, shell shard, glow ring, beam, bubble, rays, firework spark, plus coin and gift icons. Roblox's default particle textures cover most of these.
- **Decals:** 3 crack stages, 6 shell patterns (one per quality tier).

If you want, I'll turn this into config ModuleScripts (an SFX map and an effects map with every value above), so swapping in the real sound IDs later is a one-line change per sound.
