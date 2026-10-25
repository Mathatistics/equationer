test_that("adapter registry resolves built-in model classes correctly", {
  fit_lm <- lm(mpg ~ wt, data = mtcars)
  adapter <- .resolve_adapter(fit_lm)
  
  expect_s3_class(adapter, "AdapterLM")
  expect_equal(adapter$get_response_name(), "mpg")
})

test_that(".resolve_adapter throws an error for unregistered models", {
  unsupported <- structure(list(), class = "unknown_model")
  expect_error(
    .resolve_adapter(unsupported),
    "No adapter registered for model class: unknown_model"
  )
})

test_that("register_model_adapter successfully registers custom classes", {
  CustomAdapter <- R6::R6Class("CustomAdapter", inherit = ModelAdapter,
    public = list(
      get_response_name = function() "y",
      get_fixed_effects = function() c("(Intercept)" = 1),
      get_data         = function() data.frame(y = 1),
      get_error_label   = function() " + e"
    )
  )
  
  register_model_adapter("custom_class", CustomAdapter)
  obj <- structure(list(), class = "custom_class")
  adapter <- .resolve_adapter(obj)
  
  expect_s3_class(adapter, "CustomAdapter")
})
