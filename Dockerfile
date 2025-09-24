FROM debian:bookworm-slim@sha256:acd98e6cfc42813a4db9ca54ed79b6f702830bfc2fa43a2c2e87517371d82edb

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      bzip2=1.0.8-5+b1 \
      gzip=1.12-1 \
      xz-utils=5.4.1-1 \
      zstd=1.5.4+dfsg2-5 \
      linux-perf \
      sysstat \
      procps \
      coreutils \
  && rm -rf /var/lib/apt/lists/*

# Copy the benchmark script into the image's executable path
COPY benchmark.sh /usr/local/bin/benchmark.sh

# Make the script executable
RUN chmod +x /usr/local/bin/benchmark.sh

# Set the default command to run the script
CMD [ "benchmark.sh" ]
