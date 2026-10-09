# The 14 Judge-Selected Ideas: Detailed Breakdown
Research date: Sept 27–28, 2026. Sources are in `FINAL-TOP-PICKS.md`, `factcheck/` and `research/`.

## Read this first: rules that apply to every idea

**Money math.** These are estimates from the council's Investor memo.
- Payout: $1 that players spend ≈ **$0.21** to you, or **$0.30** from age-verified US 18+ spenders. DevEx is $0.0038 per Robux.
- Net earnings per 1 average concurrent player (CCU) per month:
  - **HIGH** density (collection/RNG/steal-protect): **$1.9–4.2**. Anchor: Tizzy's Build a Base and Steal made $25K/mo at 13.1K CCU, then $119K/mo at 38K CCU.
  - **MID**: **$1.5–2.3**.
  - **LOW** (party/round games): **~$0.6**. Party games earn about 18% of what collection games earn per player-hour (Creator Exchange, Aug 2025).
- So **1,000 average CCU ≈ $1.9K–4.2K a month** for a HIGH game. Most new games never reach 1,000. The realistic early target is 150–1,000.

**Monetization rules**
1. **Consumables over gamepasses.** "Spend days per user" is a ranking signal, so many small repeat buys beat one big pass.
2. **Painkillers, not vitamins.** Sell the fix at the exact moment of pain: the timer, the fail screen, the moment someone is about to steal from you. Give every product 3+ ways to reach it (world prompt, shop, fail screen).
3. **Paid randomness is regulated (since May 26, 2026).**
   - If Robux buys a random outcome, or boosts luck on one, show odds that add up to 100% before purchase.
   - Update those odds live when a luck boost is active.
   - Gate AU/BE/NL/UK/BR players with PolicyService.
   - Safer default: Robux buys **luck, speed, skips and protection**. Capsules and bags are bought with in-game coins.
4. **Never break the economy.** Every faucet (way currency enters) needs a sink (way it leaves).
5. **Extra revenue lines you get for free:**
   - Regional pricing, on by default: +4–10% revenue.
   - Rewarded video ads once you have 2K monthly visitors.
   - Robux subscriptions (49 R$ minimum, you keep 70%). Good for a "daily free capsule" pass.
   - Creator Rewards: 5 R$ a day per qualifying daily player.
   - **40% commission** on UGC avatar items bought inside your game.
6. **Prices below are starting points.** Test them with Roblox's native A/B testing, which applies config changes in about 5 minutes.

**Why any of these can rank (the June 2026 algorithm)**
- Home "Recommended for You" is 90%+ of discovery.
- It ranks on:
  - Play-through rate (honest thumbnail)
  - Bounce in the first 60s and in 60–180s
  - **Play days across days 1, 2–7 and 8–28**
  - Playtime, capped at 60 min a day
- Co-play days and spend days are secondary signals.
- Every idea below is designed to:
  1. Deliver its title in 30 seconds.
  2. Have timers that bring players back daily.
  3. Reward playing with friends.

**What you do vs. what I do:** you build maps, models and UI (plus any RemoteEvents I ask for). I write the OOP services and controllers, the module loader, and the config ModuleScripts, all server-authoritative.

---

## 1. Clip a Bag Charm (Build now, speed bet, ~3 weeks)

**The game.** You spawn in a small mall with a plain backpack visible on your avatar. Capsule machines hold plush bag charms: animals, food, tiny monsters, all original characters. Each charm clips onto your bag, where everyone can see it. Charms earn "Style" coins every second while clipped, so a better bag means more income. Charms roll rarity (Common → Mythic → Secret) and a mutation (Fuzzy, Glitter, Glow, Rainbow). Four duplicates merge into one higher tier.

**The twist:** charms have **weight**. Every hour there's a **Bag Race**, an obstacle run through the mall. A heavy, flexy bag scores more Style but runs slower. Every race forces a choice between showing off and winning.

**Why it would work**
- **Real trend.**
  - Bag charms are the 2026 back-to-school accessory: Google searches +168% in 2025, Pinterest +700% (trend reports).
  - Plush charms are the current most-viral style.
  - Kids 8–14 already collect them in real life. The Labubu wave proved blind-box collecting psychology at massive scale.
