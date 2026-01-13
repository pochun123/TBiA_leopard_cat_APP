import os
from langchain_huggingface import HuggingFaceEmbeddings, HuggingFaceEndpoint
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough

# -------------------------------
# 1. 載入向量庫
# -------------------------------
embed_model = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectorstore = Chroma(
    persist_directory="shihu_db_hf",
    embedding_function=embed_model
)
retriever = vectorstore.as_retriever()

# -------------------------------
# 2. 設定 LLM
# -------------------------------
hf_token = os.getenv("HUGGINGFACEHUB_API_TOKEN")
llm = HuggingFaceEndpoint(
    repo_id="Qwen/Qwen2.5-7B-Instruct",
    task="conversational",
    huggingfacehub_api_token=hf_token,
    temperature=0
)

# -------------------------------
# 3. 設定 Prompt
# -------------------------------
prompt = ChatPromptTemplate.from_template(
    """你是一位台灣石虎保育專家，請根據以下資訊回答問題：

資訊：
{context}

問題：
{question}
"""
)

# -------------------------------
# 4. 建立 RAG chain
# -------------------------------
rag_chain = (
    {
        "context": retriever,
        "question": RunnablePassthrough()
    }
    | prompt
    | llm
)

# Python 函式，Shiny 可呼叫
def rag_query(user_question: str) -> str:
    response = rag_chain.invoke(user_question)
    return response.content

