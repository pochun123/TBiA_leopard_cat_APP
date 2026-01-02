# 使用官方 R-Shiny 映像檔
FROM rocker/shiny-verse:latest

# 安裝系統套件（Python 與網頁開發所需）
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libssl-dev \
    libcurl4-openssl-dev

# 設定工作目錄
WORKDIR /code

# 複製所有專案檔案
COPY . .

# 安裝 R 套件
RUN R -e "install.packages(c('shiny', 'leaflet', 'dplyr', 'lubridate', 'plotly', 'bslib', 'shinyjs', 'reticulate'))"

# 6. 建立 Python 虛擬環境並安裝套件
# 建立路徑為 /opt/venv 的虛擬環境
RUN python3 -m venv /opt/venv
# 設定環境變數，讓系統優先使用虛擬環境中的 python 與 pip
ENV PATH="/opt/venv/bin:$PATH"

# 暴露埠號（Hugging Face 規定使用 7860）
EXPOSE 7860

# 啟動命令
CMD ["R", "-e", "shiny::runApp('/code/app.R', host = '0.0.0.0', port = 7860)"]
