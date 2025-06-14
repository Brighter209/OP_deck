#!/bin/bash

set -e

DECK_FILE="decklist.deck"
OUTPUT_DIR="docs"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*

declare -a IMAGE_LIST=()

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  QTY=$(echo "$line" | cut -dx -f1)
  CARD_CODE=$(echo "$line" | cut -dx -f2)

  URL="https://en.onepiece-cardgame.com/images/cardlist/card/${CARD_CODE}.png"
  FILE="${OUTPUT_DIR}/${CARD_CODE}.png"

  if curl -s --fail -o "$FILE" "$URL"; then
    for ((i=0; i<QTY; i++)); do
      IMAGE_LIST+=("$CARD_CODE.png")
    done
  fi
done < "$DECK_FILE"
touch "$OUTPUT_DIR/.nojekyll"

# Génération HTML
cat <<EOF > "$OUTPUT_DIR/deck_preview.html"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Deck Preview</title>
  <style>
    body { background: #111; color: #fff; font-family: sans-serif; text-align: center; }
    .grid { display: flex; flex-wrap: wrap; gap: 10px; justify-content: center; margin: 20px; }
    img { width: 150px; transition: transform 0.2s; border-radius: 8px; }
    img:hover { transform: scale(1.3); z-index: 2; }
  </style>
</head>
<body>
  <h1>Deck Preview</h1>
  <div class="grid">
EOF

for img in "${IMAGE_LIST[@]}"; do
  echo "    <img src='$img'>" >> "$OUTPUT_DIR/deck_preview.html"
done

cat <<EOF >> "$OUTPUT_DIR/deck_preview.html"
  </div>
</body>
</html>
EOF


