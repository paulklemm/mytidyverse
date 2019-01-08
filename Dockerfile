FROM r-base:3.5.2

RUN apt-get -qq update && \
  DEBIAN_FRONTEND=noninteractive apt-get -qy install \
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
  # svglite dependency (required for svg rmarkdown outout)
  libcairo2-dev \
  # Being able to use the `R` documentation
  less \
  # Required for rjava
  default-jdk \
  r-cran-rjava \
  # Being able to open plotly plots
  # Currently firefox cannot be installed for some weird reason. Used the hack below for it
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
  && apt-get clean

# HACK for installing firefox
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy install -t sid firefox

# Install Visidata
RUN pip3 install PyYAML pypng requests psycopg2 openpyxl xlrd h5py fonttools mapbox lxml xport sas7bdat pandas pyshp python-dateutil visidata

# Configure java for R
RUN R CMD javareconf

RUN Rscript -e 'install.packages(c("tidyverse", "devtools", "roxygen2", "ggrepel", "packrat", "usethis", "WriteXLS", "here", "plotly", "svglite", "languageserver", "flexdashboard", "DT", "rJava"), repos = "http://cran.uni-muenster.de/"); source("https://bioconductor.org/biocLite.R"); biocLite(c("biomaRt", "clusterProfiler"), suppressUpdates=TRUE, suppressAutoUpdate = TRUE); devtools::install_github("rstudio/radix"); devtools::install_github("paulklemm/mygo"); devtools::install_github("paulklemm/rmyknife"); devtools::install_github("paulklemm/peekr"); devtools::install_github("paulklemm/rvisidata");'

# Download and install shiny server. This code is from the rocker/shiny container https://github.com/rocker-org/shiny
# The only thing I changed is setting the repo to the Uni Münster mirror
# 2019-01-08 Currently the rocker version of the installation does not download the latest shiny server.
# This leads to a weird crash when the script sets up the server. As a workaround I set the download repo hard.
# I should swich back later to check if everything works fine again
# RUN wget --no-verbose https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
#   VERSION=$(cat version.txt)  && \
#   wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
#   gdebi -n ss-latest.deb && \
#   rm -f version.txt ss-latest.deb && \
#   . /etc/environment && \
#   R -e "install.packages(c('shiny', 'rmarkdown'), repos='http://cran.uni-muenster.de/')" && \
#   cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/
# Link from here: https://www.rstudio.com/products/shiny/download-server/
RUN wget --no-verbose "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.9.923-amd64.deb" -O ss-latest.deb && \
  gdebi -n ss-latest.deb && \
  rm -f ss-latest.deb && \
  . /etc/environment && \
  R -e "install.packages(c('shiny', 'rmarkdown'), repos='http://cran.uni-muenster.de/')" && \
  cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

# This may be not required since we will start it as singularity image anyway
EXPOSE 3838

# The shiny-server.sh file is provided with this repository and also from the rocker/shiny package https://github.com/rocker-org/shiny
COPY shiny-server.sh /usr/bin/shiny-server.sh

RUN pip3 install rtichoke
