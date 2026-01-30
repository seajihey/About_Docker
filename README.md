# Docker 이미지 경량화: 느린 배포의 원인과 해결책

## 서론: 왜 다시 '배포'를 이야기하는가?

### 컴퓨팅 자원 관리의 진화

| 시대 | 기술 | 특징 | 한계 |
|------|------|------|------|
| 1세대 | Bare Metal | 물리 서버 직접 운영 | 자원 낭비, 확장 어려움 |
| 2세대 | VM (가상머신) | 하이퍼바이저 기반 격리 | OS 전체 복제로 인한 무거움 |
| 3세대 | LXC | 커널 공유 기반 컨테이너 | 설정 복잡성 |
| 4세대 | Docker | 표준화된 컨테이너 | **오늘의 주제** |

### 문제 제기

> "우리 팀은 Docker를 쓰는데 왜 배포가 여전히 느릴까?"

많은 팀이 Docker를 도입했지만, 여전히 다음과 같은 문제에 직면합니다.

- 이미지 빌드에 10분 이상 소요
- 레지스트리에서 Pull 받는 데 네트워크 병목 발생
- 클라우드 Egress 비용이 예상보다 높음
- 오토스케일링 시 새 인스턴스 기동이 느림

**이 문서의 목표**: 현상 → 원인 → 해결책 → 비즈니스 가치의 흐름으로 Docker 이미지 최적화를 완전히 이해합니다.

---

## 1. Docker의 본질 이해하기

### Infrastructure as Code (IaC)

Docker는 단순한 가상화 도구가 아닙니다. **인프라를 코드로 정의**하는 IaC의 핵심 도구입니다.

```dockerfile
# 이것은 설정 파일이 아닌, 인프라를 정의하는 '코드'입니다
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
CMD ["node", "server.js"]
```

### 격리 메커니즘

Docker 컨테이너의 격리는 Linux 커널의 두 가지 핵심 기능에 의존합니다.

| 기술 | 역할 | 격리 대상 |
|------|------|-----------|
| **Namespace** | 프로세스 격리 | PID, Network, Mount, User 등 |
| **cgroups** | 자원 제한 | CPU, Memory, I/O |

이 두 기술 덕분에 컨테이너는 VM 없이도 완전한 격리 환경을 제공합니다.

---

## 2. [심층 분석] 도커 이미지는 왜 무거워지는가?

### Layer와 UnionFS의 이해

Docker 이미지는 **여러 개의 읽기 전용 레이어가 쌓인 구조**입니다.

```
┌─────────────────────────────┐
│     Container Layer (R/W)   │  ← 실행 시 생성되는 쓰기 가능 레이어
├─────────────────────────────┤
│     Layer 4: CMD            │
├─────────────────────────────┤
│     Layer 3: COPY .         │
├─────────────────────────────┤
│     Layer 2: RUN npm ci     │
├─────────────────────────────┤
│     Layer 1: FROM node      │  ← 베이스 이미지
└─────────────────────────────┘
```

UnionFS(Overlay2)는 이 레이어들을 **하나의 통합된 파일시스템처럼** 보이게 합니다.

### 레이어의 불변성: 가장 흔한 실수

> ⚠️ **핵심 포인트**: 한 번 생성된 레이어는 절대 수정되지 않습니다.

```dockerfile
# ❌ 잘못된 예시: 용량이 전혀 줄어들지 않습니다
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y build-essential  # Layer A: +500MB
RUN rm -rf /var/lib/apt/lists/*                           # Layer B: +0MB (삭제 '기록'만 추가)
```

**결과**: 총 이미지 크기는 여전히 500MB 이상입니다.

```dockerfile
# ✅ 올바른 예시: 하나의 레이어에서 설치와 정리를 동시에
FROM ubuntu:22.04
RUN apt-get update \
    && apt-get install -y build-essential \
    && rm -rf /var/lib/apt/lists/*  # 같은 레이어에서 삭제 → 실제 용량 감소
```

### Copy-on-Write (CoW)

컨테이너가 실행될 때, 파일 수정은 다음과 같이 처리됩니다.

1. 원본 레이어의 파일은 **그대로 유지**
2. 수정이 필요하면 해당 파일을 **Container Layer로 복사**
3. 복사된 파일에서만 **수정 수행**

이 방식 덕분에 같은 이미지를 사용하는 여러 컨테이너가 베이스 레이어를 공유할 수 있습니다.

---

## 3. [실전 전략] 이미지 다이어트: 3대 핵심 전략

### 전략 1: 베이스 이미지 교체 (The Choice)

베이스 이미지 선택만으로 **10배 이상의 용량 차이**가 발생합니다.

| 베이스 이미지 | 크기 | 특징 | 적합한 경우 |
|---------------|------|------|-------------|
| `ubuntu:22.04` | ~77MB | 풀 패키지, 디버깅 용이 | 개발/테스트 환경 |
| `node:18` | ~1GB | 개발 도구 포함 | 빌드 스테이지 |
| `node:18-alpine` | ~180MB | musl libc 기반, 경량 | 대부분의 프로덕션 |
| `node:18-slim` | ~240MB | glibc 기반, 일부 도구 제거 | Alpine 호환 이슈 시 |
| `gcr.io/distroless/nodejs18` | ~120MB | 쉘 없음, 최소 런타임 | 보안 중시 프로덕션 |

```dockerfile
# Before: 1GB 이상
FROM node:18

# After: ~180MB
FROM node:18-alpine
```

### 전략 2: Multi-Stage Build (The Transformation)

빌드 환경과 실행 환경을 **완전히 분리**합니다.

