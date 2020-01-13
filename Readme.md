# 🐳 𝓡 Custom Tidyverse Docker Image

---

<!-- TOC depthFrom:2 -->

- [Installed Dependencies](#installed-dependencies)
- [Installed R packages](#installed-r-packages)
  - [CRAN](#cran)
  - [Bioconductor](#bioconductor)
  - [GitHub](#github)
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
- `styler`
- `knitr`
- `rmarkdown`
- `vroom`
- `tidylog`

### Bioconductor

- `biomaRt`: Interface to Ensembl Biomart database
- `clusterProfiler`: GO-term enrichment analysis
- `DESeq2`: Differential gene expression analysis

### GitHub

- [rstudio/distill](https://github.com/rstudio/distill)
- [yihui/xaringan](https://github.com/yihui/xaringan)
- [paulklemm/mygo](https://github.com/paulklemm/mygo)
- [paulklemm/rmyknife](https://github.com/paulklemm/rmyknife)
- [paulklemm/peekr](https://github.com/paulklemm/peekr)
- [paulklemm/rvisidata](https://github.com/paulklemm/rvisidata)

## Build the Image

The image takes longer than dockers two-hour limit for building. That's why beginning with tag `r-base:3.5.2-1` we upload locally build images to the docker hub.

Run the building process manually using the following code (adapting the version).

```bash
docker login
docker build --no-cache -t mytidyverse .
docker tag mytidyverse paulklemm/mytidyverse:base-3.6.1-4
docker push paulklemm/mytidyverse:base-3.6.1-4
```

You can also use the makefile.

```bash
make VERSION=3.6.1-4
```

## Changelog

- *2020-01-13*
  - Add [`tidlog`](https://github.com/elbersb/tidylog)
- *2019-12-13*
  - Added [Visidata not installed properly #4](https://github.com/paulklemm/mytidyverse/issues/4)
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
