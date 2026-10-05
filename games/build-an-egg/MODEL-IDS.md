# Build an Egg! - Creator Store model IDs

Researched 2026-10-01 via toolbox-service v2 search, v1 items/details, economy v2 asset details, catalog favorites count, and thumbnail grids / store pages.

How to read this:
- Every ID below is **free** and was checked with `economy.roblox.com/v2/assets/<id>/details`, which returned `IsPublicDomain=true`. That means it's a free, copyable model, so `game:GetObjects("rbxassetid://ID")` should work in Studio or a plugin.
- **Verified?** The toolbox API marks almost every creator `verified=true`, so in practice it only means "ID-verified account". It tells you nothing about quality. The one creator with a real badge from the economy API is "(badge)": Roblox, plus Astrra.
- **Votes** are up/total and are rounded by the API (e.g. 96/100). **Fav** is the catalog favorite count.
- **sc** is the script count and **mp** the MeshPart count, both from the API. mp0 usually means SpecialMesh/Union parts.
- Search quality on the store is poor. Most cute animals have few votes, so the visual judgement (from thumbnails) carries most of the weight.

## 1. Chick (baby chicken)
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 8780281108 | Cute chick | Calestelle | 20/20, fav 25 | 0 / 5 | Round pastel-yellow chibi chick with blush cheeks. Very cute, and its 5 MeshParts (body/feet/etc.) can be animated. |
| BACKUP | 12549817121 | Baby Chicken | Astrra (badge) | 0/0, fav 9 | 0 / 0 (mesh) | Bright yellow standing chick with big orange feet. Clean, smooth and cartoony. A single mesh. |
| alt | 8780301214 | Cute chick with top hat | Calestelle | 8/10 | 0 / 6 | Same chick as the primary, wearing a top hat. |

## 2. Owl (white/snowy if possible)
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 4882190031 | Ghost Simulator Owl | GhostSimulatorModels (official asset dump from the Ghost Simulator game) | n/a, fav 4 | **1 script** / 4 | Cute low-poly brown owl with big eyes and 4 parts. Strip the script, then recolor it white for a snowy owl. |
| BACKUP | 111693302 | EPIC OWL | happyclonetrooper | 0/0, fav 0 | 0 / 0 | **White snowy owl** with wings spread. Older (2013) mesh but decent, and already white. |
| alt | 900970234 | snowy owl | cryo_k | 9/10, fav 8 | 0 / 0 | Realistic-ish white owl in flight pose, 14k tris. |
| alt | 135771743712685 | Owl | GlowinqxSabb | 0/0 | 0 / 9 | Chibi brown owl with 9 parts. Adopt-Me-like style. |
No strong, well-voted cute snowy owl exists. Weak category.

## 3. Goose / duck (to recolor gold)
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 13605683583 | Goose Model | dartiros | 0/0, fav 2 | 0 / 3 | Clean white standing goose with orange beak and feet. Simple and smooth, about 1.3k tris, 3 MeshParts. Easy to recolor gold. |
| BACKUP | 10766611158 | goose | Romapro415 | 30/30, fav 8 | 0 / 4 | White goose mid-honk. Good quality, but it looks like the Untitled Goose Game goose (same mesh as "Untitled Goose" 9047436982), so there's mild IP risk. |
| alt | 4685210528 | Low poly Duck | Baconly Studios | 0/0, fav 10 | 0 / 11 | Faceted low-poly yellow duckling with 11 parts. |
| alt | 5633203482 | Duck | Bowtie Games | 47/50, fav 18 | 0 / 10 | Realistic mallard with 10 MeshParts. |

## 4. Dragon (cute/low-poly)
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 12859249654 | Green Draco | Brunelo9 | 0/0, fav 1 | **1 script** / 34 | Chubby green baby dragon with cream belly and small wings. Cute, with 34 parts that are good for animating. Somewhat Adopt-Me-pet styled, so strip the script. |
| BACKUP | 91390031578007 | dragon pet | Nightmare686868 | 0/0, fav 0 | 0 / 1 | Big-eyed pastel-green chibi dragon. Very cute, but it's a single 20k-tri mesh (likely AI-generated). |
| alt | 2677039001 | dragon | trey0383 | 0/0 | 0 / 1 | Green cartoon dragon with purple wings. |
| alt | 17597495724 | AN_Dragon | LordCat76 | 0/0 | 0 / ? | Golden spiky baby dragon. |

## 5. Phoenix / colorful bird
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 338568374 | Phoenix Model | Roozan | 0/0, fav 1 | 0 / 0 | Classic orange/red/gold phoenix with wings spread. Stylized and about 2.3k tris. Has no scripts and is a clean copy of the popular Fire Bird mesh below. |
| BACKUP | 11900527634 | SillyBurd | piripiripete | 0/0, fav 0 | 0 / 34 | Colorful low-poly parrot or bird-of-paradise: red head, blue/green body, yellow tail. Its 34 MeshParts make it ideal for animating. |
| alt | 130572527 | Fire Bird (phoenix) | Fire_Gamer | 80/90, fav 43 | **3 scripts** / 0 | Same phoenix mesh with scripts attached. Best-voted, but delete the scripts. |

