#!/bin/bash
# level-monitor.sh - Monitor microphone input levels
#
# Outputs RMS level (0.0-1.0) to stdout every ~100ms
# Run with: hs.task for integration with Hammerspoon
#
# Usage:
#   level-monitor.sh              # Output to stdout
#   level-monitor.sh /path/file   # Also write to file
#
set -euo pipefail

OUTPUT_FILE="${1:-}"
SAMPLE_DURATION="0.1"  # 100ms samples

# Convert linear amplitude to dB, then normalize to 0-1 range
# Background noise is around -90dB, speech around -40dB to -10dB
normalize_level() {
  local linear=$1
  # Avoid log of zero
  if (( $(echo "$linear < 0.0000001" | bc -l) )); then
    echo "0.0"
    return
  fi
  # Convert to dB: 20 * log10(amplitude)
  local db=$(echo "20 * l($linear) / l(10)" | bc -l)
  # Map -90dB to -10dB -> 0.0 to 1.0 (80dB range)
  local normalized=$(echo "scale=3; ($db + 90) / 80" | bc -l)
  # Clamp to 0-1
  if (( $(echo "$normalized < 0" | bc -l) )); then
    echo "0.0"
  elif (( $(echo "$normalized > 1" | bc -l) )); then
    echo "1.0"
  else
    echo "$normalized"
  fi
}

while true; do
  # Capture short sample and extract RMS amplitude
  raw_level=$(sox -d -n trim 0 "$SAMPLE_DURATION" stat 2>&1 | rg "RMS.*amplitude" | awk '{print $3}' || echo "0")
  
  if [[ -n "$raw_level" && "$raw_level" != "0" ]]; then
    level=$(normalize_level "$raw_level")
    echo "$level"
    
    # Optionally write to file
    if [[ -n "$OUTPUT_FILE" ]]; then
      echo "$level" > "$OUTPUT_FILE"
    fi
  fi
done
