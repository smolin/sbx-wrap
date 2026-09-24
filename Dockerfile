FROM docker/sandbox-templates:opencode-docker

# Switch to root to install system packages
USER root

RUN \
    apt-get update && \
    apt-get install -y bash build-essential curl file libncurses-dev python3-playwright procps git && \
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

# Switch back to agent user for agent-specific tools
USER agent

# Install playwright
RUN \
    npm install -g playwright && \
    playwright install --with-deps firefox
