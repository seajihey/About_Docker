#!/bin/bash

# ==============================================================================
# Docker 이미지 빌드 스크립트
# 모든 단계의 Dockerfile을 빌드하고 크기 및 빌드 시간을 비교합니다.
# ==============================================================================

set -e

echo "========================================"
echo "BookShelf Docker Image Build Script"
echo "========================================"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."

# 빌드 시간 저장 배열
declare -A BUILD_TIMES
declare -A BUILD_STATUS

# 시간 측정 함수
measure_time() {
    local start=$1
    local end=$2
    echo $((end - start))
}

# 시간을 분:초 형식으로 변환하는 함수
format_time() {
    local total_seconds=$1
    local minutes=$((total_seconds / 60))
    local seconds=$((total_seconds % 60))
    printf "%dm %ds" $minutes $seconds
}

# 빌드 함수 (에러 체크 포함)
build_image() {
    local name=$1
    local dockerfile=$2
    local tag=$3
    
    STEP_START=$(date +%s)
    
    # 빌드 실행 및 결과 저장
    if docker build -f "$dockerfile" -t "$tag" . 2>&1 | tee /tmp/docker_build_${name}.log | tail -5; then
        # 빌드 성공 확인
        if docker images "$tag" --format "{{.Repository}}:{{.Tag}}" | grep -q "$tag"; then
            STEP_END=$(date +%s)
            BUILD_TIMES[$name]=$(measure_time $STEP_START $STEP_END)
            BUILD_STATUS[$name]="success"
            echo -e "${GREEN}✓ $name image built ${CYAN}($(format_time ${BUILD_TIMES[$name]}))${NC}"
            return 0
        else
            echo -e "${RED}✗ $name image build failed - image not created${NC}"
            BUILD_STATUS[$name]="failed"
            return 1
        fi
    else
        echo -e "${RED}✗ $name image build failed${NC}"
        echo -e "${YELLOW}Check /tmp/docker_build_${name}.log for details${NC}"
        BUILD_STATUS[$name]="failed"
        return 1
    fi
}

# 전체 빌드 시작 시간
TOTAL_START_TIME=$(date +%s)

# 1. Basic 이미지 빌드
echo -e "${BLUE}[1/6] Building basic image...${NC}"
build_image "basic" "docker/Dockerfile.basic" "bookshelf:basic" || true
echo ""

# 2. Multistage 이미지 빌드
echo -e "${BLUE}[2/6] Building multistage image...${NC}"
build_image "multistage" "docker/Dockerfile.multistage" "bookshelf:multistage" || true
echo ""

# 3. JRE 이미지 빌드
echo -e "${BLUE}[3/6] Building JRE image...${NC}"
build_image "jre" "docker/Dockerfile.jre" "bookshelf:jre" || true
echo ""

# 4. Alpine 이미지 빌드
echo -e "${BLUE}[4/6] Building Alpine image...${NC}"
build_image "alpine" "docker/Dockerfile.alpine" "bookshelf:alpine" || true
echo ""

# 5. Jlink 이미지 빌드
echo -e "${BLUE}[5/6] Building Jlink image...${NC}"
build_image "jlink" "docker/Dockerfile.jlink" "bookshelf:jlink" || true
echo ""

# 6. Native 이미지 빌드 (옵션)
echo -e "${YELLOW}[6/6] Building Native image (this may take 10+ minutes)...${NC}"
if [[ "$1" == "--native" ]]; then
    build_image "native" "docker/Dockerfile.native" "bookshelf:native" || true
else
    echo -e "${YELLOW}⊘ native image skipped (use --native flag to build)${NC}"
    BUILD_TIMES[native]=0
    BUILD_STATUS[native]="skipped"
fi
echo ""

# 전체 빌드 종료 시간
TOTAL_END_TIME=$(date +%s)
TOTAL_BUILD_TIME=$(measure_time $TOTAL_START_TIME $TOTAL_END_TIME)

echo "========================================"
echo -e "${GREEN}Build Summary${NC}"
echo "========================================"
echo ""
echo -e "${CYAN}Individual Build Times:${NC}"

# 각 이미지별 빌드 결과 표시
for image in basic multistage jre alpine jlink; do
    if [[ "${BUILD_STATUS[$image]}" == "success" ]]; then
        echo -e "  $image:      $(format_time ${BUILD_TIMES[$image]}) ${GREEN}✓${NC}"
    elif [[ "${BUILD_STATUS[$image]}" == "failed" ]]; then
        echo -e "  $image:      ${RED}FAILED ✗${NC}"
    fi
done

if [[ "$1" == "--native" ]]; then
    if [[ "${BUILD_STATUS[native]}" == "success" ]]; then
        echo -e "  native:     $(format_time ${BUILD_TIMES[native]}) ${GREEN}✓${NC}"
    elif [[ "${BUILD_STATUS[native]}" == "failed" ]]; then
        echo -e "  native:     ${RED}FAILED ✗${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Total build time: $(format_time $TOTAL_BUILD_TIME)${NC}"
echo "========================================"
echo ""

# 실패한 빌드가 있는지 확인
failed_builds=()
for image in basic multistage jre alpine jlink native; do
    if [[ "${BUILD_STATUS[$image]}" == "failed" ]]; then
        failed_builds+=("$image")
    fi
done

if [ ${#failed_builds[@]} -gt 0 ]; then
    echo -e "${RED}========================================"
    echo "Failed Builds: ${failed_builds[*]}"
    echo -e "========================================${NC}"
    echo ""
fi

# 크기 비교 스크립트 실행
if [ -f ./scripts/compare-sizes.sh ]; then
    ./scripts/compare-sizes.sh
else
    echo -e "${YELLOW}Warning: ./scripts/compare-sizes.sh not found${NC}"
fi