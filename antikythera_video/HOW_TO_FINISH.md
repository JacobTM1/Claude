# How to finish your 5-minute video — "The 2,000-Year-Old Computer"

## What's already done ✅
All visuals are generated and saved in **your Higgsfield account** (Generations tab):
- **24 cinematic stills**, 16:9, ~1080p (model: nano-banana, 2 credits each)
- **3 Seedance 2.0 hero clips**, true **1920×1080** (5s each, 45 credits each)
- Full **narration script** (`script_and_shotlist.md`) — ~720 words, ~5 min read
- An automated **assembler** (`build_video.sh`) that stitches it all into one 1080p MP4

Credits spent so far: ~183 of your 262.5 (48 images + 135 video). Narration audio not yet generated (see below).

## Why I couldn't export the final MP4 from inside the session
Two environment limits (both are policy — I did not bypass them):
1. **Egress policy** blocked the Higgsfield asset CDN (`d8j0ntlcm91z4.cloudfront.net`), so I couldn't pull the files into the build container.
2. **The TTS/voice tool was permission-gated** and didn't get approved, so the AI voiceover didn't render.

Your own browser is NOT behind that policy — so you can open/download every asset below directly.

---

## The 2 things still needed
1. **Voiceover (narration.mp3)** — feed the script in `script_and_shotlist.md` to any TTS (ElevenLabs deep documentary voice like "Adam"/"George", or Higgsfield's voice tool once you approve it). Save as `audio/narration.mp3`.
2. **Music bed (music.mp3)** — any cinematic/ambient track (YouTube Audio Library, Epidemic Sound). Save as `audio/music.mp3`.

---

## Fastest finish — automated (≈2 min on your machine)
1. Install ffmpeg (`brew install ffmpeg` / `choco install ffmpeg`).
2. Make this folder structure and download the assets (links at bottom):
   ```
   project/
     img/01.png ... img/24.png       # the 24 stills, in order
     vid/h1.mp4  vid/h3.mp4  vid/h15.mp4   # the 3 hero clips
     audio/narration.mp3
     audio/music.mp3
     build_video.sh
   ```
3. Run: `bash build_video.sh`
4. Output: `out/antikythera_5min_1080p.mp4` — upload to YouTube.

The script applies slow Ken Burns push/pull on every still, drops the 3 Seedance clips into scenes 1, 3 and 15, mixes narration over a ducked music bed, and trims to the narration length.

## Alternative — CapCut / Premiere (manual, drag-and-drop)
Use the scene order + durations below. Put each still on the timeline for its listed seconds with a slow zoom; replace scenes 1/3/15 with the hero clips. Lay the narration across the top, music underneath at ~15% volume.

| # | Scene | Sec | Asset |
|---|-------|-----|-------|
|1|Gear emerging from water|26|**HERO h1** + still 01|
|2|Title / shipwreck wide|5|still 02|
|3|Diver descending|14|**HERO h3** + still 03|
|4|"Bodies" on seabed|16|still 04|
|5|Bronze statue close|13|still 05|
|6|Cargo ship at dusk|13|still 06|
|7|Divers lowered (sepia)|16|still 07|
|8|Lump in museum drawer|17|still 08|
|9|Gear in the corrosion|15|still 09|
|10|Bronze gear vs clock|14|still 10|
|11|Scholar with lens|12|still 11|
|12|8-ton X-ray scanner|12|still 12|
|13|X-ray reveals gears|14|still 13|
|14|Reconstructed device|9|still 14|
|15|Gears turning (crank)|8|**HERO h15** + still 15|
|16|Front dial sun/moon|13|still 16|
|17|Pin-and-slot moon orbit|16|still 17|
|18|Eclipse prediction|14|still 18|
|19|Olympic games|9|still 19|
|20|Master craftsman|9|still 20|
|21|Gear into darkness|13|still 21|
|22|Fading craftsmen|15|still 22|
|23|Dark ocean / undiscovered|16|still 23|
|24|Real fragment in case (outro)|19|still 24|

---

## Asset download links
**Hero clips (1920×1080):**
- h1 (gear from water): https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010637_bd973b70-645f-490d-9904-4840972d82d5.mp4
- h15 (gears turning): https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010642_80d900d6-f929-49f6-a878-2e399947bee0.mp4
- h3 (diver descending): https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010640_33b3ca6e-e7a7-49ac-a235-6c147acfc022.mp4

**Stills 01–24:**
01 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010258_36690113-e245-4cdf-93cf-f4f1314c117b.png
02 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010307_66ca0bac-a366-4f04-b5be-377e5be48c66.png
03 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010308_f7711ec3-d004-4288-84e3-1054a734a0da.png
04 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010310_d80e7cc5-e544-4d96-bfe5-c351ec0ead06.png
05 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010312_c9365056-406f-45f5-8f57-b8816d63c966.png
06 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010314_16a23368-bf46-4fca-a1d1-44db7429299d.png
07 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010316_b06f59fa-2965-4393-bc5f-b341c31860da.png
08 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010318_a29369f8-1073-4081-932c-e9df73e7b526.png
09 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010319_f4001a4f-ab7c-413c-b242-19adc09591f4.png
10 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010326_ac78edfb-71be-47db-9c3a-665b51cdf438.png
11 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010328_0549ebaf-ba1f-4227-9787-446fe2b23d7b.png
12 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010329_33dd5c1f-572e-42b6-add3-afcc4982e167.png
13 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010333_e0ffcc38-e063-41c8-82b1-9b2c3fdcd211.png
14 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010334_0e11208b-b21b-4472-ac2e-3989ce017da6.png
15 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010335_fba2e801-679d-4b87-af0d-8b3f4268456b.png
16 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010336_3325ccf9-d5bb-41ca-953f-4f68af9fc231.png
17 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010337_aa793db0-723c-41b0-88be-80525f57a7f1.png
18 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010344_c69c3714-7f9a-431d-a123-d5d385b53dd4.png
19 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010345_7e285656-72e5-436b-a797-f5cfd84fc640.png
20 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010347_cb06c8e0-2e86-4eb9-8e97-4a78da9fb22f.png
21 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010349_c054784b-c7be-4b83-b56e-21aef926d7ab.png
22 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010351_86f12b24-8469-4440-a930-20faa7dd4e2f.png
23 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010353_088adc0a-cf6c-4fcd-afeb-1ffe3772cbaf.png
24 https://d8j0ntlcm91z4.cloudfront.net/user_3F3LKgMotkcdUcMOXYBCks3Ny0y/hf_20260625_010353_20f16fb4-9c9b-4fd7-bb06-4052cb1cf839.png

## YouTube metadata
- **Title:** The 2,000-Year-Old Computer They Couldn't Explain
- **Thumbnail:** still 01 or 15 (the glowing bronze gear) + bold text "2,000 YEARS AHEAD OF ITS TIME"
- **Tags:** antikythera mechanism, ancient technology, lost history, ancient greece, history documentary
