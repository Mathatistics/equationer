#' @noRd
.solve_equations_via_matrix <- function(adapter, by_factor = NULL, digits = 2) {
  fit <- adapter$model
  dat <- adapter$get_data()
  fix_cf <- adapter$get_fixed_effects()
  dep_var <- adapter$get_response_name()
  err_lbl <- adapter$get_error_label()
  
  full_form <- stats::formula(fit)
  
  # Strip random effects bars using reformulas::nobars
  if (requireNamespace("reformulas", quietly = TRUE)) {
    fixed_form <- reformulas::nobars(full_form)
  } else {
    fixed_form <- full_form
  }
  
  tms <- stats::terms(fixed_form, data = dat)
  m_terms <- stats::delete.response(tms)
  
  if (is.null(by_factor)) {
    # Global equation logic
    mm <- stats::model.matrix(m_terms, data = dat[1, , drop = FALSE])
    # Build global eq string...
    # (Ensure eqs is a named character vector)
  } else {
    if (!by_factor %in% names(dat)) {
      stop("The specified `by_factor` variable '", by_factor, "' is not present in the model data.")
    }
    
    levels_fac <- levels(factor(dat[[by_factor]]))
    eqs <- character(length(levels_fac))
    names(eqs) <- paste0(by_factor, "=", levels_fac)
    
    for (lvl in levels_fac) {
      sub_dat <- dat[dat[[by_factor]] == lvl, , drop = FALSE]
      if (nrow(sub_dat) == 0) next
      
      row_idx <- 1
      mm <- stats::model.matrix(m_terms, data = sub_dat[row_idx, , drop = FALSE])
      
      # Evaluate active coefficients for this subgroup level
      active_cols <- colnames(mm)
      sub_intercept <- 0
      sub_slopes <- numeric(0)
      
      for (col in active_cols) {
        if (col == "(Intercept)") {
          sub_intercept <- if ("(Intercept)" %in% names(fix_cf)) fix_cf["(Intercept)"] else 0
        } else if (col %in% names(fix_cf)) {
          sub_slopes[col] <- fix_cf[col]
        } else {
          # Check for factor contrast matches
          matched_coef <- grep(paste0("^", col), names(fix_cf), value = TRUE)
          if (length(matched_coef) > 0) {
            sub_slopes[col] <- fix_cf[matched_coef[1]]
          } else {
            sub_slopes[col] <- 0
          }
        }
      }
      
      eq_str <- paste(dep_var, "=", round(sub_intercept, digits))
      for (s_name in names(sub_slopes)) {
        val <- sub_slopes[s_name]
        if (is.na(val) || val == 0) next
        sign_str <- if (val >= 0) " + " else " - "
        eq_str <- paste0(eq_str, sign_str, round(abs(val), digits), "*", s_name)
      }
      
      eqs[paste0(by_factor, "=", lvl)] <- paste0(eq_str, err_lbl)
    }
  }
  
  return(eqs) # Return character vector directly
}

