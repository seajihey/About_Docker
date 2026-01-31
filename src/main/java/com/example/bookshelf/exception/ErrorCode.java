package com.example.bookshelf.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    // Common
    INVALID_INPUT_VALUE(HttpStatus.BAD_REQUEST, "COMMON_001", "잘못된 입력값입니다."),
    METHOD_NOT_ALLOWED(HttpStatus.METHOD_NOT_ALLOWED, "COMMON_002", "지원하지 않는 HTTP 메서드입니다."),
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "COMMON_003", "서버 내부 오류가 발생했습니다."),

    // Book
    BOOK_NOT_FOUND(HttpStatus.NOT_FOUND, "BOOK_001", "도서를 찾을 수 없습니다."),
    DUPLICATE_ISBN(HttpStatus.CONFLICT, "BOOK_002", "이미 등록된 ISBN입니다."),
    INVALID_STOCK_QUANTITY(HttpStatus.BAD_REQUEST, "BOOK_003", "유효하지 않은 재고 수량입니다.");

    private final HttpStatus httpStatus;
    private final String code;
    private final String message;
}
