#!/usr/bin/env Rscript

# pak-migrate.R
# -----------------------------------------------------------------------------
# Snapshot the R packages installed under one R version and reinstall them --
# from their ORIGINAL sources (CRAN, Bioconductor, GitHub, GitLab, ...) -- under
# another R version, using pak.
#
# Why this exists:
#   R keeps a separate package library per *minor* version
#   (e.g. ~/R/x86_64-pc-linux-gnu-library/4.5 vs .../4.6). Bumping R 4.5 -> 4.6
#   points R at a fresh, empty library, so every package must be rebuilt. The
#   old files are still on disk, so we read them to learn WHAT you had and WHERE
#   it came from, then let pak reinstall the lot against the new R (and the
#   matching Bioconductor release, which pak selects automatically).
#
# Usage:
#   # 1. SNAPSHOT -- run under the OLD R, while the packages are still installed.
#   #    (Or run under the new R but point --lib at the old library dir.)
#   Rscript pak-migrate.R snapshot [manifest.csv] [--lib=/path/to/old/library]
#
#   # 2. RESTORE -- run under the NEW R (fresh, empty library).
#   Rscript pak-migrate.R restore  [manifest.csv] [--dry-run] [--upgrade]
#
#   # 3. VERIFY -- compare the manifest against what is installed right now.
#   Rscript pak-migrate.R verify   [manifest.csv]
#
# Manifest defaults to ./r-package-manifest.csv in every mode.
#
# Notes:
#   * CRAN/Bioc packages are installed at their CURRENT versions (what you want
#     across an R minor bump -- old versions often lack binaries for the new R).
#   * GitHub/GitLab packages are installed from their recorded branch/tag (the
#     commit SHA is recorded in the manifest for reference but not pinned, since
#     old commits may not build against the new R). Edit the ref column to pin.
#   * Anything installed from a local path or an unrecognised remote is flagged
#     "MANUAL:<type>" and listed for you to handle by hand -- it cannot be
#     reproduced automatically.
# -----------------------------------------------------------------------------

## ---- helpers ---------------------------------------------------------------

field <- function(dcf, name) {
  if (!name %in% colnames(dcf)) return(NA_character_)
  v <- dcf[1L, name]
  if (is.na(v) || !nzchar(trimws(v))) return(NA_character_)
  trimws(v)
}

# Inspect one installed package's DESCRIPTION and return a one-row list
# describing its source and the pak reference used to reinstall it.
# Returns NULL for base packages (they ship with R) and non-package dirs.
classify <- function(pkg, lib) {
  dpath <- file.path(lib, pkg, "DESCRIPTION")
  if (!file.exists(dpath)) return(NULL)
  dcf <- tryCatch(read.dcf(dpath), error = function(e) NULL)
  if (is.null(dcf)) return(NULL)

  if (identical(field(dcf, "Priority"), "base")) return(NULL)

  version    <- field(dcf, "Version")
  remoteType <- field(dcf, "RemoteType")
  biocViews  <- field(dcf, "biocViews")
  sha        <- field(dcf, "RemoteSha")

  row <- function(source, ref) {
    list(package = pkg, source = source, ref = ref,
         version = if (is.na(version)) "" else version,
         sha = if (is.na(sha)) "" else sha)
  }

  # 1) Installed from a git host / URL. Explicit install source wins over any
  #    CRAN/Bioc metadata the package may also carry.
  if (!is.na(remoteType) && !tolower(remoteType) %in% c("standard", "cran")) {
    type   <- tolower(remoteType)
    user   <- field(dcf, "RemoteUsername")
    rname  <- field(dcf, "RemoteRepo")
    ref    <- field(dcf, "RemoteRef")
    subdir <- field(dcf, "RemoteSubdir")
    url    <- field(dcf, "RemoteUrl")

    prefix <- switch(type, github = "github", gitlab = "gitlab",
                     bitbucket = "bitbucket", NA_character_)

    if (!is.na(prefix) && !is.na(user) && !is.na(rname)) {
      slug <- paste0(prefix, "::", user, "/", rname)
      if (!is.na(subdir)) slug <- paste0(slug, "/", subdir)
      if (!is.na(ref) && !tolower(ref) %in% c("head", "master", "main"))
        slug <- paste0(slug, "@", ref)
      return(row(type, slug))
    }
    if (type == "git" && !is.na(url)) return(row("git", paste0("git::", url)))
    if (type == "url" && !is.na(url)) return(row("url", paste0("url::", url)))
    # local / cran_local / unrecognised -> cannot reproduce automatically
    return(row(paste0("MANUAL:", type), ""))
  }

  # 2) Bioconductor. The reliable marker is the biocViews field, which only
  #    Bioconductor packages carry. pak resolves bioc:: against the Bioc release
  #    matching the running R.
  if (!is.na(biocViews)) return(row("bioc", paste0("bioc::", pkg)))

  # 3) CRAN (also covers P3M / RSPM mirrors). A bare name resolves against the
  #    configured CRAN-like repo.
  row("cran", pkg)
}

