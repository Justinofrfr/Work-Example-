# Build an Egg! - SFX / Music asset IDs

Source: Roblox Creator Store (toolbox-service API), 2026-10-01. All 31 IDs were checked through
`toolbox-service/v1/items/details`: each exists, is an Audio asset (typeId 3), and is listed free (`isFree: true`).
Every creator is a Roblox-licensed partner or Roblox itself: ProSoundEffects, APMOfficial (APM Music), or Roblox.

Durations: PSE values are exact, taken from the asset description. A "~" means the API only gives a rounded integer
(Roblox and APM assets), and "~0" means under 0.5 s.

| key | id | title | creator | duration (s) |
|---|---|---|---|---|
| Pickup | 9113923498 | Coral On Granite 19 (SFX) | ProSoundEffects | 0.5 |
| Place | 9118598720 | Rock Hit Dirt Impact 19 (SFX) | ProSoundEffects | 0.3 |
| Coin | 9113848418 | Coin Bounce 2 (SFX) | ProSoundEffects | 0.8 |
| Full | 9119349447 | Soccer Header 1 (SFX) | ProSoundEffects | 0.2 |
| RingComplete | 9125805579 | Rising Whoosh Hissing Build Up Ascending Swo (SFX) | ProSoundEffects | 1.1 |
| Milestone | 1842335078 | Cartoon Fanfare (c) | APMOfficial | ~2 |
| Countdown | 9114071134 | Dial Switch Twisting Sharp Ticking 79 (SFX) | ProSoundEffects | 0.4 |
| LastPiece | 9118612665 | Rock Impact 7 (SFX) | ProSoundEffects | 2.1 |
| EggGlow | 9119816546 | Synth Power Up Multi Tone Wind Ups Rise 2 (SFX) | ProSoundEffects | 2.7 |
| EggCrack | 9113958649 | Crack Egg Crunchy 2 (SFX) | ProSoundEffects | 1.6 |
| EggBurst | 9116385087 | Magic Burst 5 (SFX) | ProSoundEffects | 2.3 |
| Fanfare | 1844584807 | Glamour Fanfare 4 | APMOfficial | ~4 |
| Hatch | 9126072453 | Synth Sparkle Tone High Pitch Bell Tone Burs (SFX) | ProSoundEffects | 1.4 |
| NextEgg | 1842335060 | Cartoon Fanfare (a) | APMOfficial | ~2 |
| TrainStart | 15675024286 | Roblox_UI_Whoosh_01 | Roblox | ~1 |
| TrainLoop | 9125674129 | Metallic Glow Constant Deep Ticking Bassy Hu (SFX) | ProSoundEffects | 13.5 |
| StatMilestone | 9126076030 | Synth Sparkle Tone High Pitch Tone Burst Pin (SFX) | ProSoundEffects | 0.9 |
| GymUnlocked | 1844692556 | Game Show | APMOfficial | ~2 |
| Locked | 9114142431 | Door Latch Open And Close 2 (SFX) | ProSoundEffects | 0.8 |
| RankUp | 15675043410 | Roblox_UI_Tonal_Stinger | Roblox | ~1 |
| Purchase | 17208380755 | Roblox GUI - Purchase | Roblox | ~1 |
| Error | 17208353912 | Roblox GUI - Negative | Roblox | ~0 |
| RobuxSuccess | 99366249808641 | TutorialPurchase_01 | Roblox | ~1 |
| ServerPack | 9045751375 | 1812 Overture (sting b) | APMOfficial | ~4 |
| Reward | 9116394545 | Magic Glows Soft Clusters Of Chiming Hits 1 (SFX) | ProSoundEffects | 2.1 |
| Click | 15675032796 | Roblox_UI_Small_Click | Roblox | ~0 |
| Open | 17208204604 | Roblox GUI - Bubble | Roblox | ~1 |
| Close | 10128766965 | RBLX UI Swipe (SFX) | Roblox | ~1 |
| Ambience | 9116971178 | Morning Forest Birds 3 (SFX) | ProSoundEffects | 36.0 |
| Music | 9047876673 | Happy Adventure (Yannis Dumoutiers; ukulele/mandolin/pizzicato) | APMOfficial | ~71 |
| MusicFinal | 77999551719434 | Fun Of The Chase (Patrick Fletcher, "Playful Happy Days") | APMOfficial | ~158 |

Notes:
- The search turned up no single "horn + whoosh" asset. NextEgg (Cartoon Fanfare (a)) and ServerPack (1812 Overture sting)
  are brass stings only. To add the whoosh, layer TrainStart or RingComplete under them.
- TrainLoop and Ambience are steady recordings that were not edited as loops, so a seam may be audible. Set
  Looped = true and test them.
- Coin (0.8 s) is a single quarter clink. If you want something slightly longer and more "game" sounding, try Roblox
  `CoinTransfer_01` = 127645268874265 (~2 s).
- Other options found during the search: Pickup -> 9118608006 Rock Hits Rock On Rock 7 (0.7 s); LastPiece -> 9118617342
  Rock Impact Large Hit Scrape 1 (0.9 s); EggGlow -> 9117297453 Phasey Synth Power Up Rise 2 (3.2 s);
  Fanfare -> 1845411858 Top Prize (APM, ~5 s); MusicFinal -> 1845693355 Crazy Hurry (APM, ~64 s);
  Close -> 17208405682 Roblox GUI - Swipe; Purchase -> 10066947742 RBLX UI Purchase (SFX).

