# 🐳 𝓡 Custom Tidyverse Docker Image

<!-- TOC depthFrom:2 -->

- [Installed Dependencies](#installed-dependencies)
- [Installed R packages](#installed-r-packages)
  - [CRAN](#cran)
  - [Bioconductor](#bioconductor)
  - [GitHub](#github)
- [Changelog](#changelog)
  - [2019-01-29](#2019-01-29)
  - [2019-01-07](#2019-01-07)

<!-- /TOC -->

[My](https://github.com/paulklemm/) development `tidyverse` image is based on [r-base](https://hub.docker.com/_/r-base/).

## Installed Dependencies

It adds:

- [radian](https://github.com/randy3k/radian) as `R` console replacement
- [shiny server](https://hub.docker.com/r/rocker/shiny)
  - You can start a shiny server using `shiny-server.sh`
  - For details, check the [rocker/shiny](https://github.com/rocker-org/shiny) repo
- [visidata](https://visidata.org/) for the [rvisidata](https://github.com/paulklemm/rvisidata) package

## Installed R packages

It contains the following packages.

### CRAN

- `tidyverse`
- `devtools`
- `roxygen2`
- `ggrepel`
- `packrat`
- `usethis`
- `WriteXLS`
- `here`
- `plotly`
- `svglite`
- `languageserver`
- `flexdashboard`
- `DT`
- `rJava`
- `Seurat`

### Bioconductor

- `biomaRt`
- `clusterProfiler`

### GitHub

- [rstudio/radix](https://github.com/rstudio/radix)
- [paulklemm/mygo](https://github.com/paulklemm/mygo)
- [paulklemm/rmyknife](https://github.com/paulklemm/rmyknife)
- [paulklemm/peekr](https://github.com/paulklemm/peekr)
- [paulklemm/rvisidata](https://github.com/paulklemm/rvisidata)

## Changelog

### 2019-01-29

- Add [Seurat](https://cran.r-project.org/web/packages/Seurat/index.html) package for Single Cell RNA-Seq analysis
- `rtichoke` was renamed to `radian`

### 2019-01-07

- Switch to `r-base:3.5.2` as base image