ensure_pak <- function() {
  if (requireNamespace("pak", quietly = TRUE)) return(invisible())
  cat("pak not found -- installing it...\n")
  ok <- tryCatch({
    install.packages("pak", repos = sprintf(
      "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
      .Platform$pkgType, R.version$os, R.version$arch))
    requireNamespace("pak", quietly = TRUE)
  }, error = function(e) FALSE)
  if (!ok) install.packages("pak")            # fall back to CRAN source build
  if (!requireNamespace("pak", quietly = TRUE))
    stop("Could not install pak. Install it manually and re-run.")
}

ensure_cran <- function() {
  r <- getOption("repos")
  if (is.null(r) || is.na(r["CRAN"]) || r["CRAN"] %in% c("@CRAN@", ""))
    options(repos = c(CRAN = "https://cloud.r-project.org"))
}

installed_names <- function() rownames(installed.packages())

## ---- commands --------------------------------------------------------------

do_snapshot <- function(outfile, lib) {
  libs <- if (is.null(lib)) .libPaths() else lib
  cat("R ", as.character(getRversion()), " -- scanning libraries:\n", sep = "")
  cat(paste0("  ", libs), sep = "\n"); cat("\n")

  rows <- list(); seen <- character(0)
  for (l in libs) {
    if (!dir.exists(l)) next
    for (p in list.dirs(l, recursive = FALSE, full.names = FALSE)) {
      if (p %in% seen) next               # first libpath wins, as R does
      info <- classify(p, l)
      if (is.null(info)) next
      seen <- c(seen, p)
      rows[[length(rows) + 1L]] <- info
    }
  }
  if (length(rows) == 0L) stop("No non-base packages found in: ", paste(libs, collapse = ", "))

  df <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  df <- df[order(df$source, tolower(df$package)), ]
  write.csv(df, outfile, row.names = FALSE)

  cat(sprintf("\nWrote %d packages to %s\n", nrow(df), normalizePath(outfile, mustWork = FALSE)))
  cat("By source:\n")
  tab <- sort(table(df$source), decreasing = TRUE)
  for (nm in names(tab)) cat(sprintf("  %-14s %d\n", nm, tab[[nm]]))
  manual <- df[grepl("^MANUAL:", df$source), ]
  if (nrow(manual) > 0)
    cat(sprintf("\n%d package(s) need manual handling (see 'MANUAL:' rows).\n", nrow(manual)))
}

do_restore <- function(infile, dry_run, upgrade) {
  if (!file.exists(infile)) stop("Manifest not found: ", infile, " (run 'snapshot' first)")
  df <- read.csv(infile, stringsAsFactors = FALSE, colClasses = "character")

  manual <- df[grepl("^MANUAL:", df$source) | is.na(df$ref) | !nzchar(df$ref), ]
  auto   <- df[!(df$package %in% manual$package), ]
  refs   <- unique(auto$ref)

  cat(sprintf("R %s -- manifest %s\n", getRversion(), infile))
  cat(sprintf("%d packages: %d installable, %d need manual handling.\n",
              nrow(df), nrow(auto), nrow(manual)))
  if (nrow(manual) > 0) {
    cat("\nManual (local/unknown source -- not installed by this script):\n")
    print(manual[, c("package", "source", "version")], row.names = FALSE)
  }

  if (dry_run) {
    cat(sprintf("\n[--dry-run] %d refs that WOULD be installed:\n", length(refs)))
    cat(paste0("  ", refs), sep = "\n"); cat("\n")
    return(invisible())
  }

  ensure_cran(); ensure_pak()
  cat(sprintf("\nInstalling %d refs with pak (upgrade=%s)...\n", length(refs), upgrade))
  bulk_ok <- tryCatch({
    pak::pkg_install(refs, ask = FALSE, upgrade = upgrade)
    TRUE
  }, error = function(e) {
    cat("\nBulk install stopped with an error:\n  ", conditionMessage(e), "\n", sep = "")
    FALSE
  })

  # Whatever the bulk result, find what is still missing and retry those one at
  # a time so each failure gets its own, readable error message. Reasons are
  # stashed on df$error so report() can write them to the missing CSV.
  df$error <- ""
  inst    <- installed_names()
  missing <- auto[!(auto$package %in% inst), ]
  if (nrow(missing) > 0) {
    cat(sprintf("\n%d package(s) still missing -- retrying individually for diagnostics:\n",
                nrow(missing)))
    for (i in seq_len(nrow(missing))) {
      pkg <- missing$package[i]
      e <- tryCatch({ pak::pkg_install(missing$ref[i], ask = FALSE, upgrade = FALSE); "" },
                    error = function(e) conditionMessage(e))
      df$error[df$package == pkg] <- e
      cat(sprintf("  [%d/%d] %-30s %s\n", i, nrow(missing), missing$ref[i],
                  if (nzchar(e)) "FAILED" else "ok"))
    }
  }

  report(df, infile, note = if (bulk_ok) NULL else "bulk step errored; see above")
}

