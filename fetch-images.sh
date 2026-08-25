#!/usr/bin/env bash
# fetch-images.sh
# Localizes the DNA Roofing hero/gallery/ad images.
# Downloads the Higgsfield-generated images alongside index.html,
# then rewrites the <img src="..."> URLs to their local filenames.
#
# Usage:  bash fetch-images.sh
#
# Safe to re-run: files are overwritten in place.

set -euo pipefail
cd "$(dirname "$0")"

BASE="https://d8j0ntlcm91z4.cloudfront.net/user_3ILDUMZDrvLzRCFe8Kri261DDIA"

declare -A IMG=(
  ["img-hero.jpg"]="hf_20260825_215701_64e27b71-20b2-4899-ac11-44cd05fa48c2.png"
  ["img-roofer.jpg"]="hf_20260825_215702_f15a020f-3d86-4358-80a7-b36eb877d1db.png"
  ["img-hands.jpg"]="hf_20260825_215701_b7f2ed02-f82a-471b-8fe6-1988192cfb20.png"
  ["img-beforeafter.jpg"]="hf_20260825_215701_f1fc7976-ae23-4067-a874-2e982952860c.png"
  ["img-generations.jpg"]="hf_20260825_215701_a88d76c1-4756-4056-95ec-b664a6b979af.png"
  ["img-drone.jpg"]="hf_20260825_215701_232d8145-6244-47f6-ab87-6cbbc60b1928.png"
  ["img-ad.jpg"]="hf_20260825_215701_d7d9ba76-8012-472d-98ef-de8ee8f802ad.png"
)

echo "→ Downloading 7 images from Higgsfield…"
for OUT in "${!IMG[@]}"; do
  URL="$BASE/${IMG[$OUT]}"
  TMP="${OUT%.jpg}.png"
  echo "   $OUT"
  curl -sSfL -o "$TMP" "$URL"
done

# Convert PNG → JPG (smaller, faster). Requires ImageMagick OR ffmpeg.
if command -v magick >/dev/null 2>&1; then
  CONV() { magick "$1" -resize '1800x1800>' -quality 82 "$2"; }
elif command -v convert >/dev/null 2>&1; then
  CONV() { convert "$1" -resize '1800x1800>' -quality 82 "$2"; }
elif command -v ffmpeg >/dev/null 2>&1; then
  CONV() { ffmpeg -y -loglevel error -i "$1" -vf "scale='min(1800,iw)':-2" -q:v 5 "$2"; }
else
  echo "! Neither ImageMagick nor ffmpeg installed — leaving PNGs in place."
  for OUT in "${!IMG[@]}"; do
    mv "${OUT%.jpg}.png" "${OUT%.jpg}.png"
  done
  exit 0
fi

echo "→ Converting to JPG…"
for OUT in "${!IMG[@]}"; do
  TMP="${OUT%.jpg}.png"
  CONV "$TMP" "$OUT"
  rm -f "$TMP"
done

echo "→ Rewriting index.html to use local paths…"
# Swap each CloudFront URL for its local filename.
for OUT in "${!IMG[@]}"; do
  URL="$BASE/${IMG[$OUT]}"
  # macOS/BSD-compatible sed with a backup then remove it.
  sed -i.bak "s|$URL|$OUT|g" index.html
done
rm -f index.html.bak

echo "✓ Done. Images are local; index.html now references img-*.jpg."
echo "  Commit: git add img-*.jpg index.html && git commit -m 'Localize brand images'"
