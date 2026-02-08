# 🐳 Docker 이미지 경량화: 느린 배포의 원인과 해결책

Spring Boot 기반 애플리케이션의 Docker 이미지를 **753MB → 122MB (84% 경량화)** 한 실전 가이드

---
## 📋 목차

- [🎯 서론: 왜 다시 배포를 이야기하는가?](#-서론-왜-다시-배포를-이야기하는가)
- [🔍 Docker의 본질 이해하기](#-docker의-본질-이해하기)
- [❓ 도커 이미지는 왜 무거워지는가?](#-도커-이미지는-왜-무거워지는가)
- [🚀 이미지 최적화 전략](#-이미지-최적화-전략)
- [🔧 트러블슈팅](#-트러블슈팅)
- [📊 CI/CD 파이프라인 개선 효과](#-cicd-파이프라인-개선-효과)
- [✅ 최적화 체크리스트](#-최적화-체크리스트)
- [📚 참고 자료](#-참고-자료)

<br>

---

## 🎯 서론: 왜 다시 '배포'를 이야기하는가?

### 컴퓨팅 자원 관리의 진화

| 시대  | 기술          | 특징                    | 한계                       |
| ----- | ------------- | ----------------------- | -------------------------- |
| 1세대 | Bare Metal    | 물리 서버 직접 운영     | 자원 낭비, 확장 어려움     |
| 2세대 | VM (가상머신) | 하이퍼바이저 기반 격리  | OS 전체 복제로 인한 무거움 |
| 3세대 | LXC           | 커널 공유 기반 컨테이너 | 설정 복잡성                |
| 4세대 | Docker        | 표준화된 컨테이너       | 오늘의 주제                |

### 문제 제기

> "우리 팀은 Docker를 쓰는데 왜 배포가 여전히 느릴까?"

**주요 문제:**
- 이미지 빌드에 10분 이상 소요
- 레지스트리 Pull 시 네트워크 병목
- 클라우드 Egress 비용 부담
- 오토스케일링 시 기동 지연

**목표:** `현상 → 원인 → 해결책 → 비즈니스 가치` 흐름으로 Docker 이미지 최적화 완전 이해

<br><br>

---

## 🔍 Docker의 본질 이해하기

### 1. Infrastructure as Code (IaC)

Dockerfile은 환경 설정이 아닌 **인프라를 코드로 정의하는 도구**입니다.

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
CMD ["node", "server.js"]
```

### 2. 격리 메커니즘

| 기술 | 역할 | 격리 대상 |
| ---- | ---- | ---------- |
| Namespace | 프로세스 격리 | PID, Network, Mount, User 등 |
| cgroups | 자원 제한 | CPU, Memory, I/O |

이 두 기술 덕분에 VM 없이도 격리된 실행 환경이 가능합니다.


<br><br><br>
---

## ❓ 도커 이미지는 왜 무거워지는가?

### Layer와 UnionFS 이해하기

Docker 이미지는 **여러 읽기 전용 레이어의 합**입니다.

```
┌─────────────────────────────┐
│   Container Layer (R/W)     │
├─────────────────────────────┤
│     Layer 4: CMD            │
├─────────────────────────────┤
│     Layer 3: COPY .         │
├─────────────────────────────┤
│     Layer 2: RUN npm ci     │
├─────────────────────────────┤
│     Layer 1: FROM node      │
└─────────────────────────────┘
```

### 1. 레이어의 불변성

> 한 번 생성된 레이어는 수정되지 않습니다.

```dockerfile
# 잘못된 예시
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y build-essential
RUN rm -rf /var/lib/apt/lists/*
```

→ 총 이미지 크기는 여전히 500MB 이상.

```dockerfile
# 올바른 예시
FROM ubuntu:22.04
RUN apt-get update \
    && apt-get install -y build-essential \
    && rm -rf /var/lib/apt/lists/*

```

### 2. Copy-on-Write (CoW)

- 원본은 그대로 유지  
- 수정 시 Container Layer로 복사  
- 여러 컨테이너가 베이스 레이어를 공유 가능

### 3. 빌드 산출물의 잔존

빌드 도구, 캐시, 테스트 결과물 등이 별도 정리하지 않으면 최종 이미지에 잔존합니다.  
→ **Multi-stage build**로 불필요 파일 제거 가능.

<br><br><br>

---

## 🚀 이미지 최적화 전략

### Stage 1: Basic (753MB)

- 단일 스테이지 빌드
- `eclipse-temurin:17-jdk` 사용
- 빌드 도구 및 소스 포함

**결과:** 이미지 753MB, 낭비 12MB  
**문제:** JDK 전체 포함, Gradle 캐시 잔존

---

### Stage 2: Multi-stage Build (462MB)

```dockerfile
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /app
COPY gradlew gradle build.gradle settings.gradle ./
RUN ./gradlew dependencies --no-daemon || true
COPY src src
RUN ./gradlew bootJar --no-daemon -x test

FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY --from=builder /app/build/libs/bookshelf.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

- 빌드/런타임 분리
- 불필요 파일 제거  
**효과:** 291MB 절감 (-39%)  
**한계:** JDK 포함

<br>

---

### Stage 3: JRE Only (312MB)

```dockerfile
FROM eclipse-temurin:17-jdk AS builder
# (빌드 과정 동일)

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/build/libs/bookshelf.jar app.jar
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

- 실행 전용 JRE 사용  
- JDK 대비 139MB 절감 (-59%)

<br>

---

### Stage 4: Alpine Base (234MB)

```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS builder
# (빌드 과정 동일)

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/bookshelf.jar app.jar
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
ENTRYPOINT ["sh", "-c", "java -jar app.jar"]
```

**효과:** Debian → Alpine 전환으로 519MB 절감 (-69%)  
**기본 이미지 크기:** 78MB → 8MB

<br>

---

### Stage 5: Custom JRE (Jlink) – 122MB

```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS builder
# 빌드 과정 동일

FROM eclipse-temurin:17-jdk-alpine AS jre-builder
RUN $JAVA_HOME/bin/jlink \
  --add-modules java.base,java.logging,java.sql,java.naming,java.desktop,java.management,java.security.jgss,java.instrument \
  --strip-debug \
  --no-man-pages \
  --no-header-files \
  --compress=2 \
  --output /custom-jre

FROM alpine:3.19
RUN apk add --no-cache ca-certificates tzdata
COPY --from=jre-builder /custom-jre /opt/java
COPY --from=builder /app/build/libs/bookshelf.jar app.jar
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"
ENTRYPOINT ["sh", "-c", "java -jar app.jar"]
```

- jlink로 최소 모듈만 포함  
- **결과:** 122MB (-84%)  

<br>

---

### Stage 6: GraalVM Native Image

- JVM 제거, AOT(기계어 변환)
- 실행 속도 0.1초 내외  
- 빌드 시간 길지만 런타임 성능 압도적  
- Spring Boot + Hibernate의 리플렉션 의존성으로 약간 더 큼 (137MB)

---

## 📊 핵심 결과 비교

| 단계 | 크기 | 절감률 | 실행속도 | 특징 |
|------|------|--------|----------|------|
| Basic | 753MB | - | 보통 | JDK 포함 |
| Multi-stage | 462MB | -39% | 보통 | 빌드 분리 |
| JRE | 312MB | -59% | 보통 | 런타임 전용 |
| Alpine | 234MB | -69% | 빠름 | OS 경량화 |
| Jlink | 122MB | **-84%** | 빠름 | 모듈 최소화 |
| Native | 337MB | -55% | **매우 빠름** | AOT 실행 |

<br><br><br>

---

## 📈 CI/CD 파이프라인 개선 효과

### CI: 빌드 시간

| 항목 | 최적화 전 | 최적화 후 | 개선율 |
|------|------------|------------|----------|
| 초기 빌드 | 8분 | 3분 | 62% |
| 코드 변경 후 재빌드 | 8분 | 45초 | **91% ↓** |
| 이미지 크기 | 847MB | 127MB | 85% ↓ |

하루 50회 빌드 시 **15분 절약** 가능

---

### CD: 배포 속도

100Mbps 네트워크 기준

```
743MB 이미지:
  Push: ~68초 | Pull: ~68초 | 총 2분 20초

122MB 이미지:
  Push: ~10초 | Pull: ~10초 | 총 20초
```

Rollback 시: **2분 20초 → 20초**

---

### 비용 절감 예시

**AWS Egress (0.09$/GB)**  
100회/일 × 30일 = 3000회 배포 기준:

- 743MB 이미지: $195.84 /월  
- 122MB 이미지: $32.13 /월  
→ **연 $1,964 절감**

<br><br>
---

## ✅ 최적화 체크리스트

| # | 항목 | 체크 |
|:-:|:-----|:----:|
| 1 | 베이스 이미지 Alpine 또는 Distroless 사용 | ⬜ |
| 2 | Multi-stage Build 적용 | ⬜ |
| 3 | Jlink 또는 Native 활용 | ⬜ |
| 4 | Dockerfile 명령어 변경 빈도순 정렬 | ⬜ |
| 5 | `.dockerignore` 적용 | ⬜ |
| 6 | 프로덕션 의존성만 설치 | ⬜ |

---

📚 참고 자료

<small> Dive: Docker 이미지 레이어 분석   -   https://github.com/wagoodman/dive </small><br>
<span style="color:gray"> Docker History (Image Layer History)   -   https://docs.docker.com/reference/cli/docker/image/history/</span><br>
<span style="color:gray"> Docker Storage Drivers & Layered Filesystem   -   https://docs.docker.com/storage/storagedriver/</span><br>
<span style="color:gray"> Best Practices for Writing Dockerfiles   -   https://docs.docker.com/develop/develop-images/dockerfile_best-practices/</span><br>
<span style="color:gray"> Multi-stage Builds   -   https://docs.docker.com/build/building/multi-stage/</span><br>
<span style="color:gray"> Docker Build Cache   -   https://docs.docker.com/build/cache/</span><br>
<span style="color:gray"> Docker Official Images Program   -   https://docs.docker.com/docker-hub/official_images/</span><br>
<span style="color:gray"> Docker Image Build Overview   -   https://docs.docker.com/build/</span><br>
<span style="color:gray"> jdeps (Java Dependency Analysis Tool)   -   https://docs.oracle.com/javase/21/tools/jdeps.html</span><br>
<span style="color:gray"> jlink (Java Linker)   -   https://docs.oracle.com/javase/21/tools/jlink.html</span><br>
<span style="color:gray"> Spring Boot Container Images   -   https://docs.spring.io/spring-boot/docs/current/reference/html/container-images.html</span><br>
<span style="color:gray">Spring Boot Native Image Support   -   https://docs.spring.io/spring-boot/docs/current/reference/html/native-image.html</span><br>
<span style="color:gray"> Linux Containers (LXC) Introduction   -   https://linuxcontainers.org/lxc/introduction/</span><br>
<span style="color:gray"> Linux cgroups v2 Documentation   -   https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html</span><br>
<span style="color:gray"> Linux Namespaces Manual   -   https://man7.org/linux/man-pages/man7/namespaces.7.html</span>
