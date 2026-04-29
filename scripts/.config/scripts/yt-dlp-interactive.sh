#!/bin/bash

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null; then
    echo -e "${RED}Error: yt-dlp is not installed${NC}"
    echo "Install it using: pip install yt-dlp"
    exit 1
fi

# Check if ffmpeg is installed (required for section downloading)
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${YELLOW}Warning: ffmpeg is not installed${NC}"
        echo "Duration-based downloading requires ffmpeg for accurate cuts"
        echo "Install ffmpeg using your package manager:"
        echo "  - Ubuntu/Debian: sudo apt install ffmpeg"
        echo "  - macOS: brew install ffmpeg"
        echo "  - Windows: Download from ffmpeg.org"
        echo ""
        return 1
    fi
    return 0
}

# Function to display formats in a clean table
display_formats() {
    local url=$1
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                    AVAILABLE FORMATS                                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get video duration first
    duration=$(yt-dlp --get-duration "$url" 2>/dev/null)
    if [[ -n "$duration" ]]; then
        echo -e "${MAGENTA}Video Duration: ${YELLOW}$duration${NC}"
        echo ""
    fi
    
    printf "${YELLOW}%-8s ${GREEN}%-8s ${CYAN}%-12s ${BLUE}%-20s %-25s %-10s${NC}\n" "ID" "Ext" "Resolution" "Type" "Codec/Bitrate" "Note"
    echo "--------------------------------------------------------------------------------------------------------"
    
    # Get the format list and skip the header line
    yt-dlp -F "$url" 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        # Skip empty lines and lines that don't start with format ID
        if [[ -n "$line" ]] && [[ "$line" =~ ^[0-9]+ ]]; then
            # Extract fields using awk
            format_id=$(echo "$line" | awk '{print $1}')
            ext=$(echo "$line" | awk '{print $2}')
            resolution=$(echo "$line" | awk '{print $3}')
            fps=$(echo "$line" | awk '{print $4}')
            codec_info=$(echo "$line" | awk '{print $5}')
            bitrate=$(echo "$line" | awk '{print $6}')
            note=$(echo "$line" | awk '{for(i=7;i<=NF;i++) printf "%s ", $i; print ""}')
            
            # Determine format type
            if [[ "$codec_info" == *"video only"* ]]; then
                type="${BLUE}Video Only${NC}"
            elif [[ "$codec_info" == *"audio only"* ]]; then
                type="${CYAN}Audio Only${NC}"
            else
                type="${GREEN}Video+Audio${NC}"
            fi
            
            # Clean up resolution display
            if [[ -z "$resolution" ]] || [[ "$resolution" == "audio"* ]]; then
                resolution="N/A"
            fi
            
            # Clean up codec info
            if [[ -z "$codec_info" ]]; then
                codec_info="unknown"
            fi
            
            printf "%-8s %-8s %-12s %-20b %-25s %-10s\n" \
                "$format_id" "$ext" "$resolution" "$type" "$codec_info" "$note"
        fi
    done
    
    echo ""
    echo -e "${GREEN}Use the format IDs above to select specific formats${NC}"
    echo ""
}

# Function to convert time format to seconds
time_to_seconds() {
    local time_str=$1
    if [[ $time_str =~ ^[0-9]+$ ]]; then
        echo $time_str
    elif [[ $time_str =~ ^([0-9]+):([0-9]+)$ ]]; then
        echo $((${BASH_REMATCH[1]} * 60 + ${BASH_REMATCH[2]}))
    elif [[ $time_str =~ ^([0-9]+):([0-9]+):([0-9]+)$ ]]; then
        echo $((${BASH_REMATCH[1]} * 3600 + ${BASH_REMATCH[2]} * 60 + ${BASH_REMATCH[3]}))
    else
        echo ""
    fi
}

