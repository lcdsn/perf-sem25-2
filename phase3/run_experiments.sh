#!/bin/bash
set -e

# --- Configuration ---
IMAGE_NAME="compression-test-env2"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
OUTPUT_DIR="output/${TIMESTAMP}"

echo "--- Compression Benchmark Runner ---"

echo "--> Step 1: Building the Docker image ('${IMAGE_NAME}')..."
docker build -t ${IMAGE_NAME} .

echo "--> Step 2: Preparing the output directory ('${OUTPUT_DIR}')..."
mkdir -p ${OUTPUT_DIR}

echo "--> Step 3: Running the benchmark container..."

docker run \
  --rm \
  --privileged \
  -v "$(pwd)/${OUTPUT_DIR}":/app/output \
  ${IMAGE_NAME}

echo ""
echo "--- Benchmark complete! ---"
echo "Logs are available in './${OUTPUT_DIR}'"