do_verify <- function(infile) {
  if (!file.exists(infile)) stop("Manifest not found: ", infile)
  df <- read.csv(infile, stringsAsFactors = FALSE, colClasses = "character")
  cat(sprintf("R %s -- verifying %s\n", getRversion(), infile))
  report(df, infile)
}

# Compare manifest against the current library; print a summary and, if any are
# missing, write them to <manifest>-missing.csv.
report <- function(df, infile, note = NULL) {
  inst    <- installed_names()
  df$installed <- df$package %in% inst
  auto    <- df[!grepl("^MANUAL:", df$source) & nzchar(df$ref), ]
  manual  <- df[grepl("^MANUAL:", df$source), ]
  missing <- auto[!auto$installed, ]

  cat("\n================ summary ================\n")
  cat(sprintf("installable in manifest : %d\n", nrow(auto)))
  cat(sprintf("present now             : %d\n", sum(auto$installed)))
  cat(sprintf("MISSING                 : %d\n", nrow(missing)))
  if (nrow(manual) > 0)
    cat(sprintf("manual (do by hand)     : %d\n", nrow(manual)))
  if (!is.null(note)) cat("note                    : ", note, "\n", sep = "")

  if (nrow(missing) > 0) {
    out <- sub("\\.csv$", "", infile)
    out <- paste0(out, "-missing.csv")
    cols <- intersect(c("package", "source", "ref", "version", "error"), names(missing))
    write.csv(missing[, cols], out, row.names = FALSE)
    cat(sprintf("\nMissing packages written to %s:\n", out))
    print(missing[, intersect(c("package", "source", "ref"), names(missing))], row.names = FALSE)
  } else {
    cat("\nAll installable packages from the manifest are present. Safe to go live.\n")
  }
}

## ---- dispatch --------------------------------------------------------------

usage <- function() {
  cat("Usage:\n",
      "  Rscript pak-migrate.R snapshot [manifest.csv] [--lib=PATH]\n",
      "  Rscript pak-migrate.R restore  [manifest.csv] [--dry-run] [--upgrade]\n",
      "  Rscript pak-migrate.R verify   [manifest.csv]\n",
      "\nManifest defaults to ./r-package-manifest.csv\n", sep = "")
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) == 0) { usage(); quit(status = 1L) }

  cmd   <- args[1L]
  rest  <- args[-1L]
  flags <- rest[grepl("^--", rest)]
  pos   <- rest[!grepl("^--", rest)]

  manifest <- if (length(pos) >= 1L) pos[1L] else "r-package-manifest.csv"
  lib_flag <- sub("^--lib=", "", flags[grepl("^--lib=", flags)])
  lib      <- if (length(lib_flag) >= 1L) lib_flag[1L] else NULL
  dry_run  <- any(flags == "--dry-run")
  upgrade  <- any(flags == "--upgrade")

  switch(cmd,
    snapshot = do_snapshot(manifest, lib),
    restore  = do_restore(manifest, dry_run, upgrade),
    verify   = do_verify(manifest),
    { cat("Unknown command: ", cmd, "\n\n", sep = ""); usage(); quit(status = 1L) })
}

main()
