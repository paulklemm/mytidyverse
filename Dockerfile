FROM rocker/shiny:4.4.2

RUN apt-get -qq update && \
  # fix-broken: https://askubuntu.com/questions/1077298/depends-libnss3-23-26-but-23-21-1ubuntu4-is-to-be-installed
  DEBIAN_FRONTEND=noninteractive apt-get -qy install -f \
  python3-pip \
  # X11 Window system
  xorg \
  openbox \
  # enrichplot dependency
  libglpk-dev \
  # ggraph dependency (required for clusterProfiler)
  libudunits2-dev \
  # XML2 dependency (required for tidyverse)
  libxml2-dev \
  # httr dependency (required for tidyverse)
  libssl-dev \
  # curl dependency (required for tidyverse)
  libcurl4-openssl-dev \
  # svglite dependency (required for svg rmarkdown output)
  libcairo2-dev \
  # svglite dependency
  libfontconfig1-dev \
  # Being able to use the `R` documentation
  less \
  # Required for rjava
  default-jdk \
  r-cran-rjava \
  git \
  # Visidata requirements
  man \
  # Seurat requirements (Single Cell RNASeq package)
  libhdf5-dev \
  libgeos-dev \
  # Pigz for parallel gzip file reading and writing. See https://cloud.r-project.org/web/packages/vroom/vignettes/vroom.html and https://www.jimhester.com/post/2019-09-26-pipe-connections/
  pigz \
  # zstd. Recommended by Jim Hester. Check https://www.jimhester.com/post/2019-09-26-pipe-connections/. https://www.youtube.com/watch?time_continue=495&v=RYhwZW6ofbI
  zstd \
  # Allow rvisidata to open a new tmux pane inside an existing tmux session
  tmux \
  procps \
  # Required for gsl package, required by https://bioconductor.org/packages/release/bioc/html/TFBSTools.html (Jaspar Motif analysis)
  gsl-bin \
  libgsl0-dev \
  # Required for magick package
  libmagick++-dev \
  # Required for tesseract package
  libtesseract-dev libleptonica-dev libpoppler-cpp-dev tesseract-ocr-eng \
  # Required for rjags
  jags \
  # Required for Rmpfr which we need for Bayes stuff
  libmpfr-dev \
  # Required for Lukas' fibeR package
  libncurses5 \
  # Required for IRKernel (R kernel for Jupyter)
  libzmq5 \
  # Required for Quarto
  pandoc \
  pandoc-citeproc \
  curl \
  gdebi-core \
  zsh \
  # Git LFS
  git-lfs \
  # SSH client
  keychain \
  # Monitoring
  htop \
  btop \
  && apt-get clean

# Install languageserver for R to make it work with LSP
RUN R -e "install.packages(c('languageserver'), dependencies=TRUE)"

RUN pip3 install \
  # Pandas >2.0.0 not supported by scvi at the moment
  "pandas<2.0.0" \
  # Required for scvi
  igraph \
  openpyxl \
  python-dateutil \
  # Required to run Jupyter Notebooks
  jupyter

# Install Quarto
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
RUN gdebi --non-interactive quarto-linux-amd64.deb

# Visidata
RUN pip3 install visidata
# Install radian
RUN pip3 install radian
# Install sc-seq, reticulate, and Seurat dependencies for working with sc-seq files
RUN pip3 install anndata scanpy
# Install scvi for interfacing the hypomap packages
RUN pip3 install scvi-tools

# Configure java for R
RUN R CMD javareconf

# The shiny-server.sh file is provided with this repository and also from the rocker/shiny package https://github.com/rocker-org/shiny
COPY shiny-server.sh /usr/bin/shiny-server.sh

# Install Singularity
# Set environment variables
ENV GO_VERSION=1.17 \
    SINGULARITY_VERSION=3.8.3 \
    GOPATH=/go \
    PATH=/usr/local/go/bin:$PATH

# Install dependencies, Go, and build Singularity in one RUN statement
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libssl-dev uuid-dev libgpgme11-dev \
        squashfs-tools libseccomp-dev pkg-config wget \
    && wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz \
    && mkdir -p ${GOPATH}/src/github.com/sylabs \
    && git clone --depth 1 --branch v${SINGULARITY_VERSION} https://github.com/sylabs/singularity.git ${GOPATH}/src/github.com/sylabs/singularity \
    && cd ${GOPATH}/src/github.com/sylabs/singularity \
    && ./mconfig --without-suid && make -C ./builddir && make -C ./builddir install \
    && cd / && rm -rf ${GOPATH} \
    && apt-get purge -y --auto-remove build-essential wget \
    && rm -rf /var/lib/apt/lists/*

# This may be not required since we will start it as singularity image anyway
EXPOSE 8787
EXPOSE 3838
