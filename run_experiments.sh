#!/bin/bash
set -e

# --- Configuration ---
IMAGE_NAME="compression-test-env"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
OUTPUT_DIR="output/${TIMESTAMP}"

# --- Script Logic ---
echo "--- Compression Benchmark Runner ---"

echo "--> Step 1: Building the Docker image ('${IMAGE_NAME}')..."
docker build -t ${IMAGE_NAME} .

echo "--> Step 2: Preparing the output directory ('${OUTPUT_DIR}')..."
mkdir -p ${OUTPUT_DIR}

echo "--> Step 3: Running the benchmark container..."
docker run \
  --rm \
  --privileged \
  -v "$(pwd)/${OUTPUT_DIR}":/output \
  ${IMAGE_NAME}

echo ""
echo "--- Benchmark complete! ---"
echo "Results and logs can be found in the './${OUTPUT_DIR}' directory."
