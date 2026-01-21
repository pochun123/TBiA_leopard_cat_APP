library(shiny)
library(leaflet)
library(dplyr)
library(lubridate)
library(plotly)
library(bslib)
library(shinyjs)
library(reticulate)
library(leaflet.extras)

use_python("/opt/venv/bin/python", required = TRUE)

# 載入 RAG 查詢函數
source_python("ssqa_hf.py") 

ui <- page_navbar(
  title = "石虎保育大數據與 AI 助手",
  theme = bs_theme(version = 5, bootswatch = "minty", primary = "#C19A6B"),
  useShinyjs(),
  header = tags$head(
    tags$style("
      /* 讓標題欄高度固定 */
      .navbar { min-height: 50px; height: 60px; }
      
      /* 調整主內容區域 (container-fluid) 的間距 */
      .container-fluid { 
        padding-top: 5px !important; 
        overflow-y: auto; /* 確保內容過長時可捲動 */
      }
      
      /* 讓內容高度能自動延伸 */
      body { height: auto; min-height: 100vh; }

      .card-body {
      overflow: hidden !important; /* 不要card滾輪 */
      }
    ")
  ),
  
  # 自定義 CSS：處理懸浮聊天室
  tags$head(tags$style(HTML("
    #chat_fab { position: fixed; bottom: 25px; right: 25px; width: 60px; height: 60px; border-radius: 50%; z-index: 1000; box-shadow: 0 4px 15px rgba(0,0,0,0.3); }

    #chat_window { position: fixed; bottom: 95px; right: 25px; width: 350px; height: 390px; background: white; border-radius: 15px; display: flex; flex-direction: column; z-index: 1000; box-shadow: 0 5px 25px rgba(0,0,0,0.2); border: 1px solid #ddd; }

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

    layout_column_wrap(
      width = 1, # 讓內容寬度佔滿
      style = "padding: 20px;", # 增加邊距讓內容不貼邊
      
      navset_card_pill(
        nav_panel(
          title = "石虎簡介",
          layout_column_wrap(
            width = 1/2, # 平分為左右兩欄
            fill = TRUE,
             # 1. 石虎現況
            card(
              card_header("石虎現況"),
              card_body(
                tags$ul(
                tags$li(tags$b("分布："), "以中低海拔淺山丘陵（約1,500公尺以下），多見於農地-森林交錯地帶。"),
                tags$li(tags$b("地位："), "淺山生態系頂級消費者與保護傘物種。")
                )
              )
           ),
      
             # 2. 主要威脅
            card(
              card_header("主要威脅"),
              card_body(
                tags$ul(
                tags$li("棲地破碎化與開發；道路路殺。"),
                tags$li("人虎衝突：放養家禽遭捕食引發陷阱/毒餌。"),
                tags$li("流浪犬貓攻擊與疾病傳播。"),
                tags$li("農藥/滅鼠藥造成的二次中毒風險。")
                )
              )
            ),
      
             # 3.保育行動
            card(
              card_header("保育行動"),
              card_body(
                tags$ul(
                tags$li(tags$b("路殺熱點："), "熱區圍網/導流/通道。"),
                tags$li(tags$b("犬貓管理："), "繫繩、結紮、移除遊蕩犬貓。"),
                tags$li(tags$b("棲地連結："), "設置/維護生態廊道。"),
                tags$li(tags$b("友善農法："), "減少高風險藥劑，補助代替死性控制。")
                )
              )
            ),
      
             # 4. 你我能做什麼
            card(
              card_header("你我能做什麼"),
              card_body(
                tags$ul(
                tags$li("夜晚、清晨行經西半部淺山地區，降低車速、注意路況。"),
                tags$li("活體、路殺目擊請通報系統。"),
                tags$li("犬貓飼主繫繩、結紮、不棄養寵物。"),
                tags$li("支持環境友善產品，反對毒餌與獸鋏。")
                )
              )
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
              tags$li(tags$a("國立自然科學博物館：認識石虎", href = "https://web3.nmns.edu.tw/exhibits/107/leopardcat/cont1.html", target = "_blank")),
              tags$li(tags$a("臺灣生物多樣性資訊聯盟：物種出現紀錄查詢", href = "https://tbiadata.tw/zh-hant/search/occurrence?record_type=occ&name=%E8%B1%B9%E8%B2%93&page=1&from=search&limit=10", target = "_blank"))
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
        actionButton("municipality_all", "全選/取消鄉鎮", class = "btn-sm"),
        hr(),
        radioButtons("map_type", "地圖類型：", choices = c("標點圖" = "markers", "熱點圖" = "heatmap"), selected = "markers")
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

    # --- 全域懸浮對話框 (放在 footer 確保跨頁存在) ---
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
  # ---  數據處理邏輯 (地圖與圖表) ---
  check_data <- function(path) {
  df <- read.csv(path, stringsAsFactors = FALSE)
  required_cols <- c("latitude", "longitude", "county", "municipality", "date")
  
  if (!all(required_cols %in% colnames(df))) {
    showNotification("檔案缺少必要欄位：latitude, longitude, county, municipality, date", type = "error")
    return(NULL)
  }
  
  # 日期處理
  df$date <- parse_date_time(df$date, orders = c("ymd", "y/m/d", "mdy", "d/m/y")) %>% as.Date()
  df <- df[!is.na(df$date), ]
  
  if (nrow(df) == 0) {
    showNotification("日期格式解析失敗，請確認格式", type = "error")
    return(NULL)
  }
  
  df$year <- year(df$date)
  return(df)
  }

  rv <- reactiveVal(data.frame())

  observe({
    sample_path <- "Sample Data/mia.csv"
    if (file.exists(sample_path)) {
      df_sample <- check_data(sample_path)
      if (!is.null(df_sample)) {
        rv(df_sample)
        # 同步更新 UI 選單
        updateCheckboxGroupInput(session, "year", choices = sort(unique(df_sample$year)), selected = sort(unique(df_sample$year)))
        updateSelectInput(session, "county", choices = unique(df_sample$county), selected = unique(df_sample$county)[1])
        updateCheckboxGroupInput(session, "municipality", choices = unique(df_sample$municipality), selected = unique(df_sample$municipality))
      }
    }
  })

  observeEvent(input$file, {
    req(input$file)
    df_user <- check_data(input$file$datapath)
  
    if (!is.null(df_user)) {
      rv(df_user)
      # 同步更新 UI 選單
      updateCheckboxGroupInput(session, "year", choices = sort(unique(df_user$year)), selected = sort(unique(df_user$year)))
      updateSelectInput(session, "county", choices = unique(df_user$county), selected = unique(df_user$county)[1])
      updateCheckboxGroupInput(session, "municipality", choices = unique(df_user$municipality), selected = unique(df_user$municipality))
      showNotification("已成功載入上傳資料", type = "message")
    }
  })
  
  observeEvent(input$year_all, {
    df <- rv()
    all_years <- sort(unique(df$year))
    updateCheckboxGroupInput(session, "year", selected = if(length(input$year) == length(all_years)) character(0) else all_years)
  })
  
  observeEvent(input$county, {
    df <- rv()
    req(nrow(df) > 0, input$county)
    # 根據所選縣市，找出對應的鄉鎮
    available_muni <- df %>% 
      filter(county == input$county) %>% 
      pull(municipality) %>% 
      unique() %>% 
      sort()
  
    updateCheckboxGroupInput(session, "municipality", choices = available_muni, selected = available_muni)
  })
  
  filteredData <- reactive({
    df <- rv()
    if (nrow(df) == 0) return(df)
    req(input$year, input$municipality)
    df %>% filter(year %in% input$year, county == input$county, municipality %in% input$municipality)
  })
  
  output$map <- renderLeaflet({
    df <- filteredData()
  
    p <- leaflet() %>% 
    addProviderTiles(providers$CartoDB.Positron) %>% 
    setView(120.82, 24.56, zoom = 8)

    # Sample Data 載入成功，直接畫上去
    if (nrow(df) > 0) {
      pal <- colorFactor("Set1", domain = df$year)
      if (input$map_type == "heatmap") {
        p <- p %>% addHeatmap(lng = ~longitude, lat = ~latitude, blur = 20, max = 0.5, radius = 15)
      } else {
        p <- p %>% addCircleMarkers(
          ~longitude, ~latitude, radius = 6, color = ~pal(year),
          fillOpacity = 0.8, popup = ~paste0("年份: ", year)
        )
      }
    }
    return(p)
  })

  observe({
    df <- filteredData()
    proxy <- leafletProxy("map", data = df)
  
    # 先清除舊的所有圖層 (包含標點與熱點)
    proxy %>% clearMarkers() %>% clearHeatmap()
  
    if (nrow(df) == 0) return()
    pal <- colorFactor("Set1", domain = df$year)

    if (input$map_type == "heatmap") {
      proxy %>% addHeatmap(
        lng = ~longitude, lat = ~latitude, 
        blur = 20, max = 0.5, radius = 15
      )
    } else {
      proxy %>% addCircleMarkers(
        ~longitude, ~latitude, 
        radius = 6, 
        color = ~pal(year), 
        fillOpacity = 0.8,
        stroke = TRUE, weight = 1,
        popup = ~paste0(
          "<b>地點資訊</b><br>",
          "縣市: ", county, "<br>",
          "鄉鎮: ", municipality, "<br>",
          "年份: ", year
        )
      )
    }
  })
  
  output$lineplot <- renderPlotly({
    df <- filteredData()
    if (nrow(df) == 0) return(NULL)
    df_summary <- df %>% group_by(county, year) %>% summarise(count = n(), .groups = "drop")
    plot_ly(df_summary, x = ~as.factor(year), y = ~count, color = ~county, type = 'scatter', mode = 'lines+markers') %>%
      layout(xaxis = list(title = "年份", type = "category"), yaxis = list(title = "觀測次數"))
  })

  # ---  AI 助手邏輯 (RAG) ---
  history <- reactiveValues(logs = list())
  
  observeEvent(input$chat_fab, { runjs("$('#chat_window').toggle();") })
  observeEvent(input$close_chat, { runjs("$('#chat_window').hide();") })
  
  observeEvent(input$ask, {
    req(input$question)
    user_q <- input$question
    
    # 處理 UI：清空輸入框、顯示通知、存入使用者問題
    updateTextInput(session, "question", value = "") 
    showNotification("石虎助手正在查詢資料庫...", type = "message", duration = 2)
    
    # 將使用者問題存入歷史紀錄
    history$logs <- c(history$logs, list(list(role = "user", text = user_q)))
    
    # 呼叫 Python
    ai_res <- tryCatch({
      rag_query(user_q) 
    }, error = function(e) {
      paste("系統錯誤:", e$message)
    })
    
    # C. 將 AI 的回答存入歷史紀錄
    history$logs <- c(history$logs, list(list(role = "ai", text = ai_res)))
    
    # D. 強制捲動到底部
    runjs("$('.chat-body').scrollTop($('.chat-body')[0].scrollHeight);")
  })
  

  output$chat_history <- renderUI({
    req(history$logs)
    tagList(
      lapply(history$logs, function(log) {
        div(class = ifelse(log$role == "user", "user-msg", "ai-msg"), 
            span(log$text))
      })
    )
  })
}


shinyApp(ui, server)








