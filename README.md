# 📚 BookShelf API

Docker 이미지 경량화 실습을 위한 Spring Boot 기반 도서 관리 REST API

## 기술 스택

| 구분 | 기술 | 버전 |
|------|------|------|
| Framework | Spring Boot | 3.5.10 |
| Language | Java | 17 |
| ORM | Spring Data JPA | - |
| Database | MySQL | 8.0 |
| Build | Gradle (Groovy) | 8.x |
| Logging | Log4j2 + SLF4J | - |
| Documentation | SpringDoc OpenAPI | 2.8.0 |
| Mapping | MapStruct | 1.5.5 |

## 프로젝트 구조

```
bookshelf/
├── src/main/java/com/example/bookshelf/
│   ├── domain/          # 엔티티
│   ├── repository/      # JPA Repository
│   ├── service/         # 비즈니스 로직
│   ├── controller/      # REST Controller
│   ├── dto/             # 요청/응답 DTO
│   ├── mapper/          # MapStruct Mapper
│   ├── exception/       # 예외 처리
│   └── config/          # 설정 클래스
├── docker/
│   ├── Dockerfile.basic       # 1단계: 기본 (무거운)
│   ├── Dockerfile.multistage  # 2단계: 멀티스테이지
│   ├── Dockerfile.jre         # 3단계: JRE Only
│   ├── Dockerfile.alpine      # 4단계: Alpine
│   ├── Dockerfile.jlink       # 5단계: Jlink
│   └── Dockerfile.native      # 6단계: Native
└── scripts/
    ├── build-all-images.sh    # 전체 빌드
    └── compare-sizes.sh       # 크기 비교
```

## 빠른 시작

### 1. 로컬 개발 환경 (MySQL만 Docker)

```bash
# MySQL 컨테이너 시작
docker-compose -f docker-compose.local.yml up -d

# 애플리케이션 실행
./gradlew bootRun
```

### 2. 전체 Docker 환경

```bash
# Alpine 버전으로 실행
docker-compose --profile alpine up -d

# 또는 특정 버전 선택
docker-compose --profile basic up -d      # 기본
docker-compose --profile jre up -d        # JRE Only
docker-compose --profile jlink up -d      # Jlink
```

## API 엔드포인트

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/books` | 도서 등록 |
| GET | `/api/v1/books` | 도서 목록 (페이징) |
| GET | `/api/v1/books/{id}` | 도서 상세 |
| GET | `/api/v1/books/isbn/{isbn}` | ISBN 조회 |
| GET | `/api/v1/books/category/{category}` | 카테고리별 조회 |
| GET | `/api/v1/books/search?keyword=` | 키워드 검색 |
| PUT | `/api/v1/books/{id}` | 도서 수정 |
| PATCH | `/api/v1/books/{id}/stock` | 재고 변경 |
| DELETE | `/api/v1/books/{id}` | 도서 삭제 |

### Swagger UI
- URL: http://localhost:8080/swagger-ui.html

### Actuator
- Health: http://localhost:8080/actuator/health

## Docker 이미지 경량화 실습

### 전체 이미지 빌드

```bash
chmod +x scripts/*.sh
./scripts/build-all-images.sh
```

### 이미지 크기 비교

```bash
./scripts/compare-sizes.sh
```

### 예상 결과

| 단계 | Dockerfile | 예상 크기 | 감소율 |
|------|------------|-----------|--------|
| 1 | basic | ~650MB | 기준 |
| 2 | multistage | ~350MB | -46% |
| 3 | jre | ~280MB | -57% |
| 4 | alpine | ~200MB | -69% |
| 5 | jlink | ~150MB | -77% |
| 6 | native | ~80MB | -88% |

## 경량화 기법 설명

### 1. Basic (기본)
- 전체 JDK 포함
- 단일 스테이지 빌드
- Gradle 캐시 미활용

### 2. Multi-stage
- 빌드/런타임 스테이지 분리
- 빌드 도구 제외

### 3. JRE Only
- JDK → JRE 전환
- 컴파일러, 개발 도구 제외

### 4. Alpine
- Debian → Alpine Linux (~5MB)
- musl libc 사용

### 5. Jlink
- 커스텀 JRE 생성
- 필요한 Java 모듈만 포함

### 6. Native (GraalVM)
- AOT 컴파일
- JVM 없이 실행
- 빌드 시간 10분+, 메모리 8GB+ 필요

## 포트 매핑

| 서비스 | 포트 |
|--------|------|
| MySQL | 3306 |
| App (basic) | 8081 |
| App (multistage) | 8082 |
| App (jre) | 8083 |
| App (alpine) | 8084 |
| App (jlink) | 8085 |
| App (native) | 8086 |

## 테스트

```bash
# 단위 테스트
./gradlew test

# API 테스트 (curl)
curl -X POST http://localhost:8080/api/v1/books \
  -H "Content-Type: application/json" \
  -d '{
    "title": "테스트 도서",
    "author": "테스트 저자",
    "isbn": "9781234567890",
    "price": 20000,
    "category": "TECHNOLOGY"
  }'
```

## 라이선스

MIT License
