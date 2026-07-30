# 🐳 𝓡 Custom Tidyverse Docker Image

---

<!-- TOC depthFrom:2 -->

- [Installed Dependencies](#installed-dependencies)
- [Build the Image](#build-the-image)
- [Changelog](#changelog)

<!-- /TOC -->

---

[My](https://github.com/paulklemm/) development `tidyverse` image is based on [rocker/shiny-verse](https://hub.docker.com/r/rocker/shiny-verse).

## Installed Dependencies

It adds:

- [radian](https://github.com/randy3k/radian) as `R` console replacement
- [shiny server](https://hub.docker.com/r/rocker/shiny)
  - You can start a shiny server using `shiny-server.sh`
  - For details, check the [rocker/shiny](https://github.com/rocker-org/shiny) repo
- [visidata](https://visidata.org/) for the [rvisidata](https://github.com/paulklemm/rvisidata) package
- Node.js and npm ([NodeSource](https://github.com/nodesource/distributions), Node 24)
- A whole bunch of libraries for a number of different R packages, mostly for bioinformatics analyses

## Build the Image

The image is built remotely on GitHub Actions — no local Docker daemon needed.
The default `make` target runs the full deploy:

1. `ci-build` — tags the current commit with `VERSION` and pushes it; GitHub
   Actions builds the image (native amd64, no emulation), smoke-tests it and
   pushes `paulklemm/mytidyverse:VERSION` to Docker Hub
2. `wait-image` — polls Docker Hub until the tag appears (~30–60 min)
3. `remote-singularity` — converts the image to a `.simg` directly on the HPC
   via an unprivileged `singularity pull` (no root or Docker on the server)
4. `create-link` — flips the `latest` symlink → the new image goes live

```bash
make VERSION=4.6.1-2
```

Or adapt the default `VERSION` in the makefile and run `make`. To rebuild an
existing version without creating a new tag, use the *Run workflow* button on
the [Actions page](https://github.com/paulklemm/mytidyverse/actions).

### One-time setup

The workflow authenticates to Docker Hub via two repository secrets (GitHub →
Settings → Secrets and variables → Actions): `DOCKERHUB_USERNAME` and
`DOCKERHUB_TOKEN` (an access token with *Read & Write* scope from Docker Hub →
Account Settings → Personal access tokens).

### Local fallback

The old fully-local flow is still available if CI is down (requires a local
Docker daemon; slow on Apple Silicon due to amd64 emulation):

```bash
make local-deploy VERSION=4.6.1-2   # build → push → .simg conversion → scp → create-link
```

## Migrating R packages across an R bump

R keeps a separate package library per minor version (`~/R/…-library/4.5` vs
`…/4.6`), so bumping R leaves the new version with an empty library. The
`pak-migrate.R` script snapshots the packages installed under the old R —
detecting each one's source (CRAN, Bioconductor, GitHub, …) — and reinstalls
them under the new R with [pak](https://pak.r-lib.org/). The makefile drives it
on the server, inside the image.

### Full workflow (R bump that carries packages over)

When the package library must be rebuilt, don't run the default `make` — it
flips `latest` to the new image at the end, before you get a chance to restore
and verify. Run the steps individually instead, in this order (bump `VERSION`
in the makefile, or pass `VERSION=…` to every command, first):

```bash
make snapshot            # 1. read the CURRENT (live) image's library -> r-package-manifest.csv
make ci-build            # 2. tag + push -> GitHub Actions builds and pushes the new image
make wait-image          # 3. wait until the new image is on Docker Hub
make remote-singularity  # 4. convert it to a .simg on the server (new image now on the server)
make restore-dry         # 5. preview what the new image would reinstall (installs nothing)
make restore             # 6. reinstall the manifest under the new image with pak
make verify              # 7. confirm the new library matches the manifest
make create-link         # 8. only now flip `latest` to the new image -> go live
```

Steps 1 and 8 are the ordering that matters: snapshot **while the old image is
still `latest`** (otherwise it reads the empty new library), and flip `latest`
**only after** verify passes. Steps 2–4 are exactly what the default `make`
does, minus `create-link`.

pak selects the Bioconductor release matching the new R automatically. Anything
it can't reinstall is listed in `<manifest>-missing.csv` with the reason. Pass
extra pak flags with `make restore PAK_FLAGS=--upgrade`. If a step fails,
re-running it is safe — every target is idempotent.

## Changelog

- *2026-07-30*
  - Move the Docker build to GitHub Actions and the `.simg` conversion onto the HPC (unprivileged `singularity pull`) — no local Docker daemon and no root on the server needed
  - Add Node.js and npm (NodeSource, Node 24)
  - Bump to `4.6.1-2`
- *2026-07-21*
  - Add `pak-migrate.R` and `make snapshot`/`restore`/`restore-dry`/`verify` to reinstall R packages across an R minor-version bump
- *2026-07-02*
  - Bump base image to R 4.6.1
  - Bump Apptainer `1.3.0` → `1.5.2` and Quarto `1.7.31` → `1.9.38`
  - Add `libsodium-dev`
  - Fix silent-failure and robustness issues in Dockerfile, makefile, `.dockerignore` and `shiny-server.sh`
  - Bump to `4.6.1-1`
- *2026-04-28*
  - Add ripgrep
  - Bump to `4.5.3-1`
- *2025-09-22*
  - Add git-lfs
  - Bump to `4.5.1-2`
- *2025-07-02*
  - Add Apptainer/Singularity
  - Bump to `4.5.1`
- *2025-05-14*
  - Add quarto
  - Bump to `4.5.0`
- *2025-04-24*
  - Add `git-lfs`
  - Bump to `4.4.3`
- *2025-01-23*
  - Remove Singularity
- *2025-01-14*
  - Bump to `4.4.2`
  - Add `btop`, `htop`, `keychain` and `git-lfs`
  - Remove `Quarto`
  - Remove `libncurses5` (required for FibeR package)
- *2024-12-10*
  - Add git lfs
- *2024-10-08*
  - Add singularity
- *2024-10-01*
  - Add keychain
- *2024-09-30*
  - Add ZSH
- *2024-09-27*
  - Add Quarto
  - Bump to 4.4.1
- *2024-05-14*
  - Bump to 4.4.0
  - Add Jupyter Notebook
- *2023-09-15*
  - Add `igraph` dependency for scvi
- *2023-09-11*
  - Add potential fix for scvi by reverting to pandas < 2.0.0
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
