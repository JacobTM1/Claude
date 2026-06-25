#!/usr/bin/env bash
# ============================================================
# Antikythera — "The 2,000-Year-Old Computer" 5-min assembler
# ============================================================
# Builds a 1080p cinematic faceless-history video from:
#   img/01.png .. img/24.png   (24 stills, 16:9)   <- download from Higgsfield
#   vid/h1.mp4 vid/h3.mp4 vid/h15.mp4  (3 Seedance hero clips)
#   audio/narration.mp3        (voiceover)
#   audio/music.mp3            (background bed; any cinematic/ambient track)
#
# Requires ffmpeg. Run:  bash build_video.sh
# Output: out/antikythera_5min_1080p.mp4
# ------------------------------------------------------------
set -euo pipefail
mkdir -p seg out
FPS=30
RES="1920x1080"

# Per-scene on-screen duration in seconds (roughly tracks narration beats).
# Scenes 1, 3, 15 are HERO scenes: the Seedance clip (5s) plays first,
# then the matching still continues for the remainder.
DUR=(26 5 14 16 13 13 16 17 15 14 12 12 14 9 8 13 16 14 9 9 13 15 16 19)
HERO=(1 3 15)   # 1-indexed scene numbers backed by a video clip

is_hero () { for h in "${HERO[@]}"; do [ "$1" -eq "$h" ] && return 0; done; return 1; }

# --- Ken Burns clip from a still ---
kenburns () { # $1=img  $2=out  $3=dur  $4=direction(in/out)
  local d=$3 frames=$(( $3 * FPS ))
  if [ "$4" = "out" ]; then
    local z="if(eq(on,1),1.15,zoom-0.00045)"
  else
    local z="min(zoom+0.00045,1.15)"
  fi
  ffmpeg -y -loop 1 -i "$1" -t "$d" -r $FPS -filter_complex \
    "scale=2560:-1,crop=2400:1350,zoompan=z='${z}':d=${frames}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${RES}:fps=${FPS},format=yuv420p" \
    -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$2" -loglevel error
}

# --- normalize a hero clip to exactly 1080p/FPS ---
normhero () { # $1=in $2=out
  ffmpeg -y -i "$1" -r $FPS -vf "scale=${RES}:force_original_aspect_ratio=increase,crop=${RES},format=yuv420p" \
    -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$2" -loglevel error
}

echo ">> Building per-scene segments..."
LIST=seg/list.txt; : > "$LIST"
for i in $(seq 1 24); do
  n=$(printf "%02d" "$i"); d=${DUR[$((i-1))]}
  dir=$([ $((i%2)) -eq 0 ] && echo out || echo in)   # alternate zoom direction
  if is_hero "$i"; then
    normhero "vid/h${i}.mp4" "seg/${n}a.mp4"
    rem=$(( d - 5 )); [ $rem -lt 1 ] && rem=1
    kenburns "img/${n}.png" "seg/${n}b.mp4" "$rem" "$dir"
    echo "file '${n}a.mp4'" >> "$LIST"
    echo "file '${n}b.mp4'" >> "$LIST"
  else
    kenburns "img/${n}.png" "seg/${n}.mp4" "$d" "$dir"
    echo "file '${n}.mp4'" >> "$LIST"
  fi
  echo "   scene $n ok (${d}s)"
done

echo ">> Concatenating video track..."
ffmpeg -y -f concat -safe 0 -i "$LIST" -c copy seg/video.mp4 -loglevel error

echo ">> Mixing narration + music and muxing..."
# Music ducked to -18dB under the narration; output trimmed to narration length + 1.5s tail.
ffmpeg -y -i seg/video.mp4 -i audio/narration.mp3 -i audio/music.mp3 \
  -filter_complex "[2:a]volume=0.16[m];[1:a][m]amix=inputs=2:duration=first:dropout_transition=3[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest \
  out/antikythera_5min_1080p.mp4 -loglevel error

echo ">> DONE -> out/antikythera_5min_1080p.mp4"
