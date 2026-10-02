# Build an Egg! — Thumbnail & Icon Pack

Research basis (2 Oct 2026): current icons and thumbnails of Build the Pyramid!, Grow a Garden, Steal a Brainrot, Pet Simulator 99, 99 Nights in the Forest, Build A Boat For Treasure, Bubble Gum Simulator INFINITY, Muscle Legends and +1 Speed Keyboard Escape, plus the Roblox Creator Hub thumbnail and icon docs.

## What the front page is doing right now

1. **One giant hero object** fills 50–85% of the frame and shows the end goal at an absurd scale. Examples: the pyramid, the giant fruit, the giant pet.
2. **A smiling or smirking avatar** sits at the edge for scale and identity. It's often cropped and turned toward the hero object.
3. **The verb is shown, not written.** Characters carry things overhead, run or point, and an arrow shows the loop.
4. **Numbers replace sentences.** "+1", "+1M", "+9,973T", "$991,511/s", in white or rainbow-gradient text with a thick black outline.
5. **Rarity words read instantly.** "SECRET" in rainbow, "1 OF 1".
6. **Icons have 0–2 words.** Thumbnails carry at most a short update name, top-centre.
7. **Saturated, high-key palettes** built on one complementary pair, such as purple/yellow or sky blue/gold.
8. **Radial rays, starbursts, sparkles and auras** sit behind pets and power moments.
9. **The camera is at eye level or low**, so monuments look huge.
10. **A co-op cue:** several players working together or racing.
11. **Stylised in-engine renders**, with stronger lighting and outlines, plus 2D effects. The elements are still real game content.

## Rules (Roblox policy + play-through rate)

- Show only things that are in the game. If you show the Rainbow Egg hatching a Unicorn, the game must really do that.
- Don't use claims like "best game" or "free", fake UI, or real-life photos.
- Don't copy Build the Pyramid!'s purple-block-and-arrow layout. The "confusingly similar" rule applies.
- Keep text short, top-centre, and out of the bottom ~12%, because the player count overlays it.
- **Icon:** 512×512, no text (or at most 2 words). It must read at 150×150. Keep detail away from the rounded corners.
- **Thumbnails:** 1920×1080 (16:9), under 3 MB. Upload at least 3 so personalization can A/B them. Don't swap them for 7 days.

## Assets to capture and export

Export each as a **transparent PNG at least 2048px on the long side**. For each one:
- Studio: hide the GUI, set a plain background, take a screenshot and remove the background.
- Or, for meshes: export the model as FBX and render it in Blender with a transparent film.

These are the reference images you'll give the image generator, so it uses the game's real look.

| # | Asset | How to get it | Used in |
|---|---|---|---|
| 1 | **Finished giant egg**: the Common Egg fully built from the shell tiles (smooth, cream). Shoot from a low angle. | Studio: use Run mode, or set the progress to full in a test place, then screenshot the Site.Egg model | Thumb A, B, Icon |
| 2 | **Cracking egg**: the same egg mid-cutscene with glowing crack lines and light leaking out | Pause the hatch cutscene during the "CRACK!" shot and screenshot it | Thumb A, Icon |
| 3 | **Rainbow Egg and Golden Egg** recolours of the giant egg | Set ProjectsConfig Color and screenshot the egg | Thumb C, Icon option |
| 4 | **Hatchlings**: Rainbow Unicorn, Void Dragon, Golden Bunny, Gem Axolotl, plus the Common Duck | Spawn each hatchling (EggController) or pet model and take a front three-quarter shot of each | Thumb A, C |
| 5 | **Small pets at each rarity**: Duck (Common), Kitten (Rare), Fox (Epic), Owl (Legendary), Dragon or Unicorn (Mythic) | Pet models from the pet pack. Shoot them on their own. | Thumb C |
| 6 | **Cracked eggshells**: 3 shapes (bottom half, top cap, shallow bowl) in brown, tan and white | Blender: `assets/EggShells.fbx` (already set up) | All |
| 7 | **Avatar carrying a TALL backpack shell stack** (about 60–200 shells), front and three-quarter views | Studio: give your avatar a full carry, then screenshot it at eye level | Thumb B, Icon |
| 8 | **Avatar on the bench press**: arms up with the barbell, plus the treadmill run pose | Studio: stand on a Gym1 pad and screenshot it | Thumb C (optional) |
| 9 | **Spiral ramp section**: 3–4 steps with the white chevron arrows, plus the green PLACE zone | Studio screenshot of one ramp segment (not the whole map) | Thumb B |
| 10 | **Egg fragments**: the glowing coloured shards with trails | Studio: freeze the fragment shower and screenshot it | Thumb A, C |
| 11 | **Training bubbles**: blue "+", gold "★" and red "🔥" bubble UI | Screenshot the Bubbles UI while training | Thumb C |
| 12 | **Coin icon and HUD numbers**, as style reference only | Screenshot the HUD | Text style |
| 13 | **Game logo**: "BUILD AN EGG!" in a chunky white rounded font with a black outline, a cracked egg as the "O" in EGG, and a yellow-to-orange gradient on "EGG" | Make it in Photopea, Canva or Figma, or ask the image generator for it on its own | Thumbs |

