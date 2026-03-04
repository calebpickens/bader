#!/bin/bash

# Usage: ./benchmark_bader.sh path/to/CHGCAR
CHGCAR_PATH=$1

if [ ! -f "$CHGCAR_PATH" ]; then
    echo "Error: CHGCAR file not found at $CHGCAR_PATH"
    exit 1
fi

TEST_NAME=$(basename $(dirname "$CHGCAR_PATH"))
BASE_DIR="./parallelization_output"
OUTPUT_DIR="$BASE_DIR/$TEST_NAME"

mkdir -p "$OUTPUT_DIR"

RESULTS_FILE="$OUTPUT_DIR/results.log"
echo "Bader Parallelization Benchmark - $(date)" > "$RESULTS_FILE"
echo "Testing file: $CHGCAR_PATH" >> "$RESULTS_FILE"
echo "------------------------------------------------" >> "$RESULTS_FILE"
printf "%-10s | %-15s | %-10s\n" "Threads" "Time (Seconds)" "Consistency" >> "$RESULTS_FILE"

THREAD_COUNTS=(1 2 4 8)

for T in "${THREAD_COUNTS[@]}"; do
    LOG_FILE="$OUTPUT_DIR/bader_${T}thread.log"
    ACF_FILE="$OUTPUT_DIR/ACF_${T}t.dat"
    
    echo "Running $TEST_NAME with $T threads..."
    
    START_TIME=$(date +%s.%N)
    ./bader "$CHGCAR_PATH" -cp -threads "$T" > "$LOG_FILE" 2>&1
    END_TIME=$(date +%s.%N)
    
    ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
    mv ACF.dat "$ACF_FILE"
    
    if [ "$T" -eq "${THREAD_COUNTS[0]}" ]; then
        CONSISTENCY="Baseline"
    else
        if diff "$OUTPUT_DIR/ACF_1t.dat" "$ACF_FILE" > /dev/null; then
            CONSISTENCY="PASSED"
        else
            CONSISTENCY="FAILED"
        fi
    fi
    
    printf "%-10s | %-15s | %-10s\n" "$T" "$ELAPSED" "$CONSISTENCY" >> "$RESULTS_FILE"
done

echo "------------------------------------------------" >> "$RESULTS_FILE"
echo "Benchmark for $TEST_NAME complete. See $RESULTS_FILE"
