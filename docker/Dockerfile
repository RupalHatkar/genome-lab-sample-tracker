FROM rocker/r-ver:4.4.3

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libsqlite3-dev \
    libuv1 \
    && rm -rf /var/lib/apt/lists/*

ENV R_LIBS_USER=/usr/local/lib/R/site-library

RUN mkdir -p ${R_LIBS_USER}

RUN Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest")); install.packages(c("plumber", "jsonlite", "DBI", "RSQLite", "fs"), lib = Sys.getenv("R_LIBS_USER"), dependencies = TRUE, Ncpus = 2)'

RUN Rscript -e '.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths())); print(.libPaths()); library(plumber); library(jsonlite); library(DBI); library(RSQLite); library(fs); cat("R API dependencies installed successfully\n")'

WORKDIR /app

COPY R/ /app/R/
COPY entrypoint.R /app/entrypoint.R

RUN mkdir -p /data

ENV PORT=8001
ENV SAMPLE_TRACKER_DB=/data/samples.sqlite

EXPOSE 8001

CMD ["Rscript", "entrypoint.R"]