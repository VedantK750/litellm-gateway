# LiteLLM AI gateway for Render.
# Pinned to an immutable SemVer stable tag (NOT :main-latest / :main-stable) for
# supply-chain hygiene. Bump deliberately. Latest stable as of this scaffold: v1.90.0.
FROM ghcr.io/berriai/litellm-database:v1.90.0-stable

COPY config.yaml /app/config.yaml

# Render injects $PORT; default to 4000 locally. The image's entrypoint is the
# litellm CLI, so we only pass args here.
CMD ["--config", "/app/config.yaml", "--port", "4000"]