- **Lane is open.** Only catalog UGC charm items exist on Roblox. No charm collection game was found (fact-checked twice).
- **Avatar identity sells on Roblox.** Catalog Avatar Creator and Dress To Impress stay in the top charts because self-expression *is* the product. Your bag is visible on your avatar, so every player advertises your game to others in the server.
- **Psychology levers:** RNG collection + showoff + number-go-up (Style/sec) + social friction (the race).
- **Clip moment:** a Mythic-covered bag loses the race to a kid with one charm.

**Loops**
- **Minute:** roll a capsule. The tier is picked by your peg-board machine, reskinned as a "capsule sorter". Clip, earn, roll again.
- **Session:** finish a 5-charm set for a set bonus, upgrade to a bigger bag (more slots), win a race.
- **Day:** capsule machines restock every 15 min with limited stock per server (Grow a Garden-style scarcity), a free daily capsule, hourly races, offline Style income.
- **Week:** a new "Series" drops every Saturday and retires the following week (limited-series FOMO).

**Monetization**
| Product | Type | Price (start) | Pain moment it fixes |
|---|---|---|---|
| Lucky Charm Spray (2× luck, 15 min) | Consumable | 39 R$ | Right after a restock, when stock is limited |
| Restock Now (restocks the whole server) | Consumable | 99 R$ | Machine sold out; everyone benefits, so the buyer gets to flex |
| Featherweight (ignore charm weight for one race) | Consumable | 25 R$ | Race lobby countdown |
| +3 Bag Slots | Pass | 149 R$ | Bag full, can't clip the new charm |
| 2× Style | Pass | 199 R$ | Always on |
| Charm Club (1 free premium capsule a day) | Subscription | 49 R$/mo | Daily return plus recurring revenue |
| UGC charm accessories in a shop kiosk | Catalog | You earn 40% | Players wear their favourite charm outside your game |

- **Money density: HIGH.** Estimate: ~$1.9–4.2K/mo per 1,000 average CCU.
- **The UGC kiosk is a revenue line almost no competitor uses.** If you publish (or partner on) real UGC bag-charm accessories, you get 40% of every sale made inside your game.

**Risks**
- **Blind-box sims could copy it within weeks.** Mitigation: ship in 3 weeks.
- **IP risk.** No Labubu, Pop Mart or Sanrio lookalikes.
- **Kill it if:** fewer than half of testers re-roll without being told to, or nobody changes their bag before a race.

---

## 2. Freeze-Dry Your Candy (Build now, ~2.5–3 weeks)

**The game.** You own a kitchen plot with a freeze dryer. Buy candy bags with coins from a shop that restocks every 5 min. Open a bag and the pieces pour down your **peg-board sorter** into tray slots that each carry a multiplier (arcade framing, soft currency only). Load the tray, start the dryer timer, then open the door: candy **puffs up**. Puff size is random, and mutations can land: Galaxy, Glitter, Giant, Frosted, Rainbow. Sell puffed candy at your stand, display rares on your shelf, or trade during the nightly Swap Hour.

**The twist: push your luck.** You can open the door early at 60–90% progress:
- **Good outcome:** a chance at a **MEGA puff** worth 10×.
- **Bad outcome:** a chance the candy **collapses**, and you lose it.

Friends standing by your dryer can "hold the door", which adds luck. That gives players a reason to play together.

**Why it would work**
- **Real trend.**
  - #freezedriedcandy is reported at 2.7–4.7B TikTok views and called one of the loudest food trends of 2026 (secondary trend reports).
  - The before/after puff plus the audible crunch is exactly the TikTok "clip moment" format.
- **Proven loop.** Timer growth plus offline progress plus restock scarcity is the Grow a Garden skeleton. GaG was reportedly built in 3 days and became Roblox's all-time CCU record holder.
- **Lane open.** No freeze-dry game was found on Roblox, only candy tycoons.
- **Reuses your Plinko system,** so it's the cheapest MVP.
- **Seasonal tail.** Launch on Halloween candy, move to Christmas candy canes, then Valentine's hearts. Each season swaps content and keeps the same systems.
- **Levers:** RNG + ASMR + number-go-up + social (swap hour, friend luck).

