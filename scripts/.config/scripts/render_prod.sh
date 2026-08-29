#!/usr/bin/env bash
#=============================================================================
# Production render script — Houdini Karma (husk)
#=============================================================================
# Improvements over a raw husk call:
#   1. Timestamped, rotating master log  (never clobbers previous runs)
#   2. Per-frame individual logs         (instant grep for slow/failed frames)
#   3. -V a3 verbosity                   (production sweet-spot)
#   4. Exit-code checking + failure log  (failures surfaced immediately)
#   5. --snapshot for crash resilience   (partial saves survive crashes)
#   6. Live redrawing progress display   (compact, no wall-of-log spam)
#
# Usage:
#   ./render_prod.sh               # full range (frames 1-96)
#   ./render_prod.sh 10 20         # frames 10-20 only
#   DRY_RUN=1 ./render_prod.sh     # print what would run without rendering
#=============================================================================

set -euo pipefail

# ---- Configuration ---------------------------------------------------------
SCENE="/mnt/data/Houdini/swirl-surface-tension/usd/usd_rop1.usdnc"
RESOLUTION="640 640"
VERBOSITY="a3"
IMAGE_MODE="progressive"
SNAPSHOT_INTERVAL=30            # seconds between partial-image snapshots

FRAME_FIRST="${1:-1}"
FRAME_LAST="${2:-96}"

# ---- Directories -----------------------------------------------------------
SCENE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_ROOT="${SCENE_DIR}/render_logs"
RUN_TS="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="${LOG_ROOT}/${RUN_TS}"
MASTER_LOG="${RUN_DIR}/master.log"
FAILURE_LOG="${RUN_DIR}/failures.log"
STATS_CSV="${RUN_DIR}/stats.csv"

mkdir -p "$RUN_DIR"

# ---- Detect terminal -------------------------------------------------------
# If stdout is not a TTY (piped, farm, cron), fall back to plain line output
TTY_MODE=false
if [[ -t 1 ]]; then
    TTY_MODE=true
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
else
    TERM_COLS=80
fi
BAR_WIDTH=$(( TERM_COLS - 5 ))
(( BAR_WIDTH > 80 )) && BAR_WIDTH=80   # cap — full-width bars are hard to scan

# ---- Colour helpers (ANSI-C quoted — real escape chars, no -e needed) -------
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
DIM=$'\033[2m'
NC=$'\033[0m'

# ---- ANSI escape sequences -------------------------------------------------
if $TTY_MODE; then
    CURSOR_HIDE=$'\033[?25l'
    CURSOR_SHOW=$'\033[?25h'
    ERASE_LINE=$'\033[2K'
    ERASE_DOWN=$'\033[J'
else
    CURSOR_HIDE=""
    CURSOR_SHOW=""
    ERASE_LINE=""
    ERASE_DOWN=""
fi

# ---- Counters & state ------------------------------------------------------
TOTAL_FRAMES=$(( FRAME_LAST - FRAME_FIRST + 1 ))
PASSED=0
FAILED=0
SKIPPED=0
TOTAL_START=$(date +%s)
INTERRUPTED=0

# ---- Logging functions (always write to master log) ------------------------
log_master()  { echo "[$(date '+%H:%M:%S')] $*" >> "$MASTER_LOG"; }
log_success() { echo "[$(date '+%H:%M:%S')] ✓ $*" >> "$MASTER_LOG"; }
log_fail()    { echo "[$(date '+%H:%M:%S')] ✗ $*" | tee -a "$FAILURE_LOG" >> "$MASTER_LOG"; }

# ---- Signal handling -------------------------------------------------------
on_interrupt() {
    INTERRUPTED=1
    printf '%s\n' "${CURSOR_SHOW}"
    # Move below the status block so summary renders cleanly
    if $TTY_MODE; then
        printf '\n\n\n\n'
    fi
}
trap on_interrupt INT TERM