```lua
Pickup = "rbxassetid://9113923498",
Place = "rbxassetid://9118598720",
Coin = "rbxassetid://9113848418",
Full = "rbxassetid://9119349447",
RingComplete = "rbxassetid://9125805579",
Milestone = "rbxassetid://1842335078",
Countdown = "rbxassetid://9114071134",
LastPiece = "rbxassetid://9118612665",
EggGlow = "rbxassetid://9119816546",
EggCrack = "rbxassetid://9113958649",
EggBurst = "rbxassetid://9116385087",
Fanfare = "rbxassetid://1844584807",
Hatch = "rbxassetid://9126072453",
NextEgg = "rbxassetid://1842335060",
TrainStart = "rbxassetid://15675024286",
TrainLoop = "rbxassetid://9125674129",
StatMilestone = "rbxassetid://9126076030",
GymUnlocked = "rbxassetid://1844692556",
Locked = "rbxassetid://9114142431",
RankUp = "rbxassetid://15675043410",
Purchase = "rbxassetid://17208380755",
Error = "rbxassetid://17208353912",
RobuxSuccess = "rbxassetid://99366249808641",
ServerPack = "rbxassetid://9045751375",
Reward = "rbxassetid://9116394545",
Click = "rbxassetid://15675032796",
Open = "rbxassetid://17208204604",
Close = "rbxassetid://10128766965",
Ambience = "rbxassetid://9116971178",
Music = "rbxassetid://9047876673",
MusicFinal = "rbxassetid://77999551719434",
```

## Non-Roblox replacements

These replace the 8 slots that used Roblox-made sounds. Every ID (primary and backup) was checked through
`toolbox-service/v1/items/details` on 2026-10-01: each exists, is Audio (typeId 3), is free (`isFree: true`), is
public (visibilityStatus 0), and is not by the Roblox account. Durations come from decoding the delivered audio file.
"Audible" is how long the sound stays above -40 dB of its peak; the rest is silence or tail padding in the file.
Porevoz Games' "Smaltra UI" sounds are one consistent UI pack, so Click, Open, Close, Error, Purchase and RobuxSuccess
come from it on purpose.

| key | id | title | creator | duration | backup id |
|---|---|---|---|---|---|
| TrainStart | 9120704978 | Whooshes Fast Wipes Quick Airy Slices 3 (SFX) | ProSoundEffects | 0.41 s | 128772614880834 (sfx_whoosh_hi_short01, Jplay5x5, 0.24 s) |
| RankUp | 112485797063762 | UI - Level Up | SodaBreadle | 1.54 s (audible ~1.0 s) | 134821092416328 (Rewards Level Up - Next Tier, Los Calientes Studio, 2.48 s, audible ~1.4 s) |
| Purchase | 99446219356738 | Smaltra UI purchase | Porevoz Games | 0.84 s | 124957448085846 (Smaltra UI shop, Porevoz Games, 1.03 s) |
| Error | 79618522216171 | Smaltra UI error | Porevoz Games | 0.48 s | 87047730068459 (Access Denied, SodaBreadle, 0.74 s, audible ~0.33 s) |
| RobuxSuccess | 135480104279575 | Smaltra UI reward | Porevoz Games | 1.99 s (audible ~1.2 s) | 122399158411452 (PUZZLE_Success_Bright_Voice_Two_Note_Fast_Delay, CoreCraft Studio, 0.83 s) |
| Click | 92828025705705 | Smaltra UI click | Porevoz Games | 0.48 s file (audible ~0.07 s) | 92647604633081 (UI - Light Click 2, SodaBreadle, 0.22 s) |
| Open | 125936704752259 | Smaltra UI open | Porevoz Games | 0.48 s file (audible ~0.15 s) | 70452176150315 (UI - Open Click, SodaBreadle, 0.25 s) |
| Close | 103749529388434 | Smaltra UI close | Porevoz Games | 0.48 s file (audible ~0.21 s) | 9120704940 (Whooshes Fast Wipes Quick Airy Slices 1 (SFX), ProSoundEffects, 0.35 s swipe) |

Notes:
- The picks were judged from titles, durations and levels only. Nobody has listened to them yet, so test them in Studio.
- Levels vary. The Smaltra purchase, reward and click sounds peak at about 0 dBFS. SodaBreadle's Level Up (-16 dB) and
  Smaltra UI error (-15 dB) are quieter, so raise their Volume if needed.
- PSE descriptions list longer durations than the delivered files. For example, 9120708588 says 0.7 s in its
  description but decodes to 0.43 s. The table uses the decoded value.
- Community "cha ching" and "level up" uploads were skipped when the title pointed to a sound ripped from another game
  (Omori, Mario, Celeste, Apple Pay and similar).

```lua
TrainStart = "rbxassetid://9120704978",
RankUp = "rbxassetid://112485797063762",
Purchase = "rbxassetid://99446219356738",
Error = "rbxassetid://79618522216171",
RobuxSuccess = "rbxassetid://135480104279575",
Click = "rbxassetid://92828025705705",
Open = "rbxassetid://125936704752259",
Close = "rbxassetid://103749529388434",
```
