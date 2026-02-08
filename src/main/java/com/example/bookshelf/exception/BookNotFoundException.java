package com.example.bookshelf.exception;

public class BookNotFoundException extends RuntimeException {

    private final Long bookId;

    public BookNotFoundException(Long bookId) {
        super(String.format("도서를 찾을 수 없습니다. (ID: %d)", bookId));
        this.bookId = bookId;
    }

    public BookNotFoundException(String message) {
        super(message);
        this.bookId = null;
    }

    public Long getBookId() {
        return bookId;
    }
}
