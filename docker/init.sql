-- BookShelf Database 초기화 스크립트

-- 샘플 데이터 삽입 (테이블은 JPA가 자동 생성)
-- 애플리케이션 시작 후 자동으로 테이블이 생성되면 아래 데이터가 삽입됨

-- 초기 설정
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- 테이블이 존재하면 샘플 데이터 삽입
-- (JPA ddl-auto: update 사용 시 테이블 자동 생성 후 적용)

DELIMITER //

CREATE PROCEDURE IF NOT EXISTS insert_sample_data()
BEGIN
    -- 테이블 존재 여부 확인
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'bookshelf' AND table_name = 'books') THEN
        -- 기존 데이터가 없을 때만 삽입
        IF (SELECT COUNT(*) FROM books) = 0 THEN
            INSERT INTO books (title, author, isbn, publisher, price, stock_quantity, category, description, published_date, created_at, updated_at)
            VALUES
            ('클린 코드', '로버트 C. 마틴', '9788966260959', '인사이트', 33000, 100, 'TECHNOLOGY', '애자일 소프트웨어 장인 정신. 나쁜 코드도 돌아는 간다. 그러나...', '2013-12-24', NOW(), NOW()),
            ('이펙티브 자바', '조슈아 블로크', '9788966262281', '인사이트', 36000, 80, 'TECHNOLOGY', '자바 플랫폼 모범 사례의 결정판', '2018-11-01', NOW(), NOW()),
            ('객체지향의 사실과 오해', '조영호', '9788998139766', '위키북스', 20000, 120, 'TECHNOLOGY', '역할, 책임, 협력 관점에서 본 객체지향', '2015-06-17', NOW(), NOW()),
            ('자바 ORM 표준 JPA 프로그래밍', '김영한', '9788960777330', '에이콘', 43000, 50, 'TECHNOLOGY', 'JPA 기본부터 실무까지', '2015-07-28', NOW(), NOW()),
            ('토비의 스프링 3.1', '이일민', '9788960773417', '에이콘', 72000, 30, 'TECHNOLOGY', '스프링의 이해와 원리', '2012-09-21', NOW(), NOW()),
            ('1984', '조지 오웰', '9788937460777', '민음사', 10800, 200, 'FICTION', '빅 브라더가 지배하는 전체주의 사회', '2003-06-20', NOW(), NOW()),
            ('데미안', '헤르만 헤세', '9788937460449', '민음사', 8800, 150, 'FICTION', '한 청년의 자아 찾기 여정', '2000-05-15', NOW(), NOW()),
            ('코스모스', '칼 세이건', '9788983711892', '사이언스북스', 22000, 60, 'SCIENCE', '우주의 경이로움을 담은 과학 교양서', '2006-12-20', NOW(), NOW()),
            ('총, 균, 쇠', '재레드 다이아몬드', '9788970127248', '문학사상', 28000, 70, 'HISTORY', '무기, 병균, 금속은 인류의 운명을 어떻게 바꿨는가', '2005-12-19', NOW(), NOW()),
            ('아주 작은 습관의 힘', '제임스 클리어', '9791196203009', '비즈니스북스', 16000, 180, 'SELF_HELP', '최고의 변화는 가장 작은 습관에서 시작된다', '2019-02-26', NOW(), NOW());
        END IF;
    END IF;
END //

DELIMITER ;

-- 프로시저 실행 (테이블 생성 후)
-- CALL insert_sample_data();
