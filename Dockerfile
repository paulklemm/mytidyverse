FROM r-base

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
  # Being able to use the `R` documentation
  less \
  git \
  && apt-get clean

RUN Rscript -e 'install.packages(c("tidyverse", "devtools", "roxygen2", "ggrepel", "packrat")); source("https://bioconductor.org/biocLite.R"); biocLite(c("biomaRt", "clusterProfiler", "usethis"), suppressUpdates=TRUE, suppressAutoUpdate = TRUE)'

RUN pip3 install rtichoke

# Clone my .Rprofile https://gist.github.com/paulklemm/920bb2ee5d886ffe7a9fb743156f875d
RUN \
  git clone https://gist.github.com/920bb2ee5d886ffe7a9fb743156f875d.git && \
  cp 920bb2ee5d886ffe7a9fb743156f875d/.Rprofile ~/ && \
  rm -rf 920bb2ee5d886ffe7a9fb743156f875d
