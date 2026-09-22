# entrypoint.R
library(plumber)

# Source API
pr <- plumber::plumb("R/api.R")

port <- as.integer(Sys.getenv("PORT", 8000))
pr$run(port = port, host = "0.0.0.0")