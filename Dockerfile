FROM docker/sandbox-templates:opencode-docker

# Switch to root to install system packages
USER root

RUN \
    apt-get update && \
    apt-get install -y bash build-essential cargo curl file git libncurses-dev python3-playwright procps rustc sqlite3 && \
    apt-get clean && \
    touch /.dockerenv && \
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /usr/bin/bash && \
    echo Done

# Download and run the opentofu installer script:
RUN \
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh && \
    chmod +x install-opentofu.sh && \
    ./install-opentofu.sh --install-method deb && \
    rm -f install-opentofu.sh && \
    echo Done

# Install go-task, ref https://taskfile.dev/docs/installation
RUN \
    curl -1sLf 'https://dl.cloudsmith.io/public/task/task/setup.deb.sh' | bash && \
    apt-get install -y task && \
    apt-get clean

# Switch back to agent user for agent-specific tools
USER agent

# Update opencode to the latest version
RUN \
    npm install -g opencode-ai@latest

# Install playwright
RUN \
    npm install -g playwright && \
    playwright install --with-deps firefox

# Extra tooling for friction-free work
RUN \
    sudo apt-get install -y python3.14-venv && \
    uv tool install pip-audit