# Function to download video section
download_section() {
    local url=$1
    local format_id=$2
    local start_time=$3
    local end_time=$4
    
    if [[ -z "$start_time" ]]; then
        echo -e "${RED}Error: Start time is required${NC}"
        return 1
    fi
    
    # Convert times to seconds for validation
    start_sec=$(time_to_seconds "$start_time")
    if [[ -z "$start_sec" ]]; then
        echo -e "${RED}Error: Invalid start time format. Use MM:SS or HH:MM:SS or seconds${NC}"
        return 1
    fi
    
    if [[ -n "$end_time" ]]; then
        end_sec=$(time_to_seconds "$end_time")
        if [[ -z "$end_sec" ]]; then
            echo -e "${RED}Error: Invalid end time format. Use MM:SS or HH:MM:SS or seconds${NC}"
            return 1
        fi
        time_range="${start_sec}-${end_sec}"
        time_display="${start_time} to ${end_time}"
    else
        time_range="${start_sec}-inf"
        time_display="from ${start_time} to end"
    fi
    
    echo -e "${BLUE}Downloading section: ${time_display}${NC}"
    echo -e "${YELLOW}Running: yt-dlp -f \"$format_id\" --download-sections \"*${time_range}\" --force-keyframes-at-cuts \"$url\"${NC}"
    echo ""
    
    yt-dlp -f "$format_id" --download-sections "*${time_range}" --force-keyframes-at-cuts "$url"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Section download completed!${NC}"
    else
        echo -e "${RED}✗ Section download failed!${NC}"
    fi
}

