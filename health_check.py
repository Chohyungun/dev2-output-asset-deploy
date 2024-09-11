from fastapi import FastAPI, HTTPException
import psutil
import GPUtil
import platform
import subprocess
import requests
import socket
from config import *

app = FastAPI()

# 로컬 IP 자동 감지 (Windows 환경만 가능, Linux 환경은 고정 IP 사용)
def get_local_ip():
    return "host.docker.internal"

@app.get("/health-check")
async def check_service_health():
    service_status = {}

    # 도커 컨테이너에서 실행되는 서비스 확인
    for config in DOCKER_CONFIG:
        container_name = config["container_name"]
        port = config["port"]
        service_url = f"http://{container_name}:{port}"
        try:
            # HTTP 요청 보내서 응답 확인
            response = requests.get(service_url)
            if response.status_code == 200:
                service_status[f"{container_name}_port_{port}"] = {"status": "Service is healthy", "code": 200}
            else:
                service_status[f"{container_name}_port_{port}"] = {"status": "Service is not healthy", "code": response.status_code}
        except requests.ConnectionError:
            service_status[f"{container_name}_port_{port}"] = {"status": "Service is not reachable", "code": 503}

    # 로컬에서 실행되는 서비스 확인
    for port in LOCAL_CONFIG["ports"]:
        ip_address = IP_ADDRESS # windows 환경일 경우 아래의 get_local_ip()를 활용하여 자동으로 로컬 환경에서 배포되고 있는 서비스 감지 가능
        # ip_address = get_local_ip()
        service_url = f"http://{ip_address}:{port}"
        try:
            response = requests.get(service_url)
            if response.status_code == 200:
                service_status[f"port_{port}"] = {"status": "Service is healthy", "code": 200}
            else:
                service_status[f"port_{port}"] = {"status": "Service is not healthy", "code": response.status_code}
        except requests.ConnectionError:
            service_status[f"port_{port}"] = {"status": "Service is not reachable", "code": 503}

    return service_status

# 하드웨어 상태 확인 엔드포인트
@app.get("/hardware-status")
async def hardware_status():
    # CPU 사용률
    try:
        cpu_usage = psutil.cpu_percent(interval=1)
    except Exception as e:
        cpu_usage = "No_info"

    # 메모리 사용 정보
    try:
        memory_info = psutil.virtual_memory()
        memory_usage_percent = memory_info.percent
        memory_total = memory_info.total
        memory_used = memory_info.used
    except Exception as e:
        memory_usage_percent = "No_info"
        memory_total = "No_info"
        memory_used = "No_info"

    # GPU 사용률 (GPUtil)
    try:
        gpus = GPUtil.getGPUs()
        if gpus:
            gpu_info = [{"id": gpu.id, "name": gpu.name, "load": gpu.load*100, "memory_used": gpu.memoryUsed, "memory_total": gpu.memoryTotal} for gpu in gpus]
        else:
            gpu_info = "No_info"
    except Exception as e:
        gpu_info = "No_info"

    return {
        "cpu_usage_percent": cpu_usage,
        "memory_usage_percent": memory_usage_percent,
        "memory_total": memory_total,
        "memory_used": memory_used,
        "gpu_info": gpu_info
    }


# 하드웨어 정보 확인 엔드포인트
@app.get("/hardware-info")
async def hardware_info():
    # CPU 정보 (lscpu 명령어 사용)
    try:
        cpu_info = subprocess.check_output("lscpu", shell=True).decode().split("\n")
        cpu_info = [line for line in cpu_info if "Model name" in line][0].split(":")[1].strip()
    except Exception as e:
        cpu_info = "No_info"

    # 메모리 정보
    try:
        memory_info = psutil.virtual_memory()
        memory_total = memory_info.total
    except Exception as e:
        memory_total = "No_info"

    # 운영체제 정보
    try:
        os_info = platform.system() + " " + platform.release()
    except Exception as e:
        os_info = "No_info"

    # GPU 정보
    try:
        gpus = GPUtil.getGPUs()
        if gpus:
            gpu_info = [{"id": gpu.id, "name": gpu.name, "memory_total": gpu.memoryTotal} for gpu in gpus]
        else:
            gpu_info = "No_info"
    except Exception as e:
        gpu_info = "No_info"

    return {
        "cpu_info": cpu_info,
        "memory_total": memory_total,
        "os_info": os_info,
        "gpu_info": gpu_info
    }
