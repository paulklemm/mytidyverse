FROM rocker/tidyverse

RUN apt-get -qq update && \
  apt-get -qy install \
  python3-pip \
  && apt-get clean

RUN pip3 install rtichoke

# Clone my .Rprofile https://gist.github.com/paulklemm/920bb2ee5d886ffe7a9fb743156f875d
RUN \
  git clone https://gist.github.com/920bb2ee5d886ffe7a9fb743156f875d.git && \
  cp 920bb2ee5d886ffe7a9fb743156f875d/.Rprofile ~/ && \
  rm -rf 920bb2ee5d886ffe7a9fb743156f875d
