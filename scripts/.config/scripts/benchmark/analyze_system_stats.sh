#!/bin/bash
# sysstat — record system usage, show summary on Ctrl+C
# No deps beyond coreutils + procps (top)
#
# Usage: ./sysstat                    # record until Ctrl+C, then show summary
#        ./sysstat path/to/log        # analyze existing log

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/sysstat"
mkdir -p "$CACHE"

# ---------- analysis ----------

analyze() {
  awk '
    BEGIN {
      sc=0; cpu_us=0; cpu_sy=0; cpu_id=0; cpu_wa=0
      mem_free=0; mem_used=0; mem_cache=0; mem_total=0
      l1=0; l5=0; l15=0
      mx_cpu_us=0; mx_cpu_sy=0; mx_cpu_wa=0
      mx_mem_used=0; mn_mem_free=9999999; mx_load=0
    }
    /^=+ / { sc++; next }            # timestamp line marks new sample
    /^%Cpu/ {
      if (match($0, /([0-9.]+) us/)) { v=substr($0,RSTART,RLENGTH-3)+0; cpu_us+=v; if(v>mx_cpu_us)mx_cpu_us=v }
      if (match($0, /([0-9.]+) sy/)) { v=substr($0,RSTART,RLENGTH-3)+0; cpu_sy+=v; if(v>mx_cpu_sy)mx_cpu_sy=v }
      if (match($0, /([0-9.]+) id/)) { v=substr($0,RSTART,RLENGTH-3)+0; cpu_id+=v }
      if (match($0, /([0-9.]+) wa/)) { v=substr($0,RSTART,RLENGTH-3)+0; cpu_wa+=v; if(v>mx_cpu_wa)mx_cpu_wa=v }
      next
    }
    /^MiB Mem/ {
      gsub(/,/,"")
      if (match($0, /([0-9.]+) used/)) { v=substr($0,RSTART,RLENGTH-5)+0; mem_used+=v; if(v>mx_mem_used)mx_mem_used=v }
      if (match($0, /([0-9.]+) free/)) { v=substr($0,RSTART,RLENGTH-5)+0; mem_free+=v; if(v<mn_mem_free)mn_mem_free=v }
      if (match($0, /([0-9.]+) buff\/cache/)) { v=substr($0,RSTART,RLENGTH-11)+0; mem_cache+=v }
      if (match($0, /([0-9.]+) total/)) mem_total=substr($0,RSTART,RLENGTH-6)+0
      next
    }
    /load average:/ {
      if (match($0, /load average: ([0-9.]+), ([0-9.]+), ([0-9.]+)/, a)) {
        l1+=a[1]+0; l5+=a[2]+0; l15+=a[3]+0
        if(a[1]+0>mx_load)mx_load=a[1]+0
      }
      next
    }
    END {
      if (sc==0) { print "No samples."; exit }
      printf "\n  \360\237\223\212  SYSTEM STATS  (%d samples, ~%d min)\n", sc, sc
      printf "  \342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\342\200\225\n"
      printf "  CPU   user  %5.1f%%  (peak %5.1f%%)\n", cpu_us/sc, mx_cpu_us
      printf "        sys   %5.1f%%  (peak %5.1f%%)\n", cpu_sy/sc, mx_cpu_sy
      printf "        idle  %5.1f%%\n", cpu_id/sc
      printf "        iowait %5.1f%%  (peak %5.1f%%)\n", cpu_wa/sc, mx_cpu_wa
      pct=(mem_used/sc)/mem_total*100
      printf "  Mem   used  %6.0f MiB  (%4.1f%%)  (peak %6.0f MiB)\n", mem_used/sc, pct, mx_mem_used
      printf "        free  %6.0f MiB  (%4.1f%%)  (min  %6.0f MiB)\n", mem_free/sc, (mem_free/sc)/mem_total*100, mn_mem_free
      printf "        cache %6.0f MiB\n", mem_cache/sc
      printf "  Load  1m    %.2f\n", l1/sc
      printf "        5m    %.2f\n", l5/sc
      printf "        15m   %.2f\n", l15/sc
      printf "        peak  %.2f\n", mx_load
      s=100
      if (cpu_us/sc > 60) s-=20
      if (pct > 80) s-=20
      if (l1/sc > 4) s-=20
      if (cpu_wa/sc > 10) s-=10
      printf "\n  Health: %d/100  %s\n", s, (s>=80?"  \360\237\237\242 Excellent":s>=60?"  \360\237\237\241 Good":s>=40?"  \360\237\237\240 Fair":"  \360\237\224\264 Poor")
      print ""
    }
  ' "$1"
}

# ---------- standalone analysis mode ----------

if [ $# -ge 1 ] && [ -f "$1" ]; then
  analyze "$1"
  exit
fi

# ---------- record mode ----------

LOG=$(mktemp "$CACHE/sysstat-XXXXXX.log")

cleanup() {
  echo
  (echo "=== $(date) ==="; LC_ALL=C top -bn1 -i | head -5; echo) >> "$LOG"
  echo "Stopped. $(grep -c '^===' "$LOG") samples collected."
  analyze "$LOG"
  rm -f "$LOG"
  exit
}
trap cleanup INT TERM

echo "Recording system stats… Ctrl+C to stop (live summary every sample)"
echo ""

count=0
while :; do
  (echo "=== $(date) ==="; LC_ALL=C top -bn1 -i | head -5; echo) >> "$LOG"
  ((count++))
    tput home
    tput ed
    echo "Recording system stats… (${count} sample(s) captured, Ctrl+C to stop)"
    analyze "$LOG"
  sleep 60
done
