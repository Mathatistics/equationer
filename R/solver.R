.solve_equations_via_matrix <- function(adapter, by_factor, digits) {
  data    <- adapter$get_data()
  fix_cf  <- adapter$get_fixed_effects()
  dep_var <- adapter$get_response_name()
  
  # Ensure target factor fields are properly cast in reference data
  for (f in by_factor) data[[f]] <- as.factor(data[[f]])
  
  # 1. Create a compact grid of unique factor combinations
  lev_list <- lapply(by_factor, function(f) levels(data[[f]]))
  names(lev_list) <- by_factor
  combo_grid <- expand.grid(lev_list, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  
  # Identify numeric continuous variables separate from the factors
  all_terms <- attr(stats::terms(stats::formula(adapter$model)), "term.labels")
  continuous_vars <- setdiff(all_terms, by_factor)
  continuous_vars <- continuous_vars[!grepl(paste(by_factor, collapse = "|"), continuous_vars)]
  
  equations <- character(nrow(combo_grid))
  combo_names <- apply(combo_grid, 1, function(row) paste(paste0(names(row), "=", row), collapse = " & "))
  names(equations) <- combo_names
  
  # Predictor-only formula (dropping the response variable)
  pred_formula <- stats::delete.response(stats::terms(stats::formula(adapter$model)))
  
  # 2. Vectorized Math Engine: Calculate unique group intercepts and slopes via Model Matrix projections
  for (i in 1:nrow(combo_grid)) {
    # Generate baseline dummy test rows for this target factor level group combination
    mock_row <- combo_grid[i, , drop = FALSE]
    
    # Ensure factor columns in mock_row retain the original full levels from `data` 
    # so stats::model.matrix recognizes the complete contrast factor setup without throwing a 1-level error
    for (f in by_factor) {
      mock_row[[f]] <- factor(mock_row[[f]], levels = levels(data[[f]]))
    }
    
    # Target Intercept Shift extraction
    for (cv in continuous_vars) mock_row[[cv]] <- 0
    
    # Clean model matrix mapping generation using predictor-only formula
    mat_int <- stats::model.matrix(pred_formula, data = mock_row)
    group_intercept <- sum(mat_int[1, ] * fix_cf, na.rm = TRUE)
    
    # Target Slope evaluation updates
    slopes <- numeric(length(continuous_vars))
    names(slopes) <- continuous_vars
    
    for (cv in continuous_vars) {
      mock_slope <- mock_row
      mock_slope[[cv]] <- 1
      mat_slope <- stats::model.matrix(pred_formula, data = mock_slope)
      # Subtract the baseline intercept projection to extract the pure calculated derivative slope
      slopes[cv] <- sum((mat_slope[1, ] - mat_int[1, ]) * fix_cf, na.rm = TRUE)
    }
    
    # 3. Assemble plain text string output
    eq_str <- paste(dep_var, "=", round(group_intercept, digits))
    for (s_name in names(slopes)) {
      val <- slopes[s_name]
      if (is.na(val) || val == 0) next
      sign_str <- if (val >= 0) " + " else " - "
      eq_str <- paste0(eq_str, sign_str, round(abs(val), digits), "*", s_name)
    }
    
    equations[i] <- paste0(eq_str, adapter$get_error_label())
  }
  
  return(equations)
}

