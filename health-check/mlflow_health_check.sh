#!/bin/bash
source /data/ai/solution-dev2-project/dev2-output-asset-deploy/health-check/.env
AUTH="$MLFLOW_ID:$MLFLOW_PASSWORD"
# 로그 파일 경로 (Prometheus textfile collector 경로)
PROM_FILE="/data/ai/chg/node_exporter-1.5.0.linux-amd64/textfile_collector/service_stats_mlflow.prom"

# MLflow 상태 체크 명령어
MLFLOW_HEALTH=$(curl -s -u "$AUTH" -o /dev/null -w "%{http_code}" http://211.57.84.52:8000/mlflow-health)

# 현재 시간 기록
echo "# HELP mlflow_service_status The current status of the MLflow service" > $PROM_FILE
echo "# TYPE mlflow_service_status gauge" >> $PROM_FILE

# MLflow 상태 확인 (200 응답 시 서비스 정상)
if [ "$MLFLOW_HEALTH" -eq 200 ]; then
  echo "mlflow_service_status 1" >> $PROM_FILE
else
  echo "mlflow_service_status 0" >> $PROM_FILE
fi
