#!/usr/bin/env bash

set -euo pipefail

DEPENDENCIES=(ffmpeg magick gum md5sum file)
for cmd in "${DEPENDENCIES[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is not installed or not in PATH" >&2
        exit 1
    fi
done

# --- Start ---

# Default values
TOP_TEXT=""
BOTTOM_TEXT=""
VIDEO_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --top=*)
        TOP_TEXT="${1#*=}"
        shift
        ;;
    --bottom=*)
        BOTTOM_TEXT="${1#*=}"
        shift
        ;;
    --top)
        TOP_TEXT="$2"
        shift 2
        ;;
    --bottom)
        BOTTOM_TEXT="$2"
        shift 2
        ;;
    -*)
        gum log -l error "Unknown option: $1"
        exit 1
        ;;
    *)
        VIDEO_FILE="$1"
        shift
        ;;
    esac
done

gum log -l debug "top=$TOP_TEXT"
gum log -l debug "video=$VIDEO_FILE"
gum log -l debug "bottom=$BOTTOM_TEXT"

if [[ -z "$VIDEO_FILE" ]]; then
    gum log -l error "please provide a video/image file"
    exit 1
fi

function cleanup() {
    gum log -l info "Running cleanup!"
    rm "/tmp/memify-top.png" "/tmp/memify-bottom.png" 2>/dev/null
}

trap cleanup EXIT

if [[ -n "$TOP_TEXT" ]]; then
    magick -size 1000x250 xc:white \
        -gravity center \
        -font Anton-Regular \
        -fill black \
        -size 950x240 caption:"$TOP_TEXT" \
        -colorspace sRGB \
        -composite /tmp/memify-top.png
fi

if [[ -n "$BOTTOM_TEXT" ]]; then
    magick -size 1000x250 xc:white \
        -gravity center \
        -font Anton-Regular \
        -fill black \
        -size 950x240 caption:"$BOTTOM_TEXT" \
        -colorspace sRGB \
        -composite /tmp/memify-bottom.png
fi

# Build ffmpeg input list
INPUTS=(-i "$VIDEO_FILE")
FILTER_COMPLEX=""

# Count of input streams for filter-complex
STREAM_INDEX=0

# Add top text if exists
if [[ -f /tmp/memify-top.png ]]; then
    INPUTS+=(-i /tmp/memify-top.png)
    # Scale top to 1000px width
    FILTER_COMPLEX+="[1:v]scale=1000:-2[top];"
    STREAM_INDEX=$((STREAM_INDEX + 1))
fi

FILTER_COMPLEX+="[0:v]scale=1000:-2[vid];"

# Add bottom text if exists
if [[ -f /tmp/memify-bottom.png ]]; then
    INPUTS+=(-i /tmp/memify-bottom.png)
    FILTER_COMPLEX+="[${STREAM_INDEX}:v]scale=1000:-2[bottom];"
fi

# Build vstack depending on which text exists
if [[ -f /tmp/memify-top.png ]] && [[ -f /tmp/memify-bottom.png ]]; then
    FILTER_COMPLEX+="[top][vid][bottom]vstack=inputs=3[out]"
elif [[ -f /tmp/memify-top.png ]]; then
    FILTER_COMPLEX+="[top][vid]vstack=inputs=2[out]"
elif [[ -f /tmp/memify-bottom.png ]]; then
    FILTER_COMPLEX+="[vid][bottom]vstack=inputs=2[out]"
else
    FILTER_COMPLEX+="[vid]copy[out]"
fi

OUTPUT="meme-$(echo "$TOP_TEXT" "$BOTTOM_TEXT" "$VIDEO_FILE" | md5sum - | awk '{print $1}').$(file --brief --extension "$VIDEO_FILE")"
gum log -l info --prefix Output "$OUTPUT"

# Run ffmpeg
gum spin --title="Cooking your the meme!" -- \
    ffmpeg "${INPUTS[@]}" \
    -filter_complex "$FILTER_COMPLEX;[out]format=yuv420p[final]" -map "[final]" \
    -c:v libx264 -crf 23 -preset veryfast -y \
    "$OUTPUT"