## 6. Chicken / hen (ambient)
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 4376443752 | Chicken | BlueNebula10 | 96/100, fav 131 | 0 / 1 | Brown hen, semi-realistic but soft and textured. The most popular chicken on the store, though less "cartoon" than the rest of the set. |
| BACKUP | 930957937 | Hen | SmallFally | 10/10, fav 5 | 0 / 0 | White hen with red comb, clean and stylized, 26k tris. |
| alt | 17183525920 | Low Poly Chicken | Xp0nda | 0/0, fav 2 | 0 / 1 | Blocky Crossy-Road-style voxel chicken. |

## 7. Egg (to recolor)
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 5168800671 | Egg mesh | francherre | 192/200, fav 59 | 0 / 1 | Smooth, clean egg MeshPart (500 tris). Perfect base to scale and recolor. |
| BACKUP | 14123433731 | Low Poly Egg | Blemov | 0/0, fav 0 | 0 / 1 | Faceted low-poly egg (112 tris), the flat-shaded stylized look. |
| alt | 11378659186 | Low Poly Eggs | ItsPlasmaRBLX2 | 0/0 | 0 / 3 | 3 small faceted eggs. |

## 8. Bird nest / straw nest
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 444386649 | Bird Nest | Mistertitanic44 | 47/50, fav 26 | 0 / 7 | Twiggy dark-brown nest with 7 MeshParts. Scale it up for the giant-egg nest. |
| BACKUP | 2657877247 | Bird Nest (?) | r_0773n | 18/20, fav 15 | 0 / 0 | Flatter golden-straw ring nest, a warmer color that suits sunset. |

## 9. Low-poly nature pack
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 6933438443 | Synty Nature Pack | **Roblox (official, licensed Synty POLYGON)** | 768/800, fav 829 | 0 / 200 | Official low-poly pack of trees, plants, bushes, flowers, logs, boulders, rocks and outdoor props. Licensed for any Roblox game. |
| BACKUP | 9682467046 | Low Poly Nature Pack | Proudism | 39/40, fav 28 | 0 / 47 | Brighter cartoon low-poly trees, rocks and flowers. Sunnier palette. |
| alt | 79689531752352 | Yasu's Stylized Tree Pack | mvyasu | 297/300, fav 133 | 0 / 61 | Stylized trees. |
| alt | 4893246329 | Low Poly Tree | Abishpc | 930/1000, fav 214 | 0 / 3 | Classic single low-poly tree. |
| alt | 14603612772 | Low Poly Rocks | neervu | 66/70, fav 25 | 0 / 1 | Grey faceted rocks. |

## 10. Treadmill
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 135041830463035 | Treadmills by System | System_xxp | 40+ votes, 88%, fav 1 | 0 / 0 | Five candy-colored simulator-style treadmills (blue/orange/red/green/pink) on a base. Cute and fits the simulator genre. Recent (Jul 2026). |
| BACKUP | 109866492613700 | Treadmill | French World Studio | 0/0, fav 0 | 0 / 4 | Chunky wooden/brown simulator treadmill with 4 parts. |
| alt | 916218035 | Treadmill | Eppobot | 44/50 | 1 script / 0 | Realistic black treadmill. |

## 11. Weight bench / dumbbell rack
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 15275879602 | [GYM] Dumbbells rack | palomies112moii | 9/10, fav 4 | 0 / 7 | 2-tier rack of black dumbbells, realistic, about 31k tris. |
| BACKUP | 2151381239 | Gym Weight Lifter Bench | mikeyguzboy2 | 7/10, fav 2 | 0 / 0 | Black bench with a barbell. Simple. |
There's no good cute or low-poly gym set. Consider recoloring these, or build primitives.

## 12. Wooden scaffolding / planks / ramp
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 12947205672 | CONSTRUCTION MODEL | infrain34 | 0/0, fav 7 | 0 / 0 | Light-wood scaffolding tower with ladders and platforms. Fits "building the egg". |
| BACKUP | 2915486138 | Low Poly Wood Pack | BL00MIE | 19/20, fav 31 | 0 / 38 | Pack of low-poly logs, planks and wood pieces. About 55k tris total. |
| alt | 4113279509 | Scaffolding (Mesh) | bearduckmonkey | 9/10, fav 9 | 0 / 3 | Leaning metal/wood scaffold. |

## 13. Wooden sign / signpost
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 12712225222 | Low poly sign Text | OFF6_6 | 31/40, fav 9 | 0 / 1 | Low-poly dark-wood board on a post (92 tris). Add a SurfaceGui for text. |
| BACKUP | 1014941563 | Wooden Arrow Sign | citrusfruitt | 27/30, fav 4 | 0 / 0 | Wooden arrow-shaped direction sign. |
| alt | 11935183890 | Wooden Sign Post | ImAvafe | 0/0, fav 3 | 0 / 3 | Multi-arrow signpost. |

