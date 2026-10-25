# Internal registry environment storage
.adapter_registry <- new.env(parent = emptyenv())

#' Register a New Model Adapter
#'
#' Registers a custom R6 model adapter class into the internal `.adapter_registry` 
#' environment, enabling `equationer` to support additional model frameworks.
#'
#' @param class_name Character string specifying the class name of the target model 
#'   (e.g., `"brmsfit"`).
#' @param adapter_r6 An R6 class generator inheriting from `ModelAdapter`.
#' 
#' @return Invisible `NULL`. Called for its side effect of updating the adapter registry.
#' @export
#'
#' @examples
#' \dontrun{
#' register_model_adapter("my_model_class", MyCustomAdapterR6)
#' }
register_model_adapter <- function(class_name, adapter_r6) {
  .adapter_registry[[class_name]] <- adapter_r6
}

# Seed the package defaults
register_model_adapter("lm", AdapterLM)
register_model_adapter("lmerMod", AdapterLME4)
register_model_adapter("lmerModLmerTest", AdapterLME4)
register_model_adapter("glmmTMB", AdapterTMB)

# Resolver mapping
.resolve_adapter <- function(model) {
  classes <- class(model)
  for (cls in classes) {
    if (exists(cls, envir = .adapter_registry)) {
      return(.adapter_registry[[cls]]$new(model))
    }
  }
  stop(paste("No adapter registered for model class:", paste(classes, collapse = ", ")))
}