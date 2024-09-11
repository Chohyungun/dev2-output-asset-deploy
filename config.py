# config.py

# 리눅스 환경의 경우 
IP_ADDRESS = "20.41.117.139"

# 도커 환경 설정
DOCKER_CONFIG = [
    {"container_name": "frontend", "port": 8090},

]
# 로컬 환경 설정
LOCAL_CONFIG = {
    "ports": [5173, 5174]
}