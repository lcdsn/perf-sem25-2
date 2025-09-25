FROM debian:bookworm-slim@sha256:acd98e6cfc42813a4db9ca54ed79b6f702830bfc2fa43a2c2e87517371d82edb

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     bzip2=1.0.8-5+b1 \
     gzip=1.12-1 \
     xz-utils=5.4.1-1 \
     zstd=1.5.4+dfsg2-5 \
     python3=3.11.2-1+b1 \
     sysstat=12.6.1-1 \
     procps=2:4.0.2-3 \
     coreutils=9.1-1 \
     linux-perf=6.1.153-1 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY a_tale_of_two_cities.txt markov_text_generator.py run_generator.py ./

# Copy the benchmark script into the image's executable path
COPY benchmark.sh /usr/local/bin/benchmark.sh

# Make the script executable
RUN chmod +x /usr/local/bin/benchmark.sh

CMD [ "benchmark.sh" ]
