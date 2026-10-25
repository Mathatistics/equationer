test_that(".solve_equations_via_matrix handles factor subgroups correctly", {
  df <- transform(mtcars, cyl = factor(cyl))
  fit <- lm(mpg ~ wt + cyl, data = df)
  adapter <- .resolve_adapter(fit)
  
  eqs <- .solve_equations_via_matrix(adapter, by_factor = "cyl", digits = 2)
  
  expect_type(eqs, "character")
  expect_length(eqs, 3)
  expect_named(eqs, c("cyl=4", "cyl=6", "cyl=8"))
  
  for (eq in eqs) {
    expect_true(grepl("mpg =", eq, fixed = TRUE))
    expect_true(grepl("wt", eq, fixed = TRUE))
  }
})
