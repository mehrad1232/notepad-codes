FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && playwright install --with-deps chromium
COPY nova_cloud ./nova_cloud
EXPOSE 8765
CMD ["uvicorn", "nova_cloud.main:app", "--host", "0.0.0.0", "--port", "8765"]
