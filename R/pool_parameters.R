#' Pool Model Parameters
#'
#' This function "pools" (i.e. combines) model parameters in a similar fashion as \code{mice::pool()}. However, this function pools parameters from \code{parameters_model} objects, as returned by \code{\link{model_parameters}}.
#'
#' @param x A list of \code{parameters_model} objects, as returned by
#'   \code{\link{model_parameters}}, or a list of model-objects that is
#'   supported by \code{model_parameters()}.
#' @param ... Currently not used.
#' @inheritParams model_parameters.default
#' @inheritParams bootstrap_model
#' @inheritParams model_parameters.merMod
#'
#' @note Models with multiple components, (for instance, models with zero-inflation,
#'   where predictors appear in the count and zero-inflated part) may fail in
#'   case of identical names for coefficients in the different model components,
#'   since the coefficient table is grouped by coefficient names for pooling. In
#'   such cases, coefficients of count and zero-inflated model parts would be
#'   combined. Therefore, the \code{component} argument defaults to
#'   \code{"conditional"} to avoid this.
#'
#' @details Averaging of parameters follows Rubin's rules (\cite{Rubin, 1987, p. 76}).
#'   The pooled degrees of freedom is based on the Barnard-Rubin adjustment for
#'   small samples (\cite{Barnard and Rubin, 1999}).
#'
#' @references
#' Barnard, J. and Rubin, D.B. (1999). Small sample degrees of freedom with multiple imputation. Biometrika, 86, 948-955.
#' Rubin, D.B. (1987). Multiple Imputation for Nonresponse in Surveys. New York: John Wiley and Sons.
#'
#' @examples
#' # example for multiple imputed datasets
#' if (require("mice")) {
#'   data("nhanes2")
#'   imp <- mice(nhanes2, printFlag = FALSE)
#'   models <- lapply(1:5, function(i) {
#'     lm(bmi ~ age + hyp + chl, data = complete(imp, action = i))
#'   })
#'   pool_parameters(models)
#'
#'   # should be identical to:
#'   m <- with(data = imp, exp = lm(bmi ~ age + hyp + chl))
#'   summary(pool(m))
#' }
#' @return A data frame of indices related to the model's parameters.
#' @importFrom stats var pt
#' @importFrom insight is_model_supported is_model
#' @export
pool_parameters <- function(x,
                            exponentiate = FALSE,
                            component = "conditional",
                            details = FALSE,
                            verbose = TRUE,
                            ...) {

  # check input, save original model -----

  original_model <- NULL
  obj_name <- deparse(substitute(x), width.cutoff = 500)

  if (all(sapply(x, insight::is_model)) && all(sapply(x, insight::is_model_supported))) {
    original_model <- x[[1]]
    x <- lapply(x, model_parameters, component = component, details = details, ...)
  }

  if (!all(sapply(x, inherits, "parameters_model"))) {
    stop("'x' must be a list of 'parameters_model' objects, as returned by the 'model_parameters()' function.", call. = FALSE)
  }

  if (is.null(original_model)) {
    original_model <- .get_object(x[[1]])
  }

  if (isTRUE(attributes(x[[1]])$exponentiate)) {
    warning("Pooling on exponentiated parameters is not recommended. Please call 'model_parameters()' with 'exponentiate = FALSE', and rather call 'pool_parameters(..., exponentiate = TRUE)'.", call. = FALSE)
  }


  # only pool for specific component -----

  original_x <- x
  if ("Component" %in% colnames(x[[1]]) && !.is_empty_object(component) && component != "all") {
    x <- lapply(x, function(i) {
      i <- i[i$Component == component, ]
      i$Component <- NULL
      i
    })
    warning(paste0("Pooling applied to the ", component, " model component."), call. = FALSE)
  }


  # preparation ----

  params <- do.call(rbind, x)
  len <- length(x)
  ci <- attributes(original_x[[1]])$ci
  if (is.null(ci)) ci <- .95


  # split multiply (imputed) datasets by parameters

  estimates <- split(params, factor(params$Parameter, levels = unique(x[[1]]$Parameter)))


  # pool estimates etc. -----

  pooled_params <- do.call(rbind, lapply(estimates, function(i) {
    # pooled estimate
    pooled_estimate <- mean(i$Coefficient)

    # pooled standard error
    ubar <- mean(i$SE^2)
    tmp <- ubar + (1 + 1 / len) * stats::var(i$Coefficient)
    pooled_se <- sqrt(tmp)

    # pooled degrees of freedom, Barnard-Rubin adjustment for small samples
    df_column <- colnames(i)[grepl("(\\bdf\\b|\\bdf_error\\b)", colnames(i))][1]
    if (length(df_column)) {
      pooled_df <- .barnad_rubin(m = nrow(i), b = stats::var(i$Coefficient), t = tmp, dfcom = unique(i[[df_column]]))
    } else {
      pooled_df <- Inf
    }

    # pooled statistic
    pooled_statistic <- pooled_estimate / pooled_se

    # confidence intervals
    alpha <- (1 + ci) / 2
    fac <- suppressWarnings(stats::qt(alpha, df = pooled_df))

    data.frame(
      Coefficient = pooled_estimate,
      SE = pooled_se,
      CI_low = pooled_estimate - pooled_se * fac,
      CI_high = pooled_estimate + pooled_se * fac,
      Statistic = pooled_statistic,
      df_error = pooled_df,
      p = 2 * stats::pt(abs(pooled_statistic), df = pooled_df, lower.tail = FALSE)
    )
  }))


  # pool random effect variances -----

  pooled_random <- NULL
  if (details && !is.null(attributes(original_x[[1]])$details)) {
    pooled_random <- attributes(original_x[[1]])$details
    n_rows <- nrow(pooled_random)
    for (i in 1:n_rows) {
      re <- unlist(lapply(original_x, function(j) {
        # random effects
        attributes(j)$details$Value[i]
      }))
      pooled_random$Value[i] <- mean(re, na.rm = TRUE)
    }
  }


  # reorder ------

  pooled_params$Parameter <- x[[1]]$Parameter
  pooled_params <- pooled_params[c("Parameter", "Coefficient", "SE", "CI_low", "CI_high", "Statistic", "df_error", "p")]


  # final attributes -----

  if (exponentiate) pooled_params <- .exponentiate_parameters(pooled_params)
  # this needs to be done extra here, cannot call ".add_model_parameters_attributes()"
  pooled_params <- .add_pooled_params_attributes(
    pooled_params,
    model_params = original_x[[1]],
    model = original_model,
    ci,
    exponentiate,
    verbose = verbose
  )
  attr(pooled_params, "object_name") <- obj_name
  attr(pooled_params, "details") <- pooled_random


  # pool sigma ----

  sig <- unlist(.compact_list(lapply(original_x, function(i) {
    attributes(i)$sigma
  })))

  if (!.is_empty_object(sig)) {
    attr(pooled_params, "sigma") <- mean(sig, na.rm = TRUE)
  }


  class(pooled_params) <- c("parameters_model", "see_parameters_model", class(pooled_params))
  pooled_params
}




