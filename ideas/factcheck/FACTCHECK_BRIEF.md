# Fact-check brief (shared by all fact-checker agents) — 2026-09-27
You receive a batch of idea records (JSON lines) from /home/user/Work-Example-/ideas/shortlist.jsonl. For EACH idea, independently verify with WebSearch (Roblox APIs and Rolimons direct fetch are blocked; search snippets from roblox.com/games pages, rolimons.com/game pages, fandom wikis, code sites, Dexerto/GameRant/ProGameGuides surface visits/CCU):

1. ROBLOX OCCUPANCY (most important). 1–3 searches per idea with different phrasings, e.g. `roblox "<core noun> <verb>" game`, `site:roblox.com/games <keywords>`, `rolimons <keywords>`. Record every competitor found with visits/CCU and snippet date. Verdict: OPEN (nothing, or only dead micro-games) · CROWDED (several small/mid occupants or one live 1M–50M) · TAKEN (any occupant with 50M+ visits or 5K+ CCU history, or the exact mechanic already live and growing).
2. DEMAND. If the idea's evidence field is "none" or looks unverifiable, do 1 search to confirm or refute the underlying trend/game/show. Never accept a number you did not see.
3. MONETIZATION DENSITY: HIGH (collection/RNG/steal-protect/progression with consumable painkillers) · MID · LOW (pure party/round games with cosmetics only). Party games earn ~18% of collection games per player-hour (Creator Exchange, Aug 2025).
4. ADJUSTED SCORES O/D/P/A/B (1–5) after your checks — be harsh; the generators inflated scores. B = buildable by a solo scripter + builder in ≤1 month (no huge level design, no LLM APIs, no complex soft-body physics).
5. RED FLAGS: owned IP/likeness, gore/maturity, gambling look (casino, "plinko" is censored), freehand drawing/text moderation, doomscroll mechanics (banned Aug 25 2026), needs many players to work with no bot fallback.

## Output
Append one JSON object per idea (JSON Lines) to the output path you are given:
{"id":"...","title":"...","lane":"OPEN|CROWDED|TAKEN","competitors":"name – visits/CCU – source/date; ...","demand_check":"verified: ... | refuted: ... | unverified","money":"HIGH|MID|LOW","O":n,"D":n,"P":n,"A":n,"B":n,"red_flags":"...","verdict":"KEEP|PIVOT|KILL","why":"one sentence","pivot":"if PIVOT, the one change"}
Write incrementally (every ~5 ideas). Budget: ≤ 3 searches per idea; if search budget runs out, mark remaining lane "UNCHECKED" and say so. Never invent numbers.
Final reply ≤ 150 words: counts of KEEP/PIVOT/KILL and your 5 best KEEPs.