# ---- Progress helpers (TTY mode only) --------------------------------------
draw_bar() {
    local processed=$(( PASSED + FAILED + SKIPPED ))
    local pct=0
    local filled=0
    local empty=$BAR_WIDTH

    if (( TOTAL_FRAMES > 0 )); then
        pct=$(( processed * 100 / TOTAL_FRAMES ))
        filled=$(( processed * BAR_WIDTH / TOTAL_FRAMES ))
        empty=$(( BAR_WIDTH - filled ))
    fi

    local bar_filled=""
    local bar_empty=""
    local bar_frac=""
    local i

    # Build segments in chunks to avoid printf explosions
    for (( i=0; i<filled; i++ )); do bar_filled+="▓"; done
    for (( i=0; i<empty; i++ )); do bar_empty+="░"; done

    local elapsed=$(( $(date +%s) - TOTAL_START ))
    local elapsed_m=$(( elapsed / 60 ))
    local elapsed_s=$(( elapsed % 60 ))
    local eta_str="--"

    if (( processed > 0 )); then
        local sec_per_frame=$(( elapsed / processed ))
        local remaining=$(( TOTAL_FRAMES - processed ))
        local eta=$(( sec_per_frame * remaining ))
        local eta_m=$(( eta / 60 ))
        local eta_s=$(( eta % 60 ))
        eta_str="${eta_m}m${eta_s}s"
    fi

    printf '%s' "${ERASE_LINE}"
    printf "  Progress  %s${bar_empty}  %3d/%-3d  %3d%%\n" \
           "$bar_filled" "$processed" "$TOTAL_FRAMES" "$pct"
    printf '%s' "${ERASE_LINE}"
    printf "  ${GREEN}✓ %d passed${NC}  ${YELLOW}⏭ %d skipped${NC}  ${RED}✗ %d failed${NC}  ${DIM}⏳ %d to go${NC}\n" \
           "$PASSED" "$SKIPPED" "$FAILED" "$(( TOTAL_FRAMES - processed ))"
}

draw_current_frame() {
    local label="$1"   # "rendering" "done" "failed" "skipping" "interrupted"
    local frame="$2"
    local extra="$3"   # e.g. "(15s)" or "[ALF_PROGRESS 45%]"
    local color=""
    local icon=""

    case "$label" in
        rendering)   color="$CYAN";     icon="↻" ;;
        done)        color="$GREEN";    icon="✓" ;;
        failed)      color="$RED";      icon="✗" ;;
        skipping)    color="$DIM";      icon="⏭" ;;
        interrupted) color="$MAGENTA";  icon="⚠" ;;
        *)           color="$NC";       icon=" " ;;
    esac

    local elapsed=$(( $(date +%s) - TOTAL_START ))
    local elapsed_m=$(( elapsed / 60 ))
    local elapsed_s=$(( elapsed % 60 ))

    printf '%s' "${ERASE_LINE}"
    printf "  ${color}${icon} Frame %04d — %s${NC} %s ${DIM}· elapsed %dm%02ds${NC}\n" \
           "$frame" "$label" "$extra" "$elapsed_m" "$elapsed_s"
}

# ---- Per-frame husk progress watcher ---------------------------------------
# Polls a temp file that collects ALF_PROGRESS lines and triggers redraws.
# Uses a lightweight polling approach that works with any husk stream routing.
watch_husk_progress() {
    local f="$1"
    local progress_file="${RUN_DIR}/.progress_$(printf '%04d' "$f")"
    local last=""
    while kill -0 "$$" 2>/dev/null; do   # exit when parent shell dies
        local cur
        cur=$(cat "$progress_file" 2>/dev/null || true)
        if [[ "$cur" != "$last" ]]; then
            last="$cur"
            if [[ -n "$cur" ]]; then
                redraw_status "rendering" "$f" "[$cur]"
            fi
        fi
        sleep 0.3
    done
}

