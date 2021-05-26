FROM rocker/r-ver:4.1.0

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
  # Shiny requirements
  pandoc \
  pandoc-citeproc \
  sudo \
  gdebi-core \
  libxt-dev \
  wget \
  # Visidata requirements
  man \
  # Seurat requirements (Single Cell RNASeq package)
  libhdf5-dev \
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
  ibmagick++-dev \
  # Required for rjags
  jags \
  && apt-get clean

# Install Visidata. Check https://github.com/saulpw/visidata/blob/stable/requirements.txt
RUN pip3 install \ 
  # dta (Stata)
  pandas \
  # http
  requests \
  # html/xml
  lxml \
  # xlsx
  openpyxl \
  # xls
  xlrd \
  # hdf5
  h5py \
  # postgres
  # HACK: 3.5.3-1: Does not work, so we excluded it
  # psycopg2 \
  # shapefiles
  pyshp \
  # mbtiles
  mapbox-vector-tile \
  # png
  pypng \
  # ttf/otf
  fonttools \
  # sas7bdat (SAS)
  sas7bdat \
  # xpt (SAS)
  xport \
  # sav (SPSS)
  savReaderWriter \
  # yaml/yml
  PyYAML \
  # pcap
  dpkt \
  # pcap
  dnslib \
  # graphviz
  namestand \
  python-dateutil

# Visidata 2 pre-release
RUN pip3 install visidata
# Install radian
RUN pip3 install radian

# Configure java for R
RUN R CMD javareconf

# Download and install shiny server. This code is from the rocker/shiny container https://github.com/rocker-org/shiny
# The only thing I changed is setting the repo to the Uni Münster mirror
RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
  VERSION=$(cat version.txt)  && \
  wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
  gdebi -n ss-latest.deb && \
  rm -f version.txt ss-latest.deb && \
  . /etc/environment && \
  R -e "install.packages(c('shiny', 'rmarkdown'), repos='http://cran.uni-muenster.de/')" && \
  cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

# This may be not required since we will start it as singularity image anyway
EXPOSE 3838

# The shiny-server.sh file is provided with this repository and also from the rocker/shiny package https://github.com/rocker-org/shiny
COPY shiny-server.sh /usr/bin/shiny-server.sh

EXPOSE 8787
