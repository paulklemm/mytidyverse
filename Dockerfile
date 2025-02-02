# Base image with Shiny Server and R 4.4.2
FROM rocker/shiny-verse:4.4.2

# System dependencies installation with cleanup
RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    # Core development tools
    build-essential gcc python3-dev python3-pip python3-venv \
    # System utilities
    git less procps tmux curl wget zsh gdebi-core keychain \
    # Compression tools
    pigz zstd \
    # Java stack
    default-jdk r-cran-rjava \
    # X11 dependencies
    xorg openbox \
    # Monitoring tools
    htop btop \
    # Bioinformatics dependencies
    libhdf5-dev libgeos-dev libgsl0-dev gsl-bin \
    # R package system dependencies
    libglpk-dev libudunits2-dev libxml2-dev libssl-dev \
    libcurl4-openssl-dev libcairo2-dev libfontconfig1-dev \
    libmagick++-dev libtesseract-dev libleptonica-dev \
    libpoppler-cpp-dev libmpfr-dev libzmq5 \
    libicu-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# Manual installation of libicu70 for tidyverse compatibility
RUN wget -q http://security.ubuntu.com/ubuntu/pool/main/i/icu/libicu70_70.1-2ubuntu1_amd64.deb && \
    dpkg -i libicu70_70.1-2ubuntu1_amd64.deb && \
    rm libicu70_70.1-2ubuntu1_amd64.deb

# Configure Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python package installation
RUN pip3 install --no-cache-dir \
    "pandas<2.0.0" \
    igraph openpyxl python-dateutil jupyter \
    visidata radian anndata scanpy scvi-tools

# R environment configuration
RUN R CMD javareconf  # Java integration for R packages

# Application setup
COPY shiny-server.sh /usr/bin/shiny-server.sh

# Network configuration
# Shiny Server
EXPOSE 3838
# RStudio Server
EXPOSE 8787

# Recommended runtime configuration
VOLUME /srv/shiny-server
VOLUME /var/lib/shiny-server
CMD ["/usr/bin/shiny-server.sh"]
