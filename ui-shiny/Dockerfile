FROM rocker/r-ver:4.4.3

ENV R_LIBS_USER=/usr/local/lib/R/site-library
ENV SHINY_PORT=3838

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libuv1 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/lib/R/site-library

RUN Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest")); install.packages(c("shiny", "httr2", "jsonlite"), lib = Sys.getenv("R_LIBS_USER"), dependencies = TRUE, Ncpus = 2)'

RUN Rscript -e '.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths())); library(shiny); library(httr2); library(jsonlite); cat("Shiny UI dependencies installed successfully\n")'

WORKDIR /app
COPY app.R /app/app.R

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = as.integer(Sys.getenv('SHINY_PORT', '3838')))"]
