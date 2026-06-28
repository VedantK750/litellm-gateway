# LiteLLM AI gateway for Render, tuned to fit a 512 MiB instance.
# Pinned to an immutable SemVer release tag (NOT :main-latest / :main-stable) for
# supply-chain hygiene. Bump deliberately. Latest release as of this scaffold: v1.90.0.
FROM ghcr.io/berriai/litellm-database:v1.90.0

COPY config.yaml /app/config.yaml

# --- Memory tuning (the difference between booting and OOM on 512 MiB) ---
# MALLOC_ARENA_MAX: glibc allocates a separate heap "arena" per thread; uvicorn's
#   threadpool can spawn many, each reserving memory. Cap to 2 -> big RSS drop.
# MALLOC_TRIM_THRESHOLD_: return freed memory to the OS instead of hoarding it.
# TOKENIZERS_PARALLELISM / *_NUM_THREADS: stop tiktoken/tokenizers & math libs from
#   spinning up one thread per core (each thread = more arenas = more memory).
# WEB_CONCURRENCY=1: single worker process (no per-worker memory multiplication).
ENV MALLOC_ARENA_MAX=2 \
    MALLOC_TRIM_THRESHOLD_=100000 \
    TOKENIZERS_PARALLELISM=false \
    OMP_NUM_THREADS=1 \
    OPENBLAS_NUM_THREADS=1 \
    RAYON_NUM_THREADS=1 \
    WEB_CONCURRENCY=1 \
    LITELLM_LOG=ERROR \
    PORT=4000

EXPOSE 4000

# Explicit single worker; Render injects $PORT (we also default it to 4000 above).
CMD ["--config", "/app/config.yaml", "--port", "4000", "--num_workers", "1"]
