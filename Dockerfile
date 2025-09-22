# Base image: R 4.5.1 with Shiny Server and tidyverse
FROM rocker/shiny-verse:4.5.1

# Install system dependencies with minimal X11 requirements
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # Core development tools
    build-essential gcc python3-dev python3-pip python3-venv \
    # System utilities
    git less procps tmux curl wget zsh gdebi-core keychain pandoc \
    # Compression tools
    pigz zstd \
    # Java stack
    default-jdk \
    # GIT LFS
    git-lfs \
    # Minimal X11 dependencies for forwarding
    xvfb xauth xfonts-base x11-xkb-utils \
    # Monitoring tools
    htop btop \
    # Bioinformatics dependencies
    libhdf5-dev libgeos-dev libgsl0-dev gsl-bin \
    # R package system dependencies
    libglpk-dev libudunits2-dev libxml2-dev libssl-dev \
    libcurl4-openssl-dev libcairo2-dev libfontconfig1-dev \
    libmagick++-dev libtesseract-dev libleptonica-dev \
    libpoppler-cpp-dev libmpfr-dev libzmq5 libicu-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Apptainer (Singularity)
RUN apt-get update && \
    apt-get install -y \
        libfuse3-3 \
        fakeroot \
        software-properties-common \
        squashfs-tools \
        cryptsetup \
        uidmap \
        wget && \
    wget https://github.com/apptainer/apptainer/releases/download/v1.3.0/apptainer_1.3.0_amd64.deb && \
    dpkg -i apptainer_1.3.0_amd64.deb && \
    rm apptainer_1.3.0_amd64.deb

# Optionally, create a symlink for 'singularity' command
RUN ln -s /usr/bin/apptainer /usr/local/bin/singularity

# Configure Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages
RUN pip3 install --no-cache-dir \
    "pandas<2.0.0" \
    igraph openpyxl python-dateutil jupyter \
    visidata radian anndata scanpy scvi-tools

# Install Quarto CLI (pinned version)
ARG QUARTO_VERSION="1.7.31"
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb && \
    gdebi --non-interactive quarto-${QUARTO_VERSION}-linux-amd64.deb && \
    rm quarto-${QUARTO_VERSION}-linux-amd64.deb

# Configure Java for R
RUN R CMD javareconf && \
    R -e "install.packages('rJava', repos='https://cloud.r-project.org')"

# Copy and configure Shiny Server
COPY shiny-server.sh /usr/bin/shiny-server.sh
RUN chmod +x /usr/bin/shiny-server.sh

# Expose ports
EXPOSE 3838 8787

# Runtime configuration
VOLUME ["/srv/shiny-server", "/var/lib/shiny-server"]

CMD ["/usr/bin/shiny-server.sh"]