## Icon prompt (512×512)

> Square Roblox game icon, stylized glossy 3D render in the style of top Roblox simulator icons. A GIANT cracked rainbow egg dominates the right two-thirds of the frame. It sits in a straw nest, with zig-zag crack lines glowing bright gold and warm light bursting out through the cracks. A smiling Roblox avatar (bacon hair, big toothy grin) leans in from the bottom-left, cropped at the chest. He wears a brown leather backpack with an absurdly tall, slightly wobbly stack of cracked brown and white eggshells piled into the sky, taller than the frame. A few loose cracked eggshell halves tumble through the air around them with white sparkle stars. The background is a bright sky-blue radial starburst with soft rays coming from behind the egg. The palette is high saturation: sky blue, sunny yellow and gold, with rainbow pastel on the egg. A clean thick dark outline separates the subjects from the background, with strong rim light. The camera is at eye level, slightly low, looking up at the egg so it feels huge. No text, no logos, no UI. The composition must read clearly as a tiny 150×150 thumbnail: big shapes and high contrast, with nothing important in the corners. Reference images: [egg render], [shell stack avatar], [cracked shells].

## Thumbnail A: "THE HATCH" (1920×1080)

> Wide 16:9 Roblox game thumbnail, stylized high-quality 3D render with cinematic lighting, matching the look of front-page Roblox simulators. The centre-right holds a COLOSSAL egg, as tall as a skyscraper, sitting in a giant straw nest. It is made of smooth cream eggshell tiles and is cracking open at the top. Jagged shell pieces explode outward, and blinding golden-white light and god rays burst from the crack. Bursting out of the top of the egg is a huge, adorable RAINBOW UNICORN pet with sparkly pastel rainbow fur, big shiny eyes and an open happy mouth, front paws raised, filling the upper-middle of the frame. Glowing coloured egg fragments (pink, purple, gold, cyan) fly outward with light trails. A wooden spiral staircase ramp with white chevron arrows winds around the egg. In the bottom-left foreground, three cheering Roblox avatars, cropped at the waist, look up in awe with their arms in the air. Each wears a backpack piled with a tall stack of cracked brown and white eggshells. Behind everything is a bright blue sky with a strong radial starburst of rays from the egg, confetti, and white four-point sparkles. The palette is saturated sky blue, gold, and rainbow pastels on the pet. The camera is low, looking up, to exaggerate the scale. Top-centre has a short chunky title, "HATCH IT!", in a bold rounded white font with a thick black outline and a subtle yellow-to-orange gradient. There is NO other text and nothing important in the bottom 12% of the frame. Only show things that exist in the game: the giant egg, the spiral ramp, the shell backpacks, the egg fragments and the unicorn hatchling. Reference images: [egg render], [cracking egg], [rainbow unicorn hatchling], [fragments], [ramp section], [shell stack avatar].

