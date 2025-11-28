#!/bin/bash
# Script to fix comp_time_ms and decomp_time_ms in benchmark CSV
# The original benchmark.sh incorrectly parsed the elapsed time from /usr/bin/time -v

set -e

INPUT_CSV="output/2025-11-20_17-48-37/benchmark_results_2025-11-20_20-48-41.csv"
LOGS_DIR="output/2025-11-20_17-48-37/logs_2025-11-20_20-48-41"
OUTPUT_CSV="output/2025-11-20_17-48-37/benchmark_results_2025-11-20_20-48-41_fixed.csv"

# Function to parse elapsed time from time log file
# Time format: "0:01.38" means 0 min, 1.38 sec = 1380 ms
parse_time_ms() {
    local logfile="$1"
    if [[ -f "$logfile" ]]; then
        grep "Elapsed (wall clock)" "$logfile" | awk '{split($NF,a,/[:.]/); print int(a[1]*60000 + a[2]*1000 + a[3]*10)}'
    else
        echo "0"
    fi
}

# Read header and write to output
head -1 "$INPUT_CSV" > "$OUTPUT_CSV"

# Process each data row
tail -n +2 "$INPUT_CSV" | while IFS=, read -r algo filename run comp_time decomp_time rest; do
    # Construct log file paths
    comp_log="${LOGS_DIR}/${algo}_${filename}_run${run}_time_comp.txt"
    decomp_log="${LOGS_DIR}/${algo}_${filename}_run${run}_time_decomp.txt"

    # Parse correct times
    new_comp_time=$(parse_time_ms "$comp_log")
    new_decomp_time=$(parse_time_ms "$decomp_log")

    # Write corrected row
    echo "${algo},${filename},${run},${new_comp_time},${new_decomp_time},${rest}"
done >> "$OUTPUT_CSV"

echo "Fixed CSV written to: $OUTPUT_CSV"
echo "Sample of corrected times:"
head -5 "$OUTPUT_CSV" | column -t -s,
