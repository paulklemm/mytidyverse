FROM r-base:4.0.2

RUN apt-get -qq update && \
  # fix-broken: https://askubuntu.com/questions/1077298/depends-libnss3-23-26-but-23-21-1ubuntu4-is-to-be-installed
  DEBIAN_FRONTEND=noninteractive apt-get -qy install -f \
  python3-pip \
  # X11 Window system
  xorg \
  openbox \
  # ggraph dependency (required for clusterProfiler)
  libudunits2-dev \
  # XML2 dependency (required for tidyverse)
  libxml2-dev \
  # httr dependency (required for tidyverse)
  libssl-dev \
  # curl dependency (required for tidyverse)
  libcurl4-openssl-dev \
  # svglite dependency (required for svg rmarkdown output)
  # In 3.6.2-1, libcairo2-dev broke the dependency tree, so we removed it
  # libcairo2-dev \
  # svglite dependency
  # In 4.0.2-1, libfontconfig1-dev broke the dependency tree, so we removed it
  # libfontconfig1-dev \
  # Being able to use the `R` documentation
  less \
  # Required for rjava
  default-jdk \
  r-cran-rjava \
  # Being able to open plotly plots
  # firefox \
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
  # RStudio Server dependency
  libclang-dev \
  && apt-get clean

# HACK for installing firefox
# RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install -t sid firefox

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
RUN pip3 install git+https://github.com/saulpw/visidata@v2.-3.0
# Install radian
RUN pip3 install radian

# Configure java for R
RUN R CMD javareconf

# Fix GenomicAlignments install error. See https://github.com/paulklemm/mytidyverse/issues/3
# RUN Rscript -e 'install.packages("BiocManager", repos = "http://cloud.r-project.org/"); BiocManager::install("GenomicAlignments")'
# 2020-04-09 Do not ship the package with any R package installed. Use renv for package management
# # Install CRAN R packages
# RUN Rscript -e 'install.packages(c("devtools", "tidyverse", "roxygen2", "ggrepel", "renv", "usethis", "WriteXLS", "plotly", "svglite", "languageserver", "flexdashboard", "DT", "rJava", "Seurat", "styler", "knitr", "rmarkdown", "vroom", "tidylog", "drake"), repos = "http://cloud.r-project.org/")'
# # Install Bioconductor R packages
# RUN Rscript -e 'BiocManager::install(c("biomaRt", "clusterProfiler", "DESeq2"), update = TRUE, ask = FALSE)'
# # Install GitHub R packages
# RUN Rscript -e 'remotes::install_github("yihui/xaringan"); devtools::install_github("paulklemm/rmyknife"); devtools::install_github("paulklemm/mygo"); devtools::install_github("paulklemm/rvisidata");'

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
# Link from here: https://www.rstudio.com/products/shiny/download-server/
# 2019-01-08 Currently the rocker version of the installation does not download the latest shiny server.
# This leads to a weird crash when the script sets up the server. As a workaround I set the download repo hard.
# I should swich back later to check if everything works fine again
# RUN wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.9.923-amd64.deb" -O ss-latest.deb && \
#   gdebi -n ss-latest.deb && \
#   rm -f ss-latest.deb && \
#   . /etc/environment && \
#   R -e "install.packages(c('shiny', 'rmarkdown'), repos='http://cloud.r-project.org/')" && \
#   cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

# This may be not required since we will start it as singularity image anyway
EXPOSE 3838

# The shiny-server.sh file is provided with this repository and also from the rocker/shiny package https://github.com/rocker-org/shiny
COPY shiny-server.sh /usr/bin/shiny-server.sh

# Install RStudio Server
RUN wget https://www.rstudio.org/download/latest/stable/server/bionic/rstudio-server-latest-amd64.deb && \
  sudo gdebi --non-interactive rstudio-server-latest-amd64.deb

EXPOSE 8787
