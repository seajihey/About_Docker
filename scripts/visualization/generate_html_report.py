#!/usr/bin/env python3
"""
Docker 이미지 최적화 종합 HTML 리포트 생성기
- 이미지 크기 비교
- 레이어 분석
- 빌드 시간 추이
- 권장사항
"""

import subprocess
import json
import os
from datetime import datetime

def get_image_info():
    """Docker 이미지 정보 수집"""
    images = ['basic', 'multistage', 'jre', 'alpine', 'jlink', 'native']
    info = {}
    
    for img in images:
        try:
            # 크기
            result = subprocess.run(
                ['docker', 'image', 'inspect', f'bookshelf:{img}'],
                capture_output=True, text=True, check=True
            )
            data = json.loads(result.stdout)[0]
            
            info[img] = {
                'size_bytes': data['Size'],
                'size_mb': data['Size'] / (1024 * 1024),
                'created': data['Created'],
                'architecture': data['Architecture'],
                'os': data['Os'],
                'layers': len(data.get('RootFS', {}).get('Layers', [])),
            }
        except (subprocess.CalledProcessError, json.JSONDecodeError, IndexError):
            info[img] = None
    
    return info

def generate_html_report(info, output_path):
    """HTML 리포트 생성"""
    
    # 기준 크기 (basic)
    base_size = info.get('basic', {}).get('size_mb', 1) if info.get('basic') else 1
    
    # 정렬된 이미지 (크기순)
    sorted_images = sorted(
        [(k, v) for k, v in info.items() if v],
        key=lambda x: x[1]['size_mb']
    )
    
    # 최소/최대
    if sorted_images:
        min_img = sorted_images[0]
        max_img = sorted_images[-1]
    else:
        min_img = max_img = ('N/A', {'size_mb': 0})
    
    html = f'''<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker Image Optimization Report - BookShelf</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #eee;
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
        }}
        header {{
            text-align: center;
            padding: 40px 0;
            border-bottom: 1px solid #333;
            margin-bottom: 40px;
        }}
        h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
            background: linear-gradient(90deg, #00d4ff, #7c3aed);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }}
        .subtitle {{
            color: #888;
            font-size: 1.1em;
        }}
        .metrics {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }}
        .metric-card {{
            background: rgba(255,255,255,0.05);
            border-radius: 16px;
            padding: 24px;
            text-align: center;
            border: 1px solid rgba(255,255,255,0.1);
            transition: transform 0.3s;
        }}
        .metric-card:hover {{
            transform: translateY(-5px);
        }}
        .metric-value {{
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 8px;
        }}
        .metric-label {{
            color: #888;
            font-size: 0.9em;
        }}
        .success {{ color: #00d4ff; }}
        .warning {{ color: #ffd93d; }}
        .danger {{ color: #ff6b6b; }}
        .chart-container {{
            background: rgba(255,255,255,0.05);
            border-radius: 16px;
            padding: 30px;
            margin-bottom: 30px;
            border: 1px solid rgba(255,255,255,0.1);
        }}
        .chart-title {{
            font-size: 1.3em;
            margin-bottom: 20px;
            color: #fff;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }}
        th, td {{
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }}
        th {{
            background: rgba(255,255,255,0.05);
            font-weight: 600;
        }}
        tr:hover {{
            background: rgba(255,255,255,0.03);
        }}
        .size-bar {{
            height: 8px;
            background: linear-gradient(90deg, #00d4ff, #7c3aed);
            border-radius: 4px;
            margin-top: 5px;
        }}
        .badge {{
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: 600;
        }}
        .badge-best {{ background: #00d4ff; color: #000; }}
        .badge-good {{ background: #00c853; color: #000; }}
        .badge-warning {{ background: #ffd93d; color: #000; }}
        .badge-large {{ background: #ff6b6b; color: #000; }}
        .recommendations {{
            background: rgba(0, 212, 255, 0.1);
            border-left: 4px solid #00d4ff;
            padding: 20px;
            border-radius: 0 16px 16px 0;
            margin-top: 30px;
        }}
        .recommendations h3 {{
            margin-bottom: 15px;
        }}
        .recommendations ul {{
            margin-left: 20px;
        }}
        .recommendations li {{
            margin-bottom: 10px;
            line-height: 1.6;
        }}
        footer {{
            text-align: center;
            padding: 40px 0;
            color: #666;
            border-top: 1px solid #333;
            margin-top: 40px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🐳 Docker Image Optimization Report</h1>
            <p class="subtitle">BookShelf API - Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </header>

        <div class="metrics">
            <div class="metric-card">
                <div class="metric-value danger">{max_img[1]['size_mb']:.0f}MB</div>
                <div class="metric-label">Original Size (Basic)</div>
            </div>
            <div class="metric-card">
                <div class="metric-value success">{min_img[1]['size_mb']:.0f}MB</div>
                <div class="metric-label">Best Optimized ({min_img[0].upper()})</div>
            </div>
            <div class="metric-card">
                <div class="metric-value warning">{max_img[1]['size_mb'] - min_img[1]['size_mb']:.0f}MB</div>
                <div class="metric-label">Total Saved</div>
            </div>
            <div class="metric-card">
                <div class="metric-value success">{(1 - min_img[1]['size_mb']/max_img[1]['size_mb'])*100:.0f}%</div>
                <div class="metric-label">Reduction Rate</div>
            </div>
        </div>

        <div class="chart-container">
            <h2 class="chart-title">📊 Image Size Comparison</h2>
            <canvas id="sizeChart"></canvas>
        </div>

        <div class="chart-container">
            <h2 class="chart-title">📋 Detailed Comparison</h2>
            <table>
                <thead>
                    <tr>
                        <th>Image</th>
                        <th>Size</th>
                        <th>Layers</th>
                        <th>Reduction</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
'''
    
    # 테이블 행 추가
    for img, data in sorted(info.items(), key=lambda x: -x[1]['size_mb'] if x[1] else 0):
        if data:
            reduction = (1 - data['size_mb']/base_size) * 100 if base_size > 0 else 0
            size_percent = (data['size_mb']/base_size) * 100 if base_size > 0 else 0
            
            # 배지 결정
            if data['size_mb'] == min_img[1]['size_mb']:
                badge = '<span class="badge badge-best">⭐ BEST</span>'
            elif reduction >= 60:
                badge = '<span class="badge badge-good">EXCELLENT</span>'
            elif reduction >= 30:
                badge = '<span class="badge badge-warning">GOOD</span>'
            else:
                badge = '<span class="badge badge-large">LARGE</span>'
            
            html += f'''
                    <tr>
                        <td><strong>{img.upper()}</strong></td>
                        <td>
                            {data['size_mb']:.0f} MB
                            <div class="size-bar" style="width: {size_percent}%"></div>
                        </td>
                        <td>{data['layers']}</td>
                        <td>{reduction:.0f}%</td>
                        <td>{badge}</td>
                    </tr>
'''
    
    html += '''
                </tbody>
            </table>
        </div>

        <div class="chart-container">
            <h2 class="chart-title">🥧 Size Distribution</h2>
            <canvas id="pieChart"></canvas>
        </div>

        <div class="recommendations">
            <h3>💡 Recommendations</h3>
            <ul>
                <li><strong>개발/테스트 환경:</strong> Alpine 이미지 사용 권장 (빠른 빌드, 적절한 크기)</li>
                <li><strong>프로덕션 환경:</strong> Jlink 이미지 사용 권장 (최소 크기, 보안 강화)</li>
                <li><strong>빠른 시작이 중요한 경우:</strong> Native 이미지 고려 (단, 빌드 시간 증가)</li>
                <li><strong>CI/CD 최적화:</strong> 멀티스테이지 빌드로 캐시 활용 극대화</li>
            </ul>
        </div>

        <footer>
            <p>Generated by BookShelf Docker Optimization Tool</p>
        </footer>
    </div>

    <script>
'''
    
    # Chart.js 데이터
    labels = [img.upper() for img in info.keys() if info[img]]
    sizes = [info[img]['size_mb'] for img in info.keys() if info[img]]
    colors = ['#e74c3c', '#e67e22', '#f39c12', '#27ae60', '#2980b9', '#9b59b6'][:len(labels)]
    
    html += f'''
        // Bar Chart
        const ctx1 = document.getElementById('sizeChart').getContext('2d');
        new Chart(ctx1, {{
            type: 'bar',
            data: {{
                labels: {json.dumps(labels)},
                datasets: [{{
                    label: 'Size (MB)',
                    data: {json.dumps([round(s, 1) for s in sizes])},
                    backgroundColor: {json.dumps(colors)},
                    borderColor: {json.dumps(colors)},
                    borderWidth: 2,
                    borderRadius: 8
                }}]
            }},
            options: {{
                responsive: true,
                plugins: {{
                    legend: {{ display: false }}
                }},
                scales: {{
                    y: {{
                        beginAtZero: true,
                        grid: {{ color: 'rgba(255,255,255,0.1)' }},
                        ticks: {{ color: '#888' }}
                    }},
                    x: {{
                        grid: {{ display: false }},
                        ticks: {{ color: '#888' }}
                    }}
                }}
            }}
        }});

        // Pie Chart
        const ctx2 = document.getElementById('pieChart').getContext('2d');
        new Chart(ctx2, {{
            type: 'doughnut',
            data: {{
                labels: {json.dumps(labels)},
                datasets: [{{
                    data: {json.dumps([round(s, 1) for s in sizes])},
                    backgroundColor: {json.dumps(colors)},
                    borderWidth: 0
                }}]
            }},
            options: {{
                responsive: true,
                plugins: {{
                    legend: {{
                        position: 'right',
                        labels: {{ color: '#888' }}
                    }}
                }}
            }}
        }});
    </script>
</body>
</html>
'''
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"✓ HTML report saved: {output_path}")

def main():
    output_dir = './reports'
    os.makedirs(output_dir, exist_ok=True)
    
    print("=" * 50)
    print("Docker Image Optimization HTML Report Generator")
    print("=" * 50)
    print()
    
    print("Collecting image information...")
    info = get_image_info()
    
    found = sum(1 for v in info.values() if v)
    print(f"Found {found} images")
    print()
    
    print("Generating HTML report...")
    generate_html_report(info, f'{output_dir}/optimization_report.html')
    
    print()
    print("=" * 50)
    print(f"Report saved to: {output_dir}/optimization_report.html")
    print("Open in browser to view interactive charts!")
    print("=" * 50)

if __name__ == '__main__':
    main()
