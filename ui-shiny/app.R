library(shiny)
library(httr2)

api_base <- Sys.getenv("API_BASE_URL", unset = "http://api:8001")

unwrap_value <- function(x) {
  if (is.list(x) && length(x) == 1) {
    return(unwrap_value(x[[1]]))
  }
  if (length(x) == 1) {
    return(x[[1]])
  }
  x
}

to_sample_data_frame <- function(payload) {
  samples <- payload$samples

  if (is.null(samples) || length(samples) == 0) {
    return(data.frame(
      sample_id = character(),
      patient_id = character(),
      test_type = character(),
      status = character(),
      created_at = character(),
      updated_at = character(),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(samples, function(sample) {
    data.frame(
      sample_id = as.character(unwrap_value(sample$sample_id)),
      patient_id = as.character(unwrap_value(sample$patient_id)),
      test_type = as.character(unwrap_value(sample$test_type)),
      status = as.character(unwrap_value(sample$status)),
      created_at = as.character(unwrap_value(sample$created_at)),
      updated_at = as.character(unwrap_value(sample$updated_at)),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

get_samples <- function() {
  response <- request(paste0(api_base, "/samples")) |>
    req_timeout(10) |>
    req_perform()

  resp_body_json(response, simplifyVector = FALSE)
}

create_sample <- function(sample_id, patient_id, test_type, status) {
  response <- request(paste0(api_base, "/samples")) |>
    req_method("POST") |>
    req_body_json(list(
      sample_id = sample_id,
      patient_id = patient_id,
      test_type = test_type,
      status = status
    )) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  list(
    status_code = resp_status(response),
    body = resp_body_json(response, simplifyVector = FALSE)
  )
}

update_status <- function(sample_id, status) {
  response <- request(paste0(api_base, "/samples/", URLencode(sample_id, reserved = TRUE))) |>
    req_method("PATCH") |>
    req_body_json(list(status = status)) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  list(
    status_code = resp_status(response),
    body = resp_body_json(response, simplifyVector = FALSE)
  )
}

ui <- fluidPage(
  tags$head(
    tags$title("Genome Lab Sample Tracker – Shiny UI"),
    tags$style(HTML("
      body { padding-top: 20px; }
      .app-note { color: #555; margin-bottom: 22px; }
      .section-card {
        border: 1px solid #d9d9d9;
        border-radius: 8px;
        padding: 18px;
        margin-bottom: 20px;
        background: #fff;
      }
    "))
  ),

  titlePanel("Genome Lab Sample Tracker – Shiny UI"),

  p(
    class = "app-note",
    "Demonstration interface only. Use synthetic data; this prototype is not for clinical use."
  ),

  fluidRow(
    column(
      width = 5,
      div(
        class = "section-card",
        h3("Create sample"),
        textInput("sample_id", "Sample ID"),
        textInput("patient_id", "Patient ID"),
        textInput("test_type", "Test Type", value = "WGS"),
        selectInput(
          "create_status",
          "Initial Status",
          choices = c("RECEIVED", "EXTRACTED", "SEQUENCED", "REPORTED")
        ),
        actionButton("create_sample", "Create Sample", class = "btn-primary"),
        br(), br(),
        uiOutput("create_message")
      )
    ),

    column(
      width = 7,
      div(
        class = "section-card",
        h3("Update sample status"),
        textInput("update_sample_id", "Sample ID"),
        selectInput(
          "update_status",
          "New Status",
          choices = c("RECEIVED", "EXTRACTED", "SEQUENCED", "REPORTED")
        ),
        actionButton("update_sample", "Update Status", class = "btn-warning"),
        br(), br(),
        uiOutput("update_message")
      )
    )
  ),

  div(
    class = "section-card",
    fluidRow(
      column(8, h3("Sample list")),
      column(
        4,
        div(
          style = "text-align: right; padding-top: 15px;",
          actionButton("refresh_samples", "Refresh List")
        )
      )
    ),
    tableOutput("sample_table"),
    br(),
    uiOutput("load_message")
  )
)

server <- function(input, output, session) {
  samples_data <- reactiveVal(data.frame())
  load_error <- reactiveVal(NULL)
  create_notice <- reactiveVal(NULL)
  update_notice <- reactiveVal(NULL)

  refresh_samples <- function() {
    tryCatch({
      payload <- get_samples()
      samples_data(to_sample_data_frame(payload))
      load_error(NULL)
    }, error = function(e) {
      load_error(paste("Could not load samples from the API:", conditionMessage(e)))
    })
  }

  observeEvent(input$refresh_samples, {
    refresh_samples()
  })

  observe({
    refresh_samples()
  })

  observeEvent(input$create_sample, {
    create_notice(NULL)

    if (!nzchar(trimws(input$sample_id)) ||
        !nzchar(trimws(input$patient_id)) ||
        !nzchar(trimws(input$test_type))) {
      create_notice(list(type = "error", text = "Sample ID, Patient ID, and Test Type are required."))
      return()
    }

    tryCatch({
      result <- create_sample(
        trimws(input$sample_id),
        trimws(input$patient_id),
        trimws(input$test_type),
        input$create_status
      )

      if (result$status_code == 201) {
        create_notice(list(type = "success", text = "Sample created successfully."))
        updateTextInput(session, "sample_id", value = "")
        updateTextInput(session, "patient_id", value = "")
        refresh_samples()
      } else {
        message_text <- if (!is.null(result$body$error)) {
          unwrap_value(result$body$error)
        } else {
          "The API did not accept the request."
        }
        create_notice(list(type = "error", text = as.character(message_text)))
      }
    }, error = function(e) {
      create_notice(list(type = "error", text = conditionMessage(e)))
    })
  })

  observeEvent(input$update_sample, {
    update_notice(NULL)

    if (!nzchar(trimws(input$update_sample_id))) {
      update_notice(list(type = "error", text = "Sample ID is required."))
      return()
    }

    tryCatch({
      result <- update_status(trimws(input$update_sample_id), input$update_status)

      if (result$status_code == 200) {
        update_notice(list(type = "success", text = "Sample status updated successfully."))
        refresh_samples()
      } else {
        message_text <- if (!is.null(result$body$error)) {
          unwrap_value(result$body$error)
        } else {
          "The API did not accept the update."
        }
        update_notice(list(type = "error", text = as.character(message_text)))
      }
    }, error = function(e) {
      update_notice(list(type = "error", text = conditionMessage(e)))
    })
  })

  output$sample_table <- renderTable({
    samples_data()
  }, striped = TRUE, bordered = TRUE, spacing = "s")

  output$load_message <- renderUI({
    if (!is.null(load_error())) {
      div(class = "alert alert-danger", load_error())
    }
  })

  output$create_message <- renderUI({
    notice <- create_notice()
    if (is.null(notice)) {
      return(NULL)
    }

    css_class <- if (notice$type == "success") "alert alert-success" else "alert alert-danger"
    div(class = css_class, notice$text)
  })

  output$update_message <- renderUI({
    notice <- update_notice()
    if (is.null(notice)) {
      return(NULL)
    }

    css_class <- if (notice$type == "success") "alert alert-success" else "alert alert-danger"
    div(class = css_class, notice$text)
  })
}

shinyApp(ui, server)
