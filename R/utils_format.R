# helper ------------------------

.prepare_x_for_print <- function(x, select, coef_name, s_value) {
  # minor fix for nested Anovas
  if ("Group" %in% colnames(x) && sum(x$Parameter == "Residuals") > 1) {
    colnames(x)[which(colnames(x) == "Group")] <- "Subgroup"
  }

  if (!is.null(select)) {
    if (all(select == "minimal")) {
      select <- c("Parameter", "Coefficient", "CI", "CI_low", "CI_high", "p")
    } else if (all(select == "short")) {
      select <- c("Parameter", "Coefficient", "SE", "p")
    } else if (is.numeric(select)) {
      select <- colnames(x)[select]
    }
    select <- union(select, c("Parameter", "Component", "Effects", "Response", "Subgroup"))
    # for emmGrid objects, we save specific parameter names as attribute
    parameter_names <- attributes(x)$parameter_names
    if (!is.null(parameter_names)) {
      select <- c(parameter_names, select)
    }
    to_remove <- setdiff(colnames(x), select)
    x[to_remove] <- NULL
  }

  # remove columns that have only NA or Inf
  to_remove <- sapply(x, function(col) all(is.na(col) | is.infinite(col)))
  if (any(to_remove)) x[to_remove] <- NULL

  # For Bayesian models, we need to prettify parameter names here...
  mc <- attributes(x)$model_class
  cp <- attributes(x)$cleaned_parameters
  if (!is.null(mc) && !is.null(cp) && mc %in% c("stanreg", "stanmvreg", "brmsfit")) {
    if (length(cp) == length(x$Parameter)) {
      x$Parameter <- cp
    }
    pretty_names <- FALSE
  }

  # for bayesian meta, remove ROPE_CI
  if (isTRUE(attributes(x)$is_bayes_meta)) {
    x$CI <- NULL
    x$ROPE_CI <- NULL
    x$ROPE_low <- NULL
    x$ROPE_high <- NULL
  }

  if (!is.null(coef_name)) {
    colnames(x)[which(colnames(x) == "Coefficient")] <- coef_name
    colnames(x)[which(colnames(x) == "Std_Coefficient")] <- paste0("Std_", coef_name)
  }

  if (isTRUE(s_value) && "p" %in% colnames(x)) {
    colnames(x)[colnames(x) == "p"] <- "s"
    x[["s"]] <- log2(1 / x[["s"]])
  }

  x
}



.prepare_splitby_for_print <- function(x) {
  split_by <- ""
  split_by <- c(split_by, ifelse("Component" %in% names(x) && .n_unique(x$Component) > 1, "Component", ""))
  split_by <- c(split_by, ifelse("Effects" %in% names(x) && .n_unique(x$Effects) > 1, "Effects", ""))
  split_by <- c(split_by, ifelse("Response" %in% names(x) && .n_unique(x$Response) > 1, "Response", ""))
  split_by <- c(split_by, ifelse("Subgroup" %in% names(x) && .n_unique(x$Subgroup) > 1, "Subgroup", ""))

  split_by <- split_by[nchar(split_by) > 0]
  split_by
}





# this function is actually similar to "insight::print_parameters()", but more
# sophisticated, to ensure nicely outputs even for complicated or complex models,
# or edge cases...

