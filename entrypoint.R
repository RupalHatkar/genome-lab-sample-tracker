library(plumber)

api_path <- Sys.getenv("API_PATH", "R/api.R")
port <- as.integer(Sys.getenv("PORT", "8001"))

pr <- plumber::plumb(api_path)

pr$run(
  host = "0.0.0.0",
  port = port
)