redraw_status() {
    local label="$1" frame="$2" extra="$3"
    if $TTY_MODE; then
        printf '\033[4A'     # move up to top of 4-line status block
    fi
    draw_bar                                 # 2 lines: progress bar + counters
    draw_current_frame "$label" "$frame" "$extra"  # 1 line: current activity
    printf '\n'                               # 1 line: spacer (4 total → no drift)
    if $TTY_MODE; then
        printf '%s' "${ERASE_DOWN}"           # clear any stale content below
    fi
}

# ---- Plain-text one-liner for non-TTY mode ---------------------------------
plain_status() {
    local label="$1" frame="$2" extra="$3"
    local processed=$(( PASSED + FAILED + SKIPPED ))
    local elapsed=$(( $(date +%s) - TOTAL_START ))
    local elapsed_m=$(( elapsed / 60 ))
    local elapsed_s=$(( elapsed % 60 ))
    echo "[$(date '+%H:%M:%S')] ${label}: frame ${frame} | ✓${PASSED} ✗${FAILED} ⏭${SKIPPED} | ${processed}/${TOTAL_FRAMES} | ${elapsed_m}m${elapsed_s}s ${extra}"
}

# ---- Dry-run guard ---------------------------------------------------------
if [[ "${DRY_RUN:-0}" = "1" ]]; then
    echo "DRY RUN — would render frames ${FRAME_FIRST} → ${FRAME_LAST}"
    echo "  scene:       ${SCENE}"
    echo "  resolution:  ${RESOLUTION}"
    echo "  verbosity:   ${VERBOSITY}"
    echo "  image mode:  ${IMAGE_MODE}"
    echo "  logs →       ${RUN_DIR}"
    echo "  stats →      ${STATS_CSV}"
    exit 0
fi

# ---- Banner (to log, and TTY gets the compact status block) ----------------
log_master "══════════════════════════════════════════════════════════"
log_master " Karma production render"
log_master "   Scene:  ${SCENE}"
log_master "   Frames: ${FRAME_FIRST} → ${FRAME_LAST}"
log_master "   Logs:   ${RUN_DIR}"
log_master "══════════════════════════════════════════════════════════"

# ---- Stats header (CSV) ----------------------------------------------------
echo "frame,start_time,end_time,elapsed_sec,exit_code,mem_peak" > "$STATS_CSV"

# ---- Initial terminal setup ------------------------------------------------
if $TTY_MODE; then
    printf '%s' "$CURSOR_HIDE"
    # Print header line + 3 blank status lines + 1 spacer
    printf '═ Karma · %s · %s · %s · %s ═\n' "$(basename "$SCENE")" "$RESOLUTION" "$IMAGE_MODE" "$VERBOSITY"
    printf '\n\n\n\n'  # 4 placeholder lines for the status block
fi

# ═══════════════════════════════════════════════════════════════════════════
#   RENDER LOOP
# ═══════════════════════════════════════════════════════════════════════════