#' @keywords internal
.print_model_parms_components <- function(x, pretty_names, split_column = "Component", digits = 2, ci_digits = 2, p_digits = 3, coef_column = NULL, format = NULL, ci_width = "auto", ci_brackets = TRUE, ...) {
  final_table <- list()

  # check if user supplied digits attributes
  is_ordinal_model <- attributes(x)$ordinal_model
  if (is.null(is_ordinal_model)) is_ordinal_model <- FALSE

  # zero-inflated stuff
  is_zero_inflated <- (!is.null(x$Component) & "zero_inflated" %in% x$Component)
  zi_coef_name <- attributes(x)$zi_coefficient_name

  # make sure we have correct order of levels from split-factor
  if (!is.null(attributes(x)$model_class) && all(attributes(x)$model_class == "mediate")) {
    x$Component <- factor(x$Component, levels = c("control", "treated", "average", "Total Effect"))
    x$Parameter <- trimws(gsub("(.*)\\((.*)\\)$", "\\1", x$Parameter))
  } else {
    x[split_column] <- lapply(x[split_column], function(i) {
      if (!is.factor(i)) i <- factor(i, levels = unique(i))
      i
    })
  }

  # fix column output
  if (inherits(attributes(x)$model, c("lavaan", "blavaan")) && "Label" %in% colnames(x)) {
    x$From <- ifelse(x$Label == "" | x$Label == x$To, x$From, paste0(x$From, " (", x$Label, ")"))
    x$Label <- NULL
  }

  # set up split-factor
  if (length(split_column) > 1) {
    split_by <- lapply(split_column, function(i) x[[i]])
  } else {
    split_by <- list(x[[split_column]])
  }
  names(split_by) <- split_column

  # make sure we have correct sorting here...
  tables <- split(x, f = split_by)

  # sanity check - only preserve tables with any data in data frames
  tables <- tables[sapply(tables, nrow) > 0]

  for (type in names(tables)) {

    # Don't print Component column
    for (i in split_column) {
      tables[[type]][[i]] <- NULL
    }

    # Smooth terms statistics
    if ("t / F" %in% names(tables[[type]])) {
      if (type == "smooth_terms") {
        names(tables[[type]])[names(tables[[type]]) == "t / F"] <- "F"
      }
      if (type == "conditional") {
        names(tables[[type]])[names(tables[[type]]) == "t / F"] <- "t"
      }
    } else if (type == "smooth_terms" && "t" %in% names(tables[[type]])) {
      names(tables[[type]])[names(tables[[type]]) == "t"] <- "F"
    }


    if ("z / Chi2" %in% names(tables[[type]])) {
      if (type == "smooth_terms") {
        names(tables[[type]])[names(tables[[type]]) == "z / Chi2"] <- "Chi2"
      }
      if (type == "conditional") {
        names(tables[[type]])[names(tables[[type]]) == "z / Chi2"] <- "z"
      }
    }

    # Don't print se and ci if all are missing
    if (all(is.na(tables[[type]]$SE))) tables[[type]]$SE <- NULL
    if (all(is.na(tables[[type]]$CI_low))) tables[[type]]$CI_low <- NULL
    if (all(is.na(tables[[type]]$CI_high))) tables[[type]]$CI_high <- NULL

    # Don't print if empty col
    tables[[type]][sapply(tables[[type]], function(x) {
      all(x == "") | all(is.na(x))
    })] <- NULL

    attr(tables[[type]], "digits") <- digits
    attr(tables[[type]], "ci_digits") <- ci_digits
    attr(tables[[type]], "p_digits") <- p_digits

    # rename columns for zero-inflation part
    if (grepl("^zero", type) && !is.null(zi_coef_name) && !is.null(coef_column)) {
      colnames(tables[[type]])[which(colnames(tables[[type]]) == coef_column)] <- zi_coef_name
      colnames(tables[[type]])[which(colnames(tables[[type]]) == paste0("Std_", coef_column))] <- paste0("Std_", zi_coef_name)
    }

    formatted_table <- insight::format_table(tables[[type]], pretty_names = pretty_names, ci_width = ci_width, ci_brackets = ci_brackets, ...)

    component_name <- switch(
      type,
      "mu" = ,
      "fixed" = ,
      "conditional" = "Fixed Effects",
      "random" = "Random Effects",
      "conditional.fixed" = ifelse(is_zero_inflated, "Fixed Effects (Count Model)", "Fixed Effects"),
      "conditional.random" = ifelse(is_zero_inflated, "Random Effects (Count Model)", "Random Effects"),
      "zero_inflated" = "Zero-Inflated",
      "zero_inflated.fixed" = "Fixed Effects (Zero-Inflated Model)",
      "zero_inflated.random" = "Random Effects (Zero-Inflated Model)",
      "dispersion" = "Dispersion",
      "marginal" = "Marginal Effects",
      "emmeans" = "Estimated Marginal Means",
      "contrasts" = "Contrasts",
      "simplex.fixed" = ,
      "simplex" = "Monotonic Effects",
      "smooth_sd" = "Smooth Terms (SD)",
      "smooth_terms" = "Smooth Terms",
      "sigma.fixed" = ,
      "sigma" = "Sigma",
      "Correlation" = "Correlation",
      "SD/Cor" = "SD / Correlation",
      "Loading" = "Loading",
      "scale" = ,
      "scale.fixed" = "Scale Parameters",
      "extra" = ,
      "extra.fixed" = "Extra Parameters",
      "nu" = "Nu",
      "tau" = "Tau",
      "meta" = "Meta-Parameters",
      "studies" = "Studies",
      "within" = "Within-Effects",
      "between" = "Between-Effects",
      "interactions" = "(Cross-Level) Interactions",
      "precision" = ,
      "precision." = "Precision",
      type
    )


    # tweaking of sub headers

    if ("DirichletRegModel" %in% attributes(x)$model_class) {
      if (grepl("^conditional\\.", component_name) || split_column == "Response") {
        s1 <- "Response level:"
        s2 <- gsub("^conditional\\.(.*)", "\\1", component_name)
      } else {
        s1 <- component_name
        s2 <- ""
      }
    } else if (length(split_column) > 1) {
      s1 <- component_name
      s2 <- ""
    } else if (split_column == "Response" && is_ordinal_model) {
      s1 <- "Response level:"
      s2 <- component_name
    } else if (split_column == "Subgroup") {
      s1 <- component_name
      s2 <- ""
    } else if (component_name %in% c("Within-Effects", "Between-Effects", "(Cross-Level) Interactions")) {
      s1 <- component_name
      s2 <- ""
    } else if (grepl(tolower(split_column), tolower(component_name), fixed = TRUE)) {
      s1 <- component_name
      s2 <- ""
    } else if (split_column == "Type") {
      s1 <- component_name
      s2 <- ""
    } else {
      s1 <- component_name
      s2 <- ifelse(tolower(split_column) == "component", "", split_column)
    }


    table_caption <- NULL
    if (is.null(format) || format == "text") {
      # Print
      if (component_name != "rewb-contextual") {
        table_caption <- c(sprintf("# %s %s", s1, tolower(s2)), "blue")
      }
    } else if (format %in% c("markdown", "html")) {
      # Print
      if (component_name != "rewb-contextual") {
        table_caption <- sprintf("%s %s", s1, tolower(s2))
      }
      # replace brackets by parenthesis
      formatted_table$Parameter <- gsub("[", "(", formatted_table$Parameter, fixed = TRUE)
      formatted_table$Parameter <- gsub("]", ")", formatted_table$Parameter, fixed = TRUE)
    }

    if (identical(format, "html")) {
      formatted_table$Component <- table_caption
    } else {
      attr(formatted_table, "table_caption") <- table_caption
    }

    final_table <- c(final_table, list(formatted_table))
  }

  if (identical(format, "html")) {
    do.call(rbind, final_table)
  } else {
    .compact_list(final_table)
  }
}
