#' S3 Export Container Class Constructor
#' @noRd
.new_equation_collection <- function(equations, adapter) {
  structure(
    list(
      equations = equations,
      metadata = list(
        dependent_variable = adapter$get_response_name(),
        model_class = class(adapter$model)[1]
      )
    ),
    class = "equation_collection"
  )
}

#' @export
print.equation_collection <- function(x, ...) {
  cat(sprintf("Model Equation Collection [%s -> %s]\n\n", x$metadata$model_class, x$metadata$dependent_variable))
  for (n in names(x$equations)) {
    cat(sprintf("  %-30s : %s\n", n, x$equations[n]))
  }
  invisible(x)
}

#' @export
as.data.frame.equation_collection <- function(x, ...) {
  data.frame(subgroup = names(x$equations), equation = unname(x$equations), stringsAsFactors = FALSE)
}
