test_that("AdapterLM and AdapterLME4 extract components properly", {
  # LM Adapter
  fit_lm <- lm(mpg ~ wt + hp, data = mtcars)
  ad_lm <- AdapterLM$new(fit_lm)
  expect_equal(ad_lm$get_response_name(), "mpg")
  expect_named(ad_lm$get_fixed_effects(), c("(Intercept)", "wt", "hp"))
  expect_equal(ad_lm$get_error_label(), " + e")
  
  # LME4 Adapter
  library(lme4)
  fit_lmer <- lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy)
  ad_lmer <- AdapterLME4$new(fit_lmer)
  expect_equal(ad_lmer$get_response_name(), "Reaction")
  expect_named(ad_lmer$get_fixed_effects(), c("(Intercept)", "Days"))
  expect_equal(ad_lmer$get_error_label(), " + [u]")
  expect_type(ad_lmer$get_random_effects(), "list")
})
