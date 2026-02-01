#!/bin/bash

# ==============================================================================
# Docker 이미지 크기 비교 스크립트
# 각 최적화 단계별 이미지 크기를 비교합니다.
# ==============================================================================

echo ""
echo "========================================"
echo "Docker Image Size Comparison"
echo "========================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 이미지 목록
IMAGES=("bookshelf:basic" "bookshelf:multistage" "bookshelf:jre" "bookshelf:alpine" "bookshelf:jlink" "bookshelf:native")
NAMES=("1. Basic (JDK Full)" "2. Multi-stage" "3. JRE Only" "4. Alpine Linux" "5. Jlink Custom JRE" "6. GraalVM Native")

# 기준 크기 (basic 이미지)
BASE_SIZE=0

echo "┌────────────────────────────┬────────────┬────────────┬────────────┐"
echo "│ Image                      │ Size       │ Reduction  │ % of Base  │"
echo "├────────────────────────────┼────────────┼────────────┼────────────┤"

for i in "${!IMAGES[@]}"; do
    IMAGE="${IMAGES[$i]}"
    NAME="${NAMES[$i]}"
    
    # 이미지 존재 여부 확인
    if docker image inspect "$IMAGE" > /dev/null 2>&1; then
        # 이미지 크기 (바이트)
        SIZE_BYTES=$(docker image inspect "$IMAGE" --format='{{.Size}}')
        SIZE_MB=$((SIZE_BYTES / 1024 / 1024))
        
        # 기준 크기 설정 (첫 번째 이미지)
        if [ $i -eq 0 ]; then
            BASE_SIZE=$SIZE_MB
            REDUCTION="baseline"
            PERCENT="100%"
        else
            if [ $BASE_SIZE -gt 0 ]; then
                REDUCTION_MB=$((BASE_SIZE - SIZE_MB))
                PERCENT=$((SIZE_MB * 100 / BASE_SIZE))
                REDUCTION="-${REDUCTION_MB}MB"
            else
                REDUCTION="N/A"
                PERCENT="N/A"
            fi
        fi
        
        # 색상 설정 (작을수록 녹색)
        if [ $SIZE_MB -lt 150 ]; then
            COLOR=$GREEN
        elif [ $SIZE_MB -lt 250 ]; then
            COLOR=$CYAN
        elif [ $SIZE_MB -lt 400 ]; then
            COLOR=$YELLOW
        else
            COLOR=$RED
        fi
        
        printf "│ %-26s │ ${COLOR}%8sMB${NC} │ %10s │ %10s │\n" "$NAME" "$SIZE_MB" "$REDUCTION" "$PERCENT"
    else
        printf "│ %-26s │ ${RED}%10s${NC} │ %10s │ %10s │\n" "$NAME" "NOT FOUND" "-" "-"
    fi
done

echo "└────────────────────────────┴────────────┴────────────┴────────────┘"
echo ""

# 상세 정보
echo "========================================"
echo "Detailed Image Information"
echo "========================================"
echo ""

for IMAGE in "${IMAGES[@]}"; do
    if docker image inspect "$IMAGE" > /dev/null 2>&1; then
        echo -e "${BLUE}$IMAGE${NC}"
        docker image inspect "$IMAGE" --format='  Created: {{.Created}}'
        docker image inspect "$IMAGE" --format='  Architecture: {{.Architecture}}'
        docker image inspect "$IMAGE" --format='  OS: {{.Os}}'
        echo ""
    fi
done

echo "========================================"
echo "Optimization Tips Applied"
echo "========================================"
echo ""
echo "1. Basic      → Full JDK, single stage, no optimization"
echo "2. Multistage → Separate build/runtime stages"
echo "3. JRE Only   → Removed compiler, dev tools"
echo "4. Alpine     → Minimal Linux distro (~5MB base)"
echo "5. Jlink      → Custom JRE with only needed modules"
echo "6. Native     → AOT compiled, no JVM required"
echo ""
echo "========================================"
