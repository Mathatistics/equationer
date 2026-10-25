test_that("extract_mixed_equation generates global and factor-stratified models", {
  fit <- lm(mpg ~ wt, data = mtcars)
  col_global <- extract_mixed_equation(fit, digits = 2)
  expect_s3_class(col_global, "equation_collection")
  expect_true("Global" %in% names(col_global$equations))
  
  df <- transform(mtcars, cyl = factor(cyl))
  fit_fac <- lm(mpg ~ wt + cyl, data = df)
  col_fac <- extract_mixed_equation(fit_fac, by_factor = "cyl", digits = 2)
  expect_length(col_fac$equations, 3)
})

test_that("extract_mixed_equation processes subject-level random effects for lmer", {
  library(lme4)
  fit_lmer <- lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy)
  col_subj <- extract_mixed_equation(fit_lmer, by_subject = TRUE, digits = 2)
  
  expect_s3_class(col_subj, "equation_collection")
  expect_true(any(grepl("Subject=", names(col_subj$equations))))
})
