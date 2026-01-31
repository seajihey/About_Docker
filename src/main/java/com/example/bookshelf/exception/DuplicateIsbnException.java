package com.example.bookshelf.exception;

public class DuplicateIsbnException extends RuntimeException {

    private final String isbn;

    public DuplicateIsbnException(String isbn) {
        super(String.format("이미 등록된 ISBN입니다. (ISBN: %s)", isbn));
        this.isbn = isbn;
    }

    public String getIsbn() {
        return isbn;
    }
}
