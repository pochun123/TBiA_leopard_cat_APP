library(shiny)
library(leaflet)
library(dplyr)
library(lubridate)
library(plotly)
library(bslib)
library(shinyjs)
library(reticulate)

Sys.setenv(RETICULATE_PYTHON = "/opt/venv/bin/python")
Sys.setenv(PATH = paste("/opt/venv/bin", Sys.getenv("PATH"), sep = ":"))
source_python("ssqa_hf.py")  # 載入 RAG 查詢函數

ui <- page_navbar(
  title = "石虎保育大數據與 AI 助手",
  theme = bs_theme(version = 5, bootswatch = "minty", primary = "#C19A6B"),
  useShinyjs(),
  
  # 自定義 CSS：處理懸浮聊天室
  tags$head(tags$style(HTML("
    #chat_fab { position: fixed; bottom: 25px; right: 25px; width: 60px; height: 60px; border-radius: 50%; z-index: 1000; box-shadow: 0 4px 15px rgba(0,0,0,0.3); }

    #chat_window { position: fixed; bottom: 95px; right: 25px; width: 350px; height: 420px; background: white; border-radius: 15px; display: flex; flex-direction: column; z-index: 1000; box-shadow: 0 5px 25px rgba(0,0,0,0.2); border: 1px solid #ddd; }

    .chat-header { background: #2c3e50; color: white; padding: 12px; border-radius: 15px 15px 0 0; display: flex; justify-content: space-between; align-items: center; }

    .chat-body { padding: 15px; flex-grow: 1; overflow-y: auto; background: #f9f9f9; font-size: 14px; display: flex; flex-direction: column; gap: 10px;}

    .chat-footer { 
      padding: 10px !important; 
      border-top: 1px solid #eee; 
      background: white; 
      border-radius: 0 0 15px 15px; 
    }

    /* 讓輸入框與按鈕並排 */
    .input-group-container {
      display: flex;
      gap: 5px;
      align-items: center;
    }

    /* 移除 Shiny 預設的 margin */
    .chat-footer .form-group { 
      margin-bottom: 0 !important;
    }

    /* 調整輸入框高度與按鈕一致 */
    #question {
      height: 38px;
    }

    .user-msg { text-align: right; margin-bottom: 10px; }

    .user-msg span { background: #007bff; color: white; padding: 8px 12px; border-radius: 15px; display: inline-block; max-width: 80%; }

    .ai-msg { text-align: left; margin-bottom: 10px; }

    .ai-msg span { background: #e9ecef; color: #333; padding: 8px 12px; border-radius: 15px; display: inline-block; max-width: 80%; }

  "))),
  
  # 分頁 1: 科普與參考資料
  nav_panel(
    title = "石虎科普與資料庫",
    icon = icon("circle-info"),
    
    # 使用 layout_column_wrap 取代原本錯誤的 container_fluid
    layout_column_wrap(
      width = 1, # 讓內容寬度佔滿
      style = "padding: 20px;", # 增加邊距讓內容不貼邊
      
      navset_card_pill(
        nav_panel(
          title = "石虎簡介",
          layout_column_wrap(
            width = 1/2, # 平分為左右兩欄
            # 左側文字
            div(
              h3("亞洲豹貓（石虎） Prionailurus bengalensis"),
              tags$hr(),
              p("石虎是台灣現存唯一的原生貓科野生動物，屬於亞洲豹貓的一個亞種。"),
              tags$ul(
                tags$li(tags$b("特徵："), "耳後有白斑、眼窩內側有兩條白線、身上有豹紋般的斑點。"),
                tags$li(tags$b("棲地："), "主要分佈於海拔 800 公尺以下的淺山環境，如草生地、林地。"),
                tags$li(tags$b("現況："), "目前族群數量估計僅剩約 500 隻，屬瀕危保育類動物。")
              )
            ),
            # 右側圖片
            div(
              tags$img(src = "shi.jpg", 
                       width = "100%", 
                       style = "border-radius: 15px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);")
            )
          )
        ),
        nav_panel(
          title = "參考資料與連結",
          card_body(
            h4("相關研究資源"),
            tags$ul(
              tags$li(tags$a("農業部生物多樣性研究所", href = "https://www.tbri.gov.tw/", target = "_blank")),
              tags$li(tags$a("台灣石虎保育協會", href = "https://www.lcactw.org/", target = "_blank")),
              tags$li(tags$a("環境資訊中心 - 石虎報導專區", href = "https://e-info.org.tw/", target = "_blank"))
            ),
            hr(),
            p(style = "color: gray; font-style: italic;", "本系統之數據僅供學術交流使用，若有引用需求請洽相關主管機關。")
          )
        )
      )
    )
  ),
  # 分頁 2: 數據地圖儀表板
  nav_panel(
    title = "地圖監測中心",
    layout_sidebar(
      sidebar = sidebar(
        title = "資料篩選",
        fileInput("file", "上傳石虎 CSV 檔案", accept = ".csv"),
        hr(),
        checkboxGroupInput("year", "選擇年份：", choices = NULL),
        actionButton("year_all", "全選/取消年份", class = "btn-sm"),
        hr(),
        selectInput("county", "選擇縣市：", choices = NULL),
        checkboxGroupInput("municipality", "選擇鄉鎮市：", choices = NULL),
        actionButton("municipality_all", "全選/取消鄉鎮", class = "btn-sm")
      ),
      # 主顯示區：上方地圖，下方圖表
      card(
        full_screen = TRUE,
        card_header("石虎地理分佈圖"),
        leafletOutput("map", height = "500px")
      ),
      card(
        full_screen = TRUE,
        card_header("歷年趨勢分析"),
        plotlyOutput("lineplot", height = "300px")
      )
    )
  ),
  
  # --- 全域懸浮 AI 助手 (放在 footer 確保跨頁存在) ---
  footer = tags$div(
    actionButton("chat_fab", icon("comment-dots", class = "fa-2x"), class = "btn-primary"),
    div(id = "chat_window",
        div(class = "chat-header",
            span(icon("robot"), "石寶"),
            actionLink("close_chat", icon("xmark"), style = "color: white;")
        ),
        div(class = "chat-body", uiOutput("chat_history")),
        div(class = "chat-footer",
            div(class = "input-group-container",
                textInput("question", NULL, placeholder = "詢問關於石虎的問題...", width = "100%"),
                actionButton("ask", NULL, icon = icon("paper-plane"), class = "btn-primary")
            )
        )
        
    )
  )
)

server <- function(input, output, session) {
  # --- 1. 數據處理邏輯 (地圖與圖表) ---
  rv <- reactiveVal(data.frame())
  
  observeEvent(input$file, {
    req(input$file)
    df <- read.csv(input$file$datapath, stringsAsFactors = FALSE)
    df$date <- as.Date(df$date)
    df$year <- year(df$date)
    rv(df)
    
    updateCheckboxGroupInput(session, "year", choices = sort(unique(df$year)), selected = sort(unique(df$year)))
    updateSelectInput(session, "county", choices = unique(df$county), selected = unique(df$county)[1])
    updateCheckboxGroupInput(session, "municipality", choices = unique(df$municipality), selected = unique(df$municipality))
  })
  
  observeEvent(input$year_all, {
    df <- rv()
    all_years <- sort(unique(df$year))
    updateCheckboxGroupInput(session, "year", selected = if(length(input$year) == length(all_years)) character(0) else all_years)
  })
  
  observeEvent(input$municipality_all, {
    df <- rv()
    all_muni <- unique(df$municipality)
    updateCheckboxGroupInput(session, "municipality", selected = if(length(input$municipality) == length(all_muni)) character(0) else all_muni)
  })
  
  filteredData <- reactive({
    df <- rv()
    if (nrow(df) == 0) return(df)
    req(input$year, input$municipality)
    df %>% filter(year %in% input$year, county == input$county, municipality %in% input$municipality)
  })
  
  output$map <- renderLeaflet({
    leaflet() %>% addProviderTiles(providers$CartoDB.Positron) %>% setView(120.97, 23.97, zoom = 7)
  })
  
  observe({
    df <- filteredData()
    if (nrow(df) == 0) { leafletProxy("map") %>% clearMarkers(); return() }
    pal <- colorFactor("Set1", domain = rv()$year)
    leafletProxy("map", data = df) %>%
      clearMarkers() %>%
      addCircleMarkers(~longitude, ~latitude, radius = 6, color = ~pal(year), fillOpacity = 0.8,
                       popup = ~paste0("縣市: ", county, "<br>鄉鎮: ", municipality, "<br>年份: ", year))
  })
  
  output$lineplot <- renderPlotly({
    df <- filteredData()
    if (nrow(df) == 0) return(NULL)
    df_summary <- df %>% group_by(county, year) %>% summarise(count = n(), .groups = "drop")
    plot_ly(df_summary, x = ~as.factor(year), y = ~count, color = ~county, type = 'scatter', mode = 'lines+markers') %>%
      layout(xaxis = list(title = "年份", type = "category"), yaxis = list(title = "觀測次數"))
  })
  
  # --- 2. AI 助手邏輯 (RAG) ---
  history <- reactiveValues(logs = list())
  
  observeEvent(input$chat_fab, { runjs("$('#chat_window').toggle();") })
  observeEvent(input$close_chat, { runjs("$('#chat_window').hide();") })
  
  observeEvent(input$ask, {
    req(input$question)
    user_q <- input$question
    
    # A. 立即處理 UI：清空輸入框、顯示通知、存入使用者問題
    updateTextInput(session, "question", value = "") 
    showNotification("石虎助手正在查詢資料庫...", type = "message", duration = 2)
    
    # 將使用者問題存入歷史紀錄 (這步沒做，UI 就不會顯示你問了什麼)
    history$logs <- c(history$logs, list(list(role = "user", text = user_q)))
    
    # B. 呼叫 Python (只呼叫一次)
    ai_res <- tryCatch({
      rag_query(user_q) # 確保這裡只執行一次
    }, error = function(e) {
      paste("系統錯誤:", e$message)
    })
    
    # C. 將 AI 的回答存入歷史紀錄
    history$logs <- c(history$logs, list(list(role = "ai", text = ai_res)))
    
    # D. 強制捲動到底部
    runjs("$('.chat-body').scrollTop($('.chat-body')[0].scrollHeight);")
  })
  
  # 渲染對話 (確保 ID 與 UI 中的 uiOutput("chat_history") 相同)
  output$chat_history <- renderUI({
    req(history$logs)
    # 使用 tagList 包裹，確保 HTML 結構正確渲染
    tagList(
      lapply(history$logs, function(log) {
        div(class = ifelse(log$role == "user", "user-msg", "ai-msg"), 
            span(log$text))
      })
    )
  })
}


shinyApp(ui, server)