for (( f=FRAME_FIRST; f<=FRAME_LAST; f++ )); do
    # Abort loop if user hit Ctrl+C
    if (( INTERRUPTED )); then
        log_master "Interrupted — stopping render loop"
        break
    fi

    FRAME_PAD="$(printf '%04d' "$f")"
    FRAME_LOG="${RUN_DIR}/frame_${FRAME_PAD}.log"
    OUTPUT_EXR="/mnt/data/Houdini/swirl-surface-tension/render/untitled.karmarendersettings.${FRAME_PAD}.exr"

    # --- Skip already-rendered frames ------------------------------------
    if [[ -f "$OUTPUT_EXR" ]]; then
        ((SKIPPED += 1))
        echo "${f},,,,skipped," >> "$STATS_CSV"
        log_master "Frame ${FRAME_PAD} already exists — skipping"
        if $TTY_MODE; then
            redraw_status "skipping" "$f" ""
        else
            plain_status "skip" "$f" ""
        fi
        continue
    fi

    # --- Render the frame ------------------------------------------------
    T0=$(date +%s)
    log_master "Rendering frame ${FRAME_PAD}/${FRAME_LAST}…"

    PROGRESS_FILE="${RUN_DIR}/.progress_${FRAME_PAD}"
    : > "$PROGRESS_FILE"   # clear from any previous run

    # Start a background watcher that redraws as ALF_PROGRESS updates
    WATCHER_PID=""
    if $TTY_MODE; then
        watch_husk_progress "$f" &
        WATCHER_PID=$!
        redraw_status "rendering" "$f" ""
    else
        plain_status "render" "$f" ""
    fi

    # Run husk:
    #   stdout + stderr merged → tee to per-frame log + filter ALF_PROGRESS → progress file
    #   pipefail ensures the pipeline exit code reflects husk's exit code
    if husk \
        -r ${RESOLUTION} \
        -f "$f" -n 1 \
        -V "$VERBOSITY" \
        --image-mode "$IMAGE_MODE" \
        --skip-existing-frames \
        --snapshot "$SNAPSHOT_INTERVAL" \
        --error-summary force \
        --make-output-path \
        "$SCENE" \
        2>&1 \
        | tee "$FRAME_LOG" \
        | { grep --line-buffered -oP 'ALF_PROGRESS\s+\d+%' || true; } \
        | while read -r p; do echo "$p" > "$PROGRESS_FILE"; done; then

        T1=$(date +%s)
        ELAPSED=$(( T1 - T0 ))
        ((PASSED += 1))
        log_success "Frame ${FRAME_PAD} done  (${ELAPSED}s)"

        MEM_PEAK=$(grep -oP 'peak memory:\s*\K[0-9.]+' "$FRAME_LOG" 2>/dev/null | tail -1 || echo "")
        echo "${f},${T0},${T1},${ELAPSED},0,${MEM_PEAK}" >> "$STATS_CSV"

        if $TTY_MODE; then
            redraw_status "done" "$f" "(${ELAPSED}s)"
        else
            plain_status "done" "$f" "(${ELAPSED}s)"
        fi

    else
        T1=$(date +%s)
        ELAPSED=$(( T1 - T0 ))
        EXIT_CODE=$?

        if (( INTERRUPTED )); then
            log_master "Frame ${FRAME_PAD} interrupted by user"
            echo "${f},${T0},${T1},${ELAPSED},SIGINT," >> "$STATS_CSV"
            if $TTY_MODE; then
                redraw_status "interrupted" "$f" "(${ELAPSED}s)"
            fi
            # Kill progress watcher
            [[ -n "${WATCHER_PID:-}" ]] && kill "$WATCHER_PID" 2>/dev/null || true
            [[ -n "${WATCHER_PID:-}" ]] && wait "$WATCHER_PID" 2>/dev/null || true
            rm -f "$PROGRESS_FILE"
            break
        fi

        ((FAILED += 1))
        log_fail "Frame ${FRAME_PAD} FAILED  (exit ${EXIT_CODE}, ${ELAPSED}s)"
        echo "${f},${T0},${T1},${ELAPSED},${EXIT_CODE}," >> "$STATS_CSV"

        # Append last 20 lines of the failed frame log to master for triage
        {
            echo "  --- last 20 lines of ${FRAME_LOG} ---"
            tail -20 "$FRAME_LOG" 2>/dev/null || true
            echo "  --- end ---"
        } >> "$MASTER_LOG"

        if $TTY_MODE; then
            redraw_status "failed" "$f" "(${ELAPSED}s, exit ${EXIT_CODE})"
        else
            plain_status "FAILED" "$f" "exit=${EXIT_CODE} ${ELAPSED}s"
        fi
    fi

    # Kill the progress watcher for this frame
    if [[ -n "${WATCHER_PID:-}" ]]; then
        kill "$WATCHER_PID" 2>/dev/null || true
        wait "$WATCHER_PID" 2>/dev/null || true
    fi
    # Clean up temp progress file
    rm -f "$PROGRESS_FILE"
