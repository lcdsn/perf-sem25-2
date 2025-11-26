#!/bin/bash
set -e

# --- CONFIGURATION ---
ALGOS=("gzip" "bzip2" "xz" "zstd")
REPETITIONS=3
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')

INPUT_DIR="files"
OUTPUT_DIR="output"
LOGS_DIR="${OUTPUT_DIR}/logs_${TIMESTAMP}"
OUTPUT_FILE="${OUTPUT_DIR}/benchmark_results_${TIMESTAMP}.csv"

# --- PERF EVENTS ---
PERF_EVENTS="cycles,instructions,branches,branch-misses,cache-misses,context-switches,minor-faults,major-faults,task-clock"
IO_EVENTS="syscalls:sys_enter_read,syscalls:sys_enter_write"

# --- SETUP ---
mkdir -p "$OUTPUT_DIR" "$LOGS_DIR"

echo '--> Extracting files.tar.xz ...';
tar -xf ./files.tar.xz

echo "--- Starting Benchmark ---"
echo "Results: $OUTPUT_FILE"
echo "Logs: $LOGS_DIR"

# CSV header
echo "algorithm,filename,run,comp_time_ms,decomp_time_ms,orig_size_b,compressed_size_b,compression_ratio_pct,\
comp_cycles,comp_instructions,comp_branch_misses,comp_cache_misses,comp_minor_faults,comp_major_faults,\
comp_read_calls$comp_write_calls,\
decomp_cycles,decomp_instructions,decomp_branch_misses,decomp_cache_misses,decomp_minor_faults,decomp_major_faults,\
decomp_read_calls,decomp_write_calls" \
  > "$OUTPUT_FILE"


# --- HELPERS ---

collect_time_metrics() {
  local logfile="$1"
  local cmd="$2"

  printf "TIME CMD: %s\n" "$cmd"
  /usr/bin/time -v bash -c "$cmd" 2> "$logfile"
}

collect_perf_metrics() {
  local logfile="$1"
  local cmd="$2"

  printf "PERF CMD: %s\n" "$cmd"
  perf stat -e "${PERF_EVENTS},${IO_EVENTS}" -o "$logfile" -- bash -c "$cmd"
}

start_monitors() {
  local prefix="$1"
  vmstat 1 > "${LOGS_DIR}/${prefix}_vmstat.log" &
  VMSTAT_PID=$!
  iostat -d -x 1 > "${LOGS_DIR}/${prefix}_iostat.log" &
  IOSTAT_PID=$!
}

stop_monitors() {
  kill $VMSTAT_PID $IOSTAT_PID 2>/dev/null || true
  sleep 1
}

# --- MAIN LOOP ---

