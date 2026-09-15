FROM node:24-bookworm-slim

# Ferramentas básicas de shell
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Codex CLI
RUN npm install -g @openai/codex

WORKDIR /workspace

CMD ["bash"]