# helper ------


.barnad_rubin <- function(m, b, t, dfcom = 999999) {
  # fix for z-statistic
  if (is.null(dfcom) || all(is.na(dfcom)) || all(is.infinite(dfcom))) {
    return(Inf)
  }
  lambda <- (1 + 1 / m) * b / t
  lambda[lambda < 1e-04] <- 1e-04
  dfold <- (m - 1) / lambda^2
  dfobs <- (dfcom + 1) / (dfcom + 3) * dfcom * (1 - lambda)
  dfold * dfobs / (dfold + dfobs)
}



#' @importFrom insight find_formula
.add_pooled_params_attributes <- function(pooled_params, model_params, model, ci, exponentiate, verbose = TRUE) {
  info <- insight::model_info(model, verbose = FALSE)
  pretty_names <- attributes(model_params)$pretty_names
  if (length(pretty_names) < nrow(model_params)) {
    pretty_names <- c(pretty_names, model_params$Parameter[(length(pretty_names) + 1):nrow(model_params)])
  }
  attr(pooled_params, "ci") <- ci
  attr(pooled_params, "exponentiate") <- exponentiate
  attr(pooled_params, "pretty_names") <- pretty_names
  attr(pooled_params, "verbose") <- verbose
  attr(pooled_params, "ordinal_model") <- attributes(pooled_params)$ordinal_model
  attr(pooled_params, "model_class") <- attributes(pooled_params)$model_class
  attr(pooled_params, "bootstrap") <- attributes(pooled_params)$bootstrap
  attr(pooled_params, "iterations") <- attributes(pooled_params)$iterations
  attr(pooled_params, "df_method") <- attributes(pooled_params)$df_method
  attr(pooled_params, "digits") <- attributes(pooled_params)$digits
  attr(pooled_params, "ci_digits") <- attributes(pooled_params)$ci_digits
  attr(pooled_params, "p_digits") <- attributes(pooled_params)$p_digits
  # column name for coefficients
  coef_col <- .find_coefficient_type(info, exponentiate)
  attr(pooled_params, "coefficient_name") <- coef_col
  attr(pooled_params, "zi_coefficient_name") <- ifelse(isTRUE(exponentiate), "Odds Ratio", "Log-Odds")
  # formula
  attr(pooled_params, "model_formula") <- insight::find_formula(model)
  pooled_params
}
