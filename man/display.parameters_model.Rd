% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/display.R, R/format.R, R/print_html.R,
%   R/print_md.R
\name{display.parameters_model}
\alias{display.parameters_model}
\alias{display.parameters_stan}
\alias{display.parameters_sem}
\alias{display.parameters_efa_summary}
\alias{display.parameters_efa}
\alias{display.equivalence_test_lm}
\alias{format.parameters_model}
\alias{print_html.parameters_model}
\alias{print_md.parameters_model}
\title{Print tables in different output formats}
\usage{
\method{display}{parameters_model}(
  object,
  format = "markdown",
  pretty_names = TRUE,
  split_components = TRUE,
  select = NULL,
  caption = NULL,
  subtitle = NULL,
  footer = NULL,
  align = NULL,
  digits = 2,
  ci_digits = 2,
  p_digits = 3,
  ci_brackets = c("(", ")"),
  ...
)

\method{display}{parameters_stan}(
  object,
  split_components = TRUE,
  select = NULL,
  format = "markdown",
  ...
)

\method{display}{parameters_sem}(
  object,
  format = "markdown",
  digits = 2,
  ci_digits = 2,
  p_digits = 3,
  ci_brackets = c("(", ")"),
  ...
)

\method{display}{parameters_efa_summary}(object, format = "markdown", digits = 3, ...)

\method{display}{parameters_efa}(
  object,
  format = "markdown",
  digits = 2,
  sort = FALSE,
  threshold = NULL,
  labels = NULL,
  ...
)

\method{display}{equivalence_test_lm}(object, format = "markdown", digits = 2, ...)

\method{format}{parameters_model}(
  x,
  pretty_names = TRUE,
  split_components = TRUE,
  select = NULL,
  digits = 2,
  ci_digits = 2,
  p_digits = 3,
  ci_width = NULL,
  ci_brackets = NULL,
  format = NULL,
  ...
)

\method{print_html}{parameters_model}(
  x,
  pretty_names = TRUE,
  split_components = TRUE,
  select = NULL,
  caption = NULL,
  subtitle = NULL,
  footer = NULL,
  align = NULL,
  digits = 2,
  ci_digits = 2,
  p_digits = 3,
  ci_brackets = c("(", ")"),
  show_sigma = FALSE,
  show_formula = FALSE,
  verbose = TRUE,
  ...
)

\method{print_md}{parameters_model}(
  x,
  pretty_names = TRUE,
  split_components = TRUE,
  select = NULL,
  caption = NULL,
  subtitle = NULL,
  footer = NULL,
  digits = 2,
  ci_digits = 2,
  p_digits = 3,
  ci_brackets = c("(", ")"),
  ...
)
}
\arguments{
\item{object}{An object returned by \code{\link[=model_parameters]{model_parameters()}},
\code{\link[=simulate_parameters]{simulate_parameters()}},
\code{\link[=equivalence_test.lm]{equivalence_test()}} or
\code{\link[=principal_components]{principal_components()}}.}

\item{format}{String, indicating the output format. Can be \code{"markdown"}
or \code{"html"}.}

\item{pretty_names}{Return "pretty" (i.e. more human readable) parameter names.}

\item{split_components}{Logical, if \code{TRUE} (default), For models with
multiple components (zero-inflation, smooth terms, ...), each component is
printed in a separate table. If \code{FALSE}, model parameters are printed
in a single table and a \code{Component} column is added to the output.}

\item{select}{Character vector (or numeric index) of column names that should
be printed. If \code{NULL} (default), all columns are printed. The shortcut
\code{select = "minimal"} prints coefficient, confidence intervals and p-values,
while \code{select = "short"} prints coefficient, standard errors and p-values.}

\item{caption}{Table caption and subtitle, as string. If \code{NULL},
no caption or subtitle is printed.}

\item{subtitle}{Table caption and subtitle, as string. If \code{NULL},
no caption or subtitle is printed.}

\item{footer}{Table footer, as string. For markdown-formatted tables, table
footers, due to the limitation in markdown rendering, are actually just a
new text line under the table.}

\item{align}{Only applies to HTML tables. May be one of \code{"left"},
\code{"right"} or \code{"center"}.}

\item{digits}{Number of decimal places for numeric values (except confidence intervals and p-values).}

\item{ci_digits}{Number of decimal places for confidence intervals.}

\item{p_digits}{Number of decimal places for p-values. May also be \code{"scientific"} for scientific notation of p-values.}

\item{ci_brackets}{Logical, if \code{TRUE} (default), CI-values are encompassed in square brackets (else in parentheses).}

\item{...}{Arguments passed to or from other methods.}

\item{sort}{Sort the loadings.}

\item{threshold}{A value between 0 and 1 indicates which (absolute) values from the loadings should be removed. An integer higher than 1 indicates the n strongest loadings to retain. Can also be \code{"max"}, in which case it will only display the maximum loading per variable (the most simple structure).}

\item{labels}{A character vector containing labels to be added to the loadings data. Usually, the question related to the item.}

\item{x}{An object returned by \code{\link[=model_parameters]{model_parameters()}}.}

\item{ci_width}{Minimum width of the returned string for confidence intervals. If not \code{NULL} and width is larger than the string's length, leading whitespaces are added to the string. If \code{width="auto"}, width will be set to the length of the longest string.}

\item{show_sigma}{Logical, if \code{TRUE}, adds information about the residual
standard deviation.}

\item{show_formula}{Logical, if \code{TRUE}, adds the model formula to the output.}

\item{verbose}{Toggle warnings and messages.}
}
\value{
A character vector. If \code{format = "markdown"}, the return value
  will be a character vector in markdown-table format.
}
\description{
Prints tables (i.e. data frame) in different output formats.
  \code{print_md()} is a alias for \code{display(format = "markdown")}.
}
\details{
\code{display()} is useful when the table-output from functions,
  which is usually printed as formatted text-table to console, should
  be formatted for pretty table-rendering in markdown documents, or if
  knitted from rmarkdown to PDF or Word files. See
  \href{https://easystats.github.io/parameters/articles/model_parameters_formatting.html}{vignette}
  for examples.
}
\examples{
model <- lm(mpg ~ wt + cyl, data = mtcars)
mp <- model_parameters(model)
display(mp)
}