```dockerfile
# ==================== Stage 1: Builder ====================
FROM node:18 AS builder
WORKDIR /app

# 의존성 설치 (빌드 도구 포함)
COPY package*.json ./
RUN npm ci

# 애플리케이션 빌드
COPY . .
RUN npm run build

# ==================== Stage 2: Production ====================
FROM node:18-alpine AS production
WORKDIR /app

# 프로덕션 의존성만 설치
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# 빌드 결과물만 복사
COPY --from=builder /app/dist ./dist

# 비root 사용자로 실행
USER node
CMD ["node", "dist/server.js"]
```

**결과 비교**:

```bash
# 단일 스테이지
$ docker images myapp:single
REPOSITORY   TAG      SIZE
myapp        single   847MB

# 멀티 스테이지
$ docker images myapp:multi
REPOSITORY   TAG      SIZE
myapp        multi    127MB   # 85% 감소!
```

### 전략 3: 레이어 캐싱 최적화 (The Order)

Dockerfile의 **명령어 순서**가 빌드 속도를 결정합니다.

**핵심 원칙**: 변경이 적은 것 → 변경이 잦은 것 순으로 배치

```dockerfile
# ❌ 비효율적인 순서: 코드 변경 시 모든 레이어 재빌드
FROM node:18-alpine
WORKDIR /app
COPY . .                    # 코드 변경 → 이 레이어부터 캐시 무효화
RUN npm ci                  # 매번 재설치 (3-5분 소요)
CMD ["node", "server.js"]
```

```dockerfile
# ✅ 최적화된 순서: 의존성 캐시 활용
FROM node:18-alpine
WORKDIR /app

# 1. 의존성 정의 파일 먼저 복사 (자주 변경되지 않음)
COPY package*.json ./

# 2. 의존성 설치 (package.json이 변경되지 않으면 캐시 사용)
RUN npm ci

# 3. 소스 코드 복사 (자주 변경됨)
COPY . .

CMD ["node", "server.js"]
```

**빌드 로그 비교**:

```bash
# 최적화 전: 코드만 수정했는데 전체 재빌드
Step 3/5 : COPY . .
Step 4/5 : RUN npm ci
 ---> Running in 2a3b4c5d6e7f   # 매번 3분 소요

# 최적화 후: 코드만 수정 시
Step 3/5 : COPY package*.json ./
 ---> Using cache              # ✅ 캐시 사용
Step 4/5 : RUN npm ci
 ---> Using cache              # ✅ 캐시 사용 (3분 → 0초)
Step 5/6 : COPY . .
 ---> 1a2b3c4d5e6f             # 이것만 새로 실행
```

---

## 4. 결과: 경량화가 CI/CD에 주는 선물

### CI 단계: 빌드 시간 감소

| 지표 | 최적화 전 | 최적화 후 | 개선율 |
|------|-----------|-----------|--------|
| 초기 빌드 | 8분 | 3분 | 62% ↓ |
| 코드 변경 후 재빌드 | 8분 | 45초 | **91% ↓** |
| 이미지 크기 | 847MB | 127MB | 85% ↓ |

**개발자 생산성 향상**: 하루 10번 빌드 × 7분 절약 = **일 70분 절약**

### CD 단계: 배포 속도 향상

```
이미지 Push/Pull 속도 비교 (100Mbps 네트워크 기준)

847MB 이미지:
  Push: ~68초 | Pull: ~68초 | 총 배포: ~2분 20초

127MB 이미지:
  Push: ~10초 | Pull: ~10초 | 총 배포: ~20초
```

**장애 복구(Rollback) 시간**: 2분 20초 → 20초 (긴급 상황에서 결정적 차이)

### 운영 관점: 비용 절감

#### 1. 오토스케일링 Cold Start 개선

```
트래픽 급증 시 새 인스턴스 기동 시간:

큰 이미지 (847MB):
  이미지 Pull: 68초 + 컨테이너 시작: 5초 = 총 73초
  → 트래픽 급증 시 73초간 기존 인스턴스에 과부하

작은 이미지 (127MB):
  이미지 Pull: 10초 + 컨테이너 시작: 5초 = 총 15초
  → 빠른 스케일아웃으로 안정적 서비스
```

#### 2. 클라우드 비용 절감

```
월간 Egress 비용 계산 (AWS 기준, $0.09/GB)

시나리오: 일 100회 배포 × 30일 = 월 3,000회 배포

큰 이미지: 3,000 × 847MB = 2,541GB → $228.69/월
작은 이미지: 3,000 × 127MB = 381GB  → $34.29/월

월 절감액: $194.40 (연간 $2,332.80)
```

#### 3. 레지스트리 스토리지 비용

```
이미지 버전 100개 보관 시:

큰 이미지: 847MB × 100 = 84.7GB 스토리지
작은 이미지: 127MB × 100 = 12.7GB 스토리지

72GB 스토리지 절감
```

---

## 요약: 최적화 체크리스트

```
□ 베이스 이미지를 Alpine 또는 Distroless로 교체했는가?
□ Multi-Stage Build를 적용했는가?
□ 빌드 도구와 런타임 환경을 분리했는가?
□ Dockerfile 명령어를 변경 빈도 순으로 정렬했는가?
□ 하나의 RUN 명령에서 설치와 정리를 함께 수행하는가?
□ .dockerignore로 불필요한 파일을 제외했는가?
□ 프로덕션 의존성만 설치했는가? (npm ci --only=production)
```

---

## 참고 자료

- [Docker Official Documentation - Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Google Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [Alpine Linux](https://alpinelinux.org/)

---

> **핵심 메시지**: Docker 이미지 최적화는 단순한 기술적 개선이 아닙니다. 개발자 생산성, 서비스 안정성, 그리고 운영 비용에 직접적인 영향을 미치는 **비즈니스 가치**입니다.
