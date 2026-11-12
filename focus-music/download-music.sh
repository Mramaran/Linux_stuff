#!/usr/bin/env bash
# Downloads the focus music (one time, about 250 MB). Already-downloaded tracks are skipped.
#   ~/Music/Focus/Calm  14 calm instrumental tracks by Kevin MacLeod (incompetech.com), CC-BY 4.0
#   ~/Music/Focus/Lofi  16 lo-fi tracks from OpenGameArt.org, CC0 (public domain):
#                       7 by Holizna ("Happy Lo-Fi" collection) + 9 by TAD ("Lofi Compilation")
# Also writes ~/Music/Focus/CREDITS.txt.
set -e
BASE="${FOCUS_MUSIC_DIR:-$HOME/Music/Focus}"
DIR="$BASE/Calm"
URL="https://incompetech.com/music/royalty-free/mp3-royaltyfree"
TRACKS=(
    "Ethereal Relaxation" "Relaxing Piano Music" "Healing" "Dreams Become Real" "Clean Soul"
    "Meditation Impromptu 01" "Meditation Impromptu 02" "Meditation Impromptu 03" "Dreamer"
    "Calmant" "Floating Cities" "Bathed in the Light" "Frost Waltz" "Peaceful Desolation"
)
mkdir -p "$DIR" "$BASE/Lofi"
for t in "${TRACKS[@]}"; do
    f="$DIR/$t.mp3"
    if [ -s "$f" ]; then echo "have $t"; continue; fi
    curl -sfL --max-time 300 -o "$f.part" "$URL/$(printf '%s' "$t" | sed 's/ /%20/g').mp3" \
        && mv "$f.part" "$f" && echo "got  $t" || { rm -f "$f.part"; echo "FAILED $t"; }
done

# ---- Lo-fi (CC0) ----
OGA="https://opengameart.org/sites/default/files"
LOFI="$BASE/Lofi"
TAD=("A cup of tea" "Bartender" "Cat caffe" "Countryside" "Cue" "Florist" "Morning rain" "Oceanside" "Rainy Forest")
for t in "${TAD[@]}"; do
    f="$LOFI/TAD - $t.mp3"
    if [ -s "$f" ]; then echo "have TAD - $t"; continue; fi
    curl -sfL --max-time 300 -o "$f.part" "$OGA/$(printf '%s' "$t" | sed 's/ /%20/g')_0.mp3" \
        && mv "$f.part" "$f" && echo "got  TAD - $t" || { rm -f "$f.part"; echo "FAILED TAD - $t"; }
done
if ! ls "$LOFI"/Holizna\ -\ *.mp3 >/dev/null 2>&1; then
    tmp=$(mktemp -d)
    if curl -sfL --max-time 600 -o "$tmp/holizna.zip" "$OGA/happy_lo-fi_lofi_collection.zip"; then
        # MP3s only (the zip also has OGG copies); file names only, no paths from the archive
        python3 -I - "$tmp/holizna.zip" "$LOFI" <<'PY'
import os, re, sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
for i in z.infolist():
    n = os.path.basename(i.filename)
    if not n.lower().endswith(".mp3"):
        continue
    n = re.sub(r"(\.mp3)+$", ".mp3", n, flags=re.I)
    n = re.sub(r"^\d+\s+HoliznaCC0 - ", "Holizna - ", n)
    with z.open(i) as s, open(os.path.join(sys.argv[2], n), "wb") as d:
        d.write(s.read())
    print("got ", n[:-4])
PY
    else
        echo "FAILED Holizna collection"
    fi
    rm -rf "$tmp"
else
    echo "have Holizna collection"
fi

{
    echo "Focus music credits"
    echo "==================="
    echo
    echo "Calm/ — music by Kevin MacLeod (incompetech.com)"
    echo "Licensed under Creative Commons: By Attribution 4.0"
    echo "https://creativecommons.org/licenses/by/4.0/"
    echo
    for t in "${TRACKS[@]}"; do echo "  $t — Kevin MacLeod (incompetech.com)"; done
    echo
    echo "Lofi/ — public domain (CC0 1.0), from OpenGameArt.org; no credit required"
    echo "https://creativecommons.org/publicdomain/zero/1.0/"
    echo "  Holizna — \"Happy Lo-Fi (Lofi Collection)\"  https://opengameart.org/content/happy-lo-fi-lofi-collection"
    echo "  TAD     — \"Lofi Compilation\"               https://opengameart.org/content/lofi-compilation"
} > "$BASE/CREDITS.txt"
echo "Done: $(ls "$DIR" | wc -l) calm + $(ls "$LOFI" | wc -l) lo-fi tracks in $BASE"
