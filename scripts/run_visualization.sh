#!/bin/bash

# ==============================================================================
# Docker 이미지 최적화 결과 종합 시각화 스크립트
# 
# 이 스크립트는 다음 리포트를 생성합니다:
#   1. PNG/SVG 차트 (matplotlib)
#   2. Dive 레이어 분석
#   3. Dockerfile 구조 시각화
#   4. 인터랙티브 HTML 리포트
# ==============================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/reports"

cd "$PROJECT_DIR"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     🐳 Docker Image Optimization Visualization Suite        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 디렉토리 생성
mkdir -p "$REPORT_DIR"

# 옵션 파싱
RUN_DIVE=false
RUN_DOCKERFILE=false
RUN_CHARTS=true
RUN_HTML=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            RUN_DIVE=true
            RUN_DOCKERFILE=true
            shift
            ;;
        --dive)
            RUN_DIVE=true
            shift
            ;;
        --dockerfile)
            RUN_DOCKERFILE=true
            shift
            ;;
        --charts-only)
            RUN_DIVE=false
            RUN_DOCKERFILE=false
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --all           Run all visualizations including dive and dockerfile"
            echo "  --dive          Include dive layer analysis"
            echo "  --dockerfile    Include dockerfile structure visualization"
            echo "  --charts-only   Only generate charts (default without args)"
            echo "  --help          Show this help"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Python 확인
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        echo -e "${RED}Error: Python is not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Python found: $PYTHON_CMD${NC}"
}

# matplotlib 확인 및 설치
check_matplotlib() {
    if ! $PYTHON_CMD -c "import matplotlib" 2>/dev/null; then
        echo -e "${YELLOW}Installing matplotlib...${NC}"
        pip install matplotlib --quiet || pip3 install matplotlib --quiet
    fi
    echo -e "${GREEN}✓ matplotlib available${NC}"
}

echo -e "${CYAN}[1/5] Checking dependencies...${NC}"
check_python
check_matplotlib
echo ""

# ============================================
# 1. PNG/SVG 차트 생성
# ============================================
echo -e "${CYAN}[2/5] Generating PNG/SVG charts...${NC}"
if [ -f "$SCRIPT_DIR/visualization/generate_charts.py" ]; then
    cd "$PROJECT_DIR"
    $PYTHON_CMD "$SCRIPT_DIR/visualization/generate_charts.py"
    echo ""
else
    echo -e "${YELLOW}⊘ Chart script not found, skipping${NC}"
fi

# ============================================
# 2. HTML 리포트 생성
# ============================================
echo -e "${CYAN}[3/5] Generating interactive HTML report...${NC}"
if [ -f "$SCRIPT_DIR/visualization/generate_html_report.py" ]; then
    cd "$PROJECT_DIR"
    $PYTHON_CMD "$SCRIPT_DIR/visualization/generate_html_report.py"
    echo ""
else
    echo -e "${YELLOW}⊘ HTML report script not found, skipping${NC}"
fi

# ============================================
# 3. Dive 레이어 분석 (선택적)
# ============================================
if [ "$RUN_DIVE" = true ]; then
    echo -e "${CYAN}[4/5] Running Dive layer analysis...${NC}"
    if [ -f "$SCRIPT_DIR/visualization/analyze_with_dive.sh" ]; then
        chmod +x "$SCRIPT_DIR/visualization/analyze_with_dive.sh"
        bash "$SCRIPT_DIR/visualization/analyze_with_dive.sh" || echo -e "${YELLOW}Dive analysis completed with warnings${NC}"
        echo ""
    fi
else
    echo -e "${CYAN}[4/5] Dive analysis skipped (use --dive to enable)${NC}"
    echo ""
fi

# ============================================
# 4. Dockerfile 구조 시각화 (선택적)
# ============================================
if [ "$RUN_DOCKERFILE" = true ]; then
    echo -e "${CYAN}[5/5] Visualizing Dockerfile structures...${NC}"
    if [ -f "$SCRIPT_DIR/visualization/visualize_dockerfile.sh" ]; then
        chmod +x "$SCRIPT_DIR/visualization/visualize_dockerfile.sh"
        bash "$SCRIPT_DIR/visualization/visualize_dockerfile.sh" || echo -e "${YELLOW}Dockerfile visualization completed with warnings${NC}"
        echo ""
    fi
else
    echo -e "${CYAN}[5/5] Dockerfile visualization skipped (use --dockerfile to enable)${NC}"
    echo ""
fi

# ============================================
# 결과 요약
# ============================================
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                    📊 Generated Reports                      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 생성된 파일 목록
if [ -d "$REPORT_DIR" ]; then
    echo -e "${GREEN}Reports directory: $REPORT_DIR${NC}"
    echo ""
    echo "Generated files:"
    find "$REPORT_DIR" -type f -name "*.png" -o -name "*.svg" -o -name "*.html" -o -name "*.txt" 2>/dev/null | while read file; do
        SIZE=$(du -h "$file" 2>/dev/null | cut -f1)
        echo "  📄 $(basename "$file") ($SIZE)"
    done
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                      🎉 Complete!                            ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "View HTML report: ${CYAN}open $REPORT_DIR/optimization_report.html${NC}"
echo -e "View charts: ${CYAN}open $REPORT_DIR/05_dashboard.png${NC}"
echo ""

# macOS에서 자동으로 열기 (선택적)
if [[ "$OSTYPE" == "darwin"* ]]; then
    read -p "Open HTML report in browser? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$REPORT_DIR/optimization_report.html" 2>/dev/null || true
    fi
fi
