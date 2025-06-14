#!/bin/bash

set -euo pipefail

DECK_FILE="${1:-decklist.deck}"
OUTPUT_DIR="docs"
PICTURE_DIR="$OUTPUT_DIR/pictures"

if [[ ! -f "$DECK_FILE" ]]; then
  echo "❌ Fichier deck introuvable : $DECK_FILE"
  exit 1
fi

mkdir -p "$PICTURE_DIR"
rm -f "$PICTURE_DIR"/* "$OUTPUT_DIR/deck.png" "$OUTPUT_DIR/deck.pdf" "$OUTPUT_DIR/deck_preview.html"

declare -a IMAGE_LIST=()

while IFS= read -r line || [[ -n "$line" ]]; do
  line=$(echo "$line" | tr -d '\r')  # Nettoyage Windows

  [[ -z "$line" || "$line" =~ ^# ]] && continue

  QTY=$(echo "$line" | cut -dx -f1)
  CARD_CODE=$(echo "$line" | cut -dx -f2)

  URL="https://en.onepiece-cardgame.com/images/cardlist/card/${CARD_CODE}.png"
  FILE="$PICTURE_DIR/${CARD_CODE}.png"

  echo "🔽 Téléchargement $CARD_CODE ($QTY×)..."

  if curl -s --fail -o "$FILE" "$URL"; then
    for ((i=0; i<QTY; i++)); do
      COPY="$PICTURE_DIR/${CARD_CODE}_${i}.png"
      cp "$FILE" "$COPY"
      IMAGE_LIST+=("pictures/${CARD_CODE}_${i}.png")
    done
  else
    echo "❌ Échec du téléchargement : $CARD_CODE"
  fi
done < "$DECK_FILE"

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

# Désactive Jekyll
touch "$OUTPUT_DIR/.nojekyll"

# Génération image PNG globale
echo "🖼️ Génération de l’image PNG..."
montage "${IMAGE_LIST[@]/#/$OUTPUT_DIR/}" -tile x -geometry +5+5 "$OUTPUT_DIR/deck.png"

# Conversion en PDF
echo "📄 Génération du PDF..."
magick "$OUTPUT_DIR/deck.png" "$OUTPUT_DIR/deck.pdf"

echo "✅ Terminé. Fichiers générés dans : $OUTPUT_DIR/"
