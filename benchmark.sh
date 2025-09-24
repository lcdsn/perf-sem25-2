#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- CONFIGURATION ---
ALGOS=("gzip" "bzip2" "xz" "zstd")
SIZES_MB=(10 100 1000)
REPETITIONS=3
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
OUTPUT_DIR="/output" 
OUTPUT_FILE="${OUTPUT_DIR}/benchmark_results_${TIMESTAMP}.csv"
LOGS_DIR="${OUTPUT_DIR}/logs_${TIMESTAMP}"
PERF_EVENTS="task-clock,context-switches,cpu-migrations,page-faults,cycles,instructions,branches,branch-misses"

# --- SCRIPT SETUP ---

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root to clear the system page cache." 
   exit 1
fi

echo "algorithm,size_mb,run,compression_time_ms,decompression_time_ms,original_size_b,compressed_size_b,compression_ratio_pct,comp_cycles,comp_instructions,comp_branch_misses,decomp_cycles,decomp_instructions,decomp_branch_misses" > $OUTPUT_FILE
mkdir -p $LOGS_DIR

echo "--- Starting Benchmark ---"
echo "Results will be saved to: ${OUTPUT_FILE}"
echo "Detailed logs will be saved in: ${LOGS_DIR}"

# --- MONITORING FUNCTIONS ---
VMSTAT_PID=0
IOSTAT_PID=0

start_monitors() {
  local log_prefix=$1
  vmstat 1 > "${LOGS_DIR}/${log_prefix}_vmstat.log" &
  VMSTAT_PID=$!
  iostat -d -x 1 > "${LOGS_DIR}/${log_prefix}_iostat.log" &
  IOSTAT_PID=$!
}

stop_monitors() {
  kill $VMSTAT_PID $IOSTAT_PID
  # Wait briefly to ensure processes are killed before the next step
  sleep 1
}

# --- MAIN LOGIC ---

for size in "${SIZES_MB[@]}"; do
  FILENAME="testfile_${size}M.bin"
  echo "--- Generating master test file: ${FILENAME} ---"
  dd if=/dev/urandom of=$FILENAME bs=1M count=$size status=progress
  ORIGINAL_SIZE=$(stat -c%s "$FILENAME")

  for algo in "${ALGOS[@]}"; do
    for i in $(seq 1 $REPETITIONS); do
      echo "--- Testing: Size=${size}M | Algo=${algo} | Run=${i}/${REPETITIONS} ---"
      LOG_PREFIX="${algo}_${size}M_run${i}"

      case $algo in
        gzip) EXT=".gz"; COMPRESS_CMD="gzip -f -k $FILENAME"; DECOMPRESS_CMD="gzip -d -c ${FILENAME}${EXT} > /dev/null";;
        bzip2) EXT=".bz2"; COMPRESS_CMD="bzip2 -f -k $FILENAME"; DECOMPRESS_CMD="bzip2 -d -c ${FILENAME}${EXT} > /dev/null";;
        xz) EXT=".xz"; COMPRESS_CMD="xz -f -k $FILENAME"; DECOMPRESS_CMD="xz -d -c ${FILENAME}${EXT} > /dev/null";;
        zstd) EXT=".zst"; COMPRESS_CMD="zstd -f -k $FILENAME"; DECOMPRESS_CMD="zstd -d -c ${FILENAME}${EXT} > /dev/null";;
      esac
      
      COMPRESSED_FILENAME="${FILENAME}${EXT}"

      # 1. --- COMPRESSION TEST ---
      echo "    > Clearing caches and running compression..."
      sync && echo 3 > /proc/sys/vm/drop_caches
      
      start_monitors "${LOG_PREFIX}_compress"
      perf stat -e $PERF_EVENTS -o perf_compress.txt -- $COMPRESS_CMD
      stop_monitors
      
      COMP_TIME_MS=$(grep 'task-clock' perf_compress.txt | awk '{print $1}' | tr -d ','); COMP_CYCLES=$(grep 'cycles' perf_compress.txt | awk '{print $1}' | tr -d ','); COMP_INSTRUCTIONS=$(grep 'instructions' perf_compress.txt | awk '{print $1}' | tr -d ','); COMP_BRANCH_MISSES=$(grep 'branch-misses' perf_compress.txt | awk '{print $1}' | tr -d ',')
      COMPRESSED_SIZE=$(stat -c%s "$COMPRESSED_FILENAME"); COMPRESSION_RATIO=$(awk "BEGIN {printf \"%.2f\", $COMPRESSED_SIZE*100/$ORIGINAL_SIZE}")

      # 2. --- DECOMPRESSION TEST ---
      echo "    > Clearing caches and running decompression..."
      sync && echo 3 > /proc/sys/vm/drop_caches

      start_monitors "${LOG_PREFIX}_decompress"
      perf stat -e $PERF_EVENTS -o perf_decompress.txt -- bash -c "$DECOMPRESS_CMD"
      stop_monitors

      DECOMP_TIME_MS=$(grep 'task-clock' perf_decompress.txt | awk '{print $1}' | tr -d ','); DECOMP_CYCLES=$(grep 'cycles' perf_decompress.txt | awk '{print $1}' | tr -d ','); DECOMP_INSTRUCTIONS=$(grep 'instructions' perf_decompress.txt | awk '{print $1}' | tr -d ','); DECOMP_BRANCH_MISSES=$(grep 'branch-misses' perf_decompress.txt | awk '{print $1}' | tr -d ',')
      
      # 3. --- SAVE RESULTS ---
      echo "    > Saving results..."
      echo "$algo,$size,$i,$COMP_TIME_MS,$DECOMP_TIME_MS,$ORIGINAL_SIZE,$COMPRESSED_SIZE,$COMPRESSION_RATIO,$COMP_CYCLES,$COMP_INSTRUCTIONS,$COMP_BRANCH_MISSES,$DECOMP_CYCLES,$DECOMP_INSTRUCTIONS,$DECOMP_BRANCH_MISSES" >> $OUTPUT_FILE

      # 4. --- CLEAN UP FOR NEXT RUN ---
      rm $COMPRESSED_FILENAME
    done
  done
  rm $FILENAME
done

echo "--- Benchmark complete! ---"
