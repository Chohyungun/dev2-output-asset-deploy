#!/bin/bash
# .env 파일 로드
source /data/ai/solution-dev2-project/dev2-output-asset-deploy/health-check/.env

AUTH="$MLFLOW_ID:$MLFLOW_PASSWORD"
# 파일 경로 설정
PROMETHEUS_FILE="/data/ai/chg/node_exporter-1.5.0.linux-amd64/textfile_collector/hardware_stats.prom"

# FastAPI 서버 주소
FASTAPI_SERVER="http://211.57.84.52:8000"

# hardware-status에서 CPU, Memory, GPU 상태 정보 가져오기
STATUS=$(curl -s -u "$AUTH" "$FASTAPI_SERVER/hardware-status")
CPU_USAGE=$(echo "$STATUS" | jq '.cpu_usage_percent')
MEMORY_USAGE=$(echo "$STATUS" | jq '.memory_usage_percent')
MEMORY_TOTAL=$(echo "$STATUS" | jq '.memory_total')
MEMORY_USED=$(echo "$STATUS" | jq '.memory_used')
GPU_INFO=$(echo "$STATUS" | jq '.gpu_info[0]')

GPU_USAGE=$(echo "$GPU_INFO" | jq '.load')
GPU_MEMORY_USED=$(echo "$GPU_INFO" | jq '.memory_used')
GPU_MEMORY_TOTAL=$(echo "$GPU_INFO" | jq '.memory_total')

# hardware-info에서 기본 하드웨어 정보 가져오기
INFO=$(curl -s -u "$AUTH" "$FASTAPI_SERVER/hardware-info")
CPU_INFO=$(echo "$INFO" | jq -r '.cpu_info' | sed 's/ /_/g')  # 공백을 밑줄로 변경
OS_INFO=$(echo "$INFO" | jq -r '.os_info' | sed 's/ /_/g')    # 공백을 밑줄로 변경
GPU_NAME=$(echo "$INFO" | jq -r '.gpu_info[0].name' | sed 's/ /_/g')  # 공백을 밑줄로 변경

# Prometheus 메트릭 파일 작성
echo "# HELP cpu_usage_percent Current CPU usage in percent" > "$PROMETHEUS_FILE"
echo "# TYPE cpu_usage_percent gauge" >> "$PROMETHEUS_FILE"
echo "cpu_usage_percent $CPU_USAGE" >> "$PROMETHEUS_FILE"

echo "# HELP memory_usage_percent Current memory usage in percent" >> "$PROMETHEUS_FILE"
echo "# TYPE memory_usage_percent gauge" >> "$PROMETHEUS_FILE"
echo "memory_usage_percent $MEMORY_USAGE" >> "$PROMETHEUS_FILE"

echo "# HELP memory_total_bytes Total memory in bytes" >> "$PROMETHEUS_FILE"
echo "# TYPE memory_total_bytes gauge" >> "$PROMETHEUS_FILE"
echo "memory_total_bytes $MEMORY_TOTAL" >> "$PROMETHEUS_FILE"

echo "# HELP memory_used_bytes Used memory in bytes" >> "$PROMETHEUS_FILE"
echo "# TYPE memory_used_bytes gauge" >> "$PROMETHEUS_FILE"
echo "memory_used_bytes $MEMORY_USED" >> "$PROMETHEUS_FILE"

echo "# HELP gpu_usage_percent Current GPU usage in percent" >> "$PROMETHEUS_FILE"
echo "# TYPE gpu_usage_percent gauge" >> "$PROMETHEUS_FILE"
echo "gpu_usage_percent $GPU_USAGE" >> "$PROMETHEUS_FILE"

echo "# HELP gpu_memory_used_bytes Used GPU memory in bytes" >> "$PROMETHEUS_FILE"
echo "# TYPE gpu_memory_used_bytes gauge" >> "$PROMETHEUS_FILE"
echo "gpu_memory_used_bytes $GPU_MEMORY_USED" >> "$PROMETHEUS_FILE"

echo "# HELP gpu_memory_total_bytes Total GPU memory in bytes" >> "$PROMETHEUS_FILE"
echo "# TYPE gpu_memory_total_bytes gauge" >> "$PROMETHEUS_FILE"
echo "gpu_memory_total_bytes $GPU_MEMORY_TOTAL" >> "$PROMETHEUS_FILE"

# 추가 하드웨어 정보 출력 (정수 값을 1로 설정하고, 레이블에 문자열 포함)
echo "# HELP cpu_info CPU model information" >> "$PROMETHEUS_FILE"
echo "# TYPE cpu_info gauge" >> "$PROMETHEUS_FILE"
echo "cpu_info{model=\"$CPU_INFO\"} 1" >> "$PROMETHEUS_FILE"  # model 레이블 수정

echo "# HELP os_info Operating system information" >> "$PROMETHEUS_FILE"
echo "# TYPE os_info gauge" >> "$PROMETHEUS_FILE"
echo "os_info{os=\"$OS_INFO\"} 1" >> "$PROMETHEUS_FILE"  # os 레이블 수정

echo "# HELP gpu_info GPU model information" >> "$PROMETHEUS_FILE"
echo "# TYPE gpu_info gauge" >> "$PROMETHEUS_FILE"
echo "gpu_info{name=\"$GPU_NAME\"} 1" >> "$PROMETHEUS_FILE"  # name 레이블 수정
