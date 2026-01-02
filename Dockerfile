# 使用官方 R-Shiny 映像檔
FROM rocker/shiny-verse:latest

# 安裝系統套件（Python 與網頁開發所需）
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3.12-venv \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev

# 設定工作目錄
WORKDIR /code

# 複製所有專案檔案
COPY . .

# 安裝 R 套件
RUN R -e "install.packages(c('shiny', 'leaflet', 'dplyr', 'lubridate', 'plotly', 'bslib', 'shinyjs', 'reticulate'))"

# 建立路徑為 /opt/venv 的虛擬環境
RUN python3 -m venv /opt/venv --without-pip
# 使用絕對路徑強制在該環境內啟動 pip
RUN /opt/venv/bin/python3 -m ensurepip
RUN /opt/venv/bin/python3 -m pip install --upgrade pip
# 強制使用虛擬環境內的 pip 安裝 requirements.txt 中的所有套件
RUN /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# 設定權限，確保 Shiny 服務的使用者 (shiny) 有權限讀取虛擬環境與執行檔
RUN chmod -R 755 /opt/venv /code

# 設定環境變數，讓系統與 R 優先抓取此虛擬環境
ENV PATH="/opt/venv/bin:$PATH"
ENV RETICULATE_PYTHON="/opt/venv/bin/python"

# 暴露埠號（Hugging Face 規定使用 7860）
EXPOSE 7860

# 啟動命令
CMD ["R", "-e", "shiny::runApp('/code/app.R', host = '0.0.0.0', port = 7860)"]