## Thumbnail B: "BUILD IT TOGETHER" (1920×1080)

> Wide 16:9 Roblox game thumbnail, stylized glossy 3D render, bright and energetic simulator style. The diagonal composition runs from the bottom-left to the top-right. A line of four Roblox avatars races up a wooden spiral staircase ramp that winds around a GIANT half-built egg. The egg is only built up to its middle: smooth cream eggshell tiles end in a glowing green "next ring" band where shells are being placed, and above it there is open sky where the rest of the egg will go. The lead avatar, closest to the camera and filling the bottom-left third, is a grinning muscular Roblox noob. They carry an absurdly tall backpack stack of cracked brown, tan and white eggshells that towers above their head and leans dramatically. Small cracked shells are flying off the stack toward the egg in arcs, each with a "+1" popup in white text with a black outline. The other avatars behind also carry tall shell stacks, showing co-op teamwork. On the ramp steps, white chevron arrows point up toward the top of the egg. Behind the ramp, a sunny sky-blue background with puffy clouds, green hills and soft light rays from the top-right. The palette is saturated: lime green, sky blue, warm cream and gold. The camera is low and three-quarter, so the egg looks enormous and the ramp climbs out of frame. Top-centre has the title "BUILD THE EGG!" in a chunky rounded white font with a thick black outline, with "EGG" in a yellow-to-orange gradient. No other text, no fake UI, and keep the bottom 12% clear. Only show real game elements: the shell backpack stacks, the spiral ramp with chevrons, the half-built egg with the glowing build band, and "+1" coin popups. Reference images: [shell stack avatar], [ramp section], [egg render], [cracked shells].

## Thumbnail C: "RAINBOW PETS" (1920×1080)

> Wide 16:9 Roblox game thumbnail, stylized glossy 3D render, collector/RNG simulator style. In the centre, a huge glowing RAINBOW EGG sits on a pedestal and is cracking open with prismatic light. Arranged in a fanned arc in front of it, from left to right by rarity, are pets: a grey Duck (Common), a blue Kitten (Rare), a purple Fox (Epic), a golden Owl (Legendary) and a pink Dragon (Mythic). They grow bigger and glow more toward the right. The Mythic dragon is the largest, with a magenta aura and lightning sparkles. Above each pet floats its rarity word in a matching colour (COMMON, RARE, EPIC, LEGENDARY, MYTHIC), in a chunky rounded font with a black outline; MYTHIC has a shimmering rainbow gradient. Five glowing egg fragments orbit the rainbow egg in a ring, connected by thin light streaks, to show the "5 fragments → 1 pet" trade-up. On the left edge, a smiling Roblox avatar holds up a glowing gold fragment, cropped at the shoulder. Behind everything is a deep purple-to-magenta radial burst with gold rays, confetti and sparkles, the purple/gold complementary pair used by top pet games. The camera is at eye level, straight on, as a hero shot. Title at the top-centre: "RAINBOW EGG" in a chunky rounded white font with a black outline and a rainbow gradient fill. Nothing else is written, and the bottom 12% stays clear. Only show pets and rarities that exist in the game. Reference images: [rainbow egg], [pet renders by rarity], [fragments], [avatar].

## Bonus thumbnail D (optional, gym hook)

> 16:9 Roblox thumbnail, glossy 3D render. A hyper-muscular grinning Roblox avatar on a bench press pushes a huge barbell up, with a yellow lightning aura. Training bubbles float around: blue "+" bubbles, a gold "★" bubble and a red "🔥" bubble, each with "+50" or "+15" popups in white with a black outline. The background is the gym platform with a treadmill and a dark-to-blue radial burst. Top-centre text: "TRAIN & HATCH". Bottom 12% clear.

## Upload plan

- **Icon:** the icon above.
- **Thumbnails:** A, B and C. Add D once the gym is a selling point.
- Let personalization run for 7+ days.
- Then swap out the worst-performing thumbnail by qPTR (qualified play-through rate). Never use a thumbnail that shows something the first 30 seconds of play doesn't deliver.
