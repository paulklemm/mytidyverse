# Base image: R 4.6.1 with Shiny Server and tidyverse
FROM rocker/shiny-verse:4.6.1

# Install system dependencies with minimal X11 requirements
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # Core development tools
    build-essential python3-dev python3-pip python3-venv \
    # System utilities
    git less procps tmux curl wget zsh keychain pandoc \
    # Compression tools
    pigz zstd \
    # Java stack
    default-jdk \
    # GIT LFS
    git-lfs \
    # Minimal X11 dependencies for forwarding
    xvfb xauth xfonts-base x11-xkb-utils \
    # Monitoring and debugging tools
    htop btop gdu duf sysstat lsof strace \
    # Bioinformatics dependencies
    libhdf5-dev libgeos-dev libgsl-dev gsl-bin \
    # Add Ripgrep
    ripgrep \
    # R package system dependencies
    libglpk-dev libudunits2-dev libxml2-dev libssl-dev \
    libcurl4-openssl-dev libcairo2-dev libfontconfig1-dev \
    libmagick++-dev libtesseract-dev libleptonica-dev \
    libpoppler-cpp-dev libmpfr-dev libzmq3-dev libicu-dev \
    libsodium-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Apptainer (Singularity)
# Nested use is limited: unprivileged `exec`/`pull` work on hosts with user
# namespaces; `fakeroot` builds generally don't work nested
ARG APPTAINER_VERSION="1.5.2"
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libfuse3-3 \
        fakeroot \
        squashfs-tools \
        cryptsetup \
        uidmap && \
    curl -fLO https://github.com/apptainer/apptainer/releases/download/v${APPTAINER_VERSION}/apptainer_${APPTAINER_VERSION}_amd64.deb && \
    apt-get install -y --no-install-recommends ./apptainer_${APPTAINER_VERSION}_amd64.deb && \
    rm apptainer_${APPTAINER_VERSION}_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Optionally, create a symlink for 'singularity' command
RUN ln -sf /usr/bin/apptainer /usr/local/bin/singularity

# SLURM user for HPC integration: the cluster's slurm-wlm client tools, config
# and munge socket are bind-mounted into the container at runtime (see Readme,
# "Using SLURM from inside the container"). Parsing slurm.conf requires the
# SlurmUser to resolve inside the container - create it with the host's uid.
RUN groupadd --system --gid 64030 slurm && \
    useradd --system --uid 64030 --gid slurm \
        --home-dir /nonexistent --shell /usr/sbin/nologin slurm

# Configure Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages
RUN pip3 install --no-cache-dir \
    pandas \
    igraph openpyxl python-dateutil jupyter \
    visidata radian anndata scanpy scvi-tools \
    nvitop turm

# Install Quarto CLI (pinned version)
ARG QUARTO_VERSION="1.9.38"
RUN curl -fLO https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./quarto-${QUARTO_VERSION}-linux-amd64.deb && \
    rm quarto-${QUARTO_VERSION}-linux-amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and npm (NodeSource; Ubuntu's packaged node is outdated)
ARG NODE_MAJOR="24"
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (pinned version; Ubuntu's packaged gh is outdated)
ARG GH_VERSION="2.100.0"
RUN curl -fLO https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./gh_${GH_VERSION}_linux_amd64.deb && \
    rm gh_${GH_VERSION}_linux_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure Java for R
RUN R CMD javareconf && \
    install2.r --error rJava

# Copy and configure Shiny Server
COPY shiny-server.sh /usr/bin/shiny-server.sh
RUN chmod +x /usr/bin/shiny-server.sh

# Expose ports
EXPOSE 3838

CMD ["/usr/bin/shiny-server.sh"]
