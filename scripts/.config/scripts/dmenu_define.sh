#!/usr/bin/env bash

# CONFIGURATION - Change these values to adjust behavior
WRAP_WIDTH=125              # Characters before wrapping (default: 80)
DMENU_LINES=25              # Number of lines to show in dmenu
FONT="Px437 DOS/V re. JPN30:size=24"  # dmenu font
PLAYER="mpv"                 # Audio player (mpv, mpg123, ffplay, vlc, etc.)

# Get word from primary selection (what you've selected with mouse)
word=$(xclip -o -selection primary 2>/dev/null || wl-paste -p 2>/dev/null)

# If nothing in primary, try clipboard as fallback
if [[ -z "$word" ]]; then
    word=$(xclip -o -selection clipboard 2>/dev/null || wl-paste 2>/dev/null)
fi

# Function to play pronunciation audio
play_audio() {
    local audio_url="$1"
    local word="$2"
    
    if [[ -n "$audio_url" ]]; then
        # Play in background and disown
        case "$PLAYER" in
            mpv)
                mpv --no-video --quiet "$audio_url" >/dev/null 2>&1 &
                ;;
            mpg123)
                mpg123 -q "$audio_url" >/dev/null 2>&1 &
                ;;
            ffplay)
                ffplay -nodisp -autoexit -loglevel quiet "$audio_url" >/dev/null 2>&1 &
                ;;
            vlc)
                vlc --intf dummy --play-and-exit "$audio_url" >/dev/null 2>&1 &
                ;;
            *)
                # Try to find a player
                if command -v mpv >/dev/null 2>&1; then
                    mpv --no-video --quiet "$audio_url" >/dev/null 2>&1 &
                elif command -v mpg123 >/dev/null 2>&1; then
                    mpg123 -q "$audio_url" >/dev/null 2>&1 &
                elif command -v ffplay >/dev/null 2>&1; then
                    ffplay -nodisp -autoexit -loglevel quiet "$audio_url" >/dev/null 2>&1 &
                else
                    notify-send "Audio Player" "No audio player found. Install mpv, mpg123, or ffplay."
                fi
                ;;
        esac
    fi
}

# Function to fetch and display definition for a word
define_word() {
    local search_word="$1"
    
    # Fetch definition
    response=$(curl -s --connect-timeout 5 --max-time 10 "https://api.dictionaryapi.dev/api/v2/entries/en_US/$search_word")
    
    # Check if word was found
    if [[ -z "$response" ]] || echo "$response" | jq -e '.title == "No Definitions Found"' >/dev/null 2>&1; then
        # Word not found - offer to type another word
        new_word=$(echo "❌ Word not found: $search_word" | dmenu -l 1 -fn "$FONT" -nb "#000000" -nf "#bf616a" -sb "#ffffff" -sf "#000000" -p "Type another word:")
        if [[ -n "$new_word" ]]; then
            define_word "$new_word"
        fi
        exit 1
    fi
    
    # Extract audio URLs
    audio_urls=$(echo "$response" | jq -r '.[0].phonetics[]?.audio | select(. != null and . != "")' | grep -v '^$')
    
    # Function to wrap text to specific width
    wrap_text() {
        local text="$1"
        local width="${2:-$WRAP_WIDTH}"
        # Remove existing indentation, then wrap, then add consistent indentation
        echo "$text" | sed 's/^[[:space:]]*//' | fold -s -w "$width" | sed 's/^/      /'  # 6 spaces for wrapped lines
    }
    
    # Parse with jq and format for dmenu
    formatted=$(echo "$response" | jq -r '
    .[0] as $data |
    "📗  " + $data.word + " " + ($data.phonetic // ""),
    "🔊  PRONUNCIATION (select to play audio)",
    ( $data.meanings[] | 
      "🔸  " + (.partOfSpeech | ascii_upcase),
      ( .definitions[] | 
        "    📝 " + (.definition | gsub("\n"; " ")),
        (if .example then "      💬 " + (.example | gsub("\n"; " ")) else empty end),
        (if .synonyms and (.synonyms | length > 0) then "      🔤 " + (.synonyms | join(", ")) else empty end)
      )
    )
    ' | grep -v '^$')
    
    # Process each line and wrap long ones with consistent indentation
    wrapped=""
    while IFS= read -r line; do
        # Determine base indentation based on line type
        if [[ "$line" =~ ^"    📝" ]]; then
            # Main definition - keep at 4 spaces
            if [[ ${#line} -gt $WRAP_WIDTH ]]; then
                # For wrapped parts of definition, use 6 spaces (definition + extra indent)
                first_line=$(echo "$line" | sed 's/^[[:space:]]*//' | fold -s -w "$WRAP_WIDTH" | head -1 | sed 's/^/    /')
                rest_lines=$(echo "$line" | sed 's/^[[:space:]]*//' | fold -s -w "$WRAP_WIDTH" | tail -n +2 | sed 's/^/      /')
                wrapped+="$first_line"$'\n'
                [[ -n "$rest_lines" ]] && wrapped+="$rest_lines"$'\n'
            else
                wrapped+="$line"$'\n'
            fi
        elif [[ "$line" =~ ^"      💬" ]] || [[ "$line" =~ ^"      🔤" ]]; then
            # Examples and synonyms - already at 6 spaces
            if [[ ${#line} -gt $WRAP_WIDTH ]]; then
                wrapped+=$(wrap_text "$line" "$WRAP_WIDTH")$'\n'
            else
                wrapped+="$line"$'\n'
            fi
        else
            # Headers and part of speech - keep as is (no wrapping needed)
            wrapped+="$line"$'\n'
        fi
    done <<< "$formatted"
    
    # Show in dmenu - remove any trailing empty lines
    selected=$(echo "$wrapped" | sed '/^$/d' | dmenu -l "$DMENU_LINES" -fn "$FONT" -nb "#000000" -nf "#ffffff" -sb "#ffffff" -sf "#000000")
    
    # Handle selection
    if [[ -n "$selected" ]]; then
        if [[ "$selected" =~ ^"🔊" ]]; then
            # User selected pronunciation - play audio
            if [[ -n "$audio_urls" ]]; then
                # Try to play the first audio URL (usually US pronunciation)
                first_audio=$(echo "$audio_urls" | head -1)
                play_audio "$first_audio" "$search_word"
                # Show dmenu again after playing
                define_word "$search_word"
            else
                notify-send "No Audio" "No pronunciation audio available for '$search_word'"
            fi
        else
            # Just exit (no notification)
            exit 0
        fi
    fi
}

# Function for initial word selection/prompt
initial_prompt() {
    local typed_word
    typed_word=$(echo "🔍 Type a word to define:" | dmenu -l 1 -fn "$FONT" -nb "#000000" -nf "#ffffff" -sb "#ffffff" -sf "#000000" -p "Word:")
    if [[ -n "$typed_word" ]]; then
        define_word "$typed_word"
    fi
}

# Check for empty word or special characters
if [[ -z "$word" || "$word" =~ [\/] ]]; then
    # Empty or invalid input - let user type a word
    initial_prompt
    exit 1
fi

# Call the define function with the selected word
define_word "$word"
