FROM r-base:3.5.1

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
  firefox \
  git \
  pandoc \
  && apt-get clean

# Configure java for R
RUN R CMD javareconf

RUN Rscript -e 'install.packages(c("tidyverse", "devtools", "roxygen2", "ggrepel", "packrat", "usethis", "WriteXLS", "here", "plotly", "svglite", "languageserver", "flexdashboard", "DT", "rJava"), repos = "http://cran.uni-muenster.de/"); source("https://bioconductor.org/biocLite.R"); biocLite(c("biomaRt", "clusterProfiler"), suppressUpdates=TRUE, suppressAutoUpdate = TRUE); devtools::install_github("rstudio/radix")'

RUN pip3 install rtichoke