done

# ═══════════════════════════════════════════════════════════════════════════
#   SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

TOTAL_END=$(date +%s)
TOTAL_ELAPSED=$(( TOTAL_END - TOTAL_START ))
TOTAL_MIN=$(( TOTAL_ELAPSED / 60 ))
TOTAL_SEC=$(( TOTAL_ELAPSED % 60 ))

# Restore cursor
printf '%s' "$CURSOR_SHOW"

# Move below the status block in TTY mode
if $TTY_MODE; then
    printf '\n\n'
fi

# Build a terminal-friendly summary
printf '\n'
printf '═══════════════════════════════════════\n'
printf '  RENDER COMPLETE\n'
printf '  ─────────────────────────────────\n'
printf '  %s✓ passed  %s%d%s\n'     "$GREEN" "$GREEN" "$PASSED" "$NC"
printf '  %s✗ failed  %s%d%s\n'     "$RED"   "$RED"   "$FAILED" "$NC"
printf '  %s⏭ skipped %s%d%s\n'     "$YELLOW" "$YELLOW" "$SKIPPED" "$NC"
printf '  ─────────────────────────────────\n'
printf '  Total frames: %d\n' "$TOTAL_FRAMES"
printf '  Wall time:    %dm %02ds\n' "$TOTAL_MIN" "$TOTAL_SEC"
printf '  Logs:         %s\n' "$RUN_DIR"
printf '  Stats:        %s\n' "$STATS_CSV"
printf '═══════════════════════════════════════\n'

if (( FAILED > 0 )); then
    printf '\n%s✗  %d FRAME(S) FAILED — see %s%s\n' "$RED" "$FAILED" "$FAILURE_LOG" "$NC"
fi

if (( INTERRUPTED )); then
    printf '\n%s⚠  Render was interrupted (Ctrl+C)%s\n' "$MAGENTA" "$NC"
fi

# Log summary to master log
{
    echo ""
    echo "──────────────────────────────────────────────────────────"
    echo " RENDER COMPLETE"
    echo "   Passed:     ${PASSED}"
    echo "   Failed:     ${FAILED}"
    echo "   Skipped:    ${SKIPPED}"
    echo "   Total time: ${TOTAL_MIN}m ${TOTAL_SEC}s"
    if (( INTERRUPTED )); then
        echo "   Stopped:    interrupted by user"
    fi
    echo "   Logs:       ${RUN_DIR}"
    echo "   Stats:      ${STATS_CSV}"
    echo "──────────────────────────────────────────────────────────"
} >> "$MASTER_LOG"

# ---- Post-render sanity checks ---------------------------------------------
log_master "Running output sanity checks…"
BAD_FRAMES=0
for (( f=FRAME_FIRST; f<=FRAME_LAST; f++ )); do
    FRAME_PAD="$(printf '%04d' "$f")"
    OUTPUT_EXR="/mnt/data/Houdini/swirl-surface-tension/render/untitled.karmarendersettings.${FRAME_PAD}.exr"

    if [[ ! -f "$OUTPUT_EXR" ]]; then
        continue
    fi

    SIZE=$(stat --printf="%s" "$OUTPUT_EXR" 2>/dev/null || echo "0")
    if (( SIZE < 1024 )); then
        log_fail "Frame ${FRAME_PAD}: file suspiciously small (${SIZE} bytes)"
        ((BAD_FRAMES += 1))
    fi
done

if (( BAD_FRAMES > 0 )); then
    log_fail "${BAD_FRAMES} frames have suspicious output — review ${FAILURE_LOG}"
    printf '%s⚠  %d frame(s) have suspiciously small output files%s\n' "$YELLOW" "$BAD_FRAMES" "$NC"
else
    log_master "All output files passed sanity check"
fi

exit $FAILED
