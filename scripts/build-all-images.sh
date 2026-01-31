#!/bin/bash

# ==============================================================================
# Docker 이미지 빌드 스크립트
# 모든 단계의 Dockerfile을 빌드하고 크기를 비교합니다.
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
NC='\033[0m' # No Color

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."

# 빌드 시작 시간
START_TIME=$(date +%s)

echo -e "${BLUE}[1/6] Building basic image...${NC}"
docker build -f docker/Dockerfile.basic -t bookshelf:basic . 2>&1 | tail -5
echo -e "${GREEN}✓ basic image built${NC}"
echo ""

echo -e "${BLUE}[2/6] Building multistage image...${NC}"
docker build -f docker/Dockerfile.multistage -t bookshelf:multistage . 2>&1 | tail -5
echo -e "${GREEN}✓ multistage image built${NC}"
echo ""

echo -e "${BLUE}[3/6] Building JRE image...${NC}"
docker build -f docker/Dockerfile.jre -t bookshelf:jre . 2>&1 | tail -5
echo -e "${GREEN}✓ jre image built${NC}"
echo ""

echo -e "${BLUE}[4/6] Building Alpine image...${NC}"
docker build -f docker/Dockerfile.alpine -t bookshelf:alpine . 2>&1 | tail -5
echo -e "${GREEN}✓ alpine image built${NC}"
echo ""

echo -e "${BLUE}[5/6] Building Jlink image...${NC}"
docker build -f docker/Dockerfile.jlink -t bookshelf:jlink . 2>&1 | tail -5
echo -e "${GREEN}✓ jlink image built${NC}"
echo ""

echo -e "${YELLOW}[6/6] Building Native image (this may take 10+ minutes)...${NC}"
echo -e "${YELLOW}      Skipping native build by default. Run with --native flag to include.${NC}"
if [[ "$1" == "--native" ]]; then
    docker build -f docker/Dockerfile.native -t bookshelf:native . 2>&1 | tail -5
    echo -e "${GREEN}✓ native image built${NC}"
else
    echo -e "${YELLOW}⊘ native image skipped${NC}"
fi
echo ""

# 빌드 종료 시간
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

echo "========================================"
echo -e "${GREEN}Build completed in ${BUILD_TIME} seconds${NC}"
echo "========================================"
echo ""

# 크기 비교 스크립트 실행
./scripts/compare-sizes.sh
