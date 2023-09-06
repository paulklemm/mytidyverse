# 🐳 𝓡 Custom Tidyverse Docker Image

---

<!-- TOC depthFrom:2 -->

- [Installed Dependencies](#installed-dependencies)
- [Build the Image](#build-the-image)
- [Changelog](#changelog)

<!-- /TOC -->

---

[My](https://github.com/paulklemm/) development `tidyverse` image is based on [r-base](https://hub.docker.com/_/r-base/).

## Installed Dependencies

It adds:

- [radian](https://github.com/randy3k/radian) as `R` console replacement
- [shiny server](https://hub.docker.com/r/rocker/shiny)
  - You can start a shiny server using `shiny-server.sh`
  - For details, check the [rocker/shiny](https://github.com/rocker-org/shiny) repo
- [visidata](https://visidata.org/) for the [rvisidata](https://github.com/paulklemm/rvisidata) package
- A whole bunch of libraries for a number of different R packages, mostly for bioinformatics analyses

## Build the Image

Run the building process manually using the following code (adapting the version).

```bash
docker login
docker build --no-cache -t mytidyverse .
docker tag mytidyverse paulklemm/mytidyverse:base-4.3.1-1
docker push paulklemm/mytidyverse:base-4.3.1-1
```

You can also use the makefile.

```bash
make VERSION=4.3.1-1
```

## Changelog

- *2023-09-06*
  - Bump to 4.3.1
  - Add `scvi` tools to interface HypoMap packages
- *2022-08-03*
  - Add `libgeos-dev` dependency required for Seurat
- *2022-08-02*
  - Add `libncurses5` to comply with Lukas' `fibeR` package
  - Bump to 4.2.1
- *2022-02-25*
  - Add `anndata` and `scanpy` python modules
  - Bump to 4.1.2
- *2021-09-03*
  - Fix requirements for magick and tesseract package
- *2021-08-16*
  - Add some library to allow `ggstatsplot` to be installed and bump to 4.1.1
- *2021-05-26*
  - Switch to `rocker/r-ver` as all rocker images `>= 4.0.0` are now on Ubuntu 20.04 instead of Debian
- *2021-02-25*
  - Bump to `4.0.4`
- *2020-11-30*
  - Add `jags` and `ibmagick++-dev`
- *2020-10-20*
  - Clean up Dockerfile and bump to `4.0.3`
- *2020-09-09*
  - Add required libraries for `TFBSTools` package
- *2020-08-27*
  - Remove RStudio Server
  - Switch to `rocker/r-ubuntu:20.04`
- *2020-08-25*
  - Add RStudio Server
- *2020-07-21*
  - Bump to `r-base:4.0.2`
- *2020-04-17*
  - Add `tmux` for `rvisidata`
- *2020-04-09*
  - Bump to `r-base:3.6.3`
  - Remove all R packages
  - Add standard shiny installation
- *2020-02-18*
  - Bump to `r-base:3.6.2`
  - Add [`renv`](https://rstudio.github.io/renv/)
  - Add [`drake`](https://github.com/ropensci/drake)
- *2020-01-13*
  - Add [`tidlog`](https://github.com/elbersb/tidylog)
- *2019-12-13*
  - Add [Visidata not installed properly #4](https://github.com/paulklemm/mytidyverse/issues/4)
- *2019-12-12*
  - Add hack for fixing issue [Fix GenomicAlignments error #3](https://github.com/paulklemm/mytidyverse/issues/3)
- *2019-11-05*
  - Add visidata 2 pre-release
  - Add [Fix GenomicAlignments error #3](https://github.com/paulklemm/mytidyverse/issues/3)
- *2019-10-28*
  - Add `styler`, `knitr`, `rmarkdown` and `vroom`
- *2019-10-17*
  - Add DESeq2
- *2019-09-02*
  - Fix broken Uni-Muenster CRAN link
  - Update default variables to point to r-base 3.6.1
- *2019-04-10*
  - Radix package was renamed to distill
- *2019-04-05*
  - Bump base image to `r-base:3.5.3`
  - Add makefile
- *2019-01-29*
  - Add [Seurat](https://cran.r-project.org/web/packages/Seurat/index.html) package for Single Cell RNA-Seq analysis
  - `rtichoke` was renamed to `radian`
- *2019-01-07*
  - Switch to `r-base:3.5.2` as base image
