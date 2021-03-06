#' @inheritParams insight::get_parameters
#' @export
model_parameters.bamlss <- function(model,
                                    centrality = "median",
                                    dispersion = FALSE,
                                    ci = .89,
                                    ci_method = "hdi",
                                    test = c("pd", "rope"),
                                    rope_range = "default",
                                    rope_ci = 1.0,
                                    component = "all",
                                    exponentiate = FALSE,
                                    standardize = NULL,
                                    verbose = TRUE,
                                    ...) {
  modelinfo <- insight::model_info(model)

  # Processing
  params <- .extract_parameters_bayesian(
    model,
    centrality = centrality,
    dispersion = dispersion,
    ci = ci,
    ci_method = ci_method,
    test = test,
    rope_range = rope_range,
    rope_ci = rope_ci,
    bf_prior = NULL,
    diagnostic = NULL,
    priors = NULL,
    effects = "all",
    component = component,
    standardize = standardize,
    ...
  )

  params <- .add_pretty_names(params, model)
  if (exponentiate) params <- .exponentiate_parameters(params)
  params <- .add_model_parameters_attributes(params, model, ci, exponentiate, ci_method = ci_method, verbose = verbose, ...)

  attr(params, "parameter_info") <- insight::clean_parameters(model)
  attr(params, "object_name") <- deparse(substitute(model), width.cutoff = 500)
  class(params) <- unique(c("parameters_stan", "see_parameters_model", "parameters_model", class(params)))

  params
}


#' @export
standard_error.bamlss <- function(model,
                                  component = c("all", "conditional", "location", "distributional", "auxilliary"),
                                   ...) {
  component <- match.arg(component)
  params <- insight::get_parameters(model, component = component, ...)

  .data_frame(
    Parameter = colnames(params),
    SE = unname(sapply(params, stats::sd, na.rm = TRUE))
  )
}


#' @export
p_value.bamlss <- p_value.BFBayesFactor
