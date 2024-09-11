# FastAPI용 Dockerfile
FROM amd64/python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# FastAPI와 필요한 패키지 설치
RUN pip install -U pip \
    && pip install "fastapi[all]" requests psutil gputil

# FastAPI 애플리케이션 복사
COPY health_check.py /app/health_check.py
COPY config.py /app/config.py

# FastAPI 실행 명령
CMD ["uvicorn", "health_check:app", "--host", "0.0.0.0", "--port", "8015", "--reload"]