**Loops**
- **Minute:** open a bag, sort it, load a tray.
- **Session:** dryer tiers (×3 → ×10 capacity), candy index, stand upgrades.
- **Day:** dryer timers of 5–30 min that keep running offline, the 5-min shop restock, a "Candy of the Day", and the nightly Swap Hour.
- **Week:** a new candy line every Saturday. Rebirth resets kitchen money for a permanent puff multiplier.

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Instant Dry | Consumable | 19–79 R$ (scales with time left) | Staring at a long timer (Grow a Garden's best seller type) |
| Stable Door (no collapse on an early open) | Consumable | 29 R$ | Right before the risky early open. **Main painkiller** |
| Mutation Syrup (luck, 15 min) | Consumable | 49 R$ | While loading a tray |
| Sugar Rush (server-wide 2× mutations, 10 min) | Consumable | 99 R$ | Social flex, and everyone thanks the buyer |
| +1 Dryer | Pass | 149 R$ | Waiting on a single dryer |
| 2× Offline Drying | Pass | 199 R$ | Logging out |

- **Money density: HIGH.** Estimate: ~$1.9–4.2K/mo per 1,000 CCU.

**Risks**
- **Loot-box optics.** Bags are bought with coins only, odds are shown, PolicyService gating is on.
- **Lane could fill.** Speed matters.
- **Kill it if:** testers stop after their first puff, or nobody ever opens early.

---

## 3. Unwrap the Golden Ticket (Build first, ~3 weeks)

**The game.** A chocolate town plaza with a closed factory gate at one end. Buy chocolate bars with coins and unwrap them: slow foil-tear ASMR, then a chocolate piece with rarity and flavour mutations for your wrapper album, or a sale. Hidden in the bars: **only 5 Golden Tickets per server per hour.**

When you pull one, your avatar glows gold and the whole server sees it. You have 60–90 seconds to carry the ticket across the plaza to the gate. **Anyone can tag you and steal it.** You can also sell it on the spot to another player for coins. Reach the gate and you enter a **90-second Factory Run**, a room-based challenge (chocolate river, candy maze, sugar-glass bridge) with the game's best prizes: factory-only accessories, rare bars and ticket stubs.

**Why it would work**
- **Hottest trend on the list.**
  - Netflix's *Wonka's The Golden Ticket* premiered **Sept 23, 2026**; per Variety, NBC and Netflix Tudum, it pays $3M to the winner.
  - Ferrero and Netflix announced a Wonka candy brand revival for autumn 2026: chocolate, candy, ice cream and cereal.
  - Kids will see golden tickets on TV and in stores at the same time.
- **Lane open.** On 9/27, Roblox search showed only old Chocolate Factory Tycoons and UGC items. There was no golden ticket game.
- **Proven social engine.** "Grab the valuable thing and run while others try to steal it" is the Steal a Brainrot / Steal An Egg engine; Steal An Egg was around 2M CCU in late Sept 2026. Here it's scarce, timed and public, which manufactures chaos every hour.
- **Clip moment:** a ticket snatched one stud from the gate.
- **Levers:** RNG collection + social friction + ASMR + showoff (factory-only items).

**Loops**
- **Minute:** unwrap bars, fill the wrapper album.
- **Session:** bench upgrades (unwrap faster, carry more), album sets.
- **Day:** hourly ticket drops with a notification opt-in ("5 tickets just dropped!"), a daily free bar.
- **Week:** a Saturday "Golden Hour" (20 tickets), new factory rooms each update.

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Golden Nose (higher ticket/rare chance, 15 min) | Consumable, odds shown live | 49 R$ | Just before the hourly drop |
| Escort Shield (8s tag immunity + speed) | Consumable | 29–49 R$ | **The instant you pull a ticket.** Same idea as Tizzy's #1 seller, a base lock (theft anxiety) |
| Factory Retry | Consumable | 19 R$ | Fail screen inside the factory |
| Auto-Unwrap Bench | Pass | 199 R$ | Grind fatigue |
| +Speed | Pass | 99 R$ | Being chased |

- **Money density: HIGH.** Estimate: ~$1.9–4.2K/mo per 1,000 CCU.
- **Balance rule:** the shield must be short, never full invincibility, or paying wins every chase and free players quit.

**Risks**
- **IP:** no Wonka, Willy, Oompa or Roald Dahl names or lookalikes. Use your own chocolatier character.
- **Empty servers:** in small servers, NPC "sweet thieves" chase ticket holders.
- **Hype fades when the show ends.** Convert to an evergreen candy-factory game with new rooms monthly.
- **Kill it if:** nobody chases ticket holders during tests.

---

## 4. Stock a Bird Feeder (~3–4 weeks)

**The game.** You own a cozy backyard. Hang feeders and pick the seed (sunflower, nyjer, suet, nectar). Birds arrive as RNG spawns shaped by seed, feeder type, weather and time of day: sparrows are common, a leucistic cardinal is 1 in 50,000. Snap them with a camera minigame, where framing quality multiplies the coins. Every species fills your bird album.

**Offline "trail camera":** birds keep visiting while you're away. When you log in, you get a reveal of what came.

**The twist:** other players can join as **squirrels** and raid your feeders for seed through a baffle course you design. Bots fill quiet servers. **Crow Night:** crows bring trinkets you can trade.

**Why it would work**
- **Real behaviour.** Birdbuddy smart feeders (camera feeders that ping you with "a bird visited!"):
  - named one of TIME's Best Inventions 2023
  - sold out on Prime Day 2024
  - raised $2.5M on Kickstarter in 2025
  - Birdbuddy 2 preorders sold out at CES 2026

  The "who visited while I was gone?" surprise is proven dopamine and a **built-in reason to come back on day 1.**
- **Lane open.** Bird games on Roblox are "play as a bird". No feeder or visitor game was found.
- **The squirrel mode** adds social friction without stealing collections (raids take seed, never birds), so it isn't a harsh "Steal a X".
- **Levers:** RNG collection + showoff (album, rare sightings) + offline accrual + social friction.

**Loops**
- **Minute:** refill, snap, sell photos.
- **Session:** more feeders, rarer seeds, album sets.
- **Day:** seed timers of about 20 min, the offline camera, Crow Night, weather events (rain brings rare birds).
- **Week:** a Saturday "migration" species available for 7 days only.

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Premium Seed (rare-bird luck, 15 min) | Consumable | 29–79 R$ | Filling the feeder |
| Call the Rain (server-wide weather) | Consumable | 99 R$ | Social flex, and rare birds for everyone |
| Baffle Repair | Consumable | 19 R$ | Right after a squirrel raid |
| 24h Offline Camera | Pass | 149 R$ | Logout |
| +Feeders | Pass | 149 R$ | Yard full |

- **Money density: HIGH.** Estimate: ~$1.9–4.2K/mo per 1,000 CCU.

**Risks**
- **Kid demand is the weakest-proven part** (the Birdbuddy buyer is often adult).
- **The squirrel side may be empty.** Ship bots.
- **Kill it if:** testers don't come back after an offline gap.

---

## 5. Scrub the Kaiju (speed bet, ~3 weeks)

**The game.** A harbor where a **skyscraper-sized sleeping monster** lies covered in mud, moss and barnacles. The whole server pressure-washes it together.
- Every zone you clean pays coins.
- Barnacles pop open with random treasure.
- At 100% clean, the kaiju **wakes up** (server cutscene), roars and showers loot. The top scrubbers get the Wake Chest.
- A new kaiju species arrives every 20–30 minutes. Collect them in the Kaiju Book.

**Why it would work**
- **Proven wave.** Cleaning ASMR is huge right now:
  - Clean all the Leaves: ~86.8K CCU
  - Wash The House: ~31.5K CCU
  - Dig & Clean: ~27.8K CCU

  Every one of those is a **solo** chore sim.
- **Your twist is server co-op.** 100 players on one giant goal is a proven format (Build the Pyramid!), and it hits the **co-play signal** the algorithm now rewards.
- **Thumbnail power.** A giant half-clean monster is instantly readable and different from every "wash a house" tile.
- **Levers:** ASMR + co-op + RNG (barnacles) + spectacle.
- **Clip moment:** the clean kaiju roars awake and loot rains down.

**Loops**
- **Minute:** scrub zones.
- **Session:** hose tiers, reach the wake-up.
- **Day:** kaiju rotation every 30 min, a daily legendary.
- **Week:** a Saturday event kaiju (a swamp pumpkin kaiju for Halloween). Hose prestige.

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Turbo Nozzle (3× clean speed, 10 min) | Consumable | 25 R$ | Stubborn grime |
| Treasure Lens (barnacle luck) | Consumable | 39 R$ | Barnacle zones |
| Wake Chest ×2 | Consumable | 49 R$ | At the reveal countdown |
| Summon Legendary Kaiju (server) | Consumable | 149 R$ | Flex, and the whole server benefits |
| Hose tiers / Auto-Scrub | Pass | 99–199 R$ | Grind |

- **Money density: MID.** Estimate: ~$1.5–2.3K/mo per 1,000 CCU.

**Risks**
- **Lag from a giant dirt surface.** Use a tiled decal grid, not per-pixel.
- **Freeloaders.** Chest rewards scale with contribution.
- **Kill it if:** solo players leave before the first wake-up. Scale kaiju size to player count.

---

## 6. Shoot the Pixel Art (build only if a Roblox search finds no clone; speed bet, ~3 weeks)

**The game.** A Roblox version of **Pixel Flow**, the mobile hit.
- You have a conveyor belt and a bench of cute colour shooters.
- Tap a shooter onto the belt. As it rides around, it fires balls of its colour into a pixel picture, and matching pixels pop.
- Clear the picture to earn coins, and collect shooters with rarity (bigger ammo, rainbow shooters that match any colour).

**The twist:** every 20 minutes a **server mega-mural** appears. Everyone shoots the same giant picture, and your overflow spills onto a friend's belt. When it completes, the full picture reveals and everyone gets a random **sticker** of it for their album.

**Why it would work**
- **Proven loop with huge money.**
  - Pixel Flow! made >$1M a day at its peak and more than $100M lifetime.
  - Scopely bought a majority stake at a >$1B valuation (Feb 2026).
  - Kids already play it.
- **Lane looked open** (one check found no Roblox version). Check again before you start.
- **One-tap mobile play** fits a Roblox audience that is about 80% on mobile.
- **Its monetization transfers directly.** Hybrid-casual games make money at the **fail state** (jammed belt), which maps perfectly to Roblox consumables.
- **Levers:** ASMR + co-op + RNG collection (stickers, shooters).

**Loops**
- **Minute:** place shooters, pop pixels.
- **Session:** bigger murals (20×20 → 200×200).
- **Day:** the mega-mural every 20 min, a daily mural.
- **Week:** Saturday mural packs, each with its own sticker set.

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Belt Clear | Consumable | 15 R$ | **Belt jammed (the fail state)** |
| Continue (+5 slots) | Consumable | 19 R$ | Out-of-moves screen |
| Shooter Egg Luck | Consumable | 39 R$ | Hatching shooters |
| +Bench Slot | Pass | 149 R$ | Overflow |

- **Money density: MID.** Estimate: ~$1.5–2.3K/mo per 1,000 CCU.
- **Build tip:** I can script a tool that turns any pixel-art image into a level, so level content costs almost nothing.

**Risks**
- **Clones likely soon.** Speed matters.
- **Don't copy Pixel Flow's pig art or name.**
- **Kill it if:** players ignore the shared mural, or median session is under 5 min.

---

## 7. Chop the World Tree (~2 weeks, the fastest build)

**The game.** One enormous tree per server, and everyone chops it.
- Every swing knocks wood chips down through the branches (your **peg-board engine**) into rarity bins: acorns, sap, rare woods, a golden acorn.
- Tree health scales with player count, so it falls about every 15 minutes in a **server cutscene**.
- The top choppers get the Canopy Chest.
- Species rotate: oak, crystal tree, haunted tree. Fill the acorn index, upgrade axes, rebirth.

**Why it would work**
- **The verb is proven.** Chop Your Tree has 134.2M visits (created Nov 2025).
- **Your twist is structural:** 100 players, ONE tree, one shared fall. That's co-play plus a spectacle the solo-tree games can't show in a thumbnail.
- **Reuses the Plinko system** (chips bouncing through branches), so it's the cheapest build on the list.
- **Levers:** number-go-up + RNG + co-op + spectacle.

**Loops**
- **Minute:** chop, roll drops.
- **Session:** axe tiers, tree falls.
- **Day:** species rotation every 30 min.
- **Week:** a Saturday special tree. Axe prestige (rebirth).

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Lucky Axe (drop luck, 15 min) | Consumable | 39 R$ | Chopping |
| Canopy Chest ×2 | Consumable | 49 R$ | Fall countdown |
| Auto-Chop 30m | Consumable | 29 R$ | Going AFK |
| Summon Crystal Tree (server) | Consumable | 149 R$ | Flex |
| Axe tiers | Pass | 99–199 R$ | Grind |

- **Money density: HIGH.** Estimate: ~$1.9–4.2K/mo per 1,000 CCU.

**Risks**
- **Being seen as a Chop Your Tree clone.** The name, thumbnail and first 10 seconds must show the whole server on one giant tree.
- **Kill it if:** testers say "this is Chop Your Tree."

---

## 8. Pass the Cursed Aura (Halloween speed bet, ~2 weeks)

**The game.** An aura-rolling game (roll for auras from 1-in-2 up to 1-in-10,000,000) with **one cursed aura loose in the server**.
- **The reward:** whoever touches it holds it, and the holder rolls at **×10 luck**.
- **The catch:** it detonates at a random moment (10–40s), wiping the holder's last unsaved roll.
- Everyone wants it but must pass it on before it blows. It's hot potato, played with rarity rolls.
- The player with the rarest aura wears a **bounty crown**. Tag them for a bonus.
- Blood Moon windows 3 times a day: faster fuse, more luck.

**Why it would work**
- **Aura RNG is one of Roblox's biggest proven formats.** Sol's RNG has 2.1B+ visits and is still the #1 luck-RNG game.
- **The problem is that those games are passive** (AFK rolling). Your twist makes rolling *active and social*, with chases, betrayal and clutch passes.
- **Halloween-themed and a 2-week build.**
- **Clip moment:** a mythic lands 0.2 seconds before detonation.
- **Levers:** RNG + social friction + showoff (auras) + co-play.

**Loops**
- **Minute:** roll, chase or dodge the curse.
- **Session:** fill the aura index, with pity (a guaranteed Legendary by roll X).
- **Day:** 3 Blood Moons.
- **Week:** a new aura set every Saturday.

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Curse Ward (protect your next roll) | Consumable | 29 R$ | While holding the curse |
| Fuse Extender (+10s) | Consumable | 19 R$ | Fuse about to blow while you're mid-roll |
| Luck Potion | Consumable, odds shown live | 49 R$ | Anytime |
| Bounty Shield | Consumable | 29 R$ | Wearing the crown |
| Quick Roll / Auto Roll | Pass | 149–249 R$ | Grind |

- **Money density: HIGH.** Estimate: ~$1.9–4.2K/mo per 1,000 CCU.

**Risks**
- **Crowded parent lane.** The thumbnail must show the hot-potato chase, not "another aura game".
- **Never wipe anything bought with Robux.**
- **Kill it if:** players avoid the curse instead of wanting it.

---

## 9. Slice the Sand Core (build with changes, speed bet, ~2 weeks)

**The game.** Oddly-satisfying sand slicing. Cut layered sand blocks: each slice reveals hidden coloured layers and patterns (random, from Swirl up to Galaxy), with the crunchy sound. Sell your slices, and upgrade blades and block sizes.

**The required change:** every 15 minutes a **server mega-block** appears. Players take turns slicing in a queue. Hidden inside is **one rare core**, and whoever's slice exposes it keeps it. The tension builds with every cut.

**Why it would work**
- **Real trend.** Kinetic sand has 102.3M TikTok posts; top creator SandTagious has ~19M followers.
- **No Roblox sand-slicing game was found.**
- **Why it can't ship as-is:** cut-to-reveal is already contested (Cut a Gem 6.7M visits; Geodeworks!), so the shared-core queue is what makes it different.
- **Trademark:** don't say "Kinetic Sand".

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| X-Ray Glimpse (see how deep the core is) | Consumable | 39 R$ | Before your turn |
| Queue Skip | Consumable | 19 R$ | Waiting in line |
| Sharp Blade (more slices per turn) | Pass | 149 R$ | Grind |
| Pattern luck | Consumable | 39 R$ | Anytime |

- **Money density: HIGH** (estimate).
- **Build note (anti-lag):** pre-sliced meshes, no runtime CSG.
- **Kill it if:** it plays like a geode clone.

---

## 10. Never Walk Alone (build with changes, Halloween speed bet, ~3 weeks)

**The game.** Co-op horror for 2–6 players. Night falls in a quiet suburb and you do chores: fix the porch light, feed the dog, lock the gates.

**The one rule:** the **Tall Neighbor attacks anyone standing more than 25 studs from a teammate.** Staying close to your group *is* your health bar. Five nights per run, each 8 minutes, and the chores pull you apart.

**Required changes:**
- Chores drop **random relics** to collect.
- **NPC buddies** let solo and duo players play.

**Why it would work**
- **October is horror season.** 500+ active horror games with >200K combined daily CCU (RoLearn 2026), and October spikes (Fish It went 186K → 389K CCU from Sept to Oct 2025).
- **The rule fits in one sentence** and naturally makes friends scream when someone wanders off.
- **Friends play 1.9× longer,** and co-play days are a ranking signal.
- **Clip moment:** someone peeks around a corner, an arm reaches over the fence, screams, a sprint back.

**Monetization**
| Product | Type | Price |
|---|---|---|
| Buddy Flare (20s safe tether) | Consumable | 25 R$ |
| Revive | Consumable | 29 R$ |
| Lantern Luck (relic luck) | Consumable | 39 R$ |
| Flashlight and character cosmetics | Cosmetics | — |
| Private servers | Free | Co-play |

- **Money density: MID.** Horror monetizes lower than collection games, so the relic collection is what lifts it.
- **Risks:** a busy genre (THAT'S NOT MY FRIEND has similar tension). Put the distance meter in the thumbnail.
- **Kill it if:** full lobbies don't scream on night one.

---

## 11. Break the Ball Pit (build with changes, ~4 weeks)

**The game.** Co-op brick-breaker roguelite. Launch balls down a pit and smash bricks while descending floors over a 10-minute run.

**The twist:** **teammates' balls collide and fuse.** Fire + Ice = Steam, Lightning + Water = Storm. Your best build needs a friend's ball.

**Required change:** a ball-hatch collection (random balls with rarity) so there's something to collect between runs.

**Why it would work**
- **BALL x PIT** (Steam, 2025) sold 400K in week one and 2M+ total.
- **Ball VS Ball** on Roblox has 41.2M visits and ~31.6K playing (Sept 2026), which shows Roblox players want ball physics right now.
- **No Roblox brick-breaker roguelite was found.**
- **Reuses your peg-board ball physics.**

**Monetization**
| Product | Type | Price |
|---|---|---|
| Revive | Consumable | 29 R$ |
| Ball Hatch Luck | Consumable, odds shown | 39 R$ |
| Extra Launcher | Pass | 149 R$ |
| Fusion recipe book | Pass | 99 R$ |

- **Money density: MID → HIGH** once the gacha is in.
- **Risks:**
  - Colliding balls across players is a netcode challenge. Mitigation: deterministic custom physics run on the server.
  - 4 weeks is the edge of the 1-month limit.
- **Kill it if:** runs feel solo even in a party.

---

## 12. Feed a Creature (build, ~4 weeks)

**The game.** A cozy-spooky kitchen. Odd creatures walk in hungry, each with **secret taste preferences**: sweet or salty, crunchy or slimy, hot or cold. Cook dishes from ingredients and serve.
- **Right dish:** it purrs, befriends you and joins your bestiary. Collect them all.
- **Wrong dish:** it **grows bigger and chases the whole kitchen crew** (goofy, not gory).

Learning tastes becomes a puzzle the group solves together.

**Why it would work**
- **Proven fantasy.** Creature Kitchen (Steam, Feb 2026) is 99% positive across 7,392 reviews and was called Steam's highest-rated game of 2026.
- **No Roblox version was found.**
- **It mixes three proven levers:**
  - **collection** (bestiary)
  - **deduction** (learning tastes)
  - **co-op panic** (the chase)
- **Clip moment:** a giant blob creature chasing four screaming players around a kitchen island.

**Monetization**
| Product | Type | Price | Pain moment |
|---|---|---|---|
| Taste Hint | Consumable | 19 R$ | Stuck on a creature |
| Calm Treat (shrinks a chasing creature) | Consumable | 25 R$ | **During the chase** |
| Rare Ingredient Luck | Consumable | 39 R$ | Market restock |
| Creature habitats / extra kitchen stations | Pass | 149 R$ | — |

- **Money density: HIGH** (collection-driven).
- **Risks:**
  - Demand is thinner than it looks: only 553 peak players on Steam despite the reviews.
  - 4-week scope.
- **Kill it if:** testers guess randomly instead of learning tastes.

---

## 13. Bid for Fighters (build with changes, ~3–4 weeks)

**The game.** An auction-draft auto-battler for 4 players. Everyone gets the **same budget**, and fighters from one shared pool go up for auction one by one. Bid live, then your team auto-battles the others. Overpay for a legendary and you're stuck with a weak bench.

**Required change:** 4-player lobbies with **bot bidders**, and no ranked mode at launch.

**Why it would work**
- **Roll-to-fight is rising.** Ball VS Ball has 41.2M visits and ~31.6K playing.
- **Auction drama is proven on Roblox.** Storage Hunters peaked at 47.9K CCU.
- **Nobody combines the two;** no auction-draft auto-battler was found.
- **Clip moment:** someone goes all-in on one legendary and loses to a team of commons.

**Monetization**
| Product | Type | Price |
|---|---|---|
| Scout Peek (see the next 3 fighters) | Consumable | 19 R$ |
| Reroll Pool | Consumable | 25 R$ |
| Fighter skins, emotes | Cosmetics | — |
| Collection | Fighters you draft often unlock permanently | — |

- **Money density: MID.** Keep purchases away from the budget, or it becomes pay-to-win.
- **Risks:** needs full lobbies (bots from day one), and bidding can feel slow.
- **Kill it if:** bidding rounds bore testers.

---

## 14. Find the Key, One of Us Hid It (build with changes, speed bet, ~2.5 weeks)

**The game.** A cozy search game. 4–6 players dig through a huge junk pile to find 3 keys that open a treasure chest.

**The twist:** one player is secretly the **Burier**. They re-hide keys and plant fake ones, and players vote them out.

**Required change:** small lobbies plus a solo mode with an NPC Burier.

**Why it would work**
- **Search For The Needle** (a cozy haystack search, Aug 23, 2026) reached 22,530 CCU and ~30M visits in about a month. The format is hot right now.
- **A social-deduction twist** (the Murder Mystery 2 engine) is something none of the ~14 clones has.

**Monetization**
| Product | Type | Price |
|---|---|---|
| Metal Detector (ping nearest key) | Consumable | 19 R$ |
| Burier role pass (higher chance to be Burier) | Pass | 149 R$ |
| Vote Shield | Consumable | 25 R$ |
| Cosmetics | — | — |

- **Money density: MID.**
- **Risk:** the fad is about 5 weeks old and clones flooded in within 48 hours. **Ship in 2.5 weeks or drop it.**
- **Kill it if:** the search wave has faded by launch.

---

## Side-by-side summary
| # | Idea | Verdict | Build | Money | Main reason it works |
|---|---|---|---|---|---|
| 1 | Clip a Bag Charm | Build | 3 wk | HIGH | #1 2026 kid accessory trend, open lane, avatar showoff + UGC 40% |
| 2 | Freeze-Dry Your Candy | Build | 2.5–3 wk | HIGH | Billions-of-views trend, Grow a Garden timer loop, reuses Plinko |
| 3 | Unwrap the Golden Ticket | Build (first) | 3 wk | HIGH | Netflix show premiered Sept 23; Steal-style chase engine; open lane |
| 4 | Stock a Bird Feeder | Build | 3–4 wk | HIGH | Offline-surprise return loop, open lane |
| 5 | Scrub the Kaiju | Build | 3 wk | MID | Cleaning wave, but server co-op instead of solo |
| 6 | Shoot the Pixel Art | Build (if no clone) | 3 wk | MID | $100M+ mobile loop, not on Roblox yet |
| 7 | Chop the World Tree | Build | 2 wk | HIGH | Proven verb + 100-player shared tree, reuses Plinko |
| 8 | Pass the Cursed Aura | Build | 2 wk | HIGH | Biggest RNG format made active/social |
| 9 | Slice the Sand Core | Build with changes | 2 wk | HIGH | Sand ASMR trend + shared-core tension |
| 10 | Never Walk Alone | Build with changes | 3 wk | MID | October horror + one-sentence rule |
| 11 | Break the Ball Pit | Build with changes | 4 wk | MID→HIGH | 2M-seller loop + co-op fusion, reuses ball physics |
| 12 | Feed a Creature | Build | 4 wk | HIGH | 99%-rated Steam fantasy, collection + co-op panic |
| 13 | Bid for Fighters | Build with changes | 3–4 wk | MID | Auto-battler wave + auction drama |
| 14 | Find the Key | Build with changes | 2.5 wk | MID | Hot cozy-search format + traitor twist |

**Build order:** Golden Ticket, then Freeze-Dry Your Candy, then Clip a Bag Charm. All three are HIGH money and share candy/reveal code. Chop the World Tree is the backup if a lane fills. Before starting each one, search Roblox and Rolimons for competitors; lanes fill in weeks.
