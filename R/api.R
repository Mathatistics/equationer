#' Extract Plain-Text Regression Equations
#'
#' Extracts global or subgroup-specific plain-text regression equations from 
#' fitted linear and mixed-effects models.
#'
#' @param model A fitted model object (supported classes include `lm`, `lmerMod`, 
#'   `lmerModLmerTest`, and `glmmTMB`).
#' @param digits Integer. Number of decimal places to round coefficients (default is `2`).
#' @param by_factor Character vector of factor names by which to stratify and calculate 
#'   subgroup-specific equations. If `NULL` (default), a single global equation is returned.
#' @param by_subject Logical. If `TRUE`, extracts subject-specific equations incorporating 
#'   random effects (currently structural placeholder; default is `FALSE`).
#' 
#' @return An object of class `equation_collection` containing the generated equations 
#'   and model metadata.
#' 
#' @examples
#' \dontrun{
#' fit <- lm(mpg ~ wt + hp, data = mtcars)
#' extract_mixed_equation(fit, digits = 2)
#' 
#' # Subgroup equations by categorical variables
#' fit_fac <- lm(mpg ~ wt + factor(cyl), data = mtcars)
#' extract_mixed_equation(fit_fac, by_factor = "cyl")
#' }

#' @export
extract_mixed_equation <- function(model, digits = 2, by_factor = NULL, by_subject = FALSE) {
  adapter <- .resolve_adapter(model)
  
  if (by_subject) {
    ran_efs <- adapter$get_random_effects()
    if (is.null(ran_efs)) {
      stop("The provided model does not contain a random effects infrastructure.")
    }
    
    fix_cf  <- adapter$get_fixed_effects()
    dep_var <- adapter$get_response_name()
    err_lbl <- adapter$get_error_label()
    
    # Primary random-effects grouping variable
    grouping_var <- names(ran_efs)[1]
    rf_df <- ran_efs[[grouping_var]]
    
    subjects <- rownames(rf_df)
    eqs <- character(length(subjects))
    
    for (sbj in subjects) {
      key <- paste0(grouping_var, "=", sbj)
      subj_rf <- rf_df[sbj, , drop = FALSE]
      
      # Fixed intercept baseline
      subj_intercept <- if ("(Intercept)" %in% names(fix_cf)) fix_cf["(Intercept)"] else 0
      if ("(Intercept)" %in% colnames(subj_rf)) {
        subj_intercept <- subj_intercept + subj_rf[1, "(Intercept)"]
      }
      
      # Assemble slopes (Fixed + Random adjustment)
      all_terms <- setdiff(names(fix_cf), "(Intercept)")
      slopes <- numeric(length(all_terms))
      names(slopes) <- all_terms
      
      for (term in all_terms) {
        slopes[term] <- fix_cf[term]
        if (term %in% colnames(subj_rf)) {
          slopes[term] <- slopes[term] + subj_rf[1, term]
        }
      }
      
      # Build equation string
      eq_str <- paste(dep_var, "=", round(subj_intercept, digits))
      for (s_name in names(slopes)) {
        val <- slopes[s_name]
        if (is.na(val) || val == 0) next
        sign_str <- if (val >= 0) " + " else " - "
        eq_str <- paste0(eq_str, sign_str, round(abs(val), digits), "*", s_name)
      }
      
      eqs[key] <- paste0(eq_str, err_lbl)
    }
    
    # Clean up any zero-length unnamed entries if vector allocated extra slots
    eqs <- eqs[names(eqs) != ""]
    
    return(.new_equation_collection(eqs, adapter))
  }
  
  if (!is.null(by_factor)) {
    eqs <- .solve_equations_via_matrix(adapter, by_factor, digits)
  } else {
    # Global assignment fallback
    fix_cf <- adapter$get_fixed_effects()
    slopes <- fix_cf[names(fix_cf) != "(Intercept)"]
    eq_str <- paste(adapter$get_response_name(), "=", round(fix_cf["(Intercept)"], digits))
    for (n in names(slopes)) {
      eq_str <- paste0(eq_str, if (slopes[n] >= 0) " + " else " - ", round(abs(slopes[n]), digits), "*", n)
    }
    eqs <- c("Global" = paste0(eq_str, adapter$get_error_label()))
  }
  
  return(.new_equation_collection(eqs, adapter))
}

# extract_mixed_equation <- function(model, digits = 2, by_factor = NULL, by_subject = FALSE) {
#   adapter <- .resolve_adapter(model)
  
#   if (by_subject) {
#     # Extract subject paths...
#     ran_efs <- adapter$get_random_effects()
#     if (is.null(ran_efs)) stop("The provided model does not contain a random effects infrastructure.")
#     # (Random effects loop logic maps cleanly here utilizing adapter$get_fixed_effects())
#     stop("Random effects processing branch omitted for structural demonstration brevity.")
#   }
  
#   if (!is.null(by_factor)) {
#     eqs <- .solve_equations_via_matrix(adapter, by_factor, digits)
#   } else {
#     # Simple global assignment fallback
#     fix_cf <- adapter$get_fixed_effects()
#     slopes <- fix_cf[names(fix_cf) != "(Intercept)"]
#     eq_str <- paste(adapter$get_response_name(), "=", round(fix_cf["(Intercept)"], digits))
#     for(n in names(slopes)) {
#       eq_str <- paste0(eq_str, if(slopes[n]>=0) " + " else " - ", round(abs(slopes[n]), digits), "*", n)
#     }
#     eqs <- c("Global" = paste0(eq_str, adapter$get_error_label()))
#   }
  
#   return(.new_equation_collection(eqs, adapter))
# }
