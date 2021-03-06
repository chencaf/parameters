% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods_aov.R
\name{model_parameters.aov}
\alias{model_parameters.aov}
\title{Parameters from ANOVAs}
\usage{
\method{model_parameters}{aov}(
  model,
  omega_squared = NULL,
  eta_squared = NULL,
  epsilon_squared = NULL,
  df_error = NULL,
  type = NULL,
  ci = NULL,
  test = NULL,
  power = FALSE,
  verbose = TRUE,
  ...
)
}
\arguments{
\item{model}{Object of class \code{\link{aov}}, \code{\link{anova}}, \code{aovlist}, \code{Gam}, \code{\link{manova}}, \code{Anova.mlm}, \code{afex_aov} or \code{maov}.}

\item{omega_squared}{Compute omega squared as index of effect size. Can be \code{"partial"} (the default, adjusted for effect size) or \code{"raw"}.}

\item{eta_squared}{Compute eta squared as index of effect size. Can be \code{"partial"} (the default, adjusted for effect size), \code{"raw"}  or \code{"adjusted"} (the latter option only for ANOVA-tables from mixed models).}

\item{epsilon_squared}{Compute epsilon squared as index of effect size. Can be \code{"partial"} (the default, adjusted for effect size) or \code{"raw"}.}

\item{df_error}{Denominator degrees of freedom (or degrees of freedom of the error estimate, i.e., the residuals). This is used to compute effect sizes for ANOVA-tables from mixed models. See 'Examples'. (Ignored for \code{afex_aov}.)}

\item{type}{Numeric, type of sums of squares. May be 1, 2 or 3. If 2 or 3, ANOVA-tables using \code{car::Anova()} will be returned. (Ignored for \code{afex_aov}.)}

\item{ci}{Confidence Interval (CI) level for effect sizes \code{omega_squared}, \code{eta_squared} etc. The default, \code{NULL}, will compute no confidence intervals. \code{ci} should be a scalar between 0 and 1.}

\item{test}{String, indicating the type of test for \code{Anova.mlm} to be returned. If \code{"multivariate"} (or \code{NULL}), returns the summary of the multivariate test (that is also given by the \code{print}-method). If \code{test = "univariate"}, returns the summary of the univariate test.}

\item{power}{Logical, if \code{TRUE}, adds a column with power for each parameter.}

\item{verbose}{Toggle warnings and messages.}

\item{...}{Arguments passed to or from other methods.}
}
\value{
A data frame of indices related to the model's parameters.
}
\description{
Parameters from ANOVAs
}
\note{
For ANOVA-tables from mixed models (i.e. \code{anova(lmer())}), only partial or adjusted effect sizes can be computed.
}
\examples{
if (requireNamespace("effectsize", quietly = TRUE)) {
  df <- iris
  df$Sepal.Big <- ifelse(df$Sepal.Width >= 3, "Yes", "No")

  model <- aov(Sepal.Length ~ Sepal.Big, data = df)
  model_parameters(
    model,
    omega_squared = "partial",
    eta_squared = "partial",
    epsilon_squared = "partial"
  )

  model_parameters(
    model,
    omega_squared = "partial",
    eta_squared = "partial",
    ci = .9
  )

  model <- anova(lm(Sepal.Length ~ Sepal.Big, data = df))
  model_parameters(model)
  model_parameters(
    model,
    omega_squared = "partial",
    eta_squared = "partial",
    epsilon_squared = "partial"
  )

  model <- aov(Sepal.Length ~ Sepal.Big + Error(Species), data = df)
  model_parameters(model)

  if (require("lme4")) {
    mm <- lmer(Sepal.Length ~ Sepal.Big + Petal.Width + (1 | Species),
      data = df
    )
    model <- anova(mm)

    # simple parameters table
    model_parameters(model)

    # parameters table including effect sizes
    model_parameters(
      model,
      eta_squared = "partial",
      ci = .9,
      df_error = dof_satterthwaite(mm)
    )
  }
}
}
