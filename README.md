# equationer <a href="https://github.com/Mathatistics/equationer"><img src="https://raw.githubusercontent.com/Mathatistics/equationer/main/man/figures/logo.png" align="right" height="138" alt="equationer website" /></a>

[![R-CMD-check](https://github.com/Mathatistics/equationer/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Mathatistics/equationer/actions/workflows/R-CMD-check.yaml)

The **equationer** R package provides an extensible, R6-registry based framework to extract clean, formatted, plain-text regression formulas, subgroup projections, and subject-level random-effects equations from fitted model objects. 

Whether you need equation strings for statistical reports, dynamic document generation (Quarto/RMarkdown), web applications, or inline metadata, `equationer` converts model objects into explicit, interpretable equation strings.

---

## Key Features

- **Standard Model Support:** Native support for `lm`, `lme4::lmer`, and `glmmTMB`.
- **Subgroup Projections (`by_factor`):** Vectorized matrix projections to solve and output subgroup-specific equations for factor levels and factor interactions.
- **Random Effects (`by_subject`):** Extract individual, subject-level equations combining fixed effects and conditional modes (random effects).
- **Pluggable Architecture:** Easily extend `equationer` to support custom or new model frameworks (e.g., `mgcv::gam`, `brms`, `ordinal`) using an internal R6 class registry.

---

## Installation

You can install the development version of `equationer` directly from GitHub:

```r
# install.packages("remotes")
remotes::install_github("rajurimal/equationer")
```

---

## Quickstart & Usage

```r
library(equationer)
```

### 1. Standard Linear Models (`lm`)

Extract a global, plain-text regression equation from an `lm` fit:

```r
fit_lm <- lm(mpg ~ wt + hp, data = mtcars)

eq_lm <- extract_mixed_equation(fit_lm, digits = 2)
print(eq_lm)
#> Model Equation Collection [lm -> mpg]
#> 
#>   Global                         : mpg = 37.23 - 3.88*wt - 0.03*hp + e
```

You can convert the resulting `equation_collection` into a standard `data.frame` for tables or downstream rendering:

```r
as.data.frame(eq_lm)
#>   subgroup                                equation
#> 1   Global mpg = 37.23 - 3.88*wt - 0.03*hp + e
```

---

### 2. Subgroup Factor Projections (`by_factor`)

When models contain categorical factors or factor interactions, `equationer` projects equations across unique factor levels using matrix projections:

```r
model_data <- transform(mtcars, cyl = factor(cyl))
fit_factor <- lm(mpg ~ wt + cyl, data = model_data)

# Stratify equations by 'cyl'
eq_subgroups <- extract_mixed_equation(fit_factor, by_factor = "cyl", digits = 2)
print(eq_subgroups)
#> Model Equation Collection [lm -> mpg]
#> 
#>   cyl=4                          : mpg = 33.99 - 3.21*wt + e
#>   cyl=6                          : mpg = 29.73 - 3.21*wt + e
#>   cyl=8                          : mpg = 27.93 - 3.21*wt + e
```

---

### 3. Mixed-Effects Models (`lme4` & `glmmTMB`)

#### Population-Level (Fixed Effects)

```r
library(lme4)

fit_lmer <- lmer(Reaction ~ Days + (Days | Subject), data = sleepstudy)

eq_lmer <- extract_mixed_equation(fit_lmer, digits = 2)
print(eq_lmer)
#> Model Equation Collection [lmerMod -> Reaction]
#> 
#>   Global                         : Reaction = 251.41 + 10.47*Days + [u]
```

#### Subject-Level Equations (`by_subject = TRUE`)

Extract subject-specific equations incorporating conditional modes (random intercepts and slopes):

```r
eq_subjects <- extract_mixed_equation(fit_lmer, digits = 2, by_subject = TRUE)

# View first few subject equations
head(as.data.frame(eq_subjects), 5)
#>      subgroup                                equation
#> 1 Subject=308 Reaction = 253.66 + 19.67*Days + [u]
#> 2 Subject=309  Reaction = 211.01 + 1.85*Days + [u]
#> 3 Subject=310  Reaction = 212.44 + 5.02*Days + [u]
#> 4 Subject=330  Reaction = 275.10 + 5.65*Days + [u]
#> 5 Subject=331  Reaction = 273.67 + 7.40*Days + [u]
```

#### Works standard with `glmmTMB`

```r
library(glmmTMB)

fit_tmb <- glmmTMB(Reaction ~ Days + (Days | Subject), data = sleepstudy)
eq_tmb <- extract_mixed_equation(fit_tmb, digits = 2)
print(eq_tmb)
```

---

## Extending `equationer` with Custom R6 Adapters

`equationer` uses an internal R6 class registry. If you work with a model framework that is not supported out of the box, you can implement a custom `ModelAdapter` and register it via `register_model_adapter()`.

Below is a complete, production-ready example extending `equationer` to support Generalized Additive Models (`mgcv::gam`).

### Step 1: Define the Adapter Class

Inherit from `ModelAdapter` and implement the core interface methods:

```r
library(mgcv)

AdapterGAM <- R6::R6Class("AdapterGAM",
  inherit = ModelAdapter,
  public = list(
    get_response_name = function() {
      as.character(formula(self$model))[2]
    },
    
    get_fixed_effects = function() {
      # Use S3 coef generic dispatch
      coef(self$model)
    },
    
    get_data = function() {
      self$model$model
    },
    
    get_error_label = function() {
      " + e"
    }
  )
)
```

### Step 2: Register the Adapter

Register your R6 class generator with the target model class name:

```r
register_model_adapter("gam", AdapterGAM)
```

### Step 3: Extract Equations from the New Model Class

Once registered, any fitted `gam` object works natively with `extract_mixed_equation()`:

```r
fit_gam <- gam(mpg ~ wt + hp + gear, data = mtcars)

eq_gam <- extract_mixed_equation(fit_gam, digits = 2)
print(eq_gam)
#> Model Equation Collection [gam -> mpg]
#> 
#>   Global                         : mpg = 24.32 - 3.33*wt - 0.03*hp + 1.22*gear + e
```

---

## License

This package is licensed under the [MIT License](LICENSE).