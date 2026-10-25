#' Abstract Base Class for Model Adapters
#'
#' @description 
#' `ModelAdapter` is an R6 abstract base class that defines the mandatory interface 
#' required for model extensions to integrate with the `equationer` package. Custom 
#' model adapters must inherit from `ModelAdapter` and implement its core methods.
#'
#' @format An R6::R6Class generator object.
#' @importFrom R6 R6Class
#' 
#' @section Methods:
#' \describe{
#'   \item{\code{initialize(model)}}{Constructor accepting the fitted model object.}
#'   \item{\code{get_response_name()}}{Returns character string of the response variable name.}
#'   \item{\code{get_fixed_effects()}}{Returns named vector of fixed effect coefficients.}
#'   \item{\code{get_data()}}{Returns the data frame used to fit the model.}
#'   \item{\code{get_random_effects()}}{Returns random effects (optional, returns `NULL` by default).}
#'   \item{\code{get_error_label()}}{Returns character string representing the error term format (e.g., `" + e"`).}
#' }
#' 
#' @export
ModelAdapter <- R6::R6Class("ModelAdapter",
  public = list(
    #' @field model The underlying fitted model object
    model = NULL,
    
    #' @description Initialize the adapter
    #' @param model A fitted model object
    initialize = function(model) { self$model <- model },
    
    #' @description Get response variable name
    get_response_name = function() { stop("Abstract method") },
    
    #' @description Get fixed effect coefficients
    get_fixed_effects = function() { stop("Abstract method") },
    
    #' @description Get underlying model data frame
    get_data         = function() { stop("Abstract method") },
    
    #' @description Get random effects (optional)
    get_random_effects = function() { return(NULL) },
    
    #' @description Get error term label format
    get_error_label   = function() { stop("Abstract method") }
  )
)

# --- Built-in Adapter implementations ---
AdapterLM <- R6::R6Class("AdapterLM", inherit = ModelAdapter,
  public = list(
    get_response_name  = function() { as.character(stats::formula(self$model))[2] },
    get_fixed_effects  = function() { coef(self$model) },
    get_data           = function() { self$model$model },
    get_error_label    = function() { " + e" }
  )
)

AdapterLME4 <- R6::R6Class("AdapterLME4", inherit = ModelAdapter,
  public = list(
    get_response_name  = function() { as.character(stats::formula(self$model))[2] },
    get_fixed_effects  = function() { lme4::fixef(self$model) },
    get_data           = function() { self$model@frame },
    get_random_effects = function() { lme4::ranef(self$model) },
    get_error_label    = function() { " + [u]" }
  )
)

AdapterTMB <- R6::R6Class("AdapterTMB", inherit = ModelAdapter,
  public = list(
    get_response_name  = function() { as.character(stats::formula(self$model))[2] },
    get_fixed_effects  = function() { glmmTMB::fixef(self$model)$cond },
    get_data           = function() { self$model$frame },
    get_random_effects = function() { glmmTMB::ranef(self$model)$cond },
    get_error_label    = function() { " + [u]" }
  )
)