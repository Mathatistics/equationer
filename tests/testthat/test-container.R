test_that("equation_collection container methods work seamlessly", {
  fit <- lm(mpg ~ wt, data = mtcars)
  col <- extract_mixed_equation(fit)
  
  # as.data.frame conversion test
  df <- as.data.frame(col)
  expect_s3_class(df, "data.frame")
  expect_equal(names(df), c("subgroup", "equation"))
  expect_equal(df$subgroup[1], "Global")
  
  # print method output test
  output <- capture.output(print(col))
  expect_true(any(grepl("Model Equation Collection", output)))
})
