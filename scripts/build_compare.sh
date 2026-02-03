#!/bin/bash
# ==============================================================================
# Dockerfile 빌드 시간 비교 스크립트
# ==============================================================================
# 실행: ./build_compare.sh
# ==============================================================================

DOCKER_DIR="docker"
RESULT_FILE="build_result.txt"

echo "=========================================="
echo "🐳 Docker 이미지 빌드 시간 비교"
echo "=========================================="
echo ""

# 결과 파일 초기화
echo "Docker 빌드 시간 비교 결과" > $RESULT_FILE
echo "생성 시간: $(date)" >> $RESULT_FILE
echo "==========================================" >> $RESULT_FILE

# ----- Dockerfile.basic 빌드 -----
echo "📦 [1/2] Dockerfile.basic 빌드 중..."
START_BASIC=$(date +%s.%N)

docker build -f ${DOCKER_DIR}/Dockerfile.basic -t bookshelf:basic . --no-cache

END_BASIC=$(date +%s.%N)
TIME_BASIC=$(echo "$END_BASIC - $START_BASIC" | bc)

echo "✅ bookshelf:basic 완료: ${TIME_BASIC}초"
echo ""

# ----- Dockerfile.optimized 빌드 -----
echo "📦 [2/2] Dockerfile.optimized 빌드 중..."
START_OPT=$(date +%s.%N)

docker build -f ${DOCKER_DIR}/Dockerfile.optimized -t bookshelf:optimized . --no-cache

END_OPT=$(date +%s.%N)
TIME_OPT=$(echo "$END_OPT - $START_OPT" | bc)

echo "✅ bookshelf:optimized 완료: ${TIME_OPT}초"
echo ""

# ----- 이미지 크기 비교 -----
SIZE_BASIC=$(docker images bookshelf:basic --format "{{.Size}}")
SIZE_OPT=$(docker images bookshelf:optimized --format "{{.Size}}")

# ----- 결과 출력 -----
echo "=========================================="
echo "📊 빌드 결과 비교"
echo "=========================================="
echo ""
printf "%-25s %-15s %-15s\n" "이미지" "빌드 시간" "이미지 크기"
printf "%-25s %-15s %-15s\n" "-------------------------" "---------------" "---------------"
printf "%-25s %-15s %-15s\n" "bookshelf:basic" "${TIME_BASIC}초" "$SIZE_BASIC"
printf "%-25s %-15s %-15s\n" "bookshelf:optimized" "${TIME_OPT}초" "$SIZE_OPT"
echo ""

# 결과 파일에 저장
echo "" >> $RESULT_FILE
printf "%-25s %-15s %-15s\n" "이미지" "빌드 시간" "이미지 크기" >> $RESULT_FILE
printf "%-25s %-15s %-15s\n" "-------------------------" "---------------" "---------------" >> $RESULT_FILE
printf "%-25s %-15s %-15s\n" "bookshelf:basic" "${TIME_BASIC}초" "$SIZE_BASIC" >> $RESULT_FILE
printf "%-25s %-15s %-15s\n" "bookshelf:optimized" "${TIME_OPT}초" "$SIZE_OPT" >> $RESULT_FILE

echo "📁 결과가 ${RESULT_FILE}에 저장되었습니다."