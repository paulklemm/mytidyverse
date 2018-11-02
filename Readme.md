# Custom Tidyverse Docker Image

My development `tidyverse` image is based on [r-base](https://hub.docker.com/_/r-base/).

You can start a shiny server using `shiny-server.sh`. For details, check the [rocker/shiny](https://github.com/rocker-org/shiny) repo.

It adds:

- [rtichoke](https://github.com/randy3k/rtichoke) as `R` console replacement
- My `.Rprofile` from [this gist](https://gist.github.com/paulklemm/920bb2ee5d886ffe7a9fb743156f875d)
