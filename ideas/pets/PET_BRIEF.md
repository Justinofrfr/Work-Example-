# Pet-idea generator brief — 2026-09-30
Goal: original Roblox PET / CREATURE game ideas a solo scripter + builder can ship as an MVP in ≤1 month, free-to-play, Robux via consumables. Pets are hot on Roblox right now (Steal An Egg ~3.1B visits in 2 months; Catch And Tame 430M visits; Adopt Me, Build a Zoo, Pets Universe, Ride a Pet all shipped Sept updates). The lane is also the MOST crowded on the platform, so every idea needs a MECHANICAL twist (what the pet DOES, how you GET it, or what the social friction is), not a new skin.

## Output (JSON Lines, exactly these keys)
{"id":"<prefix>-001","title":"Verb a Noun title","source":"trend/game/behaviour it comes from","loop":"what the player does every minute","twist":"the one mechanical thing no existing pet game does","pet_role":"what pets actually do in the loop","levers":["rng","social","rebirth","showoff","coop","asmr","pvp","trend"],"money":"2-3 painkiller consumables + where they fire","evidence":"demand evidence WITH source+date, or \"none\"","roblox_occupancy":"known nearby Roblox games, or \"unchecked\"","O":1-5,"D":1-5,"P":1-5,"A":1-5,"B":1-5}
O original at scale · D proven demand · P psychology (≥2 levers) · A algorithm fit (30s promise, daily return, co-play) · B buildable ≤1 month. Be harsh. Never invent numbers.

## TAKEN — do not pitch these loops (or only with a twist that changes the core verb)
Hatch eggs → equip pets → they multiply your clicks (Pet Simulator 99, Pets Universe, hundreds of clones) · Steal a X / Steal An Egg / Swing For Eggs · Adopt-and-roleplay pets (Adopt Me, Ride a Pet) · Catch/lasso animals → breed → mutations → sell (Catch And Tame 430M) · Merge pets (Merge Pets!, Pet Merge Simulator!, Merge Your Pets, +1 Pet Merge, Merge The Kittens 11M, Merge Vs Mobs 14M) · Zoo builder (Build a Zoo 518M) · Beekeeping (Bee Swarm) · Fish collection (Fish It, Fisch) · Grow-a-X with pets (Grow a Garden) · Roll-to-fight auto-battlers (Ball VS Ball, Grow a Chicken Fighter, Battle Pet) · Dig with pets (Dig It, Dig for Pets) · Bird RP (Feather Family, BIRD) · Dog/cat life RP (Warrior Cats, dog simulators) · Pet Store / Pet Shop tycoons · Anime-summon TD (Anime Vanguards) · Squishy / brainrot pets · Aquarium tycoons (verify) · Sniff/dig treasure dogs · Doomscroll or watch-reward mechanics (banned Aug 25 2026).
Also avoid ideas already in /home/user/Work-Example-/ideas/all-ideas-ranked.csv (grep the title first).

## What tends to work on Roblox with pets
Pets with a VISIBLE job (they act, not just multiply) · pets that create SOCIAL FRICTION (guard, steal, judge, race) · pets that are the SHOWOFF asset (rare looks, trading) · pet ownership that survives sessions (offline behaviour = D1 return) · genetics/traits that are readable by a 9-year-old · server-wide pet events (migrations, shows, races).

## Rules
- 8–15 WebSearches first: pet trends 2025–2026 (real pets on TikTok, viral animals, toys like Bitzee/Furby/Tamagotchi revival, pet-tech, pet shows), then Roblox occupancy for your best 10 ideas (query `roblox "<noun> <verb>" game` and read the snippet; record visits/CCU if shown).
- Write at least 60 distinct ideas. Append in batches of ~20.
- Final reply ≤150 words: count, file path, top 8 ids with one line each.
