local({

  reexports_file <- rprojroot::find_package_root_file("tools/documentation/reexports.json")
  pkgdown_file <- rprojroot::find_package_root_file("tools/documentation/pkgdown.yml")

  get_exported <- function() {
    # We're running tests on a source tree, likely by devtools::test()
    sub("\\.Rd", "", list.files(rprojroot::find_package_root_file("man"), pattern = "*.Rd"))

    # # We're testing an installed package, possibly for R CMD check
    # unique(unname(readRDS("../../shiny/help/aliases.rds")))
  }

  get_indexed <- function(pkgdown_file) {
    unlist(lapply(yaml::yaml.load_file(pkgdown_file)$reference, function(x) x$contents))
  }


  indexed_topics <- get_indexed(pkgdown_file)
  all_topics     <- get_exported()

  ## Known not to be indexed
  reexports_man_info <- jsonlite::fromJSON(reexports_file, simplifyDataFrame = FALSE)
  reexports_man_file_names <- unlist(
    recursive = TRUE,
    lapply(reexports_man_info, function(alias_pkg_info) {
      lapply(alias_pkg_info$exports, function(man_item) {
        sub(".Rd", "", man_item$file, fixed = TRUE)
      })
    })
  )
  # TODO check for internal help pages and not warn about them
  # TODO .. or check that pkgdown::build_reference_index() does not produce warnings
  known_unindexed <- c("shiny-package", "stacktrace", "knitr_methods",
                       "pageWithSidebar", "headerPanel", "shiny.appobj",
                       "deprecatedReactives", "reexports", "makeReactiveBinding",
                       "reactiveConsole", "registerThemeDependency",
                       "memoryCache", "diskCache", "shinyDeprecated", "devmode")

  ## This test ensures that every documented topic is included in
  ## staticdocs/index.r, unless explicitly waived by specifying it
  ## in the known_unindexed variable above.
  missing <- setdiff(all_topics, c(known_unindexed, indexed_topics))
  ## Explicitly add reexports man files as they will be added at shiny-dev-center documentation build time
  unknown <- setdiff(c(known_unindexed, indexed_topics), c(all_topics, reexports_man_file_names))

  testthat::expect_equal(length(missing), 0,
    info = paste("Functions missing from ./tools/documentation/pkgdown.yml:\n",
      paste(" - ", missing, sep = "", collapse = "\n"),
      "\nPlease update ./tools/documentation/pkgdown.yml or ",
      "`known_unindexed` in ./tools/documentation/checkPkgdown.R",
      sep = ""))
  testthat::expect_equal(length(unknown), 0,
    info = paste("Unrecognized functions in ./tools/documentation/pkgdown.yml:\n",
      paste(" - ", unknown, sep = "", collapse = "\n"),
      "\nPlease update ./tools/documentation/pkgdown.yml",
      sep = ""))
  invisible(TRUE)
})
