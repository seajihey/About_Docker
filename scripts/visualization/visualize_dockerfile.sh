#!/bin/bash

# ==============================================================================
# Dockerfile 구조 시각화 스크립트
# dockerfilegraph를 사용하여 Dockerfile의 멀티스테이지 구조를 시각화
#
# 설치:
#   go install github.com/patrickhoefler/dockerfilegraph@latest
#   또는
#   brew install dockerfilegraph (Mac)
# ==============================================================================

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOCKERFILE_DIR="./docker"
REPORT_DIR="./reports/dockerfile-graphs"

mkdir -p "$REPORT_DIR"

echo "========================================"
echo -e "${BLUE}Dockerfile Structure Visualization${NC}"
echo "========================================"
echo ""

# dockerfilegraph 설치 확인
if command -v dockerfilegraph &> /dev/null; then
    echo -e "${GREEN}✓ dockerfilegraph is installed${NC}"
    USE_DOCKERFILEGRAPH=true
else
    echo -e "${YELLOW}⚠ dockerfilegraph not installed${NC}"
    echo "  Install: go install github.com/patrickhoefler/dockerfilegraph@latest"
    USE_DOCKERFILEGRAPH=false
fi

echo ""

# Dockerfile 목록
DOCKERFILES=(
    "Dockerfile.basic"
    "Dockerfile.multistage"
    "Dockerfile.jre"
    "Dockerfile.alpine"
    "Dockerfile.jlink"
    "Dockerfile.native"
)

for DOCKERFILE in "${DOCKERFILES[@]}"; do
    FILEPATH="$DOCKERFILE_DIR/$DOCKERFILE"
    BASENAME=$(echo $DOCKERFILE | sed 's/Dockerfile\.//')
    
    if [ -f "$FILEPATH" ]; then
        echo -e "${BLUE}Processing: $DOCKERFILE${NC}"
        
        if [ "$USE_DOCKERFILEGRAPH" = true ]; then
            # PNG 생성
            dockerfilegraph --filename "$FILEPATH" --output "$REPORT_DIR/${BASENAME}_graph.png" --format png 2>/dev/null || true
            
            # SVG 생성
            dockerfilegraph --filename "$FILEPATH" --output "$REPORT_DIR/${BASENAME}_graph.svg" --format svg 2>/dev/null || true
            
            # DOT 생성 (Graphviz용)
            dockerfilegraph --filename "$FILEPATH" --output "$REPORT_DIR/${BASENAME}_graph.dot" --format dot 2>/dev/null || true
            
            echo -e "  ${GREEN}✓ Graphs generated${NC}"
        else
            echo -e "  ${YELLOW}⊘ Skipped (dockerfilegraph not installed)${NC}"
        fi
        
        # Dockerfile 요약 정보 생성
        {
            echo "========================================"
            echo "DOCKERFILE ANALYSIS: $DOCKERFILE"
            echo "========================================"
            echo ""
            echo "--- Stages ---"
            grep -n "^FROM" "$FILEPATH" || echo "No FROM found"
            echo ""
            echo "--- Key Instructions ---"
            grep -n "^RUN\|^COPY\|^ADD\|^ENV\|^EXPOSE\|^ENTRYPOINT\|^CMD" "$FILEPATH" | head -20
            echo ""
            echo "--- Statistics ---"
            echo "Total lines: $(wc -l < "$FILEPATH")"
            echo "FROM statements: $(grep -c "^FROM" "$FILEPATH" || echo 0)"
            echo "RUN statements: $(grep -c "^RUN" "$FILEPATH" || echo 0)"
            echo "COPY statements: $(grep -c "^COPY" "$FILEPATH" || echo 0)"
            echo ""
        } > "$REPORT_DIR/${BASENAME}_analysis.txt"
        
        echo ""
    else
        echo -e "${YELLOW}⊘ Not found: $FILEPATH${NC}"
    fi
done

# 멀티스테이지 비교 요약
echo "Generating multi-stage comparison..."
{
    echo "========================================"
    echo "MULTI-STAGE BUILD COMPARISON"
    echo "========================================"
    echo ""
    printf "%-15s %8s %8s %8s %8s\n" "DOCKERFILE" "STAGES" "RUN" "COPY" "LINES"
    printf "%-15s %8s %8s %8s %8s\n" "---------------" "--------" "--------" "--------" "--------"
    
    for DOCKERFILE in "${DOCKERFILES[@]}"; do
        FILEPATH="$DOCKERFILE_DIR/$DOCKERFILE"
        BASENAME=$(echo $DOCKERFILE | sed 's/Dockerfile\.//')
        
        if [ -f "$FILEPATH" ]; then
            STAGES=$(grep -c "^FROM" "$FILEPATH" || echo 0)
            RUNS=$(grep -c "^RUN" "$FILEPATH" || echo 0)
            COPIES=$(grep -c "^COPY" "$FILEPATH" || echo 0)
            LINES=$(wc -l < "$FILEPATH")
            
            printf "%-15s %8s %8s %8s %8s\n" "$BASENAME" "$STAGES" "$RUNS" "$COPIES" "$LINES"
        fi
    done
    
    echo ""
    echo "========================================"
} > "$REPORT_DIR/multistage_comparison.txt"

cat "$REPORT_DIR/multistage_comparison.txt"

echo ""
echo -e "${GREEN}========================================"
echo "Visualization complete!"
echo "Reports saved to: $REPORT_DIR/"
echo "========================================${NC}"