for FILE in "$INPUT_DIR"/*; do
  BASENAME=$(basename "$FILE")
  ORIGINAL_SIZE=$(stat -c %s "$FILE")

  echo ""
  echo "--- Processing file: $BASENAME ---"
  echo "    > Preloading file into cache..."
  cat "$FILE" > /dev/null

  for i in $(seq 1 $REPETITIONS); do
    for algo in "${ALGOS[@]}"; do

      echo "--- Algo=$algo | File=$BASENAME | Run $i/$REPETITIONS ---"

      case $algo in
        gzip)  EXT=".gz";  COMPRESS_CMD="gzip -f -k \"$FILE\"";                     DECOMPRESS_CMD="gzip -d -c \"${FILE}${EXT}\" > /dev/null";;
        bzip2) EXT=".bz2"; COMPRESS_CMD="bzip2 -f -k \"$FILE\"";                    DECOMPRESS_CMD="bzip2 -d -c \"${FILE}${EXT}\" > /dev/null";;
        xz)    EXT=".xz";  COMPRESS_CMD="xz -f -k \"$FILE\"";                       DECOMPRESS_CMD="xz -d -c \"${FILE}${EXT}\" > /dev/null";;
        zstd)  EXT=".zst"; COMPRESS_CMD="zstd -f -k \"$FILE\" -o \"${FILE}${EXT}\""; DECOMPRESS_CMD="zstd -d \"${FILE}${EXT}\" -o /dev/null";;
      esac

      COMPRESSED_FILENAME="${FILE}${EXT}"

      # ---------- COMPRESSION ----------
      echo "    > Running compression..."
      TIME_COMP_LOG="${LOGS_DIR}/${algo}_${BASENAME}_run${i}_time_comp.txt"
      PERF_COMP_LOG="${LOGS_DIR}/${algo}_${BASENAME}_run${i}_perf_comp.txt"

      start_monitors "${algo}_${BASENAME}_run${i}_compress"

      collect_time_metrics "$TIME_COMP_LOG" "$COMPRESS_CMD"
      collect_perf_metrics "$PERF_COMP_LOG" "$COMPRESS_CMD"

      stop_monitors

      COMP_TIME_MS=$(grep "Elapsed (wall clock)" "$TIME_COMP_LOG" | awk '{print $(NF-2)*60000 + $(NF-1)*1000}' || echo 0)
      COMPRESSED_SIZE=$(stat -c %s "$COMPRESSED_FILENAME")
      COMPRESSION_RATIO=$(awk "BEGIN {printf \"%.2f\", $COMPRESSED_SIZE*100/$ORIGINAL_SIZE}")

      # PERF extraction
      comp_cycles=$(grep 'cycles' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      comp_instr=$(grep 'instructions' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      comp_bmiss=$(grep 'branch-misses' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      comp_cachemiss=$(grep 'cache-misses' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      comp_minor=$(grep 'minor-faults' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      comp_major=$(grep 'major-faults' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      comp_read_calls=$(grep 'syscalls:sys_enter_read' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      comp_write_calls=$(grep 'syscalls:sys_enter_write' "$PERF_COMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')

      # ---------- DECOMPRESSION ----------
      echo "    > Running decompression..."
      TIME_DECOMP_LOG="${LOGS_DIR}/${algo}_${BASENAME}_run${i}_time_decomp.txt"
      PERF_DECOMP_LOG="${LOGS_DIR}/${algo}_${BASENAME}_run${i}_perf_decomp.txt"

      start_monitors "${algo}_${BASENAME}_run${i}_decompress"

      collect_time_metrics "$TIME_DECOMP_LOG" "$DECOMPRESS_CMD"
      collect_perf_metrics "$PERF_DECOMP_LOG" "$DECOMPRESS_CMD"

      stop_monitors

      DECOMP_TIME_MS=$(grep "Elapsed (wall clock)" "$TIME_DECOMP_LOG" | awk '{print $(NF-2)*60000 + $(NF-1)*1000}' || echo 0)

      # PERF decomp
      decomp_cycles=$(grep 'cycles' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      decomp_instr=$(grep 'instructions' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      decomp_bmiss=$(grep 'branch-misses' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      decomp_cachemiss=$(grep 'cache-misses' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      decomp_minor=$(grep 'minor-faults' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      decomp_major=$(grep 'major-faults' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      decomp_read_calls=$(grep 'syscalls:sys_enter_read' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')
      decomp_write_calls=$(grep 'syscalls:sys_enter_write' "$PERF_DECOMP_LOG" | head -1 | awk '{print $1}' | tr -d ',')

      # ---------- SAVE CSV ROW ----------
      echo "$algo,$BASENAME,$i,$COMP_TIME_MS,$DECOMP_TIME_MS,$ORIGINAL_SIZE,$COMPRESSED_SIZE,$COMPRESSION_RATIO,\
$comp_cycles,$comp_instr,$comp_bmiss,$comp_cachemiss,$comp_minor,$comp_major,$comp_read_calls,$comp_write_calls,\
$decomp_cycles,$decomp_instr,$decomp_bmiss,$decomp_cachemiss,$decomp_minor,$decomp_major,$decomp_read_calls,$decomp_write_calls" \
        >> "$OUTPUT_FILE"

      rm -f "$COMPRESSED_FILENAME"
      sleep 1

    done
  done

  echo "    > Clearing caches..."
  sync && echo 3 > /proc/sys/vm/drop_caches
done

echo "--- Benchmark complete! ---"
