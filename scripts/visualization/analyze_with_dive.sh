#!/bin/bash

# ==============================================================================
# Dive를 활용한 Docker 이미지 레이어 분석 스크립트
# 
# Dive 설치:
#   - Linux: wget https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.deb && sudo dpkg -i dive_0.12.0_linux_amd64.deb
#   - Mac: brew install dive
#   - Windows: choco install dive
# ==============================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

IMAGES=("bookshelf:basic" "bookshelf:multistage" "bookshelf:jre" "bookshelf:alpine" "bookshelf:jlink" "bookshelf:native")
REPORT_DIR="./reports/dive"

# Dive 설치 확인
check_dive() {
    if ! command -v dive &> /dev/null; then
        echo -e "${RED}Error: dive is not installed${NC}"
        echo ""
        echo "Install dive:"
        echo "  Linux (Debian/Ubuntu):"
        echo "    wget https://github.com/wagoodman/dive/releases/download/v0.12.0/dive_0.12.0_linux_amd64.deb"
        echo "    sudo dpkg -i dive_0.12.0_linux_amd64.deb"
        echo ""
        echo "  Mac:"
        echo "    brew install dive"
        echo ""
        echo "  Windows:"
        echo "    choco install dive"
        exit 1
    fi
    echo -e "${GREEN}✓ dive is installed${NC}"
}

# 디렉토리 생성
mkdir -p "$REPORT_DIR"

echo "========================================"
echo -e "${BLUE}Docker Image Layer Analysis with Dive${NC}"
echo "========================================"
echo ""

check_dive
echo ""

# 각 이미지 분석
for IMAGE in "${IMAGES[@]}"; do
    IMAGE_NAME=$(echo $IMAGE | cut -d':' -f2)
    
    if docker image inspect "$IMAGE" > /dev/null 2>&1; then
        echo -e "${CYAN}Analyzing: $IMAGE${NC}"
        
        # JSON 리포트 생성 (CI 모드)
        echo "  → Generating JSON report..."
        dive "$IMAGE" --ci --json "$REPORT_DIR/${IMAGE_NAME}_analysis.json" 2>/dev/null || true
        
        # 텍스트 요약 생성
        echo "  → Generating summary..."
        {
            echo "========================================"
            echo "DIVE ANALYSIS: $IMAGE"
            echo "========================================"
            echo ""
            dive "$IMAGE" --ci 2>&1 || true
        } > "$REPORT_DIR/${IMAGE_NAME}_summary.txt"
        
        echo -e "  ${GREEN}✓ Reports saved${NC}"
        echo ""
    else
        echo -e "${YELLOW}⊘ Skipping $IMAGE (not found)${NC}"
        echo ""
    fi
done

# 비교 요약 생성
echo "Generating comparison summary..."

{
    echo "========================================"
    echo "DIVE ANALYSIS COMPARISON SUMMARY"
    echo "Generated: $(date)"
    echo "========================================"
    echo ""
    
    printf "%-20s %12s %12s %12s\n" "IMAGE" "SIZE" "EFFICIENCY" "WASTED"
    printf "%-20s %12s %12s %12s\n" "--------------------" "------------" "------------" "------------"
    
    for IMAGE in "${IMAGES[@]}"; do
        IMAGE_NAME=$(echo $IMAGE | cut -d':' -f2)
        JSON_FILE="$REPORT_DIR/${IMAGE_NAME}_analysis.json"
        
        if [ -f "$JSON_FILE" ]; then
            # JSON에서 값 추출 (jq 필요)
            if command -v jq &> /dev/null; then
                SIZE=$(docker image inspect "$IMAGE" --format='{{.Size}}' | awk '{printf "%.1fMB", $1/1024/1024}')
                EFFICIENCY=$(jq -r '.efficiency // "N/A"' "$JSON_FILE" 2>/dev/null || echo "N/A")
                WASTED=$(jq -r '.inefficientBytes // 0' "$JSON_FILE" 2>/dev/null | awk '{printf "%.1fMB", $1/1024/1024}')
                
                printf "%-20s %12s %12s %12s\n" "$IMAGE_NAME" "$SIZE" "$EFFICIENCY" "$WASTED"
            else
                SIZE=$(docker image inspect "$IMAGE" --format='{{.Size}}' | awk '{printf "%.1fMB", $1/1024/1024}')
                printf "%-20s %12s %12s %12s\n" "$IMAGE_NAME" "$SIZE" "N/A" "N/A"
            fi
        fi
    done
    
    echo ""
    echo "========================================"
    echo "Note: Install 'jq' for detailed metrics"
    echo "========================================"
} > "$REPORT_DIR/comparison_summary.txt"

cat "$REPORT_DIR/comparison_summary.txt"

echo ""
echo -e "${GREEN}========================================"
echo "Analysis complete!"
echo "Reports saved to: $REPORT_DIR/"
echo "========================================${NC}"
echo ""
echo "To view detailed layer analysis interactively:"
echo "  dive bookshelf:basic"
echo "  dive bookshelf:jlink"