## 14. Gift box / present
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 190430153 | Present | DavidX0408 | 0/0, fav 1 | 0 / 0 | Tall green box with gold ribbon and bow. Smooth and polished. |
| BACKUP | 6135293415 | Christmas Present! | gamerchrisOMGreal | 9/10, fav 5 | 0 / 0 | White box with red ribbon and bow (420 tris). Easy to recolor. |

## 15. Treasure chest / gold coin pile
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 1880922775 | Treasure Chest | StarModelX | 10/10, fav 33 | 0 / 6 | Open wooden chest with gold trim, overflowing with gold and gems. 6 parts, so the lid can open. |
| BACKUP | 123781273 | Chained treasure chest | Shikoi_Kurogami | 93/100, fav 21 | 0 / 0 | Closed wooden-and-gold chest with chain and lock. |
| coin pile | 4725406385 | Low-Poly Pile of Gold (Medium) | Exp_p | 9/10, fav 5 | 0 / 27 | Stack of low-poly gold coins with 27 parts. |
| coin alt | 3145118207 | Pile Of Gold | TheAbsoluteZerro | 10/10, fav 4 | 0 / 0 | Gold bars pile. |
| alt | 13902910537 | Low poly chest | bytvix | 10/10, fav 7 | 0 / 19 | Purple/pink glowing simulator-style chest. |

## 16. Throne (optional)
| role | id | title | creator | votes / fav | sc / mp | visual |
|---|---|---|---|---|---|---|
| PRIMARY | 2293753659 | Royal Throne | bip_q | 8/10, fav 5 | 0 / 0 | Gold throne with red cushions. Low-poly (440 tris) and cartoony. |
| BACKUP | 4830795885 | Throne | BradlyManzotti | 52/60, fav 9 | 0 / 6 | Ornate gold/brown throne with crown top. Heavy at about 82k tris. |

## Notes / cautions
- **Scripts:** Ghost Simulator Owl (4882190031) has 1, Green Draco (12859249654) has 1, and Fire Bird (130572527) has 3. Delete every Script/LocalScript after GetObjects, and sanity-check all models for stray scripts.
- **Synty packs:** Roblox also publishes other official, licensed Synty packs that may hold chests, thrones and props in the same art style as the Nature Pack. Contents not inspected. Examples are "Synty Dungeon Pack: Weapons & Props" 6933790012 and "Cave & Castle Interiors" 6934021345.
- **Removed listings:** Some search results return 404 on the store (e.g. 15308754803 "Snow Owl cute", 4655803920 "Cute LowPoly Chicken"), so don't use those.
- **Avoided:** Pet Simulator, Adopt Me, Chicken Gun, Minecraft and Duolingo rips, plus a "Pet Pack" (4537799968, 900 votes) whose contents couldn't be verified.

## Higgsfield-generated assets (2026-10-05)
Generated through the official Higgsfield MCP (mcp.higgsfield.ai). The Blender bridge connector refuses generation on trial accounts with `{"detail":{"error_type":"only_mcp_usage_on_trial_is_available"}}`. Source files are in `assets/higgsfield`.

| asset | Higgsfield job | model | credits | Roblox image id | used by |
|---|---|---|---|---|---|
| Golden goose reference | ca982692-7fdb-453c-b311-d22c9711eb39 | gpt_image_2_5 (high, transparent) | 1.5 | - | image-to-3D source |
| Golden goose mesh (11.7k tris, rigged in Blender) | 8e815db0-e842-4d4a-9930-09029d4b1ca8 | tripo_h3_1_image_to_3d | 12 | 132008718532908 (texture) | MapKit8 `World_Goose_Bird` |
| Water foam sprite | 075d4910-2504-46d2-9d03-f5bc77e63f73 | gpt_image_2_5 | 1.5 | 122701034300557 | pool/pond foam decals |
| Water splash sprite | de6a6b5a-b72c-49ed-998a-6d3da071a235 | gpt_image_2_5 | 1.5 | 138479375877399 | waterfall splash emitter |
| Water ripple sprite | 2449506c-9dc9-4bb6-b043-afb85342d596 | gpt_image_2_5 | 1.5 | 92515165368995 | pool/pond ripple decals |
| Water droplets sprite | fe7e6516-243f-4cb2-9f8d-9de2db90592d | gpt_image_2_5 | 1.5 | 93083921246854 | waterfall + pond inlet droplets |
| Water mist sprite | f0586c45-6eef-4467-b300-00b0ce6d305f | gpt_image_2_5 | 1.5 | 77178893644467 | waterfall mist emitter |

Rig bones on the goose: Root, LegL, LegR, Body, Neck, Head, WingL, WingR, Tail. The client animates them procedurally (`Effects.GooseRig`).