# Function to get video info
get_video_info() {
    local url=$1
    
    echo -e "${GREEN}Fetching video information...${NC}"
    echo ""
    
    # Get video title
    title=$(yt-dlp --get-title "$url" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Invalid URL or unable to fetch video info${NC}"
        return 1
    fi
    
    # Get video duration
    duration=$(yt-dlp --get-duration "$url" 2>/dev/null)
    
    echo -e "${CYAN}Video Title:${NC} ${YELLOW}$title${NC}"
    if [[ -n "$duration" ]]; then
        echo -e "${CYAN}Total Duration:${NC} ${YELLOW}$duration${NC}"
    fi
    echo ""
}

# Main interactive loop
main() {
    local url=$1
    
    if [ -z "$url" ]; then
        echo -e "${RED}Usage: $0 <YouTube URL or video URL>${NC}"
        echo "Example: $0 https://www.youtube.com/watch?v=VIDEO_ID"
        exit 1
    fi
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                    YT-DLP INTERACTIVE DOWNLOADER                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get video info
    get_video_info "$url"
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Check ffmpeg availability for section downloads
    ffmpeg_available=false
    if check_ffmpeg > /dev/null 2>&1; then
        ffmpeg_available=true
    fi
    
    # Display available formats
    echo -e "${YELLOW}Fetching available formats...${NC}"
    echo ""
    display_formats "$url"
    
    while true; do
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Options:${NC}"
        echo "  1) Download with specific format ID"
        echo "  2) Download best quality (video+audio)"
        echo "  3) Download best video only"
        echo "  4) Download best audio only (mp3)"
        echo "  5) Download best audio only (original format)"
        if [ "$ffmpeg_available" = true ]; then
            echo -e "${MAGENTA}  6) Download specific section/timestamp${NC}"
            echo -e "${MAGENTA}  7) Download from timestamp to end${NC}"
            echo -e "${MAGENTA}  8) Download multiple sections${NC}"
        else
            echo -e "${YELLOW}  6-8) Install ffmpeg for duration-based downloads${NC}"
        fi
        echo "  9) Show formats again"
        echo " 10) Download with custom yt-dlp options"
        echo "  0) Exit"
        echo ""
        
        read -p "$(echo -e ${GREEN}"Enter your choice: "${NC})" choice
        
        case $choice in
            1)
                echo ""
                read -p "$(echo -e ${GREEN}"Enter format ID: "${NC})" format_id
                echo ""
                echo -e "${BLUE}Downloading with format ID: $format_id${NC}"
                echo -e "${YELLOW}Running: yt-dlp -f \"$format_id\" \"$url\"${NC}"
                echo ""
                yt-dlp -f "$format_id" "$url"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Download completed!${NC}"
                else
                    echo -e "${RED}✗ Download failed!${NC}"
                fi
                ;;
            2)
                echo ""
                echo -e "${BLUE}Downloading best quality...${NC}"
                echo -e "${YELLOW}Running: yt-dlp -f \"bestvideo+bestaudio\" --merge-output-format mp4 \"$url\"${NC}"
                echo ""
                yt-dlp -f "bestvideo+bestaudio" --merge-output-format mp4 "$url"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Download completed!${NC}"
                else
                    echo -e "${RED}✗ Download failed!${NC}"
                fi
                ;;
            3)
                echo ""
                echo -e "${BLUE}Downloading best video only...${NC}"
                echo -e "${YELLOW}Running: yt-dlp -f \"bestvideo\" \"$url\"${NC}"
                echo ""
                yt-dlp -f "bestvideo" "$url"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Download completed!${NC}"
                else
                    echo -e "${RED}✗ Download failed!${NC}"
                fi
                ;;
            4)
                echo ""
                echo -e "${BLUE}Downloading best audio only (converting to MP3)...${NC}"
                echo -e "${YELLOW}Running: yt-dlp -f \"bestaudio\" --extract-audio --audio-format mp3 --audio-quality 0 \"$url\"${NC}"
                echo ""
                yt-dlp -f "bestaudio" --extract-audio --audio-format mp3 --audio-quality 0 "$url"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Download completed!${NC}"
                else
                    echo -e "${RED}✗ Download failed!${NC}"
                fi
                ;;
            5)
                echo ""
                echo -e "${BLUE}Downloading best audio only (original format)...${NC}"
                echo -e "${YELLOW}Running: yt-dlp -f \"bestaudio\" \"$url\"${NC}"
                echo ""
                yt-dlp -f "bestaudio" "$url"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Download completed!${NC}"
                else
                    echo -e "${RED}✗ Download failed!${NC}"
                fi
                ;;
            6)
                if [ "$ffmpeg_available" = true ]; then
                    echo ""
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo -e "${MAGENTA}Download Specific Section${NC}"
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo ""
                    echo -e "${YELLOW}Time formats accepted:${NC}"
                    echo "  - Seconds: 120"
                    echo "  - MM:SS: 2:30"
                    echo "  - HH:MM:SS: 1:02:30"
                    echo ""
                    read -p "$(echo -e ${GREEN}"Enter start time: "${NC})" start_time
                    read -p "$(echo -e ${GREEN}"Enter end time (press Enter for end of video): "${NC})" end_time
                    echo ""
                    echo -e "${CYAN}Select format type:${NC}"
                    echo "  a) Use best quality (video+audio)"
                    echo "  b) Use best video only"
                    echo "  c) Use best audio only"
                    echo "  d) Specify format ID"
                    read -p "$(echo -e ${GREEN}"Choice (a/b/c/d): "${NC})" format_choice
                    echo ""
                    
                    case $format_choice in
                        a) download_section "$url" "bestvideo+bestaudio" "$start_time" "$end_time" ;;
                        b) download_section "$url" "bestvideo" "$start_time" "$end_time" ;;
                        c) download_section "$url" "bestaudio" "$start_time" "$end_time" ;;
                        d) read -p "Enter format ID: " format_id
                           download_section "$url" "$format_id" "$start_time" "$end_time" ;;
                        *) echo -e "${RED}Invalid choice${NC}" ;;
                    esac
                else
                    echo -e "${RED}ffmpeg is required for section downloads${NC}"
                fi
                ;;
            7)
                if [ "$ffmpeg_available" = true ]; then
                    echo ""
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo -e "${MAGENTA}Download from Timestamp to End${NC}"
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo ""
                    echo -e "${YELLOW}Time formats accepted:${NC}"
                    echo "  - Seconds: 120"
                    echo "  - MM:SS: 2:30"
                    echo "  - HH:MM:SS: 1:02:30"
                    echo ""
                    read -p "$(echo -e ${GREEN}"Enter start time: "${NC})" start_time
                    echo ""
                    echo -e "${CYAN}Select format type:${NC}"
                    echo "  a) Use best quality (video+audio)"
                    echo "  b) Use best video only"
                    echo "  c) Use best audio only"
                    echo "  d) Specify format ID"
                    read -p "$(echo -e ${GREEN}"Choice (a/b/c/d): "${NC})" format_choice
                    echo ""
                    
                    case $format_choice in
                        a) download_section "$url" "bestvideo+bestaudio" "$start_time" "" ;;
                        b) download_section "$url" "bestvideo" "$start_time" "" ;;
                        c) download_section "$url" "bestaudio" "$start_time" "" ;;
                        d) read -p "Enter format ID: " format_id
                           download_section "$url" "$format_id" "$start_time" "" ;;
                        *) echo -e "${RED}Invalid choice${NC}" ;;
                    esac
                else
                    echo -e "${RED}ffmpeg is required for section downloads${NC}"
                fi
                ;;
            8)
                if [ "$ffmpeg_available" = true ]; then
                    echo ""
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo -e "${MAGENTA}Download Multiple Sections${NC}"
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo ""
                    echo -e "${YELLOW}Example: 0:00-1:30, 2:15-3:45, 5:00-6:30${NC}"
                    echo -e "${YELLOW}Time formats: Seconds, MM:SS, or HH:MM:SS${NC}"
                    echo ""
                    read -p "$(echo -e ${GREEN}"Enter sections (comma-separated): "${NC})" sections
                    echo ""
                    echo -e "${CYAN}Select format type:${NC}"
                    echo "  a) Use best quality (video+audio)"
                    echo "  b) Use best video only"
                    echo "  c) Use best audio only"
                    echo "  d) Specify format ID"
                    read -p "$(echo -e ${GREEN}"Choice (a/b/c/d): "${NC})" format_choice
                    echo ""
                    
                    # Convert sections to yt-dlp format
                    sections_formatted=""
                    IFS=',' read -ra SECTION_ARRAY <<< "$sections"
                    for section in "${SECTION_ARRAY[@]}"; do
                        section=$(echo "$section" | xargs) # Trim whitespace
                        if [[ -n "$section" ]]; then
                            sections_formatted="$sections_formatted*$section,"
                        fi
                    done
                    sections_formatted="${sections_formatted%,}"
                    
                    case $format_choice in
                        a) format_id="bestvideo+bestaudio" ;;
                        b) format_id="bestvideo" ;;
                        c) format_id="bestaudio" ;;
                        d) read -p "Enter format ID: " format_id ;;
                        *) echo -e "${RED}Invalid choice${NC}" && continue ;;
                    esac
                    
                    echo -e "${BLUE}Downloading sections: $sections${NC}"
                    echo -e "${YELLOW}Running: yt-dlp -f \"$format_id\" --download-sections \"$sections_formatted\" \"$url\"${NC}"
                    echo ""
                    yt-dlp -f "$format_id" --download-sections "$sections_formatted" "$url"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✓ Sections download completed!${NC}"
                    else
                        echo -e "${RED}✗ Sections download failed!${NC}"
                    fi
                else
                    echo -e "${RED}ffmpeg is required for section downloads${NC}"
                fi
                ;;
            9)
                echo ""
                display_formats "$url"
                ;;
            10)
                echo ""
                read -p "$(echo -e ${GREEN}"Enter custom yt-dlp options: "${NC})" custom_opts
                echo ""
                echo -e "${BLUE}Running: yt-dlp $custom_opts \"$url\"${NC}"
                echo -e "${YELLOW}Note: This passes your options directly to yt-dlp${NC}"
                echo ""
                eval yt-dlp $custom_opts "\"$url\""
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✓ Download completed!${NC}"
                else
                    echo -e "${RED}✗ Download failed!${NC}"
                fi
                ;;
            0)
                echo ""
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}Invalid option! Please try again.${NC}"
                ;;
        esac
        
        echo ""
    done
}

# Run main function with provided URL
main "$1"
