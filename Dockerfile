# Folio · PDF -> EPUB 转换工坊
# 构建:  docker build -t folio-pdf2epub .
# 运行:  docker run -p 5000:5000 folio-pdf2epub
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY pdf2epub.py server.py ./
COPY web ./web

EXPOSE 5000
CMD ["python", "server.py", "--host", "0.0.0.0", "--port", "5000"]
