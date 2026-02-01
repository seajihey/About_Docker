#!/usr/bin/env python3
"""
Docker 이미지 크기 비교 시각화 스크립트
- 바 차트: 이미지별 크기 비교
- 파이 차트: 감소율 시각화
- 워터폴 차트: 단계별 최적화 효과
"""

import subprocess
import json
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from datetime import datetime
import os

# 한글 폰트 설정 (시스템에 따라 조정 필요)
plt.rcParams['font.family'] = ['DejaVu Sans', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

# 색상 팔레트
COLORS = {
    'basic': '#e74c3c',      # 빨강 (비효율)
    'multistage': '#e67e22', # 주황
    'jre': '#f39c12',        # 노랑
    'alpine': '#27ae60',     # 초록
    'jlink': '#2980b9',      # 파랑
    'native': '#9b59b6',     # 보라
}

def get_image_sizes():
    """Docker 이미지 크기 조회"""
    images = ['basic', 'multistage', 'jre', 'alpine', 'jlink', 'native']
    sizes = {}
    
    for img in images:
        try:
            result = subprocess.run(
                ['docker', 'image', 'inspect', f'bookshelf:{img}', '--format', '{{.Size}}'],
                capture_output=True, text=True, check=True
            )
            size_bytes = int(result.stdout.strip())
            sizes[img] = size_bytes / (1024 * 1024)  # MB로 변환
        except subprocess.CalledProcessError:
            sizes[img] = 0
            print(f"Warning: bookshelf:{img} not found")
    
    return sizes

def create_bar_chart(sizes, output_dir):
    """이미지 크기 비교 바 차트"""
    fig, ax = plt.subplots(figsize=(12, 7))
    
    labels = list(sizes.keys())
    values = list(sizes.values())
    colors = [COLORS[k] for k in labels]
    
    # 바 차트
    bars = ax.bar(labels, values, color=colors, edgecolor='white', linewidth=2)
    
    # 기준선 (Basic)
    if sizes.get('basic', 0) > 0:
        ax.axhline(y=sizes['basic'], color='red', linestyle='--', alpha=0.5, label='Baseline (Basic)')
    
    # 값 표시
    for bar, val in zip(bars, values):
        height = bar.get_height()
        if val > 0:
            # 크기 표시
            ax.text(bar.get_x() + bar.get_width()/2., height + 10,
                    f'{val:.0f}MB', ha='center', va='bottom', fontsize=11, fontweight='bold')
            
            # 감소율 표시 (Basic 기준)
            if sizes.get('basic', 0) > 0 and bar.get_x() > 0:
                reduction = (1 - val / sizes['basic']) * 100
                ax.text(bar.get_x() + bar.get_width()/2., height/2,
                        f'-{reduction:.0f}%', ha='center', va='center', 
                        fontsize=10, color='white', fontweight='bold')
    
    ax.set_ylabel('Image Size (MB)', fontsize=12)
    ax.set_xlabel('Optimization Stage', fontsize=12)
    ax.set_title('Docker Image Size Comparison\nBookShelf API Optimization', fontsize=14, fontweight='bold')
    ax.set_ylim(0, max(values) * 1.15)
    
    # 범례
    ax.legend(loc='upper right')
    
    # 그리드
    ax.yaxis.grid(True, linestyle='--', alpha=0.3)
    ax.set_axisbelow(True)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/01_size_comparison_bar.png', dpi=150, bbox_inches='tight')
    plt.savefig(f'{output_dir}/01_size_comparison_bar.svg', bbox_inches='tight')
    print(f"✓ Bar chart saved: {output_dir}/01_size_comparison_bar.png")
    plt.close()

def create_waterfall_chart(sizes, output_dir):
    """워터폴 차트 - 단계별 절감량"""
    fig, ax = plt.subplots(figsize=(12, 7))
    
    stages = list(sizes.keys())
    values = list(sizes.values())
    
    if values[0] == 0:
        print("Warning: Basic image size is 0, skipping waterfall chart")
        return
    
    # 각 단계별 절감량 계산
    reductions = [0]  # Basic은 기준
    for i in range(1, len(values)):
        if values[i] > 0:
            reductions.append(values[i-1] - values[i] if values[i-1] > 0 else 0)
        else:
            reductions.append(0)
    
    # 누적 위치 계산
    cumulative = [values[0]]
    for i in range(1, len(values)):
        if values[i] > 0:
            cumulative.append(values[i])
        else:
            cumulative.append(cumulative[-1])
    
    # 바 그리기
    bar_width = 0.6
    for i, (stage, val, red) in enumerate(zip(stages, cumulative, reductions)):
        if i == 0:
            # 첫 번째 바 (기준)
            ax.bar(i, val, bar_width, color=COLORS[stage], edgecolor='white', linewidth=2)
        else:
            if val > 0 and cumulative[i-1] > 0:
                # 현재 크기
                ax.bar(i, val, bar_width, color=COLORS[stage], edgecolor='white', linewidth=2)
                # 절감량 표시 (연결선)
                if red > 0:
                    ax.annotate('', xy=(i, val), xytext=(i-1, cumulative[i-1]),
                               arrowprops=dict(arrowstyle='->', color='gray', lw=1.5))
    
    # 값 표시
    for i, (stage, val, red) in enumerate(zip(stages, cumulative, reductions)):
        if val > 0:
            ax.text(i, val + 15, f'{val:.0f}MB', ha='center', va='bottom', fontsize=10, fontweight='bold')
            if i > 0 and red > 0:
                ax.text(i, val + 45, f'(-{red:.0f}MB)', ha='center', va='bottom', 
                       fontsize=9, color='green', fontweight='bold')
    
    ax.set_xticks(range(len(stages)))
    ax.set_xticklabels([s.upper() for s in stages], fontsize=10)
    ax.set_ylabel('Image Size (MB)', fontsize=12)
    ax.set_title('Optimization Waterfall\nStep-by-Step Size Reduction', fontsize=14, fontweight='bold')
    ax.set_ylim(0, max(cumulative) * 1.25)
    ax.yaxis.grid(True, linestyle='--', alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/02_waterfall_chart.png', dpi=150, bbox_inches='tight')
    print(f"✓ Waterfall chart saved: {output_dir}/02_waterfall_chart.png")
    plt.close()

def create_pie_chart(sizes, output_dir):
    """파이 차트 - 최종 vs 절감"""
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    
    # 왼쪽: 이미지 크기 비율
    ax1 = axes[0]
    filtered = {k: v for k, v in sizes.items() if v > 0}
    labels = [f"{k}\n({v:.0f}MB)" for k, v in filtered.items()]
    values = list(filtered.values())
    colors = [COLORS[k] for k in filtered.keys()]
    
    wedges, texts, autotexts = ax1.pie(values, labels=labels, colors=colors,
                                        autopct='%1.1f%%', startangle=90,
                                        explode=[0.05]*len(values))
    ax1.set_title('Image Size Distribution', fontsize=12, fontweight='bold')
    
    # 오른쪽: Basic 대비 절감률 (Jlink 기준)
    ax2 = axes[1]
    if sizes.get('basic', 0) > 0 and sizes.get('jlink', 0) > 0:
        saved = sizes['basic'] - sizes['jlink']
        remaining = sizes['jlink']
        
        ax2.pie([remaining, saved], 
                labels=[f'Final Size\n({remaining:.0f}MB)', f'Saved\n({saved:.0f}MB)'],
                colors=['#2980b9', '#27ae60'],
                autopct='%1.1f%%', startangle=90,
                explode=[0, 0.1])
        ax2.set_title('Jlink Optimization Result\n(vs Basic)', fontsize=12, fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/03_pie_charts.png', dpi=150, bbox_inches='tight')
    print(f"✓ Pie charts saved: {output_dir}/03_pie_charts.png")
    plt.close()

def create_horizontal_bar(sizes, output_dir):
    """수평 바 차트 - 크기순 정렬"""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # 크기순 정렬
    sorted_sizes = dict(sorted(sizes.items(), key=lambda x: x[1], reverse=True))
    filtered = {k: v for k, v in sorted_sizes.items() if v > 0}
    
    labels = list(filtered.keys())
    values = list(filtered.values())
    colors = [COLORS[k] for k in labels]
    
    y_pos = np.arange(len(labels))
    bars = ax.barh(y_pos, values, color=colors, edgecolor='white', linewidth=2, height=0.6)
    
    # 값 표시
    for bar, val in zip(bars, values):
        width = bar.get_width()
        ax.text(width + 10, bar.get_y() + bar.get_height()/2,
                f'{val:.0f}MB', ha='left', va='center', fontsize=11, fontweight='bold')
    
    ax.set_yticks(y_pos)
    ax.set_yticklabels([s.upper() for s in labels], fontsize=11)
    ax.set_xlabel('Image Size (MB)', fontsize=12)
    ax.set_title('Docker Images Ranked by Size', fontsize=14, fontweight='bold')
    ax.set_xlim(0, max(values) * 1.2)
    ax.xaxis.grid(True, linestyle='--', alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/04_horizontal_bar.png', dpi=150, bbox_inches='tight')
    print(f"✓ Horizontal bar chart saved: {output_dir}/04_horizontal_bar.png")
    plt.close()

def create_summary_dashboard(sizes, output_dir):
    """종합 대시보드"""
    fig = plt.figure(figsize=(16, 10))
    
    # 그리드 레이아웃
    gs = fig.add_gridspec(2, 3, hspace=0.3, wspace=0.3)
    
    # 1. 메인 바 차트 (상단 전체)
    ax1 = fig.add_subplot(gs[0, :])
    filtered = {k: v for k, v in sizes.items() if v > 0}
    labels = list(filtered.keys())
    values = list(filtered.values())
    colors = [COLORS[k] for k in labels]
    
    bars = ax1.bar(labels, values, color=colors, edgecolor='white', linewidth=2)
    for bar, val in zip(bars, values):
        ax1.text(bar.get_x() + bar.get_width()/2., bar.get_height() + 10,
                f'{val:.0f}MB', ha='center', va='bottom', fontsize=10, fontweight='bold')
    ax1.set_ylabel('Size (MB)')
    ax1.set_title('Docker Image Size Comparison', fontsize=12, fontweight='bold')
    ax1.yaxis.grid(True, linestyle='--', alpha=0.3)
    
    # 2. 감소율 바 차트
    ax2 = fig.add_subplot(gs[1, 0])
    if sizes.get('basic', 0) > 0:
        reductions = {k: (1 - v/sizes['basic'])*100 for k, v in filtered.items() if v > 0}
        labels2 = list(reductions.keys())
        values2 = list(reductions.values())
        colors2 = [COLORS[k] for k in labels2]
        
        bars2 = ax2.bar(labels2, values2, color=colors2, edgecolor='white')
        for bar, val in zip(bars2, values2):
            if val > 0:
                ax2.text(bar.get_x() + bar.get_width()/2., bar.get_height() + 1,
                        f'{val:.0f}%', ha='center', va='bottom', fontsize=9)
        ax2.set_ylabel('Reduction (%)')
        ax2.set_title('Size Reduction vs Basic', fontsize=10, fontweight='bold')
        ax2.set_ylim(0, 100)
    
    # 3. 파이 차트 (최적 결과)
    ax3 = fig.add_subplot(gs[1, 1])
    if sizes.get('basic', 0) > 0 and sizes.get('jlink', 0) > 0:
        saved = sizes['basic'] - sizes['jlink']
        remaining = sizes['jlink']
        ax3.pie([remaining, saved], 
                labels=[f'Final\n{remaining:.0f}MB', f'Saved\n{saved:.0f}MB'],
                colors=['#3498db', '#2ecc71'],
                autopct='%1.0f%%', startangle=90)
        ax3.set_title('Best Result (Jlink)', fontsize=10, fontweight='bold')
    
    # 4. 핵심 지표
    ax4 = fig.add_subplot(gs[1, 2])
    ax4.axis('off')
    
    if sizes.get('basic', 0) > 0 and sizes.get('jlink', 0) > 0:
        metrics = [
            ('Original Size', f"{sizes['basic']:.0f} MB"),
            ('Best Optimized', f"{sizes['jlink']:.0f} MB"),
            ('Total Saved', f"{sizes['basic'] - sizes['jlink']:.0f} MB"),
            ('Reduction Rate', f"{(1-sizes['jlink']/sizes['basic'])*100:.1f}%"),
        ]
        
        y_start = 0.85
        for i, (label, value) in enumerate(metrics):
            ax4.text(0.1, y_start - i*0.2, label + ':', fontsize=11, 
                    transform=ax4.transAxes, fontweight='bold')
            ax4.text(0.6, y_start - i*0.2, value, fontsize=11,
                    transform=ax4.transAxes, color='#2980b9', fontweight='bold')
        
        ax4.set_title('Key Metrics', fontsize=10, fontweight='bold', y=0.95)
    
    # 전체 제목
    fig.suptitle('Docker Image Optimization Dashboard\nBookShelf API', 
                 fontsize=16, fontweight='bold', y=0.98)
    
    plt.savefig(f'{output_dir}/05_dashboard.png', dpi=150, bbox_inches='tight')
    print(f"✓ Dashboard saved: {output_dir}/05_dashboard.png")
    plt.close()

def main():
    output_dir = './reports'
    os.makedirs(output_dir, exist_ok=True)
    
    print("=" * 50)
    print("Docker Image Visualization Report Generator")
    print("=" * 50)
    print()
    
    # 이미지 크기 조회
    print("Fetching Docker image sizes...")
    sizes = get_image_sizes()
    print(f"Found images: {sizes}")
    print()
    
    # 차트 생성
    print("Generating charts...")
    create_bar_chart(sizes, output_dir)
    create_waterfall_chart(sizes, output_dir)
    create_pie_chart(sizes, output_dir)
    create_horizontal_bar(sizes, output_dir)
    create_summary_dashboard(sizes, output_dir)
    
    print()
    print("=" * 50)
    print(f"All charts saved to: {output_dir}/")
    print("=" * 50)

if __name__ == '__main__':
    main()
